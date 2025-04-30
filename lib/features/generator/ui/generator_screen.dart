import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
// Import common widgets here at the top
// import '../../advisor/widgets/chat_bubble.dart'; // Remove old incorrect import
// import '../../advisor/widgets/typing_indicator.dart'; // Remove old incorrect import
import 'package:legalai/core/widgets/chat_bubble.dart'; // Correct package import
import 'package:legalai/core/widgets/typing_indicator.dart'; // Correct package import
import './widgets/generator_step_indicator.dart'; // Correct relative path
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import

// --- State Management for Generator ---

// Using the same Message model as Advisor for simplicity
// Potentially create a separate one if generator messages need different fields later
@immutable
class Message {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  // Add optional fields for special message types if needed later
  final String? filePath;
  final String? fileUrl;
  final bool isDocumentLink;

  const Message({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.filePath,
    this.fileUrl,
    this.isDocumentLink = false, // Default to false
  });
}

// Generator State
@immutable
class GeneratorState {
  final List<Message> messages;
  final bool isLoading;
  final String? errorMessage;
  final int currentStep; // Track the current generation step (0-indexed)
  // Add fields to store the result directly in state if needed
  final String? generatedFilePath;
  final String? generatedFileUrl;


  const GeneratorState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentStep = 0, // Start at step 0
    this.generatedFilePath,
    this.generatedFileUrl,
  });

  GeneratorState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? currentStep,
    String? generatedFilePath,
    String? generatedFileUrl,
    bool clearGeneratedInfo = false, // Flag to clear generated file info
  }) {
    return GeneratorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentStep: currentStep ?? this.currentStep,
      generatedFilePath: clearGeneratedInfo ? null : generatedFilePath ?? this.generatedFilePath,
      generatedFileUrl: clearGeneratedInfo ? null : generatedFileUrl ?? this.generatedFileUrl,
    );
  }
}

// Generator Notifier
class GeneratorNotifier extends StateNotifier<GeneratorState> {
  GeneratorNotifier() : super(const GeneratorState());

  final DateFormat timeFormatter = DateFormat('HH:mm');

  // Define steps (adjust if needed)
  final List<String> generationSteps = ["Başlangıç", "Oluşturuluyor", "Tamamlandı"];

  // Start a new generation session
  Future<void> startNewGeneration() async {
    state = const GeneratorState(); // Reset state including step and generated info
    // Add initial greeting message
    _addMessage("Merhaba! Hangi belgeyi oluşturmak istersiniz? Lütfen belge türünü belirtin (örn: Kira Sözleşmesi).", false);
  }

  // Process user message (assume it's the document type request)
  Future<void> processUserMessage(String text) async {
     if (text.trim().isEmpty) return;

    _addMessage(text, true); // Add user message
    state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        clearError: true,
        currentStep: 1, // Move to "Oluşturuluyor" step
        clearGeneratedInfo: true // Clear previous results
    );

    // Simplification: Use the user's text directly as document type
    // Create a minimal data payload. A real app would collect this via forms or conversation.
    final String documentType = text.trim();
    final Map<String, dynamic> requestData = {
        "İstenen Belge Türü": documentType,
        // Add any other default/required fields the AI prompt might need
        "Ek Bilgi": "Kullanıcı tarafından ek bilgi sağlanmadı.",
    };

    try {
      print("Calling generate-document function with type: $documentType");
      final response = await Supabase.instance.client.functions.invoke(
        'generate-document', // The new combined function
        body: {'documentType': documentType, 'data': requestData},
      );

      // Handle success: Extract file path and URL
      final String? filePath = response.data?['filePath'];
      final String? publicUrl = response.data?['publicUrl']; // May be null

      print("Function response: filePath=$filePath, publicUrl=$publicUrl");

      if (filePath != null) {
        // Add a special message indicating the document is ready
         _addMessage(
             "'${documentType}' belgeniz başarıyla oluşturuldu ve kaydedildi.",
             false,
             filePath: filePath,
             fileUrl: publicUrl // Pass URL even if null, UI can handle it
         );
        state = state.copyWith(
          isLoading: false,
          currentStep: 2, // Move to "Tamamlandı" step
          generatedFilePath: filePath,
          generatedFileUrl: publicUrl,
        );
      } else {
        // Handle case where function succeeded but didn't return expected data
        print("Function succeeded but returned null/invalid data: ${response.data}");
        throw Exception("Fonksiyon başarılı oldu ancak geçerli dosya bilgisi dönmedi.");
      }

    } catch (e) {
      print("Error calling generate-document function: $e");
      String errorMessage = "Belge oluşturma sırasında bir hata oluştu.";
      errorMessage = e.toString(); // Use generic toString()

      // Add error message to chat
      _addMessage("Hata: $errorMessage", false);
      state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
          currentStep: 0 // Revert step on error? Or keep at 1? Let's revert for now.
       );
    }
  }

  // Add message to state (now with optional file info)
  void _addMessage(String text, bool isUser, {String? filePath, String? fileUrl}) {
    final message = Message(
      text: text,
      isUserMessage: isUser,
      timestamp: DateTime.now(),
      filePath: filePath, // Store path
      fileUrl: fileUrl, // Store URL
      isDocumentLink: filePath != null, // Mark as document link if path exists
    );
    // Add to the beginning for reverse ListView
    state = state.copyWith(messages: [message, ...state.messages]);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null, clearError: true);
  }
}

// Generator Provider
final generatorNotifierProvider = StateNotifierProvider<GeneratorNotifier, GeneratorState>((ref) {
  return GeneratorNotifier();
});

// --- UI ---
class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generatorNotifierProvider.notifier).startNewGeneration();
    });
  }

  void _handleSendMessage() {
    final text = _controller.text.trim();
    // Allow sending only if not loading AND if current step indicates input is expected (e.g., step 0)
    final currentState = ref.read(generatorNotifierProvider);
    if (text.isNotEmpty && !currentState.isLoading && currentState.currentStep == 0) {
      ref.read(generatorNotifierProvider.notifier).processUserMessage(text);
      _controller.clear();
      FocusScope.of(context).unfocus();
      _scrollToBottom();
    } else if (currentState.isLoading) {
       // Optionally show a snackbar or do nothing if already loading
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Lütfen belgenin oluşturulmasını bekleyin..."), duration: Duration(seconds: 2),)
       );
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
      }    });
  }

  // --- TODO: Add function to handle tapping the document link message ---
  void _handleDocumentTap(String? url, String? path) async {
     if (url != null) {
        print("Attempting to open URL: $url");
        // TODO: Use url_launcher package to open the public URL
        // Example:
        // if (await canLaunchUrl(Uri.parse(url))) {
        //   await launchUrl(Uri.parse(url));
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("URL açılamadı: $url")));
        // }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("URL açma özelliği eklenecek: $url")));
     } else if (path != null) {
         print("Attempting to handle path (e.g., generate signed URL or download): $path");
         // TODO: If URL is null but path exists, need to generate a signed URL or download via Supabase API
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İmzalı URL/İndirme özelliği eklenecek: $path")));
     } else {
         print("Error: No URL or Path provided for document tap.");
     }
  }


  @override
  Widget build(BuildContext context) {
    final generatorState = ref.watch(generatorNotifierProvider);
    final generatorNotifier = ref.read(generatorNotifierProvider.notifier);
    final theme = Theme.of(context);
    // Enable input only if not loading and in the initial step
    final bool canSendMessage = !generatorState.isLoading && generatorState.currentStep == 0;

    ref.listen(generatorNotifierProvider.select((state) => state.messages), (_, __) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
         backgroundColor: Colors.white, // Or AppTheme background
         elevation: 1, // Subtle shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
         title: const Text(
           'Belge Oluşturucu',
           style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600),
                ),
         bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0), // Height for step indicator
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GeneratorStepIndicator(
                steps: generatorNotifier.generationSteps,
                currentStep: generatorState.currentStep,
                ),
            )
         ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
               color: AppTheme.backgroundColor, // Use theme background
              child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                      reverse: true,
                      itemCount: _calculateListItemCount(generatorState),
                      itemBuilder: (context, index) {
                        return _buildListItem(context, index, generatorState, generatorNotifier);
                      },
                    ),
            ),
          ),

          // Message Input Area
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
                        color: canSendMessage ? Colors.white : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: Colors.grey[400]!, width: 1.2),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                         child: TextField(
                           controller: _controller,
                           decoration: InputDecoration(
                            hintText: canSendMessage ? 'Belge türünü yazın...' : (generatorState.isLoading ? 'Oluşturuluyor...' : 'Tamamlandı'),
                             hintStyle: TextStyle(color: Colors.grey[500]),
                             border: InputBorder.none,
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

  int _calculateListItemCount(GeneratorState generatorState) {
    int count = generatorState.messages.length;
    if (generatorState.isLoading && generatorState.currentStep == 1) count++; // Show indicator only during generation step
    if (generatorState.errorMessage != null) count++; // For error message display
    return count;
  }

  Widget _buildListItem(BuildContext context, int index, GeneratorState generatorState, GeneratorNotifier generatorNotifier) {
    int currentItemIndex = 0;

    // 1. Handle Loading Indicator (AI Generating) - Show only in step 1
    if (generatorState.isLoading && generatorState.currentStep == 1) {
      if (index == currentItemIndex) {
         // Use a different indicator? Or the same TypingIndicator?
        return const TypingIndicator();
      }
      currentItemIndex++;
    }

    // 2. Handle Error Message (Similar to AdvisorScreen)
    if (generatorState.errorMessage != null) {
      if (index == currentItemIndex) {
        return _buildErrorMessage(context, generatorState.errorMessage!, generatorNotifier);
      }
      currentItemIndex++;
    }

    // 3. Handle Actual Chat Messages
    final messageIndex = index - currentItemIndex;
    if (messageIndex < 0 || messageIndex >= generatorState.messages.length) {
        return const SizedBox.shrink(); // Should not happen, but safety check
    }

    final message = generatorState.messages[messageIndex];
    final formattedTime = timeFormatter.format(message.timestamp);

    // Check if it's a special document link message
     if (message.isDocumentLink) {
       return _buildDocumentReadyBubble(context, message);
     } else {
        // Regular chat bubble
    return ChatBubble(
      text: message.text,
      isUserMessage: message.isUserMessage,
      timestamp: formattedTime,
      leading: !message.isUserMessage
          ? const CircleAvatar( // Simple AI avatar
              radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.description_outlined, size: 18, color: Colors.white), // Generator icon
            )
              : null,
        );
     }
  }

  // --- Widget Builders for Specific Message Types ---

  Widget _buildDocumentReadyBubble(BuildContext context, Message message) {
     return Container(
       margin: const EdgeInsets.symmetric(vertical: 8.0),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const CircleAvatar( // AI avatar
                 radius: 16,
                 backgroundColor: AppTheme.primaryColor,
                 child: Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
               ),
           const SizedBox(width: 8),
           Flexible(
             child: Material(
               borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18.0),
                  bottomLeft: Radius.circular(18.0),
                  bottomRight: Radius.circular(18.0),
                ),
               elevation: 1.0,
               color: Colors.white, // Or a slightly different color
               child: InkWell( // Make it tappable
                 onTap: () => _handleDocumentTap(message.fileUrl, message.filePath),
                 borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18.0),
                    bottomLeft: Radius.circular(18.0),
                    bottomRight: Radius.circular(18.0),
                  ),
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         message.text, // e.g., "Kira Sözleşmesi belgeniz hazır."
                         style: const TextStyle(fontSize: 15.0, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 8),
                       Row(
                         mainAxisSize: MainAxisSize.min, // Prevent row from taking full width
                         children: [
                           Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryColor.withOpacity(0.8), size: 18),
                           const SizedBox(width: 6),
          Text(
                             "Belgeyi Görüntüle/İndir",
                             style: TextStyle(
                               fontSize: 14.0,
                               color: AppTheme.primaryColor,
                               fontWeight: FontWeight.w500,
                               // decoration: TextDecoration.underline, // Optional underline
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 4),
                       Align(
                         alignment: Alignment.bottomRight,
                         child: Text(
                           timeFormatter.format(message.timestamp),
                           style: TextStyle(fontSize: 11.0, color: Colors.grey[500]),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           ),
           const SizedBox(width: 40), // Ensure bubble doesn't touch the edge
        ],
      ),
    );
  }


  Widget _buildErrorMessage(BuildContext context, String error, GeneratorNotifier advisorNotifier) {
    // Reusing the error display logic from AdvisorScreen, adjust text if needed
    String userFriendlyMessage = 'Bir hata oluştu';
    String detailMessage = error;

    if (error.contains('NetworkError') || error.contains('host lookup') || error.contains('Internet')) {
      userFriendlyMessage = 'Bağlantı hatası';
      detailMessage = 'İnternet bağlantınızı kontrol edin veya fonksiyonun çalıştığından emin olun.';
    }
    else if (error.contains('Function timed out')) {
      userFriendlyMessage = 'Zaman aşımı';
      detailMessage = 'Belge oluşturma işlemi çok uzun sürdü. Lütfen tekrar deneyin.';
    }
    else if (error.contains('AI could not generate text')) {
       userFriendlyMessage = 'AI Metin Oluşturma Hatası';
       detailMessage = 'Yapay zeka istenen belge metnini oluşturamadı. Farklı bir şekilde sormayı deneyin.';
    }
    else if (error.contains('Failed to upload PDF')) {
        userFriendlyMessage = 'Kayıt Hatası';
        detailMessage = 'Oluşturulan belge kaydedilemedi. Lütfen tekrar deneyin.';
    }
    // Add more specific checks based on potential errors from the combined function

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
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  detailMessage,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
                const SizedBox(height: 8),
                 // Only show retry if it makes sense (e.g., not for invalid input errors)
                TextButton.icon(
                   onPressed: () => advisorNotifier.clearError(), // Reuse clearError for now
                  icon: Icon(Icons.refresh, size: 16, color: Colors.red[700]),
                   label: Text('Mesajı Kapat', style: TextStyle(color: Colors.red[700])),
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

} // End of _GeneratorScreenState 