String getTeamNameForDriver(String driverName) {
  final Map<String, String> pilotToTeam = {
    'kimi antonelli': 'Mercedes',
    'george russell': 'Mercedes',

    'max verstappen': 'Red Bull',
    'yuki tsunoda': 'Red Bull',

    'charles leclerc': 'Ferrari',
    'lewis hamilton': 'Ferrari',

    'lando norris': 'McLaren',
    'oscar piastri': 'McLaren',

    'alex albon': 'Williams',
    'carlos sainz': 'Williams',

    'esteban ocon': 'Haas',
    'oliver bearman': 'Haas',

    'fernando alonso': 'Aston Martin',
    'lance stroll': 'Aston Martin',

    'pierre gasly': 'Alpine',
    'franco colapinto': 'Alpine',

    'nico hulkenberg': 'Kick Sauber',
    'gabriel bortoleto': 'Kick Sauber',

    'liam lawson': 'Racing Bulls',
    'isack hadjar': 'Racing Bulls',
  };

  return pilotToTeam[driverName.toLowerCase()] ?? 'Bilinmiyor';
}
String getPilotAssetImage(String driverName) {
  // Dosya adını küçük harfe çevirip boşlukları alt çizgiye çeviriyoruz
  String fileName = driverName.toLowerCase().replaceAll(' ', '_').replaceAll('.', '') + '.png';
  return 'assets/images/pilotlar/$fileName';
}

class PilotModel {
  final String driverName;
  final String teamName;
  final int rank;
  final int points;

  PilotModel({
    required this.driverName,
    required this.teamName,
    required this.rank,
    required this.points,
  });

  factory PilotModel.fromJson(Map<String, dynamic> json) {
    final athlete = json['athlete'] as Map<String, dynamic>?;
    final stats = json['stats'] as List<dynamic>? ?? [];

    int rank = 0;
    int points = 0;

    for (var stat in stats) {
      if (stat['name'] == 'rank') {
        rank = stat['value'] ?? 0;
      } else if (stat['name'] == 'championshipPts') {
        points = stat['value'] ?? 0;
      }
    }

    final driverName = athlete != null ? (athlete['displayName'] ?? 'Bilinmiyor') : 'Bilinmiyor';
    final teamName = getTeamNameForDriver(driverName);

    return PilotModel(
      driverName: driverName,
      teamName: teamName,
      rank: rank,
      points: points,
    );
  }
}
