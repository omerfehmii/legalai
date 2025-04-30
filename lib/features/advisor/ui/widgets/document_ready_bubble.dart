import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart'; // Import open_filex
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'dart:io'; // For File operations if needed
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:legalai/core/theme/app_theme.dart';

// Placeholder for Document Ready Bubble
class DocumentReadyBubble extends StatelessWidget {
  final String? documentPath; // Assuming this is the local path to the PDF

  const DocumentReadyBubble({Key? key, this.documentPath}) : super(key: key);

  // Helper function to share the document
  Future<void> _shareDocument(BuildContext context) async {
    if (documentPath == null || documentPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşılacak belge yolu bulunamadı.'), backgroundColor: Colors.orange)
      );
      return;
    }
    try {
      final file = XFile(documentPath!); // Create XFile for sharing
      await Share.shareXFiles([file], text: 'Oluşturulan Belge Taslağı');
    } catch (e) {
      print('Error sharing document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belge paylaşılamadı: ${e.toString()}'), backgroundColor: Colors.red)
      );
    }
  }

  // Helper function to open (download/view) the document
  Future<void> _openDocument(BuildContext context) async {
     if (documentPath == null || documentPath!.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Açılacak belge yolu bulunamadı.'), backgroundColor: Colors.orange)
       );
       return;
     }
    try {
      final result = await OpenFilex.open(documentPath!);
      print('OpenFile result: ${result.message}'); // Log result
       if (result.type != ResultType.done) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Belge açılamadı: ${result.message}'), backgroundColor: Colors.orange)
         );
       }
    } catch (e) {
      print('Error opening document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belge açılamadı: ${e.toString()}'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _downloadAndOpenFile(BuildContext context) async {
    if (documentPath == null || documentPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İndirilecek belge yolu bulunamadı.')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      // Belgenin adını yoldan çıkar (son kısmı al)
      final fileName = documentPath!.split('/').last;
      // İmzalı URL oluştur (60 saniye geçerli)
      // TODO: Bucket adını doğrula ('documents' olarak varsayıldı)
      final String bucketName = 'documents'; 
      final response = await supabase.storage
          .from(bucketName)
          .createSignedUrl(documentPath!, 60); // expiresIn: 60 saniye

      final url = Uri.parse(response);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url, 
          mode: LaunchMode.externalApplication, // Tarayıcıda aç
        );
      } else {
        throw 'URL açılamadı: $url';
      }
    } on StorageException catch (e) {
       print("Supabase Storage Error: ${e.message}");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Dosya indirme linki alınamadı: ${e.message}')),
       );
    } catch (e) {
      print("Error launching URL: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belge açılamadı: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = documentPath?.split('/').last ?? 'Belge';

    return Card(
       margin: const EdgeInsets.symmetric(vertical: 10.0),
       color: Colors.green[50],
       elevation: 1,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
         side: BorderSide(color: Colors.green[200]!)
        ),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Icon(Icons.check_circle_outline, color: Colors.green[700]),
                 const SizedBox(width: 10),
                 Expanded(child: Text('Belge Taslağınız Hazır!', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green[800], fontWeight: FontWeight.bold))),
               ],
             ),
              const SizedBox(height: 16),
             Text(fileName, style: theme.textTheme.bodyMedium),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 ElevatedButton.icon(
                   icon: const Icon(Icons.visibility_outlined, size: 18), // Changed icon to visibility
                   label: const Text('Aç/İndir'), // Changed label
                   onPressed: () => _downloadAndOpenFile(context), // Call open function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    ),
                 ),
                 const SizedBox(width: 8),
                 ElevatedButton.icon(
                   icon: const Icon(Icons.share_outlined, size: 18),
                   label: const Text('Paylaş'),
                   onPressed: () => _shareDocument(context), // Call share function
                   style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    ),
                 ),
               ],
             )
           ],
         ),
       ),
    );
  }
} 