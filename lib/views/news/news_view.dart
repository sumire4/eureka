import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/news_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/gemini_service.dart';
import '../../services/rss_service.dart';
import 'news_detail_view.dart';
import 'custom_feed_view.dart';
import 'race_detail_view.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  final RssService _rssService = RssService();
  final GeminiService _geminiService = GeminiService();
  late Future<List<NewsItem>> _newsFuture;

  // Hava durumu ve yarış verisi
  WeatherData? _weather;
  NextRaceInfo? _nextRace;

  final Set<String> _bookmarkedLinks = {};

  @override
  void initState() {
    super.initState();
    _refreshNews();
    _loadWeather();
    _loadNextRace();
  }

  void _loadNextRace() async {
    final race = await DashboardService.fetchNextRace();
    if (mounted) {
      setState(() => _nextRace = race);
    }
  }

  void _loadWeather() async {
    final w = await DashboardService.fetchCurrentWeather();
    if (mounted) {
      setState(() => _weather = w);
    }
  }

  void _refreshNews() {
    setState(() {
      _newsFuture = _rssService.fetchNews();
    });
  }

  void _openNewsDetail(List<NewsItem> allItems, int clickedIndex) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => NewsDetailView(
          allNews: allItems,
          initialIndex: clickedIndex,
        ),
      ),
    );
  }

  void _toggleBookmark(String link) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_bookmarkedLinks.contains(link)) {
        _bookmarkedLinks.remove(link);
      } else {
        _bookmarkedLinks.add(link);
      }
    });
  }

  void _shareNews(NewsItem item) {
    HapticFeedback.selectionClick();
    SharePlus.instance.share(
      ShareParams(
        text: '${item.title}\n\nDetaylar: ${item.link}',
        subject: item.title,
      ),
    );
  }

  // Canlı Gemini AI Özet Modalı
  void _showAiSummaryModal(NewsItem item) {
    HapticFeedback.heavyImpact();
    final summaryFuture = _geminiService.summarizeNews(
      title: item.title,
      description: item.description,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.white.withValues(alpha: 0.35),
                      CupertinoColors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık & İkon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.sparkles,
                            color: CupertinoColors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Haber Özeti',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          minimumSize: const Size(24, 24),
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: CupertinoColors.systemGrey,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Haber Başlığı
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Canlı Gemini Özeti Alanı
                    FutureBuilder<AiSummaryResult>(
                      future: summaryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 110,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CupertinoActivityIndicator(radius: 11),
                                SizedBox(height: 8),
                                Text(
                                  'Gemini haberi analiz ediyor...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final summary = snapshot.data ?? AiSummaryResult.fallback(item.description);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryBullet('Öne Çıkan:', summary.highlight),
                              const SizedBox(height: 8),
                              _buildSummaryBullet('Puan/Yarış Etkisi:', summary.impact),
                              const SizedBox(height: 8),
                              _buildSummaryBullet('Son Durum:', summary.status),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Detaya Git Butonu
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openNewsDetail([item], 0);
                        },
                        child: const Text(
                          'Haberi Aç',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWidgets(BuildContext context) {
    final greeting = DashboardService.getGreeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. SOL BÖLÜM: Liquid Glass Hava Durumu & Günaydın
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => CustomFeedView(initialWeather: _weather),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CupertinoColors.white.withValues(alpha: 0.22),
                            CupertinoColors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            greeting,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.location_solid,
                                size: 15,
                                color: CupertinoColors.secondaryLabel,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _weather?.cityName ?? 'Konum...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _weather?.icon ?? CupertinoIcons.sun_max_fill,
                                size: 20,
                                color: const Color(0xFFFF9500),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _weather != null ? '${_weather!.temperature.round()}°C' : '--°C',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 2. SAĞ BÖLÜM: Liquid Glass F1 Sayacı
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final targetRace = _nextRace ?? NextRaceInfo.fallback();
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => RaceDetailView(race: targetRace),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CupertinoColors.white.withValues(alpha: 0.22),
                            CupertinoColors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/F1.svg/500px-F1.svg.png',
                            height: 16,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              CupertinoIcons.flag_fill,
                              size: 16,
                              color: Color(0xFFE10600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _nextRace?.countdownText ?? '1 gün 7 sa',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _nextRace?.circuitName ?? 'Pist Belirleniyor...',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8E2DE2))),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.5,
                color: CupertinoColors.label.resolveFrom(context),
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: FutureBuilder<List<NewsItem>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Haberler'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  _refreshNews();
                  _loadWeather();
                  _loadNextRace();
                },
              ),

              // Üst Liquid Glass Widget Konteynerleri
              SliverToBoxAdapter(
                child: _buildHeaderWidgets(context),
              ),

              // Liste Durumları
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                )
              else if (snapshot.hasError)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Haberler yüklenemedi.\nLütfen internet bağlantınızı kontrol edin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                    ),
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('Güncel haber bulunamadı.')),
                  )
                else
                  ..._buildNewsList(snapshot.data!),

              // Bottom pill bar'ın altında kartların gizlenmemesi için alt boşluk
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildNewsList(List<NewsItem> items) {
    final topCount = items.length > 20 ? 20 : items.length;
    final topCards = items.sublist(0, topCount);
    final remainingItems = items.sublist(topCount);

    final List<Widget> slivers = [];

    // 1. Liquid Glass Manşet Kartları
    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final item = topCards[index];
            final isSaved = _bookmarkedLinks.contains(item.link);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openNewsDetail(items, index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CupertinoColors.white.withValues(alpha: 0.24),
                            CupertinoColors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                item.imageUrl!,
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _fallbackImage(),
                              ),
                            )
                          else
                            _fallbackImage(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE10600).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  index == 0 ? 'ÖNE ÇIKAN' : 'HABER #${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Color(0xFFE10600),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _showAiSummaryModal(item),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  margin: const EdgeInsets.only(right: 2),
                                  child: const Icon(
                                    CupertinoIcons.sparkles,
                                    size: 20,
                                    color: Color(0xFF8E2DE2),
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(6),
                                onPressed: () => _shareNews(item),
                                minimumSize: const Size(32, 32),
                                child: const Icon(
                                  CupertinoIcons.share,
                                  size: 20,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(6),
                                onPressed: () => _toggleBookmark(item.link),
                                minimumSize: const Size(32, 32),
                                child: Icon(
                                  isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                  size: 20,
                                  color: isSaved ? const Color(0xFFE10600) : CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            item.pubDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.tertiaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: topCards.length,
        ),
      ),
    );

    // 2. Liquid Glass Kalan Liste (Diğer Gelişmeler)
    if (remainingItems.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CupertinoColors.white.withValues(alpha: 0.22),
                        CupertinoColors.white.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          'DİĞER GELİŞMELER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      ...remainingItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final news = entry.value;
                        final isSaved = _bookmarkedLinks.contains(news.link);
                        final itemIndex = topCount + idx;

                        return Column(
                          children: [
                            if (idx > 0)
                              Divider(
                                height: 1,
                                thickness: 0.6,
                                indent: 64,
                                endIndent: 16,
                                color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.4),
                              ),
                            CupertinoListTile(
                              backgroundColor: CupertinoColors.transparent,
                              title: Text(
                                news.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                news.pubDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              leading: news.imageUrl != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  news.imageUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _defaultIcon(),
                                ),
                              )
                                  : _defaultIcon(),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _showAiSummaryModal(news),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(
                                        CupertinoIcons.sparkles,
                                        size: 18,
                                        color: Color(0xFF8E2DE2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _shareNews(news),
                                    minimumSize: const Size(30, 30),
                                    child: const Icon(
                                      CupertinoIcons.share,
                                      size: 18,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _toggleBookmark(news.link),
                                    minimumSize: const Size(30, 30),
                                    child: Icon(
                                      isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                      size: 18,
                                      color: isSaved ? const Color(0xFFE10600) : CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _openNewsDetail(items, itemIndex),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _fallbackImage() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.photo, size: 48, color: CupertinoColors.systemGrey),
      ),
    );
  }

  Widget _defaultIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(CupertinoIcons.news, size: 22, color: CupertinoColors.systemGrey),
    );
  }
}