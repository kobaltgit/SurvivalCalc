import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/services/qr_sync_service.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  group('QrSyncService Tests', () {
    const service = QrSyncService();

    test('Encodes and decodes TripProfile faithfully', () {
      final original = TripProfile(
        id: 'test_sync_1',
        title: 'Тестовый поход по Алтаю',
        groupSize: 5,
        durationDays: 8,
        activeDays: 6,
        totalDistanceKm: 110.0,
        totalAscentMeters: 2800.0,
        season: Season.spring_autumn,
        activityType: ActivityType.mountain,
        avgParticipantWeightKg: 78.5,
        createdAt: DateTime(2026, 8, 31),
      );

      final encoded = service.encodeTripProfile(original);
      expect(encoded, startsWith('SURVIVALCALC:'));

      final decoded = service.decodeTripProfile(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.title, equals(original.title));
      expect(decoded.groupSize, equals(original.groupSize));
      expect(decoded.durationDays, equals(original.durationDays));
      expect(decoded.totalDistanceKm, equals(original.totalDistanceKm));
      expect(decoded.totalAscentMeters, equals(original.totalAscentMeters));
      expect(decoded.season, equals(original.season));
      expect(decoded.activityType, equals(original.activityType));
      expect(decoded.avgParticipantWeightKg, equals(original.avgParticipantWeightKg));
    });

    test('Decodes raw JSON string as fallback', () {
      final original = TripProfile(
        id: 'test_json_1',
        title: 'Одиночный сплав',
        groupSize: 1,
        durationDays: 3,
        activeDays: 3,
        totalDistanceKm: 45.0,
        totalAscentMeters: 100.0,
        season: Season.summer,
        activityType: ActivityType.water,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime(2026, 8, 31),
      );

      final jsonStr = original.toJson();
      final decoded = service.decodeTripProfile('  $jsonStr  ');
      expect(decoded, isNotNull);
      expect(decoded!.title, equals('Одиночный сплав'));
      expect(decoded.groupSize, equals(1));
      expect(decoded.activityType, equals(ActivityType.water));
    });

    test('Gracefully returns null on invalid or corrupted payload', () {
      expect(service.decodeTripProfile(''), isNull);
      expect(service.decodeTripProfile('   '), isNull);
      expect(service.decodeTripProfile('SURVIVALCALC:invalid_base64!@#'), isNull);
      expect(service.decodeTripProfile('random_garbage_string'), isNull);
    });
  });
}
