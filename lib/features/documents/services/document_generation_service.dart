import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/document_template.dart';
import '../data/models/saved_document.dart';
import 'package:intl/intl.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/core/services/connectivity_service.dart';
import 'package:legalai/core/services/offline_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

/// PDF belgesi oluşturma stilleri
enum PdfStyle {
  standard,     // Standart yasal belge
  modern,       // Modern ve estetik
  formal,       // Resmi diçak renklerle
  accessible,   // Erişilebilirlik için optimize edilmiş
  compact       // Kağıt tasarrufu için kompakt
}

/// PDF belgesi oluşturma seçenekleri
class PdfGenerationOptions {
  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final PdfStyle style;
  final bool includeFooter;
  final bool includeHeader;
  final bool includePageNumbers;
  final bool includeWatermark;
  final bool includeTableOfContents;
  final String? watermarkText;
  final bool protectContent;
  final String? logoPath;
  final List<String>? attachmentPaths;
  
  PdfGenerationOptions({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.style = PdfStyle.standard,
    this.includeFooter = true,
    this.includeHeader = true,
    this.includePageNumbers = true,
    this.includeWatermark = false,
    this.includeTableOfContents = false,
    this.watermarkText,
    this.protectContent = false,
    this.logoPath,
    this.attachmentPaths,
  });
}

/// PDF belge taslağı oluşturmaktan sorumlu servis sınıfı
class DocumentGenerationService {
  final ConnectivityService? _connectivityService;
  final OfflineSyncService? _offlineSyncService;
  
  /// Belge şablonları için TTF fontları
  late pw.Font _defaultFont;
  late pw.Font _boldFont;
  late pw.Font _italicFont;
  late pw.Font _headingFont;
  
  /// Belge şablonundaki özel stil bileşenleri
  late pw.TextStyle _titleStyle;
  late pw.TextStyle _headingStyle;
  late pw.TextStyle _subtitleStyle;
  late pw.TextStyle _bodyStyle;
  late pw.TextStyle _footerStyle;
  late pw.TextStyle _watermarkStyle;
  
  DocumentGenerationService({
    this.offlineMode = false,
    ConnectivityService? connectivityService,
    OfflineSyncService? offlineSyncService,
  }) : 
    _connectivityService = connectivityService,
    _offlineSyncService = offlineSyncService {
    _initializeFonts();
  }
  
  /// Font ve stilleri başlat
  Future<void> _initializeFonts() async {
    try {
      // Font yükleme işlemini geçici olarak devre dışı bırakıyoruz
      _defaultFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
      _italicFont = pw.Font.helveticaOblique();
      _headingFont = pw.Font.helveticaBold();
      
      // Standart stilleri oluştur
      _titleStyle = pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
      );
      
      _headingStyle = pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      );
      
      _subtitleStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      );
      
      _bodyStyle = pw.TextStyle(
        fontSize: 11,
      );
      
      _footerStyle = pw.TextStyle(
        fontSize: 8,
        fontStyle: pw.FontStyle.italic,
        color: PdfColor(0.5, 0.5, 0.5),
      );
      
      _watermarkStyle = pw.TextStyle(
        fontSize: 60,
        color: PdfColor(0.9, 0.9, 0.9),
      );
    } catch (e) {
      print('PDF fontları yüklenirken hata: $e');
      // Varsayılan fontları kullan
      _defaultFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
      _italicFont = pw.Font.helveticaOblique();
      _headingFont = pw.Font.helveticaBold();
      
      // Standart stilleri oluştur
      _titleStyle = pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
      );
      
      _headingStyle = pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      );
      
      _subtitleStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      );
      
      _bodyStyle = pw.TextStyle(
        fontSize: 11,
      );
      
      _footerStyle = pw.TextStyle(
        fontSize: 8,
        fontStyle: pw.FontStyle.italic,
        color: PdfColor(0.5, 0.5, 0.5),
      );
      
      _watermarkStyle = pw.TextStyle(
        fontSize: 60,
        color: PdfColor(0.9, 0.9, 0.9),
      );
    }
  }
  
  /// Çevrimdışı mod aktif mi?
  final bool offlineMode;
  
  /// İnternet bağlantısı var mı?
  bool get isOnline => _connectivityService?.isOnline ?? !offlineMode;

  /// Türkçe karakterleri ASCII eşdeğerlerine dönüştürür
  String _normalizeText(String text) {
    return text
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O');
  }

  /// Ham metin içeriğinden gelişmiş bir PDF belgesi oluşturur ve kaydeder
  /// [content] - PDF'e yazılacak ham metin içeriği
  /// [documentName] - Oluşturulacak PDF'in başlığı ve dosya adı için temel
  /// [options] - Belge oluşturma seçenekleri
  /// Oluşturulan PDF dosyasının yolunu döndürür
  Future<String> generatePdfFromContent(
    String content, 
    String documentName, 
    {PdfGenerationOptions? options}
  ) async {
    try {
      // Varsayılan seçenekleri ayarla
      options ??= PdfGenerationOptions(
        title: documentName,
        author: 'LegalAI',
        subject: 'Yasal Belge',
      );

      // Normalize text for PDF compatibility (convert Turkish characters to ASCII)
      String normalizedContent = content;
      String normalizedTitle = documentName;
      
      final pdf = pw.Document(
        title: options.title,
        author: options.author,
        subject: options.subject,
        keywords: options.keywords,
        creator: 'LegalAI Document Generator',
      );
      
      // Belgenin tarzına göre stil düzenlemeleri
      _adjustStyleByPdfType(options.style);
      
      // Belgenin ilk sayfasının içeriğini ekle
      pdf.addPage(
        _buildTitlePage(normalizedTitle, normalizedContent, options),
      );
      
      // İçindekiler ekle
      if (options.includeTableOfContents) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text('İÇİNDEKİLER', style: _titleStyle),
                  ),
                  pw.SizedBox(height: 20),
                  pw.TableOfContent(),
                ],
              );
            },
          ),
        );
      }
      
      // Belgede bölümler oluştur
      final paragraphs = normalizedContent.split('\n\n');
      List<String> headings = [];
      
      // Başlıkları çıkar
      for (var paragraph in paragraphs) {
        if (paragraph.trim().startsWith('MADDE') || paragraph.trim().toUpperCase() == paragraph.trim()) {
          headings.add(paragraph.trim());
        }
      }
      
      // Başlıkları takip eden paragraflarla belge sayfalarını oluştur
      for (int i = 0; i < paragraphs.length; i++) {
        if (i > 0) { // İlk sayfa zaten title page olarak eklendi
          if (paragraphs[i].trim().startsWith('MADDE') || 
              paragraphs[i].trim().toUpperCase() == paragraphs[i].trim()) {
            
            // Başlık ve sonraki paragraflara erişim
            final heading = paragraphs[i];
            final content = i < paragraphs.length - 1 ? paragraphs[i + 1] : '';
            
            // İçerik sayfasını oluştur
            pdf.addPage(
              _buildContentPage(heading, content, options, i + 1),
            );
          }
        }
      }
      
      // Dosyayı kaydet
      final output = await getTemporaryDirectory(); // Use temporary dir for generated docs
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // Sanitize documentName for use in file name
      final fileNameBase = _normalizeText(documentName)
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
          .toLowerCase();
      final file = File('${output.path}/${fileNameBase}_${timestamp}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Yerel veritabanına kaydedilen belgeyi senkronize et
      if (!isOnline && _offlineSyncService != null) {
        _offlineSyncService!.addPendingOperation(
          'save_document',
          {
            'documentPath': file.path,
            'documentName': documentName,
            'content': content,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return file.path;
    } catch (e) {
      // Log the error for debugging
      print('Error generating PDF from content: $e');
      throw Exception('PDF generation from content error: $e');
    }
  }
  
  /// Belgeyi şablon ve verilerden oluşturur
  Future<String> generateDocumentFromTemplate(
    DocumentTemplate template, 
    Map<String, dynamic> fieldValues,
    {PdfGenerationOptions? options}
  ) async {
    try {
      // Şablondaki yer tutucuları değiştirerek belge içeriğini oluştur
      final documentContent = _replacePlaceholders(template.templateText, fieldValues);
      
      // Varsayılan seçenekler
      options ??= PdfGenerationOptions(
        title: template.name,
        author: 'LegalAI',
        subject: template.description,
        includeHeader: true,
        includeWatermark: false,
      );
      
      // PDF oluştur
      return await generatePdfFromContent(documentContent, template.name, options: options);
    } catch (e) {
      print('Error generating document from template: $e');
      throw Exception('Template document generation error: $e');
    }
  }
  
  /// PdfStyle'a göre stil düzenlemeleri yapar
  void _adjustStyleByPdfType(PdfStyle style) {
    switch (style) {
      case PdfStyle.modern:
        _titleStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(0.1, 0.4, 0.7), // Modern mavi
        );
        
        _headingStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(0.1, 0.4, 0.7),
        );
        
        _subtitleStyle = pw.TextStyle(
          font: _boldFont,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(0.3, 0.3, 0.3),
        );
        
        _bodyStyle = pw.TextStyle(
          font: _defaultFont,
          fontSize: 11,
          color: PdfColor(0.1, 0.1, 0.1),
        );
        break;
      
      case PdfStyle.formal:
        _titleStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        );
        
        _headingStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        );
        
        _subtitleStyle = pw.TextStyle(
          font: _boldFont,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        );
        
        _bodyStyle = pw.TextStyle(
          font: _defaultFont,
          fontSize: 11,
        );
        break;
      
      case PdfStyle.accessible:
        _titleStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(0, 0, 0), // Koyu siyah yüksek kontrast
        );
        
        _headingStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(0, 0, 0),
        );
        
        _subtitleStyle = pw.TextStyle(
          font: _boldFont,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(0, 0, 0),
        );
        
        _bodyStyle = pw.TextStyle(
          font: _defaultFont,
          fontSize: 14, // Daha büyük metin
          color: PdfColor(0, 0, 0),
          lineSpacing: 1.5, // Daha fazla satır aralığı
        );
        break;
      
      case PdfStyle.compact:
        _titleStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 14, // Daha küçük başlık
          fontWeight: pw.FontWeight.bold,
        );
        
        _headingStyle = pw.TextStyle(
          font: _headingFont,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        );
        
        _subtitleStyle = pw.TextStyle(
          font: _boldFont,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        );
        
        _bodyStyle = pw.TextStyle(
          font: _defaultFont,
          fontSize: 9, // Daha küçük metin
          lineSpacing: 0.9, // Daha az satır aralığı
        );
        break;
      
      case PdfStyle.standard:
      default:
        // Varsayılan stiller zaten başlangıçta ayarlanmış
        break;
    }
  }
  
  /// Başlık sayfası oluşturur
  pw.Page _buildTitlePage(
    String title, 
    String content, 
    PdfGenerationOptions options
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Ana içerik
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Üst bilgi
                if (options.includeHeader) _buildHeader(options),
                
                pw.SizedBox(height: 40),
                
                // Başlık
                pw.Center(
                  child: pw.Text(
                    title,
                    style: _titleStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // İçerik özeti
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      // İçerik bölümünü doldur
                      pw.Paragraph(
                        text: _truncateContent(content, 1500), // Yalnızca ilk sayfaya sığacak kadar
                        style: _bodyStyle,
                      ),
                    ],
                  ),
                ),
                
                // Alt bilgi
                if (options.includeFooter) _buildFooter(1, options),
              ],
            ),
            
            // Filigran
            if (options.includeWatermark && options.watermarkText != null)
              pw.Center(
                child: pw.Transform.rotate(
                  angle: -45 * 3.1415927 / 180,
                  child: pw.Text(
                    options.watermarkText!,
                    style: _watermarkStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  /// İçerik sayfası oluşturur
  pw.Page _buildContentPage(
    String heading, 
    String content, 
    PdfGenerationOptions options,
    int pageNumber
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Ana içerik
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Üst bilgi
                if (options.includeHeader) _buildHeader(options),
                
                pw.SizedBox(height: 20),
                
                // Başlık
                pw.Paragraph(
                  text: heading,
                  style: _headingStyle,
                ),
                
                pw.SizedBox(height: 10),
                
                // İçerik özeti
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // İçerik bölümünü doldur
                      pw.Paragraph(
                        text: content,
                        style: _bodyStyle,
                      ),
                    ],
                  ),
                ),
                
                // Alt bilgi
                if (options.includeFooter) _buildFooter(pageNumber, options),
              ],
            ),
            
            // Filigran
            if (options.includeWatermark && options.watermarkText != null)
              pw.Center(
                child: pw.Transform.rotate(
                  angle: -45 * 3.1415927 / 180,
                  child: pw.Text(
                    options.watermarkText!,
                    style: _watermarkStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  /// Üst bilgi oluşturur
  pw.Widget _buildHeader(PdfGenerationOptions options) {
    return pw.Container(
      height: 40,
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColor(0.5, 0.5, 0.5))),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          options.logoPath != null
              ? pw.Image(
                  pw.MemoryImage(File(options.logoPath!).readAsBytesSync()),
                  height: 30,
                )
              : pw.Text('LegalAI', style: _subtitleStyle),
          
          // Tarih
          pw.Text(
            _getCurrentDate(),
            style: _footerStyle,
          ),
        ],
      ),
    );
  }
  
  /// Alt bilgi oluşturur
  pw.Widget _buildFooter(int pageNumber, PdfGenerationOptions options) {
    return pw.Container(
      height: 30,
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColor(0.5, 0.5, 0.5))),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Yasal uyarı
          pw.Flexible(
            child: pw.Text(
              'YASAL UYARI: Bu belge AI Avukat Asistanı ile oluşturulmuş bir taslaktır. '
              'Yasal bağlayıcılığı yoktur ve profesyonel hukuki tavsiye yerine geçmez. '
              'Kullanmadan önce avukatınıza danışın.',
              style: _footerStyle,
            ),
          ),
          
          // Sayfa numarası
          if (options.includePageNumbers)
            pw.Text(
              'Sayfa $pageNumber',
              style: _footerStyle,
            ),
        ],
      ),
    );
  }
  
  /// İçeriği belirli uzunlukla sınırlar
  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) {
      return content;
    } else {
      return content.substring(0, maxLength) + '...';
    }
  }
  
  /// Oluşturulan belgeyi Hive'a kaydeder
  Future<SavedDocument> saveDocument({
    required String title,
    required String documentType,
    required Map<String, String> collectedData,
    String? pdfPath,
    String? generatedContent,
    String? category,
    List<String>? tags,
    DocumentStatus? status,
  }) async {
    try {
      final document = SavedDocument(
        title: title,
        documentType: documentType,
        collectedData: collectedData,
        pdfPath: pdfPath,
        generatedContent: generatedContent,
        category: category,
        tags: tags,
        status: status,
      );
      
      // Hive box'a kaydet
      final box = await Hive.openBox<SavedDocument>('saved_documents');
      await box.put(document.id, document);
      
      // Çevrimdışı durumda işlemi kuyruğa ekle
      if (!isOnline && _offlineSyncService != null) {
        await _offlineSyncService!.addPendingOperation(
          'create_document',
          {
            'documentId': document.id,
            'title': title,
            'documentType': documentType,
            'collectedData': collectedData,
            'pdfPath': pdfPath,
            'generatedContent': generatedContent,
            'category': category,
            'tags': tags?.join(','),
            'status': status?.toString() ?? DocumentStatus.draft.toString(),
            'createdAt': document.createdAt.toIso8601String(),
          },
        );
      }
      
      return document;
    } catch (e) {
      print('Error saving document to Hive: $e');
      throw Exception('Document saving error: $e');
    }
  }
  
  /// Belgeyi günceller
  Future<void> updateDocument(SavedDocument document) async {
    try {
      // Hive box'ta güncelle
      final box = await Hive.openBox<SavedDocument>('saved_documents');
      await box.put(document.id, document);
      
      // Çevrimdışı durumda işlemi kuyruğa ekle
      if (!isOnline && _offlineSyncService != null) {
        await _offlineSyncService!.addPendingOperation(
          'update_document',
          {
            'documentId': document.id,
            'title': document.title,
            'documentType': document.documentType,
            'collectedData': document.collectedData,
            'pdfPath': document.pdfPath,
            'generatedContent': document.generatedContent,
            'category': document.category,
            'tags': document.tags.join(','),
            'status': document.status.toString(),
            'version': document.version,
            'updatedAt': document.updatedAt.toIso8601String(),
            'createdAt': document.createdAt.toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('Error updating document in Hive: $e');
      throw Exception('Document update error: $e');
    }
  }
  
  /// Belgeyi siler
  Future<void> deleteDocument(String documentId) async {
    try {
      // Hive box'tan sil
      final box = await Hive.openBox<SavedDocument>('saved_documents');
      
      // Belgenin PDF dosyası varsa onu da sil
      final document = box.get(documentId);
      if (document != null && document.pdfPath != null) {
        final file = File(document.pdfPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await box.delete(documentId);
      
      // Çevrimdışı durumda işlemi kuyruğa ekle
      if (!isOnline && _offlineSyncService != null) {
        await _offlineSyncService!.addPendingOperation(
          'delete_document',
          {
            'documentId': documentId,
          },
        );
      }
    } catch (e) {
      print('Error deleting document from Hive: $e');
      throw Exception('Document deletion error: $e');
    }
  }
  
  /// Belgeyi dışa aktarır ve paylaşır
  Future<void> shareDocument(SavedDocument document) async {
    if (document.pdfPath == null) {
      throw Exception('PDF yolu bulunamadı');
    }
    
    final file = File(document.pdfPath!);
    if (!await file.exists()) {
      throw Exception('Belge bulunamadı: ${document.pdfPath}');
    }
    
    try {
      await Share.shareXFiles(
        [XFile(document.pdfPath!)],
        text: 'LegalAI ile oluşturulan "${document.title}" belgesi',
        subject: document.title,
      );
    } catch (e) {
      print('Error sharing document: $e');
      throw Exception('Document sharing error: $e');
    }
  }
  
  /// Belgeyi benzersiz isimle PDF olarak dışa aktarır
  Future<String> exportDocument(SavedDocument document, Directory targetDirectory) async {
    try {
      if (document.pdfPath == null) {
        throw Exception('PDF yolu bulunamadı');
      }
      
      final sourceFile = File(document.pdfPath!);
      if (!await sourceFile.exists()) {
        throw Exception('Kaynak belge bulunamadı');
      }
      
      // Dosya adı oluştur
      final sanitizedTitle = _normalizeText(document.title)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${sanitizedTitle}_v${document.version}_$timestamp.pdf';
      final targetPath = '${targetDirectory.path}/$fileName';
      
      // Kopyala
      await sourceFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      print('Error exporting document: $e');
      throw Exception('Document export error: $e');
    }
  }
  
  /// Şablon metnindeki yer tutucuları gerçek değerlerle değiştirir
  String _replacePlaceholders(String templateText, Map<String, dynamic> fieldValues) {
    String result = templateText;
    
    // Her bir alan için yer tutucuyu değiştir
    fieldValues.forEach((key, value) {
      // String olmayan değerleri dönüştür (tarih vb.)
      String stringValue = value is DateTime 
          ? DateFormat('dd.MM.yyyy').format(value) 
          : value.toString();
          
      // Yer tutucuyu değiştir (örn. {{ad_soyad}} -> "Ahmet Yılmaz")
      result = result.replaceAll('{{$key}}', stringValue);
    });
    
    return result;
  }
  
  /// Güncel tarihi ASCII formatla döndürür
  String _getCurrentDate() {
    String date = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return date;  // Artık Türkçe karakterleri normalize etmemize gerek yok, düzgün fontlar kullanıyoruz
  }
}

/// Document Generation Service Provider
final documentGenerationServiceProvider = Provider<DocumentGenerationService>((ref) {
  final connectivityService = ref.watch(connectivityProvider.notifier);
  final offlineSyncService = ref.watch(offlineSyncServiceProvider);
  
  return DocumentGenerationService(
    connectivityService: connectivityService,
    offlineSyncService: offlineSyncService,
  );
}); 