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
import 'package:legalai/features/advisor/providers/advisor_providers.dart'; // Tam import yolu ile
import 'package:legalai/features/advisor/ui/screens/advisor_history_screen.dart'; // Add import for the history screen
import 'package:legalai/features/advisor/data/models/advisor_session.dart'; // Needed for drawer type

class AdvisorScreen extends ConsumerStatefulWidget {
  final bool startWithDocumentPrompt; // Add argument
  final String? chatId; // Add optional chatId for loading history

  const AdvisorScreen({
    super.key,
    this.chatId, // Initialize chatId
    this.startWithDocumentPrompt = false, // Default to false
  });

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
      // Check if a specific chat needs to be loaded
      if (widget.chatId != null) {
        print("Loading existing chat with ID: ${widget.chatId}"); // Debug log
        ref.read(advisorNotifierProvider.notifier).loadAdvisorChat(widget.chatId!);
      } else {
        // Otherwise, initialize a new chat
        print("Initializing new chat. startWithDocumentPrompt: ${widget.startWithDocumentPrompt}"); // Debug log
        ref.read(advisorNotifierProvider.notifier).initializeChat(
          startWithDocumentPrompt: widget.startWithDocumentPrompt
        );
      }
    });
  }
  
  void _handleSendMessage() {
    final text = _controller.text.trim();
    // Use the renamed provider
    if (text.isNotEmpty && !ref.read(advisorNotifierProvider).isLoading) {
      // Use the renamed method
      ref.read(advisorNotifierProvider.notifier).processAdvisorUserMessage(text);
      _controller.clear();
      FocusScope.of(context).unfocus();
      _scrollToEnd();
    }
  }
      
  void _scrollToEnd() {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
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
    // Use the renamed provider
    final advisorState = ref.watch(advisorNotifierProvider);
    // Use the renamed provider
    final advisorNotifier = ref.read(advisorNotifierProvider.notifier);
    final theme = Theme.of(context);
    final bool canSendMessage = !advisorState.isLoading;
    
    ref.listen(advisorNotifierProvider.select((state) => state.messages), (_, __) {
      _scrollToEnd();
    });

    // Define a slightly different background for document bubbles
    final documentBubbleColor = Theme.of(context).brightness == Brightness.light
        ? Colors.blueGrey[50] // Lighter shade for light theme
        : Colors.blueGrey[800]; // Darker shade for dark theme
    final defaultAssistantBubbleColor = Theme.of(context).brightness == Brightness.light
        ? Colors.grey[200] 
        : Colors.grey[700];

    return Scaffold(
      // Scaffold arka planını kaldır (varsayılana dönsün) veya beyaz yap
      backgroundColor: Colors.white, // Explicitly set to white for clarity
      appBar: AppBar(
        // AppBar arka planını eski rengine getir
        backgroundColor: AppTheme.backgroundColor, 
        elevation: 0, 
        // shape: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)), // Alt çizgi yoktu
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          advisorState.currentChatTitle ?? "AI Danışman",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: AppTheme.primaryColor,
                ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Wrap IconButton with a Builder and use double quotes for tooltip
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history_rounded, color: AppTheme.primaryColor, size: 26),
              tooltip: "Geçmiş Görüşmeler",
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ], // Correct closing bracket for actions
      ), // AppBar closing parenthesis
      // Add the endDrawer property
      endDrawer: const AdvisorHistoryDrawer(), // Use the new drawer widget
      body: Column(
        children: [
          Expanded(
            child: Container(
              // Gradyanı geri ekle
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundColor, // Üst renk
                    Colors.white, // Alt renk
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
              // color: targetBackgroundColor, // Düz rengi kaldır
              child: advisorState.messages.isEmpty && !advisorState.isLoading
                ? _buildEmptyState(context) 
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0), // Yatay padding azaltıldı
                    reverse: false,
                    itemCount: _calculateListItemCount(advisorState),
                    itemBuilder: (context, index) {
                      // Not: defaultAssistantBubbleColor belki Colors.white olmalı bu arka planla?
                      return _buildListItem(context, index, advisorState, documentBubbleColor, defaultAssistantBubbleColor);
                    },
                  ),
            ),
          ),
          
          // --- Input Area --- 
          SafeArea( 
            child: Padding( 
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                            hintText: canSendMessage ? 'Mesajınızı yazın...' : 'AI yanıtlıyor...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true, 
                          // TextField arka planını beyaza geri getir
                          fillColor: Colors.white, 
                          border: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0), 
                          ),
                          enabledBorder: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          ),
                           focusedBorder: OutlineInputBorder( // Odaklanmış kenarlığı değiştir
                            borderRadius: BorderRadius.circular(24.0),
                            // borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5), // Eski odak rengini kaldır
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0), // Odaklansa bile aynı gri ve ince çizgi
                          ),
                          // contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0).copyWith(right: 52.0), // Eski padding
                          contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0).copyWith(right: 52.0), // Dikey padding daha da artırıldı (ikon için yer)
                          // Gönder butonunu suffixIcon olarak ekle
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0), // İkonun sağdan boşluğu
                            child: InkWell(
                              onTap: canSendMessage && _controller.text.trim().isNotEmpty
                                  ? _handleSendMessage
                                  : null,
                              borderRadius: BorderRadius.circular(20.0), // Ripple efekti için
                              child: CircleAvatar(
                                radius: 24, // Buton yarıçapı tekrar artırıldı
                                backgroundColor: canSendMessage && _controller.text.trim().isNotEmpty
                                    ? AppTheme.primaryColor 
                                    : Colors.grey[300], 
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 24, // İkon boyutu tekrar artırıldı
                                ),
                              ),
                            ),
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        onChanged: (text) {
                          setState(() {}); 
                        },
                        onSubmitted: canSendMessage && _controller.text.trim().isNotEmpty ? (_) => _handleSendMessage() : null,
                        enabled: canSendMessage,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textColor),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8), // Buton dışarıdan kaldırıldığı için boşluk silindi
                  
                  // Send Button - Text Field içine taşındı (suffixIcon)
                  // InkWell(
                  //   onTap: canSendMessage && _controller.text.trim().isNotEmpty
                  //       ? _handleSendMessage
                  //       : null,
                  //   borderRadius: BorderRadius.circular(28.0), 
                  //   child: CircleAvatar(
                  //     radius: 28, 
                  //     backgroundColor: canSendMessage && _controller.text.trim().isNotEmpty
                  //         ? AppTheme.primaryColor 
                  //         : Colors.grey[300], 
                  //     child: const Icon(
                  //       Icons.send,
                  //       color: Colors.white,
                  //       size: 28, 
                  //     ),
                  //   ),
                  // ),
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
    // Listenin eleman sayısı = mesajlar + (hata varsa 1) + (yükleniyorsa 1)
    final totalMessages = advisorState.messages.length;
    final hasError = advisorState.errorMessage != null;
    final isLoading = advisorState.isLoading;

    // İndeks mesaj aralığındaysa mesajı göster
    if (index < totalMessages) {
      final message = advisorState.messages[index];
      // final formattedTime = timeFormatter.format(message.timestamp); // Zaman damgası artık kullanılmayacak

      // --- Prepare Text for Display (Applies to both user and AI) ---
      String displayText = message.isUserMessage ? message.question : message.answer;
      bool isDocumentMessage = message.metadata?['isDocumentMessage'] ?? false;
      String? pureDocumentText = message.metadata?['documentText'] as String?;

      if (isDocumentMessage && pureDocumentText != null && !message.isUserMessage) {
          displayText = pureDocumentText
              .replaceAll(RegExp(r"^```legal-document\n?", multiLine: true), "")
              .replaceAll(RegExp(r"\n?```$", multiLine: true), "")
              .trim();
      } else if (isDocumentMessage && !message.isUserMessage) {
           displayText = displayText
              .replaceAll(RegExp(r"^```legal-document\n?", multiLine: true), "")
              .replaceAll(RegExp(r"\n?```$", multiLine: true), "")
              .trim();
      }
      // --- End Prepare Text for Display ---

      // Widget'ı oluştur
      Widget finalItem;

      if (message.isUserMessage) {
        // --- USER MESSAGE (Bubble) ---
        Widget bubbleContent = ChatBubble(
            text: displayText,
            isUserMessage: true,
            timestamp: "", // Timestamp kaldırıldı
        );

        // Zaman damgasını bubble altına ekle - KALDIRILDI
        finalItem = Container(
            margin: EdgeInsets.only(left: 40, right: 12, top: 8, bottom: 8), // Sağ margin daha da azaltıldı
            alignment: Alignment.centerRight, // Hizalamayı geri ekle
            child: bubbleContent, // Sadece bubble
        );

      } else {
        // --- AI MESSAGE (Plain Text, No Bubble, No Icon) ---
        Widget aiTextContent = Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0), 
            child: Text(
                displayText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textColor,
                    height: 1.45,
                ),
            ),
        );

        // AI mesajı belge içeriyorsa butonları altına ekle
        if (isDocumentMessage && pureDocumentText != null) {
            aiTextContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    aiTextContent, 
                    const SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.only(left: 0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          alignment: WrapAlignment.start,
                          children: [
                            // PDF Görüntüle Button
                            ElevatedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                label: const Text("PDF Görüntüle"),
                                onPressed: () {
                                  if (pureDocumentText != null) {
                                    Navigator.push( context, MaterialPageRoute( builder: (context) => PdfViewerScreen( documentContent: pureDocumentText!,),),);
                                  } else { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Görüntülenecek belge metni bulunamadı.")),
 ); }
                                },
                                style: ElevatedButton.styleFrom( backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ),
                            ),
                            // Metni Kopyala Button
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy_outlined, size: 16, color: AppTheme.textColor),
                              label: const Text("Metni Kopyala", style: TextStyle(color: AppTheme.textColor)),
                              onPressed: () => _copyDocumentText(pureDocumentText),
                              style: OutlinedButton.styleFrom( side: BorderSide(color: Colors.grey[300]!), foregroundColor: AppTheme.textColor, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ),
                            ),
                          ],
                        )
                    )
                ],
            );
        }

        // Zaman damgasını metnin/butonların altına ekle - KALDIRILDI
        finalItem = Container(
             margin: EdgeInsets.only(left: 16, right: 40, top: 8, bottom: 8), // Sol margin sabit, sağ artırıldı
             alignment: Alignment.centerLeft,
             child: aiTextContent, // Sadece içerik (metin veya metin+buton)
        );
      }
      return finalItem;
    } 
    // Mesaj indeksinin dışındaysa, hata veya yükleniyor göstergesi olabilir
    else if (hasError && index == totalMessages) {
      // Hata mesajını göster (mesajlardan sonra)
      return _buildErrorMessage(context, advisorState.errorMessage!, ref.read(advisorNotifierProvider.notifier));
    } 
    else if (isLoading && index == totalMessages + (hasError ? 1 : 0)) {
      // Yükleniyor göstergesini göster (mesajlardan ve varsa hatadan sonra)
      return const TypingIndicator();
    } 
    else {
      // Beklenmeyen durum, boş widget döndür
      return const SizedBox.shrink();
    }
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

// --- New Widget for the End Drawer ---
class AdvisorHistoryDrawer extends ConsumerWidget {
  const AdvisorHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(advisorSessionsProvider);
    final sessionNotifier = ref.read(advisorSessionsProvider.notifier);
    final advisorNotifier = ref.read(advisorNotifierProvider.notifier);
    final DateFormat formatter = DateFormat('dd MMM, HH:mm'); // Simple date format

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          AppBar(
            title: const Text('Geçmiş Görüşmeler'),
            titleTextStyle: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            automaticallyImplyLeading: false, // Remove back button from drawer header
            actions: [
               IconButton(
                 icon: const Icon(Icons.close, color: AppTheme.primaryColor),
                 tooltip: 'Kapat',
                 onPressed: () => Navigator.pop(context), // Close the drawer
               ),
             ],
          ),
          // Body of the Drawer (List or States)
          Expanded(
            child: _buildDrawerBody(context, sessionsState, sessionNotifier, advisorNotifier, formatter, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerBody(
    BuildContext context,
    AdvisorSessionsState sessionsState,
    AdvisorSessionsNotifier sessionNotifier,
    AdvisorNotifier advisorNotifier,
    DateFormat formatter,
    WidgetRef ref,
  ) {
    if (sessionsState.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (sessionsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Hata: ${sessionsState.errorMessage!}', textAlign: TextAlign.center),
        ),
      );
    }

    if (sessionsState.sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Kaydedilmiş görüşme yok.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Session List
    return ListView.builder(
      padding: EdgeInsets.zero, // Remove padding for drawer list
      itemCount: sessionsState.sessions.length,
      itemBuilder: (context, index) {
        final session = sessionsState.sessions[index];
        return ListTile(
           leading: const Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.secondaryColor),
           title: Text(
             session.title,
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             style: const TextStyle(fontWeight: FontWeight.w500),
           ),
           subtitle: Text(
             formatter.format(session.updatedAt),
             style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
           ),
           onTap: () {
             Navigator.pop(context); // Close the drawer
             // Check if the tapped chat is already loaded
             if (ref.read(advisorNotifierProvider).currentChatId != session.id) {
                 advisorNotifier.loadAdvisorChat(session.id); // Load the selected chat
             }
           },
           // Simple trailing icon, maybe add delete later if needed
           // trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        );
      },
    );
  }
} 