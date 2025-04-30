import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/document_template.dart';
import '../../providers/document_providers.dart';
import 'package:legalai/core/theme/app_theme.dart';

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
                icon: Icon(Icons.download_outlined, size: 20),
                label: Text('İndir'),
                onPressed: () {
                  // TODO: PDF İndirme Mantığını Uygula
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('İndirme işlemi başlatıldı (simülasyon).'))
                  );
                },
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
                onPressed: () {
                  // TODO: PDF Paylaşma Mantığını Uygula
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Paylaşma işlemi başlatıldı (simülasyon).'))
                  );
                },
                 style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // İkincil bir stil kullanabiliriz veya aynı stilde bırakabiliriz
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