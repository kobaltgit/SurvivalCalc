import 'package:survival_calc/features/tracking/domain/models/camp_debrief.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';

class DailyTrack {
  static const String sandboxTripId = 'sandbox_test_trip';

  final String id;
  final int dayIndex;
  final String? tripId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final List<GpsPoint> points;
  final List<WayPoint> waypoints;
  final double totalDistanceKm;
  final double elevationGainMeters;
  final double elevationLossMeters;
  final int movingDurationSeconds;
  final int pauseDurationSeconds;
  final double avgMovingSpeedKmh;
  final double maxSpeedKmh;
  final bool isCompleted;
  final bool isSimulation;
  final int segmentIndex;
  final CampDebrief? debrief;

  const DailyTrack({
    required this.id,
    required this.dayIndex,
    this.tripId,
    required this.title,
    required this.startTime,
    this.endTime,
    this.points = const [],
    this.waypoints = const [],
    this.totalDistanceKm = 0.0,
    this.elevationGainMeters = 0.0,
    this.elevationLossMeters = 0.0,
    this.movingDurationSeconds = 0,
    this.pauseDurationSeconds = 0,
    this.avgMovingSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.isCompleted = false,
    this.isSimulation = false,
    this.segmentIndex = 1,
    this.debrief,
  });

  DailyTrack copyWith({
    String? id,
    int? dayIndex,
    String? tripId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    List<GpsPoint>? points,
    List<WayPoint>? waypoints,
    double? totalDistanceKm,
    double? elevationGainMeters,
    double? elevationLossMeters,
    int? movingDurationSeconds,
    int? pauseDurationSeconds,
    double? avgMovingSpeedKmh,
    double? maxSpeedKmh,
    bool? isCompleted,
    bool? isSimulation,
    int? segmentIndex,
    CampDebrief? debrief,
  }) {
    return DailyTrack(
      id: id ?? this.id,
      dayIndex: dayIndex ?? this.dayIndex,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      points: points ?? this.points,
      waypoints: waypoints ?? this.waypoints,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      elevationLossMeters: elevationLossMeters ?? this.elevationLossMeters,
      movingDurationSeconds:
          movingDurationSeconds ?? this.movingDurationSeconds,
      pauseDurationSeconds:
          pauseDurationSeconds ?? this.pauseDurationSeconds,
      avgMovingSpeedKmh: avgMovingSpeedKmh ?? this.avgMovingSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      isCompleted: isCompleted ?? this.isCompleted,
      isSimulation: isSimulation ?? this.isSimulation,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      debrief: debrief ?? this.debrief,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayIndex': dayIndex,
      'tripId': tripId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'totalDistanceKm': totalDistanceKm,
      'elevationGainMeters': elevationGainMeters,
      'elevationLossMeters': elevationLossMeters,
      'movingDurationSeconds': movingDurationSeconds,
      'pauseDurationSeconds': pauseDurationSeconds,
      'avgMovingSpeedKmh': avgMovingSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'isCompleted': isCompleted,
      'isSimulation': isSimulation,
      'segmentIndex': segmentIndex,
      if (debrief != null) 'debrief': debrief!.toJson(),
    };
  }

  factory DailyTrack.fromJson(Map<String, dynamic> json) {
    return DailyTrack(
      id: json['id'] as String,
      dayIndex: json['dayIndex'] as int? ?? 1,
      tripId: json['tripId'] as String?,
      title: json['title'] as String? ?? 'Ходовой день',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      points: (json['points'] as List<dynamic>?)
              ?.map((p) => GpsPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((w) => WayPoint.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      elevationGainMeters:
          (json['elevationGainMeters'] as num?)?.toDouble() ?? 0.0,
      elevationLossMeters:
          (json['elevationLossMeters'] as num?)?.toDouble() ?? 0.0,
      movingDurationSeconds: json['movingDurationSeconds'] as int? ?? 0,
      pauseDurationSeconds: json['pauseDurationSeconds'] as int? ?? 0,
      avgMovingSpeedKmh:
          (json['avgMovingSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isSimulation: json['isSimulation'] as bool? ?? false,
      segmentIndex: json['segmentIndex'] as int? ?? 1,
      debrief: json['debrief'] != null
          ? CampDebrief.fromJson(json['debrief'] as Map<String, dynamic>)
          : null,
    );
  }
}

