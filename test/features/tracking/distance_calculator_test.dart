import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/services/distance_calculator.dart';

void main() {
  group('DistanceCalculator Tests', () {
    const calculator = DistanceCalculator();

    test('Haversine distance between two known points', () {
      // Moscow Red Square: 55.7539, 37.6208
      // Saint Petersburg Palace Square: 59.9390, 30.3158
      // Known distance ~ 634 km
      final distMeters = calculator.distanceBetweenMeters(
        55.7539,
        37.6208,
        59.9390,
        30.3158,
      );

      final distKm = distMeters / 1000.0;
      expect(distKm, greaterThan(630.0));
      expect(distKm, lessThan(640.0));
    });

    test('Total distance calculation filters minor stationary jitter', () {
      final now = DateTime.now();
      final points = [
        GpsPoint(
          latitude: 43.3550,
          longitude: 42.4392,
          altitude: 2000,
          timestamp: now,
        ),
        // Jitter point < 3m away
        GpsPoint(
          latitude: 43.3550001,
          longitude: 42.4392001,
          altitude: 2000,
          timestamp: now.add(const Duration(seconds: 5)),
        ),
        // Real movement ~ 1.11 km North
        GpsPoint(
          latitude: 43.3650,
          longitude: 42.4392,
          altitude: 2200,
          timestamp: now.add(const Duration(minutes: 15)),
        ),
      ];

      final totalKm = calculator.calculateTotalDistanceKm(points);
      expect(totalKm, closeTo(1.11, 0.1));
    });

    test('Elevation profile gain and loss calculation', () {
      final now = DateTime.now();
      final points = [
        GpsPoint(
          latitude: 43.0,
          longitude: 42.0,
          altitude: 1000,
          timestamp: now,
        ),
        GpsPoint(
          latitude: 43.01,
          longitude: 42.01,
          altitude: 1350, // +350m gain
          timestamp: now.add(const Duration(minutes: 30)),
        ),
        GpsPoint(
          latitude: 43.02,
          longitude: 42.02,
          altitude: 1200, // -150m loss
          timestamp: now.add(const Duration(minutes: 60)),
        ),
        GpsPoint(
          latitude: 43.03,
          longitude: 42.03,
          altitude: 1400, // +200m gain
          timestamp: now.add(const Duration(minutes: 90)),
        ),
      ];

      final profile = calculator.calculateElevationProfile(points);
      expect(profile.gain, equals(550.0)); // 350 + 200
      expect(profile.loss, equals(150.0)); // 150
    });
  });
}
