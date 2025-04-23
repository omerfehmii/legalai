import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:legalai/features/documents/data/models/document_template.dart'; // Model yolunu kontrol edin
import 'package:legalai/main.dart'; // HiveBoxes için (veya sabitleri ayrı bir dosyaya taşıyın)

class TemplateLoader {
  static Future<void> loadInitialTemplatesIfNeeded() async {
    final templateBox = Hive.box<DocumentTemplate>(HiveBoxes.documentTemplates);

    // Eğer kutu boşsa veya belirli bir kontrol mekanizması (örn: versiyon kontrolü)
    // gerektiriyorsa şablonları yükle. Şimdilik sadece boş olup olmadığını kontrol edelim.
    if (templateBox.isEmpty) {
      print('Template box is empty. Loading initial templates...'); // Eklendi: Yükleme başlangıcı logu
      try {
        // Assets manifest dosyasını oku (assets klasöründeki tüm dosyaları listeler)
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);

        // Sadece assets/templates/ içindeki .json dosyalarını filtrele
        final templatePaths = manifestMap.keys
            .where((String key) => key.startsWith('assets/templates/') && key.endsWith('.json'))
            .toList();

        if (templatePaths.isEmpty) {
          print('No template files found in assets/templates/'); // Eklendi: Dosya bulunamadı logu
          return; // Dosya yoksa devam etme
        } else {
           print('Found templates: ${templatePaths.join(', ')}'); // Eklendi: Bulunan dosyaları logla
        }


        for (final path in templatePaths) {
          try {
            final jsonString = await rootBundle.loadString(path);
            final Map<String, dynamic> jsonMap = json.decode(jsonString);
            final template = DocumentTemplate.fromJson(jsonMap);
            // Hive'a eklerken anahtar olarak template.id'yi kullanıyoruz.
            // Eğer aynı ID'ye sahip bir şablon zaten varsa üzerine yazılır.
            await templateBox.put(template.id, template);
            print('Loaded template: ${template.id}');
          } catch (e) {
            print('Error loading or parsing template from $path: $e'); // Daha detaylı log
            // Hata yönetimi: Belirli bir şablon yüklenemezse ne yapılmalı?
            // Belki loglama yapılabilir veya kullanıcıya bilgi verilebilir.
          }
        }
        print('Initial templates loading process finished.'); // Yükleme bitişi logu
      } catch (e) {
        print('Error loading AssetManifest.json or processing templates: $e');
        // Genel hata yönetimi
      }
    } else {
      print('Template box is not empty. Skipping initial load.');
    }
  }
} 