import 'package:flutter/cupertino.dart';
import '../../services/standings_service.dart';
import 'driver_detail_view.dart';
import 'constructor_detail_view.dart';

class StandingsView extends StatefulWidget {
  final bool isTabBarVisible;

  const StandingsView({super.key, this.isTabBarVisible = true});

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  int _selectedSegment = 0;
  final StandingsService _standingsService = StandingsService();

  late Future<List<DriverStanding>> _driversFuture;
  late Future<List<ConstructorStanding>> _constructorsFuture;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  void _loadStandings() {
    setState(() {
      _driversFuture = _standingsService.fetchDriverStandings();
      _constructorsFuture = _standingsService.fetchConstructorStandings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tabBarHeight = 50.0 + bottomInset;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Sıralamalar'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async => _loadStandings(),
              ),
              if (_selectedSegment == 0)
                _buildDriverStandingsSliver()
              else
                _buildConstructorStandingsSliver(),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 120),
              ),
            ],
          ),

          // Alt Bar Üzerinde Duran Segment Butonu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: widget.isTabBarVisible ? tabBarHeight : (bottomInset > 0 ? bottomInset : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context).withValues(alpha: 0.95),
                border: const Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedSegment,
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Text('Pilotlar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Text('Markalar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _selectedSegment = val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pilotlar Listesi Slivers
  Widget _buildDriverStandingsSliver() {
    return FutureBuilder<List<DriverStanding>>(
      future: _driversFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator(radius: 14)),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Sıralama verisi alınamadı.\nLütfen internet bağlantınızı kontrol edin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CupertinoColors.destructiveRed),
                ),
              ),
            ),
          );
        }
        final drivers = snapshot.data ?? [];
        if (drivers.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('Pilot sıralaması bulunamadı.')),
          );
        }

        return SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            header: const Text(
              'GÜNCEL PİLOTLAR ŞAMPİYONASI',
              style: TextStyle(letterSpacing: 0.3),
            ),
            children: drivers.map((d) {
              return _buildDriverTile(d);
            }).toList(),
          ),
        );
      },
    );
  }

  // Takımlar Listesi Slivers
  Widget _buildConstructorStandingsSliver() {
    return FutureBuilder<List<ConstructorStanding>>(
      future: _constructorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator(radius: 14)),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Markalar sıralaması alınamadı.\nLütfen internet bağlantınızı kontrol edin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CupertinoColors.destructiveRed),
                ),
              ),
            ),
          );
        }
        final constructors = snapshot.data ?? [];
        if (constructors.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('Markalar sıralaması bulunamadı.')),
          );
        }

        return SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            header: const Text(
              'GÜNCEL MARKALAR ŞAMPİYONASI',
              style: TextStyle(letterSpacing: 0.3),
            ),
            children: constructors.map((c) {
              return _buildConstructorTile(c);
            }).toList(),
          ),
        );
      },
    );
  }
  // Pilot Satırı: Sıralama no + Yuvarlak OpenF1 Fotoğrafı + İsim
  Widget _buildDriverTile(DriverStanding d) {
    final isTopThree = d.position == '1' || d.position == '2' || d.position == '3';

    Color posColor;
    if (d.position == '1') {
      posColor = const Color(0xFFE10600);
    } else if (d.position == '2') {
      posColor = const Color(0xFFD4AF37);
    } else if (d.position == '3') {
      posColor = const Color(0xFF8A95A5);
    } else {
      posColor = CupertinoColors.secondaryLabel;
    }

    return CupertinoListTile(
      leadingSize: 62,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sıralama Numarası
          SizedBox(
            width: 22,
            child: Text(
              d.position,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isTopThree ? FontWeight.w800 : FontWeight.w600,
                color: posColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Yuvarlak OpenF1 Fotoğrafı
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemGrey6,
            ),
            clipBehavior: Clip.antiAlias,
            child: d.headshotUrl != null && d.headshotUrl!.isNotEmpty
                ? Image.network(
              d.headshotUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CupertinoActivityIndicator(radius: 8),
                );
              },
              errorBuilder: (_, _, _) => const Icon(
                CupertinoIcons.person_fill,
                size: 18,
                color: CupertinoColors.systemGrey3,
              ),
            )
                : const Icon(
              CupertinoIcons.person_fill,
              size: 18,
              color: CupertinoColors.systemGrey3,
            ),
          ),
        ],
      ),
      title: Text(
        d.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        d.constructorName,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${d.points} PTS',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          const CupertinoListTileChevron(),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => DriverDetailView(driver: d),
          ),
        );
      },
    );
  }

  Color _getConstructorColor(String name) {
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

  String _getConstructorLogoUrl(String name) {
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

  // Takım Satırı: Sıra no + Gerçek Takım Logosu + İsim + Puan
  Widget _buildConstructorTile(ConstructorStanding c) {
    final isTopThree = c.position == '1' || c.position == '2' || c.position == '3';
    final teamColor = _getConstructorColor(c.name);
    final logoUrl = _getConstructorLogoUrl(c.name);

    Color posColor;
    if (c.position == '1') {
      posColor = const Color(0xFFE10600);
    } else if (c.position == '2') {
      posColor = const Color(0xFFD4AF37);
    } else if (c.position == '3') {
      posColor = const Color(0xFF8A95A5);
    } else {
      posColor = CupertinoColors.secondaryLabel;
    }

    return CupertinoListTile(
      leadingSize: 62,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              c.position,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isTopThree ? FontWeight.w800 : FontWeight.w600,
                color: posColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Gerçek Takım Logosu Rozeti
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.white,
            ),
            child: Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                CupertinoIcons.flag_fill,
                size: 14,
                color: teamColor,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        c.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        '${c.wins} Galibiyet',
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${c.points} PTS',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          const CupertinoListTileChevron(),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ConstructorDetailView(constructor: c),
          ),
        );
      },
    );
  }
}