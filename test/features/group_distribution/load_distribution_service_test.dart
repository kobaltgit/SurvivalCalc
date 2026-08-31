import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/group_distribution/domain/services/load_distribution_service.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';

void main() {
  group('LoadDistributionService Tests', () {
    const service = LoadDistributionService();

    final testGear = [
      const GearItem(
        id: 'gear_01',
        nameRu: 'Палатка 2-местная',
        category: GearCategory.shelter,
        type: GearType.group,
        weightG: 2400,
        season: GearSeason.all,
        isMandatory: true,
      ),
      const GearItem(
        id: 'gear_13',
        nameRu: 'Котелки походные',
        category: GearCategory.cooking,
        type: GearType.group,
        weightG: 900,
        season: GearSeason.all,
        isMandatory: true,
      ),
      const GearItem(
        id: 'gear_15',
        nameRu: 'Газовый баллон 230г',
        category: GearCategory.cooking,
        type: GearType.group,
        weightG: 380,
        quantity: 3,
        season: GearSeason.all,
        isMandatory: true,
      ),
      const GearItem(
        id: 'gear_24',
        nameRu: 'Топор походный',
        category: GearCategory.tools,
        type: GearType.group,
        weightG: 850,
        season: GearSeason.all,
        isMandatory: true,
      ),
    ];

    final testFood = [
      const ShoppingListItem(
        foodItem: FoodItem(
          id: 'food_01',
          nameRu: 'Гречневая крупа',
          category: FoodCategory.grains,
          calories100g: 343,
          protein100g: 13,
          fat100g: 3,
          carbs100g: 62,
          potassiumMg100g: 380,
          magnesiumMg100g: 200,
          sodiumMg100g: 1,
          ironMg100g: 6.7,
          vitCMg100g: 0,
          portionG: 80,
          shelfLifeDays: 730,
        ),
        totalGrams: 1600,
        totalPortions: 20,
        totalCalories: 5488,
      ),
      const ShoppingListItem(
        foodItem: FoodItem(
          id: 'food_14',
          nameRu: 'Сублимированная говядина',
          category: FoodCategory.proteins,
          calories100g: 520,
          protein100g: 65,
          fat100g: 28,
          carbs100g: 0,
          potassiumMg100g: 600,
          magnesiumMg100g: 40,
          sodiumMg100g: 150,
          ironMg100g: 8,
          vitCMg100g: 0,
          portionG: 35,
          shelfLifeDays: 730,
        ),
        totalGrams: 700,
        totalPortions: 20,
        totalCalories: 3640,
      ),
    ];

    test('Evenly distributes load between 4 standard participants', () {
      final participants = [
        const Participant(id: 'p1', name: 'Алексей'),
        const Participant(id: 'p2', name: 'Борис'),
        const Participant(id: 'p3', name: 'Владимир'),
        const Participant(id: 'p4', name: 'Дмитрий'),
      ];

      final distributed = service.autoDistribute(
        participants: participants,
        allGear: testGear,
        shoppingList: testFood,
        personalGearWeightKg: 8.0,
      );

      expect(distributed.length, equals(4));

      // Each participant should have assigned items
      for (final p in distributed) {
        expect(p.totalPackWeightKg, greaterThan(8.0));
      }

      // Check max delta between lightest and heaviest backpack is small (under 2.5 kg)
      final weights = distributed.map((p) => p.totalPackWeightKg).toList();
      final maxW = weights.reduce((a, b) => a > b ? a : b);
      final minW = weights.reduce((a, b) => a < b ? a : b);
      expect(maxW - minW, lessThan(2.5));
    });

    test('Includes and reports personal gear items for each participant', () {
      final personalItem = const GearItem(
        id: 'gear_pers_1',
        nameRu: 'Спальный мешок комфорт',
        category: GearCategory.shelter,
        type: GearType.personal,
        weightG: 1200,
        season: GearSeason.all,
        isMandatory: true,
      );

      final participants = [
        const Participant(id: 'p1', name: 'Иван'),
      ];

      final distributed = service.autoDistribute(
        participants: participants,
        allGear: [...testGear, personalItem],
        shoppingList: testFood,
        personalGearWeightKg: 0.0,
      );

      expect(distributed.first.personalGear, isNotEmpty);
      expect(distributed.first.personalGear.first.nameRu, equals('Спальный мешок комфорт'));

      final report = service.generateParticipantReport(distributed.first);
      expect(report, contains('Личное снаряжение:'));
      expect(report, contains('Спальный мешок комфорт'));
    });

    test('Assigns condition-specific medical gear ONLY to the participant with the condition', () {
      const asthmaItem = GearItem(
        id: 'gear_med_asthma',
        nameRu: 'Ингалятор (Сальбутамол)',
        category: GearCategory.med_hygiene,
        type: GearType.personal,
        weightG: 60,
        season: GearSeason.all,
        isMandatory: true,
      );

      final participants = [
        const Participant(id: 'p1', name: 'Алексей (здоров)'),
        const Participant(
          id: 'p2',
          name: 'Борис (астма)',
          medicalConditions: [MedicalCondition.asthma],
        ),
      ];

      final distributed = service.autoDistribute(
        participants: participants,
        allGear: [...testGear, asthmaItem],
        shoppingList: testFood,
        personalGearWeightKg: 0.0,
      );

      final healthy = distributed.firstWhere((p) => p.id == 'p1');
      final asthmatic = distributed.firstWhere((p) => p.id == 'p2');

      // Healthy participant must NOT have the inhaler
      expect(healthy.personalGear.any((g) => g.id == 'gear_med_asthma'), isFalse);

      // Asthmatic participant MUST have the inhaler
      expect(asthmatic.personalGear.any((g) => g.id == 'gear_med_asthma'), isTrue);
    });

    test('Prioritizes group first-aid kit to Medic and repair kit to RepairMaster', () {
      const groupMedKit = GearItem(
        id: 'gear_31',
        nameRu: 'Групповая аптечка',
        category: GearCategory.med_hygiene,
        type: GearType.group,
        weightG: 650,
        season: GearSeason.all,
        isMandatory: true,
      );

      const groupRepairKit = GearItem(
        id: 'gear_23',
        nameRu: 'Ремнабор походный',
        category: GearCategory.tools,
        type: GearType.group,
        weightG: 400,
        season: GearSeason.all,
        isMandatory: true,
      );

      final participants = [
        const Participant(id: 'p1', name: 'Алексей', role: TripRole.medic),
        const Participant(id: 'p2', name: 'Борис', role: TripRole.repairMaster),
        const Participant(id: 'p3', name: 'Владимир', role: TripRole.member),
      ];

      final distributed = service.autoDistribute(
        participants: participants,
        allGear: [...testGear, groupMedKit, groupRepairKit],
        shoppingList: testFood,
        personalGearWeightKg: 0.0,
      );

      final medic = distributed.firstWhere((p) => p.id == 'p1');
      final repairMaster = distributed.firstWhere((p) => p.id == 'p2');
      final member = distributed.firstWhere((p) => p.id == 'p3');

      // Medic should have the group first-aid kit
      expect(medic.assignedGear.any((g) => g.id == 'gear_31'), isTrue);

      // Repair master should have the repair kit
      expect(repairMaster.assignedGear.any((g) => g.id == 'gear_23'), isTrue);

      // Normal member should not have them
      expect(member.assignedGear.any((g) => g.id == 'gear_31'), isFalse);
      expect(member.assignedGear.any((g) => g.id == 'gear_23'), isFalse);
    });

    test('Generates readable Markdown report for individual participant with role and duty days', () {
      const p = Participant(
        id: 'p1',
        name: 'Иван',
        role: TripRole.medic,
        personalGearWeightKg: 7.5,
      );
      final report = service.generateParticipantReport(p, dutyDays: [1, 4]);
      expect(report, contains('Индивидуальная раскладка: Иван'));
      expect(report, contains('Медик'));
      expect(report, contains('День 1, День 4'));
      expect(report, contains('9.00 кг'));
    });
  });
}
