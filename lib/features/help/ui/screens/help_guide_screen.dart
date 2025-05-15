import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Arama dialog'u göster
          _showSearchDialog(context);
        },
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.search),
        label: const Text('Yardım Ara'),
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