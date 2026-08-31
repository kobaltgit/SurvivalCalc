import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/tracking/domain/models/camp_debrief.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class CampDebriefCalculator {
  final MetabolicCalculator metabolicCalculator;

  const CampDebriefCalculator({
    this.metabolicCalculator = const MetabolicCalculator(),
  });

  CampDebrief generateDebrief({
    required DailyTrack track,
    required TripProfile profile,
    required TripCalculationResult planResult,
  }) {
    // 1. Planned day averages
    final int safeDays = profile.activeDays > 0 ? profile.activeDays : 1;
    final double plannedDistanceKm = profile.totalDistanceKm / safeDays;
    final double plannedAscentMeters = profile.totalAscentMeters / safeDays;
    final double plannedDailyCalories = planResult.targets.dailyCalories;

    // 2. Actual physical metrics
    final double actualDistanceKm = track.totalDistanceKm;
    final double actualAscentMeters = track.elevationGainMeters;
    final double actualDescentMeters = track.elevationLossMeters;

    // 3. Create a single-day profile for actual metrics to compute exact metabolic burn
    final TripProfile actualDayProfile = profile.copyWith(
      durationDays: 1,
      activeDays: 1,
      totalDistanceKm: actualDistanceKm,
      totalAscentMeters: actualAscentMeters,
    );

    final actualTargets = metabolicCalculator.calculate(actualDayProfile);
    final double actualCaloriesBurned = actualTargets.dailyCalories;
    final double calorieDelta = actualCaloriesBurned - plannedDailyCalories;

    // 4. Hydration & Electrolytes
    final double targetWaterLiters = actualTargets.dailyWaterLiters;
    // Compensation depends on weather and moving duration
    double eveningWaterCompensationLiters = 1.0;
    if (actualDistanceKm > plannedDistanceKm || profile.season == Season.summer) {
      eveningWaterCompensationLiters += 0.5;
    }
    if (track.movingDurationSeconds > 5 * 3600) {
      eveningWaterCompensationLiters += 0.5;
    }

    String electrolyteAdvice = 'Водно-солевой баланс в норме. Выпейте теплый чай с сахаром.';
    if (calorieDelta > 300 || actualAscentMeters > 500 || profile.season == Season.summer) {
      electrolyteAdvice = '⚠️ Высокое потоотделение и потеря солей. Рекомендуется растворить пакет Регидрона/Изотоника в 0.7–1.0 л воды перед сном.';
    }

    // 5. Nutrition Recommendations
    final List<String> recommendations = [];
    if (calorieDelta > 500) {
      recommendations.add(
        '🔥 Высокий перерасход энергии (+${calorieDelta.toStringAsFixed(0)} ккал). Добавьте к ужину 30–40 г сала/масла и 50 г орехов для закрытия окна.',
      );
      recommendations.add(
        '🍫 Съешьте дополнительный батончик/шоколад из запаса на перекус перед сном для ночного термогенеза.',
      );
    } else if (calorieDelta > 200) {
      recommendations.add(
        '⚡ Небольшой перерасход (+${calorieDelta.toStringAsFixed(0)} ккал). Увеличьте порцию вечерней крупы/пюре на 20–30%.',
      );
    } else if (calorieDelta < -300) {
      recommendations.add(
        '🌿 Щадящий день (сэкономлено ${(-calorieDelta).toStringAsFixed(0)} ккал). Можно оставить часть вечернего десерта в резервный НЗ.',
      );
    } else {
      recommendations.add(
        '✅ Нагрузка точно соответствует плану. Следуйте стандартной вечерней раскладке.',
      );
    }

    if (profile.season == Season.winter || profile.season == Season.extreme_cold) {
      recommendations.add(
        '❄️ Зимний режим: перед сном обязательно выпейте горячий жирный бульон для предотвращения ночного переохлаждения.',
      );
    }

    // 6. Resources & Weight Melt calculation
    final double dailyFoodWeightG =
        planResult.foodWeightPerPersonPerDayKg * 1000.0;
    final double dailyGasG = planResult.targets.dailyGasFuelG;

    // Remaining backpack weight calculation
    final double startPackWeightKg = planResult.startPackWeightPerPersonKg;
    final double totalWeightLossKg =
        ((dailyFoodWeightG + dailyGasG) * track.dayIndex) / 1000.0;
    final double estimatedMorningPackWeightKg =
        (startPackWeightKg - totalWeightLossKg).clamp(0.0, 100.0);

    return CampDebrief(
      dayIndex: track.dayIndex,
      dayTitle: track.title.isNotEmpty
          ? track.title
          : 'День ${track.dayIndex}: Вечерний отчет',
      plannedDistanceKm: plannedDistanceKm,
      actualDistanceKm: actualDistanceKm,
      plannedAscentMeters: plannedAscentMeters,
      actualAscentMeters: actualAscentMeters,
      actualDescentMeters: actualDescentMeters,
      movingDurationSeconds: track.movingDurationSeconds,
      pauseDurationSeconds: track.pauseDurationSeconds,
      avgMovingSpeedKmh: track.avgMovingSpeedKmh,
      plannedDailyCalories: plannedDailyCalories,
      actualCaloriesBurned: actualCaloriesBurned,
      calorieDelta: calorieDelta,
      targetWaterLiters: targetWaterLiters,
      eveningWaterCompensationLiters: eveningWaterCompensationLiters,
      electrolyteAdvice: electrolyteAdvice,
      nutritionRecommendations: recommendations,
      dailyFoodWeightConsumedG: dailyFoodWeightG,
      dailyGasConsumedG: dailyGasG,
      estimatedMorningPackWeightKg: estimatedMorningPackWeightKg,
    );
  }
}
