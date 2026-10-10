import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_model.dart';
import '../../services/rss_service.dart';
import 'news_detail_view.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  final RssService _rssService = RssService();
  late Future<List<NewsItem>> _newsFuture;

  // Kaydedilen haberlerin linklerini tutan set
  final Set<String> _bookmarkedLinks = {};

  @override
  void initState() {
    super.initState();
    _refreshNews();
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
    Share.share(
      '${item.title}\n\nDetaylar: ${item.link}',
      subject: item.title,
    );
  }

  // Gemini Basılı Tutma Popup Menüsü
  void _showAiSummaryModal(NewsItem item) {
    HapticFeedback.heavyImpact(); // Basılı tutulduğunda iOS haptic titreşimi
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.18),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık & Gemini Rozeti
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Gemini moru/mavisi
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                      'Eureka AI Özeti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 24,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: CupertinoColors.systemGrey3,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Haber Başlığı Küçük
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

                // AI Özeti Kutusu (3 Maddede hap bilgi)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryBullet(
                        'Öne Çıkan:',
                        item.description.isNotEmpty
                            ? (item.description.length > 90
                            ? '${item.description.substring(0, 90)}...'
                            : item.description)
                            : 'Gelişmeler teknik ekip tarafından doğrulandı.',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryBullet(
                        'Puan/Yarış Etkisi:',
                        'Hafta sonundaki yarış stratejilerini doğrudan değiştirebilir.',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryBullet(
                        'Son Durum:',
                        'Mühendisler ve pilotlar arasındaki toplantılar devam ediyor.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Detaya Git Butonu
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(12),
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
              style: const TextStyle(fontSize: 12.5, color: CupertinoColors.label, height: 1.3),
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
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Haberler'),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async => _refreshNews(),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Haberler yüklenemedi.\nLütfen internet bağlantınızı kontrol edin.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CupertinoColors.destructiveRed),
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

    // 1. BÖLÜM: İlk 20 Büyük Manşet Kartı
    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final item = topCards[index];
            final isSaved = _bookmarkedLinks.contains(item.link);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () => _openNewsDetail(items, index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görsel
                      if (item.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrl!,
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackImage(),
                          ),
                        )
                      else
                        _fallbackImage(),
                      const SizedBox(height: 12),

                      // Üst Etiket & Aksiyon Butonları (Gemini AI, Paylaş, Kaydet)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE10600).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
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

                          // Gemini AI İkonu (Tıklanınca ipucu, Basılı tutunca Özet)
                          GestureDetector(
                            onLongPress: () => _showAiSummaryModal(item),
                            onTap: () => _showAiSummaryModal(item), // Kullanım kolaylığı için tek tıkta da açılır
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(right: 2),
                              child: const Icon(
                                CupertinoIcons.sparkles,
                                size: 20,
                                color: Color(0xFF8E2DE2), // Gemini Gradient rengi
                              ),
                            ),
                          ),

                          // Paylaş Butonu
                          CupertinoButton(
                            padding: const EdgeInsets.all(6),
                            minSize: 32,
                            onPressed: () => _shareNews(item),
                            child: const Icon(
                              CupertinoIcons.share,
                              size: 20,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),

                          // Kaydet Butonu
                          CupertinoButton(
                            padding: const EdgeInsets.all(6),
                            minSize: 32,
                            onPressed: () => _toggleBookmark(item.link),
                            child: Icon(
                              isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                              size: 20,
                              color: isSaved ? const Color(0xFFE10600) : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Başlık
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
                        '${item.pubDate} • Motorsport TR',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: topCards.length,
        ),
      ),
    );

    // 2. BÖLÜM: Kalan Kompakt Liste
    if (remainingItems.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            header: const Text('DİĞER GELİŞMELER'),
            children: remainingItems.map((news) {
              final isSaved = _bookmarkedLinks.contains(news.link);
              final itemIndex = topCount + remainingItems.indexOf(news);

              return CupertinoListTile(
                title: Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${news.pubDate} • Motorsport TR',
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
                    errorBuilder: (_, __, ___) => _defaultIcon(),
                  ),
                )
                    : _defaultIcon(),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gemini AI Butonu
                    GestureDetector(
                      onLongPress: () => _showAiSummaryModal(news),
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
                    // Paylaş
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 30,
                      onPressed: () => _shareNews(news),
                      child: const Icon(
                        CupertinoIcons.share,
                        size: 18,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Kaydet
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 30,
                      onPressed: () => _toggleBookmark(news.link),
                      child: Icon(
                        isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                        size: 18,
                        color: isSaved ? const Color(0xFFE10600) : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
                onTap: () => _openNewsDetail(items, itemIndex),
              );
            }).toList(),
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
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(12),
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
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(CupertinoIcons.news, size: 22, color: CupertinoColors.systemGrey),
    );
  }
}