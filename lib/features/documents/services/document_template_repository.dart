import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../data/models/document_template.dart';
import '../data/models/document_field.dart';
import '../data/models/saved_document_draft.dart';

/// Belge şablonlarını ve taslakları Hive ile yerel olarak yöneten repository
class DocumentTemplateRepository {
  static const String _templatesBoxName = 'document_templates';
  static const String _draftsBoxName = 'document_drafts';
  
  Box<DocumentTemplate>? _templatesBox;
  Box<SavedDocumentDraft>? _draftsBox;
  
  /// Repository'yi başlatır ve Hive kutularını hazırlar
  Future<void> initialize() async {
    _templatesBox = await Hive.openBox<DocumentTemplate>(_templatesBoxName);
    _draftsBox = await Hive.openBox<SavedDocumentDraft>(_draftsBoxName);
    
    // İlk çalıştırmada şablonları yükle (eğer boşsa)
    if (_templatesBox!.isEmpty) {
      await _loadInitialTemplates();
    }
  }
  
  /// Tüm belge şablonlarını döndürür
  List<DocumentTemplate> getAllTemplates() {
    return _templatesBox?.values.toList() ?? [];
  }
  
  /// ID'ye göre belge şablonu döndürür
  Future<DocumentTemplate?> getTemplateById(String templateId) async {
    return _templatesBox?.get(templateId);
  }
  
  /// ID'ye göre belirli bir kategorideki şablonları döndürür
  List<DocumentTemplate> getTemplatesByCategory(String category) {
    // Bu fonksiyon ileride kullanılabilir, şimdilik kategorileri uygulamıyoruz
    return _templatesBox?.values.toList() ?? [];
  }
  
  /// Yeni bir belge taslağı kaydeder
  Future<void> saveDraft(String templateId, Map<String, dynamic> fieldValues) async {
    final draft = SavedDocumentDraft(
      templateId: templateId,
      fieldValuesJson: jsonEncode(fieldValues),
      lastSaved: DateTime.now(),
    );
    
    await _draftsBox?.put('${templateId}_${DateTime.now().millisecondsSinceEpoch}', draft);
  }
  
  /// Belirli bir şablona ait kaydedilmiş taslakları döndürür
  List<SavedDocumentDraft> getDraftsForTemplate(String templateId) {
    return _draftsBox?.values
        .where((draft) => draft.templateId == templateId)
        .toList() ?? [];
  }
  
  /// Önceden tanımlanmış şablonları yükler
  Future<void> _loadInitialTemplates() async {
    try {
      // assets/templates/ klasöründen şablon dosyalarını oku
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // templates ile başlayan asset dosyalarını bul
      final templatePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/templates/') && key.endsWith('.json'))
          .toList();
      
      // Her şablonu yükle ve Hive'a kaydet
      for (final path in templatePaths) {
        final String jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        
        final template = DocumentTemplate.fromJson(jsonData);
        await _templatesBox?.put(template.id, template);
      }
    } catch (e) {
      print('Template loading error: $e');
      // Hata durumunda varsayılan şablonlar yükle
      await _loadDefaultTemplates();
    }
  }
  
  /// Hata durumunda varsayılan şablonları yükler
  Future<void> _loadDefaultTemplates() async {
    // Basit bir iş sözleşmesi şablonu
    final employmentContract = DocumentTemplate(
      id: 'employment_contract',
      name: 'İş Sözleşmesi',
      description: 'Standart iş sözleşmesi taslağı',
      version: 1,
      fields: [
        DocumentField(
          key: 'isci_adi',
          label: 'İşçi Adı Soyadı',
          type: 'text',
          required: true,
        ),
        DocumentField(
          key: 'isveren_adi',
          label: 'İşveren Adı/Unvanı',
          type: 'text',
          required: true,
        ),
        DocumentField(
          key: 'tc_kimlik',
          label: 'T.C. Kimlik No',
          type: 'text',
          required: true,
        ),
        DocumentField(
          key: 'baslama_tarihi',
          label: 'İşe Başlama Tarihi',
          type: 'date',
          required: true,
        ),
        DocumentField(
          key: 'aylik_ucret',
          label: 'Aylık Brüt Ücret',
          type: 'number',
          required: true,
        ),
      ],
      templateText: 'İŞ SÖZLEŞMESİ\n\n'
          'İşbu İş Sözleşmesi, aşağıda belirtilen taraflar arasında imzalanmıştır:\n\n'
          'İŞVEREN: {{isveren_adi}}\n'
          'İŞÇİ: {{isci_adi}}, T.C. Kimlik No: {{tc_kimlik}}\n\n'
          'MADDE 1 - TARAFLAR\n'
          'İşveren {{isveren_adi}} ve İşçi {{isci_adi}} arasında aşağıdaki şartlarda iş sözleşmesi '
          'düzenlenmiştir.\n\n'
          'MADDE 2 - İŞE BAŞLAMA TARİHİ\n'
          'İşçi {{baslama_tarihi}} tarihinde işe başlayacaktır.\n\n'
          'MADDE 3 - ÜCRET\n'
          'İşçiye aylık brüt {{aylik_ucret}} TL ücret ödenecektir.',
      extractionPromptHint: 'Bir iş sözleşmesi için işçi ve işveren bilgilerini, işe başlama tarihini ve ücreti çıkar.',
    );
    
    await _templatesBox?.put(employmentContract.id, employmentContract);
  }
  
  /// Kaynakları temizler
  Future<void> dispose() async {
    await _templatesBox?.close();
    await _draftsBox?.close();
  }
} 