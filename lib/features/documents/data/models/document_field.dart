import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'document_field.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 1)
@JsonSerializable() // JSON dönüşümü için
class DocumentField extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'key') // JSON anahtarıyla eşleşme
  final String key;

  @HiveField(1)
  @JsonKey(name: 'label')
  final String label;

  @HiveField(2)
  @JsonKey(name: 'type')
  final String type; // 'text', 'number', 'date' vb.

  @HiveField(3)
  @JsonKey(name: 'required')
  final bool required;

  DocumentField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
  });

  // JSON'dan nesne oluşturmak için factory constructor
  factory DocumentField.fromJson(Map<String, dynamic> json) => _$DocumentFieldFromJson(json);

  // Nesneyi JSON'a dönüştürmek için metot
  Map<String, dynamic> toJson() => _$DocumentFieldToJson(this);
} 