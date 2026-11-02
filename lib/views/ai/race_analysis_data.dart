// lib/screens/race_analysis_data.dart
//
// Eureka AI yarış analizi - veri katmanı.
// OpenF1'den gerçek veri çeker, istatistiksel tahmin üretir,
// Gemini'ye SADECE bu gerçek veriyi verip yorum yazdırır.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

double? _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v == null) return null;
  return double.tryParse(v.toString());
}

int? _int(dynamic v) {
  if (v is num) return v.toInt();
  if (v == null) return null;
  return int.tryParse(v.toString());
}

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime _date(dynamic v) =>
    DateTime.tryParse(_str(v))?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

Color _hex(dynamic v) {
  final s = _str(v).replaceAll('#', '');
  final n = int.tryParse(s, radix: 16);
  if (n == null || s.length != 6) return const Color(0xFF8E8E93);
  return Color(0xFF000000 | n);
}

// ───────────────────────── Yardımcılar ─────────────────────────

const _alpha2 = {
  'BRN': 'BH', 'BHR': 'BH', 'KSA': 'SA', 'SAU': 'SA', 'AUS': 'AU',
  'JPN': 'JP', 'CHN': 'CN', 'USA': 'US', 'ITA': 'IT', 'MON': 'MC',
  'MCO': 'MC', 'CAN': 'CA', 'ESP': 'ES', 'AUT': 'AT', 'GBR': 'GB',
  'BEL': 'BE', 'HUN': 'HU', 'NED': 'NL', 'NLD': 'NL', 'AZE': 'AZ',
  'SGP': 'SG', 'SIN': 'SG', 'MEX': 'MX', 'BRA': 'BR', 'QAT': 'QA',
  'UAE': 'AE', 'ARE': 'AE', 'POR': 'PT', 'TUR': 'TR', 'GER': 'DE',
  'FRA': 'FR', 'RSA': 'ZA',
};

String flagEmoji(String code) {
  final a2 = _alpha2[code.toUpperCase()];
  if (a2 == null) return '🏁';
  return String.fromCharCodes(a2.codeUnits.map((c) => 0x1F1E6 + c - 0x41));
}

String sessionNameTr(String n) {
  switch (n) {
    case 'Practice 1':
      return 'Antrenman 1';
    case 'Practice 2':
      return 'Antrenman 2';
    case 'Practice 3':
      return 'Antrenman 3';
    case 'Qualifying':
      return 'Sıralama Turları';
    case 'Sprint Qualifying':
    case 'Sprint Shootout':
      return 'Sprint Sıralama';
    case 'Sprint':
      return 'Sprint Yarışı';
    case 'Race':
      return 'Yarış';
    default:
      return n;
  }
}

String formatRaceTime(double s) {
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${sec.toStringAsFixed(3).padLeft(6, '0')}';
}

DriverInfo driverOf(Map<int, DriverInfo> m, int n) =>
    m[n] ?? DriverInfo.unknown(n);

// ───────────────────────── Modeller ─────────────────────────

class Meeting {
  final int key, year, circuitKey;
  final String name, location, country, countryCode, circuit, circuitImage;
  final DateTime start, end;

  const Meeting({
    required this.key,
    required this.year,
    required this.circuitKey,
    required this.name,
    required this.location,
    required this.country,
    required this.countryCode,
    required this.circuit,
    required this.circuitImage,
    required this.start,
    required this.end,
  });

  factory Meeting.fromJson(Json j) => Meeting(
    key: _int(j['meeting_key']) ?? 0,
    year: _int(j['year']) ?? 0,
    circuitKey: _int(j['circuit_key']) ?? 0,
    name: _str(j['meeting_name']),
    location: _str(j['location']),
    country: _str(j['country_name']),
    countryCode: _str(j['country_code']),
    circuit: _str(j['circuit_short_name']),
    circuitImage: _str(j['circuit_image']),
    start: _date(j['date_start']),
    end: _date(j['date_end']),
  );
}

class SessionInfo {
  final int key;
  final String name, countryCode;
  final DateTime start, end;

  const SessionInfo({
    required this.key,
    required this.name,
    required this.countryCode,
    required this.start,
    required this.end,
  });

  factory SessionInfo.fromJson(Json j) => SessionInfo(
    key: _int(j['session_key']) ?? 0,
    name: _str(j['session_name']),
    countryCode: _str(j['country_code']),
    start: _date(j['date_start']),
    end: _date(j['date_end']),
  );
}

class DriverInfo {
  final int number;
  final String acronym, name, team, headshot;
  final Color color;

  const DriverInfo({
    required this.number,
    required this.acronym,
    required this.name,
    required this.team,
    required this.headshot,
    required this.color,
  });

  factory DriverInfo.unknown(int n) => DriverInfo(
    number: n,
    acronym: '#$n',
    name: 'Pilot #$n',
    team: '',
    headshot: '',
    color: const Color(0xFF8E8E93),
  );

  factory DriverInfo.fromJson(Json j) {
    final n = _int(j['driver_number']) ?? 0;
    final full = _str(j['full_name']).isNotEmpty
        ? _str(j['full_name'])
        : _str(j['broadcast_name']);
    return DriverInfo(
      number: n,
      acronym: _str(j['name_acronym']).isEmpty ? '#$n' : _str(j['name_acronym']),
      name: full.isEmpty ? 'Pilot #$n' : full,
      team: _str(j['team_name']),
      headshot: _str(j['headshot_url']),
      color: _hex(j['team_colour']),
    );
  }

  String get lastName {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? name : parts.last;
  }
}

class ResultRow {
  final int driver, laps;
  final int? position;
  final double points;
  final bool dnf, dns, dsq;
  final String gap;
  final double? time;

  const ResultRow({
    required this.driver,
    required this.position,
    required this.laps,
    required this.points,
    required this.dnf,
    required this.dns,
    required this.dsq,
    required this.gap,
    required this.time,
  });

  bool get out => dnf || dns || dsq;

  factory ResultRow.fromJson(Json j) {
    final g = j['gap_to_leader'];
    var gap = '';
    if (g is num) {
      gap = g == 0 ? '' : '+${g.toStringAsFixed(3)}';
    } else if (g is String) {
      gap = g;
    }
    final d = j['duration'];
    return ResultRow(
      driver: _int(j['driver_number']) ?? 0,
      position: _int(j['position']),
      laps: _int(j['number_of_laps']) ?? 0,
      points: _num(j['points']) ?? 0,
      dnf: j['dnf'] == true,
      dns: j['dns'] == true,
      dsq: j['dsq'] == true,
      gap: gap,
      time: d is num ? d.toDouble() : null,
    );
  }
}

class StintRow {
  final int driver, number, lapStart;
  final int? lapEnd;
  final String compound;

  const StintRow({
    required this.driver,
    required this.number,
    required this.lapStart,
    required this.lapEnd,
    required this.compound,
  });

  factory StintRow.fromJson(Json j) => StintRow(
    driver: _int(j['driver_number']) ?? 0,
    number: _int(j['stint_number']) ?? 0,
    lapStart: _int(j['lap_start']) ?? 1,
    lapEnd: _int(j['lap_end']),
    compound: _str(j['compound']).toUpperCase(),
  );
}

class WeatherSummary {
  final double? air, track, humidity, wind; // wind m/s
  final bool rain;
  const WeatherSummary({
    this.air,
    this.track,
    this.humidity,
    this.wind,
    required this.rain,
  });
}

class StandingRow {
  final int driver, position;
  final double points;
  const StandingRow(this.driver, this.position, this.points);
}

// ── Sayfa bölümlerine özel paketler ──

class Calendar {
  final Meeting? next, previous;
  const Calendar(this.next, this.previous);
}

class Recap {
  final Meeting meeting;
  final SessionInfo race;
  final List<ResultRow> results;
  final Map<int, DriverInfo> drivers;
  final Map<int, int> grid;
  const Recap(this.meeting, this.race, this.results, this.drivers, this.grid);
}

class StintData {
  final List<StintRow> rows;
  final List<ResultRow> results;
  final Map<int, DriverInfo> drivers;
  final int totalLaps;
  const StintData(this.rows, this.results, this.drivers, this.totalLaps);
}

class RaceWeather {
  final Meeting meeting;
  final WeatherSummary summary;
  const RaceWeather(this.meeting, this.summary);
}

class Standings {
  final List<StandingRow> rows;
  final Map<int, DriverInfo> drivers;
  const Standings(this.rows, this.drivers);
}

class FormData {
  final List<String> labels;
  final Map<int, List<int?>> positions; // 0 = bitirmedi
  final Map<int, double> points;
  const FormData(this.labels, this.positions, this.points);
}

class FormRow {
  final DriverInfo driver;
  final List<int?> positions;
  const FormRow(this.driver, this.positions);
}

class FormTable {
  final List<String> labels;
  final List<FormRow> rows;
  const FormTable(this.labels, this.rows);
}

class TrackHistory {
  final Meeting meeting;
  final List<ResultRow> top;
  final Map<int, DriverInfo> drivers;
  final Map<int, int> positions; // 0 = bitirmedi
  final List<StintRow> winnerStints;
  final int winnerLaps;
  final WeatherSummary? weather;
  const TrackHistory(this.meeting, this.top, this.drivers, this.positions,
      this.winnerStints, this.winnerLaps, this.weather);
}

class Prediction {
  final DriverInfo driver;
  final double score, prob, form, champ, track;
  const Prediction(
      this.driver, this.score, this.prob, this.form, this.champ, this.track);
}

class Commentary {
  final String overview, strategy, battle, risk;
  const Commentary(this.overview, this.strategy, this.battle, this.risk);
}

// ───────────────────────── OpenF1 istemcisi ─────────────────────────

class _CacheEntry {
  final List<Json> data;
  final DateTime at;
  _CacheEntry(this.data, this.at);
}

/// Ücretsiz OpenF1 limitine (3 istek/sn, 30 istek/dk) uymak için istekleri
/// sıraya dizer, aralarına bekleme koyar ve 10 dk önbellekler.
class OpenF1 {
  OpenF1._();
  static final OpenF1 instance = OpenF1._();
  static const _base = 'https://api.openf1.org/v1';

  final Map<String, _CacheEntry> _cache = {};
  Future<void> _gate = Future<void>.value();

  void clearCache() => _cache.clear();

  Future<T> _queue<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    _gate = _gate.then((_) async {
      try {
        completer.complete(await job());
      } catch (e, s) {
        completer.completeError(e, s);
      }
      await Future<void>.delayed(const Duration(milliseconds: 380));
    });
    return completer.future;
  }

  Future<List<Json>> get(String endpoint, Map<String, String> query) async {
    final uri = Uri.parse('$_base/$endpoint').replace(queryParameters: query);
    final key = uri.toString();
    final hit = _cache[key];
    if (hit != null &&
        DateTime.now().difference(hit.at) < const Duration(minutes: 10)) {
      return hit.data;
    }

    final data = await _queue<List<Json>>(() async {
      for (var attempt = 0; attempt < 3; attempt++) {
        final res = await http.get(uri).timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          final decoded = json.decode(utf8.decode(res.bodyBytes));
          if (decoded is List) {
            return decoded
                .whereType<Map>()
                .map((e) => Json.from(e))
                .toList();
          }
          return <Json>[];
        }
        if (res.statusCode == 404) return <Json>[]; // sonuç yok
        if (res.statusCode == 429) {
          await Future<void>.delayed(Duration(seconds: 1 + attempt));
          continue;
        }
        throw Exception('OpenF1 ${res.statusCode}');
      }
      throw Exception('OpenF1 istek limiti aşıldı');
    });

    _cache[key] = _CacheEntry(data, DateTime.now());
    return data;
  }
}

// ───────────────────────── Gemini yorumu ─────────────────────────

class GeminiCommentary {
  // Model adı zamanla değişebilir; gerekirse burayı güncelle.
  static const _model = 'gemini-2.5-flash';

  static Future<Commentary?> generate(Json context) async {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty) return null;

    final prompt = '''
Sen Formula 1 teknik analiz uzmanısın. Aşağıda OpenF1'den alınmış GERÇEK veriler ve istatistiksel bir tahmin modelinin çıktısı var.
Sadece bu verilere dayanarak, Türkçe ve kısa yorum yaz. Verilmeyen sayı, pilot, takım veya olay UYDURMA.
Her alan en fazla 2 cümle olsun.

Veri:
${json.encode(context)}

Yalnızca şu anahtarlara sahip geçerli bir JSON döndür:
{"overview": "hafta sonuna genel bakış", "strategy": "lastik ve pit stratejisi beklentisi", "battle": "izlenmesi gereken çekişme", "risk": "sürpriz/risk faktörü"}
''';

    try {
      final res = await http
          .post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': key,
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 1000,
            'responseMimeType': 'application/json',
            'thinkingConfig': {'thinkingBudget': 0},
          },
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        debugPrint('Gemini hata: ${res.statusCode} ${res.body}');
        return null;
      }
      final data = json.decode(utf8.decode(res.bodyBytes));
      var text =
      _str(data['candidates'][0]['content']['parts'][0]['text']).trim();
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final m = json.decode(text) as Map<String, dynamic>;
      return Commentary(
        _str(m['overview']),
        _str(m['strategy']),
        _str(m['battle']),
        _str(m['risk']),
      );
    } catch (e) {
      debugPrint('Gemini yorum hatası: $e');
      return null;
    }
  }
}

// ───────────────────────── Denetleyici ─────────────────────────

/// Sayfadaki her bölüm kendi Future'ını dinler; böylece veri geldikçe
/// bölümler tek tek ekrana düşer.
class RaceAnalysisController {
  final OpenF1 _api = OpenF1.instance;

  late final Future<Calendar?> calendar = _loadCalendar();
  late final Future<List<SessionInfo>?> nextSessions = _loadNextSessions();
  late final Future<Recap?> recap = _loadRecap();
  late final Future<StintData?> stints = _loadStints();
  late final Future<RaceWeather?> weather = _loadWeather();
  late final Future<Standings?> standings = _loadStandings();
  late final Future<FormData?> form = _loadForm();
  late final Future<TrackHistory?> history = _loadHistory();
  late final Future<List<Prediction>?> prediction = _loadPrediction();
  late final Future<FormTable?> formTable = _loadFormTable();
  late final Future<Commentary?> commentary = _loadCommentary();

  // ── takvim ──

  Future<List<Meeting>> _meetings(int year) async {
    final rows = await _api.get('meetings', {'year': '$year'});
    return rows
        .map(Meeting.fromJson)
        .where((m) => !m.name.toLowerCase().contains('testing'))
        .toList();
  }

  Future<List<Meeting>> _safeMeetings(int year) async {
    try {
      return await _meetings(year);
    } catch (_) {
      return [];
    }
  }

  Future<Calendar?> _loadCalendar() async {
    final now = DateTime.now().toUtc();
    var all = await _meetings(now.year);
    if (!all.any((m) => m.end.isAfter(now))) {
      all = [...all, ...await _safeMeetings(now.year + 1)];
    }
    if (!all.any((m) => m.end.isBefore(now))) {
      all = [...await _safeMeetings(now.year - 1), ...all];
    }
    all.sort((a, b) => a.start.compareTo(b.start));
    Meeting? next, prev;
    for (final m in all) {
      if (m.end.isAfter(now)) {
        next ??= m;
      } else {
        prev = m;
      }
    }
    return Calendar(next, prev);
  }

  Future<List<SessionInfo>> _sessions(int meetingKey) async {
    final rows = await _api.get('sessions', {'meeting_key': '$meetingKey'});
    return rows.map(SessionInfo.fromJson).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<List<SessionInfo>?> _loadNextSessions() async {
    final cal = await calendar;
    final next = cal?.next;
    if (next == null) return null;
    final s = await _sessions(next.key);
    return s.isEmpty ? null : s;
  }

  // ── genel çekiciler ──

  Future<SessionInfo?> _raceSession(int meetingKey) async {
    final s = await _sessions(meetingKey);
    for (final x in s) {
      if (x.name == 'Race') return x;
    }
    return null;
  }

  Future<List<ResultRow>> _results(int sessionKey) async {
    final rows = await _api.get('session_result', {'session_key': '$sessionKey'});
    return rows.map(ResultRow.fromJson).toList()
      ..sort((a, b) => (a.position ?? 99).compareTo(b.position ?? 99));
  }

  Future<Map<int, DriverInfo>> _drivers(int sessionKey) async {
    final rows = await _api.get('drivers', {'session_key': '$sessionKey'});
    final map = <int, DriverInfo>{};
    for (final j in rows) {
      final d = DriverInfo.fromJson(j);
      map[d.number] = d;
    }
    return map;
  }

  WeatherSummary? _summarize(List<Json> rows) {
    if (rows.isEmpty) return null;
    double? avg(String k) {
      final v = rows.map((r) => _num(r[k])).whereType<double>().toList();
      return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
    }

    return WeatherSummary(
      air: avg('air_temperature'),
      track: avg('track_temperature'),
      humidity: avg('humidity'),
      wind: avg('wind_speed'),
      rain: rows.any((r) => (_num(r['rainfall']) ?? 0) > 0),
    );
  }

  // ── son yarış ──

  Future<Recap?> _loadRecap() async {
    final cal = await calendar;
    final m = cal?.previous;
    if (m == null) return null;
    final race = await _raceSession(m.key);
    if (race == null) return null;
    final results = await _results(race.key);
    if (results.isEmpty) return null;
    final drivers = await _drivers(race.key);
    final grid = <int, int>{};
    try {
      final rows = await _api.get('starting_grid', {'session_key': '${race.key}'});
      for (final j in rows) {
        final n = _int(j['driver_number']);
        final p = _int(j['position']);
        if (n != null && p != null) grid[n] = p;
      }
    } catch (_) {}
    return Recap(m, race, results, drivers, grid);
  }

  Future<StintData?> _loadStints() async {
    final r = await recap;
    if (r == null) return null;
    final rows = await _api.get('stints', {'session_key': '${r.race.key}'});
    if (rows.isEmpty) return null;
    final total = r.results.fold<int>(0, (a, b) => math.max(a, b.laps));
    return StintData(
        rows.map(StintRow.fromJson).toList(), r.results, r.drivers, total);
  }

  Future<RaceWeather?> _loadWeather() async {
    final r = await recap;
    if (r == null) return null;
    final rows = await _api.get('weather', {'session_key': '${r.race.key}'});
    final s = _summarize(rows);
    return s == null ? null : RaceWeather(r.meeting, s);
  }

  Future<Standings?> _loadStandings() async {
    final r = await recap;
    if (r == null) return null;
    try {
      final rows = await _api
          .get('championship_drivers', {'session_key': '${r.race.key}'});
      final list = rows
          .map((j) => StandingRow(_int(j['driver_number']) ?? 0,
          _int(j['position_current']) ?? 99, _num(j['points_current']) ?? 0))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      return list.isEmpty ? null : Standings(list, r.drivers);
    } catch (_) {
      return null;
    }
  }

  // ── son 3 yarış formu ──

  Future<FormData?> _loadForm() async {
    final cal = await calendar;
    final prev = cal?.previous;
    if (prev == null) return null;
    final now = DateTime.now().toUtc();
    final rows = await _api
        .get('sessions', {'year': '${prev.year}', 'session_name': 'Race'});
    final done = rows
        .map(SessionInfo.fromJson)
        .where((s) => s.end.isBefore(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (done.isEmpty) return null;
    final last = done.length > 3 ? done.sublist(done.length - 3) : done;

    final positions = <int, List<int?>>{};
    final points = <int, double>{};
    for (var i = 0; i < last.length; i++) {
      final res = await _results(last[i].key);
      for (final r in res) {
        final list = positions.putIfAbsent(
            r.driver, () => List<int?>.filled(last.length, null));
        list[i] = r.out ? 0 : r.position;
        points[r.driver] = (points[r.driver] ?? 0) + r.points;
      }
    }
    return FormData(last.map((s) => s.countryCode).toList(), positions, points);
  }

  // ── bu pistte geçen yıl ──

  Future<TrackHistory?> _loadHistory() async {
    final cal = await calendar;
    final next = cal?.next;
    if (next == null) return null;
    final rows = await _api.get('meetings', {
      'year': '${next.year - 1}',
      'circuit_key': '${next.circuitKey}',
    });
    final meetings = rows.map(Meeting.fromJson).toList();
    if (meetings.isEmpty) return null;
    final m = meetings.first;
    final race = await _raceSession(m.key);
    if (race == null) return null;
    final results = await _results(race.key);
    if (results.isEmpty) return null;
    final drivers = await _drivers(race.key);

    WeatherSummary? w;
    try {
      w = _summarize(await _api.get('weather', {'session_key': '${race.key}'}));
    } catch (_) {}

    var stints = <StintRow>[];
    final winner = results.first;
    try {
      final s = await _api.get('stints', {
        'session_key': '${race.key}',
        'driver_number': '${winner.driver}',
      });
      stints = s.map(StintRow.fromJson).toList()
        ..sort((a, b) => a.number.compareTo(b.number));
    } catch (_) {}

    final pos = <int, int>{
      for (final r in results) r.driver: r.out ? 0 : (r.position ?? 0)
    };
    return TrackHistory(
        m, results.take(3).toList(), drivers, pos, stints, winner.laps, w);
  }

  // ── tahmin modeli ──
  //
  // Skor = form (son 3 yarış, yakın yarışa daha çok ağırlık)
  //      + şampiyona puanı + bu pistteki geçen yıl sonucu.
  // Bu bir bahis oranı değil, geçmiş veriden türetilmiş istatistiksel bir skordur.

  Future<List<Prediction>?> _loadPrediction() async {
    final r = await recap;
    if (r == null) return null;
    final f = await form;
    final h = await history;
    final st = await standings;

    final pts = <int, double>{};
    if (st != null) {
      for (final s in st.rows) {
        pts[s.driver] = s.points;
      }
    } else if (f != null) {
      pts.addAll(f.points);
    }
    final maxPts = pts.values.fold<double>(0, math.max);

    final wTrack = h == null ? 0.0 : 0.20;
    final wForm = h == null ? 0.55 : 0.45;
    final wChamp = h == null ? 0.45 : 0.35;

    final raw = <List<dynamic>>[]; // [driver, score, form, champ, track]
    for (final d in r.drivers.values) {
      double fs = 0, fw = 0;
      final ps = f?.positions[d.number];
      if (ps != null) {
        for (var i = 0; i < ps.length; i++) {
          final p = ps[i];
          if (p == null) continue;
          final w = (i + 1).toDouble();
          fs += w * (p == 0 ? 0.0 : ((21 - p) / 20).clamp(0.0, 1.0).toDouble());
          fw += w;
        }
      }
      final formScore = fw == 0 ? 0.3 : fs / fw;
      final champ = maxPts == 0 ? 0.0 : (pts[d.number] ?? 0) / maxPts;
      double track = 0;
      if (h != null) {
        final hp = h.positions[d.number];
        track = hp == null
            ? 0.35
            : (hp == 0 ? 0.0 : ((21 - hp) / 20).clamp(0.0, 1.0).toDouble());
      }
      final score = wForm * formScore + wChamp * champ + wTrack * track;
      raw.add([d, score, formScore, champ, track]);
    }
    if (raw.isEmpty) return null;

    final exps = raw.map((e) => math.exp((e[1] as double) * 6)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    final list = <Prediction>[
      for (var i = 0; i < raw.length; i++)
        Prediction(raw[i][0] as DriverInfo, raw[i][1] as double, exps[i] / sum,
            raw[i][2] as double, raw[i][3] as double, raw[i][4] as double)
    ]..sort((a, b) => b.score.compareTo(a.score));
    return list.take(6).toList();
  }

  Future<FormTable?> _loadFormTable() async {
    final preds = await prediction;
    final f = await form;
    if (preds == null || f == null) return null;
    final rows = <FormRow>[
      for (final p in preds)
        FormRow(p.driver,
            f.positions[p.driver.number] ?? List<int?>.filled(f.labels.length, null))
    ];
    return FormTable(f.labels, rows);
  }

  // ── Gemini yorumu (gerçek veriyle beslenir) ──

  Future<Commentary?> _loadCommentary() async {
    final cal = await calendar;
    final next = cal?.next;
    final preds = await prediction;
    final r = await recap;
    if (next == null || preds == null || r == null) return null;
    final w = await weather;
    final h = await history;
    final st = await standings;

    String nameOf(int n) => driverOf(r.drivers, n).name;

    final ctx = <String, dynamic>{
      'sonraki_yaris': {
        'ad': next.name,
        'pist': next.circuit,
        'ulke': next.country,
        'baslangic': next.start.toIso8601String(),
      },
      'tahmin_modeli_ilk5': preds
          .take(5)
          .map((p) => {
        'pilot': p.driver.name,
        'takim': p.driver.team,
        'olasilik_yuzde': (p.prob * 100).round(),
        'form_skoru': double.parse(p.form.toStringAsFixed(2)),
        'sampiyona_skoru': double.parse(p.champ.toStringAsFixed(2)),
        'pist_gecmisi_skoru': double.parse(p.track.toStringAsFixed(2)),
      })
          .toList(),
      'son_yaris': {
        'ad': r.meeting.name,
        'podyum': r.results.take(3).map((x) => nameOf(x.driver)).toList(),
        'yarisi_bitirmeyen_sayisi': r.results.where((x) => x.out).length,
      },
      if (w != null)
        'son_yaris_hava': {
          'hava_c': w.summary.air?.round(),
          'pist_c': w.summary.track?.round(),
          'nem_yuzde': w.summary.humidity?.round(),
          'yagmur': w.summary.rain,
        },
      if (h != null)
        'gecen_yil_bu_pistte': {
          'podyum': h.top.map((x) => driverOf(h.drivers, x.driver).name).toList(),
          'kazanan_lastikleri': h.winnerStints.map((s) => s.compound).toList(),
        },
      if (st != null)
        'sampiyona_ilk5': st.rows
            .take(5)
            .map((s) => {
          'pilot': driverOf(st.drivers, s.driver).name,
          'puan': s.points,
        })
            .toList(),
    };
    return GeminiCommentary.generate(ctx);
  }
}