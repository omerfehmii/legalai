import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/features/chat/data/models/chat_message.dart';
import 'package:legalai/features/chat/data/models/chat_session.dart';
import 'package:legalai/features/chat/services/chat_service.dart';

// Chat State'ini temsil eden sınıf
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final String? currentChatId;
  final String? currentChatTitle;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentChatId,
    this.currentChatTitle,
  });

  // Kolaylık sağlamak için state'i kopyalayıp güncelleyen metot
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    String? currentChatId,
    String? currentChatTitle,
    bool clearError = false, // Hata mesajını temizlemek için flag
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentChatId: currentChatId ?? this.currentChatId,
      currentChatTitle: currentChatTitle ?? this.currentChatTitle,
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
      // Önceki sohbet verilerini temizle
      state = ChatState(isLoading: true);
      
      // Yeni bir sohbet oturumu oluştur
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
    state = state.copyWith(isLoading: true, currentChatId: chatId);
    try {
      // Mevcut sohbet oturumunu bul
      final session = _chatService.getChatSessionById(chatId);
      if (session == null) {
        throw Exception('Sohbet bulunamadı.');
      }
      
      // Sohbet mesajlarını yükle
      final messages = _chatService.getChatHistoryForSession(chatId);
      
      // State'i güncelle
      state = state.copyWith(
        messages: messages, 
        currentChatTitle: session.title,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Sohbet yüklenemedi.', isLoading: false);
    }
  }

  // Hata mesajını temizle
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Yeni bir mesaj gönder
  Future<void> sendMessage(String question) async {
    if (state.currentChatId == null) {
      // Eğer aktif bir sohbet yoksa, yeni sohbet oluştur
      await startNewChat();
      if (state.currentChatId == null) {
        // Hala sohbet oluşturulamadıysa çık
        return;
      }
    }
    
    // Kullanıcının sorusunu hemen ekle (optimistic UI)
    final userMessage = ChatMessage(
      question: question, 
      answer: '', 
      timestamp: DateTime.now(),
      chatId: state.currentChatId!,
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMessage], 
      isLoading: true, 
      clearError: true,
    );

    try {
      // AI'dan cevabı al
      final answer = await _chatService.askAI(question, state.currentChatId!);

      // Soru-cevap çiftini oluştur ve Hive'a kaydet
      final aiMessage = ChatMessage(
        question: question,
        answer: answer,
        timestamp: DateTime.now(),
        chatId: state.currentChatId!,
      );
      await _chatService.saveChatMessage(aiMessage);

      // State'i güncelle - son kullanıcı mesajını AI cevabıyla güncelle
      final updatedMessages = List<ChatMessage>.from(state.messages);
      // Son eklenen userMessage'ı kaldır
      updatedMessages.removeLast();
      // Yeni AI mesajını ekle
      updatedMessages.add(aiMessage);
      
      state = state.copyWith(messages: updatedMessages, isLoading: false);
    } catch (e) {
      // Hata durumunda state'i güncelle
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }
}

// ChatNotifier için StateNotifierProvider
final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService);
});

// ChatSessions için StateNotifierProvider
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, ChatSessionsState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatSessionsNotifier(chatService);
}); 