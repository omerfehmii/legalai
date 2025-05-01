import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart'; // Import Hive
import '../data/models/advisor_message.dart';
import '../data/models/advisor_session.dart';
import '../services/advisor_service.dart';
import 'package:legalai/main.dart'; // Import main for HiveBoxes
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this line
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

// Belge oluşturma sürecinin durumunu belirten enum
enum DocumentGenerationStatus {
  idle,          // Normal sohbet veya başlangıç durumu
  collectingInfo,// AI bilgi topluyor
  awaitingConfirmation, // AI bilgileri topladı, kullanıcı onayı bekliyor
  generating,    // PDF oluşturuluyor
  ready,         // PDF hazır, link/buton gösterilebilir
  failed,        // PDF oluşturma başarısız oldu
}

// Rename ChatState to AdvisorState
class AdvisorState {
  // Update Message type later if model is renamed
  final List<AdvisorMessage> messages;
  final bool isLoading; // Genel AI cevabı veya işlem yükleniyor durumu
  final String? errorMessage;
  final String? currentChatId;
  final String? currentChatTitle;

  // Belge Oluşturma Akışı için Ek Durumlar
  final DocumentGenerationStatus generationStatus; // Belge oluşturma akışının genel durumu
  final String? requestedDocumentType; // Hangi tür belge istendiği (örn. "kira ihtarnamesi")
  final Map<String, String>? collectedData; // Toplanan alan verileri (key: value)
  final String? generatedDocumentPath; // Oluşturulan PDF'in yolu (opsiyonel)
  final bool isAiAsking; // AI'ın aktif olarak soru sorduğunu belirtir (UI'da farklı gösterim için)

  AdvisorState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentChatId,
    this.currentChatTitle,
    this.generationStatus = DocumentGenerationStatus.idle,
    this.requestedDocumentType,
    this.collectedData,
    this.generatedDocumentPath,
    this.isAiAsking = false,
  });

  // Update return type and constructor call
  AdvisorState copyWith({
    List<AdvisorMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    String? currentChatId,
    String? currentChatTitle,
    DocumentGenerationStatus? generationStatus,
    String? requestedDocumentType,
    Map<String, String>? collectedData,
    String? generatedDocumentPath,
    bool? isAiAsking,
    bool clearError = false, // Hata mesajını temizlemek için flag
    bool clearDocumentState = false, // Belge durumunu sıfırlamak için flag
  }) {
    return AdvisorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentChatId: currentChatId ?? this.currentChatId,
      currentChatTitle: currentChatTitle ?? this.currentChatTitle,
      // Belge durumunu sıfırlama kontrolü
      generationStatus: clearDocumentState ? DocumentGenerationStatus.idle : (generationStatus ?? this.generationStatus),
      requestedDocumentType: clearDocumentState ? null : (requestedDocumentType ?? this.requestedDocumentType),
      collectedData: clearDocumentState ? null : (collectedData ?? this.collectedData),
      generatedDocumentPath: clearDocumentState ? null : (generatedDocumentPath ?? this.generatedDocumentPath),
      isAiAsking: clearDocumentState ? false : (isAiAsking ?? this.isAiAsking),
    );
  }
}

// Rename ChatSessionsState to AdvisorSessionsState
class AdvisorSessionsState {
  // Update Session type later if model is renamed
  final List<AdvisorSession> sessions;
  final bool isLoading;
  final String? errorMessage;
  
  AdvisorSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  
  // Update return type and constructor call
  AdvisorSessionsState copyWith({
    List<AdvisorSession>? sessions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdvisorSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Rename ChatSessionsNotifier to AdvisorSessionsNotifier
class AdvisorSessionsNotifier extends StateNotifier<AdvisorSessionsState> {
  // Add service as dependency
  final AdvisorService _advisorService;
  final Ref ref; // Need Ref to read other providers if needed

  // Update constructor
  AdvisorSessionsNotifier(this.ref, this._advisorService) : super(AdvisorSessionsState()) {
    _loadAdvisorSessions(); // Load on init
  }
  
  void _loadAdvisorSessions() {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = _advisorService.loadAdvisorSessions();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Oturumlar yüklenirken hata oluştu: ${e.toString()}', 
        isLoading: false
      );
    }
  }

  Future<AdvisorSession> createNewSession({String? title}) async {
    state = state.copyWith(isLoading: true);
    try {
      final newSession = await _advisorService.createAdvisorSession(title: title ?? 'Yeni Görüşme');
      state = state.copyWith(
        sessions: [newSession, ...state.sessions],
        isLoading: false
      );
      return newSession;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Yeni oturum oluşturulamadı: ${e.toString()}',
        isLoading: false
      );
      // Hatayı yönetmek için boş bir oturum oluşturup döndürüyoruz
      final uuid = Uuid();
      return AdvisorSession(
        id: uuid.v4(), 
        title: title ?? 'Hata Oluştu',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  Future<void> deleteAdvisorSession(String sessionId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _advisorService.deleteAdvisorSession(sessionId);
      final updatedSessions = state.sessions
          .where((session) => session.id != sessionId)
          .toList();
      state = state.copyWith(sessions: updatedSessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Oturum silinemedi: ${e.toString()}',
        isLoading: false
      );
    }
  }
}

// Rename ChatNotifier to AdvisorNotifier
class AdvisorNotifier extends StateNotifier<AdvisorState> {
  // Add service as dependency
  final AdvisorService _advisorService;
  final Ref ref;

  // Update constructor
  AdvisorNotifier(this.ref, this._advisorService) : super(AdvisorState());

  // Keep initializeChat method
  Future<void> initializeChat({bool startWithDocumentPrompt = false}) async {
    state = AdvisorState(); 
    if (startWithDocumentPrompt) {
      // Use internal _addMessage method
      _addMessage("Merhaba! Hangi belgeyi oluşturmak istersiniz? Lütfen belge türünü belirtin (örn: Kira Sözleşmesi).", false);
    } else {
      _addMessage("Merhaba! Size nasıl yardımcı olabilirim?", false);
    }
  }

  // Keep _addMessage method
  void _addMessage(String text, bool isUser) {
     // Metnin içinde legal-document bloğu var mı kontrol et
     final RegExp docRegex = RegExp(r"```legal-document\n?(.*?)\n?```", dotAll: true, multiLine: true);
     final match = docRegex.firstMatch(text);
     
     Map<String, dynamic>? metadata;
     String messageText = text; // Görüntülenecek metin

     if (!isUser && match != null) {
       // AI mesajı ve bir belge bloğu bulundu
       String pureDocumentText = match.group(1)?.trim() ?? '';
       metadata = {
         'isDocumentMessage': true,
         'documentText': pureDocumentText,
       };
       // Mesaj metninden kod bloğunu temizleyebiliriz veya olduğu gibi bırakabiliriz.
       // Şimdilik UI'da temizlendiği için olduğu gibi bırakalım.
       // messageText = text.replaceAll(docRegex, '').trim(); 
     } else {
        metadata = {
         'isDocumentMessage': false,
       }; // Belge değil
     }

     final message = AdvisorMessage(
       question: isUser ? text : '', // Kullanıcı ise question
       answer: !isUser ? text : '', // AI ise answer (tam metni saklayalım)
       timestamp: DateTime.now(),
       chatId: state.currentChatId ?? 'unknown', // Handle potential null chatId
       isUserMessage: isUser,
       metadata: metadata, // Hesaplanan metadata'yı ekle
     );
     
     // Yeni mesajı Hive'a kaydet
     _advisorService.saveAdvisorMessage(message);
     
     // State'i güncelle (en yeni mesaj sonda)
     state = state.copyWith(messages: [...state.messages, message]);
  }

  // Rename startNewChat to startNewAdvisorChat
  Future<void> startNewAdvisorChat() async {
    state = AdvisorState(isLoading: true); // Yeni durum başlangıcı
    
    try {
      // Yeni oturum oluştur
      final newSession = await ref.read(advisorSessionsProvider.notifier).createNewSession();
      
      // State'i güncelle
      state = AdvisorState(
        currentChatId: newSession.id,
        currentChatTitle: newSession.title,
      );
      
      // Karşılama mesajı ekle
      _addMessage("Merhaba! Size nasıl yardımcı olabilirim?", false);
    } catch (e) {
      state = AdvisorState(errorMessage: 'Yeni oturum başlatılamadı: ${e.toString()}');
    }
  }

  // Rename loadChat to loadAdvisorChat
  Future<void> loadAdvisorChat(String chatId) async {
    state = AdvisorState(isLoading: true); // Yüklenirken temiz durum başlat
    
    try {
      // Servis üzerinden mesajları yükle
      final messages = await _advisorService.loadAdvisorMessages(chatId);
      final sessionInfo = await _advisorService.getAdvisorSessionInfo(chatId);
      
      // State'i güncelle
      state = AdvisorState(
        messages: messages, 
        currentChatId: chatId,
        currentChatTitle: sessionInfo?.title ?? 'AI Danışman', // Oturum adı yoksa default
      );
    } catch (e) {
      state = AdvisorState(errorMessage: 'Oturum yüklenemedi: ${e.toString()}');
    }
  }

  // clearError remains the same
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Rename processUserMessage to processAdvisorUserMessage
  Future<void> processAdvisorUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    String currentChatId = state.currentChatId ?? 'unknown'; // Use a variable

    // İlk mesajsa ve oturum ID'si yoksa yeni bir oturum başlat
    if (state.messages.isEmpty && state.currentChatId == null) {
      // Yeni oturum oluştur
      final newSession = await ref.read(advisorSessionsProvider.notifier).createNewSession();
      currentChatId = newSession.id; // Update currentChatId
      state = state.copyWith(
        currentChatId: currentChatId, 
        currentChatTitle: newSession.title,
      );
    }
    
    // Kullanıcı mesajını ekle
    _addMessage(text, true);
    
    // AI'ın yanıt vermesi için yükleme durumunu güncelle
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // İlk mesaj ise başlığı güncelle (Bu mantık kalabilir)
      // if (state.messages.length == 1) { // state.messages güncellendiği için kontrol 2 olmalı
      if (state.messages.where((m) => m.isUserMessage).length == 1) { // Sadece kullanıcı mesajlarını say
        await _updateAdvisorChatTitle(text);
      }
      
      // ---- AI cevabı al (Güncellenmiş Servis Çağrısı) ----
      final aiResponse = await _advisorService.processConversationTurn(
         userInput: text,
         chatId: currentChatId, // Ensure chatId is passed
         currentStatus: state.generationStatus, 
         requestedDocumentType: state.requestedDocumentType,
         // Ensure collectedData is not null, pass empty map if it is
         currentCollectedData: state.collectedData ?? {}
      );
      // ---- End AI Response Call ----
      
      // AI mesajını ekle (sadece metin kısmı)
      if (aiResponse.responseText != null && aiResponse.responseText!.trim().isNotEmpty) {
        _addMessage(aiResponse.responseText!, false);
      }
      
      // ---- State Güncelleme (Yapılandırılmış Yanıta Göre) ---- 
      if (aiResponse.error != null) {
        state = state.copyWith(errorMessage: aiResponse.error, isLoading: false);
      } else {
        // Başarılı yanıt: Durumu AI'dan gelen verilere göre güncelle
        state = state.copyWith(
          isLoading: false, // Yüklemeyi bitir
          generationStatus: aiResponse.newStatus ?? state.generationStatus, // Yeni durumu al, yoksa eskiyi koru
          isAiAsking: aiResponse.isAskingQuestion ?? state.isAiAsking, // AI soru soruyor mu?
          requestedDocumentType: aiResponse.documentType ?? state.requestedDocumentType, // Belge türünü güncelle
          collectedData: aiResponse.collectedData ?? state.collectedData, // Toplanan veriyi güncelle
          // generatedDocumentPath: aiResponse.documentPath ?? state.generatedDocumentPath, // documentPath burada gelmiyor
        );
      }
      // ---- End State Update ----

    } catch (e) {
      // Catch errors from the service call itself (network etc.)
      state = state.copyWith(
        errorMessage: 'Mesaj işlenirken bir hata oluştu: ${e.toString()}',
        isLoading: false
      );
    }
  }

  // Rename helper method
  Future<void> _updateAdvisorChatTitle(String firstMessage) async {
    if (state.currentChatId == null) return;
    
    try {
      // Mesajdan başlık oluştur (kısaltılmış)
      String title = firstMessage.length > 30 
          ? '${firstMessage.substring(0, 30)}...' 
          : firstMessage;
          
      // Servisi kullanarak başlığı güncelle
      await _advisorService.updateAdvisorSessionTitle(state.currentChatId!, title);
      
      // Provider'ı güncelle
      state = state.copyWith(currentChatTitle: title);
      
      // Oturumlar listesini de güncelle
      ref.read(advisorSessionsProvider.notifier)._loadAdvisorSessions();
    } catch (e) {
      // Oturum başlığı güncellenirken hata olursa sessizce devam et
      print('Oturum başlığı güncellenemedi: ${e.toString()}');
    }
  }
}

// Chat Service Provider (Hive ile)
final advisorServiceProvider = Provider<AdvisorService>((ref) {
  final supabaseClient = Supabase.instance.client; 
  // Use renamed Hive constants
  final chatHistoryBox = Hive.box<AdvisorMessage>(HiveBoxes.chatHistory);
  final chatSessionsBox = Hive.box<AdvisorSession>(HiveBoxes.chatSessions);
  return AdvisorService(supabaseClient, chatHistoryBox, chatSessionsBox);
});

// Define providers using standard StateNotifierProvider
final advisorSessionsProvider = StateNotifierProvider<AdvisorSessionsNotifier, AdvisorSessionsState>((ref) {
  final advisorService = ref.watch(advisorServiceProvider);
  return AdvisorSessionsNotifier(ref, advisorService);
});

final advisorNotifierProvider = StateNotifierProvider<AdvisorNotifier, AdvisorState>((ref) {
  final advisorService = ref.watch(advisorServiceProvider);
  return AdvisorNotifier(ref, advisorService);
}); 