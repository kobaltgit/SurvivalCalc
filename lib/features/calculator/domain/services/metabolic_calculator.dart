import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/macronutrient_targets.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class MetabolicCalculator {
  const MetabolicCalculator();

  MacronutrientTargets calculate(TripProfile profile) {
    // 1. Base Metabolic Rate (BMR) - Mifflin-St Jeor (Standardized 30yo, 175cm)
    // BMR = (10 * weight_kg) + (6.25 * 175) - (5 * 30) + 5
    final double bmr = (10.0 * profile.avgParticipantWeightKg) +
        (6.25 * 175.0) -
        (5.0 * 30.0) +
        5.0;

    // 2. Equivalent Distance (incorporating elevation gain: +1km per 100m ascent)
    final double equivalentDistanceKm =
        profile.totalDistanceKm + (profile.totalAscentMeters / 100.0);

    // 3. Daily equivalent km
    final int safeActiveDays =
        profile.activeDays > 0 ? profile.activeDays : 1;
    final double dailyEquivalentKm = equivalentDistanceKm / safeActiveDays;

    // 4. Physical Activity Level (PAL) & Activity Modifier
    double pal = 1.8;
    if (profile.activityType == ActivityType.survival ||
        dailyEquivalentKm > 20.0) {
      pal = 2.6;
    } else if (dailyEquivalentKm >= 12.0) {
      pal = 2.2;
    } else {
      pal = 1.8;
    }

    // Activity specific metabolic bonus (hypoxia, water cooling, muscle endurance)
    double activityBonusKcal = 0.0;
    if (profile.activityType == ActivityType.mountain) {
      activityBonusKcal = 250.0; // Altitude & terrain adaptation
    } else if (profile.activityType == ActivityType.water) {
      activityBonusKcal = 150.0; // Continuous upper-body paddling & water cooling
    }

    // 5. Cold Bonus
    double coldBonusKcal = 0.0;
    if (profile.season == Season.winter) {
      coldBonusKcal = 500.0;
    } else if (profile.season == Season.extreme_cold) {
      coldBonusKcal = 1000.0;
    }

    // 6. Target Daily Calories
    final double dailyCalories =
        (bmr * pal) + coldBonusKcal + activityBonusKcal;

    // 7. Protein target (1.6 - 2.0 g / kg)
    double proteinMultiplier = 1.6;
    if (profile.activityType == ActivityType.survival ||
        profile.season == Season.extreme_cold) {
      proteinMultiplier = 2.0;
    } else if (profile.activityType == ActivityType.mountain) {
      proteinMultiplier = 1.8;
    } else if (profile.activityType == ActivityType.water) {
      proteinMultiplier = 1.7;
    }
    final double dailyProteinG =
        profile.avgParticipantWeightKg * proteinMultiplier;

    // 8. Fat target (30% in summer, 35% in spring_autumn, 40% in winter/extreme)
    double fatPercent = 0.30;
    if (profile.season == Season.winter ||
        profile.season == Season.extreme_cold) {
      fatPercent = 0.40;
    } else if (profile.season == Season.spring_autumn) {
      fatPercent = 0.35;
    }
    final double dailyFatG = (dailyCalories * fatPercent) / 9.0;

    // 9. Carbs target (remaining calories, 4 kcal/g)
    final double proteinCalories = dailyProteinG * 4.0;
    final double fatCalories = dailyFatG * 9.0;
    final double remainingCarbsCalories =
        (dailyCalories - (proteinCalories + fatCalories)).clamp(0.0, 10000.0);
    final double dailyCarbsG = remainingCarbsCalories / 4.0;

    // 10. Sodium (Na): 2500 - 4000 mg
    double dailySodiumMg = 3000.0;
    if (profile.season == Season.summer ||
        profile.activityType == ActivityType.survival) {
      dailySodiumMg = 4000.0;
    } else if (profile.activityType == ActivityType.mountain) {
      dailySodiumMg = 3500.0;
    } else if (profile.activityType == ActivityType.water) {
      dailySodiumMg = 3200.0;
    }

    // 11. Water (Liters/day): 2.5 - 3.5 L base + load/heat bonus
    double dailyWaterLiters = 3.0;
    if (profile.season == Season.summer) {
      dailyWaterLiters += 1.0;
    } else if (pal >= 2.6 || profile.activityType == ActivityType.survival) {
      dailyWaterLiters += 0.5;
    }

    // 12. Gas / Fuel (g/person/day): 40g (summer/spring_autumn), 80g (winter), 100g (extreme_cold)
    double dailyGasFuelG = 40.0;
    if (profile.season == Season.extreme_cold) {
      dailyGasFuelG = 100.0;
    } else if (profile.season == Season.winter) {
      dailyGasFuelG = 80.0;
    }

    return MacronutrientTargets(
      dailyCalories: dailyCalories,
      dailyProteinG: dailyProteinG,
      dailyFatG: dailyFatG,
      dailyCarbsG: dailyCarbsG,
      dailySodiumMg: dailySodiumMg,
      dailyWaterLiters: dailyWaterLiters,
      dailyGasFuelG: dailyGasFuelG,
      bmr: bmr,
      pal: pal,
      equivalentDistanceKm: equivalentDistanceKm,
      dailyEquivalentKm: dailyEquivalentKm,
      coldBonusKcal: coldBonusKcal,
    );
  }
}
