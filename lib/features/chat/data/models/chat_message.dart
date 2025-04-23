import 'package:hive/hive.dart';

part 'chat_message.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String answer;

  @HiveField(2)
  final DateTime timestamp;
  
  @HiveField(3)
  final String chatId;

  ChatMessage({
    required this.question,
    required this.answer,
    required this.timestamp,
    required this.chatId,
  });
} 