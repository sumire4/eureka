import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// F1 Takımları
enum F1Team {
  ferrari,
  mercedes,
  redBull,
  mclaren,
  astonMartin,
  alpine,
  williams,
  rbVcarb,
  haas,
  sauber,
}

// Takım renkleri - sadece görsel amaçlı
class F1TeamColors {
  static const Map<F1Team, Color> primaryColors = {
    F1Team.ferrari: Color(0xFFDC143C),        // Ferrari Kırmızısı
    F1Team.mercedes: Color(0xFF00D2BE),       // Mercedes Turkuaz
    F1Team.redBull: Color(0xFF0600EF),        // Red Bull Lacivert
    F1Team.mclaren: Color(0xFFFF8700),        // McLaren Turuncu
    F1Team.astonMartin: Color(0xFF006F62),    // Aston Martin Yeşil
    F1Team.alpine: Color(0xFF0090CE),         // Alpine Mavi
    F1Team.williams: Color(0xFF005AFF),       // Williams Mavi
    F1Team.rbVcarb: Color(0xFF6692FF),        // RB Açık Mavi
    F1Team.haas: Color(0xFFFFFFFF),           // Haas Beyaz
    F1Team.sauber: Color(0xFF52E252),         // Sauber Yeşil
  };

  static const Map<F1Team, String> teamNames = {
    F1Team.ferrari: 'Scuderia Ferrari',
    F1Team.mercedes: 'Mercedes-AMG F1',
    F1Team.redBull: 'Red Bull Racing',
    F1Team.mclaren: 'McLaren F1',
    F1Team.astonMartin: 'Aston Martin F1',
    F1Team.alpine: 'Alpine F1',
    F1Team.williams: 'Williams Racing',
    F1Team.rbVcarb: 'RB VCARB',
    F1Team.haas: 'MoneyGram Haas F1',
    F1Team.sauber: 'Stake F1 Kick Sauber',
  };
}

class UserProfile {
  String name;
  String email;
  F1Team favoriteTeam;
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
    this.favoriteTeam = F1Team.ferrari,
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
      'favoriteTeam': favoriteTeam.index,
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
      favoriteTeam: F1Team.values[json['favoriteTeam'] ?? 0],
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
    F1Team? favoriteTeam,
    String? favoriteDriver,
    String? favoriteCircuit,
    bool? notificationsEnabled,
    String? profileImagePath,
  }) async {
    if (name != null) _profile.name = name;
    if (favoriteTeam != null) _profile.favoriteTeam = favoriteTeam;
    if (favoriteDriver != null) _profile.favoriteDriver = favoriteDriver;
    if (favoriteCircuit != null) _profile.favoriteCircuit = favoriteCircuit;
    if (notificationsEnabled != null) _profile.notificationsEnabled = notificationsEnabled;
    if (profileImagePath != null) _profile.profileImagePath = profileImagePath;

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

// Takım seçim widget'ı
class TeamSelectionWidget extends StatelessWidget {
  final ProfileService profileService;

  const TeamSelectionWidget({
    super.key,
    required this.profileService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Favori F1 Takımınız',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Favori takımınızı seçin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: F1Team.values.map((team) {
                final isSelected = profileService.profile.favoriteTeam == team;
                return InkWell(
                  onTap: () => profileService.updateProfile(favoriteTeam: team),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? F1TeamColors.primaryColors[team]!.withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: F1TeamColors.primaryColors[team]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: F1TeamColors.primaryColors[team],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          F1TeamColors.teamNames[team]!,
                          style: TextStyle(
                            color: isSelected
                                ? F1TeamColors.primaryColors[team]
                                : null,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: F1TeamColors.primaryColors[team],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}