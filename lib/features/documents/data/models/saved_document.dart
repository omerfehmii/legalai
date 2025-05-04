import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'saved_document.g.dart'; // Hive generator part

@HiveType(typeId: 5) // Ensure typeId is unique across your models
class SavedDocument extends HiveObject {
  @HiveField(0)
  late String id; // Unique ID for the document

  @HiveField(1)
  late String title; // Document title

  @HiveField(2)
  late String documentType; // Type of the document (e.g., 'Kira Sözleşmesi')

  @HiveField(3)
  late Map<String, String> collectedData; // Data used to generate the document

  @HiveField(4)
  late DateTime createdAt; // Timestamp when saved
  
  @HiveField(5)
  String? pdfPath; // Path to the generated PDF file
  
  @HiveField(6)
  String? generatedContent; // The text content of the generated document

  SavedDocument({
    required this.title,
    required this.documentType,
    required this.collectedData,
    this.pdfPath,
    this.generatedContent,
  }) {
    id = const Uuid().v4(); // Generate a unique ID
    createdAt = DateTime.now();
  }
} 