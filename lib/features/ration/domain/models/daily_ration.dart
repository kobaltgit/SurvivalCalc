import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';

class MealItem {
  final FoodItem foodItem;
  final int grams;

  const MealItem({
    required this.foodItem,
    required this.grams,
  });

  double get calories => (foodItem.calories100g * grams) / 100.0;
  double get proteinG => (foodItem.protein100g * grams) / 100.0;
  double get fatG => (foodItem.fat100g * grams) / 100.0;
  double get carbsG => (foodItem.carbs100g * grams) / 100.0;
  double get sodiumMg => (foodItem.sodiumMg100g * grams) / 100.0;
  double get potassiumMg => (foodItem.potassiumMg100g * grams) / 100.0;
  double get magnesiumMg => (foodItem.magnesiumMg100g * grams) / 100.0;
  double get vitCMg => (foodItem.vitCMg100g * grams) / 100.0;

  MealItem copyWith({
    FoodItem? foodItem,
    int? grams,
  }) {
    return MealItem(
      foodItem: foodItem ?? this.foodItem,
      grams: grams ?? this.grams,
    );
  }
}

class DailyMealSlot {
  final MealSlotType slotType;
  final List<MealItem> items;

  const DailyMealSlot({
    required this.slotType,
    required this.items,
  });

  String get nameRu => slotType.displayNameRu;

  int get totalWeightG => items.fold<int>(0, (sum, i) => sum + i.grams);
  double get totalCalories => items.fold<double>(0, (sum, i) => sum + i.calories);
  double get totalProteinG => items.fold<double>(0, (sum, i) => sum + i.proteinG);
  double get totalFatG => items.fold<double>(0, (sum, i) => sum + i.fatG);
  double get totalCarbsG => items.fold<double>(0, (sum, i) => sum + i.carbsG);
  double get totalSodiumMg => items.fold<double>(0, (sum, i) => sum + i.sodiumMg);

  DailyMealSlot copyWith({
    MealSlotType? slotType,
    List<MealItem>? items,
  }) {
    return DailyMealSlot(
      slotType: slotType ?? this.slotType,
      items: items ?? this.items,
    );
  }
}

class DailyRation {
  final int dayNumber;
  final bool isActiveDay;
  final List<DailyMealSlot> mealSlots;
  final List<String> dutyParticipantIds;

  const DailyRation({
    required this.dayNumber,
    required this.isActiveDay,
    required this.mealSlots,
    this.dutyParticipantIds = const [],
  });

  int get totalWeightG =>
      mealSlots.fold<int>(0, (sum, s) => sum + s.totalWeightG);
  double get totalCalories =>
      mealSlots.fold<double>(0, (sum, s) => sum + s.totalCalories);
  double get totalProteinG =>
      mealSlots.fold<double>(0, (sum, s) => sum + s.totalProteinG);
  double get totalFatG =>
      mealSlots.fold<double>(0, (sum, s) => sum + s.totalFatG);
  double get totalCarbsG =>
      mealSlots.fold<double>(0, (sum, s) => sum + s.totalCarbsG);
  double get totalSodiumMg =>
      mealSlots.fold<double>(0, (sum, s) => sum + s.totalSodiumMg);

  DailyRation copyWith({
    int? dayNumber,
    bool? isActiveDay,
    List<DailyMealSlot>? mealSlots,
    List<String>? dutyParticipantIds,
  }) {
    return DailyRation(
      dayNumber: dayNumber ?? this.dayNumber,
      isActiveDay: isActiveDay ?? this.isActiveDay,
      mealSlots: mealSlots ?? this.mealSlots,
      dutyParticipantIds: dutyParticipantIds ?? this.dutyParticipantIds,
    );
  }
}

class ShoppingListItem {
  final FoodItem foodItem;
  final int totalGrams;
  final int totalPortions;
  final double totalCalories;

  const ShoppingListItem({
    required this.foodItem,
    required this.totalGrams,
    required this.totalPortions,
    required this.totalCalories,
  });
}
