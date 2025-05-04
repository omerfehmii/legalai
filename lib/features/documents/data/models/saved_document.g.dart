// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedDocumentAdapter extends TypeAdapter<SavedDocument> {
  @override
  final int typeId = 5;

  @override
  SavedDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedDocument(
      title: fields[1] as String,
      documentType: fields[2] as String,
      collectedData: (fields[3] as Map).cast<String, String>(),
      pdfPath: fields[5] as String?,
      generatedContent: fields[6] as String?,
    )
      ..id = fields[0] as String
      ..createdAt = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, SavedDocument obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.documentType)
      ..writeByte(3)
      ..write(obj.collectedData)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.pdfPath)
      ..writeByte(6)
      ..write(obj.generatedContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
