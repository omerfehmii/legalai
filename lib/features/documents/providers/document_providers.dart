import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/document_template.dart';
import '../services/document_extraction_service.dart';
import '../services/document_generation_service.dart';
import '../services/document_template_repository.dart';

/// Belge şablonu repository'sini sağlar
final documentTemplateRepositoryProvider = Provider<DocumentTemplateRepository>((ref) {
  return DocumentTemplateRepository();
});

/// Tüm belge şablonlarını sunar
final templatesProvider = FutureProvider<List<DocumentTemplate>>((ref) async {
  final repository = ref.watch(documentTemplateRepositoryProvider);
  await repository.initialize();
  return repository.getAllTemplates();
});

/// Belge bilgilerini çıkarma servisini sağlar
final documentExtractionServiceProvider = StateNotifierProvider<DocumentExtractionNotifier, AsyncValue<void>>((ref) {
  return DocumentExtractionNotifier(DocumentExtractionService());
});

/// Belge oluşturma servisini sağlar
final documentGenerationServiceProvider = StateNotifierProvider<DocumentGenerationNotifier, AsyncValue<void>>((ref) {
  return DocumentGenerationNotifier(DocumentGenerationService());
});

/// Belge bilgilerini çıkarma işlemlerini yöneten notifier
class DocumentExtractionNotifier extends StateNotifier<AsyncValue<void>> {
  final DocumentExtractionService _service;
  
  DocumentExtractionNotifier(this._service) : super(const AsyncValue.data(null));
  
  /// Kullanıcının doğal dil açıklamasından bilgileri çıkarır
  Future<Map<String, dynamic>> extractFieldValues(
    String description, 
    DocumentTemplate template,
  ) async {
    state = const AsyncValue.loading();
    
    try {
      final extractedData = await _service.extractFieldValues(description, template);
      state = const AsyncValue.data(null);
      return extractedData;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Belge oluşturma işlemlerini yöneten notifier
class DocumentGenerationNotifier extends StateNotifier<AsyncValue<void>> {
  final DocumentGenerationService _service;
  
  DocumentGenerationNotifier(this._service) : super(const AsyncValue.data(null));
  
  /// PDF belgesini oluşturur
  Future<String> generatePdfDocument(
    DocumentTemplate template, 
    Map<String, dynamic> fieldValues,
  ) async {
    state = const AsyncValue.loading();
    
    try {
      final pdfPath = await _service.generatePdfDocument(template, fieldValues);
      state = const AsyncValue.data(null);
      return pdfPath;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
} 