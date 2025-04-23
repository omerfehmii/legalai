import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legalai/features/chat/data/models/chat_message.dart';
import 'package:legalai/features/chat/data/models/chat_session.dart';
import 'package:legalai/main.dart'; // HiveBoxes için

// Supabase client instance'ı için provider (main.dart'ta initialize ediliyor)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Geçici In-Memory storage
class InMemoryStorage {
  static final List<ChatMessage> messages = [];
  static final List<ChatSession> sessions = [];
}

// ChatService için provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  // Hive yerine InMemoryStorage'ı kullan
  // final chatHistoryBox = Hive.box<ChatMessage>(HiveBoxes.chatHistory);
  // final chatSessionsBox = Hive.box<ChatSession>(HiveBoxes.chatSessions);
  return ChatService(supabaseClient);
});

class ChatService {
  final SupabaseClient _supabaseClient;
  // final Box<ChatMessage> _chatHistoryBox;
  // final Box<ChatSession> _chatSessionsBox;

  ChatService(this._supabaseClient);

  // AI'a soru sorma fonksiyonu
  Future<String> askAI(String question, String chatId) async {
    try {
      print('Supabase Edge Function çağrılıyor...');
      
      // Edge Function'ı çağır
      final response = await _supabaseClient.functions.invoke(
        'ai-query', // Edge Function adı
        body: {'question': question}, // Soru parametresi
      );

      if (response.status != 200) {
        // Fonksiyon hata döndürdüyse
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] as String? ?? 'Bilinmeyen bir fonksiyon hatası oluştu.';
        print('Edge Function Error: ${response.status} - $errorMessage');
        throw Exception('Yapay zekadan yanıt alınamadı: $errorMessage');
      }

      // Başarılı yanıttan cevabı al
      final responseData = response.data as Map<String, dynamic>?;
      
      if (responseData == null) {
        throw Exception('Edge Function boş yanıt döndürdü.');
      }
      
      final answer = responseData['answer'] as String?;
      
      if (answer == null) {
        throw Exception('Yapay zeka yanıtı bulunamadı.');
      }

      return answer;
    } catch (e) {
      print('Error calling askAI function: $e');
      
      // Yaygın hata türleri için özel mesajlar
      if (e.toString().contains('NetworkError') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('İnternet bağlantınızı kontrol edin ve tekrar deneyin.');
      }
      
      if (e.toString().contains('400') || e.toString().contains('Bad request')) {
        throw Exception('Supabase Edge Function yanıt hatası. Lütfen daha sonra tekrar deneyin.');
      }
      
      // Hatanın türüne göre daha spesifik mesajlar verilebilir
      if (e is Exception) {
        rethrow; // Yakalanan Exception'ı tekrar fırlat
      }
      throw Exception('Soru gönderilirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Yeni sohbet oturumu oluştur
  Future<ChatSession> createChatSession({String? title}) async {
    try {
      final session = ChatSession.create(title: title);
      // In-memory'de sakla
      InMemoryStorage.sessions.add(session);
      return session;
    } catch (e) {
      print('Error creating chat session: $e');
      rethrow;
    }
  }
  
  // Mevcut sohbetleri al
  List<ChatSession> getChatSessions() {
    try {
      final sessions = InMemoryStorage.sessions;
      // En son oluşturulan sohbeti en üstte göster
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sessions;
    } catch (e) {
      print('Error getting chat sessions: $e');
      return [];
    }
  }
  
  // Belirli bir sohbet oturumunu al
  ChatSession? getChatSessionById(String id) {
    try {
      return InMemoryStorage.sessions.firstWhere((session) => session.id == id);
    } catch (e) {
      print('Error getting chat session by id: $e');
      return null;
    }
  }

  // Sohbet mesajını kaydet
  Future<void> saveChatMessage(ChatMessage message) async {
    try {
      // In-memory'de sakla
      InMemoryStorage.messages.add(message);
      
      // Sohbet oturumunun güncelleme tarihini de güncelle
      final sessionIndex = InMemoryStorage.sessions.indexWhere((s) => s.id == message.chatId);
      if (sessionIndex >= 0) {
        final oldSession = InMemoryStorage.sessions[sessionIndex];
        final updatedSession = ChatSession(
          id: oldSession.id,
          title: oldSession.title,
          createdAt: oldSession.createdAt,
          updatedAt: DateTime.now(),
        );
        InMemoryStorage.sessions[sessionIndex] = updatedSession;
      }
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  // Belirli bir sohbet oturumunun mesajlarını getir
  List<ChatMessage> getChatHistoryForSession(String chatId) {
    try {
      final messages = InMemoryStorage.messages
          .where((message) => message.chatId == chatId)
          .toList();
      // Zaman damgasına göre sıralama
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('Error getting chat history for session: $e');
      return [];
    }
  }

  // Tüm sohbet geçmişini alma
  List<ChatMessage> getAllChatHistory() {
    try {
      // Kutudaki tüm değerleri liste olarak al ve sırala
      final history = InMemoryStorage.messages;
      // Zaman damgasına göre sıralama
      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    } catch (e) {
      print('Error getting all chat history: $e');
      return []; // Hata durumunda boş liste döndür
    }
  }
  
  // Bir sohbet oturumunu sil
  Future<void> deleteChatSession(String chatId) async {
    try {
      // İlgili oturumun mesajlarını sil
      InMemoryStorage.messages.removeWhere((m) => m.chatId == chatId);
      
      // Oturumu sil
      InMemoryStorage.sessions.removeWhere((s) => s.id == chatId);
    } catch (e) {
      print('Error deleting chat session: $e');
      rethrow;
    }
  }
} 