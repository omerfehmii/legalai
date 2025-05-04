import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:open_filex/open_filex.dart'; // To open PDF files
import 'dart:io'; // To check file existence
import 'package:legalai/features/documents/data/models/saved_document.dart'; // Import SavedDocument
import 'package:legalai/screens/pdf_viewer_screen.dart'; // Import to view PDFs
import 'package:legalai/screens/document_editor_screen.dart'; // Import editor screen

class SavedDocumentsScreen extends StatelessWidget {
  const SavedDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('Kaydedilen Belgeler'),
      ),
      body: box != null 
          ? _buildDocumentsList(context, box)
          : FutureBuilder<Box<SavedDocument>>(
              future: Hive.openBox<SavedDocument>('saved_documents'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Belgeler yüklenirken bir hata oluştu: ${snapshot.error}'),
                  );
                }
                
                final box = snapshot.data;
                if (box == null) {
                  return Center(
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
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<SavedDocument> documentsBox, _) {
        final documents = documentsBox.values.toList();
        
        // Sort by creation date (newest first)
        documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        if (documents.isEmpty) {
          return const Center(
            child: Text('Henüz kaydedilmiş belge bulunmuyor.'),
          );
        }
        
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(doc.title),
              subtitle: Text('${doc.documentType} - ${DateFormat('dd/MM/yyyy HH:mm').format(doc.createdAt)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Düzenleme butonu
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Düzenle',
                    onPressed: () => _editDocument(context, doc, documentsBox),
                  ),
                  // Silme butonu
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    tooltip: 'Sil',
                    onPressed: () async {
                      // Show confirmation dialog before deleting
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Belgeyi Sil'),
                            content: Text('"${doc.title}" adlı belgeyi ve kaydını kalıcı olarak silmek istediğinizden emin misiniz?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('İptal'),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(false); // Return false
                                },
                              ),
                              TextButton(
                                child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(true); // Return true
                                },
                              ),
                            ],
                          );
                        },
                      );

                      // If user confirmed deletion
                      if (confirmed == true) {
                        try {
                          // 1. Delete the Hive record
                          await documentsBox.delete(doc.id);
                          print('Deleted document with ID: ${doc.id}');

                          // 2. Delete the actual file if it exists
                          if (doc.pdfPath != null && doc.pdfPath!.isNotEmpty) {
                            final file = File(doc.pdfPath!);
                            if (await file.exists()) {
                              await file.delete();
                              print('Deleted PDF file: ${doc.pdfPath}');
                            }
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${doc.title}" başarıyla silindi.'))
                          );
                        } catch (e) {
                          print("Error deleting document: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Belge silinirken bir hata oluştu: ${e.toString()}'))
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              onTap: () async {
                if (doc.pdfPath != null && doc.pdfPath!.isNotEmpty) {
                  // Check if file exists before attempting to open
                  final file = File(doc.pdfPath!);
                  if (await file.exists()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen.fromPath(pdfPath: doc.pdfPath!),
                      ),
                    );
                  } else {
                    print('File not found: ${doc.pdfPath}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF dosyası bulunamadı. Yeniden oluşturmak için belge içeriğini kullanıyoruz...'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    // PDF missing, but we can regenerate if we have the content
                    if (doc.generatedContent != null && doc.generatedContent!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(documentContent: doc.generatedContent!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Belge içeriği bulunamadı ve PDF dosyası yok.')),
                      );
                    }
                  }
                } else if (doc.generatedContent != null && doc.generatedContent!.isNotEmpty) {
                  // We have content but no PDF, so generate one
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(documentContent: doc.generatedContent!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bu belgede gösterilecek içerik bulunamadı.')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  // Belge düzenleme ekranına geçiş
  Future<void> _editDocument(BuildContext context, SavedDocument document, Box<SavedDocument> box) async {
    // Belgenin içeriği yoksa düzenleme yapılamaz
    if (document.generatedContent == null || document.generatedContent!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Düzenlenecek belge içeriği bulunamadı.'))
      );
      return;
    }
    
    // Düzenleme ekranına git ve sonucu bekle
    final wasUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentEditorScreen(document: document),
      ),
    );
    
    // Eğer belge güncellendiyse, listeyi yenile
    if (wasUpdated == true) {
      // ValueListenable ile otomatik yenilenir, manuel yenileme gerekmez
      // Bununla birlikte, UI güncellemesi için kullanıcıya bilgi verebiliriz
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge başarıyla güncellendi ve liste yenilendi.'))
      );
    }
  }
} 