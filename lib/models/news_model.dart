class NewsItem {
  final String title;
  final String description;
  final String link;
  final String pubDate;
  final String? imageUrl;

  NewsItem({
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
    this.imageUrl,
  });
}