import 'package:flutter/cupertino.dart';
import '../widgets/liquid_bottom_bar.dart';
import 'news/news_view.dart';
import 'standings/standings_view.dart';
import 'profile/profile_view.dart';
import 'ai/race_analysis_page.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _currentIndex = 0;
  final bool _isTabBarVisible = true;
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    final views = [
      const NewsView(),
      StandingsView(isTabBarVisible: _isTabBarVisible),
      const RaceAnalysisPage(),
      const ProfileView(),
    ];

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // 1. Sekme İçerikleri
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                for (var i = 0; i < views.length; i++)
                  _visited.contains(i) ? views[i] : const SizedBox.shrink(),
              ],
            ),
          ),

          // 2. Özel Cam Pill Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidPillBottomBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _visited.add(index);
                });
              },
              items: const [
                LiquidBottomBarItem(
                  icon: CupertinoIcons.news,
                  activeIcon: CupertinoIcons.news_solid,
                  label: 'Haberler',
                ),
                LiquidBottomBarItem(
                  icon: CupertinoIcons.flag,
                  activeIcon: CupertinoIcons.flag_fill,
                  label: 'Sıralama',
                ),
                LiquidBottomBarItem(
                  icon: CupertinoIcons.sparkles,
                  activeIcon: CupertinoIcons.sparkles,
                  label: 'Eureka YZ',
                ),
                LiquidBottomBarItem(
                  icon: CupertinoIcons.person_circle,
                  activeIcon: CupertinoIcons.person_circle_fill,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}