// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_document_draft.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedDocumentDraftAdapter extends TypeAdapter<SavedDocumentDraft> {
  @override
  final int typeId = 3;

  @override
  SavedDocumentDraft read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedDocumentDraft(
      templateId: fields[0] as String,
      fieldValuesJson: fields[1] as String,
      lastSaved: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedDocumentDraft obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.templateId)
      ..writeByte(1)
      ..write(obj.fieldValuesJson)
      ..writeByte(2)
      ..write(obj.lastSaved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedDocumentDraftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
