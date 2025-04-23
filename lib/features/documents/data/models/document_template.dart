import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'document_field.dart'; // DocumentField'ı import et

part 'document_template.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 2)
@JsonSerializable(explicitToJson: true) // İç içe nesne (DocumentField listesi) için
class DocumentTemplate extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'id')
  final String id;

  @HiveField(1)
  @JsonKey(name: 'name')
  final String name;

  @HiveField(2)
  @JsonKey(name: 'description')
  final String description;

  @HiveField(3)
  @JsonKey(name: 'fields')
  final List<DocumentField> fields; // DocumentField listesi

  @HiveField(4)
  @JsonKey(name: 'templateText')
  final String templateText;

  @HiveField(5)
  @JsonKey(name: 'version')
  final int version;

  @HiveField(6)
  @JsonKey(name: 'extractionPromptHint', includeIfNull: false) // Opsiyonel alan
  final String? extractionPromptHint;

  // Hive anahtarı olarak id kullanmak için getter
  @override
  String get key => id;


  DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.fields,
    required this.templateText,
    required this.version,
    this.extractionPromptHint,
  });

   // JSON'dan nesne oluşturmak için factory constructor
  factory DocumentTemplate.fromJson(Map<String, dynamic> json) => _$DocumentTemplateFromJson(json);

  // Nesneyi JSON'a dönüştürmek için metot
  Map<String, dynamic> toJson() => _$DocumentTemplateToJson(this);
} 