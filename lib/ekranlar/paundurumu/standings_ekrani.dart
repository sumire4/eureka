
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StandingsEkrani extends StatefulWidget {
  final Function(bool)? onScroll;
  const StandingsEkrani({super.key, this.onScroll});

  @override
  State<StandingsEkrani> createState() => _StandingsEkraniState();
}

class _StandingsEkraniState extends State<StandingsEkrani> {
  late final WebViewController controller;
  bool isLoading = true;
  int _selectedIndex = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ScrollChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'hide') {
            if (_isVisible) {
              setState(() {
                _isVisible = false;
              });
              if (widget.onScroll != null) {
                widget.onScroll!(true);
              }
            }
          } else if (message.message == 'show') {
            if (!_isVisible) {
              setState(() {
                _isVisible = true;
              });
              if (widget.onScroll != null) {
                widget.onScroll!(false);
              }
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });

            // formula1.com sayfasındaki gereksiz elementleri gizlemek ve popup'ları engellemek için JS
            controller.runJavaScript('''
              const selectorsToHide = [
                'footer',
                '.site-footer',
                '.f1-footer',
                '.f1-site-footer',
                '.f1-global-footer',
                '.cookie-banner',
                '#onetrust-banner-sdk',
                '#onetrust-consent-sdk',
                '.ot-sdk-show-settings',
                '.ot-floating-button',
                '.truste_overlay',
                '#truste-consent-track',
                '.consent-overlay',
                '.subscription',
                '.subscribe',
                '[class*="subscribe"]',
                '[class*="consent"]',
                '[class*="cookie"]',
                '[class*="gdpr"]',
                '.newsletter',
                '.promo',
                '.promotion',
                '.advert',
                '.advertisement',
                '.ad-container',
                '[class*="ad-"]',
                '[id*="ad-"]',
                '.banner-ad',
                '[class*="banner"]',
                '[class*="popup"]',
                '[class*="modal"]',
                '[role="dialog"]',
                '.overlay',
                '.modal-overlay',
                '.backdrop',
                // iframe reklamları
                'iframe[src*="doubleclick"]',
                'iframe[src*="googlesyndication"]',
                'iframe[src*="amazon-adsystem"]',
                'iframe[src*="googletagmanager"]'
              ];
              
              selectorsToHide.forEach(selector => {
                const elements = document.querySelectorAll(selector);
                elements.forEach(el => el.style.display = 'none');  
              });

              document.body.style.marginTop = '0px';
              document.body.style.backgroundColor = 'white';

              

              

              // Yeni sekme/popup açılmasını engelle
              window.open = function(url) {
                if (url) { location.href = url; }
                return null;
              };
              const anchors = Array.from(document.querySelectorAll('a[target="_blank"]'));
              anchors.forEach(a => { a.removeAttribute('target'); });

              // Yatay taşmayı engelle
              document.documentElement.style.overflowX = 'hidden';
              document.body.style.overflowX = 'hidden';

              // NATIONALITY sütununu gizle (başlık metnine göre index'i bul)
              const hideNationalityColumn = () => {
                const tables = Array.from(document.querySelectorAll('table'));
                tables.forEach(tbl => {
                  const thead = tbl.querySelector('thead');
                  const headerCells = thead ? Array.from(thead.querySelectorAll('th')) : [];
                  let nationalityIndex = -1;
                  headerCells.forEach((th, idx) => {
                    const text = (th.textContent || '').trim().toUpperCase();
                    if (text.includes('NATIONALITY')) {
                      nationalityIndex = idx;
                    }
                  });
                  if (nationalityIndex >= 0) {
                    // Başlığı gizle
                    if (headerCells[nationalityIndex]) {
                      headerCells[nationalityIndex].style.display = 'none';
                    }
                    // Gövde hücrelerini gizle
                    const rows = Array.from(tbl.querySelectorAll('tbody tr'));
                    rows.forEach(tr => {
                      const tds = tr.querySelectorAll('td');
                      if (tds[nationalityIndex]) {
                        tds[nationalityIndex].style.display = 'none';
                      }
                    });
                    // Tablo genişliğini otomatiğe al
                    tbl.style.width = '100%';
                  }
                });
              };
              hideNationalityColumn();
              // Dinamik içerik geç gelirse tekrar dene
              setTimeout(hideNationalityColumn, 800);
              setTimeout(hideNationalityColumn, 1600);

              

              
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            final allow = request.url.startsWith('https://www.formula1.com/');
            return allow ? NavigationDecision.navigate : NavigationDecision.prevent;
          },
        ),
      )
    // formula1.com F1 2025 sürücüler puan durumu
      ..loadRequest(Uri.parse('https://www.formula1.com/en/results/2025/drivers'));
  }

  void _onTogglePressed(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final urls = [
      'https://www.formula1.com/en/results/2025/drivers', // Sürücüler
      'https://www.formula1.com/en/results/2025/team', // Takımlar
    ];

    controller.loadRequest(Uri.parse(urls[index]));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE10600)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Puan durumu yükleniyor...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

    );
  }
}
