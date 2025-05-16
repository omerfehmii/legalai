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
      category: fields[8] as String?,
      tags: (fields[9] as List?)?.cast<String>(),
      status: fields[10] as DocumentStatus?,
      relatedDocumentIds: (fields[12] as List?)?.cast<String>(),
      notes: fields[13] as String?,
      expiryDate: fields[14] as DateTime?,
      isFavorite: fields[15] as bool?,
      metadata: (fields[16] as Map?)?.cast<String, dynamic>(),
      version: fields[11] as int,
    )
      ..id = fields[0] as String
      ..createdAt = fields[4] as DateTime
      ..updatedAt = fields[7] as DateTime;
  }

  @override
  void write(BinaryWriter writer, SavedDocument obj) {
    writer
      ..writeByte(17)
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
      ..write(obj.generatedContent)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.version)
      ..writeByte(12)
      ..write(obj.relatedDocumentIds)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.expiryDate)
      ..writeByte(15)
      ..write(obj.isFavorite)
      ..writeByte(16)
      ..write(obj.metadata);
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

class DocumentStatusAdapter extends TypeAdapter<DocumentStatus> {
  @override
  final int typeId = 11;

  @override
  DocumentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentStatus.draft;
      case 1:
        return DocumentStatus.completed;
      case 2:
        return DocumentStatus.signed;
      case 3:
        return DocumentStatus.submitted;
      case 4:
        return DocumentStatus.expired;
      case 5:
        return DocumentStatus.archived;
      default:
        return DocumentStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentStatus obj) {
    switch (obj) {
      case DocumentStatus.draft:
        writer.writeByte(0);
        break;
      case DocumentStatus.completed:
        writer.writeByte(1);
        break;
      case DocumentStatus.signed:
        writer.writeByte(2);
        break;
      case DocumentStatus.submitted:
        writer.writeByte(3);
        break;
      case DocumentStatus.expired:
        writer.writeByte(4);
        break;
      case DocumentStatus.archived:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
