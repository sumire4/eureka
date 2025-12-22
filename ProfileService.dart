import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProfile {
  String name;
  String email;
  DateTime joinDate;
  int totalTimeSpent; // dakika cinsinden
  int newsRead;
  int videosWatched;
  int sessionsCount;
  List<String> savedNews;
  String profileImagePath;
  bool notificationsEnabled;
  String favoriteDriver;
  String favoriteCircuit;

  UserProfile({
    this.name = 'F1 Hayranı',
    this.email = '',
    DateTime? joinDate,
    this.totalTimeSpent = 0,
    this.newsRead = 0,
    this.videosWatched = 0,
    this.sessionsCount = 0,
    this.savedNews = const [],
    this.profileImagePath = '',
    this.notificationsEnabled = true,
    this.favoriteDriver = '',
    this.favoriteCircuit = '',
  }) : joinDate = joinDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'joinDate': joinDate.toIso8601String(),
      'totalTimeSpent': totalTimeSpent,
      'newsRead': newsRead,
      'videosWatched': videosWatched,
      'sessionsCount': sessionsCount,
      'savedNews': savedNews,
      'profileImagePath': profileImagePath,
      'notificationsEnabled': notificationsEnabled,
      'favoriteDriver': favoriteDriver,
      'favoriteCircuit': favoriteCircuit,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? 'F1 Hayranı',
      email: json['email'] ?? '',
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      newsRead: json['newsRead'] ?? 0,
      videosWatched: json['videosWatched'] ?? 0,
      sessionsCount: json['sessionsCount'] ?? 0,
      savedNews: List<String>.from(json['savedNews'] ?? []),
      profileImagePath: json['profileImagePath'] ?? '',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      favoriteDriver: json['favoriteDriver'] ?? '',
      favoriteCircuit: json['favoriteCircuit'] ?? '',
    );
  }
}

class ProfileService extends ChangeNotifier {
  static const String _profileKey = 'user_profile';
  static const String _sessionStartKey = 'session_start';

  UserProfile _profile = UserProfile();
  DateTime? _sessionStart;

  UserProfile get profile => _profile;

  // Profili yükle
  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);

    if (profileJson != null) {
      final Map<String, dynamic> data = json.decode(profileJson);
      _profile = UserProfile.fromJson(data);
    }

    // Oturum başlangıcını kaydet
    _sessionStart = DateTime.now();
    await prefs.setString(_sessionStartKey, _sessionStart!.toIso8601String());
    _profile.sessionsCount++;

    await _saveProfile();
    notifyListeners();
  }

  // Profili kaydet
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(_profile.toJson()));
  }

  // Profil bilgilerini güncelle
  Future<void> updateProfile({
    String? name,
    String? email,
    String? favoriteDriver,
    String? favoriteCircuit,
    bool? notificationsEnabled,
  }) async {
    if (name != null) _profile.name = name;
    if (email != null) _profile.email = email;
    if (favoriteDriver != null) _profile.favoriteDriver = favoriteDriver;
    if (favoriteCircuit != null) _profile.favoriteCircuit = favoriteCircuit;
    if (notificationsEnabled != null) _profile.notificationsEnabled = notificationsEnabled;

    await _saveProfile();
    notifyListeners();
  }

  // Haber okuma sayısını artır
  Future<void> incrementNewsRead() async {
    _profile.newsRead++;
    await _saveProfile();
    notifyListeners();
  }

  // Video izleme sayısını artır
  Future<void> incrementVideosWatched() async {
    _profile.videosWatched++;
    await _saveProfile();
    notifyListeners();
  }

  // Haberi favorilere ekle/çıkar
  Future<void> toggleSavedNews(String newsId) async {
    if (_profile.savedNews.contains(newsId)) {
      _profile.savedNews.remove(newsId);
    } else {
      _profile.savedNews.add(newsId);
    }
    await _saveProfile();
    notifyListeners();
  }

  // Geçirilen süreyi güncelle
  Future<void> updateTimeSpent() async {
    if (_sessionStart != null) {
      final now = DateTime.now();
      final sessionDuration = now.difference(_sessionStart!).inMinutes;
      _profile.totalTimeSpent += sessionDuration;
      _sessionStart = now;
      await _saveProfile();
    }
  }

  // Oturum sonlandır
  Future<void> endSession() async {
    await updateTimeSpent();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStartKey);
  }

  // İstatistikleri al
  Map<String, dynamic> getStats() {
    final daysSinceJoin = DateTime.now().difference(_profile.joinDate).inDays;
    final avgTimePerDay = daysSinceJoin > 0 ? _profile.totalTimeSpent / daysSinceJoin : 0;

    return {
      'totalTimeSpent': _profile.totalTimeSpent,
      'totalTimeFormatted': _formatDuration(_profile.totalTimeSpent),
      'newsRead': _profile.newsRead,
      'videosWatched': _profile.videosWatched,
      'sessionsCount': _profile.sessionsCount,
      'daysSinceJoin': daysSinceJoin,
      'avgTimePerDay': avgTimePerDay.round(),
      'avgTimePerDayFormatted': _formatDuration(avgTimePerDay.round()),
      'savedNewsCount': _profile.savedNews.length,
    };
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}dk';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours < 24) {
      return remainingMinutes > 0 ? '${hours}s ${remainingMinutes}dk' : '${hours}s';
    }

    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    return remainingHours > 0 ? '${days}g ${remainingHours}s' : '${days}g';
  }

  // Profili sıfırla
  Future<void> resetProfile() async {
    _profile = UserProfile();
    await _saveProfile();
    notifyListeners();
  }
}