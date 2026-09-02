import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';

class CampDebrief {
  final int dayIndex;
  final String dayTitle;
  
  // Physical stats
  final double plannedDistanceKm;
  final double actualDistanceKm;
  final double plannedAscentMeters;
  final double actualAscentMeters;
  final double actualDescentMeters;
  final int movingDurationSeconds;
  final int pauseDurationSeconds;
  final double avgMovingSpeedKmh;
  
  // Metabolic stats
  final double plannedDailyCalories;
  final double actualCaloriesBurned;
  final double calorieDelta; // actual - planned (+ means deficit/overburn)
  
  // Hydration & Electrolytes
  final double targetWaterLiters;
  final double eveningWaterCompensationLiters;
  final String electrolyteAdvice;
  
  // Nutrition adjustments
  final List<String> nutritionRecommendations;
  
  // Weight & resources impact
  final double dailyFoodWeightConsumedG;
  final double dailyGasConsumedG;
  final double estimatedMorningPackWeightKg;

  // Daily camp journal & photo reflections
  final List<DailyCampNote> notes;

  const CampDebrief({
    required this.dayIndex,
    required this.dayTitle,
    required this.plannedDistanceKm,
    required this.actualDistanceKm,
    required this.plannedAscentMeters,
    required this.actualAscentMeters,
    required this.actualDescentMeters,
    required this.movingDurationSeconds,
    required this.pauseDurationSeconds,
    required this.avgMovingSpeedKmh,
    required this.plannedDailyCalories,
    required this.actualCaloriesBurned,
    required this.calorieDelta,
    required this.targetWaterLiters,
    required this.eveningWaterCompensationLiters,
    required this.electrolyteAdvice,
    required this.nutritionRecommendations,
    required this.dailyFoodWeightConsumedG,
    required this.dailyGasConsumedG,
    required this.estimatedMorningPackWeightKg,
    this.notes = const [],
  });

  CampDebrief copyWith({
    int? dayIndex,
    String? dayTitle,
    double? plannedDistanceKm,
    double? actualDistanceKm,
    double? plannedAscentMeters,
    double? actualAscentMeters,
    double? actualDescentMeters,
    int? movingDurationSeconds,
    int? pauseDurationSeconds,
    double? avgMovingSpeedKmh,
    double? plannedDailyCalories,
    double? actualCaloriesBurned,
    double? calorieDelta,
    double? targetWaterLiters,
    double? eveningWaterCompensationLiters,
    String? electrolyteAdvice,
    List<String>? nutritionRecommendations,
    double? dailyFoodWeightConsumedG,
    double? dailyGasConsumedG,
    double? estimatedMorningPackWeightKg,
    List<DailyCampNote>? notes,
  }) {
    return CampDebrief(
      dayIndex: dayIndex ?? this.dayIndex,
      dayTitle: dayTitle ?? this.dayTitle,
      plannedDistanceKm: plannedDistanceKm ?? this.plannedDistanceKm,
      actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
      plannedAscentMeters: plannedAscentMeters ?? this.plannedAscentMeters,
      actualAscentMeters: actualAscentMeters ?? this.actualAscentMeters,
      actualDescentMeters: actualDescentMeters ?? this.actualDescentMeters,
      movingDurationSeconds: movingDurationSeconds ?? this.movingDurationSeconds,
      pauseDurationSeconds: pauseDurationSeconds ?? this.pauseDurationSeconds,
      avgMovingSpeedKmh: avgMovingSpeedKmh ?? this.avgMovingSpeedKmh,
      plannedDailyCalories: plannedDailyCalories ?? this.plannedDailyCalories,
      actualCaloriesBurned: actualCaloriesBurned ?? this.actualCaloriesBurned,
      calorieDelta: calorieDelta ?? this.calorieDelta,
      targetWaterLiters: targetWaterLiters ?? this.targetWaterLiters,
      eveningWaterCompensationLiters:
          eveningWaterCompensationLiters ?? this.eveningWaterCompensationLiters,
      electrolyteAdvice: electrolyteAdvice ?? this.electrolyteAdvice,
      nutritionRecommendations:
          nutritionRecommendations ?? this.nutritionRecommendations,
      dailyFoodWeightConsumedG:
          dailyFoodWeightConsumedG ?? this.dailyFoodWeightConsumedG,
      dailyGasConsumedG: dailyGasConsumedG ?? this.dailyGasConsumedG,
      estimatedMorningPackWeightKg:
          estimatedMorningPackWeightKg ?? this.estimatedMorningPackWeightKg,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayIndex': dayIndex,
      'dayTitle': dayTitle,
      'plannedDistanceKm': plannedDistanceKm,
      'actualDistanceKm': actualDistanceKm,
      'plannedAscentMeters': plannedAscentMeters,
      'actualAscentMeters': actualAscentMeters,
      'actualDescentMeters': actualDescentMeters,
      'movingDurationSeconds': movingDurationSeconds,
      'pauseDurationSeconds': pauseDurationSeconds,
      'avgMovingSpeedKmh': avgMovingSpeedKmh,
      'plannedDailyCalories': plannedDailyCalories,
      'actualCaloriesBurned': actualCaloriesBurned,
      'calorieDelta': calorieDelta,
      'targetWaterLiters': targetWaterLiters,
      'eveningWaterCompensationLiters': eveningWaterCompensationLiters,
      'electrolyteAdvice': electrolyteAdvice,
      'nutritionRecommendations': nutritionRecommendations,
      'dailyFoodWeightConsumedG': dailyFoodWeightConsumedG,
      'dailyGasConsumedG': dailyGasConsumedG,
      'estimatedMorningPackWeightKg': estimatedMorningPackWeightKg,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }

  factory CampDebrief.fromJson(Map<String, dynamic> json) {
    return CampDebrief(
      dayIndex: json['dayIndex'] as int? ?? 1,
      dayTitle: json['dayTitle'] as String? ?? 'Вечерний лагерь',
      plannedDistanceKm:
          (json['plannedDistanceKm'] as num?)?.toDouble() ?? 0.0,
      actualDistanceKm:
          (json['actualDistanceKm'] as num?)?.toDouble() ?? 0.0,
      plannedAscentMeters:
          (json['plannedAscentMeters'] as num?)?.toDouble() ?? 0.0,
      actualAscentMeters:
          (json['actualAscentMeters'] as num?)?.toDouble() ?? 0.0,
      actualDescentMeters:
          (json['actualDescentMeters'] as num?)?.toDouble() ?? 0.0,
      movingDurationSeconds: json['movingDurationSeconds'] as int? ?? 0,
      pauseDurationSeconds: json['pauseDurationSeconds'] as int? ?? 0,
      avgMovingSpeedKmh:
          (json['avgMovingSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      plannedDailyCalories:
          (json['plannedDailyCalories'] as num?)?.toDouble() ?? 0.0,
      actualCaloriesBurned:
          (json['actualCaloriesBurned'] as num?)?.toDouble() ?? 0.0,
      calorieDelta: (json['calorieDelta'] as num?)?.toDouble() ?? 0.0,
      targetWaterLiters:
          (json['targetWaterLiters'] as num?)?.toDouble() ?? 3.0,
      eveningWaterCompensationLiters:
          (json['eveningWaterCompensationLiters'] as num?)?.toDouble() ?? 1.0,
      electrolyteAdvice: json['electrolyteAdvice'] as String? ?? '',
      nutritionRecommendations:
          (json['nutritionRecommendations'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      dailyFoodWeightConsumedG:
          (json['dailyFoodWeightConsumedG'] as num?)?.toDouble() ?? 0.0,
      dailyGasConsumedG:
          (json['dailyGasConsumedG'] as num?)?.toDouble() ?? 0.0,
      estimatedMorningPackWeightKg:
          (json['estimatedMorningPackWeightKg'] as num?)?.toDouble() ?? 0.0,
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => DailyCampNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

