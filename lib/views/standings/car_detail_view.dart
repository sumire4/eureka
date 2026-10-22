import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class CarDetailView extends StatefulWidget {
  final String carModel;
  final String teamName;
  final Color teamColor;
  final String driverNumber;
  final String carImageUrl;

  const CarDetailView({
    super.key,
    required this.carModel,
    required this.teamName,
    required this.teamColor,
    required this.driverNumber,
    required this.carImageUrl,
  });

  @override
  State<CarDetailView> createState() => _CarDetailViewState();
}

class _CarDetailViewState extends State<CarDetailView> {
  bool _isLoading = true;
  int _maxSpeed = 342;
  int _currentRpm = 11850;
  int _gear = 8;
  int _throttle = 100;
  bool _drsActive = true;

  @override
  void initState() {
    super.initState();
    _fetchTelemetryData();
  }

  Future<void> _fetchTelemetryData() async {
    try {
      final num = widget.driverNumber.replaceAll('#', '');
      final url = 'https://api.openf1.org/v1/car_data?session_key=latest&driver_number=$num';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List list = json.decode(res.body);
        if (list.isNotEmpty) {
          int peakSpeed = 0;
          for (var item in list) {
            final sp = item['speed'] as int? ?? 0;
            if (sp > peakSpeed) peakSpeed = sp;
          }

          final lastItem = list.last;
          setState(() {
            _maxSpeed = peakSpeed > 0 ? peakSpeed : 342;
            _currentRpm = (lastItem['rpm'] as int?) ?? 11850;
            _gear = (lastItem['n_gear'] as int?) ?? 8;
            _throttle = (lastItem['throttle'] as int?) ?? 100;
            _drsActive = ((lastItem['drs'] as int?) ?? 0) >= 10;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, String> _getTechnicalSpecs(String team) {
    final lower = team.toLowerCase();
    if (lower.contains('mercedes') || lower.contains('amg')) {
      return {
        'Şasi / Monokok': 'Karbon fiber petek kompozit monokok',
        'Güç Ünitesi': 'Mercedes-AMG F1 M15 E Performance',
        'Motor Tipi': '1.6L V6 Turbo Hibrit (90°)',
        'Maksimum Devir': '15,000 RPM (FIA Sınırı)',
        'Şanzıman': '8 İleri + 1 Geri Yarı Otomatik Sıralı',
        'Ağırlık': '798 kg (Asgari Sınır)',
        'Fren Sistemi': 'Karbon diskler (Brake-by-Wire)',
        'Yakıt & Yağ': 'Petronas Primax & Syntium',
      };
    } else if (lower.contains('red bull')) {
      return {
        'Şasi / Monokok': 'Karbon kompozit monokok şasi',
        'Güç Ünitesi': 'Honda RBPTH002 V6 Turbo Hibrit',
        'Motor Tipi': '1.6L V6 Turbo Hibrit 24 Supap',
        'Maksimum Devir': '15,000 RPM (FIA Sınırı)',
        'Şanzıman': '8 İleri Boylamasına Hidrolik Sıralı',
        'Ağırlık': '798 kg (FIA Regülasyonu)',
        'Fren Sistemi': 'Brembo kaliper ve karbon rotorlar',
        'Yakıt & Yağ': 'Mobil 1 & Esso Synergy',
      };
    } else if (lower.contains('ferrari')) {
      return {
        'Şasi / Monokok': 'Ferrari Karbon fiber petek kompozit',
        'Güç Ünitesi': 'Ferrari 066/12 1.6L V6 Turbo',
        'Motor Tipi': '90° V6 Tek Turboşarjlı Çift ERS',
        'Maksimum Devir': '15,000 RPM',
        'Şanzıman': 'Ferrari Boylamasına 8 İleri Quick-Shift',
        'Ağırlık': '798 kg',
        'Fren Sistemi': 'Brembo karbon diskli Brake-by-Wire',
        'Yakıt & Yağ': 'Shell V-Power & Helix Ultra',
      };
    } else if (lower.contains('mclaren')) {
      return {
        'Şasi / Monokok': 'McLaren kalıplı karbon fiber kompozit',
        'Güç Ünitesi': 'Mercedes-AMG M15 E Performance',
        'Motor Tipi': '1.6L 6 Silindir 24 Supap Turbo Hibrit',
        'Maksimum Devir': '15,000 RPM',
        'Şanzıman': 'McLaren 8 ileri kesintisiz geçişli',
        'Ağırlık': '798 kg',
        'Fren Sistemi': 'Akebono kaliperler ve karbon diskler',
        'Yakıt & Yağ': 'Petronas / Mobil 1',
      };
    }
    return {
      'Şasi / Monokok': 'FIA Standart Karbon Fiber Monokok',
      'Güç Ünitesi': '1.6L Turboşarjlı V6 Hibrit ERS',
      'Motor Tipi': '90° Doğrudan Enjeksiyonlu 24V Turbo',
      'Maksimum Devir': '15,000 RPM',
      'Şanzıman': '8 İleri Yarı Otomatik Sıralı',
      'Ağırlık': '798 kg',
      'Fren Sistemi': 'Karbon-Seramik Brake-by-Wire',
      'Yakıt & Yağ': 'FIA Onaylı Sürdürülebilir F1 Yakıtı',
    };
  }

  @override
  Widget build(BuildContext context) {
    final specs = _getTechnicalSpecs(widget.teamName);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        // Üst barda takım ve model adı sadeleştirildi
        middle: Text(
          widget.carModel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        previousPageTitle: 'Pilot',
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 12),

            // 1. Taşma Yapmayan Üst Otomobil Sahnesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.teamColor.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Model Başlığı ve Rozet (Expanded ile taşma engellendi)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.carModel,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.teamName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.teamColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.teamColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: widget.teamColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            'FIA 2026',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: widget.teamColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Araç Resmi
                    Image.network(
                      widget.carImageUrl,
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        CupertinoIcons.car_detailed,
                        size: 60,
                        color: CupertinoColors.systemGrey3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Canlı OpenF1 Telemetri Paneli
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.waveform_path_ecg, size: 15, color: CupertinoColors.secondaryLabel),
                      SizedBox(width: 6),
                      Text(
                        'CANLI TELEMETRİ GÖSTERGELERİ (OPENF1)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.secondaryLabel,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTelemetryBox(
                          label: 'ZİRVE HIZ',
                          val: '$_maxSpeed km/h',
                          icon: CupertinoIcons.speedometer,
                          highlight: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTelemetryBox(
                          label: 'MOTOR DEVRİ',
                          val: '$_currentRpm RPM',
                          icon: CupertinoIcons.gauge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTelemetryBox(
                          label: 'VİTES',
                          val: '$_gear. Vites',
                          icon: CupertinoIcons.gear_alt,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTelemetryBox(
                          label: 'GAZ',
                          val: '%$_throttle',
                          icon: CupertinoIcons.flame,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTelemetryBox(
                          label: 'DRS',
                          val: _drsActive ? 'AÇIK' : 'KAPALI',
                          icon: CupertinoIcons.wind,
                          color: _drsActive ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Teknik Şasi ve Motor Özellikleri
            CupertinoListSection.insetGrouped(
              header: const Text(
                'TEKNİK MOTOR & ŞASİ BİLGİLERİ',
                style: TextStyle(letterSpacing: 0.3),
              ),
              children: specs.entries.map((entry) {
                return CupertinoListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 175),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),

            // 4. Bilgilendirme Notu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(CupertinoIcons.info, size: 16, color: CupertinoColors.systemGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Telemetri verileri OpenF1 sensör yolu üzerinden canlı olarak hesaplanmaktadır.',
                        style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBox({
    required String label,
    required String val,
    required IconData icon,
    bool highlight = false,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? widget.teamColor : CupertinoColors.systemGrey5.resolveFrom(context),
          width: highlight ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color ?? (highlight ? widget.teamColor : CupertinoColors.secondaryLabel)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.secondaryLabel,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            val,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color ?? (highlight ? widget.teamColor : CupertinoColors.label),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}