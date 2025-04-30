import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legalai/features/chat/data/models/chat_message.dart';
import 'package:legalai/features/chat/data/models/chat_session.dart';
import 'package:legalai/main.dart'; // HiveBoxes için
// Yeni importlar
import 'package:legalai/features/chat/providers/chat_providers.dart'; // DocumentGenerationStatus için
import 'package:legalai/features/chat/data/models/ai_response.dart';
import 'package:legalai/features/chat/data/models/generation_result.dart';
import 'package:uuid/uuid.dart'; // Yeni session ID için

// Supabase client instance'ı için provider (main.dart'ta initialize ediliyor)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// InMemoryStorage kaldırıldı

// ChatService için provider (güncellendi)
final chatServiceProvider = Provider<ChatService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  // Hive kutularını al
  final chatHistoryBox = Hive.box<ChatMessage>(HiveBoxes.chatHistory);
  final chatSessionsBox = Hive.box<ChatSession>(HiveBoxes.chatSessions);
  return ChatService(supabaseClient, chatHistoryBox, chatSessionsBox);
});

class ChatService {
  final SupabaseClient _supabaseClient;
  final Box<ChatMessage> _chatHistoryBox;
  final Box<ChatSession> _chatSessionsBox;
  final Uuid _uuid = Uuid(); // ID üretmek için

  // Constructor güncellendi
  ChatService(this._supabaseClient, this._chatHistoryBox, this._chatSessionsBox);

  // Eski askAI kaldırıldı

  /// Kullanıcı girdisini ve sohbet durumunu işler, AI ile etkileşime girer.
  Future<AIResponse> processConversationTurn({
    required String userInput,
    required String chatId,
    required DocumentGenerationStatus currentStatus,
    required String? requestedDocumentType,
    required Map<String, String> currentCollectedData,
    // List<ChatMessage>? previousMessages, // Opsiyonel: LLM'e geçmişi göndermek için
  }) async {
    try {
      print('Calling Supabase Edge Function: process-chat-turn');
      
      // Edge Function'a gönderilecek veriler
      final requestBody = {
        'userInput': userInput,
        'chatId': chatId,
        'currentStatus': currentStatus.name, // Enum'ı string'e çevir
        'requestedDocumentType': requestedDocumentType,
        'currentCollectedData': currentCollectedData,
        // 'history': previousMessages?.map((m) => m.toJson()).toList(), // Geçmişi JSON'a çevir
      };
      
      // Yeni Edge Function'ı çağır
      final response = await _supabaseClient.functions.invoke(
        'process-chat-turn', // Yeni Edge Function adı
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

    } catch (e) {
      print('Error in processConversationTurn: $e');
      String errorMessage = 'Mesaj işlenirken bilinmeyen bir hata oluştu.';
       if (e.toString().contains('NetworkError') || e.toString().contains('host lookup')) {
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
    List<ChatMessage>? chatHistory, // Context için sohbet geçmişi (opsiyonel)
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

  // Yeni sohbet oturumu oluştur (Hive'a kaydet)
  Future<ChatSession> createChatSession({String? title}) async {
    try {
      final sessionId = _uuid.v4();
      final session = ChatSession(
        id: sessionId,
        title: title ?? 'Yeni Sohbet',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _chatSessionsBox.put(sessionId, session);
      return session;
    } catch (e) {
      print('Error creating chat session in Hive: $e');
      rethrow;
    }
  }
  
  // Mevcut sohbetleri al (Hive'dan)
  List<ChatSession> getChatSessions() {
    try {
      final sessions = _chatSessionsBox.values.toList();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Son güncellenene göre sırala
      return sessions;
    } catch (e) {
      print('Error getting chat sessions from Hive: $e');
      return [];
    }
  }
  
  // Belirli bir sohbet oturumunu al (Hive'dan)
  ChatSession? getChatSessionById(String id) {
    try {
      return _chatSessionsBox.get(id);
    } catch (e) {
      print('Error getting chat session by id from Hive: $e');
      return null;
    }
  }

  // Sohbet başlığını güncelle (Hive'da)
  Future<void> updateChatSessionTitle(String chatId, String title) async {
     try {
       final session = _chatSessionsBox.get(chatId);
       if (session != null) {
         session.title = title; // HiveObject olduğu için doğrudan güncellenebilir
         session.updatedAt = DateTime.now();
         await session.save(); // Değişikliği kaydet
       }
     } catch (e) {
       print('Error updating chat session title in Hive: $e');
     }
  }

  // Sohbet mesajını kaydet (Hive'a)
  Future<void> saveChatMessage(ChatMessage message) async {
    try {
      // Mesaja benzersiz bir anahtar ata (eğer HiveObject değilse)
      // String messageKey = '${message.chatId}_${message.timestamp.millisecondsSinceEpoch}';
      // await _chatHistoryBox.put(messageKey, message);
      
      // HiveObject olduğu için doğrudan add kullanılabilir (otomatik artan anahtar)
      await _chatHistoryBox.add(message);
      
      // Sohbet oturumunun güncelleme tarihini de güncelle
      final session = _chatSessionsBox.get(message.chatId);
      if (session != null) {
        session.updatedAt = DateTime.now();
        await session.save();
      }
    } catch (e) {
      print('Error saving chat message to Hive: $e');
    }
  }

  // Belirli bir sohbet oturumunun mesajlarını getir (Hive'dan)
  List<ChatMessage> getChatHistoryForSession(String chatId) {
    try {
      final messages = _chatHistoryBox.values
          .where((message) => message.chatId == chatId)
          .toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('Error getting chat history for session from Hive: $e');
      return [];
    }
  }

  // Tüm sohbet geçmişini alma (Hive'dan)
  List<ChatMessage> getAllChatHistory() {
    try {
      final history = _chatHistoryBox.values.toList();
      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    } catch (e) {
      print('Error getting all chat history from Hive: $e');
      return [];
    }
  }

  // Bir sohbet oturumunu sil (Hive'dan)
  Future<void> deleteChatSession(String chatId) async {
    try {
      // İlgili oturumun mesajlarını sil
      final messageKeys = _chatHistoryBox.keys.where((key) {
        final message = _chatHistoryBox.get(key);
        return message != null && message.chatId == chatId;
      }).toList();
      await _chatHistoryBox.deleteAll(messageKeys);
      
      // Oturumu sil
      await _chatSessionsBox.delete(chatId);
    } catch (e) {
      print('Error deleting chat session from Hive: $e');
      rethrow;
    }
  }
} 