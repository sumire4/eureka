import 'package:flutter/cupertino.dart';
import '../../services/standings_service.dart';
import 'car_detail_view.dart';

class ConstructorDetailView extends StatelessWidget {
  final ConstructorStanding constructor;

  const ConstructorDetailView({super.key, required this.constructor});

  Color _getTeamColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mercedes')) return const Color(0xFF00D2BE);
    if (lower.contains('ferrari')) return const Color(0xFFE80020);
    if (lower.contains('mclaren')) return const Color(0xFFFF8000);
    if (lower.contains('red bull')) return const Color(0xFF3671C6);
    if (lower.contains('aston')) return const Color(0xFF229971);
    if (lower.contains('alpine')) return const Color(0xFF0093CC);
    if (lower.contains('williams')) return const Color(0xFF64C4FF);
    if (lower.contains('haas')) return const Color(0xFFB6BABD);
    if (lower.contains('audi') || lower.contains('sauber') || lower.contains('kick')) return const Color(0xFF52E252);
    if (lower.contains('rb') || lower.contains('cash app')) return const Color(0xFF6692FF);
    if (lower.contains('cadillac')) return const Color(0xFFFFD700);
    return const Color(0xFFE10600);
  }

  String _getTeamLogoUrl(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mercedes')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/mercedes-logo.png';
    } else if (lower.contains('ferrari')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/ferrari-logo.png';
    } else if (lower.contains('mclaren')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/mclaren-logo.png';
    } else if (lower.contains('red bull')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/red-bull-racing-logo.png';
    } else if (lower.contains('aston')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/aston-martin-logo.png';
    } else if (lower.contains('alpine')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/alpine-logo.png';
    } else if (lower.contains('williams')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/williams-logo.png';
    } else if (lower.contains('haas')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/haas-f1-team-logo.png';
    } else if (lower.contains('audi') || lower.contains('sauber') || lower.contains('kick')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/kick-sauber-logo.png';
    } else if (lower.contains('rb') || lower.contains('cash app') || lower.contains('alphatauri')) {
      return 'https://media.formula1.com/content/dam/fom-website/teams/2024/rb-logo.png';
    }
    return 'https://media.formula1.com/content/dam/fom-website/teams/2024/f1-logo.png';
  }

  String _getCarModelName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mercedes')) return 'Mercedes-AMG F1 W16';
    if (lower.contains('ferrari')) return 'Ferrari SF-25';
    if (lower.contains('mclaren')) return 'McLaren MCL39';
    if (lower.contains('red bull')) return 'Red Bull Racing RB21';
    if (lower.contains('aston')) return 'Aston Martin AMR25';
    if (lower.contains('alpine')) return 'Alpine A525';
    if (lower.contains('williams')) return 'Williams FW47';
    if (lower.contains('haas')) return 'Haas VF-25';
    if (lower.contains('audi') || lower.contains('sauber')) return 'Audi R26';
    if (lower.contains('rb') || lower.contains('cash app')) return 'VCARB 02';
    if (lower.contains('cadillac')) return 'Cadillac F1-01';
    return 'F1 2026 Hibrit';
  }

  String _getTeamCarImageUrl(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mercedes')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/mercedes.png';
    } else if (lower.contains('red bull')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/red-bull-racing.png';
    } else if (lower.contains('mclaren')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/mclaren.png';
    } else if (lower.contains('ferrari')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/ferrari.png';
    } else if (lower.contains('aston')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/aston-martin.png';
    } else if (lower.contains('alpine')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/alpine.png';
    } else if (lower.contains('williams')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/williams.png';
    } else if (lower.contains('haas')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/haas-f1-team.png';
    } else if (lower.contains('rb') || lower.contains('cash app')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/rb.png';
    }
    return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/kick-sauber.png';
  }

  Map<String, String> _getTeamProfile(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mercedes')) {
      return {
        'Üs (Merkez)': 'Brackley, Birleşik Krallık',
        'Takım Patronu': 'Toto Wolff',
        'Teknik Lider': 'James Allison',
        'Güç Ünitesi': 'Mercedes-AMG M15 E Performance',
        'Pilot 1': 'George Russell (#63)',
        'Pilot 2': 'Andrea Kimi Antonelli (#12)',
        'İlk Katılım': '1954 (Fransa GP)',
      };
    } else if (lower.contains('ferrari')) {
      return {
        'Üs (Merkez)': 'Maranello, İtalya',
        'Takım Patronu': 'Frédéric Vasseur',
        'Teknik Lider': 'Loïc Serra',
        'Güç Ünitesi': 'Ferrari 066/12',
        'Pilot 1': 'Charles Leclerc (#16)',
        'Pilot 2': 'Lewis Hamilton (#44)',
        'İlk Katılım': '1950 (Monako GP)',
      };
    } else if (lower.contains('mclaren')) {
      return {
        'Üs (Merkez)': 'Woking, Birleşik Krallık',
        'Takım Patronu': 'Andrea Stella',
        'Teknik Lider': 'Rob Marshall',
        'Güç Ünitesi': 'Mercedes-AMG M15 E Performance',
        'Pilot 1': 'Lando Norris (#4)',
        'Pilot 2': 'Oscar Piastri (#81)',
        'İlk Katılım': '1966 (Monako GP)',
      };
    } else if (lower.contains('red bull')) {
      return {
        'Üs (Merkez)': 'Milton Keynes, Birleşik Krallık',
        'Takım Patronu': 'Christian Horner',
        'Teknik Lider': 'Pierre Waché',
        'Güç Ünitesi': 'Honda RBPTH002',
        'Pilot 1': 'Max Verstappen (#1)',
        'Pilot 2': 'Isack Hadjar (#6)',
        'İlk Katılım': '2005 (Avustralya GP)',
      };
    }
    return {
      'Üs (Merkez)': 'Avrupa F1 Operasyon Merkezi',
      'Takım Patronu': 'Takım Yönetimi',
      'Teknik Lider': 'Teknik Departman',
      'Güç Ünitesi': '1.6L V6 Turbo Hibrit',
      'Pilot 1': '1. Sürücü',
      'Pilot 2': '2. Sürücü',
      'İlk Katılım': 'FIA Formula 1 Şampiyonası',
    };
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = _getTeamColor(constructor.name);
    final carModelName = _getCarModelName(constructor.name);
    final carImageUrl = _getTeamCarImageUrl(constructor.name);
    final profile = _getTeamProfile(constructor.name);
    final teamLogoUrl = _getTeamLogoUrl(constructor.name);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(constructor.name),
        previousPageTitle: 'Sıralamalar',
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 16),

            // 1. Üst Takım Kimlik Kartı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: teamColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        teamLogoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          CupertinoIcons.flag_fill,
                          color: teamColor,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            constructor.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile['Üs (Merkez)'] ?? 'F1 Takımı',
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Şampiyona Metrik Kartları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: 'ŞAMPİYONA',
                      value: '${constructor.position}. Sıra',
                      color: constructor.position == '1' ? const Color(0xFFE10600) : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: 'TOPLAM PUAN',
                      value: '${constructor.points} PTS',
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: 'GALİBİYET',
                      value: constructor.wins,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Tıklanabilir Yarış Otomobili Kartı (Telemetriye Geçiş)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CarDetailView(
                        carModel: carModelName,
                        teamName: constructor.name,
                        teamColor: teamColor,
                        driverNumber: '1',
                        carImageUrl: carImageUrl,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: teamColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YARIŞ OTOMOBİLİ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.secondaryLabel,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  carModelName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: CupertinoColors.label.resolveFrom(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Telemetri',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: teamColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_forward,
                                size: 14,
                                color: teamColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Image.network(
                          carImageUrl,
                          height: 95,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            CupertinoIcons.car_detailed,
                            size: 48,
                            color: CupertinoColors.systemGrey3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Takım ve Organizasyon Bilgileri Listesi
            CupertinoListSection.insetGrouped(
              header: const Text(
                'TAKIM & YÖNETİM BİLGİLERİ',
                style: TextStyle(letterSpacing: 0.3),
              ),
              children: profile.entries.map((e) {
                return CupertinoListTile(
                  title: Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Text(
                      e.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.secondaryLabel,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}