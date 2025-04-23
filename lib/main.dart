import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Hive Modellerini ve Adaptörlerini import et
import 'features/chat/data/models/chat_message.dart';
import 'features/chat/data/models/chat_session.dart';
import 'features/documents/data/models/document_field.dart';
import 'features/documents/data/models/document_template.dart';
import 'features/documents/data/models/saved_document_draft.dart';
import 'core/hive/template_loader.dart'; // TemplateLoader'ı import et
import 'features/chat/ui/screens/chat_screen.dart'; // ChatScreen'i import et
import 'features/home/ui/screens/home_screen.dart'; // HomeScreen'i import et
import 'core/theme/app_theme.dart'; // App theme'i import et

// Uygulamanın ana widget'ını (henüz oluşturulmadı) import et (örnek: app.dart)
// import 'app.dart';

// Hive Box isimleri için sabitler (opsiyonel ama önerilir)
class HiveBoxes {
  static const String chatHistory = 'chatHistory';
  static const String chatSessions = 'chatSessions';
  static const String documentTemplates = 'documentTemplates';
  static const String savedDrafts = 'savedDrafts';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e"); // Hata durumunda logla
    // .env dosyası yüklenemezse uygulama devam etmeli mi? Karar verilebilir.
    // Şimdilik devam ediyoruz ama Supabase başlatılamayacak.
  }

  // Hive kullanımını geçici olarak atlayalım
  // 1. Hive Başlatma
  // await Hive.initFlutter();

  // 2. Hive Adaptörlerini Kaydetme
  // Hive.registerAdapter(ChatMessageAdapter());
  // Hive.registerAdapter(ChatSessionAdapter());
  // Hive.registerAdapter(DocumentFieldAdapter());
  // Hive.registerAdapter(DocumentTemplateAdapter());
  // Hive.registerAdapter(SavedDocumentDraftAdapter());

  // 3. Hive Kutularını Açma
  // await Hive.openBox<ChatMessage>(HiveBoxes.chatHistory);
  // await Hive.openBox<ChatSession>(HiveBoxes.chatSessions);
  // await Hive.openBox<DocumentTemplate>(HiveBoxes.documentTemplates);
  // await Hive.openBox<SavedDocumentDraft>(HiveBoxes.savedDrafts); // Opsiyonel MVP

  // 4. Supabase Başlatma (.env'den okuyarak)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file.');
    // Bu durumda Supabase başlatılamaz, belki bir hata ekranı gösterilebilir?
  } else {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // 5. Şablonları Assets'ten Yükleme
  // await TemplateLoader.loadInitialTemplatesIfNeeded(); // Call the loader

  // Uygulamayı Riverpod ProviderScope ile sarmalayarak çalıştır
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Örnek Ana Uygulama Widget'ı (app.dart içine taşınabilir)
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegalAI',
      theme: AppTheme.lightTheme,
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// TODO: _loadInitialTemplatesIfNeeded() fonksiyonunu implement et 