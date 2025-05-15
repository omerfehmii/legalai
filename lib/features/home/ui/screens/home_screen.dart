import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:card_swiper/card_swiper.dart';
import 'dart:ui'; // For ImageFilter
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/advisor/ui/screens/advisor_screen.dart';
import 'package:legalai/screens/saved_documents_screen.dart';
import 'package:legalai/features/help/ui/screens/feature_tour_screen.dart';
// import 'package:legalai/features/document_analysis/ui/screens/document_analysis_screen.dart'; // Kaldırıldı
// import 'package:legalai/features/document_scanner/ui/screens/document_scanner_screen.dart'; // Scan özelliği kaldırıldı

// Hangi içeriğin gösterileceğini belirten enum
enum HomeScreenContent {
  home,
  profile,
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Hangi içeriğin gösterileceğini tutan değişken
  HomeScreenContent _currentContent = HomeScreenContent.home;
  
  // Tema için boolean değer
  bool isDarkMode = false;
  
  // Dil seçimi için değer
  String selectedLanguage = 'Türkçe';
  
  // Bildirim ayarı için değer
  bool notificationsEnabled = true;

  // İçeriği değiştiren fonksiyon
  void _switchContent(HomeScreenContent content) {
    setState(() {
      _currentContent = content;
    });
  }

  // Örnek belge modelleri
  final List<DocumentModel> documents = const [
    DocumentModel(
      id: '1',
      title: 'Kira Sözleşmesi',
      summary: 'Konut kiralaması için hazırlanan yasal sözleşme.',
      date: '10 Mayıs 2023',
      type: 'Sözleşme',
      text: 'MADDE 1 - TARAFLAR\n\nKiraya veren: Okan Öztürk\nKiracı: Mehmet Yılmaz\n\nMADDE 2 - KİRA SÜRESİ\n\nKira süresi 12 (oniki) ay olup, ...',
    ),
    DocumentModel(
      id: '2',
      title: 'İş Sözleşmesi',
      summary: 'Belirsiz süreli iş sözleşmesi belgesi.',
      date: '25 Haziran 2023',
      type: 'Sözleşme',
      text: 'MADDE 1 - TARAFLAR\n\nİşveren: ABC Teknoloji A.Ş.\nİşçi: Ayşe Kaya\n\nMADDE 2 - ÇALIŞMA SÜRESİ\n\nİş ilişkisi belirsiz süreli olup, ...',
    ),
    DocumentModel(
      id: '3',
      title: 'Vekaletname',
      summary: 'Genel vekaletname belgesi örneği.',
      date: '12 Eylül 2023',
      type: 'Vekaletname',
      text: 'VEKALETNAME\n\nAşağıda imzası bulunan ben, Can Aydın (TC No: 12345678901), aşağıdaki işleri yapması için Hande Yıldız\'ı (TC No: 98765432109) vekil tayin ediyorum:\n\n1. Bankadaki ...',
    ),
    DocumentModel(
      id: '4',
      title: 'Satış Sözleşmesi',
      summary: 'Taşınmaz mal satış sözleşmesi.',
      date: '5 Ocak 2024',
      type: 'Sözleşme',
      text: 'TAŞINMAZ MAL SATIŞ SÖZLEŞMESİ\n\nMadde 1 - Taraflar\n\nSatıcı: Deniz Yılmaz\nAlıcı: Kemal Kaya\n\nMadde 2 - Taşınmaz Bilgileri\n\nİl: İstanbul\nİlçe: Kadıköy\n\nTaşınmaz ...',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    // Set status bar style for light background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _currentContent == HomeScreenContent.home
                ? _buildHomeContent(context)
                : _buildProfileContent(context),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            // Left side pill-shaped container with two options
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
            ),
              child: Row(
              children: [
                  // First icon (home/layers icon)
                  GestureDetector(
                    onTap: () {
                      _switchContent(HomeScreenContent.home);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.layers,
                        color: _currentContent == HomeScreenContent.home
                            ? AppTheme.secondaryColor 
                            : Colors.white,
                        size: 24,
                      ),
                  ),
                ),
                
                  // Second icon (profile)
                  GestureDetector(
                    onTap: () {
                      _switchContent(HomeScreenContent.profile);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _currentContent == HomeScreenContent.profile
                            ? const Color(0xFF333333)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.person_outline,
                        color: _currentContent == HomeScreenContent.profile
                            ? AppTheme.secondaryColor 
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Ask AI quick button on right side (Changed from Add)
            GestureDetector(
              onTap: () {
                // Ask AI özelliğini başlat (parametre olmadan)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvisorScreen(),
                  ),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.secondaryColor,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ana sayfa içeriği
  Widget _buildHomeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // Top header with question mark and notification icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Question mark icon (help)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeatureTourScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.question_mark,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Notification icon with badge
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  child: const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                ),
                // Notification badge
                Positioned(
                  top: 4,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "3",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // Greeting text
        Text(
          'Merhaba,',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 32,
            height: 1.1,
          ),
        ),
        
        // Main heading
        Text(
          'Hukuki asistanınız\nyanınızda',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 40,
            height: 1.2,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: 25),
        
        // Vurgulanan Ask AI özelliği - Ana kısımda gösterilen dikkat çekici kutu
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdvisorScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.secondaryColor,
                  AppTheme.secondaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Yapay Zeka Hukuk Asistanı',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hukuki sorularınızı sorun, belge oluşturun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Main feature buttons - Yeni 3x1 grid düzeni
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          children: [
            // Ask AI button - Ön plana çıkarıldı
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.chat_bubble_outline),
              title: 'Soru Sor',
              subtitle: 'Hukuki danışmanlık',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvisorScreen()),
                );
              },
              isHighlighted: true,
            ),
            
            // Create button
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.description_outlined),
              title: 'Oluştur',
              subtitle: 'Belge oluştur',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvisorScreen(startWithDocumentPrompt: true),
                  ),
                );
              },
            ),
            
            // Docs button
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.folder_copy_outlined),
              title: 'Belgeler',
              subtitle: 'Kaydedilenler',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavedDocumentsScreen()),
                );
              },
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Son Belgeler Başlığı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Belgeler',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavedDocumentsScreen()),
                );
              },
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Son belgeler listesi
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: documents.length > 3 ? 3 : documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return _buildRecentDocumentItem(context, doc);
          },
        ),
        
        const SizedBox(height: 20),
        
        // Search bar with background color matching and gray outline
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: Colors.grey[500], size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    // Placeholder for search logic
                    print("Search query: $value");
                  },
                  decoration: InputDecoration(
                    hintText: 'Belge ara',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    fillColor: AppTheme.backgroundColor,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Son belge öğesi widget'ı
  Widget _buildRecentDocumentItem(BuildContext context, DocumentModel document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
            color: AppTheme.secondaryColor,
            size: 24,
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${document.type} • ${document.date}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        onTap: () {
          // Belge görüntüleme ekranına git
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavedDocumentsScreen()),
          );
        },
      ),
    );
  }

  // Profil sayfası içeriği
  Widget _buildProfileContent(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // Üst Kısım - Profil Bilgileri
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Üst kısım karşılama ve düzenleme butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profiliniz',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      onPressed: () {
                        // Profil adını düzenleme dialog'u
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Ad Düzenle'),
                            content: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Adınızı girin',
                                filled: true,
                              ),
                              onSubmitted: (value) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('İsim güncellendi: $value'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('İsim güncellendi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Kaydet'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Profil Avatarı
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        // Fotoğraf seçme dialog'u
                        showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Profil Fotoğrafı'),
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galeriden Seç'),
                                onTap: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Galeri seçildi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Kamera ile Çek'),
                                onTap: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kamera seçildi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_forever),
                                title: const Text('Fotoğrafı Kaldır'),
                                onTap: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fotoğraf kaldırıldı'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Kullanıcı Adı
              const Text(
                'Kullanıcı',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Kullanıcı İstatistikleri
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Belgeler', '12'),
                    _buildStatDivider(),
                    _buildStatItem('Sorular', '28'),
                    _buildStatDivider(),
                    _buildStatItem('Kayıtlı', '6 Ay'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Ayarlar Başlığı
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            'Uygulama Ayarları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        
        // Ayarlar Listesi - Uygulama
        _buildSettingsItem(
          icon: Icons.language,
          title: 'Dil',
          subtitle: selectedLanguage,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Dil Seçin'),
                children: [
                  ListTile(
                    title: const Text('Türkçe'),
                    selected: selectedLanguage == 'Türkçe',
                    leading: const Icon(Icons.check),
                    onTap: () {
                      setState(() {
                        selectedLanguage = 'Türkçe';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('English'),
                    selected: selectedLanguage == 'English',
                    leading: const Icon(Icons.check),
                    onTap: () {
                      setState(() {
                        selectedLanguage = 'English';
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
          showBadge: false,
          showSwitch: false,
          showArrow: true,
        ),
        
        _buildSettingsItem(
          icon: Icons.brightness_4,
          title: 'Koyu Tema',
          subtitle: 'Uygulama temasını değiştirin',
          onTap: () {
            setState(() {
              isDarkMode = !isDarkMode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isDarkMode ? 'Koyu tema aktif' : 'Açık tema aktif'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          showBadge: false,
          showSwitch: true,
          switchValue: isDarkMode,
          onSwitchChanged: (value) {
            setState(() {
              isDarkMode = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value ? 'Koyu tema aktif' : 'Açık tema aktif'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          showArrow: false,
        ),
        
        _buildSettingsItem(
          icon: Icons.notifications_none,
          title: 'Bildirimler',
          subtitle: 'Bildirim tercihlerinizi yönetin',
          onTap: () {
            setState(() {
              notificationsEnabled = !notificationsEnabled;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notificationsEnabled ? 'Bildirimler açık' : 'Bildirimler kapalı'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          showBadge: false,
          showSwitch: true,
          switchValue: notificationsEnabled,
          onSwitchChanged: (value) {
            setState(() {
              notificationsEnabled = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value ? 'Bildirimler açık' : 'Bildirimler kapalı'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          showArrow: false,
        ),
        
        _buildSettingsItem(
          icon: Icons.help_outline,
          title: 'Yardım ve Destek',
          subtitle: 'Sık sorulan sorular ve iletişim',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FeatureTourScreen()),
            );
          },
          showBadge: false,
        ),
        
        const SizedBox(height: 8),
        
        // Veri Temizleme Butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Verileri Temizle'),
                  content: const Text(
                    'Tüm kayıtlı belgeleriniz ve soru geçmişiniz silinecek. Bu işlem geri alınamaz.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tüm veriler temizlendi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Verileri Temizle',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        // Çıkış Yap Butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Çıkış yapıldı'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Çıkış'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text(
              'Çıkış Yap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Profil istatistik elemanı
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // İstatistikler arasındaki dikey çizgi
  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }

  // Settings Item Widget - Geliştirilmiş switch desteği
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String subtitle = '',
    bool showBadge = false,
    bool showSwitch = false,
    bool? switchValue,
    Function(bool)? onSwitchChanged,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        subtitle: subtitle.isNotEmpty 
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ) 
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBadge)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            if (showSwitch)
              Switch.adaptive(
                value: switchValue ?? false,
                onChanged: onSwitchChanged,
                activeColor: AppTheme.secondaryColor,
              )
            else if (showArrow)
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildFeatureButton(
    BuildContext context, {
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false, // Vurgulanacak buton için yeni parametre
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted 
              ? AppTheme.secondaryColor.withOpacity(0.1) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: isHighlighted
              ? Border.all(color: AppTheme.secondaryColor, width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isHighlighted
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWireframeIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
      ),
      child: Icon(
        icon,
        size: 20,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

// Belge modeli
class DocumentModel {
  final String id;
  final String title;
  final String summary;
  final String date;
  final String type;
  final String text;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.date,
    required this.type,
    required this.text,
  });
} 