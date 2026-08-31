import 'dart:convert';
import 'package:survival_calc/core/enums/trip_enums.dart';

class TripProfile {
  final String id;
  final String title;
  final int groupSize;
  final int durationDays;
  final int activeDays;
  final double totalDistanceKm;
  final double totalAscentMeters;
  final Season season;
  final ActivityType activityType;
  final double avgParticipantWeightKg;
  final DateTime createdAt;

  const TripProfile({
    required this.id,
    this.title = 'Новый поход',
    required this.groupSize,
    required this.durationDays,
    required this.activeDays,
    required this.totalDistanceKm,
    required this.totalAscentMeters,
    required this.season,
    required this.activityType,
    this.avgParticipantWeightKg = 75.0,
    required this.createdAt,
  });

  TripProfile copyWith({
    String? id,
    String? title,
    int? groupSize,
    int? durationDays,
    int? activeDays,
    double? totalDistanceKm,
    double? totalAscentMeters,
    Season? season,
    ActivityType? activityType,
    double? avgParticipantWeightKg,
    DateTime? createdAt,
  }) {
    return TripProfile(
      id: id ?? this.id,
      title: title ?? this.title,
      groupSize: groupSize ?? this.groupSize,
      durationDays: durationDays ?? this.durationDays,
      activeDays: activeDays ?? this.activeDays,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalAscentMeters: totalAscentMeters ?? this.totalAscentMeters,
      season: season ?? this.season,
      activityType: activityType ?? this.activityType,
      avgParticipantWeightKg:
          avgParticipantWeightKg ?? this.avgParticipantWeightKg,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'groupSize': groupSize,
      'durationDays': durationDays,
      'activeDays': activeDays,
      'totalDistanceKm': totalDistanceKm,
      'totalAscentMeters': totalAscentMeters,
      'season': season.name,
      'activityType': activityType.name,
      'avgParticipantWeightKg': avgParticipantWeightKg,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TripProfile.fromMap(Map<String, dynamic> map) {
    return TripProfile(
      id: map['id'] as String? ?? 'trip_default',
      title: map['title'] as String? ?? 'Поход',
      groupSize: (map['groupSize'] as num?)?.toInt() ?? 1,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 3,
      activeDays: (map['activeDays'] as num?)?.toInt() ?? 3,
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 30.0,
      totalAscentMeters: (map['totalAscentMeters'] as num?)?.toDouble() ?? 500.0,
      season: Season.fromString(map['season'] as String? ?? 'summer'),
      activityType:
          ActivityType.fromString(map['activityType'] as String? ?? 'hiking'),
      avgParticipantWeightKg:
          (map['avgParticipantWeightKg'] as num?)?.toDouble() ?? 75.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory TripProfile.fromJson(String source) =>
      TripProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  static TripProfile createDefault() {
    return TripProfile(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Мой поход',
      groupSize: 2,
      durationDays: 3,
      activeDays: 3,
      totalDistanceKm: 35.0,
      totalAscentMeters: 600.0,
      season: Season.summer,
      activityType: ActivityType.hiking,
      avgParticipantWeightKg: 75.0,
      createdAt: DateTime.now(),
    );
  }
}
