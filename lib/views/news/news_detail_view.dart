import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_model.dart';

class NewsDetailView extends StatefulWidget {
  final List<NewsItem> allNews;
  final int initialIndex;

  const NewsDetailView({
    super.key,
    required this.allNews,
    required this.initialIndex,
  });

  @override
  State<NewsDetailView> createState() => _NewsDetailViewState();
}

class _NewsDetailViewState extends State<NewsDetailView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openFullArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _isDarkMode ? Brightness.dark : Brightness.light;
    final bgColor = _isDarkMode
        ? CupertinoColors.black
        : CupertinoColors.systemGroupedBackground;
    final cardColor = _isDarkMode
        ? const Color(0xFF1C1C1E)
        : CupertinoColors.white;
    final textColor = _isDarkMode
        ? CupertinoColors.white
        : CupertinoColors.black;
    final secondaryTextColor = _isDarkMode
        ? CupertinoColors.systemGrey
        : CupertinoColors.secondaryLabel;
    final buttonBg = _isDarkMode
        ? const Color(0xFF2C2C2E)
        : CupertinoColors.systemGrey6;

    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: bgColor,
        barBackgroundColor: _isDarkMode
            ? const Color(0xCC1C1C1E)
            : const Color(0xCCFFFFFF),
      ),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.back, size: 26),
                Text('Haberler', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          middle: Text(
            '${_currentIndex + 1} / ${widget.allNews.length}',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            child: Icon(
              _isDarkMode ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
              size: 22,
              color: _isDarkMode
                  ? CupertinoColors.systemYellow
                  : CupertinoColors.systemIndigo,
            ),
          ),
        ),
        child: NotificationListener<OverscrollNotification>(
          onNotification: (overscroll) {
            if (_currentIndex == 0 && overscroll.overscroll < -15) {
              Navigator.of(context).pop();
              return true;
            }
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.allNews.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.allNews[index];
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Manşet Görseli
                    if (item.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          height: 230,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackImage(),
                        ),
                      )
                    else
                      _fallbackImage(),

                    const SizedBox(height: 16),

                    // Üst Etiket & Tarih
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE10600).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'MOTORSPORT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE10600),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.pubDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Başlık (Büyük iOS Tipografisi)
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.6,
                        height: 1.25,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Okuma Alanı (Safari Reader Stili Kart)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Metnin tamamı: Satır kısıtlaması yok, rahat satır yüksekliği
                          SelectableText(
                            item.description.isNotEmpty
                                ? item.description
                                : 'Haber detayı için aşağıdaki kaynaktan orijinal içeriği inceleyebilirsiniz.',
                            style: TextStyle(
                              fontSize: 16.5,
                              height: 1.6,
                              letterSpacing: -0.2,
                              color: textColor.withValues(alpha: 0.92),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // iOS Tarzı Minimalist "Kaynağa Git" Aksiyon Butonu
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _openFullArticle(item.link),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: buttonBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE10600).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.compass,
                                      size: 16,
                                      color: Color(0xFFE10600),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Motorsport Türkiye',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          'Haberin orijinal kaynağını aç',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_forward,
                                    size: 16,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.photo, size: 54, color: CupertinoColors.systemGrey),
      ),
    );
  }
}