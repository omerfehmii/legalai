// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advisor_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdvisorMessageAdapter extends TypeAdapter<AdvisorMessage> {
  @override
  final int typeId = 0;

  @override
  AdvisorMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdvisorMessage(
      question: fields[0] as String,
      answer: fields[1] as String,
      timestamp: fields[2] as DateTime,
      chatId: fields[3] as String,
      isUserMessage: fields[4] as bool,
      metadata: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AdvisorMessage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.answer)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.chatId)
      ..writeByte(4)
      ..write(obj.isUserMessage)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvisorMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdvisorMessage _$AdvisorMessageFromJson(Map<String, dynamic> json) =>
    AdvisorMessage(
      question: json['question'] as String,
      answer: json['answer'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      chatId: json['chatId'] as String,
      isUserMessage: json['isUserMessage'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AdvisorMessageToJson(AdvisorMessage instance) =>
    <String, dynamic>{
      'question': instance.question,
      'answer': instance.answer,
      'timestamp': instance.timestamp.toIso8601String(),
      'chatId': instance.chatId,
      'isUserMessage': instance.isUserMessage,
      if (instance.metadata case final value?) 'metadata': value,
    };
