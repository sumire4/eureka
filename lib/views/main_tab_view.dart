import 'package:flutter/cupertino.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_bottom_bar.dart';
import 'news/news_view.dart';
import 'standings/standings_view.dart';
import 'ai/eureka_ai_view.dart';
import 'profile/profile_view.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _currentIndex = 0;
  final bool _isTabBarVisible = true;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sayfalar build içinde tanımlanıyor; _isTabBarVisible değiştikçe StandingsView'a aktarılır
    final views = [
      const NewsView(),
      StandingsView(isTabBarVisible: _isTabBarVisible),
      const EurekaAiView(),
      const ProfileView(),
    ];

    return CupertinoPageScaffold(
      child: LiquidBackground(
        child: Stack(
          children: [
            // 1. Aktif Sayfa İçeriği
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: views,
              ),
            ),

            // 2. Süzülen Liquid Glass Bottom Bar (Animasyonlu Gizlenme / Gösterilme)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: 0,
              right: 0,
              bottom: _isTabBarVisible ? 0 : -100, // Gizlendiğinde ekranın altına kayar
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isTabBarVisible ? 1.0 : 0.0,
                child: LiquidPillBottomBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabSelected,
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
                      icon: CupertinoIcons.person_crop_circle,
                      activeIcon: CupertinoIcons.person_crop_circle_fill,
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}