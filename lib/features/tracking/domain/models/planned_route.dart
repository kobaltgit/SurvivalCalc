import 'dart:convert';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';

class PlannedRoute {
  final String id;
  final String name;
  final String description;
  final double totalDistanceKm;
  final double totalAscentMeters;
  final double totalDescentMeters;
  final List<GpsPoint> points;
  final List<WayPoint> waypoints;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final DateTime importedAt;

  const PlannedRoute({
    required this.id,
    required this.name,
    this.description = '',
    required this.totalDistanceKm,
    required this.totalAscentMeters,
    required this.totalDescentMeters,
    required this.points,
    required this.waypoints,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.importedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalDistanceKm': totalDistanceKm,
      'totalAscentMeters': totalAscentMeters,
      'totalDescentMeters': totalDescentMeters,
      'points': points.map((p) => p.toJson()).toList(),
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'minLat': minLat,
      'maxLat': maxLat,
      'minLon': minLon,
      'maxLon': maxLon,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  factory PlannedRoute.fromMap(Map<String, dynamic> map) {
    return PlannedRoute(
      id: map['id'] as String? ?? 'route_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Плановый маршрут',
      description: map['description'] as String? ?? '',
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalAscentMeters: (map['totalAscentMeters'] as num?)?.toDouble() ?? 0.0,
      totalDescentMeters: (map['totalDescentMeters'] as num?)?.toDouble() ?? 0.0,
      points: (map['points'] as List<dynamic>?)
              ?.map((p) => GpsPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      waypoints: (map['waypoints'] as List<dynamic>?)
              ?.map((w) => WayPoint.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      minLat: (map['minLat'] as num?)?.toDouble() ?? 0.0,
      maxLat: (map['maxLat'] as num?)?.toDouble() ?? 0.0,
      minLon: (map['minLon'] as num?)?.toDouble() ?? 0.0,
      maxLon: (map['maxLon'] as num?)?.toDouble() ?? 0.0,
      importedAt: map['importedAt'] != null
          ? DateTime.tryParse(map['importedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory PlannedRoute.fromJson(String source) =>
      PlannedRoute.fromMap(json.decode(source) as Map<String, dynamic>);
}
