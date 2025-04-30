import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/core/theme/app_theme.dart';
import '../../data/models/document_template.dart';
import '../../data/models/document_field.dart';
import '../../providers/document_providers.dart';
import 'document_preview_screen.dart';

/// Kullanıcının AI tarafından çıkarılan verileri gözden geçirip düzenleyebileceği ekran
class DocumentReviewScreen extends ConsumerStatefulWidget {
  final DocumentTemplate template;
  final Map<String, String> extractedData; // AI'dan gelen ilk veri

  const DocumentReviewScreen({
    Key? key,
    required this.template,
    required this.extractedData,
  }) : super(key: key);

  @override
  ConsumerState<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends ConsumerState<DocumentReviewScreen> {
  // Her alan için bir TextEditingController tutacak map
  late Map<String, TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>(); // Form state'i için anahtar
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Controller'ları başlangıç verileriyle oluştur (field.key kullanarak)
    _controllers = {
      for (var field in widget.template.fields)
        field.key: TextEditingController(text: widget.extractedData[field.key] ?? ''),
    };
  }

  @override
  void dispose() {
    // Controller'ları temizle
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bilgileri Gözden Geçir',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form( // Form widget'ı ile sarmala
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yasal Uyarı
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline, 
                        color: theme.colorScheme.onSecondaryContainer, 
                        size: 20
                      ),
                      const SizedBox(width: 10),
          Expanded(
                        child: Text(
                          'ÖNEMLİ: Lütfen yapay zeka tarafından doldurulan tüm bilgileri dikkatlice kontrol edin ve gerekirse düzeltin. Bu taslak yasal tavsiye niteliği taşımaz.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            height: 1.4 // Satır yüksekliği
                          ),
                        ),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 24),

                // Alan Listesi
                ...widget.template.fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0), // Alanlar arası boşluk
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                          field.label, // Alan etiketi
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600, 
                            color: theme.colorScheme.onSurfaceVariant
                            ),
                          ),
                          const SizedBox(height: 8),
                        TextFormField(
                          // field.key kullanarak doğru controller'ı al
                          controller: _controllers[field.key], 
                          // Klavye tipini alan tipine (string) göre ayarla
                          keyboardType: _getKeyboardType(field.type), 
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            // hintText için field.label kullan
                            hintText: '${field.label} girin...', 
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                             enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                              ),
                               errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
                              ),
                          ),
                          // Basit bir doğrulama ekleyebiliriz (örneğin boş olamaz)
                          validator: (value) {
                            // if (field.required && (value == null || value.isEmpty)) {
                            //   return '${field.label} alanı boş bırakılamaz.';
                            // }
                            return null; // Şimdilik doğrulama yok
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24), // Buton öncesi boşluk

                // Onay Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                     icon: _isProcessing
                        ? Container()
                        : Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: _isProcessing
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary)),
                          )
                        : Text('Onayla ve Belgeyi Oluştur'),
                    onPressed: _isProcessing ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Pill shape
                      ),
                       elevation: 2,
                    ),
                  ),
                ),
                 const SizedBox(height: 16), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Alan tipine (String) göre klavye tipini belirle
  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType.toLowerCase()) { // Küçük harfe çevirerek kontrol et
      case 'number':
      case 'currency':
        return TextInputType.numberWithOptions(decimal: true);
      case 'date':
        return TextInputType.datetime; // Veya özel bir tarih seçici kullanılabilir
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'multilinetext': // Muhtemel string değeri
      case 'text_area': // Başka bir muhtemel değer
        return TextInputType.multiline;
      case 'text':
      default:
        return TextInputType.text;
    }
  }

  // Formu gönderme ve PDF oluşturma adımına geçme
  void _submitForm() {
    // if (_formKey.currentState!.validate()) { // Validasyon aktif edilirse
      // Form geçerliyse, güncellenmiş verileri topla
      final Map<String, String> finalData = {
        for (var entry in _controllers.entries) entry.key: entry.value.text,
      };

      setState(() {
        _isProcessing = true; 
      });

      print("Final Data Submitted: $finalData"); // Konsola yazdır (test için)

      // TODO: PDF Oluşturma Mantığını Çağır
      // 1. PDF oluşturma servisini çağır (finalData ve widget.template ile)
      // 2. Oluşturulan PDF dosyasının yolunu veya verisini al
      // 3. Bir sonraki ekrana (DocumentPreviewScreen) yönlendir (PDF yolu/verisi ile)

      // Şimdilik sadece gecikme ve sonraki adıma geçiş simülasyonu
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
           setState(() { _isProcessing = false; });
          // Örnek yönlendirme (DocumentPreviewScreen oluşturulunca aktif edilecek)
          /*
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentPreviewScreen(
                // Gerekli parametreleri geçir (örn: pdfPath veya pdfBytes)
          ),
        ),
      );
          */
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Belge oluşturma işlemi başlatıldı (simülasyon).'), backgroundColor: Colors.green,)
          );
        }
      });
    // } else {
    //   // Form geçerli değilse kullanıcıyı uyar
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Lütfen tüm gerekli alanları kontrol edin.'), backgroundColor: theme.colorScheme.error,)
    //   );
    // }
  }
}

// DocumentFieldType enum'ı olmadığı için yorum satırı kaldırıldı.
// String tabanlı tipe göre işlem yapılıyor.

// DocumentFieldType enum'ının tanımlı olduğunu varsayıyoruz (muhtemelen models içinde)
// Eğer yoksa, buraya veya ilgili model dosyasına eklenmeli:
/*
enum DocumentFieldType {
  text,
  multilineText,
  number,
  date,
  currency,
  email,
  phone,
  // Diğer tipler eklenebilir
}
*/ 