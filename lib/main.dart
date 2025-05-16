import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Hive Modellerini ve Adaptörlerini import et
import 'features/advisor/data/models/advisor_message.dart';
import 'features/advisor/data/models/advisor_session.dart';
import 'features/documents/data/models/document_field.dart';
import 'features/documents/data/models/document_template.dart';
import 'features/documents/data/models/saved_document_draft.dart';
import 'features/documents/data/models/saved_document.dart'; // Import SavedDocument
import 'core/hive/template_loader.dart'; // TemplateLoader'ı import et
import 'core/services/connectivity_service.dart'; // Çevrimdışı servisini import et
import 'core/services/offline_sync_service.dart'; // Senkronizasyon servisini import et
import 'core/services/theme_service.dart'; // Tema servisini import et
import 'features/home/ui/screens/home_screen.dart'; // HomeScreen'i import et
import 'core/theme/app_theme.dart'; // App theme'i import et
import 'features/onboarding/ui/screens/onboarding_screen.dart'; // Onboarding ekranını import et

// Hive Box isimleri için sabitler
class HiveBoxes {
  static const String chatHistory = 'advisorMessages';
  static const String chatSessions = 'advisorSessions';
  static const String documentTemplates = 'document_templates';
  static const String savedDrafts = 'document_drafts';
  static const String savedDocuments = 'saved_documents';
  static const String pendingOperations = 'pending_operations';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sistem UI rengini ayarla
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiStyleForBrightness(Brightness.light));

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
  Hive.registerAdapter(DocumentStatusAdapter());

  // 3. Hive Kutularını Açma
  await Hive.openBox<AdvisorMessage>(HiveBoxes.chatHistory);
  await Hive.openBox<AdvisorSession>(HiveBoxes.chatSessions);
  await Hive.openBox<DocumentTemplate>(HiveBoxes.documentTemplates);
  await Hive.openBox<SavedDocumentDraft>(HiveBoxes.savedDrafts);
  await Hive.openBox<SavedDocument>(HiveBoxes.savedDocuments);
  await Hive.openBox<String>(HiveBoxes.pendingOperations);

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

  // 5. Bağlantı durumunu kontrol et
  final connectivityResult = await Connectivity().checkConnectivity();
  final initialConnectionStatus = connectivityResult == ConnectivityResult.none
      ? ConnectionStatus.offline
      : ConnectionStatus.online;
      
  // 6. SharedPreferences'i başlat
  final sharedPreferences = await SharedPreferences.getInstance();

  // Uygulamayı Riverpod ProviderScope ile sarmalayarak çalıştır
  runApp(
    ProviderScope(
      overrides: [
        // İlk başlatma sırasında bağlantı durumunu ayarla
        connectivityProvider.overrideWith((ref) {
          final service = ConnectivityService();
          service.state = initialConnectionStatus;
          return service;
        }),
        // SharedPreferences'i provider olarak sağla
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: MyApp(),
    ),
  );
}

// Ana Uygulama Widget'ı
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Çevrimdışı durumunu dinle
    ref.watch(connectivityProvider);
    
    // Onboarding durumunu kontrol et
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    
    // Tema modunu izle
    final appThemeMode = ref.watch(themeModeProvider);
    
    // Sistem UI rengini tema moduna göre ayarla
    final isDarkMode = appThemeMode == AppThemeMode.dark || 
      (appThemeMode == AppThemeMode.system && 
        MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    SystemChrome.setSystemUIOverlayStyle(
      AppTheme.systemUiStyleForBrightness(
        isDarkMode ? Brightness.dark : Brightness.light
      )
    );
    
    return MaterialApp(
      title: 'LegalAI',
      themeMode: ref.watch(flutterThemeModeProvider),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: onboardingCompleted.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const OfflineNotification(child: HomeScreen()),
        data: (completed) {
          // Kullanıcı ilk kez uygulamayı açıyorsa onboarding ekranını göster
          if (!completed) {
            return const OnboardingScreen();
          }
          // Değilse ana ekrana yönlendir
          return const OfflineNotification(child: HomeScreen());
        },
      ),
    );
  }
}

// Geçici şablonları yükle
Future<void> _loadInitialTemplatesIfNeeded() async {
  // Şablonların olup olmadığını kontrol et
  final box = await Hive.openBox<DocumentTemplate>(HiveBoxes.documentTemplates);
  if (box.isEmpty) {
    // Şablonları yükle
    // TODO: Şablon yükleme işlemini implement et
  }
} 