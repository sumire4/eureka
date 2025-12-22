import 'package:flutter/material.dart';
import 'anasayfa.dart';
import 'package:provider/provider.dart';
import 'ekranlar/profil/profile_service.dart'; // ProfileService class’ının bulunduğu dosya
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _girisSayisiniArtir() async {
  final prefs = await SharedPreferences.getInstance();
  int sayi = prefs.getInt('uygulama_giris_sayisi') ?? 0;
  await prefs.setInt('uygulama_giris_sayisi', sayi + 1);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _girisSayisiniArtir();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProfileService()..loadProfile(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Orientation? _sonYonu;
  DateTime? _baslangic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // İlk açılışta orientation alınır
      _sonYonu = MediaQuery.of(context).orientation;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final yeniYonu = MediaQuery.of(context).orientation;

      if (_sonYonu == null) {
        _sonYonu = yeniYonu;
        return;
      }

      if (_sonYonu != yeniYonu) {
        if (yeniYonu == Orientation.landscape) {
          // Landscape moda geçildi → zaman başlat
          _baslangic = DateTime.now();
        } else if (_sonYonu == Orientation.landscape && yeniYonu == Orientation.portrait) {
          // Portrait moda geçildi → zaman farkını hesapla
          if (_baslangic != null) {
            final farkDakika = DateTime.now().difference(_baslangic!).inSeconds / 60.0;
            _ekleIzlenenSure(farkDakika);
          }
          _baslangic = null;
        }
        _sonYonu = yeniYonu;
      }
    });
  }

  Future<void> _ekleIzlenenSure(double dakika) async {
    final prefs = await SharedPreferences.getInstance();
    double onceki = prefs.getDouble('izlenen_yaris_saati') ?? 0.0;
    await prefs.setDouble('izlenen_yaris_saati', onceki + (dakika / 60.0)); // Saat olarak kaydediyoruz
    debugPrint("İzlenen yarış süresi güncellendi: +${(dakika / 60.0).toStringAsFixed(2)} saat");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
