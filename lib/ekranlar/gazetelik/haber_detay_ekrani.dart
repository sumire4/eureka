import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rss_dart/dart_rss.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HaberDetayEkrani extends StatefulWidget {
  final List<RssItem> tumHaberler; // Tüm haberler listesi
  final int baslangicIndex; // Başlangıç indexi

  const HaberDetayEkrani({
    Key? key,
    required this.tumHaberler,
    required this.baslangicIndex, required RssItem haber,
  }) : super(key: key);

  @override
  State<HaberDetayEkrani> createState() => _HaberDetayEkraniState();
}

class _HaberDetayEkraniState extends State<HaberDetayEkrani> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  Map<int, String?> _htmlContents = {}; // Her haber için HTML içeriği cache
  Map<int, bool> _loadingStates = {}; // Her haber için loading durumu
  bool _amoledMode = false; // AMOLED dark mode

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.baslangicIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Animasyon controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // İlk haberin içeriğini yükle
    _loadFullArticle(_currentIndex);
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAmoledMode() {
    setState(() {
      _amoledMode = !_amoledMode;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Yeni sayfanın içeriğini yükle
    if (!_htmlContents.containsKey(index)) {
      _loadFullArticle(index);
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Fade animasyonu
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _loadFullArticle(int index) async {
    final haber = widget.tumHaberler[index];
    final link = haber.link;
    final desc = haber.description ?? '';

    setState(() {
      _loadingStates[index] = true;
    });

    if (link != null && link.isNotEmpty) {
      try {
        print('🔄 Makale yükleniyor: $link');

        // Mercury Parser benzeri yaklaşım
        final content = await _extractContentMercuryStyle(link);

        if (content.isNotEmpty && content.length > desc.length) {
          setState(() {
            _htmlContents[index] = content;
            _loadingStates[index] = false;
          });
          return;
        }

        print('⚠️ Mercury-style extraction başarısız, fallback deneniyor...');

      } catch (e) {
        print('❌ Extraction hatası: $e');
      }
    }

    // Fallback: RSS description
    setState(() {
      _htmlContents[index] = desc.isNotEmpty ? _cleanContent(desc) : '<p>İçerik yüklenemedi.</p>';
      _loadingStates[index] = false;
    });
  }

  /// Mercury Parser tarzında content extraction
  Future<String> _extractContentMercuryStyle(String url) async {
    // Readability.js benzeri header'lar
    final headers = {
      'User-Agent': 'Mozilla/5.0 (compatible; CapyReader/1.0; +https://github.com/jocmp/capyreader)',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ HTML alındı: ${response.body.length} bytes');
        return await _parseWithReadabilityAlgorithm(response.body, url);
      }

      print('❌ HTTP ${response.statusCode}');
    } catch (e) {
      print('❌ Request hatası: $e');
    }

    return '';
  }

  /// Mozilla Readability.js algoritmasının basitleştirilmiş versiyonu
  Future<String> _parseWithReadabilityAlgorithm(String html, String baseUrl) async {
    final doc = html_parser.parse(html);

    // 1. PREPARATION: Gereksiz elementleri temizle
    _removeUnlikelyElements(doc);
    _cleanConditionally(doc);

    // 2. SCORING: Elementleri skorla
    final candidates = _scoreElements(doc);

    // 3. SELECT: En iyi adayı seç
    final bestCandidate = _selectBestCandidate(candidates);

    if (bestCandidate != null) {
      print('🎯 En iyi aday bulundu: ${bestCandidate.element.localName} (${bestCandidate.score} puan)');

      // 4. POST-PROCESS: İçeriği temizle ve formatla
      final content = _postProcessContent(bestCandidate.element, baseUrl);

      print('📝 İçerik uzunluğu: ${content.length} chars');
      return content;
    }

    print('❌ Uygun aday bulunamadı');
    return '';
  }

  /// Readability: Unlikely elementleri kaldır
  void _removeUnlikelyElements(dom.Document doc) {
    final unlikelyCandidates = RegExp(
        r'banner|breadcrumbs|combx|comment|community|cover-wrap|disqus|extra|foot|header|legends|menu|related|remark|replies|rss|shoutbox|sidebar|skyscraper|social|sponsor|supplemental|ad-break|agegate|pagination|pager|popup|yom-remote',
        caseSensitive: false
    );

    final okMaybeItsACandidate = RegExp(
        r'and|article|body|column|main|shadow',
        caseSensitive: false
    );

    doc.querySelectorAll('*').forEach((element) {
      final classAndId = '${element.className} ${element.id}';

      if (unlikelyCandidates.hasMatch(classAndId) &&
          !okMaybeItsACandidate.hasMatch(classAndId)) {
        element.remove();
      }
    });
  }

  /// Readability: Koşullu temizlik
  void _cleanConditionally(dom.Document doc) {
    final tagsToScore = ['p', 'td', 'pre'];

    doc.querySelectorAll('table,ul,div').forEach((element) {
      final weight = _getClassWeight(element);

      if (weight < 0) {
        element.remove();
        return;
      }

      if (_getCharCount(element, ',') < 10) {
        final p = element.querySelectorAll('p').length;
        final img = element.querySelectorAll('img').length;
        final li = element.querySelectorAll('li').length - 100;
        final input = element.querySelectorAll('input').length;

        final embedCount = element.querySelectorAll('embed').length;
        final linkDensity = _getLinkDensity(element);
        final contentLength = element.text.trim().length;

        if ((img > 1 && p / img.toDouble() < 0.5 && !_hasAncestorTag(element, 'figure')) ||
            (!tagsToScore.contains(element.localName) && li > p) ||
            (input > (p / 3).floor()) ||
            (!tagsToScore.contains(element.localName) && contentLength < 25 && (img == 0 || img > 2) && !_hasAncestorTag(element, 'figure')) ||
            (!tagsToScore.contains(element.localName) && weight < 25 && linkDensity > 0.2) ||
            (weight >= 25 && linkDensity > 0.5) ||
            ((embedCount == 1 && contentLength < 75) || embedCount > 1)) {
          element.remove();
        }
      }
    });
  }

  /// Element skorlama (Readability algoritması)
  List<_ScoredElement> _scoreElements(dom.Document doc) {
    final candidates = <_ScoredElement>[];

    doc.querySelectorAll('p,td,pre').forEach((element) {
      final parentNode = element.parent;
      final grandParentNode = parentNode?.parent;
      final innerText = element.text.trim();

      if (innerText.length < 25) return;

      // İçerik skoru hesapla
      double contentScore = 1.0;
      contentScore += innerText.split(',').length;
      contentScore += (innerText.length / 100).clamp(0, 3);

      // Parent node'a skor ekle
      if (parentNode != null) {
        _addScoreToElement(candidates, parentNode, contentScore);

        // Grandparent'a yarım skor
        if (grandParentNode != null) {
          _addScoreToElement(candidates, grandParentNode, contentScore / 2);
        }
      }
    });

    // Tag-based bonuslar
    for (final candidate in candidates) {
      final element = candidate.element;
      double score = candidate.score;

      score *= _getElementMultiplier(element);
      score += _getClassWeight(element);

      candidate.score = score;
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  void _addScoreToElement(List<_ScoredElement> candidates, dom.Element element, double score) {
    final existing = candidates.firstWhere(
          (c) => c.element == element,
      orElse: () {
        final newCandidate = _ScoredElement(element, 0);
        candidates.add(newCandidate);
        return newCandidate;
      },
    );
    existing.score += score;
  }

  _ScoredElement? _selectBestCandidate(List<_ScoredElement> candidates) {
    if (candidates.isEmpty) return null;

    final topCandidate = candidates.first;
    print('🏆 En iyi aday: ${topCandidate.element.localName}.${topCandidate.element.className} (${topCandidate.score.toStringAsFixed(1)})');

    // Alternative'leri kontrol et
    final alternativeCandidateAncestors = <dom.Element>[];
    for (int i = 1; i < candidates.length && i < 5; i++) {
      final candidate = candidates[i];
      if (candidate.score / topCandidate.score >= 0.75) {
        alternativeCandidateAncestors.add(candidate.element);
      }
    }

    return topCandidate;
  }

  String _postProcessContent(dom.Element element, String baseUrl) {
    // Gereksiz elementleri kaldır
    element.querySelectorAll('script,noscript,style,object,embed,iframe,link,meta').forEach((e) => e.remove());

    // Sosyal medya ve reklam elementlerini kaldır
    element.querySelectorAll('[class*="social"],[class*="share"],[class*="tweet"],[class*="facebook"],[class*="twitter"],[id*="social"],[class*="ad"],[id*="ad"]').forEach((e) => e.remove());

    // Boş paragrafları kaldır
    element.querySelectorAll('p').forEach((p) {
      if (p.text.trim().isEmpty) p.remove();
    });

    // Link density yüksek olan elementleri kaldır
    element.querySelectorAll('div,section,header,footer,aside').forEach((e) {
      if (_getLinkDensity(e) > 0.8) e.remove();
    });

    // Relative URL'leri absolute'a çevir
    element.querySelectorAll('img').forEach((img) {
      final src = img.attributes['src'];
      if (src != null && src.startsWith('/')) {
        final uri = Uri.parse(baseUrl);
        img.attributes['src'] = '${uri.scheme}://${uri.host}$src';
      }
    });

    return element.innerHtml;
  }

  // Helper methods
  int _getClassWeight(dom.Element element) {
    int weight = 0;
    final className = element.className.toLowerCase();
    final id = element.id.toLowerCase();

    if (RegExp(r'negative|hentry|comment|discuss|disqus|foot|header|menu|meta|nav|pager|sidebar|sponsor|ad').hasMatch(className)) {
      weight -= 25;
    }

    if (RegExp(r'article|body|content|entry|hentry|main|page|pagination|post|text|blog|story').hasMatch(className)) {
      weight += 25;
    }

    if (RegExp(r'negative|comment|discuss|disqus|foot|header|menu|meta|nav|pager|sidebar|sponsor|ad').hasMatch(id)) {
      weight -= 25;
    }

    if (RegExp(r'article|body|content|entry|hentry|main|page|pagination|post|text|blog|story').hasMatch(id)) {
      weight += 25;
    }

    return weight;
  }

  double _getElementMultiplier(dom.Element element) {
    switch (element.localName?.toLowerCase()) {
      case 'div': return 5;
      case 'pre': case 'td': case 'blockquote': return 3;
      case 'address': case 'ol': case 'ul': case 'dl': case 'dd': case 'dt': case 'li': case 'form': return -3;
      case 'h1': case 'h2': case 'h3': case 'h4': case 'h5': case 'h6': case 'th': return -5;
      default: return 0;
    }
  }

  int _getCharCount(dom.Element element, String char) {
    return char.allMatches(element.text).length;
  }

  double _getLinkDensity(dom.Element element) {
    final textLength = element.text.length;
    if (textLength == 0) return 0;

    final linkLength = element.querySelectorAll('a').fold<int>(0, (sum, link) => sum + link.text.length);
    return linkLength / textLength;
  }

  bool _hasAncestorTag(dom.Element element, String tagName) {
    dom.Element? parent = element.parent;
    while (parent != null) {
      if (parent.localName?.toLowerCase() == tagName.toLowerCase()) return true;
      parent = parent.parent;
    }
    return false;
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'Okumaya devam et.*|Devamını oku.*|Continue reading.*|Read more.*', caseSensitive: false), '')
        .trim();
  }

  Widget _buildNewsContent(RssItem haber, int index) {
    final imageUrl = haber.enclosure?.url;
    final isLoading = _loadingStates[index] ?? true;
    final htmlContent = _htmlContents[index];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                haber.title ?? 'Başlık Yok',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: _amoledMode ? Colors.white : null,
                ),
              ),
            ),

            if (haber.pubDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                      Icons.access_time,
                      size: 16,
                      color: _amoledMode ? Colors.grey[400] : Colors.grey[600]
                  ),
                  const SizedBox(width: 6),
                  Text(
                    haber.pubDate!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _amoledMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (htmlContent != null && htmlContent.isNotEmpty)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Html(
                  data: htmlContent,
                  onLinkTap: (url, _, __) {
                    if (url != null) _launchURL(url);
                  },
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: _amoledMode ? Colors.white : null,
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 16),
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.6),
                      textAlign: TextAlign.justify,
                      color: _amoledMode ? Colors.white : null,
                    ),
                    'h1,h2,h3,h4,h5,h6': Style(
                      margin: Margins.only(top: 20, bottom: 10),
                      fontWeight: FontWeight.bold,
                      color: _amoledMode ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    'img': Style(
                      width: Width(double.infinity),
                      margin: Margins.symmetric(vertical: 12),
                    ),
                    'blockquote': Style(
                      margin: Margins.symmetric(vertical: 16, horizontal: 20),
                      padding: HtmlPaddings.only(left: 16),
                      border: Border(left: BorderSide(color: _amoledMode ? Colors.grey[600]! : Colors.grey, width: 4)),
                      fontStyle: FontStyle.italic,
                      color: _amoledMode ? Colors.grey[300] : null,
                    ),
                    'a': Style(
                      color: _amoledMode ? Colors.blue[300] : null,
                    ),
                  },
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: _amoledMode ? Colors.grey[600] : Colors.grey[400]
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tam içerik yüklenemedi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _amoledMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => haber.link != null ? _launchURL(haber.link!) : null,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Orijinal haberi aç'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentHaber = widget.tumHaberler[_currentIndex];

    return Theme(
      data: _amoledMode
          ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      )
          : Theme.of(context),
      child: Scaffold(
        backgroundColor: _amoledMode ? Colors.black : null,
        appBar: AppBar(
          title: Text(currentHaber.title ?? 'Haber Detayı'),
          elevation: 0,
          backgroundColor: _amoledMode ? Colors.black : null,
          foregroundColor: _amoledMode ? Colors.white : null,
          actions: [
            // AMOLED mod butonu
            IconButton(
              icon: Icon(_amoledMode ? Icons.brightness_7 : Icons.brightness_2),
              onPressed: _toggleAmoledMode,
              tooltip: _amoledMode ? 'Açık moda geç' : 'AMOLED moda geç',
            ),
            // Tarayıcıda aç butonu
            if (currentHaber.link != null)
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                onPressed: () => _launchURL(currentHaber.link!),
                tooltip: 'Orijinal haberi aç',
              ),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.tumHaberler.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildNewsContent(widget.tumHaberler[index], index);
          },
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('URL açılamadı: $e');
    }
  }
}

class _ScoredElement {
  final dom.Element element;
  double score;

  _ScoredElement(this.element, this.score);
}