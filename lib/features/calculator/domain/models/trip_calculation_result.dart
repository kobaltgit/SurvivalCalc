import 'package:survival_calc/features/calculator/domain/models/macronutrient_targets.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class TripCalculationResult {
  final TripProfile profile;
  final MacronutrientTargets targets;
  final List<DailyRation> dailyRations; // Shared / Common group rations
  final Map<String, List<DailyRation>> individualRations; // Key: Participant ID -> their specific rations
  final List<Participant> participants;
  final List<ShoppingListItem> shoppingList;
  final List<GearItem> gearList;

  // Weight statistics (in kg and grams)
  final double totalPersonalGearWeightKg;
  final double totalGroupGearWeightKg;
  final double groupGearWeightPerPersonKg;
  final double totalGearWeightPerPersonKg;
  final double foodWeightPerPersonPerDayKg;
  final double totalFoodWeightPerPersonKg;
  final double totalFoodWeightAllGroupKg;
  final double startPackWeightPerPersonKg;
  final List<double> dailyPackWeightsPerPersonKg;

  const TripCalculationResult({
    required this.profile,
    required this.targets,
    required this.dailyRations,
    this.individualRations = const {},
    this.participants = const [],
    required this.shoppingList,
    required this.gearList,
    required this.totalPersonalGearWeightKg,
    required this.totalGroupGearWeightKg,
    required this.groupGearWeightPerPersonKg,
    required this.totalGearWeightPerPersonKg,
    required this.foodWeightPerPersonPerDayKg,
    required this.totalFoodWeightPerPersonKg,
    required this.totalFoodWeightAllGroupKg,
    required this.startPackWeightPerPersonKg,
    required this.dailyPackWeightsPerPersonKg,
  });

  /// Checked gear count
  int get checkedGearCount => gearList.where((g) => g.isChecked).length;
  int get totalGearCount => gearList.length;
  double get gearProgress =>
      totalGearCount == 0 ? 0.0 : checkedGearCount / totalGearCount;
}
