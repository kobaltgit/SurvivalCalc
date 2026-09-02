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
}
