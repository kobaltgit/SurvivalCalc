import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';

class LoadDistributionService {
  const LoadDistributionService();

  /// Automatically distributes group gear and food items across participants
  /// using a greedy load-balancing algorithm weighted by participant strength ratios.
  List<Participant> autoDistribute({
    required List<Participant> participants,
    required List<GearItem> allGear,
    required List<ShoppingListItem> shoppingList,
    required double personalGearWeightKg,
  }) {
    if (participants.isEmpty) return [];

    // Filter group gear items
    final groupGear = allGear
        .where((g) => g.type == GearType.group)
        .toList()
      ..sort((a, b) => b.totalWeightG.compareTo(a.totalWeightG));

    // Base personal gear items (common to everyone, excluding personalized items)
    final basePersonalGear = allGear.where((g) {
      if (g.type != GearType.personal) return false;
      if (g.id == 'gear_med_asthma' ||
          g.id == 'gear_med_joints' ||
          g.id == 'gear_med_gi' ||
          g.id == 'gear_cook_solo') {
        return false;
      }
      return true;
    }).toList();

    // Specific personal items lookup
    final asthmaItem = allGear.where((g) => g.id == 'gear_med_asthma').firstOrNull;
    final jointsItem = allGear.where((g) => g.id == 'gear_med_joints').firstOrNull;
    final giItem = allGear.where((g) => g.id == 'gear_med_gi').firstOrNull;
    final cookSoloItem = allGear.where((g) => g.id == 'gear_cook_solo').firstOrNull;

    // Sort food items descending by total weight
    final sortedFood = List<ShoppingListItem>.from(shoppingList)
      ..sort((a, b) => b.totalGrams.compareTo(a.totalGrams));

    // Initialize participants with clean lists and personalized personal gear
    final currentList = participants.map((p) {
      final pGear = List<GearItem>.from(basePersonalGear);

      if (p.medicalConditions.contains(MedicalCondition.asthma) && asthmaItem != null) {
        pGear.add(asthmaItem.copyWith(quantity: 1));
      }
      if (p.medicalConditions.contains(MedicalCondition.joint_pain) && jointsItem != null) {
        pGear.add(jointsItem.copyWith(quantity: 1));
      }
      if (p.medicalConditions.contains(MedicalCondition.gi_issues) && giItem != null) {
        pGear.add(giItem.copyWith(quantity: 1));
      }
      if (p.hasSpecialDiet && cookSoloItem != null) {
        pGear.add(cookSoloItem.copyWith(quantity: 1));
      }

      final pWeightKg = pGear.isNotEmpty
          ? pGear.fold<int>(0, (sum, g) => sum + g.totalWeightG) / 1000.0
          : personalGearWeightKg;

      return p.copyWith(
        personalGear: pGear,
        personalGearWeightKg: pWeightKg,
        assignedGear: [],
        assignedFood: [],
      );
    }).toList();

    // 1. Role-based priority assignments for key group items
    final remainingGroupGear = List<GearItem>.from(groupGear);

    // Medic priority: group first-aid kit & medical equipment
    final medicIdx = currentList.indexWhere((p) => p.role == TripRole.medic);
    if (medicIdx != -1) {
      final medItems = remainingGroupGear.where((g) =>
          g.category == GearCategory.med_hygiene ||
          g.id == 'gear_31' ||
          g.id == 'gear_med_allergy' ||
          g.id == 'gear_med_pressure').toList();
      for (final item in medItems) {
        remainingGroupGear.remove(item);
        final target = currentList[medicIdx];
        currentList[medicIdx] = target.copyWith(assignedGear: [...target.assignedGear, item]);
      }
    }

    // Repair master priority: repair kit & field tools
    final repairIdx = currentList.indexWhere((p) => p.role == TripRole.repairMaster);
    if (repairIdx != -1) {
      final repairItems = remainingGroupGear.where((g) =>
          g.id == 'gear_23' ||
          g.id == 'gear_24' ||
          g.id == 'gear_25').toList();
      for (final item in repairItems) {
        remainingGroupGear.remove(item);
        final target = currentList[repairIdx];
        currentList[repairIdx] = target.copyWith(assignedGear: [...target.assignedGear, item]);
      }
    }

    // Navigator or Leader priority: navigation and comms
    final navIdx = currentList.indexWhere((p) => p.role == TripRole.navigator);
    final leaderIdx = currentList.indexWhere((p) => p.role == TripRole.leader);
    final commsTargetIdx = navIdx != -1 ? navIdx : leaderIdx;
    if (commsTargetIdx != -1) {
      final commsItems = remainingGroupGear.where((g) =>
          g.id == 'gear_27' ||
          g.id == 'gear_30').toList();
      for (final item in commsItems) {
        remainingGroupGear.remove(item);
        final target = currentList[commsTargetIdx];
        currentList[commsTargetIdx] = target.copyWith(assignedGear: [...target.assignedGear, item]);
      }
    }

    // 2. Distribute remaining heavy group gear items with load-balancing
    for (final gear in remainingGroupGear) {
      // Find participant with minimum weighted load
      currentList.sort((a, b) {
        final loadA = a.totalPackWeightKg / (a.strengthRatio <= 0 ? 1.0 : a.strengthRatio);
        final loadB = b.totalPackWeightKg / (b.strengthRatio <= 0 ? 1.0 : b.strengthRatio);
        return loadA.compareTo(loadB);
      });

      final target = currentList.first;
      final updatedGear = [...target.assignedGear, gear];
      currentList[0] = target.copyWith(assignedGear: updatedGear);
    }

    // 3. Distribute food items
    for (final food in sortedFood) {
      currentList.sort((a, b) {
        final loadA = a.totalPackWeightKg / (a.strengthRatio <= 0 ? 1.0 : a.strengthRatio);
        final loadB = b.totalPackWeightKg / (b.strengthRatio <= 0 ? 1.0 : b.strengthRatio);
        return loadA.compareTo(loadB);
      });

      final target = currentList.first;
      final updatedFood = [...target.assignedFood, food];
      currentList[0] = target.copyWith(assignedFood: updatedFood);
    }

    // Restore original ordering of participants by ID/name
    currentList.sort((a, b) => a.name.compareTo(b.name));
    return currentList;
  }

  /// Reassigns a gear item to a specific participant
  List<Participant> reassignGearItem({
    required List<Participant> participants,
    required String gearId,
    required String targetParticipantId,
  }) {
    GearItem? itemToMove;

    // Find and remove item from previous holder
    final updated = participants.map((p) {
      final gearList = List<GearItem>.from(p.assignedGear);
      final idx = gearList.indexWhere((g) => g.id == gearId);
      if (idx != -1) {
        itemToMove = gearList.removeAt(idx);
        return p.copyWith(assignedGear: gearList);
      }
      return p;
    }).toList();

    if (itemToMove == null) return participants;

    // Add item to new holder
    return updated.map((p) {
      if (p.id == targetParticipantId) {
        return p.copyWith(assignedGear: [...p.assignedGear, itemToMove!]);
      }
      return p;
    }).toList();
  }

  /// Reassigns a food item to a specific participant
  List<Participant> reassignFoodItem({
    required List<Participant> participants,
    required String foodId,
    required String targetParticipantId,
  }) {
    ShoppingListItem? itemToMove;

    final updated = participants.map((p) {
      final foodList = List<ShoppingListItem>.from(p.assignedFood);
      final idx = foodList.indexWhere((f) => f.foodItem.id == foodId);
      if (idx != -1) {
        itemToMove = foodList.removeAt(idx);
        return p.copyWith(assignedFood: foodList);
      }
      return p;
    }).toList();

    if (itemToMove == null) return participants;

    return updated.map((p) {
      if (p.id == targetParticipantId) {
        return p.copyWith(assignedFood: [...p.assignedFood, itemToMove!]);
      }
      return p;
    }).toList();
  }

  /// Generates a shareable Markdown report for a single participant
  String generateParticipantReport(Participant participant, {List<int>? dutyDays}) {
    final sb = StringBuffer();
    sb.writeln('🎒 **Индивидуальная раскладка: ${participant.name}**');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('${participant.role.emoji} **Должность:** ${participant.role.displayNameRu}');
    if (dutyDays != null && dutyDays.isNotEmpty) {
      sb.writeln('🔥 **Дежурство по кухне:** День ${dutyDays.join(', День ')}');
    }
    sb.writeln('⚖️ **Общий вес рюкзака:** ${participant.totalPackWeightKg.toStringAsFixed(2)} кг');
    sb.writeln('  • Личное снаряжение: ${participant.personalGearWeightKg.toStringAsFixed(2)} кг');
    sb.writeln('  • Назначенное групп. снаряжение: ${participant.assignedGroupGearWeightKg.toStringAsFixed(2)} кг');
    sb.writeln('  • Продуктовая раскладка: ${participant.assignedFoodWeightKg.toStringAsFixed(2)} кг');
    sb.writeln('  • Носимая вода на старт: 1.5 кг');
    sb.writeln();

    if (participant.personalGear.isNotEmpty) {
      sb.writeln('🎒 **Личное снаряжение:**');
      for (final g in participant.personalGear) {
        sb.writeln('  [ ] ${g.nameRu} — ${g.totalWeightG} г');
      }
      sb.writeln();
    }

    if (participant.assignedGear.isNotEmpty) {
      sb.writeln('🏕️ **Групповое снаряжение к переноске:**');
      for (final g in participant.assignedGear) {
        sb.writeln('  [ ] ${g.nameRu} ${g.quantity > 1 ? '(x${g.quantity})' : ''} — ${g.totalWeightG} г');
      }
      sb.writeln();
    }

    if (participant.assignedFood.isNotEmpty) {
      sb.writeln('🥫 **Продукты к закупке и переноске:**');
      for (final f in participant.assignedFood) {
        sb.writeln('  [ ] ${f.foodItem.nameRu} — ${f.totalGrams} г (${f.totalPortions} порц.)');
      }
      sb.writeln();
    }

    return sb.toString();
  }
}
