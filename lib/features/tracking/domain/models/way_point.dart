enum WayPointType {
  water,
  camp,
  pass,
  obstacle,
  viewpoint,
  other,
}

extension WayPointTypeExtension on WayPointType {
  String get displayNameRu {
    switch (this) {
      case WayPointType.water:
        return 'Родник / Вода';
      case WayPointType.camp:
        return 'Лагерь / Стоянка';
      case WayPointType.pass:
        return 'Перевал / Вершина';
      case WayPointType.obstacle:
        return 'Препятствие / Брод';
      case WayPointType.viewpoint:
        return 'Видовая точка';
      case WayPointType.other:
        return 'Особая метка';
    }
  }

  String get iconKey {
    switch (this) {
      case WayPointType.water:
        return 'water_drop';
      case WayPointType.camp:
        return 'cabin';
      case WayPointType.pass:
        return 'landscape';
      case WayPointType.obstacle:
        return 'warning';
      case WayPointType.viewpoint:
        return 'photo_camera';
      case WayPointType.other:
        return 'location_on';
    }
  }
}

class WayPoint {
  final String id;
  final String title;
  final String? note;
  final WayPointType type;
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  const WayPoint({
    required this.id,
    required this.title,
    this.note,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'type': type.name,
      'lat': latitude,
      'lng': longitude,
      'alt': altitude,
      'time': timestamp.toIso8601String(),
    };
  }

  factory WayPoint.fromJson(Map<String, dynamic> json) {
    return WayPoint(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String?,
      type: WayPointType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WayPointType.other,
      ),
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      altitude: (json['alt'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['time'] as String),
    );
  }
}
