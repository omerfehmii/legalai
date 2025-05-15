import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:legalai/features/documents/data/models/saved_document.dart';
import 'package:legalai/features/documents/services/document_generation_service.dart';
import 'package:legalai/screens/pdf_viewer_screen.dart';
import 'package:legalai/core/theme/app_theme.dart';

class DocumentEditorScreen extends StatefulWidget {
  final SavedDocument document;
  
  // Callback fonksiyonu ekleniyor
  final Function(String, String)? onSave;

  const DocumentEditorScreen({
    Key? key, 
    required this.document, 
    this.onSave,
  }) : super(key: key);

  @override
  _DocumentEditorScreenState createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Mevcut belge başlığını ve içeriğini editörlere yükle
    _titleController = TextEditingController(text: widget.document.title);
    _contentController = TextEditingController(
      text: widget.document.generatedContent ?? 'Belge içeriği bulunamadı'
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Belge Düzenle'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.save, color: AppTheme.primaryColor),
                tooltip: 'Kaydet',
                onPressed: _saveDocument,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
        : _buildEditorBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _previewDocument,
        backgroundColor: AppTheme.secondaryColor,
        child: const Icon(Icons.visibility),
      ),
    );
  }
  
  Widget _buildEditorBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Belge Başlığı
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Belge Başlığı',
                border: InputBorder.none,
                labelStyle: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Belge türü bilgisi (salt okunur)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belge Türü',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.document.documentType,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Belge içeriği
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belge İçeriği',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    hintText: 'Belge içeriğini buraya yazın...',
                  ),
                  maxLines: 20,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Kaydet Butonu
          ElevatedButton.icon(
            onPressed: _saveDocument,
            icon: const Icon(Icons.save),
            label: const Text('Kaydet ve Çık'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Belgeyi kaydetme işlemi
  Future<void> _saveDocument() async {
    // Yükleniyor durumunu ayarla
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final newTitle = _titleController.text.trim();
      final newContent = _contentController.text;
      
      if (newTitle.isEmpty) {
        throw Exception('Belge başlığı boş olamaz');
      }
      
      if (newContent.isEmpty) {
        throw Exception('Belge içeriği boş olamaz');
      }
      
      // Eğer callback fonksiyonu tanımlanmışsa çağır
      if (widget.onSave != null) {
        widget.onSave!(newTitle, newContent);
        Navigator.pop(context);
        return;
      }

      // PDF'i yeniden oluştur
      final documentGenerationService = DocumentGenerationService();
      final pdfPath = await documentGenerationService.generatePdfFromContent(
        newContent, 
        newTitle
      );
      
      print('Düzenlenen belge PDF yolu: $pdfPath');
      
      // Eski PDF dosyasını sil
      if (widget.document.pdfPath != null) {
        final oldFile = File(widget.document.pdfPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
          print('Eski PDF dosyası silindi: ${widget.document.pdfPath}');
        }
      }
      
      // Belge verisini güncelle
      widget.document.title = newTitle;
      widget.document.generatedContent = newContent;
      widget.document.pdfPath = pdfPath;
      
      // Hive'a kaydet
      await widget.document.save();
      
      print('Belge güncellendi, ID: ${widget.document.id}');
      
      // Kullanıcıya başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belge başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Önceki ekrana geri dön
        Navigator.pop(context, true); // true = güncelleme yapıldı
      }
      
    } catch (e) {
      print('Belge güncellenirken hata oluştu: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Belge güncellenirken hata oluştu: $e';
      });
    }
  }
  
  // Belge önizleme işlemi
  Future<void> _previewDocument() async {
    try {
      final content = _contentController.text;
      
      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önizlemek için belge içeriği gereklidir'))
        );
        return;
      }
      
      // PdfViewerScreen kullanarak belgeyi önizle
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(documentContent: content),
        ),
      );
    } catch (e) {
      print('Belge önizleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Önizleme oluşturulamadı: $e'))
      );
    }
  }
} 