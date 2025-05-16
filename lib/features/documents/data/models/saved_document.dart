import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'saved_document.g.dart'; // Hive generator part

/// Belge durumunu temsil eden enum
@HiveType(typeId: 11)
enum DocumentStatus {
  @HiveField(0)
  draft,       // Taslak
  @HiveField(1)
  completed,   // Tamamlanmış
  @HiveField(2)
  signed,      // İmzalanmış
  @HiveField(3)
  submitted,   // Teslim edilmiş
  @HiveField(4)
  expired,     // Süresi geçmiş
  @HiveField(5)
  archived     // Arşivlenmiş
}

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
  
  @HiveField(7)
  DateTime updatedAt; // Son değiştirilme tarihi
  
  @HiveField(8)
  String category; // Belge kategorisi (örn. "Sözleşmeler", "Dilekçeler")
  
  @HiveField(9)
  List<String> tags; // Etiketler
  
  @HiveField(10)
  DocumentStatus status; // Belge durumu
  
  @HiveField(11)
  int version; // Belge versiyonu
  
  @HiveField(12)
  List<String>? relatedDocumentIds; // İlişkili belge ID'leri
  
  @HiveField(13)
  String? notes; // Kullanıcı notları
  
  @HiveField(14)
  DateTime? expiryDate; // Geçerlilik sonu tarihi (varsa)
  
  @HiveField(15)
  bool? isFavorite; // Favori mi?
  
  @HiveField(16)
  Map<String, dynamic>? metadata; // İsteğe bağlı ekstra veriler

  SavedDocument({
    required this.title,
    required this.documentType,
    required this.collectedData,
    this.pdfPath,
    this.generatedContent,
    String? category,
    List<String>? tags,
    DocumentStatus? status,
    this.relatedDocumentIds,
    this.notes,
    this.expiryDate,
    this.isFavorite,
    this.metadata,
    this.version = 1,
  }) : 
    category = category ?? 'Genel',
    tags = tags ?? [],
    status = status ?? DocumentStatus.draft,
    updatedAt = DateTime.now() {
    id = const Uuid().v4(); // Generate a unique ID
    createdAt = DateTime.now();
  }
  
  /// Belgeyi günceller ve güncelleme zamanını yeniler
  void update({
    String? title,
    String? documentType,
    Map<String, String>? collectedData,
    String? pdfPath,
    String? generatedContent,
    String? category,
    List<String>? tags,
    DocumentStatus? status,
    List<String>? relatedDocumentIds,
    String? notes,
    DateTime? expiryDate,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    if (title != null) this.title = title;
    if (documentType != null) this.documentType = documentType;
    if (collectedData != null) this.collectedData = collectedData;
    if (pdfPath != null) this.pdfPath = pdfPath;
    if (generatedContent != null) this.generatedContent = generatedContent;
    if (category != null) this.category = category;
    if (tags != null) this.tags = tags;
    if (status != null) this.status = status;
    if (relatedDocumentIds != null) this.relatedDocumentIds = relatedDocumentIds;
    if (notes != null) this.notes = notes;
    if (expiryDate != null) this.expiryDate = expiryDate;
    if (isFavorite != null) this.isFavorite = isFavorite;
    if (metadata != null) this.metadata = metadata;
    
    // Versiyonu arttır ve güncelleme tarihini yenile
    version++;
    updatedAt = DateTime.now();
  }
  
  /// Bu belgenin yeni bir versiyonunu oluşturur
  SavedDocument createNewVersion({
    String? title,
    String? documentType,
    Map<String, String>? collectedData,
    String? pdfPath,
    String? generatedContent,
    String? category,
    List<String>? tags,
    DocumentStatus? status,
    List<String>? relatedDocumentIds,
    String? notes,
    DateTime? expiryDate,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    // Eski ilişkili belge listesini kopyala ve bu belgeyi ekle
    final oldRelatedDocIds = relatedDocumentIds != null 
        ? List<String>.from(relatedDocumentIds!) 
        : <String>[];
    if (!oldRelatedDocIds.contains(id)) {
      oldRelatedDocIds.add(id);
    }
    
    // Yeni belgeyi oluştur
    return SavedDocument(
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      collectedData: collectedData ?? Map<String, String>.from(this.collectedData),
      pdfPath: pdfPath,
      generatedContent: generatedContent ?? this.generatedContent,
      category: category ?? this.category,
      tags: tags ?? List<String>.from(this.tags),
      status: status ?? DocumentStatus.draft, // Yeni versiyon her zaman taslak olarak başlar
      relatedDocumentIds: oldRelatedDocIds,
      notes: notes ?? this.notes,
      expiryDate: expiryDate ?? this.expiryDate,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata != null ? Map<String, dynamic>.from(metadata) : 
        (this.metadata != null ? Map<String, dynamic>.from(this.metadata!) : null),
      version: version + 1, // Versiyon numarasını arttır
    );
  }
  
  /// Belgenin okunabilir durumunu döndürür
  String get statusText {
    switch (status) {
      case DocumentStatus.draft:
        return 'Taslak';
      case DocumentStatus.completed:
        return 'Tamamlandı';
      case DocumentStatus.signed:
        return 'İmzalandı';
      case DocumentStatus.submitted:
        return 'Teslim Edildi';
      case DocumentStatus.expired:
        return 'Süresi Geçti';
      case DocumentStatus.archived:
        return 'Arşivlendi';
      default:
        return 'Bilinmiyor';
    }
  }
} 