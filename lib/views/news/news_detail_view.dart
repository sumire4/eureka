import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url.trim());
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  // Figma iOS 27 Sheet: Canlı Web Sitesi Önizleme Modalı
  void _openFigmaWebSheet(String url, String newsTitle) {
    HapticFeedback.mediumImpact();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _Ios27FullWebSheet(
        url: url.trim(),
        title: newsTitle,
        onOpenExternal: () => _launchExternalUrl(url),
      ),
    );
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
              setState(() => _isDarkMode = !_isDarkMode);
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
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final item = widget.allNews[index];
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          height: 230,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackImage(),
                        ),
                      )
                    else
                      _fallbackImage(),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE10600).withValues(alpha: 0.12),
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
                          style: TextStyle(fontSize: 12, color: secondaryTextColor),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

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

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Tıklandığında direkt canlı web sayfası sheet'i açılır
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _openFigmaWebSheet(item.link, item.title),
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
                                      color: const Color(0xFFE10600).withValues(alpha: 0.12),
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
                                          'Haberin web önizlemesini aç',
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

// -------------------------------------------------------------
// GÜNCELLENMİŞ FIGMA IOS 27 SHEETS (MODALS) BAŞLIK VE BUTONLARI
// -------------------------------------------------------------
class _Ios27FullWebSheet extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback onOpenExternal;

  const _Ios27FullWebSheet({
    required this.url,
    required this.title,
    required this.onOpenExternal,
  });

  @override
  State<_Ios27FullWebSheet> createState() => _Ios27FullWebSheetState();
}

class _Ios27FullWebSheetState extends State<_Ios27FullWebSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final double sheetHeight = mediaQuery.size.height * 0.92;

    final sheetBg = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.96)
        : CupertinoColors.white.withValues(alpha: 0.98);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26.0)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.25),
                blurRadius: 35,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Üst Tutamaç (Grabber)
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                child: Center(
                  child: Container(
                    width: 60.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                ),
              ),

              // 2. Başlık ve İkonlar Çubuğu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Sol: Kapatma Butonu (44x44 Cam Kapsül)
                    _FigmaGlassButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 17,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),

                    // Orta: Kısa, Ferah ve İki Taraftan Boşluklu Başlık
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Butonlarla ara mesafe artırıldı
                        child: Text(
                          'Haber Kaynağı', // Kısa ve temiz başlık
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                    ),

                    // Sağ: Mavi Dolgusuz, Genişletilmiş Safari Pusula İkonu
                    _FigmaGlassButton(
                      onTap: widget.onOpenExternal,
                      child: const Icon(
                        CupertinoIcons.compass,
                        size: 23, // İkon büyütüldü ve daha geniş hale getirildi
                        color: Color(0xFF007AFF), // Apple Safari Mavi çizgi rengi
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 0.8,
                thickness: 0.6,
                color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.4),
              ),

              // 3. Web Sitesi
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: sheetBg,
                        child: const Center(
                          child: CupertinoActivityIndicator(radius: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// FIGMA LIQUID GLASS BUTON (44x44px Nötr Cam Efekti)
// -------------------------------------------------------------
class _FigmaGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _FigmaGlassButton({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF2C2C2E).withValues(alpha: 0.8)
        : const Color(0xFFE5E5EA).withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE6E6E6).withValues(alpha: isDark ? 0.25 : 0.6),
              const Color(0xFF282828).withValues(alpha: isDark ? 0.35 : 0.05),
            ],
          ),
          border: Border.all(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.15)
                : CupertinoColors.white.withValues(alpha: 0.8),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}