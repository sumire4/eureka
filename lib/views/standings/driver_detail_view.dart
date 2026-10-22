import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../services/standings_service.dart';
import 'car_detail_view.dart';

class DriverDetailView extends StatefulWidget {
  final DriverStanding driver;

  const DriverDetailView({super.key, required this.driver});

  @override
  State<DriverDetailView> createState() => _DriverDetailViewState();
}

class _DriverDetailViewState extends State<DriverDetailView> {
  bool _isLoading = true;
  Map<String, dynamic>? _openF1Data;

  @override
  void initState() {
    super.initState();
    _fetchDriverDetails();
  }

  Future<void> _fetchDriverDetails() async {
    try {
      String url = 'https://api.openf1.org/v1/drivers?driver_number=${widget.driver.driverNumber}';
      if (widget.driver.driverNumber.isEmpty) {
        url = 'https://api.openf1.org/v1/drivers?name_acronym=${widget.driver.code}';
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        if (list.isNotEmpty) {
          setState(() {
            _openF1Data = list.last;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _parseTeamColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFFE10600);
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFFE10600);
    }
  }

  String _getCountryIso2(String code) {
    const Map<String, String> countryMap = {
      'ITA': 'it',
      'NED': 'nl',
      'GBR': 'gb',
      'MON': 'mc',
      'ESP': 'es',
      'AUS': 'au',
      'MEX': 'mx',
      'GER': 'de',
      'JPN': 'jp',
      'FRA': 'fr',
      'CAN': 'ca',
      'ARG': 'ar',
      'CHN': 'cn',
      'DEN': 'dk',
      'FIN': 'fi',
      'USA': 'us',
      'BRA': 'br',
      'THA': 'th',
      'NZL': 'nz',
    };
    return countryMap[code.toUpperCase()] ?? 'it';
  }

  String _getCountryName(String code) {
    const Map<String, String> names = {
      'ITA': 'İtalya',
      'NED': 'Hollanda',
      'GBR': 'Birleşik Krallık',
      'MON': 'Monako',
      'ESP': 'İspanya',
      'AUS': 'Avustralya',
      'MEX': 'Meksika',
      'GER': 'Almanya',
      'JPN': 'Japonya',
      'FRA': 'Fransa',
      'CAN': 'Kanada',
      'ARG': 'Arjantin',
      'CHN': 'Çin',
      'DEN': 'Danimarka',
      'FIN': 'Finlandiya',
      'USA': 'Amerika Birleşik Devletleri',
      'BRA': 'Brezilya',
      'THA': 'Tayland',
      'NZL': 'Yeni Zelanda',
    };
    return names[code.toUpperCase()] ?? 'Bilinmiyor';
  }

  // Takıma göre gerçek araç model adı (W16, RB21, SF-25 vb.)
  String _getCarModelName(String constructorName) {
    final lower = constructorName.toLowerCase();
    if (lower.contains('mercedes')) return 'Mercedes-AMG F1 W16';
    if (lower.contains('red bull')) return 'Red Bull Racing RB21';
    if (lower.contains('ferrari')) return 'Ferrari SF-25';
    if (lower.contains('mclaren')) return 'McLaren MCL39';
    if (lower.contains('aston')) return 'Aston Martin AMR25';
    if (lower.contains('alpine')) return 'Alpine A525';
    if (lower.contains('williams')) return 'Williams FW47';
    if (lower.contains('haas')) return 'Haas VF-25';
    if (lower.contains('rb') || lower.contains('cash app')) return 'VCARB 02';
    if (lower.contains('sauber') || lower.contains('kick')) return 'Kick Sauber C45';
    return 'F1 2026 Hibrit';
  }

  String _getTeamCarImageUrl(String constructorName) {
    final lower = constructorName.toLowerCase();
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
    } else if (lower.contains('rb') || lower.contains('cash app') || lower.contains('alphatauri')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/rb.png';
    } else if (lower.contains('sauber') || lower.contains('kick')) {
      return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/kick-sauber.png';
    }
    return 'https://media.formula1.com/d_team_car_fallback_image.png/content/dam/fom-website/teams/2024/car.png';
  }

  @override
  Widget build(BuildContext context) {
    final teamHex = _openF1Data?['team_colour']?.toString();
    final teamColor = _parseTeamColor(teamHex);

    String rawCountry = _openF1Data?['country_code']?.toString() ?? '';
    if (rawCountry.isEmpty && widget.driver.fullName.toLowerCase().contains('antonelli')) {
      rawCountry = 'ITA';
    } else if (rawCountry.isEmpty) {
      rawCountry = 'ITA';
    }

    final countryIso = _getCountryIso2(rawCountry);
    final countryName = _getCountryName(rawCountry);
    final acronym = _openF1Data?['name_acronym']?.toString() ?? widget.driver.code;
    final photoUrl = widget.driver.headshotUrl ?? _openF1Data?['headshot_url']?.toString();
    final driverNumber = widget.driver.driverNumber.isNotEmpty
        ? widget.driver.driverNumber
        : (_openF1Data?['driver_number']?.toString() ?? '12');
    final carImageUrl = _getTeamCarImageUrl(widget.driver.constructorName);
    final carModelName = _getCarModelName(widget.driver.constructorName);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.driver.fullName),
        previousPageTitle: 'Sıralamalar',
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 16),

            // 1. Üst Profil Kartı: Sola Yaslı Avatar + Sağa Yaslı Pilot & Ülke Bilgisi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: teamColor, width: 3),
                            color: CupertinoColors.systemGrey6,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              CupertinoIcons.person_fill,
                              size: 48,
                              color: CupertinoColors.systemGrey3,
                            ),
                          )
                              : const Icon(
                            CupertinoIcons.person_fill,
                            size: 48,
                            color: CupertinoColors.systemGrey3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: teamColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Text(
                            '#$driverNumber',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.driver.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (acronym.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    acronym,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.driver.constructorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: teamColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.network(
                                    'https://flagcdn.com/w40/$countryIso.png',
                                    width: 22,
                                    height: 15,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      CupertinoIcons.flag_fill,
                                      size: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  countryName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ],
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

            // 2. Sezon İstatistikleri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ŞAMPİYONA',
                      value: '${widget.driver.position}. Sıra',
                      color: widget.driver.position == '1'
                          ? const Color(0xFFE10600)
                          : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'TOPLAM PUAN',
                      value: '${widget.driver.points} PTS',
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'GALİBİYET',
                      value: widget.driver.wins,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Tıklanabilir Yarış Otomobili Kartı (Model Adı + Detay Sayfası Yönlendirmesi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CarDetailView(
                        carModel: carModelName,
                        teamName: widget.driver.constructorName,
                        teamColor: teamColor,
                        driverNumber: driverNumber,
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
                          Column(
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
                              ),
                            ],
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
                          errorBuilder: (_, _, _) => Container(
                            height: 95,
                            alignment: Alignment.center,
                            child: const Icon(
                              CupertinoIcons.car_detailed,
                              size: 48,
                              color: CupertinoColors.systemGrey3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Detaylı Bilgi Listesi
            CupertinoListSection.insetGrouped(
              header: const Text(
                'PİLOT & ARAÇ BİLGİLERİ',
                style: TextStyle(letterSpacing: 0.3),
              ),
              children: [
                CupertinoListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      'https://flagcdn.com/w40/$countryIso.png',
                      width: 22,
                      height: 15,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text('Ülke / Milliyet'),
                  trailing: Text(
                    '$countryName ($rawCountry)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.number, color: CupertinoColors.systemGrey),
                  title: const Text('Kalıcı Araç Numarası'),
                  trailing: Text(
                    '#$driverNumber',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.tag, color: CupertinoColors.systemGrey),
                  title: const Text('Yayın Kısaltması (Acronym)'),
                  trailing: Text(
                    acronym,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.circle_grid_hex, color: CupertinoColors.systemGrey),
                  title: const Text('Takım Rengi'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: CupertinoColors.systemGrey4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        teamHex != null ? '#$teamHex' : '-',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required Color color}) {
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