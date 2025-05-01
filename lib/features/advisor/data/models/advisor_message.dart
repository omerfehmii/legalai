import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'advisor_message.g.dart'; // Update part directive

@HiveType(typeId: 0) // Keep typeId for backward compatibility if needed, or re-assign
@JsonSerializable()
// Rename class
class AdvisorMessage extends HiveObject {
  @HiveField(0)
  final String question; // Consider renaming? Or keep as is?

  @HiveField(1)
  final String answer; // Consider renaming? Or keep as is?

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String chatId; // Rename to sessionId? Relates to AdvisorSession

  @HiveField(4)
  final bool isUserMessage;

  @HiveField(5, defaultValue: null)
  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? metadata;

  // Update constructor name
  AdvisorMessage({
    required this.question,
    required this.answer,
    required this.timestamp,
    required this.chatId, // Rename to sessionId?
    required this.isUserMessage,
    this.metadata,
  });

  // Update factory and toJson method names (generated code will handle implementation)
  factory AdvisorMessage.fromJson(Map<String, dynamic> json) => _$AdvisorMessageFromJson(json);

  Map<String, dynamic> toJson() => _$AdvisorMessageToJson(this);
} 