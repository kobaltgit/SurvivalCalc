import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/services/camp_debrief_calculator.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  group('CampDebriefCalculator Tests', () {
    const metabolicCalculator = MetabolicCalculator();
    const debriefCalculator = CampDebriefCalculator();

    final planProfile = TripProfile(
      id: 'trip_test',
      title: 'Тестовый поход',
      groupSize: 1,
      durationDays: 3,
      activeDays: 3,
      totalDistanceKm: 30.0, // 10 km/day planned
      totalAscentMeters: 1500.0, // 500m/day planned
      season: Season.summer,
      activityType: ActivityType.hiking,
      avgParticipantWeightKg: 75.0,
      createdAt: DateTime(2026, 8, 31),
    );

    final planTargets = metabolicCalculator.calculate(planProfile);
    final mockPlanResult = TripCalculationResult(
      profile: planProfile,
      targets: planTargets,
      dailyRations: [],
      shoppingList: [],
      gearList: [],
      participants: [],
      totalPersonalGearWeightKg: 8.0,
      totalGroupGearWeightKg: 2.0,
      groupGearWeightPerPersonKg: 2.0,
      totalGearWeightPerPersonKg: 10.0,
      foodWeightPerPersonPerDayKg: 0.8,
      totalFoodWeightPerPersonKg: 2.4,
      totalFoodWeightAllGroupKg: 2.4,
      startPackWeightPerPersonKg: 12.4,
      dailyPackWeightsPerPersonKg: [12.4, 11.6, 10.8],
    );

    test('Generates debrief with calorie deficit when group climbed harder', () {
      final now = DateTime.now();
      final hardDayTrack = DailyTrack(
        id: 'track_1',
        dayIndex: 1,
        title: 'День 1: Подъем на перевал',
        startTime: now,
        endTime: now.add(const Duration(hours: 6)),
        totalDistanceKm: 16.0, // 16 km actual vs 10 km planned
        elevationGainMeters: 1100.0, // 1100m actual vs 500m planned
        elevationLossMeters: 200.0,
        movingDurationSeconds: 5 * 3600,
        pauseDurationSeconds: 1 * 3600,
        avgMovingSpeedKmh: 3.2,
        isCompleted: true,
      );

      final debrief = debriefCalculator.generateDebrief(
        track: hardDayTrack,
        profile: planProfile,
        planResult: mockPlanResult,
      );

      expect(debrief.actualDistanceKm, equals(16.0));
      expect(debrief.actualAscentMeters, equals(1100.0));
      // Calorie burn should be higher than planned
      expect(debrief.actualCaloriesBurned, greaterThan(debrief.plannedDailyCalories));
      expect(debrief.calorieDelta, greaterThan(300.0));
      expect(debrief.nutritionRecommendations.isNotEmpty, isTrue);
      // Electrolyte advice should trigger for hard day
      expect(debrief.electrolyteAdvice.contains('Регидрон'), isTrue);
      // Morning pack weight should decrease by daily food + gas
      expect(debrief.estimatedMorningPackWeightKg, lessThan(mockPlanResult.startPackWeightPerPersonKg));
    });
  });
}
