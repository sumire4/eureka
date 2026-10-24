import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import '../../models/news_model.dart';
import '../../services/dashboard_service.dart';
import 'news_detail_view.dart';

class CustomFeedView extends StatefulWidget {
  final WeatherData? initialWeather;

  const CustomFeedView({super.key, this.initialWeather});

  @override
  State<CustomFeedView> createState() => _CustomFeedViewState();
}

class _CustomFeedViewState extends State<CustomFeedView> {
  WeatherData? _weather;
  List<String> _savedFeeds = [];
  String? _selectedFeedUrl;
  List<NewsItem> _customNews = [];
  bool _isLoadingNews = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _weather = widget.initialWeather;
    _loadSavedFeeds();
    if (_weather == null) {
      _refreshWeather();
    }
  }

  void _refreshWeather() async {
    final w = await DashboardService.fetchCurrentWeather();
    if (mounted) setState(() => _weather = w);
  }

  Future<void> _loadSavedFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final feeds = prefs.getStringList('custom_rss_urls') ?? [];
    debugPrint('Yüklü Kayıtlı RSS Listesi: $feeds');

    if (mounted) {
      setState(() {
        _savedFeeds = List.from(feeds);
        if (_savedFeeds.isNotEmpty && _selectedFeedUrl == null) {
          _selectedFeedUrl = _savedFeeds.first;
        }
      });
    }

    if (_selectedFeedUrl != null) {
      _fetchFeedContent(_selectedFeedUrl!);
    }
  }

  Future<void> _addFeed(String rawUrl) async {
    String cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) return;

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList('custom_rss_urls') ?? [];

    if (!currentList.contains(cleanUrl)) {
      currentList.add(cleanUrl);
      await prefs.setStringList('custom_rss_urls', currentList);
      debugPrint('RSS Başarıyla Kaydedildi: $cleanUrl');
    }

    if (mounted) {
      setState(() {
        _savedFeeds = List.from(currentList);
        _selectedFeedUrl = cleanUrl;
      });
      _fetchFeedContent(cleanUrl);
    }
  }

  Future<void> _deleteFeed(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList('custom_rss_urls') ?? [];
    currentList.remove(url);
    await prefs.setStringList('custom_rss_urls', currentList);

    if (mounted) {
      setState(() {
        _savedFeeds = List.from(currentList);
        _selectedFeedUrl = _savedFeeds.isNotEmpty ? _savedFeeds.first : null;
        if (_selectedFeedUrl == null) {
          _customNews = [];
        }
      });
    }

    if (_selectedFeedUrl != null) {
      _fetchFeedContent(_selectedFeedUrl!);
    }
  }

  Future<void> _fetchFeedContent(String url) async {
    setState(() {
      _isLoadingNews = true;
      _errorMessage = null;
    });

    debugPrint('RSS Çekiliyor: $url');

    try {
      final uri = Uri.parse(url.trim());
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 12));

      debugPrint('RSS Yanıt Kodu: ${res.statusCode}');

      if (res.statusCode == 200) {
        String rawXml;
        try {
          rawXml = utf8.decode(res.bodyBytes);
        } catch (_) {
          rawXml = res.body;
        }

        final document = XmlDocument.parse(rawXml);

        var nodes = document.findAllElements('item').toList();
        if (nodes.isEmpty) {
          nodes = document.findAllElements('entry').toList();
        }

        debugPrint('Bulunan Haber Sayısı: ${nodes.length}');

        final List<NewsItem> parsedList = [];

        for (var node in nodes) {
          final title = node.findElements('title').firstOrNull?.innerText ?? 'Başlıksız';

          String link = '';
          final linkNode = node.findElements('link').firstOrNull;
          if (linkNode != null) {
            link = linkNode.getAttribute('href') ?? linkNode.innerText;
          }

          String desc = node.findElements('description').firstOrNull?.innerText ??
              node.findElements('summary').firstOrNull?.innerText ??
              node.findElements('content').firstOrNull?.innerText ??
              '';

          final pubDate = node.findElements('pubDate').firstOrNull?.innerText ??
              node.findElements('published').firstOrNull?.innerText ??
              node.findElements('updated').firstOrNull?.innerText ??
              '';

          // Resim bulma
          String? imageUrl;
          final enclosure = node.findElements('enclosure').firstOrNull;
          if (enclosure != null) {
            imageUrl = enclosure.getAttribute('url');
          }

          if (imageUrl == null) {
            for (var elem in node.children) {
              if (elem is XmlElement && elem.name.local == 'content' && elem.name.prefix == 'media') {
                imageUrl = elem.getAttribute('url');
                break;
              }
            }
          }

          if (imageUrl == null && desc.contains('<img')) {
            final match = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(desc);
            if (match != null) {
              imageUrl = match.group(1);
            }
          }

          final cleanTitle = title.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          final cleanDesc = desc.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

          parsedList.add(
            NewsItem(
              title: cleanTitle,
              link: link.trim(),
              description: cleanDesc,
              pubDate: pubDate.trim(),
              imageUrl: imageUrl?.trim(),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _customNews = parsedList;
            _isLoadingNews = false;
          });
        }
        return;
      } else {
        throw Exception('Sunucu yanıt vermedi (Kod: ${res.statusCode})');
      }
    } catch (e) {
      debugPrint('RSS Hatası: $e');
      if (mounted) {
        setState(() {
          _customNews = [];
          _isLoadingNews = false;
          _errorMessage = 'Akış yüklenemedi: $e';
        });
      }
    }
  }

  void _showAddFeedDialog() {
    final textController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Yeni RSS Akışı Ekle'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'https://site.com/rss.xml',
            keyboardType: TextInputType.url,
            autofocus: true,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              // Metni pop etmeden önce hafızaya alıyoruz
              final inputUrl = textController.text;
              Navigator.of(ctx).pop();
              if (inputUrl.trim().isNotEmpty) {
                _addFeed(inputUrl);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Özel Akış & Detay'),
        previousPageTitle: 'Geri',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddFeedDialog,
          child: const Icon(CupertinoIcons.add, size: 24),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Detaylı Hava Durumu
            SliverToBoxAdapter(
              child: _buildDetailedWeatherSection(context),
            ),

            // 2. RSS Kapsülleri (Eklenenler)
            SliverToBoxAdapter(
              child: _buildFeedSelector(context),
            ),

            // 3. İçerik / Durumlar
            if (_isLoadingNews)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              )
            else if (_savedFeeds.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 50, color: CupertinoColors.systemGrey3),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz RSS Akışı Eklenmedi',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sağ üstteki "+" simgesine dokunarak veya aşağıdaki hazır kaynaklardan birini seçerek hemen başlayın:',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                        ),
                        const SizedBox(height: 20),
                        // Hızlı Test Butonları
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildPresetButton('Motorsport F1', 'https://tr.motorsport.com/rss/f1/news/'),
                            _buildPresetButton('NTV Spor', 'https://www.ntvspor.net/rss'),
                            _buildPresetButton('TRT Spor', 'https://www.trtspor.com.tr/rss.xml'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else if (_customNews.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Bu akışta henüz gösterilecek haber bulunamadı.',
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                    ),
                  )
                else
                  _buildNewsSliverList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String title, String url) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: CupertinoColors.systemGrey6.resolveFrom(context),
      borderRadius: BorderRadius.circular(12),
      onPressed: () => _addFeed(url),
      child: Text(
        '+ $title',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE10600)),
      ),
    );
  }

  Widget _buildDetailedWeatherSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.location_fill, size: 18, color: Color(0xFFE10600)),
                    const SizedBox(width: 6),
                    Text(
                      _weather?.cityName ?? 'Konum...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      _weather?.icon ?? CupertinoIcons.sun_max_fill,
                      size: 26,
                      color: const Color(0xFFFF9500),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _weather != null ? '${_weather!.temperature.round()}°C' : '--°C',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weatherDetailItem('Durum', 'Açık / Parçalı'),
                  _weatherDetailItem('Rüzgar', '12 km/s'),
                  _weatherDetailItem('Nem', '%48'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherDetailItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: CupertinoColors.secondaryLabel, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFeedSelector(BuildContext context) {
    if (_savedFeeds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _savedFeeds.length,
          itemBuilder: (context, idx) {
            final feed = _savedFeeds[idx];
            final isSelected = feed == _selectedFeedUrl;
            final host = Uri.tryParse(feed)?.host.replaceFirst('www.', '') ?? 'Akış ${idx + 1}';

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFeedUrl = feed);
                  _fetchFeedContent(feed);
                },
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  showCupertinoModalPopup(
                    context: context,
                    builder: (ctx) => CupertinoActionSheet(
                      title: Text(feed),
                      actions: [
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _deleteFeed(feed);
                          },
                          child: const Text('Bu Akışı Kaldır'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE10600) : CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Center(
                    child: Text(
                      host,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final item = _customNews[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => NewsDetailView(
                      allNews: _customNews,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _customNews.length,
      ),
    );
  }
}