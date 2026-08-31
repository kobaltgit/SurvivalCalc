import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/macronutrient_targets.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class RationGeneratorService {
  const RationGeneratorService();

  List<DailyRation> generateRations({
    required TripProfile profile,
    required MacronutrientTargets targets,
    required List<FoodItem> availableFoods,
    DietaryRestriction dietaryRestriction = DietaryRestriction.none,
  }) {
    final List<DailyRation> rations = [];
    final foodMap = {for (var f in availableFoods) f.id: f};

    // Helper to substitute food if it violates dietary restriction
    String resolveFoodId(String originalId) {
      if (dietaryRestriction == DietaryRestriction.none) return originalId;

      switch (dietaryRestriction) {
        case DietaryRestriction.vegetarian:
          if (['food_13', 'food_14', 'food_15', 'food_16', 'food_19', 'food_20', 'food_24'].contains(originalId)) {
            // Replace meats with red lentils, chickpeas or egg powder
            return originalId == 'food_14' || originalId == 'food_15' ? 'food_08' : 'food_09';
          }
          break;
        case DietaryRestriction.lactose_free:
          if (['food_49', 'food_17'].contains(originalId)) {
            // Replace milk powder/cheese with coconut oil or raisins
            return originalId == 'food_49' ? 'food_28' : 'food_35';
          }
          break;
        case DietaryRestriction.gluten_free:
          if (['food_03', 'food_04', 'food_05', 'food_06', 'food_07', 'food_45', 'food_43'].contains(originalId)) {
            // Replace oatmeal/pasta/couscous with buckwheat, rice or corn grits
            return originalId == 'food_03' || originalId == 'food_04' ? 'food_01' : 'food_02';
          }
          break;
        case DietaryRestriction.nut_allergy:
          if (['food_27', 'food_29', 'food_30', 'food_31', 'food_32'].contains(originalId)) {
            // Replace nuts/peanut butter with dried apricots or sunflower kozinaki
            return originalId == 'food_27' ? 'food_40' : 'food_34';
          }
          break;
        case DietaryRestriction.no_sugar:
          if (['food_48', 'food_41', 'food_44'].contains(originalId)) {
            // Replace sugar with dark chocolate 85% or almonds
            return originalId == 'food_48' ? 'food_30' : 'food_42';
          }
          break;
        case DietaryRestriction.none:
          break;
      }
      return originalId;
    }

    // Helper to pick foods by id or fallback to default
    FoodItem getFood(String id, [FoodItem? fallback]) {
      final safeId = resolveFoodId(id);
      return foodMap[safeId] ??
          fallback ??
          availableFoods.firstWhere((f) => f.id == safeId,
              orElse: () => availableFoods.first);
    }

    // Diverse meal presets for cycling across days
    final breakfastOptions = [
      // Preset 1: Oatmeal with milk, dried fruits, butter, coffee, sugar & salt
      [
        {'id': 'food_03', 'baseG': 70}, // Oatmeal traditional
        {'id': 'food_49', 'baseG': 25}, // Milk powder
        {'id': 'food_35', 'baseG': 30}, // Raisins
        {'id': 'food_25', 'baseG': 20}, // Ghee butter
        {'id': 'food_51', 'baseG': 4},  // Coffee
        {'id': 'food_48', 'baseG': 25}, // Sugar
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
      ],
      // Preset 2: Buckwheat porridge with egg powder, jerky, sugar & salt
      [
        {'id': 'food_01', 'baseG': 80}, // Buckwheat
        {'id': 'food_18', 'baseG': 30}, // Egg powder
        {'id': 'food_25', 'baseG': 20}, // Ghee
        {'id': 'food_50', 'baseG': 5},  // Tea
        {'id': 'food_48', 'baseG': 20}, // Sugar
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
      ],
      // Preset 3: Couscous with sublimated beef, ghee, cocoa, sugar & salt
      [
        {'id': 'food_07', 'baseG': 70}, // Couscous
        {'id': 'food_14', 'baseG': 30}, // Freeze-dried beef
        {'id': 'food_25', 'baseG': 20}, // Ghee
        {'id': 'food_52', 'baseG': 18}, // Cocoa
        {'id': 'food_49', 'baseG': 20}, // Milk powder
        {'id': 'food_48', 'baseG': 20}, // Sugar
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
      ],
      // Preset 4: Quick Oats with peanuts, dried apricots, tea, sugar & salt
      [
        {'id': 'food_04', 'baseG': 65}, // Quick Oats
        {'id': 'food_27', 'baseG': 30}, // Peanut butter
        {'id': 'food_34', 'baseG': 30}, // Dried apricots
        {'id': 'food_50', 'baseG': 5},  // Tea
        {'id': 'food_48', 'baseG': 20}, // Sugar
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
      ],
    ];

    final lunchOptions = [
      // Preset 1: Army crackers, dry cured sausage, cheese, isotonic, nuts
      [
        {'id': 'food_45', 'baseG': 50}, // Army crackers
        {'id': 'food_16', 'baseG': 50}, // Salami sausage
        {'id': 'food_17', 'baseG': 40}, // Parmesan cheese
        {'id': 'food_29', 'baseG': 30}, // Walnuts
        {'id': 'food_47', 'baseG': 25}, // Isotonic
      ],
      // Preset 2: Jerky, lard/salot, dates, almonds, isotonic
      [
        {'id': 'food_13', 'baseG': 40}, // Jerky
        {'id': 'food_24', 'baseG': 40}, // Lard/salot
        {'id': 'food_45', 'baseG': 45}, // Crackers
        {'id': 'food_36', 'baseG': 40}, // Dates
        {'id': 'food_30', 'baseG': 30}, // Almonds
        {'id': 'food_47', 'baseG': 25}, // Isotonic
      ],
      // Preset 3: Pemmican, hazelnuts, dried cranberries, crackers
      [
        {'id': 'food_19', 'baseG': 50}, // Pemmican
        {'id': 'food_45', 'baseG': 45}, // Crackers
        {'id': 'food_31', 'baseG': 35}, // Hazelnuts
        {'id': 'food_38', 'baseG': 25}, // Dried cranberries
        {'id': 'food_47', 'baseG': 25}, // Isotonic
      ],
    ];

    final dinnerOptions = [
      // Preset 1: Pasta with freeze-dried chicken, parmesan, ghee, garlic, spices & salt
      [
        {'id': 'food_05', 'baseG': 85}, // Pasta
        {'id': 'food_15', 'baseG': 35}, // Freeze-dried chicken
        {'id': 'food_17', 'baseG': 30}, // Parmesan
        {'id': 'food_25', 'baseG': 25}, // Ghee
        {'id': 'food_54', 'baseG': 3},  // Dried garlic
        {'id': 'food_55', 'baseG': 2},  // Spices
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
        {'id': 'food_50', 'baseG': 5},  // Tea
        {'id': 'food_48', 'baseG': 20}, // Sugar
      ],
      // Preset 2: Mashed potato flakes with beef, lard, bouillon & salt
      [
        {'id': 'food_06', 'baseG': 65}, // Potato flakes
        {'id': 'food_14', 'baseG': 35}, // Freeze-dried beef
        {'id': 'food_24', 'baseG': 30}, // Lard/salot
        {'id': 'food_56', 'baseG': 10}, // Bouillon cube
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
        {'id': 'food_53', 'baseG': 30}, // Fruit kissel
      ],
      // Preset 3: Red lentils with jerky, ghee, spices, sugar, tea & salt
      [
        {'id': 'food_09', 'baseG': 75}, // Red lentils
        {'id': 'food_13', 'baseG': 40}, // Jerky
        {'id': 'food_25', 'baseG': 25}, // Ghee
        {'id': 'food_55', 'baseG': 2},  // Spices
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
        {'id': 'food_50', 'baseG': 5},  // Tea
        {'id': 'food_48', 'baseG': 20}, // Sugar
      ],
      // Preset 4: Rice with freeze-dried beef, ghee, spices, sugar, tea & salt
      [
        {'id': 'food_02', 'baseG': 80}, // Rice
        {'id': 'food_14', 'baseG': 35}, // Freeze-dried beef
        {'id': 'food_25', 'baseG': 25}, // Ghee
        {'id': 'food_55', 'baseG': 2},  // Spices
        {'id': 'food_46', 'baseG': 5},  // Iodized table salt
        {'id': 'food_50', 'baseG': 5},  // Tea
        {'id': 'food_48', 'baseG': 20}, // Sugar
      ],
    ];

    final pocketFoodOptions = [
      // Preset 1: Dark chocolate, protein bar, banana chips
      [
        {'id': 'food_41', 'baseG': 35}, // Dark chocolate
        {'id': 'food_42', 'baseG': 60}, // Protein bar
        {'id': 'food_37', 'baseG': 30}, // Banana chips
      ],
      // Preset 2: Energy gel, sunflower halva, salted peanuts
      [
        {'id': 'food_43', 'baseG': 40}, // Energy gel
        {'id': 'food_39', 'baseG': 50}, // Halva
        {'id': 'food_32', 'baseG': 35}, // Peanuts
      ],
      // Preset 3: Kozinaki, fruit pastila, dark chocolate
      [
        {'id': 'food_40', 'baseG': 50}, // Kozinaki
        {'id': 'food_44', 'baseG': 30}, // Fruit pastille
        {'id': 'food_41', 'baseG': 35}, // Dark chocolate
      ],
    ];

    for (int day = 1; day <= profile.durationDays; day++) {
      final bool isActiveDay = day <= profile.activeDays;
      final int cycleIndex = day - 1;

      // Select preset per meal slot
      final bPreset =
          breakfastOptions[cycleIndex % breakfastOptions.length];
      final lPreset = lunchOptions[cycleIndex % lunchOptions.length];
      final dPreset = dinnerOptions[cycleIndex % dinnerOptions.length];
      final pPreset =
          pocketFoodOptions[cycleIndex % pocketFoodOptions.length];

      List<MealItem> buildSlotItems(
          List<Map<String, dynamic>> preset, MealSlotType slotType) {
        final targetSlotCalories =
            targets.dailyCalories * slotType.defaultRatio;

        // Calculate unscaled calories of preset
        double baseSlotCalories = 0.0;
        for (var item in preset) {
          final food = getFood(item['id'] as String);
          final grams = (item['baseG'] as num).toInt();
          baseSlotCalories += (food.calories100g * grams) / 100.0;
        }

        final double scale = baseSlotCalories > 0
            ? (targetSlotCalories / baseSlotCalories)
            : 1.0;

        return preset.map((item) {
          final food = getFood(item['id'] as String);
          final baseG = (item['baseG'] as num).toInt();
          final scaledG = (baseG * scale).round().clamp(1, 400);
          return MealItem(foodItem: food, grams: scaledG);
        }).toList();
      }

      final slots = [
        DailyMealSlot(
          slotType: MealSlotType.breakfast,
          items: buildSlotItems(bPreset, MealSlotType.breakfast),
        ),
        DailyMealSlot(
          slotType: MealSlotType.lunch_snack,
          items: buildSlotItems(lPreset, MealSlotType.lunch_snack),
        ),
        DailyMealSlot(
          slotType: MealSlotType.dinner,
          items: buildSlotItems(dPreset, MealSlotType.dinner),
        ),
        DailyMealSlot(
          slotType: MealSlotType.pocket_food,
          items: buildSlotItems(pPreset, MealSlotType.pocket_food),
        ),
      ];

      rations.add(DailyRation(
        dayNumber: day,
        isActiveDay: isActiveDay,
        mealSlots: slots,
      ));
    }

    return rations;
  }

  List<ShoppingListItem> buildShoppingList({
    required List<DailyRation> rations,
    required int groupSize,
  }) {
    final Map<String, ({FoodItem food, int totalGrams, double totalCalories})>
        aggregated = {};

    for (final ration in rations) {
      for (final slot in ration.mealSlots) {
        for (final item in slot.items) {
          final current = aggregated[item.foodItem.id];
          final itemTotalGrams = item.grams * groupSize;
          final itemTotalCalories = item.calories * groupSize;

          if (current == null) {
            aggregated[item.foodItem.id] = (
              food: item.foodItem,
              totalGrams: itemTotalGrams,
              totalCalories: itemTotalCalories,
            );
          } else {
            aggregated[item.foodItem.id] = (
              food: item.foodItem,
              totalGrams: current.totalGrams + itemTotalGrams,
              totalCalories: current.totalCalories + itemTotalCalories,
            );
          }
        }
      }
    }

    final list = aggregated.values.map((v) {
      final portionG = v.food.portionG > 0 ? v.food.portionG : 50;
      final totalPortions = (v.totalGrams / portionG).ceil();
      return ShoppingListItem(
        foodItem: v.food,
        totalGrams: v.totalGrams,
        totalPortions: totalPortions,
        totalCalories: v.totalCalories,
      );
    }).toList();

    // Sort by category and then by name
    list.sort((a, b) {
      final catCompare =
          a.foodItem.category.index.compareTo(b.foodItem.category.index);
      if (catCompare != 0) return catCompare;
      return a.foodItem.nameRu.compareTo(b.foodItem.nameRu);
    });

    return list;
  }

  /// Generates a fair round-robin duty roster across days.
  /// If groupSize >= 4, pairs of 2 are assigned. Otherwise, 1 person per day.
  List<DailyRation> assignDutySchedule({
    required List<DailyRation> rations,
    required List<Participant> participants,
  }) {
    if (rations.isEmpty || participants.isEmpty) return rations;

    final n = participants.length;
    final pairSize = n >= 4 ? 2 : 1;

    return rations.asMap().entries.map((entry) {
      final dayIdx = entry.key;
      final r = entry.value;

      final List<String> dutyIds = [];
      for (int i = 0; i < pairSize; i++) {
        final participantIdx = (dayIdx * pairSize + i) % n;
        dutyIds.add(participants[participantIdx].id);
      }

      return r.copyWith(dutyParticipantIds: dutyIds);
    }).toList();
  }
}
