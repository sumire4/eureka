import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiSummaryResult {
  final String highlight;
  final String impact;
  final String status;

  AiSummaryResult({
    required this.highlight,
    required this.impact,
    required this.status,
  });

  factory AiSummaryResult.fallback(String fallbackText) {
    return AiSummaryResult(
      highlight: fallbackText.isNotEmpty ? fallbackText : 'Detaylar haber içeriğinde yer alıyor.',
      impact: 'Hafta sonu stratejilerini ve araç ayarlarını doğrudan etkileyebilir.',
      status: 'Teknik heyet ve pilotlar arasındaki değerlendirmeler devam ediyor.',
    );
  }
}

class GeminiService {
  // .env dosyasından güvenli okuma
  static String get _apiKey =>  dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  Future<AiSummaryResult> summarizeNews({
    required String title,
    required String description,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('UYARI: GEMINI_API_KEY tanımlanmamış!');
      return AiSummaryResult.fallback(description);
    }

    final prompt = '''
Sen uzman bir Formula 1 editörüsün. Aşağıdaki haber başlığı ve içeriğini oku.
Bize tam olarak şu 3 başlıkta çok kısa, net (her biri tek cümle) Türkçe hap bilgi üret:
1. OneCikan: En önemli gelişme
2. Etki: Yarışa, takıma veya şampiyonaya etkisi
3. SonDurum: Şu anki durum veya bir sonraki aşama

Cevabını SADECE geçerli bir JSON objesi olarak ver. Markdown kod bloğu (```json) kullanma. Format:
{
  "oneCikan": "...",
  "etki": "...",
  "sonDurum": "..."
}

Haber Başlığı: $title
Haber İçeriği: $description
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 250,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        // Olası markdown işaretlerini temizle
        rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

        final parsed = json.decode(rawText);
        return AiSummaryResult(
          highlight: parsed['oneCikan'] ?? 'Haber teknik ekibi tarafından doğrulandı.',
          impact: parsed['etki'] ?? 'Şampiyona mücadelesinde dengeleri değiştirebilir.',
          status: parsed['sonDurum'] ?? 'Gelişmeler takip ediliyor.',
        );
      } else {
        debugPrint('Gemini API Hatası: ${response.statusCode} - ${response.body}');
        return AiSummaryResult.fallback(description);
      }
    } catch (e) {
      debugPrint('Gemini Exception: $e');
      return AiSummaryResult.fallback(description);
    }
  }
}