import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/home/ui/screens/home_screen.dart';

/// Kullanıcı ilk kez uygulamayı açtığında gösterilen onboarding ekranı
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Hukuki Asistanınıza Hoş Geldiniz',
      description: 'LegalAI ile hukuki sorunlarınıza yapay zeka destekli çözümler bulabilir, belgelerinizi hızlıca hazırlayabilirsiniz.',
      image: 'assets/logo.png',
      icon: Icons.gavel,
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'Çevrimdışı Kullanım',
      description: 'İnternet bağlantınız olmadığında bile belgelerinize erişebilir ve yeni belgeler oluşturabilirsiniz.',
      image: null,
      icon: Icons.cloud_off,
      color: Colors.blueGrey,
    ),
    OnboardingPage(
      title: 'Yapay Zeka Asistanı',
      description: 'Hukuki danışman asistanımız, sorularınızı yanıtlayabilir, belgelerinizi hazırlamanıza yardımcı olabilir.',
      image: null,
      icon: Icons.chat,
      color: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      title: 'Belge Yönetimi',
      description: 'Oluşturduğunuz tüm belgeler cihazınızda güvenle saklanır ve istediğiniz zaman düzenleyebilirsiniz.',
      image: null,
      icon: Icons.folder,
      color: Colors.teal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Onboarding ekranının tamamlandığını SharedPreferences'e kaydet
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.backgroundColor],
          ),
        ),
        child: Stack(
          children: [
            // Ana içerik - PageView
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _isLastPage = index == _pages.length - 1;
                });
              },
              itemBuilder: (context, index) {
                return _buildPageContent(_pages[index], size);
              },
            ),
            
            // Sayfa göstergesi
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: WormEffect(
                    activeDotColor: AppTheme.secondaryColor,
                    dotColor: Colors.grey.shade300,
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),
              ),
            ),
            
            // Atla ve Devam Et butonları
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Atla butonu
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'Atla',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    
                    // Devam Et / Başla butonları
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (_isLastPage) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(_isLastPage ? 'Başla' : 'Devam Et'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page, Size size) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon veya görsel
          if (page.image != null)
            Image.asset(
              page.image!,
              height: size.height * 0.2,
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: page.color,
              ),
            ),
            
          SizedBox(height: size.height * 0.05),
            
          // Başlık
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
            
          SizedBox(height: size.height * 0.03),
            
          // Açıklama
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Onboarding ekranlarının data sınıfı
class OnboardingPage {
  final String title;
  final String description;
  final String? image;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    this.image,
    required this.icon,
    required this.color,
  });
}

/// SharedPreferences'e dayalı onboarding durumu provider'ı
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboardingCompleted') ?? false;
}); 