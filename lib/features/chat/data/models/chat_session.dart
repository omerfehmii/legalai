import 'package:hive/hive.dart';

part 'chat_session.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 4)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime updatedAt;
  
  // HiveObject'in 'key' değeri (otomatik olarak atanacak)
  dynamic key;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.key,
  });
  
  // Create a new chat session with auto-generated ID
  factory ChatSession.create({String? title}) {
    final now = DateTime.now();
    return ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'Yeni Sohbet',
      createdAt: now,
      updatedAt: now,
    );
  }
} 