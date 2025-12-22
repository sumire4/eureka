import 'package:donemprojesi/ekranlar/paundurumu/standings_ekrani.dart';
import 'package:flutter/material.dart';
import 'package:donemprojesi/ekranlar/profil/profil_ekrani.dart';
import 'ekranlar/gazetelik/haber_ekrani.dart';
import 'ekranlar/brief/brief_ekrani.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isVisible = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onScroll(bool scrollingDown) {
    if (scrollingDown && _isVisible) {
      setState(() => _isVisible = false);
    } else if (!scrollingDown && !_isVisible) {
      setState(() => _isVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isVisible
          ? AppBar(
        title: Center(
          child: Text(
            _selectedIndex == 0
                ? "Gazetelik"
                : _selectedIndex == 1
                ? "Puan Durumu"
                : _selectedIndex == 2
                ? "İzle"
                : "Profil",
          ),
        ),
        elevation: 0,
      )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HaberEkrani(onScroll: _onScroll),
          StandingsEkrani(onScroll: _onScroll),
          BriefEkrani(onScroll: _onScroll),
          ProfilEkrani(onScroll: _onScroll),
        ],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isVisible ? 70 : 0,
        child: Wrap(
          children: [
            NavigationBar(
              height: 70,
              backgroundColor: Theme.of(context).colorScheme.surface,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.article), label: "Gazetelik"),
                NavigationDestination(icon: Icon(Icons.sports_score), label: "Puan Durumu"),
                NavigationDestination(icon: Icon(Icons.tv), label: "İzle"),
                NavigationDestination(icon: Icon(Icons.account_circle_rounded), label: "Profil"),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
            ),
          ],
        ),
      ),
    );
  }
}

