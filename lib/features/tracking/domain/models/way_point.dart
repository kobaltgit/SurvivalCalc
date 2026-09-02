import 'package:survival_calc/core/enums/trip_enums.dart';

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
        return 'Видовая точка / Фото';
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
  final String? photoPath;
  final String? authorName;
  final TripRole? authorRole;

  const WayPoint({
    required this.id,
    required this.title,
    this.note,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    this.photoPath,
    this.authorName,
    this.authorRole,
  });

  WayPoint copyWith({
    String? id,
    String? title,
    String? note,
    WayPointType? type,
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? timestamp,
    String? photoPath,
    String? authorName,
    TripRole? authorRole,
  }) {
    return WayPoint(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
      photoPath: photoPath ?? this.photoPath,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
    );
  }

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
      if (photoPath != null) 'photoPath': photoPath,
      if (authorName != null) 'authorName': authorName,
      if (authorRole != null) 'authorRole': authorRole!.name,
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
      photoPath: json['photoPath'] as String?,
      authorName: json['authorName'] as String?,
      authorRole: json['authorRole'] != null
          ? TripRole.fromString(json['authorRole'] as String)
          : null,
    );
  }
}

