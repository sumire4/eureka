// lib/screens/race_analysis_page.dart
//
// Eureka AI - Cupertino (iOS) tasarımlı yarış analiz sayfası.
// Kullanım: tab'ına `const RaceAnalysisPage()` koyman yeterli.

import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'race_analysis_data.dart';

// ───────────────────────── Stil yardımcıları ─────────────────────────

const _months = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
];
const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

TextStyle _t(BuildContext c, double size,
    {FontWeight w = FontWeight.w400,
      Color? color,
      double? h,
      double? ls}) =>
    TextStyle(
      fontSize: size,
      fontWeight: w,
      color: color ?? CupertinoColors.label.resolveFrom(c),
      height: h,
      letterSpacing: ls,
      decoration: TextDecoration.none,
    );

Color _sec(BuildContext c) => CupertinoColors.secondaryLabel.resolveFrom(c);
Color _sep(BuildContext c) => CupertinoColors.separator.resolveFrom(c);
Color _fill(BuildContext c) => CupertinoColors.tertiarySystemFill.resolveFrom(c);

const _kRed = Color(0xFFE10600);

// ───────────────────────── Sayfa ─────────────────────────

class RaceAnalysisPage extends StatefulWidget {
  const RaceAnalysisPage({super.key});

  @override
  State<RaceAnalysisPage> createState() => _RaceAnalysisPageState();
}

class _RaceAnalysisPageState extends State<RaceAnalysisPage> {
  RaceAnalysisController _c = RaceAnalysisController();

  Future<void> _refresh() async {
    OpenF1.instance.clearCache();
    final fresh = RaceAnalysisController();
    setState(() => _c = fresh);
    try {
      await fresh.calendar;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        physics:
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Eureka AI'),
            automaticallyImplyLeading: false,
            border: null,
          ),
          CupertinoSliverRefreshControl(onRefresh: _refresh),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Hero(c: _c),
                _Async<List<Prediction>>(
                  title: 'Eureka Tahmini',
                  subtitle: 'İstatistiksel model',
                  future: _c.prediction,
                  loadingHeight: 260,
                  builder: (_, d) => _PredictionCard(d),
                ),
                _Async<Commentary>(
                  title: 'Yapay Zeka Yorumu',
                  subtitle: 'Gemini',
                  future: _c.commentary,
                  loadingHeight: 200,
                  empty:
                  'Yorum üretilemedi. .env içindeki GEMINI_API_KEY ve internet bağlantısını kontrol et.',
                  builder: (_, d) => _CommentaryCard(d),
                ),
                _Async<List<SessionInfo>>(
                  title: 'Hafta Sonu Programı',
                  subtitle: 'Yerel saatinle',
                  future: _c.nextSessions,
                  empty: 'Program henüz yayınlanmadı.',
                  builder: (_, d) => _ScheduleCard(d),
                ),
                _Async<Recap>(
                  title: 'Son Yarış',
                  future: _c.recap,
                  loadingHeight: 320,
                  builder: (_, d) => _RecapCard(d),
                ),
                _Async<StintData>(
                  title: 'Lastik Stratejisi',
                  subtitle: 'Son yarış',
                  future: _c.stints,
                  loadingHeight: 260,
                  builder: (_, d) => _StintCard(d),
                ),
                _Async<RaceWeather>(
                  title: 'Pist Koşulları',
                  subtitle: 'Son yarış',
                  future: _c.weather,
                  builder: (_, d) => _WeatherCard(d),
                ),
                _Async<FormTable>(
                  title: 'Son 3 Yarış Formu',
                  future: _c.formTable,
                  builder: (_, d) => _FormCard(d),
                ),
                _Async<Standings>(
                  title: 'Pilotlar Şampiyonası',
                  future: _c.standings,
                  empty: 'Şampiyona verisi bu yarış için henüz mevcut değil.',
                  builder: (_, d) => _StandingsCard(d),
                ),
                _Async<TrackHistory>(
                  title: 'Bu Pistte Geçen Yıl',
                  future: _c.history,
                  empty: 'Bu pist geçen yıl takvimde yoktu.',
                  loadingHeight: 220,
                  builder: (_, d) => _HistoryCard(d),
                ),
                const _Footer(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Temel parçalar ─────────────────────────

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(title,
                style: _t(context, 22, w: FontWeight.w700, ls: -0.4)),
          ),
          if (subtitle != null)
            Text(subtitle!, style: _t(context, 13, color: _sec(context))),
        ],
      ),
    );
  }
}

/// Future'ı dinler; yüklenirken indikatör, hata/boşta mesaj, veri gelince yumuşak geçişle içerik.
class _Async<T> extends StatelessWidget {
  const _Async({
    required this.title,
    required this.future,
    required this.builder,
    this.subtitle,
    this.empty = 'Bu veri şu an mevcut değil.',
    this.loadingHeight = 140,
  });

  final String title;
  final String? subtitle;
  final Future<T?> future;
  final Widget Function(BuildContext, T) builder;
  final String empty;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title, subtitle),
          FutureBuilder<T?>(
            future: future,
            builder: (ctx, snap) {
              Widget child;
              if (snap.connectionState != ConnectionState.done) {
                child = _Card(
                  key: const ValueKey('loading'),
                  child: SizedBox(
                    height: loadingHeight,
                    child: const Center(child: CupertinoActivityIndicator()),
                  ),
                );
              } else if (snap.hasError || snap.data == null) {
                child = _Card(
                  key: const ValueKey('empty'),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.info_circle,
                          color: _sec(ctx), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          snap.hasError
                              ? 'Veri alınamadı. Aşağı çekerek yenileyebilirsin.'
                              : empty,
                          style: _t(ctx, 14, color: _sec(ctx), h: 1.35),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                child = KeyedSubtree(
                  key: const ValueKey('data'),
                  child: builder(ctx, snap.data as T),
                );
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                child: child,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) => Container(
      height: 0.5, margin: EdgeInsets.only(left: indent), color: _sep(context));
}

class _Bar extends StatelessWidget {
  const _Bar(this.value, this.color, {this.height = 6});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: _fill(context),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.d, {this.size = 44});
  final DriverInfo d;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(d.acronym,
          style: _t(context, size * 0.28, w: FontWeight.w700, color: d.color)),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: d.color.withValues(alpha: 0.16),
        border: Border.all(color: d.color, width: 2),
      ),
      child: ClipOval(
        child: d.headshot.isEmpty
            ? initials
            : Image.network(
          d.headshot,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => initials,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: CupertinoColors.white),
          const SizedBox(width: 5),
        ],
        Text(text,
            style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                decoration: TextDecoration.none)),
      ]),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon, this.color, {this.size = 32});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Icon(icon, size: size * 0.58, color: CupertinoColors.white),
  );
}

// ───────────────────────── Hero ─────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.c});
  final RaceAnalysisController c;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Calendar?>(
      future: c.calendar,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _Card(
            child: const SizedBox(
              height: 300,
              child: Center(child: CupertinoActivityIndicator()),
            ),
          );
        }
        final next = snap.data?.next;
        if (snap.hasError || next == null) {
          return _Card(
            child: Text(
              snap.hasError
                  ? 'Takvim alınamadı. Aşağı çekerek yenile.'
                  : 'Yeni sezon takvimi henüz yayınlanmadı.',
              style: _t(ctx, 15, color: _sec(ctx)),
            ),
          );
        }
        return FutureBuilder<List<SessionInfo>?>(
          future: c.nextSessions,
          builder: (_, s) => _HeroCard(meeting: next, sessions: s.data ?? const []),
        );
      },
    );
  }
}

class _Target {
  final DateTime time;
  final String label;
  final bool live;
  const _Target(this.time, this.label, this.live);
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.meeting, required this.sessions});
  final Meeting meeting;
  final List<SessionInfo> sessions;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _Target _target() {
    final now = DateTime.now().toUtc();
    for (final s in widget.sessions) {
      if (s.end.isAfter(now)) {
        final live = !s.start.isAfter(now);
        return _Target(live ? s.end : s.start, sessionNameTr(s.name), live);
      }
    }
    return _Target(widget.meeting.start, 'Hafta sonu', false);
  }

  String _range() {
    final s = widget.meeting.start.toLocal();
    final e = widget.meeting.end.toLocal();
    if (s.month == e.month) return '${s.day}–${e.day} ${_months[s.month - 1]}';
    return '${s.day} ${_months[s.month - 1]} – ${e.day} ${_months[e.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meeting;
    final t = _target();
    var diff = t.time.difference(DateTime.now().toUtc());
    if (diff.isNegative) diff = Duration.zero;
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final mi = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    final live = widget.sessions.isNotEmpty && t.live;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E0E16), Color(0xFF2B0A16), Color(0xFFB3001B)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x40B3001B), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Pill(DateTime.now().toUtc().isAfter(m.start)
                        ? 'BU HAFTA SONU'
                        : 'SIRADAKİ GP',
                        icon: CupertinoIcons.sparkles),
                    _Pill('${flagEmoji(m.countryCode)}  ${_range()}'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(m.name,
                    style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -0.6,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(CupertinoIcons.location_solid,
                      size: 13, color: Color(0xB3FFFFFF)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${m.circuit} · ${m.country}',
                      style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  height: 168,
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: m.circuitImage.isEmpty
                      ? const Icon(CupertinoIcons.flag_fill,
                      color: Color(0xFFBDBDC2), size: 40)
                      : Image.network(
                    m.circuitImage,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const Center(child: CupertinoActivityIndicator()),
                    errorBuilder: (_, _, _) => const Icon(
                        CupertinoIcons.flag_fill,
                        color: Color(0xFFBDBDC2),
                        size: 40),
                  ),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  if (live)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF30D158)),
                    ),
                  Expanded(
                    child: Text(
                      live
                          ? 'CANLI · ${t.label} · bitmesine kalan'
                          : '${t.label} · başlamasına kalan',
                      style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _CountBox(d, 'GÜN'),
                  const SizedBox(width: 8),
                  _CountBox(h, 'SAAT'),
                  const SizedBox(width: 8),
                  _CountBox(mi, 'DK'),
                  const SizedBox(width: 8),
                  _CountBox(s, 'SN'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox(this.value, this.label);
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x26FFFFFF), width: 0.5),
        ),
        child: Column(children: [
          Text(value.toString().padLeft(2, '0'),
              style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  decoration: TextDecoration.none)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  decoration: TextDecoration.none)),
        ]),
      ),
    );
  }
}

// ───────────────────────── Tahmin ─────────────────────────

class _PredictionCard extends StatelessWidget {
  const _PredictionCard(this.items);
  final List<Prediction> items;

  @override
  Widget build(BuildContext context) {
    final lead = items.first;
    final maxProb = lead.prob;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Avatar(lead.driver, size: 66),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('EN YÜKSEK SKOR',
                    style: _t(context, 11,
                        w: FontWeight.w700, color: _kRed, ls: 0.8)),
                const SizedBox(height: 3),
                Text(lead.driver.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(context, 20, w: FontWeight.w700, ls: -0.3)),
                Text(lead.driver.team,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(context, 13, color: _sec(context))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('%${(lead.prob * 100).round()}',
                  style: _t(context, 30,
                      w: FontWeight.w800, color: lead.driver.color, ls: -0.8)),
              Text('model skoru', style: _t(context, 11, color: _sec(context))),
            ]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Meter('Form', lead.form, lead.driver.color)),
            const SizedBox(width: 12),
            Expanded(child: _Meter('Şampiyona', lead.champ, lead.driver.color)),
            const SizedBox(width: 12),
            Expanded(child: _Meter('Pist geçmişi', lead.track, lead.driver.color)),
          ]),
          const SizedBox(height: 16),
          const _Hairline(),
          for (var i = 1; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}',
                      style: _t(context, 15,
                          w: FontWeight.w700, color: _sec(context))),
                ),
                _Avatar(items[i].driver, size: 32),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(items[i].driver.lastName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(context, 14.5, w: FontWeight.w600)),
                    Text(items[i].driver.team,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(context, 11, color: _sec(context))),
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: _Bar(items[i].prob / maxProb, items[i].driver.color,
                        height: 8)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 38,
                  child: Text('%${(items[i].prob * 100).round()}',
                      textAlign: TextAlign.right,
                      style: _t(context, 14, w: FontWeight.w700)),
                ),
              ]),
            ),
            if (i != items.length - 1) const _Hairline(indent: 32),
          ],
          const SizedBox(height: 6),
          Text(
            'Skor; son 3 yarış formu, şampiyona puanı ve bu pistteki geçen yıl sonucundan hesaplanır. Bahis oranı değildir.',
            style: _t(context, 11.5, color: _sec(context), h: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(context, 11.5, color: _sec(context))),
        ),
        Text('${(value * 100).round()}',
            style: _t(context, 11.5, w: FontWeight.w700)),
      ]),
      const SizedBox(height: 5),
      _Bar(value, color, height: 5),
    ]);
  }
}

// ───────────────────────── Gemini yorumu ─────────────────────────

class _CommentaryCard extends StatelessWidget {
  const _CommentaryCard(this.c);
  final Commentary c;

  @override
  Widget build(BuildContext context) {
    final items = <List<dynamic>>[
      [CupertinoIcons.sparkles, CupertinoColors.systemPurple, 'Genel Bakış', c.overview],
      [CupertinoIcons.timer, CupertinoColors.systemOrange, 'Strateji & Lastik', c.strategy],
      [CupertinoIcons.person_2_fill, CupertinoColors.systemBlue, 'İzlenecek Çekişme', c.battle],
      [CupertinoIcons.exclamationmark_triangle_fill, CupertinoColors.systemRed, 'Risk Faktörü', c.risk],
    ].where((e) => (e[3] as String).trim().isNotEmpty).toList();

    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _IconTile(items[i][0] as IconData, items[i][1] as Color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((items[i][2] as String).toUpperCase(),
                      style: _t(context, 11,
                          w: FontWeight.w700, color: _sec(context), ls: 0.6)),
                  const SizedBox(height: 4),
                  Text(items[i][3] as String,
                      style: _t(context, 15, h: 1.38)),
                ]),
              ),
            ]),
          ),
          if (i != items.length - 1) const _Hairline(indent: 44),
        ],
      ]),
    );
  }
}

// ───────────────────────── Program ─────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(this.sessions);
  final List<SessionInfo> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        for (var i = 0; i < sessions.length; i++) ...[
          _SessionRow(sessions[i], now),
          if (i != sessions.length - 1) const _Hairline(indent: 76),
        ],
      ]),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow(this.s, this.now);
  final SessionInfo s;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final st = s.start.toLocal();
    final en = s.end.toLocal();
    final done = s.end.isBefore(now);
    final live = !s.start.isAfter(now) && !done;
    final isRace = s.name == 'Race';
    final accent = isRace ? _kRed : CupertinoColors.label.resolveFrom(context);

    return Container(
      color: isRace ? _kRed.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Column(children: [
            Text(_days[st.weekday - 1].toUpperCase(),
                style: _t(context, 10.5,
                    w: FontWeight.w700, color: isRace ? _kRed : _sec(context), ls: 0.6)),
            Text('${st.day}',
                style: _t(context, 22, w: FontWeight.w700, color: accent)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sessionNameTr(s.name),
                style: _t(context, 16,
                    w: isRace ? FontWeight.w700 : FontWeight.w600,
                    color: done ? _sec(context) : null)),
            const SizedBox(height: 2),
            Text('${_hm(st)} – ${_hm(en)}',
                style: _t(context, 13, color: _sec(context))),
          ]),
        ),
        if (live)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _kRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('CANLI',
                style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    decoration: TextDecoration.none)),
          )
        else if (done)
          const Icon(CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.systemGreen, size: 22)
        else
          Icon(isRace ? CupertinoIcons.flag_fill : CupertinoIcons.clock,
              color: isRace ? _kRed : _sec(context), size: 20),
      ]),
    );
  }
}

// ───────────────────────── Son yarış ─────────────────────────

class _RecapCard extends StatelessWidget {
  const _RecapCard(this.r);
  final Recap r;

  @override
  Widget build(BuildContext context) {
    final classified = r.results.where((x) => x.position != null).toList();
    final podium = classified.take(3).toList();
    final rest = classified.skip(3).take(7).toList();
    final outCount = r.results.where((x) => x.out).length;
    final date = r.race.start.toLocal();

    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(flagEmoji(r.meeting.countryCode),
              style: const TextStyle(fontSize: 22, decoration: TextDecoration.none)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.meeting.name,
                  style: _t(context, 17, w: FontWeight.w700, ls: -0.2)),
              Text(
                  '${_days[date.weekday - 1]} ${date.day} ${_months[date.month - 1]} · ${classified.isEmpty ? 0 : classified.first.laps} tur',
                  style: _t(context, 12.5, color: _sec(context))),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        if (podium.length == 3)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: _PodiumColumn(podium[1], r, 2, 74)),
            const SizedBox(width: 8),
            Expanded(child: _PodiumColumn(podium[0], r, 1, 104)),
            const SizedBox(width: 8),
            Expanded(child: _PodiumColumn(podium[2], r, 3, 56)),
          ]),
        const SizedBox(height: 14),
        for (var i = 0; i < rest.length; i++) ...[
          _ResultRowTile(rest[i], r),
          if (i != rest.length - 1) const _Hairline(indent: 34),
        ],
        if (outCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 16, color: CupertinoColors.systemOrange),
              const SizedBox(width: 8),
              Text('$outCount pilot yarışı tamamlayamadı',
                  style: _t(context, 13, color: _sec(context))),
            ]),
          ),
      ]),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn(this.row, this.r, this.rank, this.height);
  final ResultRow row;
  final Recap r;
  final int rank;
  final double height;

  @override
  Widget build(BuildContext context) {
    final d = driverOf(r.drivers, row.driver);
    final sub = rank == 1
        ? (row.time != null ? formatRaceTime(row.time!) : 'Kazanan')
        : (row.gap.isEmpty ? '—' : row.gap);
    return Column(children: [
      _Avatar(d, size: rank == 1 ? 62 : 52),
      const SizedBox(height: 6),
      Text(d.acronym, style: _t(context, 16, w: FontWeight.w800, ls: 0.3)),
      const SizedBox(height: 2),
      Text(sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _t(context, 11, color: _sec(context))),
      const SizedBox(height: 8),
      Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [d.color.withValues(alpha: 0.95), d.color.withValues(alpha: 0.35)],
          ),
        ),
        child: Text('$rank',
            style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 30,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none)),
      ),
    ]);
  }
}

class _ResultRowTile extends StatelessWidget {
  const _ResultRowTile(this.row, this.r);
  final ResultRow row;
  final Recap r;

  @override
  Widget build(BuildContext context) {
    final d = driverOf(r.drivers, row.driver);
    final g = r.grid[row.driver];
    Widget delta = const SizedBox(width: 40);
    if (g != null && row.position != null && !row.out) {
      final diff = g - row.position!;
      final up = diff > 0;
      delta = SizedBox(
        width: 40,
        child: diff == 0
            ? Text('–',
            textAlign: TextAlign.center,
            style: _t(context, 13, color: _sec(context)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
              up
                  ? CupertinoIcons.arrowtriangle_up_fill
                  : CupertinoIcons.arrowtriangle_down_fill,
              size: 9,
              color: up
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed),
          const SizedBox(width: 2),
          Text('${diff.abs()}',
              style: _t(context, 12.5,
                  w: FontWeight.w700,
                  color: up
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed)),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        SizedBox(
          width: 22,
          child: Text('${row.position}',
              style: _t(context, 14, w: FontWeight.w700, color: _sec(context))),
        ),
        Container(
          width: 4,
          height: 28,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
              color: d.color, borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(context, 15, w: FontWeight.w600)),
            Text(d.team,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(context, 11.5, color: _sec(context))),
          ]),
        ),
        delta,
        SizedBox(
          width: 42,
          child: Text(row.points > 0 ? '+${row.points.toStringAsFixed(0)}' : '',
              textAlign: TextAlign.right,
              style: _t(context, 13.5, w: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ───────────────────────── Lastik stratejisi ─────────────────────────

Color _compoundColor(String c) {
  switch (c) {
    case 'SOFT':
      return const Color(0xFFFF3B30);
    case 'MEDIUM':
      return const Color(0xFFFFCC00);
    case 'HARD':
      return const Color(0xFFE5E5EA);
    case 'INTERMEDIATE':
      return const Color(0xFF34C759);
    case 'WET':
      return const Color(0xFF0A84FF);
    default:
      return const Color(0xFF8E8E93);
  }
}

String _compoundTr(String c) {
  switch (c) {
    case 'SOFT':
      return 'Soft';
    case 'MEDIUM':
      return 'Medium';
    case 'HARD':
      return 'Hard';
    case 'INTERMEDIATE':
      return 'Inter';
    case 'WET':
      return 'Wet';
    default:
      return c;
  }
}

class _StintBar extends StatelessWidget {
  const _StintBar(this.stints, this.total, this.driverLaps, {this.height = 22});
  final List<StintRow> stints;
  final int total;
  final int driverLaps;
  final double height;

  @override
  Widget build(BuildContext context) {
    final list = [...stints]..sort((a, b) => a.number.compareTo(b.number));
    var used = 0;
    final children = <Widget>[];
    for (final s in list) {
      final end = s.lapEnd ?? driverLaps;
      final len = (end - s.lapStart + 1).clamp(1, 999).toInt();
      used += len;
      final color = _compoundColor(s.compound);
      final dark = s.compound == 'MEDIUM' || s.compound == 'HARD';
      children.add(Expanded(
        flex: len,
        child: Container(
          height: height,
          margin: const EdgeInsets.only(right: 1.5),
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text(
            len >= 6 && s.compound.isNotEmpty ? s.compound[0] : '',
            style: TextStyle(
                color: dark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none),
          ),
        ),
      ));
    }
    if (used < total) {
      children.add(Expanded(flex: total - used, child: const SizedBox()));
    }
    return Row(children: children);
  }
}

class _StintCard extends StatelessWidget {
  const _StintCard(this.d);
  final StintData d;

  @override
  Widget build(BuildContext context) {
    final byDriver = <int, List<StintRow>>{};
    for (final s in d.rows) {
      byDriver.putIfAbsent(s.driver, () => []).add(s);
    }
    final top = d.results
        .where((r) => r.position != null && byDriver.containsKey(r.driver))
        .take(10)
        .toList();

    // Hamur dağılımı (tüm pilotlar, tur bazında)
    final usage = <String, int>{};
    for (final s in d.rows) {
      final laps = d.results
          .where((r) => r.driver == s.driver)
          .map((r) => r.laps)
          .fold<int>(0, (a, b) => a > b ? a : b);
      final len = ((s.lapEnd ?? laps) - s.lapStart + 1).clamp(0, 999).toInt();
      if (s.compound.isNotEmpty) {
        usage[s.compound] = (usage[s.compound] ?? 0) + len;
      }
    }
    final totalUse = usage.values.fold<int>(0, (a, b) => a + b);
    final usageList = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final r in top) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.5),
            child: Row(children: [
              SizedBox(
                width: 42,
                child: Text(driverOf(d.drivers, r.driver).acronym,
                    style: _t(context, 13, w: FontWeight.w700)),
              ),
              Expanded(
                child: _StintBar(byDriver[r.driver]!, d.totalLaps, r.laps),
              ),
              SizedBox(
                width: 34,
                child: Text('${byDriver[r.driver]!.length - 1}x',
                    textAlign: TextAlign.right,
                    style: _t(context, 12, color: _sec(context))),
              ),
            ]),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 42, right: 34, top: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tur 1', style: _t(context, 10.5, color: _sec(context))),
            Text('Tur ${d.totalLaps}', style: _t(context, 10.5, color: _sec(context))),
          ]),
        ),
        const SizedBox(height: 14),
        const _Hairline(),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in usageList)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _fill(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _compoundColor(e.key)),
                ),
                const SizedBox(width: 6),
                Text(
                    '${_compoundTr(e.key)} %${totalUse == 0 ? 0 : (e.value * 100 / totalUse).round()}',
                    style: _t(context, 12.5, w: FontWeight.w600)),
              ]),
            ),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('"2x" = pit stop sayısı. Yüzdeler tüm pilotların tur dağılımıdır.',
              style: _t(context, 11.5, color: _sec(context))),
        ),
      ]),
    );
  }
}

// ───────────────────────── Hava / pist ─────────────────────────

String _weatherInsight(WeatherSummary w) {
  final parts = <String>[];
  if (w.track != null && w.air != null) {
    final diff = (w.track! - w.air!).round();
    parts.add('Asfalt havadan $diff°C daha sıcaktı.');
  }
  if (w.track != null) {
    if (w.track! >= 45) {
      parts.add('Yüksek pist sıcaklığı lastik aşınmasını ve aşırı ısınmayı artırır.');
    } else if (w.track! < 28) {
      parts.add('Düşük sıcaklık lastikleri çalışma aralığına getirmeyi zorlaştırır.');
    } else {
      parts.add('Pist sıcaklığı lastikler için dengeli bir aralıktaydı.');
    }
  }
  if (w.rain) {
    parts.add('Yarış sırasında yağmur kaydedildi; strateji dalgalanmaya açıktı.');
  }
  return parts.join(' ');
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard(this.w);
  final RaceWeather w;

  @override
  Widget build(BuildContext context) {
    final s = w.summary;
    String v(double? x, String unit) => x == null ? '–' : '${x.round()}$unit';
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Stat(CupertinoIcons.thermometer, CupertinoColors.systemBlue,
              v(s.air, '°C'), 'Hava'),
          const SizedBox(width: 10),
          _Stat(CupertinoIcons.flame_fill, CupertinoColors.systemOrange,
              v(s.track, '°C'), 'Pist'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _Stat(CupertinoIcons.drop_fill, CupertinoColors.systemTeal,
              v(s.humidity, '%'), 'Nem'),
          const SizedBox(width: 10),
          _Stat(CupertinoIcons.wind, CupertinoColors.systemIndigo,
              s.wind == null ? '–' : '${(s.wind! * 3.6).round()} km/s', 'Rüzgar'),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _IconTile(
              s.rain ? CupertinoIcons.cloud_rain_fill : CupertinoIcons.sun_max_fill,
              s.rain ? CupertinoColors.systemBlue : CupertinoColors.systemYellow,
              size: 28),
          const SizedBox(width: 10),
          Text(s.rain ? 'Yağmur kaydedildi' : 'Kuru yarış',
              style: _t(context, 15, w: FontWeight.w600)),
        ]),
        if (_weatherInsight(s).isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_weatherInsight(s),
              style: _t(context, 13.5, color: _sec(context), h: 1.4)),
        ],
        const SizedBox(height: 8),
        Text('${w.meeting.circuit} · yarış boyunca ortalama değerler',
            style: _t(context, 11.5, color: _sec(context))),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.color, this.value, this.label);
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(value, style: _t(context, 24, w: FontWeight.w700, ls: -0.5)),
          Text(label, style: _t(context, 12, color: _sec(context))),
        ]),
      ),
    );
  }
}

// ───────────────────────── Form ─────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard(this.t);
  final FormTable t;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 120),
          for (final l in t.labels)
            Expanded(
              child: Text(l,
                  textAlign: TextAlign.center,
                  style: _t(context, 11,
                      w: FontWeight.w700, color: _sec(context), ls: 0.6)),
            ),
        ]),
        const SizedBox(height: 8),
        for (var i = 0; i < t.rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(
                width: 120,
                child: Row(children: [
                  Container(
                    width: 4,
                    height: 24,
                    margin: const EdgeInsets.only(right: 9),
                    decoration: BoxDecoration(
                        color: t.rows[i].driver.color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Expanded(
                    child: Text(t.rows[i].driver.lastName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(context, 14.5, w: FontWeight.w600)),
                  ),
                ]),
              ),
              for (final p in t.rows[i].positions)
                Expanded(child: Center(child: _PosPill(p))),
            ]),
          ),
          if (i != t.rows.length - 1) const _Hairline(),
        ],
      ]),
    );
  }
}

class _PosPill extends StatelessWidget {
  const _PosPill(this.p);
  final int? p;

  @override
  Widget build(BuildContext context) {
    String text;
    Color bg;
    Color fg = CupertinoColors.white;
    if (p == null) {
      text = '–';
      bg = _fill(context);
      fg = _sec(context);
    } else if (p == 0) {
      text = 'DNF';
      bg = CupertinoColors.systemRed;
    } else if (p == 1) {
      text = 'P1';
      bg = const Color(0xFFFFD60A);
      fg = const Color(0xFF1C1C1E);
    } else if (p! <= 3) {
      text = 'P$p';
      bg = const Color(0xFF8E8E93);
    } else if (p! <= 10) {
      text = 'P$p';
      bg = CupertinoColors.systemGreen;
    } else {
      text = 'P$p';
      bg = _fill(context);
      fg = _sec(context);
    }
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(text,
          style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none)),
    );
  }
}

// ───────────────────────── Şampiyona ─────────────────────────

class _StandingsCard extends StatelessWidget {
  const _StandingsCard(this.s);
  final Standings s;

  @override
  Widget build(BuildContext context) {
    final rows = s.rows.take(5).toList();
    final leader = rows.first.points;
    return _Card(
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              SizedBox(
                width: 24,
                child: Text('${rows[i].position}',
                    style: _t(context, 16, w: FontWeight.w800,
                        color: i == 0 ? _kRed : _sec(context))),
              ),
              _Avatar(driverOf(s.drivers, rows[i].driver), size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(driverOf(s.drivers, rows[i].driver).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(context, 14.5, w: FontWeight.w600)),
                    ),
                    Text(rows[i].points.toStringAsFixed(0),
                        style: _t(context, 15, w: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 6),
                  _Bar(leader == 0 ? 0 : rows[i].points / leader,
                      driverOf(s.drivers, rows[i].driver).color,
                      height: 5),
                  if (i > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                        'Lider ile fark: ${(leader - rows[i].points).toStringAsFixed(0)} puan',
                        style: _t(context, 11, color: _sec(context))),
                  ],
                ]),
              ),
            ]),
          ),
          if (i != rows.length - 1) const _Hairline(indent: 34),
        ],
      ]),
    );
  }
}

// ───────────────────────── Bu pistte geçen yıl ─────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.h);
  final TrackHistory h;

  @override
  Widget build(BuildContext context) {
    final winner = h.top.first;
    final wd = driverOf(h.drivers, winner.driver);
    final stops = h.winnerStints.isEmpty ? null : h.winnerStints.length - 1;
    final medals = [
      const Color(0xFFFFD60A),
      const Color(0xFFC7C7CC),
      const Color(0xFFCD7F32)
    ];

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${h.meeting.year} · ${h.meeting.name}',
            style: _t(context, 13, color: _sec(context))),
        const SizedBox(height: 12),
        for (var i = 0; i < h.top.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration:
                BoxDecoration(shape: BoxShape.circle, color: medals[i]),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none)),
              ),
              const SizedBox(width: 12),
              _Avatar(driverOf(h.drivers, h.top[i].driver), size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(driverOf(h.drivers, h.top[i].driver).name,
                      style: _t(context, 15, w: FontWeight.w600)),
                  Text(driverOf(h.drivers, h.top[i].driver).team,
                      style: _t(context, 11.5, color: _sec(context))),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 10),
        const _Hairline(),
        const SizedBox(height: 14),
        if (h.winnerStints.isNotEmpty) ...[
          Row(children: [
            Expanded(
              child: Text('${wd.lastName} · kazanan strateji',
                  style: _t(context, 13.5, w: FontWeight.w600)),
            ),
            if (stops != null)
              Text('$stops pit stop',
                  style: _t(context, 13, color: _sec(context))),
          ]),
          const SizedBox(height: 8),
          _StintBar(h.winnerStints, h.winnerLaps, h.winnerLaps, height: 26),
          const SizedBox(height: 14),
        ],
        if (h.weather != null)
          Wrap(spacing: 8, runSpacing: 8, children: [
            _InfoChip(CupertinoIcons.thermometer, 'Hava ${h.weather!.air?.round() ?? '–'}°C'),
            _InfoChip(CupertinoIcons.flame_fill, 'Pist ${h.weather!.track?.round() ?? '–'}°C'),
            _InfoChip(
                h.weather!.rain
                    ? CupertinoIcons.cloud_rain_fill
                    : CupertinoIcons.sun_max_fill,
                h.weather!.rain ? 'Yağmurlu' : 'Kuru'),
          ]),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration:
      BoxDecoration(color: _fill(context), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _sec(context)),
        const SizedBox(width: 6),
        Text(text, style: _t(context, 12.5, w: FontWeight.w600)),
      ]),
    );
  }
}

// ───────────────────────── Alt bilgi ─────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Text(
        'Veriler OpenF1 üzerinden alınır, yorumlar Gemini tarafından yalnızca bu verilere dayanarak üretilir. Tahminler istatistikseldir ve kesin sonuç garantisi vermez.',
        textAlign: TextAlign.center,
        style: _t(context, 11.5, color: _sec(context), h: 1.4),
      ),
    );
  }
}