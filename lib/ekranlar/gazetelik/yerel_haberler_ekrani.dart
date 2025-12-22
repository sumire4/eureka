import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rss_dart/dart_rss.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class YerelHaberlerEkrani extends StatefulWidget {
  const YerelHaberlerEkrani({Key? key}) : super(key: key);

  @override
  State<YerelHaberlerEkrani> createState() => _YerelHaberlerEkraniState();
}

class _YerelHaberlerEkraniState extends State<YerelHaberlerEkrani> {
  final TextEditingController _urlController = TextEditingController();
  List<String> _abonelikler = [];
  List<RssItem> _haberler = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAbonelikler();
  }

  Future<void> _loadAbonelikler() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _abonelikler = prefs.getStringList("abonelikler") ?? [];
    });
    _fetchTumHaberler();
  }

  Future<void> _saveAbonelikler() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("abonelikler", _abonelikler);
  }

  Future<void> _abonelikEkle(String url) async {
    if (url.isNotEmpty && !_abonelikler.contains(url)) {
      setState(() {
        _abonelikler.add(url);
      });
      await _saveAbonelikler();
      _fetchTumHaberler();
    }
  }

  Future<void> _abonelikSil(String url) async {
    setState(() {
      _abonelikler.remove(url);
    });
    await _saveAbonelikler();
    _fetchTumHaberler();
  }

  Future<void> _fetchTumHaberler() async {
    if (_abonelikler.isEmpty) return;
    setState(() {
      _loading = true;
      _haberler.clear();
    });

    try {
      for (final url in _abonelikler) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final feed = RssFeed.parse(decodedBody);
          if (feed.items.isNotEmpty) {
            _haberler.addAll(feed.items);
          }
        }
      }
      _haberler.sort((a, b) {
        final da = DateTime.tryParse(a.pubDate ?? "") ?? DateTime.now();
        final db = DateTime.tryParse(b.pubDate ?? "") ?? DateTime.now();
        return db.compareTo(da);
      });
    } catch (e) {
      debugPrint("RSS Hata: $e");
    }

    setState(() {
      _loading = false;
    });
  }

  String? _getImageUrl(RssItem haber) {
    if (haber.enclosure?.url != null && haber.enclosure!.url!.isNotEmpty) {
      return haber.enclosure!.url;
    }
    final desc = haber.description ?? "";
    final regex = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regex.firstMatch(desc);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  void _rssEkleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("RSS URL Ekle"),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(hintText: "RSS URL"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                _abonelikEkle(_urlController.text.trim());
                _urlController.clear();
                Navigator.pop(context);
              },
              child: const Text("Ekle"),
            ),
          ],
        );
      },
    );
  }

  void _aboneliklerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Üstte sürükleme çubuğu ve başlık
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Abonelikler",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: _abonelikler.isEmpty
                        ? const [ListTile(title: Text("Henüz abonelik yok"))]
                        : _abonelikler.map((url) {
                      return ListTile(
                        leading: const Icon(Icons.rss_feed, color: Colors.orange),
                        title: Text(url, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _abonelikSil(url);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yerel Haberler"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _rssEkleDialog,
            tooltip: "RSS Ekle",
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _aboneliklerBottomSheet,
            tooltip: "Abonelikler",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _haberler.isEmpty
          ? const Center(child: Text("Henüz haber bulunamadı."))
          : ListView.builder(
        itemCount: _haberler.length,
        itemBuilder: (context, index) {
          final haber = _haberler[index];
          final imageUrl = _getImageUrl(haber);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              leading: imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
                ),
              )
                  : const Icon(Icons.article, size: 40),
              title: Text(
                haber.title ?? "Başlık Yok",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                haber.pubDate ?? "",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HaberDetaySayfasi(
                      haberler: _haberler,
                      initialIndex: index,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class HaberDetaySayfasi extends StatefulWidget {
  final List<RssItem> haberler;
  final int initialIndex;

  const HaberDetaySayfasi({Key? key, required this.haberler, required this.initialIndex})
      : super(key: key);

  @override
  State<HaberDetaySayfasi> createState() => _HaberDetaySayfasiState();
}

class _HaberDetaySayfasiState extends State<HaberDetaySayfasi> {
  late PageController _pageController;
  late int _currentIndex;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  String? _getImageUrl(RssItem haber) {
    // RSS'teki enclosure veya description içindeki ilk resmi al
    if (haber.enclosure?.url != null && haber.enclosure!.url!.isNotEmpty) {
      return haber.enclosure!.url;
    }
    final desc = haber.description ?? "";
    final regex = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regex.firstMatch(desc);
    if (match != null) return match.group(1);
    return null;
  }

  String _getFullContent(RssItem haber) {
    // content varsa al, yoksa description al
    String content = "";
    if (haber.content?.value != null && haber.content!.value!.isNotEmpty) {
      content = haber.content!.value!;
    } else if (haber.description != null && haber.description!.isNotEmpty) {
      content = haber.description!;
    }

    // Html içindeki ilk <img> tagını kaldır
    content = content.replaceFirst(RegExp(r'<img.*?>', caseSensitive: false), '');
    return content;
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true, forceWebView: true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("URL açılamadı")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final haber = widget.haberler[_currentIndex];
    final theme = Theme.of(context);
    final bgColor = _darkMode ? Colors.black : Colors.white;
    final textColor = _darkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          haber.title ?? "Haber Detayı",
          style: TextStyle(color: textColor, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
              });
            },
            tooltip: "Okuma Modu",
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser, color: textColor),
            onPressed: () {
              if (haber.link != null && haber.link!.isNotEmpty) {
                _launchURL(haber.link!);
              }
            },
            tooltip: "Tarayıcıda Aç",
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.haberler.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final haber = widget.haberler[index];
          final imageUrl = _getImageUrl(haber);
          final icerik = _getFullContent(haber);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    haber.title ?? "Başlık Yok",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    haber.pubDate ?? "",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Html(
                    data: icerik,
                    // <img> taglarını göstermiyoruz

                    style: {
                      "body": Style(color: textColor),
                      "p": Style(color: textColor),
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

