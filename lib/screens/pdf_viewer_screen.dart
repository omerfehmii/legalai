import 'dart:async'; // Import Completer
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:pdfx/pdfx.dart'; // Remove pdfx import
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import flutter_pdfview
import 'package:path_provider/path_provider.dart'; // Add path_provider
import 'package:uuid/uuid.dart'; // Add uuid
import 'package:hive/hive.dart'; // Add Hive
import 'dart:io'; // Add dart:io for File operations
import 'package:share_plus/share_plus.dart'; // Add share_plus
import 'package:intl/intl.dart'; // Add intl for date formatting
import 'package:open_filex/open_filex.dart'; // Add open_filex for opening PDF with system viewer
import 'package:legalai/features/documents/services/document_generation_service.dart'; // Add document generation service
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Add syncfusion pdf viewer
import 'package:legalai/features/documents/data/models/saved_document.dart'; // Import SavedDocument model

class PdfViewerScreen extends StatefulWidget {
  final String? documentContent;
  final String? pdfPath;

  // Constructor for creating PDF from document content
  const PdfViewerScreen({Key? key, required this.documentContent})
      : pdfPath = null,
        super(key: key);

  // New constructor for loading PDFs from a path
  const PdfViewerScreen.fromPath({Key? key, required this.pdfPath})
      : documentContent = null,
        super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // Remove PdfController from pdfx
  // PdfController? _pdfController;

  // Add state variables for flutter_pdfview
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;

  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfData; // Keep PDF bytes
  String? _tempPdfPath; // Path to the temporary PDF file for viewing
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.pdfPath != null) {
      _loadPdfFromPath(widget.pdfPath!);
    } else if (widget.documentContent != null) {
      _generatePdfLocally(); // Use local PDF generation by default
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Belge içeriği veya dosya yolu bulunamadı.';
      });
    }
  }

  @override
  void dispose() {
    // No explicit dispose needed for PDFViewController via Completer usually
    super.dispose();
  }

  Future<void> _generateAndLoadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      isReady = false; // Reset readiness
    });

    try {
      // 1. Call the Supabase Edge Function (remains the same)
      print('Calling generate-pdf function...');
      final response = await Supabase.instance.client.functions.invoke(
        'generate-pdf',
        body: {'documentContent': widget.documentContent},
      );

      print('Function response status: ${response.status}');
      // Debug log the full response
      print('Function full response: ${response.data}');

      if (response.status != 200) {
         final errorData = response.data;
         print('Function returned error: ${response.status} - $errorData');
         throw Exception('PDF oluşturulamadı: ${errorData?['error'] ?? 'Bilinmeyen sunucu hatası'} (Status: ${response.status})');
      }

      final responseData = response.data;
      if (responseData == null || responseData['pdfBase64'] == null) {
        print('Function response missing pdfBase64 field.');
        throw Exception('PDF verisi alınamadı (pdfBase64 alanı eksik).');
      }

      print('Received pdfBase64 data.');

      // 2. Decode Base64 string to bytes (remains the same)
      final String base64Pdf = responseData['pdfBase64'];
      // Debug log length of base64 string to verify we received actual content
      print('Base64 PDF string length: ${base64Pdf.length}');
      _pdfData = base64Decode(base64Pdf);
      // Debug log the size of decoded PDF data
      print('Decoded PDF data size: ${_pdfData!.lengthInBytes} bytes');
      
      // Quick check if PDF data seems valid (should start with %PDF)
      if (_pdfData!.length > 4) {
        final pdfHeader = String.fromCharCodes(_pdfData!.sublist(0, 4));
        print('PDF header check: $pdfHeader');
        if (pdfHeader != '%PDF') {
          print('WARNING: Data does not start with %PDF header!');
        }
      }

      // 3. Save to temporary file immediately for debugging
      try {
        final tempDir = await getTemporaryDirectory();
        final debugPath = '${tempDir.path}/debug_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final debugFile = File(debugPath);
        await debugFile.writeAsBytes(_pdfData!);
        print('Debug PDF saved to: $debugPath');
      } catch (e) {
        print('Error saving debug PDF: $e');
      }

      // 4. PDF data is ready, update state
      setState(() {
        _isLoading = false; // Loading finished, PDF data is available
        // isReady will be set by PDFView's onRender callback
        isReady = true; // Set to true since we're not using PDFView's callback anymore
      });

    } catch (e) { // General catch block will handle Supabase and other errors
      print('Error generating or loading PDF: $e');
      setState(() {
        _isLoading = false;
        // Display a generic error or parse e if possible
         _errorMessage = 'PDF yüklenirken bir hata oluştu: ${e.toString()}'; // Use toString() for details
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oluşturulan Belge'),
        actions: [
          // Add page navigation if PDF is ready
          if (isReady && pages != null && pages! > 1)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: Center(child: Text("${currentPage! + 1} / $pages")), // Show current page / total pages
             ),
          if (_pdfData != null && isReady) // Enable buttons only when ready
            Row( // Use Row for multiple icons
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.save_alt), // Save icon
                  tooltip: "PDF'yi Kaydet",
                  onPressed: _savePdf, // Call save function
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: "PDF'yi Paylaş",
                  onPressed: _sharePdf,
                ),
                // Add a button to try local PDF generation
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: "Yerel PDF Oluştur",
                  onPressed: _generatePdfLocally,
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: _buildBody(),
      ),
      // Add floating action buttons for page navigation (optional)
      floatingActionButton: isReady && pages != null && pages! > 1
        ? FutureBuilder<PDFViewController>(
            future: _controller.future,
            builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
              if (snapshot.hasData) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FloatingActionButton(
                      heroTag: "prev",
                      child: const Icon(Icons.arrow_back),
                      onPressed: () async {
                        await snapshot.data!.setPage(currentPage! - 1);
                      },
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      heroTag: "next",
                      child: const Icon(Icons.arrow_forward),
                      onPressed: () async {
                        await snapshot.data!.setPage(currentPage! + 1);
                      },
                    ),
                  ],
                );
              }
              return Container(); // Return empty container while controller is loading
            },
          )
        : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CircularProgressIndicator(); // Show loading indicator while fetching/decoding
    }
    else if (_errorMessage != null) {
      // Error display remains the same
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Tekrar Dene'),
              onPressed: _generatePdfLocally, // Retry with local generation
            )
          ],
        ),
      );
    }
    else if (_tempPdfPath != null) {
      // Show PDF viewer directly in the app
      return Column(
        children: [
          // PDF viewer takes most of the screen
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.all(8),
              // Use SfPdfViewer to display the PDF
              child: SfPdfViewer.file(
                File(_tempPdfPath!),
                key: _pdfViewerKey,
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  setState(() {
                    isReady = true;
                    pages = details.document.pages.count;
                  });
                },
              ),
            ),
          ),
          
          // Controls and info below the viewer
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Oluşturuldu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Action buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.save_alt),
                        label: Text('Kaydet'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: _savePdf,
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.share),
                        label: Text('Paylaş'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: _sharePdf,
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.cloud),
                        label: Text('Supabase ile Dene'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: _generateAndLoadPdf,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    else if (_pdfData != null && _tempPdfPath == null) {
      // Instead of PDFView, show a success message and buttons to interact with the PDF
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text(
                'PDF Oluşturuldu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(
                'PDF dosyanız başarıyla oluşturuldu. Görüntülemek, kaydetmek veya paylaşmak için aşağıdaki seçenekleri kullanabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.remove_red_eye),
                    label: Text('Görüntüle'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _openPdfWithSystemViewer,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.save_alt),
                    label: Text('Kaydet'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _savePdf,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.share),
                    label: Text('Paylaş'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _sharePdf,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.cloud),
                    label: Text('Supabase ile Dene'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: _generateAndLoadPdf,
                  ),
                ],
              ),
              SizedBox(height: 24),
              // Add debug info display
              _buildDebugInfoDisplay(),
            ],
          ),
        ),
      );
    }
    else {
      // Fallback if something went wrong (should be covered by error state)
      return const Text('PDF verisi bulunamadı.');
    }
  }

  // Open PDF with system viewer
  Future<void> _openPdfWithSystemViewer() async {
    if (_pdfData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görüntülenecek PDF verisi bulunamadı.')),
      );
      return;
    }

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final tempFilePath = '${tempDir.path}/temp_preview_$timestamp.pdf';
      
      // Write PDF data to file
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(_pdfData!);
      print('Temp PDF written for viewer: $tempFilePath (size: ${_pdfData!.length} bytes)');
      
      // Use open_filex to open the PDF with system viewer
      final result = await OpenFilex.open(tempFilePath);
      print('OpenFilex result: ${result.type} - ${result.message}');
      
      if (result.type != ResultType.done) {
        throw Exception("Dosya açılamadı: ${result.message}");
      }
      
      // Set state to indicate PDF is ready
      setState(() {
        isReady = true;
      });
      
    } catch (e) {
      print('Error opening PDF with system viewer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF görüntülenirken hata oluştu: ${e.toString()}')),
      );
    }
  }

  // Add a simple text preview for debugging
  Widget _buildDebugInfoDisplay() {
    if (_pdfData == null) return Text("PDF verisi yok");
    
    // Extract and show first few bytes as text for debugging
    String debugInfo = '';
    try {
      if (_pdfData!.length > 100) {
        debugInfo = 'PDF Boyutu: ${_pdfData!.length} bytes\n';
        debugInfo += 'İlk 100 byte: ${String.fromCharCodes(_pdfData!.sublist(0, 100)).replaceAll('\n', '\\n')}';
      } else {
        debugInfo = 'PDF Boyutu çok küçük: ${_pdfData!.length} bytes';
      }
    } catch (e) {
      debugInfo = 'Hata: $e';
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PDF Debug Bilgisi:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(debugInfo),
        ],
      ),
    );
  }

  // Generate PDF locally as an alternative approach
  Future<void> _generatePdfLocally() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Use the document generation service to create a PDF from content
      final documentGenerationService = DocumentGenerationService();
      
      // Generate a sensible title from content
      final title = _extractSuggestedName();
      
      // Call the service to generate PDF
      print('Generating PDF locally using DocumentGenerationService...');
      final pdfPath = await documentGenerationService.generatePdfFromContent(
        widget.documentContent!, 
        title
      );
      
      print('Local PDF generated at: $pdfPath');
      
      // Read the generated PDF file
      final file = File(pdfPath);
      _pdfData = await file.readAsBytes();
      
      print('Loaded local PDF data: ${_pdfData!.length} bytes');
      
      // Store the path for viewing
      _tempPdfPath = pdfPath;
      
      // Update state
      setState(() {
        _isLoading = false;
        isReady = true;
      });
      
      // Show success message and try to open it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yerel PDF başarıyla oluşturuldu.')),
      );
      
    } catch (e) {
      print('Error generating PDF locally: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Yerel PDF oluşturulurken hata: ${e.toString()}';
      });
    }
  }

  // Load PDF from a file path
  Future<void> _loadPdfFromPath(String pdfPath) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      
      print('Loaded PDF from path: $pdfPath (${_pdfData!.length} bytes)');
      
      setState(() {
        _isLoading = false;
        isReady = true;
      });
      
    } catch (e) {
      print('Error loading PDF from path: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'PDF yüklenirken hata oluştu: ${e.toString()}';
      });
    }
  }

  // --- PDF Saving Logic ---
  Future<void> _savePdf() async {
    if (_pdfData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek PDF verisi bulunamadı.')),
      );
      return;
    }

    // Extract a suggested name from the document content
    String suggestedName = _extractSuggestedName();
    
    // Show dialog to get document name from user
    final String? documentName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String inputName = suggestedName; // Start with the suggested name
        
        return AlertDialog(
          title: const Text('Belgeyi Kaydet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Belgeniz için bir isim girin:'),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: inputName),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Belge adı',
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                Navigator.of(context).pop(inputName);
              },
            ),
          ],
        );
      },
    );
    
    // If user cancelled, return without saving
    if (documentName == null || documentName.trim().isEmpty) {
      return;
    }
    
    try {
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
      await file.writeAsBytes(_pdfData!);
      print('PDF saved to: $filePath');

      // 4. Create SavedDocument and store in Hive
      final savedDocument = SavedDocument(
        title: documentName, // Use the user-provided name
        documentType: _inferDocumentType(widget.documentContent),
        collectedData: {}, // If we don't have collected data, use empty map
        pdfPath: filePath, // Store the path to the PDF file
        generatedContent: widget.documentContent, // Store the original content (might be null)
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
        print('Document saved to Hive with ID: ${savedDocument.id}, name: ${savedDocument.title}');
      } catch (e) {
        print('Error saving to Hive: $e');
        // Try a simpler approach by just writing to a file if Hive fails
        // No need to throw since we've already saved the PDF file
      }
      
      // 5. Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF "$documentName" başarıyla kaydedildi'),
          action: SnackBarAction(
            label: 'Tamam',
            onPressed: () {},
          ),
        ),
      );

    } catch (e) {
      print('Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF kaydedilirken hata oluştu: ${e.toString()}')),
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

  // --- PDF Sharing Logic ---
  Future<void> _sharePdf() async {
    if (_pdfData == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşılacak PDF verisi bulunamadı.')),
      );
      return;
    }

    try {
      // 1. Get Temporary Directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;

      // 2. Create Temporary File Path (using a fixed name is okay for temp sharing)
      final tempFilePath = '$tempPath/paylasilan_belge.pdf';
      final tempFile = File(tempFilePath);

      // 3. Write PDF Data to Temporary File
      await tempFile.writeAsBytes(_pdfData!, flush: true); // Ensure data is written
      print('Temporary PDF for sharing created at: $tempFilePath');

      // 4. Share the File using share_plus
      final xFile = XFile(tempFilePath); // Create XFile from path
      await Share.shareXFiles(
        [xFile],
        text: 'Oluşturulan PDF Belgesi', // Optional: accompanying text
        // subject: 'PDF Belgesi' // Optional: subject for email sharing
      );

      // Optional: Delete the temporary file after sharing (might not be needed as OS handles temp)
      // await tempFile.delete();

    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF paylaşılırken hata oluştu: ${e.toString()}')),
      );
    }
  }
} 