import 'dart:convert';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/trip_setup/domain/models/planned_day_schedule.dart';

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
  final String clubOrCity;
  final String difficultyCategory;
  final String geographicalRegion;
  final String emergencyExitRoutes;
  final String mkkName;

  // New MKK 2020 Standard Fields
  final String routeBookNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final String mchsRegNumber;
  final String coordinatorName;
  final String coordinatorPhone;
  final String coordinatorEmail;
  final String satellitePhone;
  final String communicationSchedule;
  final String deputyLeaderName;
  final String deputyLeaderPhone;
  final List<PlannedDaySchedule> plannedItinerary;

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
    this.clubOrCity = '',
    this.difficultyCategory = 'н/к',
    this.geographicalRegion = '',
    this.emergencyExitRoutes = '',
    this.mkkName = '',
    this.routeBookNumber = '',
    this.startDate,
    this.endDate,
    this.mchsRegNumber = '',
    this.coordinatorName = '',
    this.coordinatorPhone = '',
    this.coordinatorEmail = '',
    this.satellitePhone = '',
    this.communicationSchedule = '',
    this.deputyLeaderName = '',
    this.deputyLeaderPhone = '',
    this.plannedItinerary = const [],
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
    String? clubOrCity,
    String? difficultyCategory,
    String? geographicalRegion,
    String? emergencyExitRoutes,
    String? mkkName,
    String? routeBookNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? mchsRegNumber,
    String? coordinatorName,
    String? coordinatorPhone,
    String? coordinatorEmail,
    String? satellitePhone,
    String? communicationSchedule,
    String? deputyLeaderName,
    String? deputyLeaderPhone,
    List<PlannedDaySchedule>? plannedItinerary,
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
      clubOrCity: clubOrCity ?? this.clubOrCity,
      difficultyCategory: difficultyCategory ?? this.difficultyCategory,
      geographicalRegion: geographicalRegion ?? this.geographicalRegion,
      emergencyExitRoutes: emergencyExitRoutes ?? this.emergencyExitRoutes,
      mkkName: mkkName ?? this.mkkName,
      routeBookNumber: routeBookNumber ?? this.routeBookNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mchsRegNumber: mchsRegNumber ?? this.mchsRegNumber,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorPhone: coordinatorPhone ?? this.coordinatorPhone,
      coordinatorEmail: coordinatorEmail ?? this.coordinatorEmail,
      satellitePhone: satellitePhone ?? this.satellitePhone,
      communicationSchedule:
          communicationSchedule ?? this.communicationSchedule,
      deputyLeaderName: deputyLeaderName ?? this.deputyLeaderName,
      deputyLeaderPhone: deputyLeaderPhone ?? this.deputyLeaderPhone,
      plannedItinerary: plannedItinerary ?? this.plannedItinerary,
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
      'clubOrCity': clubOrCity,
      'difficultyCategory': difficultyCategory,
      'geographicalRegion': geographicalRegion,
      'emergencyExitRoutes': emergencyExitRoutes,
      'mkkName': mkkName,
      'routeBookNumber': routeBookNumber,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'mchsRegNumber': mchsRegNumber,
      'coordinatorName': coordinatorName,
      'coordinatorPhone': coordinatorPhone,
      'coordinatorEmail': coordinatorEmail,
      'satellitePhone': satellitePhone,
      'communicationSchedule': communicationSchedule,
      'deputyLeaderName': deputyLeaderName,
      'deputyLeaderPhone': deputyLeaderPhone,
      'plannedItinerary': plannedItinerary.map((d) => d.toMap()).toList(),
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
      clubOrCity: map['clubOrCity'] as String? ?? '',
      difficultyCategory: map['difficultyCategory'] as String? ?? 'н/к',
      geographicalRegion: map['geographicalRegion'] as String? ?? '',
      emergencyExitRoutes: map['emergencyExitRoutes'] as String? ?? '',
      mkkName: map['mkkName'] as String? ?? '',
      routeBookNumber: map['routeBookNumber'] as String? ?? '',
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'] as String)
          : null,
      mchsRegNumber: map['mchsRegNumber'] as String? ?? '',
      coordinatorName: map['coordinatorName'] as String? ?? '',
      coordinatorPhone: map['coordinatorPhone'] as String? ?? '',
      coordinatorEmail: map['coordinatorEmail'] as String? ?? '',
      satellitePhone: map['satellitePhone'] as String? ?? '',
      communicationSchedule: map['communicationSchedule'] as String? ?? '',
      deputyLeaderName: map['deputyLeaderName'] as String? ?? '',
      deputyLeaderPhone: map['deputyLeaderPhone'] as String? ?? '',
      plannedItinerary: (map['plannedItinerary'] as List<dynamic>?)
              ?.map((e) => PlannedDaySchedule.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      clubOrCity: '',
      difficultyCategory: 'н/к',
      geographicalRegion: '',
      emergencyExitRoutes: '',
      mkkName: '',
      routeBookNumber: '',
      startDate: null,
      endDate: null,
      mchsRegNumber: '',
      coordinatorName: '',
      coordinatorPhone: '',
      coordinatorEmail: '',
      satellitePhone: '',
      communicationSchedule: '',
      deputyLeaderName: '',
      deputyLeaderPhone: '',
      plannedItinerary: const [],
    );
  }
}
