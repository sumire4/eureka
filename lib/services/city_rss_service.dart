class CityRssService {
  static final _cityFeeds = {
    'istanbul': [
      {'name': 'İHA İstanbul', 'url': 'https://www.iha.com.tr/rss/istanbul'},
      {'name': 'DHA İstanbul', 'url': 'https://www.dha.com.tr/rss/istanbul'},
    ],
    'ankara': [
      {'name': 'İHA Ankara', 'url': 'https://www.iha.com.tr/rss/ankara'},
      {'name': 'Ankara Masası', 'url': 'https://www.ankaramasasi.com/rss'},
    ],
    'izmir': [
      {'name': 'İHA İzmir', 'url': 'https://www.iha.com.tr/rss/izmir'},
      {'name': 'Ege Postası', 'url': 'https://www.egepostasi.com/rss'},
    ],
    'elazig': [
      {'name': 'Kanal 23', 'url': 'https://www.gzt23.com/rss'},
      {'name': 'Günışığı Gazetesi', 'url': 'https://www.gunisigigazetesi.net/rss.xml'},
      {'name': 'Elazığ Hakimiyet', 'url': 'https://www.elazighakimiyethaber.com/rss/'},
    ],
    'bursa': [
      {'name': 'Olay Bursa', 'url': 'https://www.olay.com.tr/rss'},
      {'name': 'Bursa Hakimiyet', 'url': 'https://www.bursahakimiyet.com.tr/rss'},
    ],
    'antalya': [
      {'name': 'İHA Antalya', 'url': 'https://www.iha.com.tr/rss/antalya'},
      {'name': 'Antalya Körfez', 'url': 'https://antalyakorfez.com/rss'},
    ],
  };

  // 403 hatası vermeyen güvenilir genel yedek akışlar
  static final _fallbackFeeds = [
    {'name': 'TRT Gündem', 'url': 'https://www.trthaber.com/gundem_articles.rss'},
    {'name': 'Anadolu Ajansı', 'url': 'https://www.aa.com.tr/tr/rss/default?cat=guncel'},
  ];

  static List getFeedsForCity(String? rawCity) {
    if (rawCity == null || rawCity.trim().isEmpty) {
      return _fallbackFeeds;
    }

    // Şapkalı harfler ve Türkçe karakter normalizasyonu
    final normalized = rawCity
        .toLowerCase()
        .trim()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');

    for (var key in _cityFeeds.keys) {
      if (normalized.contains(key)) {
        return _cityFeeds[key]!;
      }
    }

    return _fallbackFeeds;
  }
}