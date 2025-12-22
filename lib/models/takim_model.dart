class TakimModel {
  final String displayName;
  final int rank;
  final int points;

  TakimModel({
    required this.displayName,
    required this.rank,
    required this.points,
  });

  factory TakimModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'];
    final stats = json['stats'] as List<dynamic>;

    int rank = 0;
    int points = 0;

    for (var stat in stats) {
      if (stat['name'] == 'rank') {
        rank = stat['value'] ?? 0;
      } else if (stat['name'] == 'points') {
        points = stat['value'] ?? 0;
      }
    }

    return TakimModel(
      displayName: team['displayName'] ?? 'Bilinmiyor',
      rank: rank,
      points: points,
    );
  }
}
