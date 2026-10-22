import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DriverStanding {
  final String position;
  final String driverId;
  final String driverNumber;
  final String code;
  final String fullName;
  final String constructorName;
  final String points;
  final String wins;
  String? headshotUrl;

  DriverStanding({
    required this.position,
    required this.driverId,
    required this.driverNumber,
    required this.code,
    required this.fullName,
    required this.constructorName,
    required this.points,
    required this.wins,
    this.headshotUrl,
  });

  factory DriverStanding.fromJson(Map<String, dynamic> json) {
    final driver = json['Driver'] ?? {};
    final constructors = (json['Constructors'] as List?) ?? [];
    final constructorName = constructors.isNotEmpty ? constructors.first['name'] ?? '' : '';

    return DriverStanding(
      position: json['position']?.toString() ?? '',
      driverId: driver['driverId'] ?? '',
      driverNumber: driver['permanentNumber']?.toString() ?? '',
      code: driver['code'] ?? '',
      fullName: '${driver['givenName'] ?? ''} ${driver['familyName'] ?? ''}'.trim(),
      constructorName: constructorName,
      points: json['points']?.toString() ?? '0',
      wins: json['wins']?.toString() ?? '0',
    );
  }
}

class ConstructorStanding {
  final String position;
  final String constructorId;
  final String name;
  final String points;
  final String wins;

  ConstructorStanding({
    required this.position,
    required this.constructorId,
    required this.name,
    required this.points,
    required this.wins,
  });

  factory ConstructorStanding.fromJson(Map<String, dynamic> json) {
    final constructor = json['Constructor'] ?? {};
    return ConstructorStanding(
      position: json['position']?.toString() ?? '',
      constructorId: constructor['constructorId'] ?? '',
      name: constructor['name'] ?? '',
      points: json['points']?.toString() ?? '0',
      wins: json['wins']?.toString() ?? '0',
    );
  }
}

class StandingsService {
  static const String _driverUrl = 'https://api.jolpi.ca/ergast/f1/current/driverStandings.json';
  static const String _constructorUrl = 'https://api.jolpi.ca/ergast/f1/current/constructorStandings.json';
  static const String _openF1DriversUrl = 'https://api.openf1.org/v1/drivers';

  // OpenF1'den fotoğrafları çeken yardımcı fonksiyon
  Future<Map<String, String>> fetchOpenF1Headshots() async {
    try {
      final response = await http.get(Uri.parse(_openF1DriversUrl));
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        final Map<String, String> headshots = {};

        for (var item in list) {
          final photo = item['headshot_url']?.toString();
          final num = item['driver_number']?.toString();
          final name = item['full_name']?.toString().toLowerCase().trim();
          final lastName = item['last_name']?.toString().toLowerCase().trim();

          if (photo != null && photo.isNotEmpty) {
            if (num != null && num.isNotEmpty) headshots[num] = photo;
            if (name != null && name.isNotEmpty) headshots[name] = photo;
            if (lastName != null && lastName.isNotEmpty) headshots[lastName] = photo;
          }
        }
        return headshots;
      }
    } catch (e) {
      debugPrint('OpenF1 headshots hatası: $e');
    }
    return {};
  }

  Future<List<DriverStanding>> fetchDriverStandings() async {
    try {
      final standingsFuture = http.get(Uri.parse(_driverUrl));
      final headshotsFuture = fetchOpenF1Headshots();

      final results = await Future.wait([standingsFuture, headshotsFuture]);
      final response = results[0] as http.Response;
      final headshots = results[1] as Map<String, String>;

      List<DriverStanding> drivers = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lists = data['MRData']?['StandingsTable']?['StandingsLists'] as List?;
        if (lists != null && lists.isNotEmpty) {
          final driverStandings = lists.first['DriverStandings'] as List?;
          if (driverStandings != null && driverStandings.isNotEmpty) {
            drivers = driverStandings.map((item) => DriverStanding.fromJson(item)).toList();
          }
        }
      }

      if (drivers.isEmpty) {
        drivers = await _fetchFallbackDrivers();
      }

      // OpenF1'den gelen fotoğrafları eşleştiriyoruz
      for (var d in drivers) {
        final lastName = d.fullName.split(' ').last.toLowerCase();
        d.headshotUrl = headshots[d.driverNumber] ??
            headshots[d.fullName.toLowerCase()] ??
            headshots[lastName];
      }

      return drivers;
    } catch (e) {
      debugPrint('Standings fetch exception: $e');
      return await _fetchFallbackDrivers();
    }
  }

  Future<List<ConstructorStanding>> fetchConstructorStandings() async {
    try {
      final response = await http.get(Uri.parse(_constructorUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lists = data['MRData']?['StandingsTable']?['StandingsLists'] as List?;
        if (lists != null && lists.isNotEmpty) {
          final constructorStandings = lists.first['ConstructorStandings'] as List?;
          if (constructorStandings != null && constructorStandings.isNotEmpty) {
            return constructorStandings.map((item) => ConstructorStanding.fromJson(item)).toList();
          }
        }
      }
      return await _fetchFallbackConstructors();
    } catch (_) {
      return await _fetchFallbackConstructors();
    }
  }

  Future<List<DriverStanding>> _fetchFallbackDrivers() async {
    try {
      final res = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/2024/driverStandings.json'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final lists = data['MRData']?['StandingsTable']?['StandingsLists'] as List?;
        if (lists != null && lists.isNotEmpty) {
          final items = lists.first['DriverStandings'] as List?;
          if (items != null) {
            return items.map((item) => DriverStanding.fromJson(item)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<ConstructorStanding>> _fetchFallbackConstructors() async {
    try {
      final res = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/2024/constructorStandings.json'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final lists = data['MRData']?['StandingsTable']?['StandingsLists'] as List?;
        if (lists != null && lists.isNotEmpty) {
          final items = lists.first['ConstructorStandings'] as List?;
          if (items != null) {
            return items.map((item) => ConstructorStanding.fromJson(item)).toList();
          }
        }
      }
    } catch (_) {}
    return [];
  }
}