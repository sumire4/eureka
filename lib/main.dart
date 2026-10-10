import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'core/theme/ios_theme.dart';
import 'views/news/news_view.dart';
import 'views/standings/standings_view.dart';
import 'views/ai_chat/ai_chat_view.dart';
import 'views/profile/profile_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Sayfalar burada build içinde tanımlanıyor ki _isTabBarVisible değiştikçe StandingsView'a aktarılsın
    final views = [
      const NewsView(),
      StandingsView(isTabBarVisible: _isTabBarVisible),
      const AiChatView(),
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
      child: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: views,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              offset: _isTabBarVisible ? Offset.zero : const Offset(0, 1),
              child: CupertinoTabBar(
                border: null,
                currentIndex: _currentIndex,
                activeColor: AppIosTheme.f1Red,
                inactiveColor: CupertinoColors.systemGrey,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.news),
                    activeIcon: Icon(CupertinoIcons.news_solid),
                    label: 'Haberler',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.flag),
                    activeIcon: Icon(CupertinoIcons.flag_fill),
                    label: 'Sıralama',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.sparkles),
                    label: 'Eureka AI',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_circle),
                    activeIcon: Icon(CupertinoIcons.person_circle_fill),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}