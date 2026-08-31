import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/gear/data/repositories/gear_repository.dart';
import 'package:survival_calc/features/gear/domain/services/gear_calculator_service.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/data/repositories/food_repository.dart';
import 'package:survival_calc/features/ration/domain/services/ration_generator_service.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Participant Health & Dietary Restriction Tests', () {
    final foodRepo = AssetFoodRepository();
    final gearRepo = AssetGearRepository();
    const metabolicCalc = MetabolicCalculator();
    const rationGen = RationGeneratorService();
    const gearCalc = GearCalculatorService();

    test('Dietary substitution excludes meat for vegetarians and substitutes plant proteins', () async {
      final foods = await foodRepo.loadFoods();
      final profile = TripProfile.createDefault().copyWith(durationDays: 3, activeDays: 3);
      final targets = metabolicCalc.calculate(profile);

      final vegRations = rationGen.generateRations(
        profile: profile,
        targets: targets,
        availableFoods: foods,
        dietaryRestriction: DietaryRestriction.vegetarian,
      );

      expect(vegRations.length, equals(3));

      // Verify no meat or animal lard in vegetarian rations
      for (final ration in vegRations) {
        for (final slot in ration.mealSlots) {
          for (final item in slot.items) {
            expect(
              ['food_13', 'food_14', 'food_15', 'food_16', 'food_19', 'food_20', 'food_24'].contains(item.foodItem.id),
              isFalse,
              reason: 'Found meat item ${item.foodItem.nameRu} in vegetarian ration',
            );
          }
        }
      }
    });

    test('Medical conditions automatically inject required emergency meds and individual cook gear', () async {
      final allGear = await gearRepo.loadGear();
      final profile = TripProfile.createDefault().copyWith(groupSize: 3);
      final targets = metabolicCalc.calculate(profile);

      final participants = [
        const Participant(
          id: 'p1',
          name: 'Алексей',
          medicalConditions: [MedicalCondition.asthma],
        ),
        const Participant(
          id: 'p2',
          name: 'Анна',
          dietaryRestrictions: [DietaryRestriction.vegetarian],
          medicalConditions: [MedicalCondition.insect_allergy],
        ),
        const Participant(
          id: 'p3',
          name: 'Дмитрий',
          medicalConditions: [MedicalCondition.joint_pain],
        ),
      ];

      final gear = gearCalc.filterAndScaleGear(
        profile: profile,
        targets: targets,
        allGear: allGear,
        participants: participants,
      );

      // Verify Asthma inhaler added
      expect(gear.any((g) => g.id == 'gear_med_asthma'), isTrue);

      // Verify Epinephrine anti-shock kit added
      expect(gear.any((g) => g.id == 'gear_med_allergy'), isTrue);

      // Verify Elastic joint bandage added
      expect(gear.any((g) => g.id == 'gear_med_joints'), isTrue);

      // Verify solo cooking pot added for Anna (vegetarian)
      expect(gear.any((g) => g.id == 'gear_cook_solo'), isTrue);
    });
  });
}
