import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart'; // Import Hive
import 'package:legalai/features/chat/data/models/chat_message.dart';
import 'package:legalai/features/chat/data/models/chat_session.dart';
import 'package:legalai/features/chat/services/chat_service.dart';
import 'package:legalai/main.dart'; // Import main for HiveBoxes
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this line
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../models/document_generation_status.dart';

part 'advisor_providers.g.dart';

// Belge oluşturma sürecinin durumunu belirten enum
enum DocumentGenerationStatus {
  idle,          // Normal sohbet veya başlangıç durumu
  collectingInfo,// AI bilgi topluyor
  awaitingConfirmation, // AI bilgileri topladı, kullanıcı onayı bekliyor
  generating,    // PDF oluşturuluyor
  ready,         // PDF hazır, link/buton gösterilebilir
  failed,        // PDF oluşturma başarısız oldu
}

// Chat State'ini temsil eden sınıf
class ChatState {
  final List<ChatMessage> messages;
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

  ChatState({
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

  // Kolaylık sağlamak için state'i kopyalayıp güncelleyen metot
  ChatState copyWith({
    List<ChatMessage>? messages,
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
    return ChatState(
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

// Chat session'larını tutan state
class ChatSessionsState {
  final List<ChatSession> sessions;
  final bool isLoading;
  final String? errorMessage;
  
  ChatSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  
  ChatSessionsState copyWith({
    List<ChatSession>? sessions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Chat session provider
class ChatSessionsNotifier extends StateNotifier<ChatSessionsState> {
  final ChatService _chatService;

  ChatSessionsNotifier(this._chatService) : super(ChatSessionsState()) {
    loadChatSessions();
  }

  void loadChatSessions() {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = _chatService.getChatSessions();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Sohbet geçmişi yüklenemedi.', isLoading: false);
    }
  }

  Future<ChatSession> createNewSession({String? title}) async {
    state = state.copyWith(isLoading: true);
    try {
      final newSession = await _chatService.createChatSession(title: title);
      // Listeyi güncelle
      state = state.copyWith(
        sessions: [newSession, ...state.sessions],
        isLoading: false,
      );
      return newSession;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Yeni sohbet oluşturulamadı.', isLoading: false);
      rethrow;
    }
  }
  
  Future<void> deleteSession(String chatId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _chatService.deleteChatSession(chatId);
      // Listeyi güncelle
      final updatedSessions = state.sessions.where((s) => s.id != chatId).toList();
      state = state.copyWith(sessions: updatedSessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Sohbet silinemedi.', isLoading: false);
    }
  }
}

// StateNotifier sınıfı
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatNotifier(this._chatService) : super(ChatState());

  // Yeni bir sohbet başlat
  Future<void> startNewChat() async {
    try {
      // Önceki sohbet verilerini temizle (belge durumu dahil)
      state = ChatState(isLoading: true);
      
      // Yeni bir sohbet oturumu oluştur (ChatService Hive'a kaydedecek)
      final newSession = await _chatService.createChatSession();
      
      // State'i güncelle
      state = state.copyWith(
        currentChatId: newSession.id,
        currentChatTitle: newSession.title,
        messages: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Yeni sohbet başlatılamadı.', isLoading: false);
    }
  }

  // Var olan bir sohbeti yükle
  Future<void> loadChat(String chatId) async {
    // Sohbet yüklenirken belge durumunu sıfırla
    state = state.copyWith(isLoading: true, currentChatId: chatId, clearDocumentState: true);
    try {
      // Mevcut sohbet oturumunu bul (ChatService Hive'dan okuyacak)
      final session = _chatService.getChatSessionById(chatId);
      if (session == null) {
        throw Exception('Sohbet bulunamadı.');
      }
      
      // Sohbet mesajlarını yükle (ChatService Hive'dan okuyacak)
      final messages = _chatService.getChatHistoryForSession(chatId);
      
      // State'i güncelle
      state = state.copyWith(
        messages: messages, 
        currentChatTitle: session.title,
        isLoading: false,
      );
      // TODO: Belki burada sohbet geçmişine bakıp yarım kalmış bir belge 
      // oluşturma süreci varsa state'i ona göre ayarlamak gerekebilir.
    } catch (e) {
      state = state.copyWith(errorMessage: 'Sohbet yüklenemedi.', isLoading: false);
    }
  }

  // Hata mesajını temizle
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Kullanıcıdan gelen mesajı işle (Soru veya Belge Akışı Cevabı)
  Future<void> processUserMessage(String text) async {
    if (state.currentChatId == null) {
      await startNewChat();
      if (state.currentChatId == null) return;
    }
    
    // Kullanıcının mesajını oluştur (ama henüz state'e ekleme)
    final userMessage = ChatMessage(
      question: text,
      answer: '', 
      timestamp: DateTime.now(),
      chatId: state.currentChatId!,
      isUserMessage: true, 
    );
    
    // Mesajı Hive'a kaydet (AI cevabı gelmeden önce)
    await _chatService.saveChatMessage(userMessage);

    // Şimdi state'i güncelle (Hive'dan okunan en son listeyi alarak)
    final currentMessages = _chatService.getChatHistoryForSession(state.currentChatId!);
    state = state.copyWith(
      messages: currentMessages, 
      isLoading: true, 
      isAiAsking: false, 
      clearError: true,
    );

    try {
      // ChatService'i çağır
      final aiResponse = await _chatService.processConversationTurn(
        userInput: text,
        chatId: state.currentChatId!,
        currentStatus: state.generationStatus,
        requestedDocumentType: state.requestedDocumentType,
        currentCollectedData: state.collectedData ?? {},
        // Önceki mesajları da göndermek LLM için faydalı olabilir
        // previousMessages: state.messages, 
      );

      // AI'ın cevabını (veya sorusunu) içeren yeni mesajı oluştur
      if (aiResponse.responseText != null && aiResponse.responseText!.isNotEmpty) {
         final aiMessage = ChatMessage(
           question: '', // AI mesajı
           answer: aiResponse.responseText!,
           timestamp: DateTime.now(),
           chatId: state.currentChatId!,
           isUserMessage: false,
           // metadata: aiResponse.metadata, 
         );
         // AI mesajını da Hive'a kaydet
      await _chatService.saveChatMessage(aiMessage);
      }

      // State'i tekrar güncelle (AI mesajı eklendi + durumlar)
      final finalMessages = _chatService.getChatHistoryForSession(state.currentChatId!);
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
        generationStatus: aiResponse.newStatus ?? state.generationStatus,
        requestedDocumentType: aiResponse.documentType ?? state.requestedDocumentType,
        collectedData: aiResponse.collectedData ?? state.collectedData,
        generatedDocumentPath: aiResponse.documentPath ?? state.generatedDocumentPath,
        isAiAsking: aiResponse.isAskingQuestion ?? false,
        errorMessage: aiResponse.error,
      );
      
      // Sohbet başlığını güncelle (ilk mesajdan sonra)
      if (finalMessages.length <= 2 && (state.currentChatTitle == null || state.currentChatTitle == 'Yeni Sohbet')) {
        await _updateChatTitle(text); // Kullanıcının ilk mesajını kullan
      }

    } catch (e) {
       // Hata durumunda sadece yükleniyor durumunu kapat ve hatayı göster
       final currentMessagesOnError = _chatService.getChatHistoryForSession(state.currentChatId!);
      state = state.copyWith(
        messages: currentMessagesOnError, // Kullanıcı mesajı hala listede
        isLoading: false, 
        errorMessage: 'Mesaj işlenirken bir hata oluştu: ${e.toString()}',
        isAiAsking: false,
      );
    }
  }

  // Toplanan bilgileri onaylama (UI'dan çağrılabilir)
  Future<void> confirmCollectedData() async {
     if (state.currentChatId == null || state.generationStatus != DocumentGenerationStatus.awaitingConfirmation || state.requestedDocumentType == null || state.collectedData == null) {
       print("Error: Cannot confirm data. Invalid state or missing info.");
       // Optionally update state with an error message
       // state = state.copyWith(errorMessage: "Belge oluşturma bilgileri eksik.");
       return;
     }

     state = state.copyWith(isLoading: true, isAiAsking: false, generationStatus: DocumentGenerationStatus.generating, errorMessage: null); // Clear previous errors

     try {
       // 1. Generate document text using AI
       print("Generating document text via AI... Type: ${state.requestedDocumentType}");
       // --- Call public method --- 
       final String generatedText = await _chatService.generateDocumentTextFromAI(
         documentType: state.requestedDocumentType!,
         data: state.collectedData!,
       );
       // --- End Call public method ---
       print("AI Text Generation successful (using service method).");

       if (generatedText.isEmpty) {
         throw Exception("AI metin üretemedi.");
       }

       // 2. Call the new Supabase function to generate PDF from text
       print("Invoking Supabase generate-pdf function...");
       final supabase = Supabase.instance.client;
       final response = await supabase.functions.invoke(
         'generate-pdf',
         body: { 'documentContent': generatedText },
       );

       if (response.status != 200 || response.data == null) {
         print("Supabase function error: Status ${response.status}, Data: ${response.data}");
         throw Exception("PDF oluşturma fonksiyonu başarısız oldu: ${response.data?['error'] ?? 'Bilinmeyen hata'}");
       }

       print("Supabase function call successful. Response: ${response.data}");
       final String? generatedPath = response.data['filePath'];
       // final String? publicUrl = response.data['publicUrl']; // Gerekirse public URL de alınabilir

       if (generatedPath == null) {
          throw Exception("PDF oluşturuldu ancak dosya yolu alınamadı.");
       }

       // 3. Update state with success and document path
       ChatMessage? confirmationMessage = ChatMessage(
         question: '',
         answer: 'Belge taslağınız hazırlandı. Yakında indirme bağlantısı görünecektir.', // Update message
         timestamp: DateTime.now(),
         chatId: state.currentChatId!,
         isUserMessage: false,
         // metadata: {'documentPath': generatedPath} // Metadata ile yolu ilet
       );
       await _chatService.saveChatMessage(confirmationMessage);

       final finalMessages = _chatService.getChatHistoryForSession(state.currentChatId!);
       state = state.copyWith(
         messages: finalMessages,
         isLoading: false,
         generationStatus: DocumentGenerationStatus.ready,
         generatedDocumentPath: generatedPath,
         errorMessage: null,
       );
       print("Document generation successful. Path: $generatedPath");

     } catch (e) {
        print("Error during document confirmation: ${e.toString()}");
        final finalMessages = _chatService.getChatHistoryForSession(state.currentChatId!); // Ensure messages are loaded even on error
        state = state.copyWith(
          messages: finalMessages,
          isLoading: false,
          generationStatus: DocumentGenerationStatus.failed,
          errorMessage: 'Belge oluşturulurken hata: ${e.toString()}',
        );
     }
  }

  // Belge oluşturma akışını iptal et/sıfırla (UI'dan çağrılabilir)
  void cancelDocumentFlow() {
    if (state.generationStatus != DocumentGenerationStatus.idle) {
      // İptal mesajını oluştur ve kaydet (opsiyonel)
      final cancellationMessage = ChatMessage(
         question: '',
         answer: 'Belge oluşturma işlemi iptal edildi.',
         timestamp: DateTime.now(),
         chatId: state.currentChatId!, 
         isUserMessage: false, // Sistem mesajı gibi
       );
       _chatService.saveChatMessage(cancellationMessage); // Hata kontrolü eklenebilir

      final finalMessages = _chatService.getChatHistoryForSession(state.currentChatId!); 
      state = state.copyWith(
        messages: finalMessages,
        clearDocumentState: true, 
        isAiAsking: false,
      );
    }
  }

  // Sohbet başlığını güncelle (internal helper)
  Future<void> _updateChatTitle(String firstMessage) async {
    if (state.currentChatId == null) return;
    try {
      final title = firstMessage.length > 40 ? '${firstMessage.substring(0, 37)}...' : firstMessage;
      await _chatService.updateChatSessionTitle(state.currentChatId!, title);
      state = state.copyWith(currentChatTitle: title);
    } catch (e) {
      print("Chat title update failed: $e");
    }
  }
}

// Chat Service Provider (Hive ile)
final chatServiceProvider = Provider<ChatService>((ref) {
  final supabaseClient = Supabase.instance.client; // Doğrudan alabiliriz
  // Hive kutularını aç (main.dart'ta zaten açılıyor olmalı, ama burada erişim lazım)
  final chatHistoryBox = Hive.box<ChatMessage>(HiveBoxes.chatHistory);
  final chatSessionsBox = Hive.box<ChatSession>(HiveBoxes.chatSessions);
  return ChatService(supabaseClient, chatHistoryBox, chatSessionsBox);
});

// Chat Notifier Provider
final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService);
});

// Chat Sessions Notifier Provider
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, ChatSessionsState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  // ChatSessionsNotifier'ın da Hive'a ihtiyacı varsa ChatService'i kullanmalı
  return ChatSessionsNotifier(chatService);
});

// State for the Advisor
@riverpod
class AdvisorNotifier extends _$AdvisorNotifier {
  late final ChatService _chatService;
  final _uuid = const Uuid();

  @override
  AdvisorState build() {
    _chatService = ref.watch(chatServiceProvider);
    // Load initial chat state if needed, or start fresh
    return AdvisorState(); 
  }

  // ... (rest of the methods like processUserMessage, startNewChat etc.)
  // ... Ensure method signatures and logic align with advisor needs ...

    Future<void> processUserMessage(String text) async {
    if (state.status == DocumentGenerationStatus.loading) return; // Prevent sending while loading

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      chatId: state.currentChatId,
      text: text,
      sender: Sender.user,
      timestamp: DateTime.now(),
    );

    // Add user message and set loading state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      status: DocumentGenerationStatus.loading, // Use loading state for AI response
      errorMessage: null,
    );

    try {
      final response = await _chatService.processTurn(
        message: text,
        chatId: state.currentChatId,
        status: state.status,
        mode: 'advisor', // <<< Specify the mode here
        collectedData: state.collectedData,
      );

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        chatId: response.chatId, 
        text: response.responseText,
        sender: Sender.ai,
        timestamp: DateTime.now(),
        isConfirmationRequest: response.isConfirmationRequest,
        pdfUrl: response.pdfUrl, 
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        status: response.newStatus,
        collectedData: response.collectedData, // Update collected data if any
        currentChatId: response.chatId, // Update chatId if it's new
        errorMessage: null,
      );
    } catch (e) {
      print('Error processing message: $e');
      final errorMessage = ChatMessage(
          id: _uuid.v4(),
          chatId: state.currentChatId,
          text: "Bir hata oluştu. Lütfen tekrar deneyin.",
          sender: Sender.ai,
          timestamp: DateTime.now(),
          isError: true
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        status: DocumentGenerationStatus.idle, // Reset to idle on error
        errorMessage: e.toString(),
      );
    } 
  }

  Future<void> startNewChat() async {
    final newChatId = _uuid.v4();
    print('Starting new advisor chat with ID: $newChatId');
    state = AdvisorState(currentChatId: newChatId);
    // Optionally send an initial greeting from AI?
    // await _sendInitialGreeting(newChatId); 
  }

  // Other methods like confirmCollectedData, generatePdf maybe removed or adapted
  // if they are not relevant for the Advisor role.
}

// State object for Advisor
class AdvisorState {
  final List<ChatMessage> messages;
  final DocumentGenerationStatus status;
  final Map<String, dynamic> collectedData;
  final String? errorMessage;
  final String currentChatId;
  final bool isAiAsking; // Derived state

  AdvisorState({
    this.messages = const [],
    this.status = DocumentGenerationStatus.idle,
    this.collectedData = const {},
    this.errorMessage,
    String? currentChatId,
  }) : currentChatId = currentChatId ?? const Uuid().v4(),
       isAiAsking = status == DocumentGenerationStatus.collectingInfo || 
                    status == DocumentGenerationStatus.awaitingConfirmation;

  AdvisorState copyWith({
    List<ChatMessage>? messages,
    DocumentGenerationStatus? status,
    Map<String, dynamic>? collectedData,
    String? errorMessage,
    String? currentChatId,
  }) {
    return AdvisorState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      collectedData: collectedData ?? this.collectedData,
      errorMessage: errorMessage ?? this.errorMessage,
      currentChatId: currentChatId ?? this.currentChatId,
    );
  }
}


// Define the provider itself using the generator
@riverpod
AdvisorNotifier advisorNotifier(AdvisorNotifierRef ref) {
  return AdvisorNotifier(ref);
} 