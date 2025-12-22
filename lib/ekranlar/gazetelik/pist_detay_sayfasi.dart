import 'dart:async';
import 'package:donemprojesi/ekranlar/brief/brief_ekrani.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class PistDetaySayfasi extends StatefulWidget {
  final Map<String, dynamic> yaris;

  const PistDetaySayfasi({super.key, required this.yaris});

  @override
  State<PistDetaySayfasi> createState() => _PistDetaySayfasiState();
}

class _PistDetaySayfasiState extends State<PistDetaySayfasi> {
  bool _favori = false;
  late Timer _timer;
  Duration _kalanSure = Duration.zero;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


  @override
  void initState() {
    super.initState();
    _baslatGeriSayim();
  }

  void _baslatGeriSayim() {
    final DateTime? hedefTarih = DateTime.tryParse(widget.yaris['race_date'] ?? '');
    if (hedefTarih != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        setState(() {
          _kalanSure = hedefTarih.difference(now).isNegative
              ? Duration.zero
              : hedefTarih.difference(now);
        });
      });
    }
  }

  String _sureFormatla(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '$days Gün $hours Saat $minutes Dakika $seconds Saniye';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _favoriToggle() {
    setState(() => _favori = !_favori);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_favori ? "Favorilere eklendi" : "Favorilerden çıkarıldı")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yaris = widget.yaris;
    final bool haritaMevcut = yaris['latitude'] != null && yaris['longitude'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(yaris['name'] ?? "Yarış Detayı"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: yaris['kusbakisiAsset'] != null
                  ? Image.asset(
                yaris['kusbakisiAsset'],
                height: 200,
                fit: BoxFit.contain,
              )
                  : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: yaris['flagUrl'] != null
                        ? Image.network(
                      yaris['flagUrl'],
                      width: 48,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.flag_outlined, size: 32),
                    )
                        : const Icon(Icons.flag_outlined, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yaris['name'] ?? "Bilinmeyen Pist",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        yaris['country'] ?? "Bilinmeyen Ülke",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Yarışa Kalan Süre:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _sureFormatla(_kalanSure),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // Detay Kartı (wrap içinde)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  children: [
                    _detayItem(Icons.route, "Uzunluk", yaris['length']),
                    _detayItem(Icons.roundabout_right, "Viraj", yaris['turns']),
                    _detayItem(Icons.flag_circle, "Tur Rekoru", yaris['lap_record']),
                    _detayItem(Icons.speed, "DRS Bölgesi", yaris['drs_zones']),
                    _detayItem(Icons.calendar_today, "İlk GP", yaris['first_gp']),
                    _detayItem(Icons.repeat_on, "Tur Sayısı", yaris['laps']),
                    _detayItem(Icons.timeline, "Toplam Mesafe", yaris['race_distance']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

// Teknik Analiz Kartı
            if (yaris.containsKey('technical_analysis')) ...[
              const SizedBox(height: 24),
              Text(
                "Sürüş Rehberi",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _analizSatiri("Geçiş Fırsatları", yaris['technical_analysis']?['passing_opportunities']),
                      _analizSatiri("Lastik Aşınması", yaris['technical_analysis']?['tire_wear']),
                      _analizSatiri("Hava Koşulu Etkisi", yaris['technical_analysis']?['weather_advantage']),
                      _analizSatiri("Ek Bilgi", yaris['technical_analysis']?['trivia']),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BriefEkrani(onScroll: (bool scrollingDown) {  },)),
                );
              },
              icon: const Icon(Icons.smart_toy, color: Color(0xFF006400)),
              label: const Text(
                "F1tr'ye ilerle",
                style: TextStyle(
                  color: Color(0xFF006400),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA8E6CF),
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 130.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detayItem(IconData icon, String baslik, String? bilgi) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bilgi ?? "-",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _analizSatiri(String baslik, String? aciklama) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            aciklama ?? "-",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
