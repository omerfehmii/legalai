import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/document_template.dart';
import '../data/models/document_field.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Kullanıcı tarafından verilen metin açıklamadan belge alanları için 
/// gerekli bilgileri çıkaran servis sınıfı
class DocumentExtractionService {
  final String _supabaseUrl;
  final String _supabaseAnonKey;

  DocumentExtractionService({
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) : _supabaseUrl = supabaseUrl ?? dotenv.env['SUPABASE_URL'] ?? '',
       _supabaseAnonKey = supabaseAnonKey ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// AI ile metin analizine dayalı olarak belge alanları için değerler çıkartır
  /// [userDescription] - Kullanıcının doğal dille belge hakkında yazdığı açıklama
  /// [template] - Bilgilerin çıkarılacağı belge şablonu
  /// 
  /// Returns a Map with field keys and their extracted values
  Future<Map<String, dynamic>> extractFieldValues(
    String userDescription,
    DocumentTemplate template,
  ) async {
    try {
      // Debug modunda çalışırken test verisi dönebiliriz
      if (kDebugMode) {
        debugPrint('Supabase Edge Function çağrılıyor...');
        
        // Geçici olarak, eğer Supabase Edge Function çağrısında sorun olursa
        // şablon ID'sine göre demo veriler dönelim
        if (template.id == 'employment_contract') {
          return _getDemoEmploymentContractData();
        } else if (template.id == 'lease_agreement') {
          return _getDemoLeaseAgreementData();
        }
      }

      // Edge Function URL'si
      final url = '$_supabaseUrl/functions/v1/extract-document-fields';
      
      // İstek gövdesi
      final body = jsonEncode({
        'description': userDescription,
        'template': {
          'id': template.id,
          'name': template.name,
          'fields': template.fields.map((f) => {
            'key': f.key,
            'label': f.label,
            'type': f.type,
            'required': f.required,
          }).toList(),
          'extractionPromptHint': template.extractionPromptHint,
        },
      });

      // Edge Function'a istek gönder
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['extractedFields'] as Map<String, dynamic>;
      } else {
        // Edge Function'dan hata dönerse ve debug modunda ise demo verilerini döndür
        if (kDebugMode) {
          debugPrint('Edge Function hatası: ${response.body}');
          if (template.id == 'employment_contract') {
            return _getDemoEmploymentContractData();
          } else if (template.id == 'lease_agreement') {
            return _getDemoLeaseAgreementData();
          }
        }
        throw Exception('Field extraction failed: ${response.body}');
      }
    } catch (e) {
      // Genel hata durumunda ve debug modunda ise demo verilerini döndür
      if (kDebugMode) {
        debugPrint('Field extraction error: $e');
        if (template.id == 'employment_contract') {
          return _getDemoEmploymentContractData();
        } else if (template.id == 'lease_agreement') {
          return _getDemoLeaseAgreementData();
        }
      }
      throw Exception('Field extraction error: $e');
    }
  }
  
  /// İş sözleşmesi için örnek veriler
  Map<String, dynamic> _getDemoEmploymentContractData() {
    return {
      'isci_adi': 'Mehmet Yılmaz',
      'isveren_adi': 'ABC Teknoloji A.Ş.',
      'tc_kimlik': '12345678901',
      'adres': 'Atatürk Cad. No:123 Kadıköy/İstanbul',
      'baslama_tarihi': '01.06.2023',
      'is_tanimi': 'Yazılım Geliştirici',
      'aylik_ucret': 25000,
      'calisma_saatleri': 'Pazartesi-Cuma 09:00-18:00',
      'izin_suresi': 14,
      'sozlesme_suresi': null,
      'imza_tarihi': '15.05.2023'
    };
  }
  
  /// Kira sözleşmesi için örnek veriler
  Map<String, dynamic> _getDemoLeaseAgreementData() {
    return {
      'kiralayan_adi': 'Ahmet Öztürk',
      'kiralayan_tc': '98765432109',
      'kiraci_adi': 'Ayşe Demir',
      'kiraci_tc': '12345678901',
      'adres': 'Bağdat Cad. No:456 D:7 Kadıköy/İstanbul',
      'kira_baslangic': '01.07.2023',
      'kira_suresi': 12,
      'kira_bedeli': 12000,
      'depozito': 24000,
      'odeme_gunu': '5',
      'tasinmaz_turu': 'Konut',
      'imza_tarihi': '15.06.2023'
    };
  }
} 