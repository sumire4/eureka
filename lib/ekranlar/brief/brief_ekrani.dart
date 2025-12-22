import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class BriefEkrani extends StatefulWidget {
  const BriefEkrani({super.key, required void Function(bool scrollingDown) onScroll});

  @override
  State<BriefEkrani> createState() => _BriefEkraniState();
}

class _BriefEkraniState extends State<BriefEkrani> {
  late final WebViewController controller;
  bool isLoading = true;
  bool _isVisible = true; // Bottom bar görünürlük durumu
  double _lastScrollPosition = 0;

  final List<String> adBlockList = [
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'amazon-adsystem.com', 'facebook.com/tr', 'google-analytics.com',
    'googletagmanager.com', 'adsystem.com', 'ads.yahoo.com', 'bing.com/rdr',
    'outbrain.com', 'taboola.com', 'criteo.com', 'adnxs.com', 'rubiconproject.com',
    'pubmatic.com', 'openx.net', 'advertising.com', 'ads.twitter.com',
  ];

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'ScrollChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final scrollPosition = double.tryParse(message.message);
          if (scrollPosition != null) {
            if (scrollPosition > _lastScrollPosition + 10 && _isVisible) {
              setState(() => _isVisible = false);
            } else if (scrollPosition < _lastScrollPosition - 10 && !_isVisible) {
              setState(() => _isVisible = true);
            }
            _lastScrollPosition = scrollPosition;
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (_) {},
          onPageStarted: (_) => setState(() { isLoading = true; _isVisible = true; }),
          onPageFinished: (_) {
            setState(() => isLoading = false);
            _injectAdBlockCSS();
            _injectScrollListener();
          },
          onWebResourceError: (_) {},
          onNavigationRequest: (request) {
            for (var adDomain in adBlockList) {
              if (request.url.contains(adDomain)) return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.f1tr.com/2025.php'));
  }

  void _injectScrollListener() {
    controller.runJavaScript('''
      var lastScrollY = window.scrollY;
      var threshold = 10;
      window.addEventListener('scroll', function() {
        var currentY = window.scrollY;
        if (Math.abs(currentY - lastScrollY) > threshold) {
          ScrollChannel.postMessage(currentY.toString());
        }
        lastScrollY = currentY;
      });
    ''');
  }

  void _injectAdBlockCSS() {
    controller.runJavaScript('''
      var adSelectors = [
        '[id*="ad"]','[class*="ad"]','[id*="banner"]','[class*="banner"]',
        '[id*="sponsor"]','[class*="sponsor"]','.advertisement','.ads',
        '.ad-container','.banner-ad','.google-ad','.adsense',
        'iframe[src*="doubleclick"]','iframe[src*="googlesyndication"]',
        'iframe[src*="amazon-adsystem"]','div[id*="google_ads"]',
        'div[class*="google_ads"]','.outbrain','.taboola','.criteo'
      ];
      var style = document.createElement('style');
      style.innerHTML = adSelectors.join(', ') + ' { display: none !important; visibility: hidden !important; }';
      document.head.appendChild(style);
      var observer = new MutationObserver(function(mutations){
        mutations.forEach(function(mutation){
          mutation.addedNodes.forEach(function(node){
            if(node.nodeType === 1){
              adSelectors.forEach(function(selector){
                try {
                  var elements = node.querySelectorAll ? node.querySelectorAll(selector) : [];
                  elements.forEach(function(el){ el.style.display='none'; el.style.visibility='hidden'; });
                } catch(e){}
              });
            }
          });
        });
      });
      observer.observe(document.body,{childList:true,subtree:true});
      window.open = function() { return null; };
      window.alert = function() { return null; };
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Container(
              color: colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(colorScheme.primary)),
                    const SizedBox(height: 16),
                    Text('Yükleniyor...', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async { if(await controller.canGoBack()) controller.goBack(); },
              ),
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () { controller.loadRequest(Uri.parse('https://www.f1tr.com/2025.php')); },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _showYearSelection,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _showManualUrlDialog,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showManualUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Video URL\'sini Girin'),
        content: TextField(controller: urlController, decoration: const InputDecoration(hintText:'Video URL\'si...',border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: (){ Navigator.pop(context); }, child: const Text('İptal')),
          ElevatedButton(onPressed: (){
            final url = urlController.text.trim();
            if(url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))){
              Navigator.pop(context);
              _startDownload(url);
            }
          }, child: const Text('İndir'))
        ],
      ),
    );
  }

  void _startDownload(String url) async {
    final colorScheme = Theme.of(context).colorScheme;
    var status = await Permission.manageExternalStorage.request();
    if(!status.isGranted) return;

    Directory? downloadDir;
    if(Platform.isAndroid){
      downloadDir = Directory('/storage/emulated/0/Download');
      if(!await downloadDir.exists()){
        downloadDir = await getExternalStorageDirectory();
        if(downloadDir != null){
          downloadDir = Directory('${downloadDir.path.split("Android")[0]}Download');
        }
      }
    } else {
      downloadDir = await getApplicationDocumentsDirectory();
    }

    if(downloadDir == null) return;
    if(!await downloadDir.exists()) await downloadDir.create(recursive: true);

    final fileName = 'F1_Video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final savePath = '${downloadDir.path}/$fileName';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Video İndiriliyor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(colorScheme.primary)),
            const SizedBox(height: 16),
            Text('$fileName indiriliyor...'),
          ],
        ),
      ),
    );

    try {
      await Dio().download(url, savePath);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video başarıyla indirildi: $savePath'), backgroundColor: Colors.green),
      );
    } catch(e){
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirme hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showYearSelection() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sezon Seçin', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
            const SizedBox(height:16),
            Expanded(
              child: ListView.builder(
                shrinkWrap:true,
                itemCount: 2025-1978+1,
                itemBuilder: (context,index){
                  final year = 2025 - index;
                  return ListTile(
                    leading: Icon(year==2025?Icons.star:Icons.calendar_today,color: colorScheme.primary),
                    title: Text('$year Sezonu', style: TextStyle(color: colorScheme.onSurface)),
                    subtitle: year==2025?const Text('Güncel sezon'):null,
                    onTap: (){
                      Navigator.pop(context);
                      controller.loadRequest(Uri.parse('https://www.f1tr.com/$year.php'));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
