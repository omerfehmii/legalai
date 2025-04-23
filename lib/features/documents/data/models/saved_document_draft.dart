import 'package:hive/hive.dart';

part 'saved_document_draft.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 3)
class SavedDocumentDraft extends HiveObject {
  @HiveField(0)
  final String templateId;

  // Hive Map<String, dynamic> doğrudan desteklemez, JSON string olarak saklanabilir
  // veya daha karmaşık bir adaptör yazılabilir. Şimdilik JSON string kullanalım.
  @HiveField(1)
  final String fieldValuesJson;

  @HiveField(2)
  final DateTime lastSaved;

  // Kolay erişim için Map'e dönüştüren getter (import 'dart:convert'; gerekir)
  // Map<String, dynamic> get fieldValues => jsonDecode(fieldValuesJson);

  SavedDocumentDraft({
    required this.templateId,
    required this.fieldValuesJson,
    required this.lastSaved,
  });
} 