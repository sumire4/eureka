import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donemprojesi/ekranlar/profil/tesekkurler.dart';
import 'about_card.dart';

class ProfilEkrani extends StatefulWidget {
  final void Function(bool scrollingDown) onScroll;
  const ProfilEkrani({super.key, required this.onScroll});
  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  String _kullaniciAdi = "F1 Tutkunu";
  String _profilFoto = "";
  String _favoriPilot = "";
  String _favoriTakim = "";

  int _okunanHaberSayisi = 0;
  double _izlenenYarisSaati = 0.0;
  int _uygulamaGirisSayisi = 0;
  DateTime _uygulamaYuklenmeTarihi = DateTime.now();

  bool showBottomBar = true;
  double _lastScrollOffset = 0;

  final List<String> _pilotlar = [
    "Max Verstappen","Sergio Pérez","Lewis Hamilton","George Russell",
    "Charles Leclerc","Carlos Sainz","Lando Norris","Oscar Piastri",
    "Fernando Alonso","Lance Stroll","Esteban Ocon","Pierre Gasly",
    "Alexander Albon","Logan Sargeant","Valtteri Bottas","Zhou Guanyu",
    "Kevin Magnussen","Nico Hülkenberg","Yuki Tsunoda","Daniel Ricciardo",
    "Sebastian Vettel","Mika Hakkinen","Kimi Raikönen"
  ];

  final List<String> _takimlar = [
    "Red Bull Racing","Mercedes","Ferrari","McLaren","Aston Martin",
    "Alpine","Williams","Alfa Romeo","Haas","AlphaTauri"
  ];

  late final TextEditingController _adController;

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController();
    _verileriYukle();
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _kullaniciAdi = prefs.getString('kullanici_adi') ?? "F1 Tutkunu";
      _profilFoto = prefs.getString('profil_foto') ?? "";
      _favoriPilot = prefs.getString('favori_pilot') ?? "";
      _favoriTakim = prefs.getString('favori_takim') ?? "";
      _okunanHaberSayisi = prefs.getInt('okunan_haber_sayisi') ?? 0;
      _izlenenYarisSaati = prefs.getDouble('izlenen_yaris_saati') ?? 0.0;
      _uygulamaGirisSayisi = prefs.getInt('uygulama_giris_sayisi') ?? 1;

      final yuklenmeTarihiStr = prefs.getString('uygulama_yukleme_tarihi');
      if (yuklenmeTarihiStr != null) {
        _uygulamaYuklenmeTarihi = DateTime.parse(yuklenmeTarihiStr);
      } else {
        _uygulamaYuklenmeTarihi = DateTime.now();
        prefs.setString('uygulama_yukleme_tarihi', _uygulamaYuklenmeTarihi.toIso8601String());
      }
      _adController.text = _kullaniciAdi;
    });
  }

  Future<void> _veriKaydet(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    else if (value is int) await prefs.setInt(key, value);
    else if (value is double) await prefs.setDouble(key, value);
  }

  String _getKullaniciSuresi() {
    // 16 Aralık 2024 sabit tarihi
    final baslangicTarihi = DateTime(2024, 12, 16);
    final fark = DateTime.now().difference(baslangicTarihi);

    if (fark.inDays > 0) return '${fark.inDays} gün';
    if (fark.inHours > 0) return '${fark.inHours} saat';
    return '${fark.inMinutes} dakika';
  }

  void _profilDuzenle() async {
    String yeniAd = _kullaniciAdi;
    String yeniFavoriPilot = _favoriPilot;
    String yeniFavoriTakim = _favoriTakim;
    String yeniProfilFoto = _profilFoto;

    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Profili Düzenle"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() {
                          yeniProfilFoto = image.path;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: yeniProfilFoto.isNotEmpty ? FileImage(File(yeniProfilFoto)) : null,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: yeniProfilFoto.isEmpty ? Icon(Icons.person, size: 40) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: yeniAd),
                    decoration: const InputDecoration(labelText: "Kullanıcı Adı"),
                    onChanged: (val) => yeniAd = val,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Favori Pilot"),
                    value: yeniFavoriPilot.isEmpty ? null : yeniFavoriPilot,
                    items: _pilotlar.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => yeniFavoriPilot = val ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Favori Takım"),
                    value: yeniFavoriTakim.isEmpty ? null : yeniFavoriTakim,
                    items: _takimlar.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => yeniFavoriTakim = val ?? ''),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _kullaniciAdi = yeniAd;
                    _favoriPilot = yeniFavoriPilot;
                    _favoriTakim = yeniFavoriTakim;
                    _profilFoto = yeniProfilFoto;
                  });
                  _veriKaydet('kullanici_adi', yeniAd);
                  _veriKaydet('favori_pilot', yeniFavoriPilot);
                  _veriKaydet('favori_takim', yeniFavoriTakim);
                  _veriKaydet('profil_foto', yeniProfilFoto);
                  Navigator.pop(context);
                },
                child: const Text("Kaydet"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollUpdateNotification) {
                if (scrollNotification.metrics.pixels > _lastScrollOffset + 10 && showBottomBar) {
                  setState(() => showBottomBar = false);
                } else if (scrollNotification.metrics.pixels < _lastScrollOffset - 10 && !showBottomBar) {
                  setState(() => showBottomBar = true);
                  widget.onScroll(false);
                }
                _lastScrollOffset = scrollNotification.metrics.pixels;
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profilFoto.isNotEmpty
                        ? (_profilFoto.startsWith("http") ? NetworkImage(_profilFoto) : FileImage(File(_profilFoto))) as ImageProvider
                        : null,
                    backgroundColor: colorScheme.primaryContainer,
                    child: _profilFoto.isEmpty ? Icon(Icons.person, size: 60, color: colorScheme.onPrimaryContainer) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(_kullaniciAdi, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Üyelik Süresi: ${_getKullaniciSuresi()}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _profilDuzenle, icon: const Icon(Icons.edit), label: const Text("Profili Düzenle")),
                  const SizedBox(height: 24),
                  if (_favoriPilot.isNotEmpty || _favoriTakim.isNotEmpty)
                    _buildCard(
                      title: 'Favorilerim',
                      icon: Icons.favorite_outline,
                      children: [
                        if (_favoriPilot.isNotEmpty) _buildFavoriItem(Icons.sports_motorsports, 'Favori Pilot', _favoriPilot),
                        if (_favoriPilot.isNotEmpty && _favoriTakim.isNotEmpty) const SizedBox(height: 12),
                        if (_favoriTakim.isNotEmpty) _buildFavoriItem(Icons.flag, 'Favori Takım', _favoriTakim),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'İstatistik',
                    icon: Icons.analytics_outlined,
                    children: [
                      _buildIstatistikItem(Icons.article_outlined, 'Okunan Haber', '$_okunanHaberSayisi', 'haber'),
                      const SizedBox(height: 12),
                      _buildIstatistikItem(Icons.play_circle_outline, 'İzlenen Yarış', _izlenenYarisSaati.toStringAsFixed(1), 'saat'),
                      const SizedBox(height: 12),
                      _buildIstatistikItem(Icons.login_outlined, 'Uygulama Girişi', '$_uygulamaGirisSayisi', 'kez'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const TesekkurCard(),
                  const AboutCard(version: '1.0.0'),
                  // Alt boşluğu azaltıldı: 100'den 24'e
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      surfaceTintColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [Icon(icon, color: colorScheme.primary), const SizedBox(width: 8), Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriItem(IconData icon, String baslik, String deger) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: colorScheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(baslik, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)), Text(deger, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))])),
      ],
    );
  }

  Widget _buildIstatistikItem(IconData icon, String baslik, String deger, String birim) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: colorScheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: Text(baslik, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: deger, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              if (birim.isNotEmpty) TextSpan(text: ' $birim', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}