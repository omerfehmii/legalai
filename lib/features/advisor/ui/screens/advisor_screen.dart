import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:legalai/features/chat/providers/chat_providers.dart'; // Removed
// import 'package:legalai/features/chat/data/models/chat_message.dart'; // Removed
// import 'package:legalai/features/chat/ui/widgets/chat_bubble.dart'; // Will define below for now
// import 'package:legalai/features/chat/ui/widgets/message_input.dart'; // Will define below for now
import 'package:legalai/core/theme/app_theme.dart'; // Import theme
// import 'package:legalai/core/widgets/disclaimer_widget.dart'; // Will define below for now
import 'package:intl/intl.dart'; // For date formatting
// import 'package:legalai/features/chat/ui/screens/chat_history_screen.dart'; // Removed
// Gerekirse indirme/paylaşma için importlar
// import 'package:open_filex/open_filex.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase import
import 'package:url_launcher/url_launcher.dart';
import 'package:legalai/core/widgets/chat_bubble.dart';
import 'package:legalai/core/widgets/typing_indicator.dart';
import '../widgets/generating_indicator.dart';
import '../widgets/confirmation_card.dart';
import '../widgets/document_ready_bubble.dart';
import 'package:legalai/screens/pdf_viewer_screen.dart'; // Import PdfViewerScreen

// --- New State Management ---

// 1. Message Model (Updated)
@immutable
class Message {
  final String id; // Add unique ID for messages
  final String text; // Full text including markdown/intro
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isDocumentMessage; // Flag for messages containing ```legal-document
  final String? pureDocumentText; // Extracted text within the block

  Message({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.isDocumentMessage = false,
    this.pureDocumentText,
  }) : id = UniqueKey().toString(); // Generate a unique ID
}

// 2. Advisor State
@immutable
class AdvisorState {
  final List<Message> messages;
  final bool isLoading;
  final String? errorMessage;
  final String currentChatTitle; // Simple title for now

  const AdvisorState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentChatTitle = 'AI Danışman', // Default title
  });

  AdvisorState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false, // Flag to explicitly clear error
    String? currentChatTitle,
  }) {
    return AdvisorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentChatTitle: currentChatTitle ?? this.currentChatTitle,
    );
  }
}

// 3. Advisor Notifier (Updated _addMessage)
class AdvisorNotifier extends StateNotifier<AdvisorState> {
  AdvisorNotifier() : super(const AdvisorState());

  final DateFormat timeFormatter = DateFormat('HH:mm'); // Keep formatter here or pass

  // Initialize or start a new chat (simplified)
  Future<void> startNewChat() async {
    state = const AdvisorState(); // Reset state for a new chat
    // Optional: Add an initial greeting message from AI
    // _addMessage("Merhaba! Size nasıl yardımcı olabilirim?", false);
  }

  // Regex to find the legal-document block
  // It captures the content between ```legal-document and ```
  final _documentRegex = RegExp(
      r"```legal-document([\s\S]*?)```",
      multiLine: true, // Allows . to match newline characters
  );


  // Process user message
  Future<void> processUserMessage(String text) async {
    if (text.trim().isEmpty) return; // Prevent empty messages

     // Add user message (no parsing needed)
    _addMessage(text, true);

    // Get current state *after* adding the user message
    final currentState = state;
    final messagesToSend = currentState.messages; // Already includes the new user message

    // Limit the history to the last N messages (e.g., 6)
    // Since messages are prepended, take the first N. Reverse to maintain chronological order for the API.
    final historyMessages = messagesToSend.take(6).toList().reversed.toList();

    // Format history for the backend (role and content)
    final formattedHistory = historyMessages.map((msg) {
      // Send the full text for context, AI will handle it
      return {'role': msg.isUserMessage ? 'user' : 'assistant', 'content': msg.text};
    }).toList();

    // Remove the *latest* user message from the history list,
    // as we will send it as the main 'query' or add it separately in the backend.
    // Let's keep it simple for now and send the *entire* formattedHistory including the last user message.
    // The backend will need to handle this structure. We'll refine this if needed.

    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);

    try {
      // --- Call Supabase Edge Function with history ---
      print("Sending history: ${formattedHistory}"); // Debug print

      final response = await Supabase.instance.client.functions.invoke(
        'legal-query', // Ensure this matches your function name
        // Send the formatted history list
         body: {'history': formattedHistory},
      );
      // --- End of Supabase call ---

      final aiResponseText = response.data['answer'] as String? ?? "AI'dan geçerli bir yanıt alınamadı.";

      // Add AI response, _addMessage will handle document parsing
      _addMessage(aiResponseText, false);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      print("Error getting AI response: $e");
      final String errorMessage = e.toString(); // Use generic toString()

      state = state.copyWith(isLoading: false, errorMessage: "AI servisinden yanıt alınamadı: $errorMessage");
       // Add a simple error message bubble
      _addMessage("Üzgünüm, bir hata oluştu: $errorMessage", false);
    }
  }

  // Add message to state (Updated to parse document block)
  void _addMessage(String text, bool isUser) {
    bool isDocMsg = false;
    String? pureDocText;

    if (!isUser) { // Only process AI messages for the block
      final match = _documentRegex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        isDocMsg = true;
        // Group 1 contains the content inside the block
        pureDocText = match.group(1)?.trim();
         print("Document block found. Extracted text length: ${pureDocText?.length}");
      }
    }

    final message = Message(
      text: text, // Store the full original text
      isUserMessage: isUser,
      timestamp: DateTime.now(),
      isDocumentMessage: isDocMsg,
      pureDocumentText: pureDocText,
    );

    state = state.copyWith(messages: [message, ...state.messages]);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null, clearError: true);
  }

  // Cancel flow (placeholder - might not be needed anymore)
  /*
  void cancelDocumentFlow() {
     print("Document flow cancelled (placeholder)");
     // Reset state if needed, e.g., remove confirmation prompts
     state = state.copyWith(isLoading: false, errorMessage: null); // Basic reset
  }
  */
}

// 4. Provider
final advisorNotifierProvider = StateNotifierProvider<AdvisorNotifier, AdvisorState>((ref) {
  return AdvisorNotifier();
});

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat timeFormatter = DateFormat('HH:mm');
  // State to track PDF generation loading for specific messages
  final Map<String, bool> _pdfLoadingStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(advisorNotifierProvider.notifier).startNewChat();
    });
  }
  
  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !ref.read(advisorNotifierProvider).isLoading) {
      ref.read(advisorNotifierProvider.notifier).processUserMessage(text);
      _controller.clear();
      FocusScope.of(context).unfocus();
      _scrollToBottom(); 
    }
  }
      
  void _scrollToBottom() {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
  }

  // --- Action Handlers ---

  // Copy document text to clipboard
  void _copyDocumentText(String? text) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belge metni panoya kopyalandı."), duration: Duration(seconds: 2)),
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Kopyalanacak metin bulunamadı."), duration: Duration(seconds: 2)),
       );
    }
  }

  // Generate PDF and show viewer (Updated to handle loading state)
  Future<void> _generateAndShowPdf(String messageId, String? documentContent) async {
    if (documentContent == null || documentContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF oluşturmak için belge içeriği bulunamadı.')),
      );
      return;
    }

    // Set loading state for this specific message
    setState(() {
      _pdfLoadingStates[messageId] = true;
    });

    try {
      // Navigate to PdfViewerScreen - it handles the generation internally
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => PdfViewerScreen(documentContent: documentContent),
         ),
       );
        // Note: PdfViewerScreen now handles its own loading/error states internally
        // We just need to track the *initiation* of the process here.

    } catch (e) {
       // Although PdfViewerScreen handles its errors, catch potential navigation errors
       print("Error navigating to PDF Viewer: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF görüntüleyici açılamadı: ${e.toString()}')),
       );
    } finally {
      // Reset loading state for this message regardless of success/failure
      setState(() {
        _pdfLoadingStates[messageId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final advisorState = ref.watch(advisorNotifierProvider);
    final advisorNotifier = ref.read(advisorNotifierProvider.notifier);
    final theme = Theme.of(context);
    final bool canSendMessage = !advisorState.isLoading;
    
    ref.listen(advisorNotifierProvider.select((state) => state.messages), (_, __) {
      _scrollToBottom();
    });

    // Define a slightly different background for document bubbles
    final documentBubbleColor = Theme.of(context).brightness == Brightness.light
        ? Colors.blueGrey[50] // Lighter shade for light theme
        : Colors.blueGrey[800]; // Darker shade for dark theme
    final defaultAssistantBubbleColor = Theme.of(context).brightness == Brightness.light
        ? Colors.grey[200]
        : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
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
            Expanded(
              child: Text(
              advisorState.currentChatTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppTheme.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Simplified actions
          // Remove conditional close button related to old generationStatus
          // if (advisorState.generationStatus != DocumentGenerationStatus.idle)
          //   IconButton(
          //     icon: const Icon(Icons.close, color: Colors.redAccent),
          //     tooltip: 'Belge Akışını İptal Et',
          //     onPressed: () => advisorNotifier.cancelDocumentFlow(), // Keep method call if needed elsewhere or remove
          //   ),
        ],
      ),
      body: Column(
        children: [
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
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundColor,
                    Colors.white,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
              child: advisorState.messages.isEmpty && !advisorState.isLoading
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    reverse: true,
                    itemCount: _calculateListItemCount(advisorState),
                    itemBuilder: (context, index) {
                      return _buildListItem(context, index, advisorState, documentBubbleColor, defaultAssistantBubbleColor);
                    },
                  ),
            ),
          ),
          
          // Message Input Area - Improved Style (Matches GeneratorScreen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: Colors.grey[400]!, width: 1.2),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                              hintText: canSendMessage ? 'Mesajınızı yazın...' : 'AI yanıtlıyor...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          onSubmitted: canSendMessage ? (_) => _handleSendMessage() : null,
                          enabled: canSendMessage,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: canSendMessage && _controller.text.trim().isNotEmpty
                        ? _handleSendMessage
                        : null,
                    borderRadius: BorderRadius.circular(24.0),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: canSendMessage && _controller.text.trim().isNotEmpty
                          ? AppTheme.primaryColor
                          : Colors.grey[300],
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int _calculateListItemCount(AdvisorState advisorState) {
    int count = advisorState.messages.length;
    if (advisorState.isLoading) count++; // For typing indicator
    if (advisorState.errorMessage != null) count++; // For error message
    // Removed counts related to generationStatus
    // if (advisorState.generationStatus == DocumentGenerationStatus.awaitingConfirmation) count++;
    // if (advisorState.generationStatus == DocumentGenerationStatus.ready) count++;
    // if (advisorState.generationStatus == DocumentGenerationStatus.generating) count++;
    return count;
  }

  // Updated to build list items including document actions
  Widget _buildListItem(BuildContext context, int index, AdvisorState advisorState, Color? documentBubbleColor, Color? defaultAssistantBubbleColor) {
    int currentItemIndex = 0;

    // 1. Handle Loading Indicator
    if (advisorState.isLoading) {
       if (index == currentItemIndex) {
         return const TypingIndicator();
       }
       currentItemIndex++;
    }

    // 2. Handle Error Message
    if (advisorState.errorMessage != null) {
       if (index == currentItemIndex) {
        // Ensure notifier is accessible if needed, or simplify error widget
        return _buildErrorMessage(context, advisorState.errorMessage!, ref.read(advisorNotifierProvider.notifier));
       }
       currentItemIndex++;
    }

    // 3. Handle Actual Chat Messages
    final messageIndex = index - currentItemIndex;
    if (messageIndex < 0 || messageIndex >= advisorState.messages.length) {
      return const SizedBox.shrink();
    }

    final message = advisorState.messages[messageIndex];
    final formattedTime = timeFormatter.format(message.timestamp);
    // Get loading state for this specific message's PDF generation
    final bool isCurrentlyGeneratingPdf = _pdfLoadingStates[message.id] ?? false;


    // --- Prepare Text for Display --- 
    String displayText = message.text;
    if (message.isDocumentMessage) {
        // Remove the markdown code block tags for cleaner display
        displayText = message.text
            .replaceAll(RegExp(r"^```legal-document\n?", multiLine: true), "") // Remove starting tag
            .replaceAll(RegExp(r"\n?```$", multiLine: true), "") // Remove ending tag
            .trim(); 
        // Optionally, only show the intro + extracted text, depends on desired look
        // Example: Find intro text before block
        // final introEnd = message.text.indexOf("```legal-document");
        // final introText = introEnd >= 0 ? message.text.substring(0, introEnd).trim() : "";
        // displayText = "$introText\n\n${message.pureDocumentText ?? ''}"; 
    }
    // --- End Prepare Text for Display ---

    // Build the core chat bubble using displayText
    Widget chatContent = ChatBubble(
       text: displayText, // Use the cleaned text for display
      isUserMessage: message.isUserMessage,
      timestamp: formattedTime,
      leading: !message.isUserMessage
           ? const CircleAvatar(
              radius: 16,
               backgroundColor: AppTheme.primaryColor,
               child: Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white),
             )
           : null,
     );

    // If it's a document message, wrap with Column and add buttons
    if (message.isDocumentMessage && message.pureDocumentText != null) {
       chatContent = Column(
          crossAxisAlignment: message.isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
             chatContent, // The original chat bubble
             const SizedBox(height: 8),
             Padding(
               // Align buttons under the bubble
               padding: EdgeInsets.only(left: message.isUserMessage ? 0 : 40, right: message.isUserMessage ? 0 : 0),
               child: Wrap( // Use Wrap for better responsiveness if buttons are long
                 spacing: 8.0, // Horizontal space between buttons
                 runSpacing: 4.0, // Vertical space if buttons wrap
                 alignment: WrapAlignment.start, // Align to the start (left for AI, right for user potentially)
                 children: [
                   ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text("PDF Görüntüle"),
                      onPressed: () {
                         if (message.pureDocumentText != null) {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => PdfViewerScreen(
                                 documentContent: message.pureDocumentText!,
                               ),
                             ),
                           );
                         } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Görüntülenecek belge metni bulunamadı.")),
                            );
                         }
                       },
                      style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: const Text("Metni Kopyala"),
                      onPressed: () => _copyDocumentText(message.pureDocumentText),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                        foregroundColor: AppTheme.primaryColor,
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                 ],
               ),
             )
          ],
       );
     }

    return chatContent;
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0), // Add some horizontal padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[300]), // Larger, different icon
            const SizedBox(height: 24),
            Text(
              'AI Danışmanınız yardıma hazır.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 8),
             Text(
              'Hukuki bir konuda bilgi almak, bir metni analiz etmek veya bir soru sormak için mesajınızı yazın.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage(BuildContext context, String error, AdvisorNotifier advisorNotifier) {
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
                  onPressed: () => advisorNotifier.clearError(),
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