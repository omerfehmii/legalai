import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/help/ui/screens/feature_tour_screen.dart';

class HelpGuideScreen extends StatefulWidget {
  const HelpGuideScreen({Key? key}) : super(key: key);

  @override
  State<HelpGuideScreen> createState() => _HelpGuideScreenState();
}

class _HelpGuideScreenState extends State<HelpGuideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<HelpCategory> _categories = [
    HelpCategory(
      title: 'Başlarken',
      icon: Icons.lightbulb_outline,
      sections: [
        HelpSection(
          title: 'Hoş Geldiniz',
          content: 'LegalAI, hukuki asistanınız olarak tasarlanmış bir uygulamadır. Yapay zeka ile desteklenen uygulamamız, hukuki sorularınızı cevaplamak ve hukuki belgeler oluşturmanıza yardımcı olmak için tasarlanmıştır.',
          icon: Icons.emoji_objects_outlined,
        ),
        HelpSection(
          title: 'Temel Özellikler',
          content: '• Hukuki sorular sorun\n• Belgeler oluşturun\n• Belgelerinizi yönetin\n• Geçmiş işlemlerinizi görüntüleyin',
          icon: Icons.star_outline,
        ),
        HelpSection(
          title: 'Ana Ekran',
          content: 'Ana ekranda üç ana buton bulunur: Soru Sor, Oluştur ve Belgeler. İhtiyacınıza göre uygun butona tıklayarak ilgili bölüme geçiş yapabilirsiniz.',
          icon: Icons.home_outlined,
        ),
      ],
    ),
    HelpCategory(
      title: 'Sorular',
      icon: Icons.question_answer_outlined,
      sections: [
        HelpSection(
          title: 'Soru Sorma',
          content: 'Hukuki bir sorunuz olduğunda, "Soru Sor" butonuna tıklayarak yapay zeka asistanımıza danışabilirsiniz. Sorunuzu açık ve net bir şekilde yazın.',
          icon: Icons.help_outline,
        ),
        HelpSection(
          title: 'Cevapları Anlama',
          content: 'Aldığınız cevaplar genel bilgilendirme amaçlıdır. Önemli hukuki kararlar için mutlaka bir avukata danışmanızı öneririz.',
          icon: Icons.info_outline,
        ),
        HelpSection(
          title: 'Soru Geçmişi',
          content: 'Sorduğunuz tüm sorular ve aldığınız cevaplar otomatik olarak kaydedilir. Profil sayfanızdan geçmiş sorularınıza erişebilirsiniz.',
          icon: Icons.history,
        ),
      ],
    ),
    HelpCategory(
      title: 'Belgeler',
      icon: Icons.description_outlined,
      sections: [
        HelpSection(
          title: 'Belge Oluşturma',
          content: '"Oluştur" butonuna tıklayarak yeni bir belge oluşturabilirsiniz. Belge türünü seçin ve gerekli bilgileri girin.',
          icon: Icons.add_circle_outline,
        ),
        HelpSection(
          title: 'Belge Düzenleme',
          content: 'Oluşturduğunuz belgeleri düzenlemek için Belgeler sayfasından ilgili belgeyi seçin ve düzenle butonuna tıklayın.',
          icon: Icons.edit_note_outlined,
        ),
        HelpSection(
          title: 'PDF İşlemleri',
          content: 'Tüm belgeleriniz otomatik olarak PDF formatında kaydedilir. Belgelerinizi görüntüleyebilir, paylaşabilir veya cihazınıza kaydedebilirsiniz.',
          icon: Icons.picture_as_pdf_outlined,
        ),
      ],
    ),
    HelpCategory(
      title: 'Profil',
      icon: Icons.person_outline,
      sections: [
        HelpSection(
          title: 'Profil Bilgileri',
          content: 'Profil bilgilerinizi düzenlemek için profil sayfanızdaki düzenleme ikonuna tıklayın.',
          icon: Icons.edit_outlined,
        ),
        HelpSection(
          title: 'Tema Ayarları',
          content: 'Uygulama temasını değiştirmek için profil sayfanızdaki "Koyu Tema" seçeneğini kullanabilirsiniz.',
          icon: Icons.brightness_4_outlined,
        ),
        HelpSection(
          title: 'Dil Ayarları',
          content: 'Uygulama dilini değiştirmek için profil sayfanızdaki "Dil" seçeneğini kullanabilirsiniz.',
          icon: Icons.language_outlined,
        ),
      ],
    ),
    HelpCategory(
      title: 'Destek',
      icon: Icons.support_agent_outlined,
      sections: [
        HelpSection(
          title: 'Sık Sorulan Sorular',
          content: 'Uygulamamız hakkında en çok sorulan soruların cevaplarını bu bölümde bulabilirsiniz.',
          icon: Icons.question_mark_outlined,
        ),
        HelpSection(
          title: 'İletişim',
          content: 'Sorularınız ve geri bildirimleriniz için bize e-posta gönderin: support@legalai.com',
          icon: Icons.email_outlined,
        ),
        HelpSection(
          title: 'Gizlilik Politikası',
          content: 'Gizlilik politikamız hakkında bilgi almak için web sitemizi ziyaret edin: www.legalai.com/privacy',
          icon: Icons.privacy_tip_outlined,
        ),
      ],
    ),
  ];

  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategoryIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          'Yardım Rehberi',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Yardım kategorileri için üst kısım
          Container(
            height: 100,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = index == _selectedCategoryIndex;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                      _tabController.animateTo(index);
                    });
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Seçilen kategori başlığı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Text(
              _categories[_selectedCategoryIndex].title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Image container with illustration
                Container(
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
                    child: _buildIllustration(_categories[_selectedCategoryIndex]),
                  ),
                ),
              ],
            ),
          ),
          
          // Yardım içeriği
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: category.sections.length,
                  itemBuilder: (context, index) {
                    final section = category.sections[index];
                    return _buildHelpItem(section);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      // Alt kısımda arama butonu
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Arama dialog'u göster
                _showSearchDialog(context);
              },
              backgroundColor: AppTheme.secondaryColor,
              icon: const Icon(Icons.search),
              label: const Text('Yardım Ara'),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Özellik turu ekranına geçiş
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeatureTourScreen()),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.slideshow),
              label: const Text('Özellik Turu'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(HelpSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.light(
            primary: AppTheme.secondaryColor,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          expandedAlignment: Alignment.topLeft,
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              section.icon,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
          ),
          title: Text(
            section.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16, thickness: 1),
                  const SizedBox(height: 8),
                  Text(
                    section.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Paylaşma özelliği buraya eklenebilir
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Paylaş'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text(
                'Yardım Ara',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Yardım konusu ara...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: Center(
                  child: Text(
                    'Arama sonuçları burada görünecek.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                ),
                child: const Text(
                  'Kapat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(HelpCategory category) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine which illustration to show based on the category title
    if (category.title.contains('Hoş Geldiniz')) {
      return _buildWelcomeIllustration();
    } else if (category.title.contains('Soru')) {
      return _buildAskAiIllustration();
    } else if (category.title.contains('Belge Oluşturun')) {
      return _buildCreateDocumentIllustration();
    } else if (category.title.contains('Yönetin')) {
      return _buildManageDocumentsIllustration();
    }
    
    // Fallback
    return Container(
      color: Colors.white,
      child: Center(
        child: Icon(
          Icons.help_outline,
          size: 120,
          color: AppTheme.secondaryColor.withOpacity(0.3),
        ),
      ),
    );
  }
  
  Widget _buildWelcomeIllustration() {
    return Container(
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
    );
  }
  
  Widget _buildAskAiIllustration() {
    return Container(
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
    );
  }
  
  Widget _buildCreateDocumentIllustration() {
    return Container(
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
    );
  }
  
  Widget _buildManageDocumentsIllustration() {
    return Container(
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
}

// Model sınıfları
class HelpCategory {
  final String title;
  final IconData icon;
  final List<HelpSection> sections;

  HelpCategory({
    required this.title,
    required this.icon,
    required this.sections,
  });
}

class HelpSection {
  final String title;
  final String content;
  final IconData icon;

  HelpSection({
    required this.title,
    required this.content,
    required this.icon,
  });
} 