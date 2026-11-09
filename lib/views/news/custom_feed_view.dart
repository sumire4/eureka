import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import '../../models/news_model.dart';
import '../../services/city_rss_service.dart';
import '../../services/dashboard_service.dart';
import 'news_detail_view.dart';

// Feed metadata öğesi (Şehir veya Manuel)
class FeedSource {
  final String title;
  final String url;
  final bool isCityFeed;

  FeedSource({required this.title, required this.url, this.isCityFeed = false});
}

class CustomFeedView extends StatefulWidget {
  final WeatherData? initialWeather;

  const CustomFeedView({super.key, this.initialWeather});

  @override
  State<CustomFeedView> createState() => _CustomFeedViewState();
}

class _CustomFeedViewState extends State<CustomFeedView> {
  WeatherData? _weather;
  List<FeedSource> _allFeeds = [];
  String? _selectedFeedUrl;
  List<NewsItem> _customNews = [];
  bool _isLoadingNews = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _weather = widget.initialWeather;
    _initializeFeeds();
    if (_weather == null) {
      _refreshWeather();
    }
  }

  void _refreshWeather() async {
    final w = await DashboardService.fetchCurrentWeather();
    if (mounted) {
      setState(() => _weather = w);
      // Hava durumu geldiğinde o şehre ait RSS akışlarını güncelle
      if (w != null && w.cityName.isNotEmpty) {
        _initializeFeeds();
      }
    }
  }

  Future<void> _initializeFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final manualUrls = prefs.getStringList('custom_rss_urls') ?? [];

    // 1. Şehre özel akışları çek
    final cityList = CityRssService.getFeedsForCity(_weather?.cityName);
    final List<FeedSource> aggregated = [];

    // Şehir kaynaklarını ekle
    for (var c in cityList) {
      aggregated.add(FeedSource(
        title: c['name'] ?? 'Yerel Kaynak',
        url: c['url']!,
        isCityFeed: true,
      ));
    }

    // 2. Kullanıcının manuel eklediklerini ekle
    for (var url in manualUrls) {
      final host = Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'Özel Akış';
      aggregated.add(FeedSource(
        title: host,
        url: url,
        isCityFeed: false,
      ));
    }

    if (mounted) {
      setState(() {
        _allFeeds = aggregated;
        if (_allFeeds.isNotEmpty && (_selectedFeedUrl == null || !_allFeeds.any((f) => f.url == _selectedFeedUrl))) {
          _selectedFeedUrl = _allFeeds.first.url;
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
    }

    await _initializeFeeds();
    setState(() => _selectedFeedUrl = cleanUrl);
    _fetchFeedContent(cleanUrl);
  }

  Future<void> _deleteFeed(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList('custom_rss_urls') ?? [];
    currentList.remove(url);
    await prefs.setStringList('custom_rss_urls', currentList);

    await _initializeFeeds();
  }

  Future<void> _fetchFeedContent(String url) async {
    setState(() {
      _isLoadingNews = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(url.trim());
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 12));

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
      } else {
        throw Exception('Sunucu yanıt vermedi (Kod: ${res.statusCode})');
      }
    } catch (e) {
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
        middle: const Text('Özel & Yerel Akış'),
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
            SliverToBoxAdapter(
              child: _buildDetailedWeatherSection(context),
            ),
            SliverToBoxAdapter(
              child: _buildFeedSelector(context),
            ),
            if (_isLoadingNews)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              )
            else if (_allFeeds.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Akış kaynağı bulunamadı.')),
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
                        'Bu akışta henüz haber bulunamadı.',
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
                      _weather?.cityName ?? 'Konum Alınıyor...',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFeedSelector(BuildContext context) {
    if (_allFeeds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _allFeeds.length,
          itemBuilder: (context, idx) {
            final feed = _allFeeds[idx];
            final isSelected = feed.url == _selectedFeedUrl;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFeedUrl = feed.url);
                  _fetchFeedContent(feed.url);
                },
                onLongPress: () {
                  if (feed.isCityFeed) {
                    // Konum bazlı yerel akışlar silinmez, bildirim verilir
                    return;
                  }
                  HapticFeedback.heavyImpact();
                  showCupertinoModalPopup(
                    context: context,
                    builder: (ctx) => CupertinoActionSheet(
                      title: Text(feed.title),
                      actions: [
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _deleteFeed(feed.url);
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (feed.isCityFeed) ...[
                        Icon(
                          CupertinoIcons.placemark,
                          size: 13,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        feed.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ],
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