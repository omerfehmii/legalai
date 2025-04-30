import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/core/theme/app_theme.dart';
import '../../data/models/document_template.dart';
import '../../data/models/document_field.dart';
import '../../providers/document_providers.dart';
import 'document_review_screen.dart';

/// Kullanıcının doğal dil ile açıklama girebildiği ekran
class DocumentDescriptionInputScreen extends ConsumerStatefulWidget {
  final DocumentTemplate template;
  
  const DocumentDescriptionInputScreen({Key? key, required this.template}) : super(key: key);

  @override
  ConsumerState<DocumentDescriptionInputScreen> createState() => _DocumentDescriptionInputScreenState();
}

class _DocumentDescriptionInputScreenState extends ConsumerState<DocumentDescriptionInputScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, 
      appBar: AppBar(
        title: Text(
          widget.template.name,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                'Belgenizi oluşturmak için ilgili durumu veya bilgileri detaylıca açıklayın:',
                style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                'Yapay zeka bu metinden gerekli bilgileri (taraflar, tarihler, vb.) çıkarmaya çalışacaktır.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              
              TextField(
                          controller: _descriptionController,
                          maxLines: null,
                minLines: 10,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                  hintText: 'Örn: Ahmet Yılmaz ile Ayşe Kaya arasında 1 yıllık kira sözleşmesi yapılacak. Başlangıç tarihi 01.08.2024, aylık kira 15000 TL...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
                  ),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                              width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isLoading 
                      ? Container()
                      : Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  label: _isLoading
                      ? SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, 
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary)
                                          ),
                        )
                      : Text('Bilgileri Çıkar ve Önizle'),
                onPressed: _isLoading ? null : _processDescription,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
              ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Kullanıcının girdiği açıklamayı işler ve bir sonraki ekrana geçer
  Future<void> _processDescription() async {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen bir açıklama girin.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      final Map<String, String> extractedData = {
        for (var field in widget.template.fields) 
          field.key: '[Yapay Zeka Tarafından Çıkarılan Veri: ${field.label}]'
      };
      
      if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentReviewScreen(
            template: widget.template,
               extractedData: extractedData,
          ),
        ),
      );
      }

    } catch (e) {
      if (mounted) {
      setState(() {
          _errorMessage = 'Bilgiler çıkarılırken bir hata oluştu: ${e.toString()}';
      });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'), 
            backgroundColor: Theme.of(context).colorScheme.error
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 