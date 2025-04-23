// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentTemplateAdapter extends TypeAdapter<DocumentTemplate> {
  @override
  final int typeId = 2;

  @override
  DocumentTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      fields: (fields[3] as List).cast<DocumentField>(),
      templateText: fields[4] as String,
      version: fields[5] as int,
      extractionPromptHint: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentTemplate obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.fields)
      ..writeByte(4)
      ..write(obj.templateText)
      ..writeByte(5)
      ..write(obj.version)
      ..writeByte(6)
      ..write(obj.extractionPromptHint);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentTemplate _$DocumentTemplateFromJson(Map<String, dynamic> json) =>
    DocumentTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((e) => DocumentField.fromJson(e as Map<String, dynamic>))
          .toList(),
      templateText: json['templateText'] as String,
      version: (json['version'] as num).toInt(),
      extractionPromptHint: json['extractionPromptHint'] as String?,
    );

Map<String, dynamic> _$DocumentTemplateToJson(DocumentTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'fields': instance.fields.map((e) => e.toJson()).toList(),
      'templateText': instance.templateText,
      'version': instance.version,
      if (instance.extractionPromptHint case final value?)
        'extractionPromptHint': value,
    };
