class CircuitCoordinates {
  // (anahtar kelimeler, enlem, boylam)
  static const _table = <(List<String>, double, double)>[
    (['sakhir', 'bahrain'], 26.0325, 50.5106),
    (['jeddah', 'saudi'], 21.6319, 39.1044),
    (['melbourne', 'albert park', 'australia'], -37.8497, 144.9680),
    (['suzuka', 'japan'], 34.8431, 136.5410),
    (['shanghai', 'china'], 31.3389, 121.2197),
    (['miami'], 25.9581, -80.2389),
    (['imola', 'emilia'], 44.3439, 11.7167),
    (['monaco', 'monte carlo'], 43.7347, 7.4206),
    (['catalunya', 'barcelona'], 41.5700, 2.2611),
    (['montreal', 'canada'], 45.5000, -73.5228),
    (['spielberg', 'red bull ring', 'austria'], 47.2197, 14.7647),
    (['silverstone', 'british', 'united kingdom'], 52.0786, -1.0169),
    (['spa', 'belgium'], 50.4372, 5.9714),
    (['hungaroring', 'budapest', 'hungary'], 47.5789, 19.2486),
    (['zandvoort', 'netherlands', 'dutch'], 52.3888, 4.5409),
    (['monza'], 45.6156, 9.2811),
    (['baku', 'azerbaijan'], 40.3725, 49.8533),
    (['singapore', 'marina bay'], 1.2914, 103.8640),
    (['austin', 'americas', 'cota'], 30.1328, -97.6411),
    (['mexico'], 19.4042, -99.0907),
    (['interlagos', 'sao paulo', 'são paulo', 'brazil'], -23.7036, -46.6997),
    (['las vegas'], 36.1147, -115.1728),
    (['lusail', 'qatar'], 25.4900, 51.4542),
    (['yas marina', 'abu dhabi', 'emirates'], 24.4672, 54.6031),
  ];

  static ({double lat, double lng})? find(String circuitName, String meetingName) {
    final haystack = '$circuitName $meetingName'.toLowerCase();
    for (final (keys, lat, lng) in _table) {
      if (keys.any(haystack.contains)) return (lat: lat, lng: lng);
    }
    return null;
  }
}