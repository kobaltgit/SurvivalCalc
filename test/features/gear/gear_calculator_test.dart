import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/gear/domain/services/gear_calculator_service.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  group('GearCalculatorService Tests', () {
    late List<GearItem> allGear;
    const metabolicCalculator = MetabolicCalculator();
    const gearCalculator = GearCalculatorService();

    setUpAll(() {
      final file = File('assets/data/gear_db.json');
      final jsonList = json.decode(file.readAsStringSync()) as List<dynamic>;
      allGear = jsonList
          .map((e) => GearItem.fromMap(e as Map<String, dynamic>))
          .toList();
    });

    test('Dataset contains all 66 gear items', () {
      expect(allGear.length, equals(66));
    });

    test('Summer trip excludes winter items and scales 2-person tents for 4 people to 2', () {
      final profile = TripProfile(
        id: 'summer_trip',
        groupSize: 4,
        durationDays: 3,
        activeDays: 3,
        totalDistanceKm: 30.0,
        totalAscentMeters: 200.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = metabolicCalculator.calculate(profile);
      final filteredGear = gearCalculator.filterAndScaleGear(
        profile: profile,
        targets: targets,
        allGear: allGear,
      );

      // No winter gear
      expect(
        filteredGear.any((g) => g.season == GearSeason.winter || g.category == GearCategory.winter),
        isFalse,
      );

      // Tents for 4 people = 2
      final tent = filteredGear.firstWhere((g) => g.id == 'gear_01');
      expect(tent.quantity, equals(2));

      // Weights calculation
      final weights = gearCalculator.calculateGearWeights(
        gearList: filteredGear,
        groupSize: 4,
      );

      expect(weights.totalPersonalGearWeightKg, greaterThan(3.0));
      expect(weights.groupGearWeightPerPersonKg, greaterThan(1.0));
      expect(
        weights.totalGearWeightPerPersonKg,
        equals(weights.totalPersonalGearWeightKg + weights.groupGearWeightPerPersonKg),
      );
    });

    test('Winter extreme trip includes snowshoes, storm tents, and avalanche shovel', () {
      final profile = TripProfile(
        id: 'winter_extreme',
        groupSize: 2,
        durationDays: 5,
        activeDays: 5,
        totalDistanceKm: 50.0,
        totalAscentMeters: 1000.0,
        season: Season.extreme_cold,
        activityType: ActivityType.survival,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
      );

      final targets = metabolicCalculator.calculate(profile);
      final filteredGear = gearCalculator.filterAndScaleGear(
        profile: profile,
        targets: targets,
        allGear: allGear,
      );

      // Winter gear included
      expect(filteredGear.any((g) => g.id == 'gear_62'), isTrue); // Snowshoes
      expect(filteredGear.any((g) => g.id == 'gear_63'), isTrue); // Avalanche shovel
      expect(filteredGear.any((g) => g.id == 'gear_02'), isTrue); // Storm tent
      expect(filteredGear.any((g) => g.id == 'gear_12'), isTrue); // Multi-fuel stove
    });
  });
}
