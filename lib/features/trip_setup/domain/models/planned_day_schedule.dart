import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class PlannedDaySchedule {
  final int dayNumber;
  final DateTime? date;
  final String routeSection;
  final double distanceKm;
  final String movementType;
  final String obstacles;

  const PlannedDaySchedule({
    required this.dayNumber,
    this.date,
    required this.routeSection,
    required this.distanceKm,
    this.movementType = 'Пешком',
    this.obstacles = '',
  });

  PlannedDaySchedule copyWith({
    int? dayNumber,
    DateTime? date,
    String? routeSection,
    double? distanceKm,
    String? movementType,
    String? obstacles,
  }) {
    return PlannedDaySchedule(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      routeSection: routeSection ?? this.routeSection,
      distanceKm: distanceKm ?? this.distanceKm,
      movementType: movementType ?? this.movementType,
      obstacles: obstacles ?? this.obstacles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'date': date?.toIso8601String(),
      'routeSection': routeSection,
      'distanceKm': distanceKm,
      'movementType': movementType,
      'obstacles': obstacles,
    };
  }

  factory PlannedDaySchedule.fromMap(Map<String, dynamic> map) {
    return PlannedDaySchedule(
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      date: map['date'] != null ? DateTime.tryParse(map['date'] as String) : null,
      routeSection: map['routeSection'] as String? ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      movementType: map['movementType'] as String? ?? 'Пешком',
      obstacles: map['obstacles'] as String? ?? '',
    );
  }

  /// Automatically generates day-by-day itinerary segments from trip parameters and waypoints
  static List<PlannedDaySchedule> generateDefaultSchedule({
    required TripProfile profile,
    PlannedRoute? plannedRoute,
    List<WayPoint> waypoints = const [],
  }) {
    if (profile.plannedItinerary.isNotEmpty) {
      return profile.plannedItinerary;
    }

    final count = profile.activeDays > 0 ? profile.activeDays : 1;
    final dailyKm = profile.totalDistanceKm / count;

    // Combine distinct waypoints
    final allWaypoints = <WayPoint>[];
    if (plannedRoute != null) {
      allWaypoints.addAll(plannedRoute.waypoints);
    }
    for (final w in waypoints) {
      if (!allWaypoints.any((existing) =>
          existing.id == w.id ||
          (existing.latitude == w.latitude && existing.longitude == w.longitude))) {
        allWaypoints.add(w);
      }
    }

    return List.generate(count, (index) {
      final dayNum = index + 1;
      DateTime? date;
      if (profile.startDate != null) {
        date = profile.startDate!.add(Duration(days: index));
      }

      String routeSection = 'Ходовой переход $dayNum (участок маршрута)';
      String obstacles = '—';

      if (allWaypoints.isNotEmpty) {
        final startIndex = ((index / count) * allWaypoints.length).floor();
        final endIndex =
            (((index + 1) / count) * allWaypoints.length).floor().clamp(startIndex, allWaypoints.length);

        final dayWpts = allWaypoints.sublist(startIndex, endIndex);
        if (dayWpts.isNotEmpty) {
          if (dayWpts.length == 1) {
            routeSection = 'Переход к: ${dayWpts.first.title}';
            obstacles = '${dayWpts.first.type.displayNameRu} (${dayWpts.first.altitude.round()} м)';
          } else {
            routeSection = '${dayWpts.first.title} — ${dayWpts.last.title}';
            obstacles = dayWpts.map((w) => '${w.title} (${w.altitude.round()}м)').join(', ');
          }
        }
      }

      return PlannedDaySchedule(
        dayNumber: dayNum,
        date: date,
        routeSection: routeSection,
        distanceKm: dailyKm,
        movementType: profile.activityType.displayNameRu,
        obstacles: obstacles,
      );
    });
  }
}
