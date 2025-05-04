import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:legalai/features/documents/data/models/saved_document.dart';
import 'package:legalai/features/documents/services/document_generation_service.dart';
import 'package:legalai/screens/pdf_viewer_screen.dart';

class DocumentEditorScreen extends StatefulWidget {
  final SavedDocument document;

  const DocumentEditorScreen({Key? key, required this.document}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Belge Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Kaydet',
            onPressed: _saveDocument,
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Önizle',
            onPressed: _previewDocument,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildEditorBody(),
    );
  }
  
  Widget _buildEditorBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
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
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Belge Başlığı',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Belge türü bilgisi (salt okunur)
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Belge Türü: ${widget.document.documentType}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Belge içeriği
          const Text(
            'Belge İçeriği',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Belge içeriğini buraya yazın...',
            ),
            maxLines: 20, // Çok satırlı içerik için
            textAlignVertical: TextAlignVertical.top,
          ),
          const SizedBox(height: 24),
          
          // Belge Kaydet ve Önizle Butonları
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveDocument,
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _previewDocument,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Önizle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          
          // Not: Düzenleme yapıldığında orijinal belge yeniden oluşturulacaktır
          const SizedBox(height: 16),
          const Text(
            'Not: Değişiklikler yapıldığında, yeni bir PDF belgesi oluşturulacaktır.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            textAlign: TextAlign.center,
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
      
      // Hive kaydını güncelle
      final updatedDocument = SavedDocument(
        title: newTitle,
        documentType: widget.document.documentType,
        collectedData: widget.document.collectedData,
        pdfPath: pdfPath,
        generatedContent: newContent,
      );
      // SavedDocument ID'sini koru
      updatedDocument.id = widget.document.id;
      
      // Hive'a kaydet
      final box = await Hive.openBox<SavedDocument>('saved_documents');
      await box.put(updatedDocument.id, updatedDocument);
      
      print('Belge güncellendi, ID: ${updatedDocument.id}');
      
      // Kullanıcıya başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge başarıyla güncellendi')),
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