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

class PdfViewerScreen extends StatefulWidget {
  final String documentContent;

  const PdfViewerScreen({Key? key, required this.documentContent}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _generateAndLoadPdf();
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
      _pdfData = base64Decode(base64Pdf);
      print('Base64 decoded successfully (${_pdfData!.lengthInBytes} bytes).');

      // 3. PDF data is ready, update state
      // No need to initialize a controller like with pdfx here,
      // PDFView widget will use _pdfData directly.
      setState(() {
        _isLoading = false; // Loading finished, PDF data is available
        // isReady will be set by PDFView's onRender callback
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
                 onPressed: _generateAndLoadPdf, // Retry fetching/decoding
              )
           ],
        ),
      );
    }
    else if (_pdfData != null) {
      // Use PDFView from flutter_pdfview
      return PDFView(
        pdfData: _pdfData!, // Pass the PDF bytes
        enableSwipe: true,
        swipeHorizontal: false, // Vertical scrolling
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        defaultPage: currentPage ?? 0,
        fitPolicy: FitPolicy.BOTH, // Adjust fit policy as needed
        preventLinkNavigation: false, // Allow links within PDF
        onRender: (_pages) {
          // Called when PDF is rendered
          setState(() {
            pages = _pages;
            isReady = true; // PDF is ready to be interacted with
          });
          print("PDF Rendered: $_pages pages");
        },
        onError: (error) {
          // Handle PDF rendering errors
          print("PDFView Error: $error");
          setState(() {
            _errorMessage = "PDF görüntülenirken hata oluştu: $error";
            isReady = false;
          });
        },
        onPageError: (page, error) {
          print('PDFView Page Error: $page: $error');
          // Optionally show a specific error message for page errors
        },
        onViewCreated: (PDFViewController pdfViewController) {
          // Complete the controller when view is created
          if (!_controller.isCompleted) {
             _controller.complete(pdfViewController);
          }
        },
        onPageChanged: (int? page, int? total) {
          // Update current page number
          print('page change: $page/$total');
          setState(() {
            currentPage = page;
          });
        },
      );
    }
    else {
      // Fallback if something went wrong (should be covered by error state)
      return const Text('PDF verisi bulunamadı.');
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

    try {
      // 1. Get Application Documents Directory
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // 2. Generate Unique Filename
      const uuid = Uuid();
      final fileName = 'belge_${uuid.v4()}.pdf';
      final filePath = '$path/$fileName';

      // 3. Write PDF Data to File
      final file = File(filePath);
      await file.writeAsBytes(_pdfData!);
      print('PDF saved to: $filePath');

      // 4. Store metadata in Hive
      // Ensure 'saved_documents' box is opened, preferably during app initialization
      final box = await Hive.openBox('saved_documents');
      await box.put(filePath, { // Use filePath as key for simplicity
        'filePath': filePath,
        'name': 'Oluşturulan Belge ${DateTime.now().toLocal().toString().substring(0, 16)}', // Simple name with date
        'savedAt': DateTime.now(),
      });
      print('Metadata saved to Hive for $filePath');
      // await box.close(); // Close if not needed immediately elsewhere

      // 5. Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF başarıyla kaydedildi: $fileName'),
          action: SnackBarAction( // Optional: Add action to open directory? (Complex)
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