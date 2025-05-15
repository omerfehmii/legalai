import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class FeatureTourScreen extends StatefulWidget {
  const FeatureTourScreen({Key? key}) : super(key: key);

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<FeatureTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<FeatureTourPage> _tourPages = [
    FeatureTourPage(
      title: 'LegalAI\'ye Hoş Geldiniz',
      description: 'Hukuki asistanınız yanınızda. Sorularınızı sorun, belgelerinizi oluşturun ve yönetin.',
      imagePath: 'assets/images/welcome_tour.png', // Bu görseli oluşturmanız gerekecek
      backgroundColor: const Color(0xFFF8F0E5),
      actions: [
        FeatureAction(
          title: 'Ana Ekran',
          description: 'Ana ekrandan tüm özelliklere erişebilirsiniz.',
          icon: Icons.home_outlined,
        ),
        FeatureAction(
          title: 'Hızlı Erişim',
          description: 'Alttaki çubukta yer alan butonlar ile hızlıca işlem yapabilirsiniz.',
          icon: Icons.bolt_outlined,
        ),
      ],
    ),
    FeatureTourPage(
      title: 'Yapay Zeka ile Soru Sorun',
      description: 'Hukuki sorularınızı yapay zeka asistanımıza sorabilirsiniz.',
      imagePath: 'assets/images/ask_ai_tour.png',
      backgroundColor: const Color(0xFFE9F8F9),
      actions: [
        FeatureAction(
          title: 'Soru Nasıl Sorulur',
          description: 'Ana ekrandan "Soru Sor" butonuna tıklayın ve sorunuzu yazın.',
          icon: Icons.help_outline,
        ),
        FeatureAction(
          title: 'Cevapları Kaydedin',
          description: 'Aldığınız cevapları kaydedebilir ve daha sonra inceleyebilirsiniz.',
          icon: Icons.bookmark_outline,
        ),
        FeatureAction(
          title: 'Detaylı Cevaplar',
          description: 'Asistanımız size ayrıntılı ve referanslı cevaplar sunar.',
          icon: Icons.description_outlined,
        ),
      ],
    ),
    FeatureTourPage(
      title: 'Belge Oluşturun',
      description: 'İhtiyacınız olan hukuki belgeleri kolayca oluşturun ve düzenleyin.',
      imagePath: 'assets/images/create_document_tour.png',
      backgroundColor: const Color(0xFFF1F0E8),
      actions: [
        FeatureAction(
          title: 'Belge Şablonları',
          description: 'Ana ekrandan "Oluştur" butonuna tıklayarak şablonları görüntüleyin.',
          icon: Icons.article_outlined,
        ),
        FeatureAction(
          title: 'Kişiselleştirme',
          description: 'Belge içeriğini ihtiyaçlarınıza göre özelleştirin.',
          icon: Icons.edit_note_outlined,
        ),
        FeatureAction(
          title: 'PDF Olarak Kaydedin',
          description: 'Belgelerinizi PDF formatında kaydedip paylaşabilirsiniz.',
          icon: Icons.picture_as_pdf_outlined,
        ),
      ],
    ),
    FeatureTourPage(
      title: 'Belgelerinizi Yönetin',
      description: 'Oluşturduğunuz tüm belgelerinizi tek bir yerden yönetin.',
      imagePath: 'assets/images/manage_documents_tour.png',
      backgroundColor: const Color(0xFFECF4D6),
      actions: [
        FeatureAction(
          title: 'Belge Arşivi',
          description: 'Ana ekrandan "Belgeler" butonuna tıklayarak tüm belgelerinize erişin.',
          icon: Icons.folder_outlined,
        ),
        FeatureAction(
          title: 'Düzenleme ve Silme',
          description: 'Belgelerinizi istediğiniz zaman düzenleyebilir veya silebilirsiniz.',
          icon: Icons.edit_outlined,
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Tour Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _tourPages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildFeaturePage(_tourPages[index]);
            },
          ),
          
          // Top Navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentPage > 0 ? Icons.arrow_back : Icons.close,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  
                  // Skip button
                  if (_currentPage < _tourPages.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Geç',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _tourPages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                      activeDotColor: AppTheme.secondaryColor,
                      dotColor: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  
                  // Next/Finish Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < _tourPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage < _tourPages.length - 1 ? 'İleri' : 'Bitir',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage < _tourPages.length - 1 ? Icons.arrow_forward : Icons.check,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage(FeatureTourPage page) {
    return Container(
      color: page.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60), // Space for top navigation
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                page.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                page.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Image
            Expanded(
              flex: 5,
              child: _buildTourIllustration(page),
            ),
            
            const SizedBox(height: 40),
            
            // Feature Actions
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: page.actions.length,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemBuilder: (context, index) {
                  final action = page.actions[index];
                  return _buildActionItem(action);
                },
              ),
            ),
            
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildTourIllustration(FeatureTourPage page) {
    // Determine which illustration to show based on the page title
    if (page.title.contains('Hoş Geldiniz')) {
      return _buildWelcomeIllustration();
    } else if (page.title.contains('Soru')) {
      return _buildAskAiIllustration();
    } else if (page.title.contains('Belge Oluşturun')) {
      return _buildCreateDocumentIllustration();
    } else if (page.title.contains('Yönetin')) {
      return _buildManageDocumentsIllustration();
    }
    
    // Fallback illustration
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Icon(
            _getFeatureIcon(page.title),
            size: 120,
            color: AppTheme.secondaryColor.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeIllustration() {
    // Implementation of _buildWelcomeIllustration method
    return Container(); // Placeholder, actual implementation needed
  }

  Widget _buildAskAiIllustration() {
    // Implementation of _buildAskAiIllustration method
    return Container(); // Placeholder, actual implementation needed
  }

  Widget _buildCreateDocumentIllustration() {
    // Implementation of _buildCreateDocumentIllustration method
    return Container(); // Placeholder, actual implementation needed
  }

  Widget _buildManageDocumentsIllustration() {
    // Implementation of _buildManageDocumentsIllustration method
    return Container(); // Placeholder, actual implementation needed
  }

  Widget _buildActionItem(FeatureAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              action.icon,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String title) {
    if (title.contains('Hoş Geldiniz')) {
      return Icons.waving_hand_outlined;
    } else if (title.contains('Soru')) {
      return Icons.question_answer_outlined;
    } else if (title.contains('Belge Oluşturun')) {
      return Icons.note_add_outlined;
    } else if (title.contains('Yönetin')) {
      return Icons.folder_outlined;
    }
    return Icons.lightbulb_outline;
  }
}

class FeatureTourPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final List<FeatureAction> actions;

  FeatureTourPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.actions,
  });
}

class FeatureAction {
  final String title;
  final String description;
  final IconData icon;

  FeatureAction({
    required this.title,
    required this.description,
    required this.icon,
  });
} 