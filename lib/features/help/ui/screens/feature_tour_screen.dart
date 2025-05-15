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
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel,
                  size: 60,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              // Welcome Text
              const Text(
                'LegalAI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hukuki Asistanınız',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 30),
              // App Features Icons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureIconColumn(Icons.question_answer_outlined, 'Soru Sor'),
                  _buildFeatureIconColumn(Icons.description_outlined, 'Belgeler'),
                  _buildFeatureIconColumn(Icons.settings_outlined, 'Ayarlar'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAskAiIllustration() {
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
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chat Interface Mockup
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.smart_toy_outlined, color: AppTheme.secondaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Hukuk Asistanı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Chat Messages
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // User Message
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12, left: 50),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Kiracı olarak haklarım nelerdir?',
                                  style: TextStyle(color: AppTheme.primaryColor),
                                ),
                              ),
                            ),
                            
                            // AI Response
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12, right: 50),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kiracı olarak temel haklarınız şunlardır:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text('• Güvenli ve sağlıklı bir konutta yaşama hakkı'),
                                    Text('• Mahremiyet hakkı'),
                                    Text('• Kira sözleşmesine uygun şekilde konutu kullanma'),
                                    SizedBox(height: 8),
                                    Text('Detaylı bilgi için...'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Input Area
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: 'Sorunuzu yazın...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateDocumentIllustration() {
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
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Document Creation Interface
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, color: AppTheme.secondaryColor),
                          const SizedBox(width: 12),
                          const Text(
                            'Yeni Belge Oluştur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Document Types
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Belge Türü Seçin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Document Type Options
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDocumentTypeOption('Kira\nSözleşmesi', Icons.home_outlined, true),
                              _buildDocumentTypeOption('İş\nSözleşmesi', Icons.work_outline, false),
                              _buildDocumentTypeOption('Vekaletname', Icons.assignment_ind_outlined, false),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Form Fields
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildDocumentFormField('Kiralayan Adı'),
                          _buildDocumentFormField('Kiracı Adı'),
                          _buildDocumentFormField('Kira Bedeli'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Create Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Belge Oluştur',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageDocumentsIllustration() {
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
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Document List Interface
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined, color: AppTheme.secondaryColor),
                          const SizedBox(width: 12),
                          const Text(
                            'Belgelerim',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
                          ),
                        ],
                      ),
                    ),
                    
                    // Document Items
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDocumentListItem(
                            'Kira Sözleşmesi', 
                            'Sözleşme • 10 Mayıs 2023', 
                            Icons.home_outlined, 
                            Colors.blue
                          ),
                          _buildDocumentListItem(
                            'İş Sözleşmesi', 
                            'Sözleşme • 25 Haziran 2023', 
                            Icons.work_outline, 
                            Colors.purple
                          ),
                          _buildDocumentListItem(
                            'Vekaletname', 
                            'Vekaletname • 12 Eylül 2023', 
                            Icons.assignment_ind_outlined, 
                            Colors.teal
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIconColumn(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppTheme.secondaryColor,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDocumentTypeOption(String label, IconData icon, bool isSelected) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.secondaryColor.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: AppTheme.secondaryColor, width: 2)
            : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.secondaryColor : Colors.grey.shade700,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.secondaryColor : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentFormField(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: label + ' girin',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentListItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.more_vert,
            color: Colors.grey,
            size: 18,
          ),
        ],
      ),
    );
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