import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  group('MetabolicCalculator 3 Benchmark Scenarios', () {
    const calculator = MetabolicCalculator();

    test('Scenario 1: Летний ПВД соло (1 чел, 2 дня, 25 км, 400 м подъем)', () {
      final profile = TripProfile(
        id: 'bench_1',
        title: 'Летний ПВД',
        groupSize: 1,
        durationDays: 2,
        activeDays: 2,
        totalDistanceKm: 25.0,
        totalAscentMeters: 400.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = calculator.calculate(profile);

      // BMR = 10 * 75 + 6.25 * 175 - 5 * 30 + 5 = 750 + 1093.75 - 150 + 5 = 1698.75
      expect(targets.bmr, equals(1698.75));

      // Equivalent distance = 25 + (400/100) = 29 km. Daily = 14.5 km -> PAL = 2.2
      expect(targets.equivalentDistanceKm, equals(29.0));
      expect(targets.dailyEquivalentKm, equals(14.5));
      expect(targets.pal, equals(2.2));
      expect(targets.coldBonusKcal, equals(0.0));

      // Daily calories = 1698.75 * 2.2 = 3737.25
      expect(targets.dailyCalories, closeTo(3737.25, 0.1));

      // Summer fat = 30%, gas = 40g, water = 4.0L (3.0 + 1.0 summer)
      expect(targets.dailyGasFuelG, equals(40.0));
      expect(targets.dailyWaterLiters, equals(4.0));
      expect(targets.dailyProteinG, equals(75.0 * 1.6)); // 120.0g
    });

    test('Scenario 2: Осенний горный поход (4 чел, 7 дней, 90 км, 3200 м подъем)', () {
      final profile = TripProfile(
        id: 'bench_2',
        title: 'Горный поход Кавказ',
        groupSize: 4,
        durationDays: 7,
        activeDays: 7,
        totalDistanceKm: 90.0,
        totalAscentMeters: 3200.0,
        season: Season.spring_autumn,
        activityType: ActivityType.mountain,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = calculator.calculate(profile);

      // Equivalent distance = 90 + 32 = 122 km. Daily = 122 / 7 = 17.43 km -> PAL = 2.2
      expect(targets.equivalentDistanceKm, equals(122.0));
      expect(targets.pal, equals(2.2));
      expect(targets.coldBonusKcal, equals(0.0));

      // Mountain protein multiplier = 1.8 -> 135g
      expect(targets.dailyProteinG, equals(135.0));

      // Daily calories with +250 kcal mountain bonus = 3737.25 + 250 = 3987.25
      expect(targets.dailyCalories, closeTo(3987.25, 0.1));

      // Spring/Autumn fat = 35%
      expect(targets.fatCalPercent, closeTo(35.0, 0.5));

      // Gas = 40g
      expect(targets.dailyGasFuelG, equals(40.0));
    });

    test('Scenario 3: Зимняя автономка (2 чел, 5 дней, 60 км, 1500 м подъем, extreme_cold)', () {
      final profile = TripProfile(
        id: 'bench_3',
        title: 'Зимняя автономка',
        groupSize: 2,
        durationDays: 5,
        activeDays: 5,
        totalDistanceKm: 60.0,
        totalAscentMeters: 1500.0,
        season: Season.extreme_cold,
        activityType: ActivityType.survival,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = calculator.calculate(profile);

      // Equivalent distance = 60 + 15 = 75 km. Survival -> PAL = 2.6
      expect(targets.equivalentDistanceKm, equals(75.0));
      expect(targets.pal, equals(2.6));

      // Extreme cold bonus = +1000 kcal
      expect(targets.coldBonusKcal, equals(1000.0));

      // Daily calories = (1698.75 * 2.6) + 1000 = 4416.75 + 1000 = 5416.75
      expect(targets.dailyCalories, closeTo(5416.75, 0.1));

      // Extreme cold fat = 40%, gas = 100g, protein = 2.0g/kg (150g)
      expect(targets.dailyProteinG, equals(150.0));
      expect(targets.dailyGasFuelG, equals(100.0));
      expect(targets.fatCalPercent, closeTo(40.0, 0.5));
    });
  });
}
