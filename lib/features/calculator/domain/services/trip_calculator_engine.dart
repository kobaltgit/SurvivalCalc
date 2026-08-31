import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/macronutrient_targets.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/gear/domain/services/gear_calculator_service.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/ration/domain/services/ration_generator_service.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class TripCalculatorEngine {
  final MetabolicCalculator metabolicCalculator;
  final RationGeneratorService rationGeneratorService;
  final GearCalculatorService gearCalculatorService;

  const TripCalculatorEngine({
    this.metabolicCalculator = const MetabolicCalculator(),
    this.rationGeneratorService = const RationGeneratorService(),
    this.gearCalculatorService = const GearCalculatorService(),
  });

  TripCalculationResult calculate({
    required TripProfile profile,
    required List<FoodItem> availableFoods,
    required List<GearItem> allGear,
    List<GearItem>? customGearOverride,
    List<Participant>? participants,
  }) {
    // 1. Calculate metabolic and macronutrient targets
    final MacronutrientTargets targets =
        metabolicCalculator.calculate(profile);

    // 2. Generate daily food rations for shared group
    final List<DailyRation> sharedDailyRations =
        rationGeneratorService.generateRations(
      profile: profile,
      targets: targets,
      availableFoods: availableFoods,
      dietaryRestriction: DietaryRestriction.none,
    );

    // 3. Generate individual rations for participants with special diets
    final Map<String, List<DailyRation>> individualRations = {};
    int specialDietCount = 0;

    if (participants != null && participants.isNotEmpty) {
      for (final p in participants) {
        if (p.hasSpecialDiet) {
          specialDietCount++;
          final primaryDiet = p.dietaryRestrictions.firstWhere(
            (d) => d != DietaryRestriction.none,
            orElse: () => DietaryRestriction.none,
          );
          final personalRations = rationGeneratorService.generateRations(
            profile: profile,
            targets: targets,
            availableFoods: availableFoods,
            dietaryRestriction: primaryDiet,
          );
          individualRations[p.id] = personalRations;
        }
      }
    }

    final int commonGroupSize = (profile.groupSize - specialDietCount).clamp(0, profile.groupSize);

    // 4. Build aggregated shopping list (Shared group + Individual rations)
    List<ShoppingListItem> shoppingList = [];
    if (commonGroupSize > 0) {
      shoppingList = rationGeneratorService.buildShoppingList(
        rations: sharedDailyRations,
        groupSize: commonGroupSize,
      );
    }

    // Merge individual diet shopping items
    for (final entry in individualRations.entries) {
      final indivShopping = rationGeneratorService.buildShoppingList(
        rations: entry.value,
        groupSize: 1,
      );
      // Merge into main shopping list
      final Map<String, ShoppingListItem> map = {for (var item in shoppingList) item.foodItem.id: item};
      for (final item in indivShopping) {
        final existing = map[item.foodItem.id];
        if (existing == null) {
          map[item.foodItem.id] = item;
        } else {
          final totalG = existing.totalGrams + item.totalGrams;
          final portionG = item.foodItem.portionG > 0 ? item.foodItem.portionG : 50;
          map[item.foodItem.id] = ShoppingListItem(
            foodItem: item.foodItem,
            totalGrams: totalG,
            totalPortions: (totalG / portionG).ceil(),
            totalCalories: existing.totalCalories + item.totalCalories,
          );
        }
      }
      shoppingList = map.values.toList();
    }

    // Sort shopping list
    shoppingList.sort((a, b) {
      final catCompare = a.foodItem.category.index.compareTo(b.foodItem.category.index);
      if (catCompare != 0) return catCompare;
      return a.foodItem.nameRu.compareTo(b.foodItem.nameRu);
    });

    // 5. Calculate gear list and weights
    final List<GearItem> gearList = customGearOverride ??
        gearCalculatorService.filterAndScaleGear(
          profile: profile,
          targets: targets,
          allGear: allGear,
          participants: participants,
        );

    final gearWeights = gearCalculatorService.calculateGearWeights(
      gearList: gearList,
      groupSize: profile.groupSize,
    );

    // 6. Food weight metrics
    final totalFoodGramsAllGroup =
        shoppingList.fold<int>(0, (sum, item) => sum + item.totalGrams);
    final double totalFoodAllGroupKg = totalFoodGramsAllGroup / 1000.0;
    final double safeGroupSize =
        profile.groupSize > 0 ? profile.groupSize.toDouble() : 1.0;
    final double totalFoodPerPersonKg = totalFoodAllGroupKg / safeGroupSize;
    final double foodPerPersonPerDayKg = profile.durationDays > 0
        ? totalFoodPerPersonKg / profile.durationDays
        : 0.0;

    // 7. Total backpack weight metrics (Personal gear + Per-person group gear + Per-person total food + 1.5L water)
    const double baseWaterKg = 1.5;
    final double startPackWeightKg = gearWeights.totalGearWeightPerPersonKg +
        totalFoodPerPersonKg +
        baseWaterKg;

    // 8. Calculate daily pack weight decay curve
    final List<double> dailyPackWeights = [];
    for (int d = 0; d < profile.durationDays; d++) {
      final remainingFoodKg =
          totalFoodPerPersonKg - (d * foodPerPersonPerDayKg);
      final currentDayPackWeight = gearWeights.totalGearWeightPerPersonKg +
          (remainingFoodKg > 0 ? remainingFoodKg : 0.0) +
          baseWaterKg;
      dailyPackWeights.add(currentDayPackWeight);
    }

    // Assign duty roster across days
    final List<DailyRation> scheduledDailyRations =
        participants != null && participants.isNotEmpty
            ? rationGeneratorService.assignDutySchedule(
                rations: sharedDailyRations,
                participants: participants,
              )
            : sharedDailyRations;

    return TripCalculationResult(
      profile: profile,
      targets: targets,
      dailyRations: scheduledDailyRations,
      individualRations: individualRations,
      participants: participants ?? const [],
      shoppingList: shoppingList,
      gearList: gearList,
      totalPersonalGearWeightKg: gearWeights.totalPersonalGearWeightKg,
      totalGroupGearWeightKg: gearWeights.totalGroupGearWeightKg,
      groupGearWeightPerPersonKg: gearWeights.groupGearWeightPerPersonKg,
      totalGearWeightPerPersonKg: gearWeights.totalGearWeightPerPersonKg,
      foodWeightPerPersonPerDayKg: foodPerPersonPerDayKg,
      totalFoodWeightPerPersonKg: totalFoodPerPersonKg,
      totalFoodWeightAllGroupKg: totalFoodAllGroupKg,
      startPackWeightPerPersonKg: startPackWeightKg,
      dailyPackWeightsPerPersonKg: dailyPackWeights,
    );
  }
}
