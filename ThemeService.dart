import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Takım renkleri
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

  static const Map<F1Team, Color> secondaryColors = {
    F1Team.ferrari: Color(0xFFFFFF00),        // Sarı
    F1Team.mercedes: Color(0xFF000000),       // Siyah
    F1Team.redBull: Color(0xFFFFB800),        // Altın
    F1Team.mclaren: Color(0xFF47C7FC),        // Açık Mavi
    F1Team.astonMartin: Color(0xFFCEDB20),    // Lime
    F1Team.alpine: Color(0xFFFF87BC),         // Pembe
    F1Team.williams: Color(0xFFFFFFFF),       // Beyaz
    F1Team.rbVcarb: Color(0xFF1E41FF),        // Koyu Mavi
    F1Team.haas: Color(0xFFEC0B0B),           // Kırmızı
    F1Team.sauber: Color(0xFF000000),         // Siyah
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

class ThemeService extends ChangeNotifier {
  static const String _teamKey = 'selected_f1_team';
  F1Team _selectedTeam = F1Team.ferrari; // Varsayılan

  F1Team get selectedTeam => _selectedTeam;

  // Seçili takımın tema rengini al
  Color get primaryColor => F1TeamColors.primaryColors[_selectedTeam]!;
  Color get secondaryColor => F1TeamColors.secondaryColors[_selectedTeam]!;
  String get teamName => F1TeamColors.teamNames[_selectedTeam]!;

  // SharedPreferences'dan takım seçimini yükle
  Future<void> loadSelectedTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final teamIndex = prefs.getInt(_teamKey) ?? 0;
    _selectedTeam = F1Team.values[teamIndex];
    notifyListeners();
  }

  // Takım seçimini kaydet
  Future<void> setSelectedTeam(F1Team team) async {
    _selectedTeam = team;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_teamKey, team.index);
    notifyListeners();
  }

  // Material 3 teması oluştur
  ThemeData createTheme({required bool isDark}) {
    final ColorScheme colorScheme = isDark
        ? ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    )
        : ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withOpacity(0.3),
        selectionHandleColor: primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: primaryColor),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
    );
  }
}

// Takım seçim widget'ı
class TeamSelectionWidget extends StatelessWidget {
  final ThemeService themeService;

  const TeamSelectionWidget({
    super.key,
    required this.themeService,
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
              'Seçtiğiniz takıma göre uygulama renkleri değişecek',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: F1Team.values.map((team) {
                final isSelected = themeService.selectedTeam == team;
                return InkWell(
                  onTap: () => themeService.setSelectedTeam(team),
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