import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../data/models/document_template.dart';
import '../../providers/document_providers.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/main.dart';

/// Oluşturulan PDF belgesini önizleme ve indirme/paylaşma ekranı
class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final String pdfPath;
  final DocumentTemplate template;
  final Map<String, dynamic> fieldValues;

  const DocumentPreviewScreen({
    Key? key,
    required this.pdfPath,
    required this.template,
    required this.fieldValues,
  }) : super(key: key);

  @override
  ConsumerState<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Belge Taslağı Hazır',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
          ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Butonların genişlemesi için
        children: [
              // --- PDF Görüntüleyici Alanı (Placeholder) ---
                Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12.0),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          ),
            child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined, 
                          size: 64, 
                          color: theme.colorScheme.primary
                              ),
                        const SizedBox(height: 16),
                        Text(
                          'PDF Önizlemesi Burada Gösterilecek',
                          style: theme.textTheme.titleMedium,
                              ),
                        const SizedBox(height: 8),
                        Text(
                          '(PDF görüntüleyici entegre edilecek)',
                           style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // --- Eylem Butonları ---
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                    : Icon(Icons.save_alt_outlined, size: 20),
                label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                onPressed: _isSaving ? null : _savePdfPermanently,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.share_outlined, size: 20),
                label: Text('Paylaş'),
                onPressed: _shareDocument,
                 style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.secondary, 
                  foregroundColor: theme.colorScheme.onSecondary,
                  textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
              ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 8), // Alt boşluk
            ],
            ),
          ),
      ),
    );
  }

  /// Belgeyi telefonun varsayılan PDF görüntüleyicisiyle açar
  Future<void> _openDocument() async {
    try {
      await OpenFilex.open(widget.pdfPath);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belge açılamadı: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Belgeyi paylaşma menüsünü açar
  Future<void> _shareDocument() async {
    final tempFile = File(widget.pdfPath);
    if (!await tempFile.exists()) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Paylaşılacak dosya bulunamadı. Lütfen tekrar oluşturun.')),
       );
       return;
    }
    
    try {
      final file = XFile(widget.pdfPath);
      await Share.shareXFiles(
        [file], 
        text: '${widget.template.name} Belgesi',
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belge paylaşılamadı: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// PDF'i kalıcı dizine kopyalar ve Hive'a kaydeder
  Future<void> _savePdfPermanently() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final tempFile = File(widget.pdfPath);
      if (!await tempFile.exists()) {
        throw Exception("Oluşturulan geçici PDF dosyası bulunamadı.");
      }
      
      // Kalıcı dizini al
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String permanentDirPath = appDocDir.path;
      
      // Yeni dosya adı oluştur (Türkçe karakterleri ve boşlukları değiştir)
      final String safeTemplateName = widget.template.name
          .replaceAll(RegExp(r'[\/\\:*?"<>|ıİşŞğĞçÇöÖüÜ ]'), '_');
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String newFileName = '${safeTemplateName}_$timestamp.pdf';
      final String permanentFilePath = '$permanentDirPath/$newFileName';
      
      // Dosyayı kalıcı dizine kopyala
      final File permanentFile = await tempFile.copy(permanentFilePath);
      print('PDF copied to: ${permanentFile.path}');
      
      // Hive'a kaydet
      final box = Hive.box(HiveBoxes.savedDocuments);
      await box.put(
        permanentFile.path, // Use path as key for simplicity, or generate UUID
        {
          'filePath': permanentFile.path,
          'name': widget.template.name, // Use template name or allow user input later
          'savedAt': DateTime.now(),
        },
      );
       print('Saved document info to Hive box: ${HiveBoxes.savedDocuments}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belge başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Optional: Delete the temporary file after successful save
      // await tempFile.delete();
      
    } catch (e) {
      print('Error saving PDF permanently: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belge kaydedilemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Belgeyi taslak olarak kaydeder
  Future<void> _saveAsDraft() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Alanları taslak olarak kaydet
      await ref.read(documentTemplateRepositoryProvider).saveDraft(
        widget.template.id, 
        widget.fieldValues,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taslak başarıyla kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Taslak kaydedilemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
} 