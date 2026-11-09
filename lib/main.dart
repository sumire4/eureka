import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/ios_theme.dart';
import 'views/news/news_view.dart';
import 'views/standings/standings_view.dart';
import 'views/profile/profile_view.dart';
import 'widgets/liquid_bottom_bar.dart';
import 'views/ai/race_analysis_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _isCompact = false; // Barın hafif küçülmesini sağlayan durum

  @override
  Widget build(BuildContext context) {
    final views = [
      const NewsView(),
      const StandingsView(isTabBarVisible: true),
      const RaceAnalysisPage(),
      const ProfileView(),
    ];

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Aşağı kaydırırken: Bar kaybolmaz, hafifçe kompakt moda geçer
        if (notification.direction == ScrollDirection.reverse) {
          if (!_isCompact) {
            setState(() => _isCompact = true);
          }
        }
        // Yukarı kaydırırken veya durunca: Normal boyutuna geri döner
        else if (notification.direction == ScrollDirection.forward) {
          if (_isCompact) {
            setState(() => _isCompact = false);
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

            // 2. Özel Cam Pill Bottom Bar (Slide & Opacity kaldırıldı, isCompact bağlandı)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiquidPillBottomBar(
                currentIndex: _currentIndex,
                isCompact: _isCompact, // Küçülme animasyonunu barın içine iletiyoruz
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
          ],
        ),
      ),
    );
  }
}