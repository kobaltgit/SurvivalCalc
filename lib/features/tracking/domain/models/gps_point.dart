class GpsPoint {
  final double latitude;
  final double longitude;
  final double altitude; // meters
  final DateTime timestamp;
  final double speedKmh;
  final double accuracy; // meters

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    this.speedKmh = 0.0,
    this.accuracy = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'alt': altitude,
      'time': timestamp.toIso8601String(),
      'spd': speedKmh,
      'acc': accuracy,
    };
  }

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    return GpsPoint(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      altitude: (json['alt'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['time'] as String),
      speedKmh: (json['spd'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['acc'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
