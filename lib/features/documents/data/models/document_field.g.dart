// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_field.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentFieldAdapter extends TypeAdapter<DocumentField> {
  @override
  final int typeId = 1;

  @override
  DocumentField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentField(
      key: fields[0] as String,
      label: fields[1] as String,
      type: fields[2] as String,
      required: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentField obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.required);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentField _$DocumentFieldFromJson(Map<String, dynamic> json) =>
    DocumentField(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      required: json['required'] as bool,
    );

Map<String, dynamic> _$DocumentFieldToJson(DocumentField instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'type': instance.type,
      'required': instance.required,
    };
