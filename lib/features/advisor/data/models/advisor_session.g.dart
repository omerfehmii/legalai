// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advisor_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdvisorSessionAdapter extends TypeAdapter<AdvisorSession> {
  @override
  final int typeId = 4;

  @override
  AdvisorSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdvisorSession(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      lastContext: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AdvisorSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.lastContext);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvisorSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
