import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/ration/domain/services/ration_generator_service.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  group('RationGeneratorService Tests', () {
    late List<FoodItem> foods;
    const metabolicCalculator = MetabolicCalculator();
    const rationGenerator = RationGeneratorService();

    setUpAll(() {
      final file = File('assets/data/food_db.json');
      final jsonList = json.decode(file.readAsStringSync()) as List<dynamic>;
      foods = jsonList
          .map((e) => FoodItem.fromMap(e as Map<String, dynamic>))
          .toList();
    });

    test('Dataset contains all 57 food items', () {
      expect(foods.length, equals(57));
    });

    test('Generates daily rations matching target calories closely', () {
      final profile = TripProfile(
        id: 'test_trip',
        groupSize: 2,
        durationDays: 3,
        activeDays: 3,
        totalDistanceKm: 30.0,
        totalAscentMeters: 500.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = metabolicCalculator.calculate(profile);
      final rations = rationGenerator.generateRations(
        profile: profile,
        targets: targets,
        availableFoods: foods,
      );

      expect(rations.length, equals(3));

      for (final ration in rations) {
        expect(ration.mealSlots.length, equals(4)); // 4 slots
        // Calories should be within 10% of target
        expect(
          ration.totalCalories,
          closeTo(targets.dailyCalories, targets.dailyCalories * 0.10),
        );
        expect(ration.totalWeightG, greaterThan(400));
        expect(ration.totalProteinG, greaterThan(60));
      }
    });

    test('Shopping list aggregates quantities correctly for group size', () {
      final profile = TripProfile(
        id: 'test_trip',
        groupSize: 4,
        durationDays: 5,
        activeDays: 5,
        totalDistanceKm: 50.0,
        totalAscentMeters: 1000.0,
        season: Season.spring_autumn,
        activityType: ActivityType.mountain,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = metabolicCalculator.calculate(profile);
      final rations = rationGenerator.generateRations(
        profile: profile,
        targets: targets,
        availableFoods: foods,
      );
      final shoppingList = rationGenerator.buildShoppingList(
        rations: rations,
        groupSize: 4,
      );

      expect(shoppingList.isNotEmpty, isTrue);

      final totalGrams =
          shoppingList.fold<int>(0, (sum, item) => sum + item.totalGrams);
      expect(totalGrams, greaterThan(5000)); // > 5kg for 4 people x 5 days
    });

    test('Assigns fair round-robin duty pairs across days for 4 participants', () {
      final profile = TripProfile(
        id: 'test_trip',
        groupSize: 4,
        durationDays: 5,
        activeDays: 5,
        totalDistanceKm: 50.0,
        totalAscentMeters: 1000.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = metabolicCalculator.calculate(profile);
      final rations = rationGenerator.generateRations(
        profile: profile,
        targets: targets,
        availableFoods: foods,
      );

      final participants = [
        const Participant(id: 'p1', name: 'Алексей'),
        const Participant(id: 'p2', name: 'Борис'),
        const Participant(id: 'p3', name: 'Владимир'),
        const Participant(id: 'p4', name: 'Дмитрий'),
      ];

      final scheduled = rationGenerator.assignDutySchedule(
        rations: rations,
        participants: participants,
      );

      expect(scheduled.length, equals(profile.durationDays));

      // Day 1 pair: p1 & p2
      expect(scheduled[0].dutyParticipantIds, equals(['p1', 'p2']));
      // Day 2 pair: p3 & p4
      expect(scheduled[1].dutyParticipantIds, equals(['p3', 'p4']));
      // Day 3 pair: p1 & p2
      expect(scheduled[2].dutyParticipantIds, equals(['p1', 'p2']));
    });
  });
}
