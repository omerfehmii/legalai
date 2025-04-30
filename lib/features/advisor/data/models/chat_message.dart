import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 0)
@JsonSerializable()
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String answer;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String chatId;

  @HiveField(4)
  final bool isUserMessage;

  @HiveField(5, defaultValue: null)
  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.question,
    required this.answer,
    required this.timestamp,
    required this.chatId,
    required this.isUserMessage,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
} 