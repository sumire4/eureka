import 'package:flutter/cupertino.dart';
import '../../services/dashboard_service.dart';

class RaceDetailView extends StatelessWidget {
  final NextRaceInfo race;

  const RaceDetailView({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    final flagUrl = DashboardService.getCountryFlagUrl(race.countryName);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          race.meetingName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        previousPageTitle: 'Geri',
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. ÜST KART: En Üstte Kalan Süre, Altında Bayrak Fotoğrafı ve Ülke/Yarış Başlığı
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN ÜSTTE KALAN SÜRE BİLGİSİ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            CupertinoIcons.timer,
                            size: 14,
                            color: Color(0xFFE10600),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'YARIŞA KALAN SÜRE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE10600).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          race.countdownText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE10600),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // KALAN SÜRENİN ALTINDA GERÇEK BAYRAK FOTOĞRAFI & ÜLKE DETAYLARI
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gerçek Ülke Bayrağı Fotoğrafı (Border & Yuvarlatılmış Köşeler)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CupertinoColors.systemGrey4.resolveFrom(context),
                              width: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            flagUrl,
                            width: 54,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 54,
                              height: 36,
                              color: CupertinoColors.systemGrey5,
                              child: const Icon(
                                CupertinoIcons.flag_fill,
                                size: 18,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Ülke İsmi ve Yarış Başlıkları
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              race.countryName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE10600),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              race.meetingName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              race.circuitName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.secondaryLabel,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. KUŞBAKIŞI PİST KROKİSİ KARTI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.map, size: 16, color: CupertinoColors.secondaryLabel),
                      SizedBox(width: 6),
                      Text(
                        'PİST DÜZENİ VE KUŞBAKIŞI HARİTA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.secondaryLabel,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      padding: const EdgeInsets.all(12),
                      child: Image.network(
                        race.circuitImageUrl,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          alignment: Alignment.center,
                          child: const Icon(
                            CupertinoIcons.map_pin_ellipse,
                            size: 48,
                            color: CupertinoColors.systemGrey3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. PİST TEKNİK GÖSTERGELERİ (Grid)
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    context,
                    label: 'PİST UZUNLUĞU',
                    val: race.circuitLength,
                    icon: CupertinoIcons.arrow_left_right,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    context,
                    label: 'TUR SAYISI',
                    val: '${race.totalLaps} Tur',
                    icon: CupertinoIcons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    context,
                    label: 'DRS BÖLGESİ',
                    val: '${race.drsZones} Bölge',
                    icon: CupertinoIcons.wind,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    context,
                    label: 'TUR REKORU',
                    val: race.lapRecord,
                    subtitle: race.lapRecordHolder,
                    icon: CupertinoIcons.stopwatch,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. HAFTA SONU SEANS TAKVİMİ
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              header: const Text(
                'HAFTA SONU SEANS PROGRAMI',
                style: TextStyle(letterSpacing: 0.3),
              ),
              children: const [
                CupertinoListTile(
                  title: Text('1. Antrenman (FP1)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: Text('Cuma 21:30', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                ),
                CupertinoListTile(
                  title: Text('2. Antrenman (FP2)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: Text('Cumartesi 01:00', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                ),
                CupertinoListTile(
                  title: Text('Sıralama Turları', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: Text('Cumartesi 00:00', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                ),
                CupertinoListTile(
                  title: Text('Büyük Yarış (Grand Prix)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE10600))),
                  trailing: Text('Pazar 23:00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
      BuildContext context, {
        required String label,
        required String val,
        required IconData icon,
        String? subtitle,
      }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: CupertinoColors.secondaryLabel),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.secondaryLabel,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.tertiaryLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}