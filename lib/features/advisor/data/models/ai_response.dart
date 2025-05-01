import 'package:legalai/features/advisor/providers/advisor_providers.dart';

class AIResponse {
  final String? responseText;         // AI'ın metin cevabı veya sorusu
  final bool? isAskingQuestion;     // AI soru soruyor mu?
  final DocumentGenerationStatus? newStatus; // Güncellenmiş belge oluşturma durumu
  final String? documentType;       // YENI - Belirlenen veya istenen belge türü ID'si/adı
  final Map<String, String>? collectedData; // Güncellenmiş toplanan veriler
  final String? documentPath;       // Eğer belge hazırsa yolu/linki
  final String? error;              // Hata mesajı
  // final Map<String, dynamic>? metadata; // UI için ek bilgi (opsiyonel)

  AIResponse({
    this.responseText,
    this.isAskingQuestion,
    this.newStatus,
    this.documentType,
    this.collectedData,
    this.documentPath,
    this.error,
    // this.metadata,
  });

  // Gerekirse JSON dönüşümü için factory ve toJson eklenebilir
  // factory AIResponse.fromJson(Map<String, dynamic> json) => ...
} 