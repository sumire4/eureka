import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String iconCode;
  final String cityName;

  WeatherData({required this.temperature, required this.iconCode, required this.cityName});

  IconData get icon {
    if (iconCode.startsWith('01')) return CupertinoIcons.sun_max_fill;
    if (iconCode.startsWith('02')) return CupertinoIcons.cloud_sun_fill;
    if (iconCode.startsWith('03') || iconCode.startsWith('04')) return CupertinoIcons.cloud_fill;
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return CupertinoIcons.cloud_rain_fill;
    if (iconCode.startsWith('11')) return CupertinoIcons.cloud_bolt_rain_fill;
    if (iconCode.startsWith('13')) return CupertinoIcons.snow;
    if (iconCode.startsWith('50')) return CupertinoIcons.cloud_fog_fill;
    return CupertinoIcons.cloud_sun_fill;
  }
}

class NextRaceInfo {
  final String circuitName;
  final String meetingName;
  final String countryName;
  final String countryFlag;
  final String circuitImageUrl;
  final String circuitLength;
  final int totalLaps;
  final int drsZones;
  final String lapRecord;
  final String lapRecordHolder;
  final DateTime raceDate;
  final String countdownText;

  NextRaceInfo({
    required this.circuitName,
    required this.meetingName,
    required this.countryName,
    required this.countryFlag,
    required this.circuitImageUrl,
    required this.circuitLength,
    required this.totalLaps,
    required this.drsZones,
    required this.lapRecord,
    required this.lapRecordHolder,
    required this.raceDate,
    required this.countdownText,
  });

  factory NextRaceInfo.fallback() {
    return NextRaceInfo(
      circuitName: 'Autódromo Hermanos Rodríguez',
      meetingName: 'Mexico City Grand Prix',
      countryName: 'Meksika',
      countryFlag: '🇲🇽',
      circuitImageUrl: 'https://media.formula1.com/image/upload/f_auto,c_limit,w_1440,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/Mexico_Circuit.png',
      circuitLength: '4.304 km',
      totalLaps: 71,
      drsZones: 3,
      lapRecord: '1:17.774',
      lapRecordHolder: 'Valtteri Bottas (2021)',
      raceDate: DateTime.now().add(const Duration(days: 1, hours: 7)),
      countdownText: '1 gün 7 sa',
    );
  }
}

class DashboardService {
  static String get _weatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static Future<NextRaceInfo> fetchNextRace() async {
    try {
      final currentYear = DateTime.now().year;
      final url = 'https://api.openf1.org/v1/meetings?year=$currentYear';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        final now = DateTime.now().toUtc();

        Map<String, dynamic>? nextMeeting;
        DateTime? nextDate;

        for (var item in list) {
          final dateStr = item['date_start'] as String?;
          if (dateStr != null) {
            final d = DateTime.tryParse(dateStr)?.toUtc();
            if (d != null && d.isAfter(now)) {
              if (nextDate == null || d.isBefore(nextDate)) {
                nextDate = d;
                nextMeeting = item;
              }
            }
          }
        }

        if (nextMeeting != null && nextDate != null) {
          final diff = nextDate.difference(now);
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          final minutes = diff.inMinutes % 60;

          String countdown;
          if (days > 0) {
            countdown = '$days gün $hours sa';
          } else if (hours > 0) {
            countdown = '$hours sa $minutes dk';
          } else {
            countdown = '$minutes dakika';
          }

          final circuit = (nextMeeting['circuit_short_name'] ??
              nextMeeting['location'] ??
              'Grand Prix Pist')
              .toString();
          final name = (nextMeeting['meeting_name'] ?? 'Formula 1 Grand Prix').toString();
          final country = (nextMeeting['country_name'] ?? 'Yarış Ülkesi').toString();

          // Ülkeye göre bayrak ve pist krokisi eşleştirmesi
          final flag = _getCountryFlag(country);
          final circuitImg = _getCircuitMap(circuit);

          return NextRaceInfo(
            circuitName: circuit,
            meetingName: name,
            countryName: country,
            countryFlag: flag,
            circuitImageUrl: circuitImg,
            circuitLength: '4.304 km',
            totalLaps: 71,
            drsZones: 3,
            lapRecord: '1:17.774',
            lapRecordHolder: 'Valtteri Bottas',
            raceDate: nextDate.toLocal(),
            countdownText: countdown,
          );
        }
      }
    } catch (e) {
      debugPrint('fetchNextRace Hatası: $e');
    }

    return NextRaceInfo.fallback();
  }

  // Ülke adına göre bayrak emojisi
  static String _getCountryFlag(String country) {
    final lower = country.toLowerCase();
    if (lower.contains('mexico') || lower.contains('meksika')) return '🇲🇽';
    if (lower.contains('brazil') || lower.contains('brezilya')) return '🇧🇷';
    if (lower.contains('united states') || lower.contains('usa') || lower.contains('amerika')) return '🇺🇸';
    if (lower.contains('abu dhabi') || lower.contains('uae') || lower.contains('bae')) return '🇦🇪';
    if (lower.contains('qatar') || lower.contains('katar')) return '🇶🇦';
    if (lower.contains('las vegas')) return '🇺🇸';
    if (lower.contains('italy') || lower.contains('italya')) return '🇮🇹';
    if (lower.contains('monaco')) return '🇲🇨';
    if (lower.contains('spain') || lower.contains('ispanya')) return '🇪🇸';
    if (lower.contains('great britain') || lower.contains('uk') || lower.contains('ingiltere')) return '🇬🇧';
    return '🏁';
  }

  // Piste göre harita görseli (yüklenemezse varsayılan F1 pist krokisi)
  static String _getCircuitMap(String circuit) {
    return 'https://media.formula1.com/image/upload/f_auto,c_limit,w_1440,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/Mexico_Circuit.png';
  }

  /// Cihazdan konum izni ister ve anlık koordinatları döner
  static Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisleri cihazda açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static String getCountryFlagUrl(String country) {
    final lower = country.toLowerCase().trim();

    // F1 Takvimindeki tüm ülkelerin ISO 3166-1 alpha-2 kod eşleştirmesi
    const Map<String, String> countryCodeMap = {
      // Bahreyn
      'bahrain': 'bh',
      'bahreyn': 'bh',
      'sakhir': 'bh',

      // Suudi Arabistan
      'saudi arabia': 'sa',
      'saudi': 'sa',
      'suudi arabistan': 'sa',
      'jeddah': 'sa',
      'cidde': 'sa',

      // Avustralya
      'australia': 'au',
      'avustralya': 'au',
      'melbourne': 'au',
      'albert park': 'au',

      // Japonya
      'japan': 'jp',
      'japonya': 'jp',
      'suzuka': 'jp',

      // Çin
      'china': 'cn',
      'çin': 'cn',
      'shanghai': 'cn',

      // Miami / Austin / Las Vegas (ABD)
      'united states': 'us',
      'usa': 'us',
      'amerika': 'us',
      'miami': 'us',
      'austin': 'us',
      'cota': 'us',
      'las vegas': 'us',

      // İtalya (İmola & Monza)
      'italy': 'it',
      'italya': 'it',
      'imola': 'it',
      'monza': 'it',
      'emilia romagna': 'it',

      // Monako
      'monaco': 'mc',
      'monako': 'mc',
      'monte carlo': 'mc',

      // Kanada
      'canada': 'ca',
      'kanada': 'ca',
      'montreal': 'ca',
      'gilles villeneuve': 'ca',

      // İspanya
      'spain': 'es',
      'ispanya': 'es',
      'barcelona': 'es',
      'catalunya': 'es',
      'madrid': 'es',

      // Avusturya
      'austria': 'at',
      'avusturya': 'at',
      'spielberg': 'at',
      'red bull ring': 'at',

      // Birleşik Krallık
      'great britain': 'gb',
      'united kingdom': 'gb',
      'uk': 'gb',
      'ingiltere': 'gb',
      'silverstone': 'gb',

      // Macaristan
      'hungary': 'hu',
      'macaristan': 'hu',
      'budapest': 'hu',
      'hungaroring': 'hu',

      // Belçika
      'belgium': 'be',
      'belçika': 'be',
      'spa': 'be',
      'francorchamps': 'be',

      // Hollanda
      'netherlands': 'nl',
      'hollanda': 'nl',
      'zandvoort': 'nl',

      // Azerbaycan
      'azerbaijan': 'az',
      'azerbaycan': 'az',
      'baku': 'az',
      'bakü': 'az',

      // Singapur
      'singapore': 'sg',
      'singapur': 'sg',
      'marina bay': 'sg',

      // Meksika
      'mexico': 'mx',
      'meksika': 'mx',
      'mexico city': 'mx',
      'hermanos rodriguez': 'mx',

      // Brezilya
      'brazil': 'br',
      'brezilya': 'br',
      'sao paulo': 'br',
      'interlagos': 'br',

      // Katar
      'qatar': 'qa',
      'katar': 'qa',
      'lusail': 'qa',

      // Abu Dabi (BAE)
      'abu dhabi': 'ae',
      'uae': 'ae',
      'bae': 'ae',
      'united arab emirates': 'ae',
      'yas marina': 'ae',
    };

    // Doğrudan veya anahtar kelime eşleşmesi kontrolü
    for (final entry in countryCodeMap.entries) {
      if (lower.contains(entry.key)) {
        return 'https://flagcdn.com/w160/${entry.value}.png';
      }
    }

    // Eşleşme bulunamazsa varsayılan olarak F1 damalı bayrağı simgesi fallback'i
    return 'https://flagcdn.com/w160/un.png';
  }

  /// Konumu alıp OpenWeather'dan anlık hava durumunu çeker
  static Future<WeatherData?> fetchCurrentWeather() async {
    // 1. Önce cihaz konumunu almaya çalış
    final position = await _determinePosition();

    // Konum alındıysa cihaz koordinatları, alınamadıysa varsayılan koordinat
    final double lat = position?.latitude ?? 38.68;
    final double lon = position?.longitude ?? 39.22;

    if (_weatherApiKey.isEmpty) {
      return WeatherData(temperature: 19.0, iconCode: '01d', cityName: 'name');
    }

    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_weatherApiKey';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final temp = (data['main']['temp'] as num).toDouble();
        final icon = data['weather']?[0]?['icon'] as String? ?? '01d';
        final city = data['name'] as String? ?? 'Elâzığ'; // Şehir adı

        return WeatherData(
          temperature: temp,
          iconCode: icon,
          cityName: city,
        );
      }
    } catch (_) {}

    return WeatherData(temperature: 19.0, iconCode: '01d', cityName: 'Elâzığ');
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Günaydın';
    if (hour >= 12 && hour < 18) return 'İyi günler';
    if (hour >= 18 && hour < 23) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  static Map<String, String> getCountdownToNextRace() {
    final now = DateTime.now();
    int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    if (daysUntilSunday == 0 && now.hour >= 18) {
      daysUntilSunday = 7;
    }
    final targetRace = DateTime(now.year, now.month, now.day + daysUntilSunday, 16, 0);
    final diff = targetRace.difference(now);

    final days = diff.inDays;
    final hours = diff.inHours % 24;

    return {
      'label': days > 0 ? '$days gün $hours sa' : '$hours saat kaldı',
    };
  }
}