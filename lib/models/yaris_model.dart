class YarisModel {
  final String yarisAdi;
  final String tarih;
  final String lokasyon;

  YarisModel({
    required this.yarisAdi,
    required this.tarih,
    required this.lokasyon,
  });

  factory YarisModel.fromJson(Map<String, dynamic> json) {
    return YarisModel(
      yarisAdi: json['competition']['name'] ?? 'Bilinmiyor',
      tarih: json['date'] ?? 'Tarih yok',
      lokasyon: json['circuit']['location']['country'] ?? 'Lokasyon yok',
    );
  }
}
