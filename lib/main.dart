import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Hive Modellerini ve Adaptörlerini import et
import 'features/advisor/data/models/advisor_message.dart';
import 'features/advisor/data/models/advisor_session.dart';
import 'features/documents/data/models/document_field.dart';
import 'features/documents/data/models/document_template.dart';
import 'features/documents/data/models/saved_document_draft.dart';
import 'features/documents/data/models/saved_document.dart'; // Import SavedDocument
import 'core/hive/template_loader.dart'; // TemplateLoader'ı import et
// import 'features/chat/ui/screens/chat_screen.dart';
import 'features/home/ui/screens/home_screen.dart'; // HomeScreen'i import et
import 'core/theme/app_theme.dart'; // App theme'i import et

// Uygulamanın ana widget'ını (henüz oluşturulmadı) import et (örnek: app.dart)
// import 'app.dart';

// Hive Box isimleri için sabitler
class HiveBoxes {
  static const String chatHistory = 'advisorMessages';
  static const String chatSessions = 'advisorSessions';
  static const String documentTemplates = 'document_templates';
  static const String savedDrafts = 'document_drafts';
  static const String savedDocuments = 'saved_documents';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e"); // Hata durumunda logla
  }

  // 1. Hive Başlatma
  await Hive.initFlutter();

  // 2. Hive Adaptörlerini Kaydetme
  Hive.registerAdapter(AdvisorMessageAdapter());
  Hive.registerAdapter(AdvisorSessionAdapter());
  Hive.registerAdapter(DocumentFieldAdapter());
  Hive.registerAdapter(DocumentTemplateAdapter());
  Hive.registerAdapter(SavedDocumentDraftAdapter());
  Hive.registerAdapter(SavedDocumentAdapter());

  // 3. Hive Kutularını Açma
  await Hive.openBox<AdvisorMessage>(HiveBoxes.chatHistory);
  await Hive.openBox<AdvisorSession>(HiveBoxes.chatSessions);
  await Hive.openBox<DocumentTemplate>(HiveBoxes.documentTemplates);
  await Hive.openBox<SavedDocumentDraft>(HiveBoxes.savedDrafts);
  await Hive.openBox<SavedDocument>(HiveBoxes.savedDocuments);

  // 4. Supabase Başlatma (.env'den okuyarak)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file.');
  } else {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // 5. Belge şablonlarını yükle
  // DocumentTemplateRepository sınıfı otomatik olarak ilk açılışta şablonları yükleyecek

  // Uygulamayı Riverpod ProviderScope ile sarmalayarak çalıştır
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Ana Uygulama Widget'ı
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