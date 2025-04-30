import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:open_filex/open_filex.dart'; // To open PDF files
import 'dart:io'; // To check file existence

class SavedDocumentsScreen extends StatelessWidget {
  const SavedDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure the box is open. It's better to open boxes in main.dart
    // but opening here ensures it's available if not opened earlier.
    final box = Hive.box('saved_documents'); // Assuming the box is already open

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydedilen Belgeler'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box snapshotBox, _) {
          // Get keys in reverse order to show newest first
          final keys = snapshotBox.keys.toList().reversed.toList();

          if (keys.isEmpty) {
            return const Center(
              child: Text('Henüz kaydedilmiş belge bulunmuyor.'),
            );
          }

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final data = snapshotBox.get(key) as Map?; // Get data as Map

              if (data == null) {
                // Handle cases where data might be null or not a Map
                return const ListTile(title: Text('Geçersiz kayıt'));
              }

              final String filePath = data['filePath'] ?? 'Bilinmiyor';
              final String name = data['name'] ?? 'İsimsiz Belge';
              final DateTime savedAt = data['savedAt'] ?? DateTime.now();

              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(name),
                subtitle: Text('Kaydedildi: ${DateFormat('dd/MM/yyyy HH:mm').format(savedAt)}\n${filePath.split('/').last}'), // Show date and filename
                isThreeLine: true, // Allows more space for subtitle
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  tooltip: 'Belgeyi Sil',
                  onPressed: () async {
                    // Show confirmation dialog before deleting
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Belgeyi Sil'),
                          content: Text('"$name" adlı belgeyi ve kaydını kalıcı olarak silmek istediğinizden emin misiniz?'),
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
                        await snapshotBox.delete(key);
                        print('Hive record deleted for key: $key');

                        // 2. Delete the actual file
                        if (filePath != 'Bilinmiyor') {
                          final file = File(filePath);
                          if (await file.exists()) {
                            await file.delete();
                            print('File deleted: $filePath');
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"$name" başarıyla silindi.'))
                        );
                      } catch (e) {
                        print("Error deleting document (key: $key, path: $filePath): $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Belge silinirken bir hata oluştu: ${e.toString()}'))
                        );
                      }
                    }
                  },
                ),
                onTap: () async {
                  if (filePath == 'Bilinmiyor') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dosya yolu bulunamadı.')),
                    );
                    return;
                  }
                  // Check if file exists before attempting to open
                  final file = File(filePath);
                  if (await file.exists()) {
                    final result = await OpenFilex.open(filePath);
                    print('OpenFilex result: ${result.type} - ${result.message}');
                    if (result.type != ResultType.done) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dosya açılamadı: ${result.message}')),
                      );
                    }
                  } else {
                    print('File not found: $filePath');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dosya bulunamadı. Kayıt siliniyor...'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    // File doesn't exist, remove the dangling record from Hive
                    await snapshotBox.delete(key);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
} 