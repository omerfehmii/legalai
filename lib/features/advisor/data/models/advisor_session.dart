import 'package:hive/hive.dart';

part 'advisor_session.g.dart'; // build_runner tarafından oluşturulacak

@HiveType(typeId: 4)
class AdvisorSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;
  
  @HiveField(4, defaultValue: null)
  String? lastContext;
  
  // HiveObject'in 'key' değeri (otomatik olarak atanacak)
  dynamic key;

  AdvisorSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastContext,
    this.key,
  });
  
  // Create a new chat session with auto-generated ID
  factory AdvisorSession.create({String? title}) {
    final now = DateTime.now();
    return AdvisorSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'Yeni Danışma',
      createdAt: now,
      updatedAt: now,
    );
  }
} 