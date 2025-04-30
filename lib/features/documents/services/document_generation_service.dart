import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/document_template.dart';
import 'package:intl/intl.dart';

/// PDF belge taslağı oluşturmaktan sorumlu servis sınıfı
class DocumentGenerationService {
  /// Bir belge şablonu ve doldurulmuş alanlarla PDF belgesi oluşturur
  /// [template] - PDF'in temelini oluşturan belge şablonu
  /// [fieldValues] - Şablondaki yer tutucuları değiştirmek için alan değerleri
  /// 
  /// Oluşturulan PDF dosyasının yolunu döndürür
  Future<String> generatePdfDocument(
    DocumentTemplate template,
    Map<String, dynamic> fieldValues,
  ) async {
    try {
      // PDF oluştur
      final pdf = pw.Document();
      
      // Şablon metnini alıp, alan değerleriyle yer tutucuları değiştir
      String finalContent = _replacePlaceholders(template.templateText, fieldValues);
      
      // Türkçe karakter desteği için font kodlamasını dikkate almalısınız
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
                    template.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Belge içeriği
                pw.Text(finalContent),
                
                // Yasal uyarı
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.Text(
                  'YASAL UYARI: Bu belge AI Avukat Asistanı ile oluşturulmuş bir taslaktır. '
                  'Yasal bağlayıcılığı yoktur ve profesyonel hukuki tavsiye yerine geçmez. '
                  'Kullanmadan önce avukatınıza danışın.',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                
                // Oluşturulma tarihi
                pw.SizedBox(height: 5),
                pw.Text(
                  'Oluşturulma Tarihi: ${_getCurrentDate()}',
                  style: pw.TextStyle(fontSize: 8),
                ),
              ],
            );
          },
        ),
      );
      
      // Dosyayı kaydet
      final output = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File('${output.path}/belge_${timestamp}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      throw Exception('PDF generation error: $e');
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
  
  /// Güncel tarihi Türkçe formatla döndürür
  String _getCurrentDate() {
    return DateFormat('dd.MM.yyyy').format(DateTime.now());
  }
} 