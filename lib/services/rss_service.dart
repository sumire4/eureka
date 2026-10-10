import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_model.dart';

class RssService {
  static const String f1FeedUrl = 'https://tr.motorsport.com/rss/f1/news/';

  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(f1FeedUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(decodedBody);
        final items = document.findAllElements('item');

        return items.map((node) {
          final title = node.findElements('title').firstOrNull?.innerText ?? '';
          final link = node.findElements('link').firstOrNull?.innerText ?? '';
          final pubDate = node.findElements('pubDate').firstOrNull?.innerText ?? '';
          // content:encoded varsa tam metni al, yoksa standart description'a düş
          final rawContent = node.findElements('content:encoded').firstOrNull?.innerText;
          final rawDesc = rawContent ?? (node.findElements('description').firstOrNull?.innerText ?? '');
          // Görsel url'sini yakalama (Motorsport enclosure kullanır)
          String? imageUrl;
          final enclosure = node.findElements('enclosure').firstOrNull;
          if (enclosure != null) {
            imageUrl = enclosure.getAttribute('url');
          }
          imageUrl ??= node.findElements('media:content').firstOrNull?.getAttribute('url');

          return NewsItem(
            title: title.trim(),
            description: _cleanHtml(rawDesc),
            link: link.trim(),
            pubDate: _formatDate(pubDate),
            imageUrl: imageUrl,
          );
        }).toList();
      } else {
        throw Exception('Haberler alınamadı: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('RSS ayrıştırma hatası: $e');
    }
  }

  // HTML taglerini temizleme
  String _cleanHtml(String htmlString) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  // Tarih metnini sadeleştirme
  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      // "Sat, 10 Oct 2026 13:00:00 +0000" gibi formatları kısaltır
      final parts = rawDate.split(' ');
      if (parts.length >= 4) {
        return '${parts[1]} ${parts[2]} ${parts[3]}';
      }
    } catch (_) {}
    return rawDate;
  }
}