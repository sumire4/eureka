import 'package:flutter/cupertino.dart';

class StandingsView extends StatefulWidget {
  final bool isTabBarVisible;

  const StandingsView({super.key, this.isTabBarVisible = true});

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  int _selectedSegment = 0;

  final List<Map<String, dynamic>> _drivers = const [
    {'pos': '1', 'name': 'Max Verstappen', 'team': 'Red Bull Racing', 'pts': '331'},
    {'pos': '2', 'name': 'Lando Norris', 'team': 'McLaren', 'pts': '279'},
    {'pos': '3', 'name': 'Charles Leclerc', 'team': 'Ferrari', 'pts': '245'},
    {'pos': '4', 'name': 'Oscar Piastri', 'team': 'McLaren', 'pts': '237'},
    {'pos': '5', 'name': 'Carlos Sainz', 'team': 'Ferrari', 'pts': '190'},
    {'pos': '6', 'name': 'Lewis Hamilton', 'team': 'Mercedes', 'pts': '174'},
    {'pos': '7', 'name': 'George Russell', 'team': 'Mercedes', 'pts': '155'},
    {'pos': '8', 'name': 'Sergio Perez', 'team': 'Red Bull Racing', 'pts': '144'},
    {'pos': '9', 'name': 'Fernando Alonso', 'team': 'Aston Martin', 'pts': '62'},
    {'pos': '10', 'name': 'Nico Hülkenberg', 'team': 'Haas F1 Team', 'pts': '24'},
    {'pos': '11', 'name': 'Lance Stroll', 'team': 'Aston Martin', 'pts': '24'},
    {'pos': '12', 'name': 'Yuki Tsunoda', 'team': 'Visa Cash App RB', 'pts': '22'},
    {'pos': '13', 'name': 'Alexander Albon', 'team': 'Williams', 'pts': '12'},
    {'pos': '14', 'name': 'Daniel Ricciardo', 'team': 'Visa Cash App RB', 'pts': '12'},
    {'pos': '15', 'name': 'Pierre Gasly', 'team': 'Alpine', 'pts': '8'},
    {'pos': '16', 'name': 'Oliver Bearman', 'team': 'Ferrari / Haas', 'pts': '7'},
    {'pos': '17', 'name': 'Kevin Magnussen', 'team': 'Haas F1 Team', 'pts': '6'},
    {'pos': '18', 'name': 'Esteban Ocon', 'team': 'Alpine', 'pts': '5'},
    {'pos': '19', 'name': 'Franco Colapinto', 'team': 'Williams', 'pts': '4'},
    {'pos': '20', 'name': 'Zhou Guanyu', 'team': 'Kick Sauber', 'pts': '0'},
  ];

  final List<Map<String, dynamic>> _constructors = const [
    {'pos': '1', 'name': 'McLaren', 'sub': 'Norris / Piastri', 'pts': '516'},
    {'pos': '2', 'name': 'Red Bull Racing', 'sub': 'Verstappen / Perez', 'pts': '475'},
    {'pos': '3', 'name': 'Ferrari', 'sub': 'Leclerc / Sainz', 'pts': '441'},
    {'pos': '4', 'name': 'Mercedes', 'sub': 'Hamilton / Russell', 'pts': '329'},
    {'pos': '5', 'name': 'Aston Martin', 'sub': 'Alonso / Stroll', 'pts': '86'},
    {'pos': '6', 'name': 'Haas F1 Team', 'sub': 'Hülkenberg / Magnussen', 'pts': '31'},
    {'pos': '7', 'name': 'Visa Cash App RB', 'sub': 'Tsunoda / Ricciardo', 'pts': '34'},
    {'pos': '8', 'name': 'Williams', 'sub': 'Albon / Colapinto', 'pts': '16'},
    {'pos': '9', 'name': 'Alpine', 'sub': 'Gasly / Ocon', 'pts': '13'},
    {'pos': '10', 'name': 'Kick Sauber', 'sub': 'Bottas / Zhou', 'pts': '0'},
  ];

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
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: Text(
                    _selectedSegment == 0
                        ? '2026 PİLOTLAR ŞAMPİYONASI'
                        : '2026 MARKALAR ŞAMPİYONASI',
                    style: const TextStyle(letterSpacing: 0.3),
                  ),
                  children: _selectedSegment == 0
                      ? _drivers
                      .map((d) => _buildStandingRow(
                    d['pos'],
                    d['name'],
                    d['team'],
                    d['pts'],
                  ))
                      .toList()
                      : _constructors
                      .map((c) => _buildStandingRow(
                    c['pos'],
                    c['name'],
                    c['sub'],
                    c['pts'],
                  ))
                      .toList(),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 120),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: widget.isTabBarVisible ? tabBarHeight : (bottomInset > 0 ? bottomInset : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.95),
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

  Widget _buildStandingRow(String pos, String name, String? sub, String pts) {
    final isTopThree = pos == '1' || pos == '2' || pos == '3';

    Color posColor;
    if (pos == '1') {
      posColor = const Color(0xFFE10600);
    } else if (pos == '2') {
      posColor = const Color(0xFFD4AF37);
    } else if (pos == '3') {
      posColor = const Color(0xFF8A95A5);
    } else {
      posColor = CupertinoColors.secondaryLabel;
    }

    return CupertinoListTile(
      leadingSize: 32,
      leading: Container(
        alignment: Alignment.center,
        child: Text(
          pos,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTopThree ? FontWeight.w800 : FontWeight.w600,
            color: posColor,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: sub != null
          ? Text(
        sub,
        style: const TextStyle(fontSize: 13),
      )
          : null,
      trailing: Text(
        '$pts PTS',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}