import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legalai/features/advisor/data/models/advisor_message.dart';
import 'package:legalai/features/advisor/data/models/advisor_session.dart';
import 'package:legalai/main.dart'; // HiveBoxes için
// Yeni importlar
import 'package:legalai/features/advisor/providers/advisor_providers.dart'; // DocumentGenerationStatus için
import 'package:legalai/features/advisor/data/models/ai_response.dart';
import 'package:legalai/features/advisor/data/models/generation_result.dart';
import 'package:uuid/uuid.dart'; // Yeni session ID için

// Supabase client instance'ı için provider (main.dart'ta initialize ediliyor)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// InMemoryStorage kaldırıldı

// ChatService için provider (güncellendi)
final advisorServiceProvider = Provider<AdvisorService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  // Hive kutularını al
  final historyBox = Hive.box<AdvisorMessage>(HiveBoxes.chatHistory);
  final sessionsBox = Hive.box<AdvisorSession>(HiveBoxes.chatSessions);
  return AdvisorService(supabaseClient, historyBox, sessionsBox);
});

class AdvisorService {
  final SupabaseClient _supabaseClient;
  final Box<AdvisorMessage> _historyBox;
  final Box<AdvisorSession> _sessionsBox;
  final Uuid _uuid = Uuid(); // ID üretmek için

  // Constructor güncellendi
  AdvisorService(this._supabaseClient, this._historyBox, this._sessionsBox);

  // Eski askAI kaldırıldı

  /// Kullanıcı girdisini ve danışma durumunu işler, AI ile etkileşime girer.
  Future<AIResponse> processConversationTurn({
    required String userInput,
    required String chatId,
    required DocumentGenerationStatus currentStatus,
    required String? requestedDocumentType,
    required Map<String, String> currentCollectedData,
    // List<AdvisorMessage>? previousMessages, // Bu parametre artık kullanılmayacak
  }) async {
    try {
      print('Calling Supabase Edge Function: legal-query with status: ${currentStatus.name}');
      
      // --- Get recent history from Hive ---
      const int historyWindowSize = 10; // Match Edge Function window size
      final List<AdvisorMessage> recentMessages = getHistoryForAdvisorSession(chatId).reversed.take(historyWindowSize).toList().reversed.toList();
      
      // Format history for the API (role/content map)
      final historyForApi = recentMessages.map((msg) => {
            'role': msg.isUserMessage ? 'user' : 'assistant',
            // Dikkat: AI yanıtının tamamını (metadata dahil) göndermemeye dikkat et.
            // Sadece metin kısmını (question veya answer'daki metin) gönderelim.
            'content': msg.isUserMessage ? msg.question : msg.answer
            // TODO: AI yanıtlarından metadata'yı temizlemek gerekebilir, şu an tüm `answer` gidiyor.
            // Belki `legal-document` bloklarını da temizlemek iyi olabilir?
      }).toList();
      
      // Add current user input to the history being sent
      historyForApi.add({'role': 'user', 'content': userInput});
      // --- End History Preparation ---
      
      // Edge Function'a gönderilecek veriler
      final requestBody = {
        // 'userInput': userInput, // userInput artık history'nin son elemanı
        // 'chatId': chatId, // chatID'yi göndermek gerekli mi? Edge function kullanmıyor gibi.
        'currentStatus': currentStatus.name, // Enum'ı string'e çevir
        'requestedDocumentType': requestedDocumentType,
        'currentCollectedData': currentCollectedData,
        'history': historyForApi, // Hazırlanan geçmişi gönder
      };
      
      // Yeni Edge Function'ı çağır
      final response = await _supabaseClient.functions.invoke(
        'legal-query', // Edge Function adı doğru
        body: requestBody, 
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] as String? ?? 'Fonksiyon hatası.';
        print('Edge Function Error: ${response.status} - $errorMessage');
        return AIResponse(error: 'Yapay zeka ile iletişim kurulamadı: $errorMessage');
      }

      // Başarılı yanıtı parse etmeden önce tür kontrolü ekleyelim
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>; // Cast artık güvenli
        
        // Yanıtı parse et ve AIResponse nesnesi oluştur
        return AIResponse(
          responseText: responseData['responseText'] as String?,
          isAskingQuestion: responseData['isAskingQuestion'] as bool?,
          newStatus: DocumentGenerationStatus.values.firstWhere(
            (e) => e.name == responseData['newStatus'] as String?, 
            orElse: () => currentStatus
          ),
          documentType: responseData['documentType'] as String?,
          collectedData: responseData['collectedData'] != null 
              ? Map<String, String>.from(responseData['collectedData'])
              : null,
          documentPath: responseData['documentPath'] as String?,
          error: responseData['error'] as String?,
        );
      } else {
         print('Unexpected response data type: ${response.data?.runtimeType}');
         print('Response data content: ${response.data}');
         return AIResponse(error: 'Fonksiyondan beklenmeyen formatta yanıt alındı.');
      }

    } catch (e, stackTrace) {
      print('Error in processConversationTurn: $e');
      print('StackTrace: $stackTrace');
      
      String errorMessage = 'Mesaj işlenirken bilinmeyen bir hata oluştu.';
      if (e is FunctionException) {
        errorMessage = 'Fonksiyon hatası: ${e.toString()}';
      } else if (e.toString().contains('NetworkError') || e.toString().contains('host lookup')) {
         errorMessage = 'İnternet bağlantınızı kontrol edin.';
      } else if (e is Exception) {
         errorMessage = e.toString();
      }
      return AIResponse(error: errorMessage);
    }
  }

  /// Belirtilen verilerle PDF belgesi oluşturur.
  Future<GenerationResult> generateDocument({
    required String chatId,
    required String templateId,
    required Map<String, String> data,
  }) async {
     try {
      print('Calling Supabase Edge Function: generate-pdf');
      
      final response = await _supabaseClient.functions.invoke(
        'generate-pdf', // PDF oluşturma için Edge Function adı
        body: {
          'chatId': chatId,
          'templateId': templateId,
          'data': data, // Onaylanmış veriler
        },
      );

      if (response.status != 200) {
         final errorData = response.data as Map<String, dynamic>?;
         final errorMessage = errorData?['error'] as String? ?? 'Fonksiyon hatası.';
         print('Edge Function Error (generate-pdf): ${response.status} - $errorMessage');
         return GenerationResult(success: false, errorMessage: 'Belge oluşturulamadı: $errorMessage');
      }

      final responseData = response.data as Map<String, dynamic>?;
       if (responseData == null) {
         return GenerationResult(success: false, errorMessage: 'PDF oluşturma fonksiyonu boş yanıt döndürdü.');
       }

      // Başarılı yanıtı parse et
      final documentPath = responseData['documentPath'] as String?;
      if (documentPath == null) {
         return GenerationResult(success: false, errorMessage: 'Oluşturulan belgenin yolu bulunamadı.');
      }
      
      return GenerationResult(success: true, documentPath: documentPath);

    } catch (e) {
       print('Error in generateDocument: $e');
       String errorMessage = 'Belge oluşturulurken bilinmeyen bir hata oluştu.';
       if (e.toString().contains('NetworkError') || e.toString().contains('host lookup')) {
         errorMessage = 'İnternet bağlantınızı kontrol edin.';
       } else if (e is Exception) {
         errorMessage = e.toString();
       }
       return GenerationResult(success: false, errorMessage: errorMessage);
    }
  }

  // --- AI Text Generation (NEW) ---
  // Metodu public yap (alt çizgi kaldırıldı)
  Future<String> generateDocumentTextFromAI({
    required String documentType,
    required Map<String, String> data,
    List<AdvisorMessage>? chatHistory, // Context için sohbet geçmişi (opsiyonel)
  }) async {
    print('Calling Supabase Edge Function: generate-text-from-ai');

    try {
      final response = await _supabaseClient.functions.invoke(
        'generate-text-from-ai', // Yeni Edge Function adı
        body: {
          'documentType': documentType,
          'data': data,
          // 'chatHistory': chatHistory?.map((m) => m.toJson()).toList(), // Gerekirse geçmişi gönder
        },
      );

      if (response.status != 200) {
         final errorData = response.data as Map<String, dynamic>?;
         final errorMessage = errorData?['error'] as String? ?? 'Fonksiyon hatası.';
         print('Edge Function Error (generate-text-from-ai): ${response.status} - $errorMessage');
         throw Exception('AI metin oluşturma fonksiyonu başarısız oldu: $errorMessage');
      }

      final responseData = response.data as Map<String, dynamic>?;
      final generatedText = responseData?['generatedText'] as String?;

      if (generatedText == null || generatedText.isEmpty) {
        print('Edge Function (generate-text-from-ai) did not return text.');
        throw Exception('AI metin üretemedi veya fonksiyon yanıtı hatalı.');
      }

      print('Successfully received generated text from Edge Function.');
      return generatedText;

    } catch (e) {
      print('Error calling generate-text-from-ai function: $e');
      // Hatanın türüne göre daha spesifik mesajlar verilebilir
      throw Exception('AI metin oluşturma işlemi sırasında hata: ${e.toString()}');
    }
  }

  // --- Hive Operasyonları ---

  // Yeni sohbet oturumu oluştur (Hive\'a kaydet)
  Future<AdvisorSession> createAdvisorSession({String? title}) async {
    final sessionId = _uuid.v4();
    print("[AdvisorService] Attempting to create session: ID=$sessionId, Title=${title ?? 'Yeni Sohbet'}"); // Log 1
    try {
      final session = AdvisorSession(
        id: sessionId,
        title: title ?? 'Yeni Sohbet',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      print("[AdvisorService] Session object created. Attempting to put into Hive box..."); // Log 2
      await _sessionsBox.put(sessionId, session);
      print("[AdvisorService] Successfully put session ID=$sessionId into Hive box."); // Log 3
      return session;
    } catch (e) {
      print('[AdvisorService] !!!!! ERROR creating/putting chat session in Hive: $e !!!!!'); // Log 4 (Error)
      rethrow; // Keep rethrowing
    }
  }
  
  // Mevcut sohbetleri al (Hive'dan)
  List<AdvisorSession> getAdvisorSessions() {
    try {
      final sessions = _sessionsBox.values.toList();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Son güncellenene göre sırala
      return sessions;
    } catch (e) {
      print('Error getting chat sessions from Hive: $e');
      return [];
    }
  }
  
  // AdvisorSessionsNotifier için eklediğimiz yeni metot
  List<AdvisorSession> loadAdvisorSessions() {
    return getAdvisorSessions();
  }
  
  // Belirli bir sohbet oturumunu al (Hive'dan)
  AdvisorSession? getAdvisorSessionById(String id) {
    try {
      return _sessionsBox.get(id);
    } catch (e) {
      print('Error getting chat session by id from Hive: $e');
      return null;
    }
  }
  
  // Sohbet oturumu bilgisini almak için yeni metod
  Future<AdvisorSession?> getAdvisorSessionInfo(String sessionId) async {
    return getAdvisorSessionById(sessionId);
  }
  
  // AdvisorNotifier sınıfı için gerekli metodları ekleyelim
  Future<List<AdvisorMessage>> loadAdvisorMessages(String sessionId) async {
    try {
      final messages = _historyBox.values
        .where((message) => message.chatId == sessionId)
        .toList();
      
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('Error loading chat messages from Hive: $e');
      return [];
    }
  }
  
  // AI yanıtı almak için metot
  Future<AIResponse> getAIResponse(String userMessage, List<AdvisorMessage> messages) async {
    // Mesaj listesini OpenAI formatına dönüştür (en eski mesaj en başta)
    List<Map<String, String>> historyForApi = messages.reversed.map((msg) {
      return {
        'role': msg.isUserMessage ? 'user' : 'assistant',
        'content': msg.isUserMessage ? msg.question : msg.answer,
      };
    }).toList();

    // Son kullanıcı mesajını da ekle (eğer messages listesinde yoksa)
    // Not: AdvisorNotifier'daki _addMessage zaten state'e ekliyor, 
    // bu yüzden messages listesi zaten son mesajı içermeli.
    // Eğer processAdvisorUserMessage içinde _addMessage'dan *önce* getAIResponse çağrılsaydı
    // buraya eklemek gerekirdi: historyForApi.add({'role': 'user', 'content': userMessage});

    print('Sending history to legal-query: ${jsonEncode(historyForApi)}'); // Log history

    try {
      print('Calling Supabase Edge Function: legal-query with history');
      final response = await _supabaseClient.functions.invoke(
        'legal-query', 
        body: {'history': historyForApi},
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] as String? ?? 'Fonksiyon hatası (status ${response.status}).';
        print('Edge Function Error (legal-query): ${response.status} - $errorMessage');
        return AIResponse(error: 'Yapay zeka ile iletişim kurulamadı: $errorMessage');
      }

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        final aiAnswer = responseData['answer'] as String?;
        print('Received answer from legal-query: $aiAnswer');
        // Sadece responseText'i dolduruyoruz, diğer alanlar null kalacak
        return AIResponse(responseText: aiAnswer);
      } else {
        print('Unexpected response data type from legal-query: ${response.data?.runtimeType}');
        print('Response data content: ${response.data}');
        return AIResponse(error: 'Fonksiyondan beklenmeyen formatta yanıt alındı.');
      }

    } catch (e, stackTrace) {
      print('Error calling legal-query: $e');
      print('StackTrace: $stackTrace');
      String errorMessage = 'Mesaj işlenirken bilinmeyen bir hata oluştu.';
      if (e is FunctionException) {
        errorMessage = 'Fonksiyon hatası: ${e.toString()}';
      } else if (e.toString().contains('NetworkError') || e.toString().contains('host lookup')) {
        errorMessage = 'İnternet bağlantınızı kontrol edin.';
      } else if (e is Exception) {
        errorMessage = e.toString();
      }
      return AIResponse(error: errorMessage);
    }
    // Eski processConversationTurn çağrısını kaldırdık
    /*
    final chatId = messages.isNotEmpty ? messages.first.chatId : 'unknown';
    
    return await processConversationTurn(
      userInput: userMessage, // Artık kullanılmıyor
      chatId: chatId, // Artık kullanılmıyor
      currentStatus: DocumentGenerationStatus.idle, // Artık kullanılmıyor
      requestedDocumentType: null, // Artık kullanılmıyor
      currentCollectedData: {}, // Artık kullanılmıyor
      history: historyForApi // processConversationTurn'ü buna göre güncellemek lazım
    );
    */
  }
  
  // Sohbet oturumunu silmek için metod
  Future<void> deleteAdvisorSession(String sessionId) async {
    try {
      // Önce oturuma ait tüm mesajları bul ve sil
      final messagesToDelete = _historyBox.values
          .where((message) => message.chatId == sessionId)
          .toList();
          
      for (var message in messagesToDelete) {
        await _historyBox.delete(message.key);
      }
      
      // Sonra oturumu sil
      await _sessionsBox.delete(sessionId);
    } catch (e) {
      print('Error deleting chat session from Hive: $e');
      rethrow;
    }
  }

  // Sohbet başlığını güncelle (Hive\'da)
  Future<void> updateAdvisorSessionTitle(String sessionId, String title) async {
    print("[AdvisorService] Attempting to update title for session ID=$sessionId to '$title'"); // Log 5
    try {
      final session = _sessionsBox.get(sessionId);
      if (session != null) {
        print("[AdvisorService] Session found. Updating title and timestamp..."); // Log 6
        session.title = title; // HiveObject olduğu için doğrudan güncellenebilir
        session.updatedAt = DateTime.now();
        await session.save(); // Değişikliği kaydet
        print("[AdvisorService] Successfully saved updated session ID=$sessionId."); // Log 7
      } else {
        print("[AdvisorService] !!!!! WARNING: Session ID=$sessionId not found in Hive box for title update. !!!!!"); // Log 8 (Warning)
      }
    } catch (e) {
      print('[AdvisorService] !!!!! ERROR updating chat session title in Hive: $e !!!!!'); // Log 9 (Error)
    }
  }

  // Sohbet mesajını kaydet (Hive'a)
  Future<void> saveAdvisorMessage(AdvisorMessage message) async {
    try {
      // Mesaja benzersiz bir anahtar ata (eğer HiveObject değilse)
      // String messageKey = '${message.chatId}_${message.timestamp.millisecondsSinceEpoch}';
      // await _chatHistoryBox.put(messageKey, message);
      
      // HiveObject olduğu için doğrudan add kullanılabilir (otomatik artan anahtar)
      await _historyBox.add(message);
      
      // Sohbet oturumunun güncelleme tarihini de güncelle
      final session = _sessionsBox.get(message.chatId);
      if (session != null) {
        session.updatedAt = DateTime.now();
        await session.save();
      }
    } catch (e) {
      print('Error saving chat message to Hive: $e');
    }
  }

  // Belirli bir sohbet oturumunun mesajlarını getir (Hive'dan)
  List<AdvisorMessage> getHistoryForAdvisorSession(String sessionId) {
    try {
      final messages = _historyBox.values
          .where((message) => message.chatId == sessionId)
          .toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('Error getting chat history for session from Hive: $e');
      return [];
    }
  }

  // Tüm sohbet geçmişini alma (Hive'dan)
  List<AdvisorMessage> getAllChatHistory() {
    try {
      final history = _historyBox.values.toList();
      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    } catch (e) {
      print('Error getting all chat history from Hive: $e');
      return [];
    }
  }
} 