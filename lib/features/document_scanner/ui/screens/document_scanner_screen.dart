import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/advisor/ui/screens/advisor_screen.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({Key? key}) : super(key: key);

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  File? _imageFile;
  String? _scannedText;
  bool _isScanning = false;
  bool _isPickingImage = false;
  
  // Test verilerimizi ve test durumlarını yönetmek için
  final List<Map<String, String>> _testDocuments = [
    {
      'title': 'Örnek Kira Sözleşmesi',
      'content': """KİRA SÖZLEŞMESİ

1. TARAFLAR
Kiralayan: Ahmet Yılmaz
Adres: Atatürk Cad. No:56 Kadıköy/İstanbul 
Telefon: 0532 123 45 67

Kiracı: Mehmet Kaya
TC Kimlik No: 12345678901
Adres: Bağdat Cad. No:120 Maltepe/İstanbul
Telefon: 0533 765 43 21

2. KİRALANAN
İstanbul ili, Kadıköy ilçesi, Caferağa mahallesi, Moda Cad. No:34 D:5 adresindeki 2+1, 90m² daire.

3. KİRA SÜRESİ
Kira süresi 1 (bir) yıldır. Başlangıç tarihi 01.07.2024, bitiş tarihi 01.07.2025'tir.

4. KİRA BEDELİ
Aylık kira bedeli 15.000 TL (onbeşbintürklirası)'dır. Kira her ayın 1. günü peşin olarak ödenecektir.

5. DEPOZİTO
Kiracı 2 aylık kira bedeli olan 30.000 TL tutarında depozito verecektir.

İmza: _____________        İmza: _____________
     Kiralayan                 Kiracı
Tarih: 15.06.2024"""
    },
    {
      'title': 'Örnek Satış Sözleşmesi',
      'content': """ÖRNEK BELGE / TEST TARAMASI

SATIŞ SÖZLEŞMESİ

SATICI:
ABC Ticaret Ltd. Şti.
Adres: İnönü Cad. No:45/3 Çankaya/Ankara
Vergi No: 1234567890

ALICI:
Ayşe Demir
TC: 12345678901
Adres: Bağdat Cad. No:120 Kadıköy/İstanbul

ÜRÜN BİLGİLERİ:
1 adet XYZ marka laptop bilgisayar
Model: Pro 123
Seri No: XYZ123456
Fiyat: 25.000 TL (Yirmibeşbin Türk Lirası)

ÖDEME BİLGİLERİ:
Peşin ödeme yapılmıştır.

GARANTİ KOŞULLARI:
Ürün 2 yıl garanti kapsamındadır.

Satıcı İmza               Alıcı İmza
____________             ___________

Tarih: 20.06.2024"""
    },
    {
      'title': 'Örnek İş Sözleşmesi',
      'content': """İŞ SÖZLEŞMESİ

İŞVEREN:
XYZ Teknoloji A.Ş.
Adres: Levent Mah. 123 Sok. No:45 Beşiktaş/İstanbul
Vergi No: 9876543210

İŞÇİ:
Ali Yılmaz
TC Kimlik No: 12345678910
Adres: Ataşehir Mah. Palmiye Sok. No:12 D:5 Ataşehir/İstanbul
Telefon: 0533 123 45 67

GÖREV TANIMI:
Yazılım Geliştirme Uzmanı

ÇALIŞMA SÜRESİ:
Belirsiz süreli, tam zamanlı.
Başlangıç tarihi: 01.07.2024

ÇALIŞMA SAATLERİ:
Haftalık 45 saat, Pazartesi-Cuma, 09:00-18:00

ÜCRET:
Aylık brüt ücret: 45.000 TL
Ödemeler her ayın son iş günü yapılacaktır.

DENEME SÜRESİ:
2 ay deneme süresi uygulanacaktır.

İş bu sözleşme taraflarca okunup anlaşılarak imzalanmıştır.

İşveren İmza               İşçi İmza
_______________           _______________

Tarih: 22.06.2024"""
    }
  ];
  
  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // Simülatör için test modu - Kamera ve galeri sorunlarını atlar
  void _useTestImage() async {
    setState(() {
      _isScanning = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _scannedText = _testDocuments[0]['content'];
      _isScanning = false;
    });
  }

  // Test için örnek belge resmini kullan
  Future<void> _useExampleDocument() async {
    setState(() {
      _isScanning = true;
      _scannedText = null;
    });
    
    // 1.5 saniye yükleniyor görüntüsü göster
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Örnek belge içeriği
    setState(() {
      _scannedText = _testDocuments[1]['content'];
      _isScanning = false;
    });
  }

  // İş sözleşmesi test belgesi
  Future<void> _useWorkContract() async {
    setState(() {
      _isScanning = true;
      _scannedText = null;
    });
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
    setState(() {
      _scannedText = _testDocuments[2]['content'];
      _isScanning = false;
    });
  }

  // İOS simülatör için test butonu ekleyelim
  Widget _buildTestButton() {
    return kDebugMode
        ? Container(
            margin: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.bug_report),
              label: const Text('Simülatör Test Modu'),
              onPressed: _useTestImage,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  // Ana galeri seçim işlevi
  Future<void> _getImage(ImageSource source) async {
    // İşlem zaten devam ediyorsa çık
    if (_isPickingImage) return;
    
    setState(() {
      _isScanning = true;
      _isPickingImage = true;
      _scannedText = null;
    });
    
    try {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görüntü seçiliyor...'), duration: Duration(seconds: 1)),
      );
      
      XFile? pickedFile;
      
      if (source == ImageSource.camera) {
        // Kamera için
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 60,
          maxWidth: 1200,
          maxHeight: 1200,
          requestFullMetadata: false,
        );
      } else {
        // Galeri için - yalnızca iOS'ta özel yaklaşım
        if (Platform.isIOS) {
          try {
            // En basit haliyle çağırın - daha az metadata
            pickedFile = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 60,
              requestFullMetadata: false,  // Daha az metadata
            );
          } catch (e) {
            print('iOS Galeri Hatası: $e');
            // İkinci bir deneme yapmıyoruz - UI hatalarını önler
          }
        } else {
          // Android 
          pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 60,
          );
        }
      }
      
      if (!mounted) return;
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        setState(() {
          _imageFile = file;
        });
        
        await _recognizeText();
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Görüntü seçme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görüntü alınırken bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isPickingImage = false;
        });
      }
    }
  }

  // Galeri seçiminde sorun yaşamamak için alternatif bottom sheet yaklaşımı
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Fotoğraf Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              // Test seçenekleri
              if (kDebugMode) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Test Seçenekleri', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined, color: Colors.blue),
                  title: const Text('Örnek Satış Sözleşmesi'),
                  subtitle: const Text('Test taraması'),
                  onTap: () {
                    Navigator.pop(context);
                    _useExampleDocument();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: Colors.green),
                  title: const Text('Örnek Kira Sözleşmesi'),
                  subtitle: const Text('Test taraması'),
                  onTap: () {
                    Navigator.pop(context);
                    _useTestImage();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recognizeText() async {
    if (_imageFile == null) return;
    
    setState(() {
      _isScanning = true;
    });
    
    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      setState(() {
        _scannedText = recognizedText.text;
      });
      
      print('Taranan Metin: $_scannedText');
    } catch (e) {
      print('Metin tanıma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Metin tanıma sırasında bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }
  
  // Belge içeriğiyle ana ekrana git
  void _continueWithScannedText() {
    if (_scannedText == null || _scannedText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarama sonucu boş. Lütfen tekrar deneyin.')),
      );
      return;
    }
    
    // Belgenin ilk satırını belge başlığı olarak kullan (veya ilk 30 karakteri)
    final documentTitle = _scannedText!.split('\n').first.trim();
    final firstLine = documentTitle.length > 30 ? '${documentTitle.substring(0, 30)}...' : documentTitle;
    
    // AI danışmanına gönderilecek metin
    String promptText = 'Bu belgeyi incele ve hukuki açıdan değerlendir:\n\n';
    promptText += _scannedText!;
    
    // Ana danışma ekranına tarama sonucuyla git
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => AdvisorScreen(
          initialMessage: promptText,
          startWithDocumentPrompt: true,
        ),
      ),
    );
    
    // Devam edildiğini göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$firstLine belgesi inceleniyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Test belgesi seçme modalını göster
  void _showTestDocumentsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Test Belgelerini Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // Test belgeleri listesi
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _testDocuments.length,
                itemBuilder: (context, index) {
                  final document = _testDocuments[index];
                  return ListTile(
                    leading: Icon(
                      index == 0 ? Icons.home_outlined : 
                      index == 1 ? Icons.shopping_cart_outlined : 
                      Icons.work_outline,
                      color: index == 0 ? Colors.green : 
                             index == 1 ? Colors.blue : 
                             Colors.orange,
                    ),
                    title: Text(document['title']!),
                    subtitle: Text('${document['content']!.split('\n').take(3).join(' ').substring(0, 30)}...'),
                    onTap: () {
                      Navigator.pop(context);
                      if (index == 0) {
                        _useTestImage();
                      } else if (index == 1) {
                        _useExampleDocument();
                      } else if (index == 2) {
                        _useWorkContract();
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belge Tarama', style: TextStyle(color: AppTheme.primaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          // Debug modunda veya sadece simülatörde görünecek test butonu
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.science_outlined, color: Colors.grey),
              onPressed: () => _showTestDocumentsModal(),
              tooltip: 'Test Belgeleri',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isScanning)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Taranıyor...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                else if (_scannedText != null) ...[
                  if (_imageFile != null)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tarama Sonucu:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      _scannedText!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Bu Metinle Devam Et'),
                    onPressed: _continueWithScannedText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden Tara'),
                    onPressed: () => _showImageSourceOptions(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: const BorderSide(color: AppTheme.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ] else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.document_scanner,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Taramak için bir belge seçin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera ile Tara'),
                        onPressed: () => _getImage(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeriden Seç'),
                        onPressed: () => _showImageSourceOptions(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                          side: const BorderSide(color: AppTheme.secondaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Test butonu ekle - sadece debug modda görünür
                      _buildTestButton(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 