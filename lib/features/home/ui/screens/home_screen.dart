import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:card_swiper/card_swiper.dart';
import 'dart:ui'; // For ImageFilter
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/chat/ui/screens/chat_screen.dart';

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

  // İçeriği değiştiren fonksiyon
  void _switchContent(HomeScreenContent content) {
    setState(() {
      _currentContent = content;
    });
  }

  // Example document models - fetch from database in real app
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
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
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
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Add button on right side
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
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
            Container(
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
                        "5",
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
        
        const SizedBox(height: 40),
        
        // Greeting text
        Text(
          'Hi Nixtio,',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 32,
            height: 1.1,
          ),
        ),
        
        // Main heading
        Text(
          'How can I help\nyou today?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 40,
            height: 1.2,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Main feature buttons - 2x2 grid
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          children: [
            // Scan button
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.document_scanner_outlined),
              title: 'Scan',
              subtitle: 'Documents, ID cards...',
              onTap: () {
                // Handle scan tap
              },
            ),
            
            // Create button
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.crop_square_outlined),
              title: 'Create',
              subtitle: 'Sign, add text, mark...',
              onTap: () {
                // Handle edit tap
              },
            ),
            
            // Docs button
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.arrow_outward_outlined),
              title: 'Docs',
              subtitle: 'PDF, DOCX, JPG, TX...',
              onTap: () {
                // Handle convert tap
              },
            ),
            
            // Ask AI button
            _buildFeatureButton(
              context,
              iconWidget: _buildWireframeIcon(Icons.grid_3x3_outlined),
              title: 'Ask AI',
              subtitle: 'Summarize, finish wri...',
              onTap: () {
                // Doğrudan yeni bir sohbet başlat
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
            ),
          ],
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
                  decoration: InputDecoration(
                    hintText: 'Search',
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

  // Profil sayfası içeriği
  Widget _buildProfileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        
        // Profil sayfası başlık
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Profil',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // Profile Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // User Name
        const Text(
          'Nixtio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Email
        Text(
          'kullanici@ornek.com',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Settings List
        _buildSettingsItem(
          icon: Icons.person_outline,
          title: 'Kişisel Bilgiler',
          onTap: () {},
        ),
        
        _buildSettingsItem(
          icon: Icons.notifications_none,
          title: 'Bildirimler',
          onTap: () {},
        ),
        
        _buildSettingsItem(
          icon: Icons.lock_outline,
          title: 'Gizlilik ve Güvenlik',
          onTap: () {},
        ),
        
        _buildSettingsItem(
          icon: Icons.help_outline,
          title: 'Yardım ve Destek',
          onTap: () {},
        ),
        
        _buildSettingsItem(
          icon: Icons.settings_outlined,
          title: 'Ayarlar',
          onTap: () {},
        ),
        
        const SizedBox(height: 20),
        
        // Logout Button
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Settings Item Widget
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.primaryColor,
          size: 16,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 6,
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
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconWidget,
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 19,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 12,
              ),
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

// Belge modeli (Keep DocumentModel as is)
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

// Removed PageFoldPainter as it's no longer needed 