import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/macronutrient_targets.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class GearCalculatorService {
  const GearCalculatorService();

  List<GearItem> filterAndScaleGear({
    required TripProfile profile,
    required MacronutrientTargets targets,
    required List<GearItem> allGear,
    List<Participant>? participants,
  }) {
    final List<GearItem> filtered = [];
    final bool isWinterOrCold = profile.season == Season.winter ||
        profile.season == Season.extreme_cold;
    final bool isSummer = profile.season == Season.summer;
    final bool isSpringAutumn = profile.season == Season.spring_autumn;

    // Calculate dynamic quantities for group equipment
    final int tentCount = (profile.groupSize / 2.0).ceil().clamp(1, 50);
    final double totalGasNeededG =
        targets.dailyGasFuelG * profile.groupSize * profile.durationDays;
    final int gasCanisterCount =
        (totalGasNeededG / 230.0).ceil().clamp(1, 50);
    final int stoveCount = (profile.groupSize / 4.0).ceil().clamp(1, 20);
    final int potCount = (profile.groupSize / 4.0).ceil().clamp(1, 20);

    for (final item in allGear) {
      // 1. Seasonal filter logic
      bool shouldInclude = true;

      if (isWinterOrCold) {
        // Winter mode: Exclude strictly summer items
        if (item.season == GearSeason.summer) {
          shouldInclude = false;
        }
        // Exclude light 3-season tent if winter storm tent is available
        if (item.id == 'gear_01') {
          shouldInclude = false;
        }
        // Exclude gas ultralight burner in extreme cold in favor of multi-fuel
        if (item.id == 'gear_11' &&
            profile.season == Season.extreme_cold) {
          shouldInclude = false;
        }
      } else if (isSummer) {
        // Summer mode: Exclude winter-only gear
        if (item.season == GearSeason.winter ||
            item.category == GearCategory.winter) {
          shouldInclude = false;
        }
        // Exclude winter sleeping bag and demi-season bag
        if (item.id == 'gear_06' || item.id == 'gear_07') {
          shouldInclude = false;
        }
        // Exclude multifuel stove in summer
        if (item.id == 'gear_12') {
          shouldInclude = false;
        }
      } else if (isSpringAutumn) {
        // Demi-season: Exclude pure winter categories like snowshoes/ice axes/baloon covers unless extreme
        if (item.category == GearCategory.winter) {
          shouldInclude = false;
        }
        // Exclude pure summer sleeping bag
        if (item.id == 'gear_05' || item.id == 'gear_07') {
          shouldInclude = false;
        }
        // Exclude multifuel stove unless chosen
        if (item.id == 'gear_12') {
          shouldInclude = false;
        }
      }

      // Activity-based item exclusions
      if (profile.activityType == ActivityType.water && item.id == 'gear_61') {
        // Exclude trekking poles for water trips
        shouldInclude = false;
      }

      if (!shouldInclude) continue;

      // 2. Dynamic quantity scaling and activity-specific overrides
      int quantity = 1;
      bool isMandatory = item.isMandatory;

      if (profile.activityType == ActivityType.mountain) {
        if (item.id == 'gear_61' || item.id == 'gear_57') {
          isMandatory = true;
        }
      } else if (profile.activityType == ActivityType.survival) {
        if (item.id == 'gear_24' ||
            item.id == 'gear_25' ||
            item.id == 'gear_10' ||
            item.id == 'gear_28') {
          isMandatory = true;
        }
      } else if (profile.activityType == ActivityType.water) {
        if (item.id == 'gear_60') {
          quantity = 2; // Extra dry bags for water expedition
          isMandatory = true;
        }
      }

      if (item.type == GearType.group) {
        if (item.id == 'gear_01' || item.id == 'gear_02') {
          // Tents
          quantity = tentCount;
        } else if (item.id == 'gear_15') {
          // Gas canisters (230g)
          quantity = gasCanisterCount;
        } else if (item.id == 'gear_11' || item.id == 'gear_12') {
          // Stoves
          quantity = stoveCount;
        } else if (item.id == 'gear_13') {
          // Pots
          quantity = potCount;
        } else if (item.id == 'gear_04') {
          // Tent pegs
          quantity = tentCount;
        } else if (item.id == 'gear_63') {
          // Avalanche shovel
          quantity = (profile.groupSize / 2.0).ceil().clamp(1, 10);
        } else if (item.id == 'gear_66') {
          // Thermal cover for canister
          quantity = gasCanisterCount;
        }
      }

      filtered.add(item.copyWith(quantity: quantity, isMandatory: isMandatory));
    }

    // 3. Dynamic Medical and Dietary Gear Additions from Participant profiles
    if (participants != null && participants.isNotEmpty) {
      final hasAsthma = participants.any((p) => p.medicalConditions.contains(MedicalCondition.asthma));
      final hasInsectAllergy = participants.any((p) => p.medicalConditions.contains(MedicalCondition.insect_allergy));
      final hasJointPain = participants.any((p) => p.medicalConditions.contains(MedicalCondition.joint_pain));
      final hasHypertension = participants.any((p) => p.medicalConditions.contains(MedicalCondition.hypertension));
      final hasGiIssues = participants.any((p) => p.medicalConditions.contains(MedicalCondition.gi_issues));
      final specialDietCount = participants.where((p) => p.hasSpecialDiet).length;

      if (hasAsthma && !filtered.any((g) => g.id == 'gear_med_asthma')) {
        filtered.add(const GearItem(
          id: 'gear_med_asthma',
          nameRu: 'Ингалятор (Сальбутамол) / Бронхолитик',
          category: GearCategory.med_hygiene,
          type: GearType.personal,
          weightG: 60,
          season: GearSeason.all,
          isMandatory: true,
        ));
      }
      if (hasInsectAllergy && !filtered.any((g) => g.id == 'gear_med_allergy')) {
        filtered.add(const GearItem(
          id: 'gear_med_allergy',
          nameRu: 'Эпинефрин / Противошоковый набор',
          category: GearCategory.med_hygiene,
          type: GearType.group,
          weightG: 80,
          season: GearSeason.all,
          isMandatory: true,
        ));
      }
      if (hasJointPain && !filtered.any((g) => g.id == 'gear_med_joints')) {
        filtered.add(const GearItem(
          id: 'gear_med_joints',
          nameRu: 'Эластичный бинт + НПВС гель (Диклофенак)',
          category: GearCategory.med_hygiene,
          type: GearType.personal,
          weightG: 120,
          season: GearSeason.all,
          isMandatory: true,
        ));
      }
      if (hasHypertension && !filtered.any((g) => g.id == 'gear_med_pressure')) {
        filtered.add(const GearItem(
          id: 'gear_med_pressure',
          nameRu: 'Тонометр компактный + гипотензивные',
          category: GearCategory.med_hygiene,
          type: GearType.group,
          weightG: 150,
          season: GearSeason.all,
          isMandatory: true,
        ));
      }
      if (hasGiIssues && !filtered.any((g) => g.id == 'gear_med_gi')) {
        filtered.add(const GearItem(
          id: 'gear_med_gi',
          nameRu: 'Антациды (Ренни/Маалокс) + Омепразол',
          category: GearCategory.med_hygiene,
          type: GearType.personal,
          weightG: 50,
          season: GearSeason.all,
          isMandatory: true,
        ));
      }
      if (specialDietCount > 0 && !filtered.any((g) => g.id == 'gear_cook_solo')) {
        filtered.add(GearItem(
          id: 'gear_cook_solo',
          nameRu: 'Личный мини-котелок / кружка 0.6л для спец-рациона',
          category: GearCategory.cooking,
          type: GearType.personal,
          weightG: 140,
          quantity: specialDietCount,
          season: GearSeason.all,
          isMandatory: true,
        ));
      }
    }

    return filtered;
  }

  /// Calculates personal and group weight breakdown
  ({
    double totalPersonalGearWeightKg,
    double totalGroupGearWeightKg,
    double groupGearWeightPerPersonKg,
    double totalGearWeightPerPersonKg,
  }) calculateGearWeights({
    required List<GearItem> gearList,
    required int groupSize,
  }) {
    final safeGroupSize = groupSize > 0 ? groupSize : 1;

    int personalGrams = 0;
    int groupGrams = 0;

    for (final item in gearList) {
      if (item.type == GearType.personal) {
        personalGrams += item.totalWeightG;
      } else {
        groupGrams += item.totalWeightG;
      }
    }

    final double personalKg = personalGrams / 1000.0;
    final double groupKg = groupGrams / 1000.0;
    final double groupPerPersonKg = groupKg / safeGroupSize;
    final double totalPerPersonKg = personalKg + groupPerPersonKg;

    return (
      totalPersonalGearWeightKg: personalKg,
      totalGroupGearWeightKg: groupKg,
      groupGearWeightPerPersonKg: groupPerPersonKg,
      totalGearWeightPerPersonKg: totalPerPersonKg,
    );
  }
}
