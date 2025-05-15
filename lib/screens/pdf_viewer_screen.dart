import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:legalai/features/documents/services/document_generation_service.dart';
import 'package:legalai/features/documents/data/models/saved_document.dart';
import 'package:legalai/core/theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? documentContent;
  final String? pdfPath;

  // Constructor for creating PDF from document content
  const PdfViewerScreen({Key? key, required this.documentContent})
      : pdfPath = null,
        super(key: key);

  // Constructor for loading PDFs from a path
  const PdfViewerScreen.fromPath({Key? key, required this.pdfPath})
      : documentContent = null,
        super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfData;
  String? _tempPdfPath;
  String _documentTitle = "Belge";
  String _infoMessage = "";
  bool _showInfo = false;
  int _currentPage = 1;
  int _totalPages = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for UI animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    if (widget.pdfPath != null) {
      _loadPdfFromPath(widget.pdfPath!);
    } else if (widget.documentContent != null) {
      _generatePdfLocally();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Belge içeriği veya dosya yolu bulunamadı';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _generatePdfLocally() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = "PDF dosyanız hazırlanıyor...";
      _showInfo = true;
    });
    
    try {
      // Use the document generation service to create a PDF from content
      final documentGenerationService = DocumentGenerationService();
      
      // Generate a sensible title from content
      _documentTitle = _extractSuggestedName();
      
      // Call the service to generate PDF
      final pdfPath = await documentGenerationService.generatePdfFromContent(
        widget.documentContent!, 
        _documentTitle
      );
      
      // Read the generated PDF file
      final file = File(pdfPath);
      _pdfData = await file.readAsBytes();
      
      // Store the path for viewing
      _tempPdfPath = pdfPath;
      
      // Update state
      setState(() {
        _isLoading = false;
        _showInfo = false;
      });
      
      // Start animation
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'PDF oluşturulurken bir hata oluştu: ${e.toString()}';
        _showInfo = false;
      });
    }
  }

  Future<void> _loadPdfFromPath(String pdfPath) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = "PDF dosyanız yükleniyor...";
      _showInfo = true;
    });
    
    try {
      // Check if file exists
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF dosyası bulunamadı: $pdfPath');
      }
      
      // Read the file
      _pdfData = await file.readAsBytes();
      _tempPdfPath = pdfPath;
      
      // Extract filename for display
      _documentTitle = pdfPath.split('/').last.split('.').first;
      
      setState(() {
        _isLoading = false;
        _showInfo = false;
      });
      
      // Start animation
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'PDF yüklenirken bir hata oluştu: ${e.toString()}';
        _showInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: _tempPdfPath != null,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _tempPdfPath != null 
          ? Colors.black.withOpacity(0.7)
          : AppTheme.backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _tempPdfPath != null ? Colors.white.withOpacity(0.2) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _tempPdfPath == null ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ] : [],
          ),
          child: Icon(
            Icons.arrow_back,
            color: _tempPdfPath != null ? Colors.white : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _documentTitle,
        style: TextStyle(
          color: _tempPdfPath != null ? Colors.white : AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (_tempPdfPath != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, color: Colors.white, size: 20),
            ),
            onPressed: _sharePdf,
          ),
        if (_tempPdfPath != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.save_alt, color: Colors.white, size: 20),
              ),
              onPressed: _savePdf,
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_errorMessage != null) {
      return _buildErrorState();
    } else if (_tempPdfPath != null) {
      return _buildPdfViewer();
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          if (_showInfo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _infoMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hata Oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              label: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: widget.documentContent != null ? _generatePdfLocally : () {
                if (widget.pdfPath != null) {
                  _loadPdfFromPath(widget.pdfPath!);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf,
              color: Colors.grey[400],
              size: 72,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PDF Dosyası Bulunamadı',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'PDF dosyanız yüklenirken bir sorun oluştu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.home, color: Colors.white, size: 20),
            label: const Text('Ana Sayfaya Dön', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // PDF Viewer
          SfPdfViewer.file(
            File(_tempPdfPath!),
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            canShowScrollHead: false,
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
            },
            pageLayoutMode: PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.vertical,
          ),
          
          // Page indicator overlay on top of PDF
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show when PDF is loaded
    if (_tempPdfPath == null) return null;
    
    return FloatingActionButton.extended(
      onPressed: _openPdfWithSystemViewer,
      backgroundColor: AppTheme.secondaryColor,
      elevation: 4,
      icon: const Icon(Icons.open_in_new, color: Colors.white),
      label: const Text('Harici Görüntüleyici', style: TextStyle(color: Colors.white)),
    );
  }

  Widget? _buildBottomBar() {
    // Only show bottom bar when there's no PDF loaded
    if (_tempPdfPath != null) return null;
    
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                label: const Text('Geri Dön', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (widget.documentContent != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  label: const Text('Yenile', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _generatePdfLocally,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Open PDF with system viewer
  Future<void> _openPdfWithSystemViewer() async {
    if (_tempPdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görüntülenecek PDF dosyası bulunamadı')),
      );
      return;
    }

    try {
      // Use open_filex to open the PDF with system viewer
      final result = await OpenFilex.open(_tempPdfPath!);
      
      if (result.type != ResultType.done) {
        throw Exception("Dosya açılamadı: ${result.message}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF açılırken bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // PDF Saving Logic
  Future<void> _savePdf() async {
    if (_pdfData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek PDF bulunamadı')),
      );
      return;
    }

    // Extract a suggested name from the document content
    String suggestedName = _documentTitle;
    
    // Show dialog to get document name from user
    final String? documentName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String inputName = suggestedName; // Start with the suggested name
        
        return AlertDialog(
          title: const Text('Belgeyi Kaydet'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Belgeniz için bir isim girin:'),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: inputName),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Belge adı',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  inputName = value;
                },
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(inputName);
              },
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
    
    // If user cancelled, return without saving
    if (documentName == null || documentName.trim().isEmpty) {
      return;
    }

    try {
      setState(() {
        _infoMessage = "Belge kaydediliyor...";
        _showInfo = true;
      });
      
      // 1. Get Application Documents Directory
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // 2. Create a valid filename from the document name
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final sanitizedName = _sanitizeFilename(documentName);
      final fileName = '${sanitizedName}_$timestamp.pdf';
      final filePath = '$path/$fileName';

      // 3. Write PDF Data to File
      final file = File(filePath);
      await file.writeAsBytes(_pdfData!, flush: true);

      // 4. Create SavedDocument and store in Hive
      final savedDocument = SavedDocument(
        title: documentName,
        documentType: _inferDocumentType(widget.documentContent),
        collectedData: {},
        pdfPath: filePath,
        generatedContent: widget.documentContent,
      );
      
      // Get the box if it's already open, otherwise open it
      Box<SavedDocument> box;
      try {
        if (Hive.isBoxOpen('saved_documents')) {
          box = Hive.box<SavedDocument>('saved_documents');
        } else {
          box = await Hive.openBox<SavedDocument>('saved_documents');
        }
        
        // Save the document
        await box.put(savedDocument.id, savedDocument);
      } catch (e) {
        // Try a simpler approach by just writing to a file if Hive fails
        print('Error saving to Hive: $e');
      }

      setState(() {
        _showInfo = false;
      });

      // 5. Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$documentName başarıyla kaydedildi'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _showInfo = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF kaydedilirken bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // PDF Sharing Logic
  Future<void> _sharePdf() async {
    if (_tempPdfPath == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşılacak PDF bulunamadı')),
      );
      return;
    }

    try {
      setState(() {
        _infoMessage = "Belge paylaşılmaya hazırlanıyor...";
        _showInfo = true;
      });
      
      // Share the File using share_plus
      final xFile = XFile(_tempPdfPath!); // Create XFile from path
      await Share.shareXFiles(
        [xFile],
        text: _documentTitle,
      );
      
      setState(() {
        _showInfo = false;
      });
    } catch (e) {
      setState(() {
        _showInfo = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF paylaşılırken bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  // Helper method to infer the document type from content
  String _inferDocumentType(String? content) {
    if (content == null) {
      return 'Hukuki Belge';
    }
    
    final lowerContent = content.toLowerCase();
    
    // Check for common document types in the content
    if (lowerContent.contains('kira') || lowerContent.contains('kiralama')) {
      return 'Kira Sözleşmesi';
    } else if (lowerContent.contains('iş') && lowerContent.contains('sözleşme')) {
      return 'İş Sözleşmesi';
    } else if (lowerContent.contains('satış') || lowerContent.contains('alım')) {
      return 'Alım Satım Sözleşmesi';
    } else if (lowerContent.contains('vekaletname')) {
      return 'Vekaletname';
    } else if (lowerContent.contains('ihtar') || lowerContent.contains('ihtarname')) {
      return 'İhtarname';
    } else if (lowerContent.contains('borç') && lowerContent.contains('makbuz')) {
      return 'Borç Makbuzu';
    } else if (lowerContent.contains('ibraname')) {
      return 'İbraname';
    } else if (lowerContent.contains('vasiyetname')) {
      return 'Vasiyetname';
    } else if (lowerContent.contains('dilekçe')) {
      return 'Dilekçe';
    }
    
    // Default if no specific type is found
    return 'Hukuki Belge';
  }

  // Extract a suggested name from the document content
  String _extractSuggestedName() {
    // First try to extract a title from the first few lines of document content
    try {
      // Check if we have access to the original document text
      if (widget.documentContent != null && widget.documentContent!.isNotEmpty) {
        // Take the first line, or first sentence that ends with a period
        final firstLines = widget.documentContent!.split('\n').take(3).join(' ');
        final firstSentence = firstLines.split('.').first.trim();
        
        // If the first sentence is reasonably short, use it as the suggested name
        if (firstSentence.length > 5 && firstSentence.length < 50) {
          return firstSentence;
        }
      }
    } catch (e) {
      print('Error extracting suggested name: $e');
    }
    
    // Fallback: Use generic name with timestamp
    return 'Hukuki Belge ${DateFormat('dd.MM.yyyy').format(DateTime.now())}';
  }
  
  // Sanitize filename to remove invalid characters
  String _sanitizeFilename(String input) {
    // Replace characters that are invalid in filenames with underscores
    final sanitized = input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') // Windows/Unix invalid chars
        .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores
    
    // Limit length to avoid too long filenames
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }
} 