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
  });

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
    );
  }
}
