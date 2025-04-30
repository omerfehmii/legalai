class GenerationResult {
  final bool success;
  final String? documentPath; // Başarılıysa PDF yolu/linki
  final String? errorMessage; // Başarısızsa hata mesajı

  GenerationResult({
    required this.success,
    this.documentPath,
    this.errorMessage,
  });

   // Gerekirse JSON dönüşümü için factory ve toJson eklenebilir
} 