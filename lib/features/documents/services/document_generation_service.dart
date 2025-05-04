import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/document_template.dart';
import 'package:intl/intl.dart';

/// PDF belge taslağı oluşturmaktan sorumlu servis sınıfı
class DocumentGenerationService {
  // Convert Turkish characters to ASCII equivalents
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

  /// Ham metin içeriğinden bir PDF belgesi oluşturur ve kaydeder
  /// [content] - PDF'e yazılacak ham metin içeriği
  /// [documentName] - Oluşturulacak PDF'in başlığı ve dosya adı için temel
  /// 
  /// Oluşturulan PDF dosyasının yolunu döndürür
  Future<String> generatePdfFromContent(String content, String documentName) async {
    try {
      // Normalize text for PDF compatibility (convert Turkish characters to ASCII)
      String normalizedContent = _normalizeText(content);
      String normalizedTitle = _normalizeText(documentName);
      
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Başlık
                pw.Center(
                  child: pw.Text(
                    normalizedTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Belge içeriği
                pw.Text(normalizedContent),

                // Yasal uyarı (ASCII versiyonu)
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.Text(
                  'YASAL UYARI: Bu belge AI Avukat Asistani ile olusturulmus bir taslaktir. '
                  'Yasal baglayiciligi yoktur ve profesyonel hukuki tavsiye yerine gecmez. '
                  'Kullanmadan once avukatiniza danisin.',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

                // Oluşturulma tarihi
                pw.SizedBox(height: 5),
                pw.Text(
                  'Olusturulma Tarihi: ${_getCurrentDate()}',
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            );
          },
        ),
      );

      // Dosyayı kaydet
      final output = await getTemporaryDirectory(); // Use temporary dir for generated docs
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // Sanitize documentName for use in file name
      final fileNameBase = _normalizeText(documentName)
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
          .toLowerCase();
      final file = File('${output.path}/${fileNameBase}_${timestamp}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      // Log the error for debugging
      print('Error generating PDF from content: $e');
      throw Exception('PDF generation from content error: $e');
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
    return _normalizeText(date);
  }
} 