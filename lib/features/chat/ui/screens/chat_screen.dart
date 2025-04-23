import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/features/chat/providers/chat_providers.dart';
import 'package:legalai/features/chat/data/models/chat_message.dart';
// import 'package:legalai/features/chat/ui/widgets/chat_bubble.dart'; // Will define below for now
// import 'package:legalai/features/chat/ui/widgets/message_input.dart'; // Will define below for now
import 'package:legalai/core/theme/app_theme.dart'; // Import theme
// import 'package:legalai/core/widgets/disclaimer_widget.dart'; // Will define below for now
import 'package:intl/intl.dart'; // For date formatting
import 'package:legalai/features/chat/ui/screens/chat_history_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.chatId});
  
  final String? chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }
  
  // Sohbeti başlat veya mevcut sohbeti yükle
  Future<void> _initChat() async {
    if (widget.chatId != null) {
      // Mevcut sohbeti yükle
      await ref.read(chatNotifierProvider.notifier).loadChat(widget.chatId!);
    } else {
      // Yeni sohbet başlat
      await ref.read(chatNotifierProvider.notifier).startNewChat();
    }
  }

  // Mesajı gönder
  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatNotifierProvider.notifier).sendMessage(text);
      _textController.clear();
      
      // Klavyeyi kapat
      FocusScope.of(context).unfocus();
      
      // Mesaj listesini aşağı kaydır (yeni mesaj gönderildiğinde)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primaryColor, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              chatState.currentChatTitle ?? 'Yeni Sohbet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer at top
          Container(
            width: double.infinity,
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Yalnızca bilgilendirme amaçlıdır. Yasal tavsiye yerine geçmez.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Message List
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: chatState.messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    reverse: true,
                    itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0) + 
                              (chatState.errorMessage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Handle loading indicator
                      if (chatState.isLoading && index == 0) {
                        return const _TypingIndicator();
                      }
                      
                      // Handle error message
                      if (chatState.errorMessage != null && index == (chatState.isLoading ? 1 : 0)) {
                        return _buildErrorMessage(context, chatState.errorMessage!, ref);
                      }
                      
                      final messageIndex = index - (chatState.isLoading ? 1 : 0) - 
                                        (chatState.errorMessage != null ? 1 : 0);
                      if (messageIndex < 0 || messageIndex >= chatState.messages.length) {
                        return const SizedBox.shrink();
                      }
                      
                      final message = chatState.messages[chatState.messages.length - 1 - messageIndex];
                      final formattedTime = timeFormatter.format(message.timestamp);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User Question Bubble
                          _ChatBubble(
                            text: message.question,
                            isUserMessage: true,
                            timestamp: formattedTime,
                          ),
                          const SizedBox(height: 4),
                          
                          // AI Answer Bubble
                          if (message.answer.isNotEmpty)
                            _ChatBubble(
                              text: message.answer,
                              isUserMessage: false,
                              timestamp: formattedTime,
                            ),
                            
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
            ),
          ),
          
          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      enabled: !chatState.isLoading,
                    ),
                  ),
                ),
                
                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _textController.text.trim().isNotEmpty && !chatState.isLoading 
                          ? AppTheme.primaryColor 
                          : Colors.grey[400],
                    ),
                    onPressed: _textController.text.trim().isNotEmpty && !chatState.isLoading 
                        ? _handleSendMessage 
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(chatNotifierProvider.notifier).startNewChat();
          _textController.clear();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI asistanınız yardıma hazır',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Sorularınızı sorabilir, metin oluşturabilir veya çeşitli konularda bilgi alabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Error message widget
  Widget _buildErrorMessage(BuildContext context, String error, WidgetRef ref) {
    // Hata mesajını basitleştir
    String userFriendlyMessage = 'Bir hata oluştu';
    String detailMessage = error;
    
    if (error.contains('NetworkError') || error.contains('host lookup') || error.contains('Internet')) {
      userFriendlyMessage = 'Bağlantı hatası';
      detailMessage = 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    } 
    else if (error.contains('Bad request') || error.contains('400')) {
      userFriendlyMessage = 'Sunucu hatası';
      detailMessage = 'AI servisi şu anda cevap veremiyor. Lütfen daha sonra tekrar deneyin.';
    }
    else if (error.contains('Error: OpenAI API')) {
      userFriendlyMessage = 'AI servisi hatası';
      // OpenAI API hata mesajını görüntüle ama teknik detayları kaldır
      final start = error.indexOf('OpenAI API hatası:');
      detailMessage = start >= 0 
          ? error.substring(start + 18).trim() 
          : 'AI servisi geçici olarak kullanılamıyor.';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userFriendlyMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailMessage,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    // Mesaj listesini güncellemek için state'i güncelle
                    ref.read(chatNotifierProvider.notifier).clearError();
                  },
                  icon: Icon(Icons.refresh, size: 16, color: Colors.red[700]),
                  label: Text('Tekrar Dene', 
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Colors.red[50],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modern typing indicator
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 20, right: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(delay: 0),
          const SizedBox(width: 4),
          _buildDot(delay: 0.4),
          const SizedBox(width: 4),
          _buildDot(delay: 0.8),
        ],
      ),
    );
  }

  Widget _buildDot({required double delay}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double opacity = (((_controller.value + delay) % 1.0) < 0.5)
            ? ((_controller.value + delay) % 0.5) * 2
            : 1.0 - (((_controller.value + delay) % 0.5) * 2);
            
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.3 + (opacity * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// Modern Chat Bubble Widget
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final String timestamp;

  const _ChatBubble({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final Color bubbleColor = isUserMessage ? AppTheme.primaryColor : Colors.white;
    final Color textColor = isUserMessage ? Colors.white : AppTheme.textColor;
    
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUserMessage ? 20 : 4),
              bottomRight: Radius.circular(isUserMessage ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 6,
            left: isUserMessage ? 0 : 8,
            right: isUserMessage ? 8 : 0,
          ),
          child: Text(
            timestamp,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }
} 