import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RaceAiAnalysis {
  final String raceName;
  final String circuitName;
  final String countryCode;
  final String dateText;
  final String circuitImageUrl;
  final String lastRaceSummary;
  final String weatherTrack;
  final String teamForm;
  final String strategyTires;
  final String podiumPrediction;

  RaceAiAnalysis({
    required this.raceName,
    required this.circuitName,
    required this.countryCode,
    required this.dateText,
    required this.circuitImageUrl,
    required this.lastRaceSummary,
    required this.weatherTrack,
    required this.teamForm,
    required this.strategyTires,
    required this.podiumPrediction,
  });

  factory RaceAiAnalysis.fallback() {
    return RaceAiAnalysis(
      raceName: 'İspanya Grand Prix',
      circuitName: 'Circuit de Barcelona-Catalunya',
      countryCode: 'ESP',
      dateText: 'Pazar, 16:00',
      circuitImageUrl: 'https://media.formula1.com/image/upload/f_auto,c_limit,w_960,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/Spain_Circuit.png',
      lastRaceSummary: 'Monako GP: Pole pozisyonundan başlayan yarışçı hatasız sürüşle zaferi aldı, yağmur stratejisi orta grupta sıralamayı değiştirdi.',
      weatherTrack: 'Pist 38°C, hava 27°C parçalı bulutlu. Yüksek yanal kuvvetler nedeniyle sol ön lastik aşınması kritik.',
      teamForm: 'McLaren ve Ferrari yüksek yere basma gücü gerektiren 3. sektörde avantajlı. Mercedes düzlük hızında güçlü.',
      strategyTires: 'C1-C2-C3 sert hamurlar devrede. Yüksek sıcaklık altında 2 pit-stop (Medium - Hard - Hard) en hızlı strateji.',
      podiumPrediction: '1. Norris  •  2. Verstappen  •  3. Leclerc',
    );
  }
}

class EurekaAiService {
  // .env dosyasından güvenli okuma
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  Future<RaceAiAnalysis> fetchNextRaceAnalysis() async {
    if (_apiKey.isEmpty) {
      return RaceAiAnalysis.fallback();
    }

    final prompt = '''
Sen Formula 1 teknik analiz uzmanı bir yapay zekasın. Formula 1 güncel takvimindeki bir sonraki yarış için teknik bir değerlendirme hazırla.
Aşağıdaki anahtarlara sahip geçerli bir JSON üret. Markdown etiketi (```json) kullanma.

JSON formatı:
{
  "raceName": "Yarış Adı",
  "circuitName": "Pist Adı",
  "countryCode": "Ülke 3 Harf Kodu (örn: ESP, ITA, GBR, JPN)",
  "dateText": "Yarış Günü ve Saati (örn: Pazar, 16:00)",
  "circuitImageUrl": "[https://media.formula1.com/image/upload/f_auto,c_limit,w_960,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/Spain_Circuit.png](https://media.formula1.com/image/upload/f_auto,c_limit,w_960,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/Spain_Circuit.png)",
  "lastRaceSummary": "Bir önceki yarışta ne oldu (1-2 cümle)",
  "weatherTrack": "Hava durumu, asfalt özellikleri ve lastik aşınması (1-2 cümle)",
  "teamForm": "Takımların formu, pist karakteristiğine uyumu (1-2 cümle)",
  "strategyTires": "Pirelli lastik hamurları ve beklenen pit stop stratejisi (1-2 cümle)",
  "podiumPrediction": "Yapay zeka podyum tahmini (örn: 1. Verstappen  •  2. Norris  •  3. Leclerc)"
}
''';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 800,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String raw = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final map = json.decode(raw);
        return RaceAiAnalysis(
          raceName: map['raceName'] ?? 'Gelecek Grand Prix',
          circuitName: map['circuitName'] ?? 'F1 Pisti',
          countryCode: map['countryCode'] ?? 'ESP',
          dateText: map['dateText'] ?? 'Pazar, 16:00',
          circuitImageUrl: map['circuitImageUrl'] ?? RaceAiAnalysis.fallback().circuitImageUrl,
          lastRaceSummary: map['lastRaceSummary'] ?? '',
          weatherTrack: map['weatherTrack'] ?? '',
          teamForm: map['teamForm'] ?? '',
          strategyTires: map['strategyTires'] ?? '',
          podiumPrediction: map['podiumPrediction'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('EurekaAiService race analysis error: $e');
    }
    return RaceAiAnalysis.fallback();
  }

  // 2. Kullanıcının sorduğu soruya chat cevabı üretir
  Future<String> askEurekaAssistant({
    required String question,
    required List<Map<String, String>> chatHistory,
  }) async {
    // API anahtarı yoksa veya .env okunmadıysa güvenli fallback
    if (_apiKey.isEmpty) {
      return 'API anahtarı henüz eklenmedi veya okunamadı. Yine de genel bilgi olarak: Takımların pit stratejileri ve lastik aşınması pist sıcaklığına göre anlık değişmektedir!';
    }

    final contents = chatHistory.map((m) {
      return {
        'role': m['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': m['text'] ?? ''}]
      };
    }).toList();

    contents.add({
      'role': 'user',
      'parts': [
        {
          'text':
          'Sen F1 taraftarları için geliştirilmiş samimi, bilgili ve analiz odaklı Eureka F1 Yapay Zeka Asistanısın. Kısa, teknik ve net Türkçe yanıt ver: $question'
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 400,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Bir yanıt üretilemedi.';
      } else {
        debugPrint('Eureka Assistant API Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Eureka Assistant Exception: $e');
    }

    return 'Bağlantı sırasında bir hata oluştu. Lütfen tekrar deneyin.';
  }
}