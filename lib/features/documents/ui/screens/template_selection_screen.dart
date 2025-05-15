import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/advisor/ui/screens/advisor_screen.dart';
import 'package:legalai/features/documents/data/models/document_template.dart';
import 'package:legalai/features/documents/services/document_template_repository.dart';

// Şablon repository provider'ı
final templateRepositoryProvider = Provider<DocumentTemplateRepository>((ref) {
  return DocumentTemplateRepository();
});

// Tüm şablonları getiren provider
final templatesProvider = FutureProvider<List<DocumentTemplate>>((ref) async {
  final repository = ref.read(templateRepositoryProvider);
  await repository.initialize(); // Repository'yi başlat
  return repository.getAllTemplates();
});

class TemplateSelectionScreen extends ConsumerWidget {
  const TemplateSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Şablon Seçin', 
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Belge türünü seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Oluşturmak istediğiniz belge türünü seçin. Yapay zeka asistanımız seçtiğiniz türe göre size yardımcı olacaktır.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Şablonlar listesi
              Expanded(
                child: templatesAsync.when(
                  data: (templates) {
                    if (templates.isEmpty) {
                      return const Center(
                        child: Text(
                          'Şablon bulunamadı',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _buildTemplateCard(context, template);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Hata: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTemplateCard(BuildContext context, DocumentTemplate template) {
    // Şablon için prompt oluştur
    String prompt = _generatePromptFromTemplate(template);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // AdvisorScreen'e git ve prompt'u başlangıç değeri olarak ver
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdvisorScreen(
                initialPrompt: prompt,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForTemplate(template.name),
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
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // "Şimdi Oluştur" butonu
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // AdvisorScreen'e git ve prompt'u başlangıç değeri olarak ver
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdvisorScreen(
                          initialPrompt: prompt,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Şimdi Oluştur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Şablon adına göre uygun ikon seç
  IconData _getIconForTemplate(String templateName) {
    final name = templateName.toLowerCase();
    
    if (name.contains('iş') || name.contains('çalışma')) {
      return Icons.work_outline;
    } else if (name.contains('kira')) {
      return Icons.home_outlined;
    } else if (name.contains('vekalet')) {
      return Icons.assignment_ind_outlined;
    } else if (name.contains('satış')) {
      return Icons.monetization_on_outlined;
    } else if (name.contains('şikayet') || name.contains('dilekçe')) {
      return Icons.description_outlined;
    } else if (name.contains('boşanma') || name.contains('aile')) {
      return Icons.family_restroom;
    } else {
      return Icons.article_outlined;
    }
  }
  
  // Şablondan prompt oluştur
  String _generatePromptFromTemplate(DocumentTemplate template) {
    // Şablondan bir başlangıç prompt'u oluştur
    String promptFields = template.fields.map((f) => f.label).join(', ');
    
    String prompt = '''${template.name} hazırlamak istiyorum. 
Bu belge için aşağıdaki bilgileri kullanmalıyız:
$promptFields

Lütfen bana bu belgeyi oluşturmak için yardımcı ol. Hangi bilgilere ihtiyacın varsa sorarsan sana sağlayacağım.''';
    
    // Eğer extractionPromptHint tanımlanmışsa, onu da ekle
    if (template.extractionPromptHint != null && template.extractionPromptHint!.isNotEmpty) {
      prompt = '${template.extractionPromptHint!}\n\n$prompt';
    }
    
    return prompt;
  }
} 