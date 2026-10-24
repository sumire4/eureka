import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/ios_theme.dart';
import 'views/news/news_view.dart';
import 'views/standings/standings_view.dart';
import 'views/ai/eureka_ai_view.dart';
import 'views/profile/profile_view.dart';
import 'widgets/liquid_bottom_bar.dart'; // 1. Liquid Bottom Bar import edildi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env dosyasını belleğe yükle
  await dotenv.load(fileName: ".env");
  runApp(const EurekaApp());
}

class EurekaApp extends StatelessWidget {
  const EurekaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Eureka',
      theme: AppIosTheme.theme,
      home: MainTabScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _currentIndex = 0;
  bool _isTabBarVisible = true;

  @override
  Widget build(BuildContext context) {
    final views = [
      const NewsView(),
      StandingsView(isTabBarVisible: _isTabBarVisible),
      const EurekaAiView(),
      const ProfileView(),
    ];

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.reverse) {
          if (_isTabBarVisible) {
            setState(() => _isTabBarVisible = false);
          }
        } else if (notification.direction == ScrollDirection.forward) {
          if (!_isTabBarVisible) {
            setState(() => _isTabBarVisible = true);
          }
        }
        return false;
      },
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            // 1. Sekme Sayfaları
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: views,
              ),
            ),

            // 2. Süzülen Liquid Glass Pill Bottom Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                offset: _isTabBarVisible ? Offset.zero : const Offset(0, 1.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isTabBarVisible ? 1.0 : 0.0,
                  child: LiquidPillBottomBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() => _currentIndex = index);
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}