import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/core/theme/app_theme.dart'; // Import AppTheme
import '../../data/models/document_template.dart';
import '../../providers/document_providers.dart';
import 'document_description_input_screen.dart';

/// Kullanıcının belge şablonu seçebileceği liste ekranı
class DocumentTemplateListScreen extends ConsumerWidget {
  const DocumentTemplateListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Şablonları dinle
    final templatesAsync = ref.watch(templatesProvider);
    final theme = Theme.of(context); // Get theme context

    return Scaffold(
      // Use AppTheme background color
      backgroundColor: AppTheme.backgroundColor, 
      appBar: AppBar(
        // Minimal AppBar style
        title: Text(
          'Belge Türü Seçin', 
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor, // Match background
        elevation: 0, // No shadow
        foregroundColor: theme.colorScheme.onBackground, // Ensure text/icons are visible
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground), // Back button color
      ),
      body: SafeArea( // Add SafeArea
        child: templatesAsync.when(
          data: (templates) => _buildTemplateList(context, ref, templates, theme),
          loading: () => Center(
            child: CircularProgressIndicator(
              // Use theme accent color
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary), 
            )
          ),
        error: (error, stackTrace) => Center(
            child: Padding( // Add padding for error message
              padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                    'Şablonlar yüklenirken bir hata oluştu.', // User-friendly error message
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(), // Keep technical error for debugging if needed
                textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error.withOpacity(0.7)),
              ),
                  const SizedBox(height: 24),
              ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                onPressed: () => ref.refresh(templatesProvider),
                child: const Text('Yeniden Dene'),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList(BuildContext context, WidgetRef ref, List<DocumentTemplate> templates, ThemeData theme) {
    if (templates.isEmpty) {
      return Center(
        child: Padding( // Add padding for empty state
          padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(Icons.find_in_page_outlined, color: theme.colorScheme.secondary, size: 64), // More relevant icon
            const SizedBox(height: 16),
              Text(
                'Kullanılabilir belge şablonu bulunamadı.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                 style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                onPressed: () => ref.refresh(templatesProvider), // Allow refresh
              child: const Text('Yenile'),
            ),
          ],
          ),
        ),
      );
    }

    // Use ListView with ListTile for a cleaner look
    return ListView.separated(
      // Consistent padding with HomeScreen
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), 
      itemCount: templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12), // Space between items
      itemBuilder: (context, index) {
        final template = templates[index];
        return Material( // Wrap with Material for InkWell effect
          color: theme.cardColor, // Use card color from theme
          borderRadius: BorderRadius.circular(12), // Rounded corners
          elevation: 1.0, // Subtle elevation
          shadowColor: Colors.black.withOpacity(0.1), // Soft shadow
          child: InkWell(
            borderRadius: BorderRadius.circular(12), // Match shape for ripple
            onTap: () => _selectTemplate(context, template),
            child: Padding( // Padding inside the tile
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Row( // Use Row for better layout control
                children: [
                  Icon(Icons.description_outlined, size: 24, color: theme.colorScheme.primary), // Leading icon
                  const SizedBox(width: 16),
                  Expanded( // Makes text take available space
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                  ),
                        if (template.description.isNotEmpty) ...[ // Show description if available
                          const SizedBox(height: 4),
                  Text(
                    template.description,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: theme.colorScheme.secondary), // Trailing icon
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectTemplate(BuildContext context, DocumentTemplate template) {
    // Bir sonraki ekrana geç: Doğal dil açıklama girişi
    Navigator.push(
      context,
      MaterialPageRoute(
        // Navigate to the next screen in the flow
        builder: (context) => DocumentDescriptionInputScreen(template: template),
      ),
    );
  }
} 