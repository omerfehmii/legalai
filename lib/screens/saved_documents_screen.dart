import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:open_filex/open_filex.dart'; // To open PDF files
import 'dart:io'; // To check file existence
import 'package:legalai/features/documents/data/models/saved_document.dart'; // Import SavedDocument
import 'package:legalai/screens/pdf_viewer_screen.dart'; // Import to view PDFs
import 'package:legalai/screens/document_editor_screen.dart'; // Import editor screen
import 'package:legalai/core/theme/app_theme.dart';

class SavedDocumentsScreen extends StatelessWidget {
  const SavedDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Try to get an existing reference to the box if it's already open
    Box<SavedDocument>? box;
    try {
      if (Hive.isBoxOpen('saved_documents')) {
        box = Hive.box<SavedDocument>('saved_documents');
      }
    } catch (e) {
      print('Error accessing saved_documents box: $e');
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
        title: Text(
          'Belgelerim',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                onPressed: () {
                  // Arama işlevselliği burada eklenebilir
                },
              ),
            ),
          ),
        ],
      ),
      body: box != null
          ? _buildDocumentsList(context, box)
          : FutureBuilder<Box<SavedDocument>>(
              future: Hive.openBox<SavedDocument>('saved_documents'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belgeler yüklenirken bir hata oluştu',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final box = snapshot.data;
                if (box == null) {
                  return const Center(
                    child: Text('Belge kutusu bulunamadı.'),
                  );
                }

                return _buildDocumentsList(context, box);
              },
            ),
    );
  }
  
  // Extracted the document list building logic to a separate method
  Widget _buildDocumentsList(BuildContext context, Box<SavedDocument> box) {
    final theme = Theme.of(context);
    
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<SavedDocument> documentsBox, _) {
        final documents = documentsBox.values.toList();
        
        // Sort by creation date (newest first)
        documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Henüz kaydedilmiş belge yok',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oluşturduğunuz belgeler burada görünecek',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Yeni Belge Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Burada direkt belge oluşturma ekranına yönlendirme yapılabilir
                  },
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet bilgiler
              Container(
                margin: const EdgeInsets.only(bottom: 16, top: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      icon: Icons.description_outlined,
                      title: '${documents.length}',
                      subtitle: 'Toplam Belge',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[200],
                    ),
                    _buildSummaryItem(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: DateFormat('dd MMM').format(DateTime.now()),
                      subtitle: 'Bugün',
                    ),
                  ],
                ),
              ),
              
              // Belge türleri
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                child: Text(
                  'Belgelerim',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Belge listesi
              Expanded(
                child: documents.isEmpty
                    ? const Center(child: Text('Belge bulunamadı.'))
                    : ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          return _buildDocumentCard(context, doc, documentsBox);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    SavedDocument doc,
    Box<SavedDocument> documentsBox,
  ) {
    final theme = Theme.of(context);
    
    // Belge türüne göre ikon belirle
    IconData docIcon;
    Color iconColor;
    
    switch (doc.documentType.toLowerCase()) {
      case 'sözleşme':
        docIcon = Icons.assignment_outlined;
        iconColor = Colors.blue;
        break;
      case 'vekaletname':
        docIcon = Icons.gavel_outlined;
        iconColor = Colors.purple;
        break;
      case 'dilekçe':
        docIcon = Icons.article_outlined;
        iconColor = Colors.teal;
        break;
      default:
        docIcon = Icons.description_outlined;
        iconColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            if (doc.pdfPath != null && doc.pdfPath!.isNotEmpty) {
              final file = File(doc.pdfPath!);
              if (await file.exists()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen.fromPath(pdfPath: doc.pdfPath!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF dosyası bulunamadı. İçerik görüntüleniyor...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                if (doc.generatedContent != null && doc.generatedContent!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(documentContent: doc.generatedContent!),
                    ),
                  );
                }
              }
            } else if (doc.generatedContent != null && doc.generatedContent!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(documentContent: doc.generatedContent!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bu belgede görüntülenecek içerik bulunamadı')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Belge tipine göre ikonlu konteyner
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    docIcon,
                    color: iconColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Belge bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.documentType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd.MM.yyyy · HH:mm').format(doc.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // İşlem butonları
                Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                      onTap: () => _editDocument(context, doc, documentsBox),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(context, doc, documentsBox),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      ),
    );
  }

  // Extract the document editing logic
  void _editDocument(
    BuildContext context,
    SavedDocument doc,
    Box<SavedDocument> documentsBox,
  ) {
    // Navigate to document editor screen with the existing document
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentEditorScreen(
          document: doc,
          onSave: (updatedTitle, updatedContent) {
            // Update the document
            doc.title = updatedTitle;
            doc.generatedContent = updatedContent;
            doc.save(); // Save changes to Hive box
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Belge başarıyla güncellendi'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  // Extract the delete confirmation dialog
  void _showDeleteConfirmation(
    BuildContext context,
    SavedDocument doc,
    Box<SavedDocument> documentsBox,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('${doc.title} belgesini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              // If there's a PDF file associated with the document, delete it
              if (doc.pdfPath != null && doc.pdfPath!.isNotEmpty) {
                final file = File(doc.pdfPath!);
                file.exists().then((exists) {
                  if (exists) {
                    file.delete();
                  }
                });
              }
              
              // Delete from Hive box
              doc.delete();
              
              // Close dialog
              Navigator.of(ctx).pop();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Belge başarıyla silindi'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 