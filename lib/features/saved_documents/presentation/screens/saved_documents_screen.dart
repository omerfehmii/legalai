import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/features/saved_documents/presentation/providers/saved_documents_provider.dart';
// import 'package:legalai/common/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:legalai/features/documents/data/models/saved_document.dart';
import 'package:legalai/screens/pdf_viewer_screen.dart';

class SavedDocumentsScreen extends ConsumerWidget {
  const SavedDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedDocumentsState = ref.watch(savedDocumentsProvider);
    final documents = savedDocumentsState.documents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydedilen Belgeler'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: savedDocumentsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz kaydedilmiş belge yok.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        title: Text(
                          doc.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                           padding: const EdgeInsets.only(top: 4.0),
                           child: Text(
                            '${doc.documentType} - ${DateFormat.yMd('tr_TR').add_Hm().format(doc.createdAt)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                          tooltip: 'Sil',
                          onPressed: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Belgeyi Sil'),
                                  content: Text('\'${doc.title}\' başlıklı belgeyi silmek istediğinizden emin misiniz?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('İptal'),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Sil'),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              ref.read(savedDocumentsProvider.notifier).deleteDocument(doc.id);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text('\'${doc.title}\' silindi.'),
                                   duration: const Duration(seconds: 2),
                                 ),
                               );
                            }
                          },
                        ),
                        onTap: () {
                           if (doc.pdfPath != null && doc.pdfPath!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen.fromPath(pdfPath: doc.pdfPath!),
                                ),
                              );
                            } else if (doc.generatedContent != null && doc.generatedContent!.isNotEmpty) {
                              // If we have the generated content but no PDF, we can regenerate the PDF
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen(documentContent: doc.generatedContent!),
                                ),
                              );
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(
                                   content: Text('Belge içeriği bulunamadı.'),
                                   duration: Duration(seconds: 2),
                                 ),
                               );
                             }
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 