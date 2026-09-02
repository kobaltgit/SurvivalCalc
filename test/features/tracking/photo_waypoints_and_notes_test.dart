import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/services/qr_sync_service.dart';
import 'package:survival_calc/features/tracking/domain/models/camp_debrief.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  group('Photo Waypoints & Field Notes Tests', () {
    test('WayPoint serializes and deserializes photoPath, authorName and authorRole correctly', () {
      final now = DateTime(2026, 9, 1, 14, 30);
      final wp = WayPoint(
        id: 'wp_test_1',
        title: 'Родник под перевалом',
        note: 'Вода чистая, дебит отличный, стоянка рядом',
        type: WayPointType.water,
        latitude: 43.3550,
        longitude: 42.4392,
        altitude: 1850.0,
        timestamp: now,
        photoPath: '/data/user/0/com.survivalcalc.app/app_flutter/trips/trip_1/photos/wp_123.jpg',
        authorName: 'Ольга',
        authorRole: TripRole.medic,
      );

      final json = wp.toJson();
      expect(json['id'], 'wp_test_1');
      expect(json['title'], 'Родник под перевалом');
      expect(json['note'], contains('Вода чистая'));
      expect(json['photoPath'], contains('wp_123.jpg'));
      expect(json['authorName'], 'Ольга');
      expect(json['authorRole'], 'medic');

      final restored = WayPoint.fromJson(json);
      expect(restored.id, wp.id);
      expect(restored.title, wp.title);
      expect(restored.note, wp.note);
      expect(restored.type, WayPointType.water);
      expect(restored.photoPath, wp.photoPath);
      expect(restored.authorName, 'Ольга');
      expect(restored.authorRole, TripRole.medic);
      expect(restored.altitude, 1850.0);
    });

    test('WayPoint copyWith preserves all fields when selectively updating', () {
      final wp = WayPoint(
        id: 'wp_test_2',
        title: 'Панорама Фишта',
        type: WayPointType.viewpoint,
        latitude: 43.95,
        longitude: 39.85,
        altitude: 2867.0,
        timestamp: DateTime.now(),
        photoPath: 'photo_initial.jpg',
        authorName: 'Иван',
        authorRole: TripRole.leader,
      );

      final updated = wp.copyWith(
        note: 'Красивый закат над ледником',
        photoPath: 'photo_retaken.jpg',
      );

      expect(updated.id, 'wp_test_2');
      expect(updated.title, 'Панорама Фишта');
      expect(updated.note, 'Красивый закат над ледником');
      expect(updated.photoPath, 'photo_retaken.jpg');
      expect(updated.authorName, 'Иван');
      expect(updated.authorRole, TripRole.leader);
    });
  });

  group('Daily Camp Journal & Debrief Notes Tests', () {
    test('DailyCampNote serializes and deserializes accurately', () {
      final now = DateTime(2026, 9, 1, 20, 15);
      final note = DailyCampNote(
        id: 'camp_note_1',
        tripId: 'trip_fisht_2026',
        dayNumber: 2,
        authorName: 'Денис',
        authorRole: TripRole.repairMaster,
        text: 'Перевал прошли за 3 часа. На стоянке сильный ветер, укрепили растяжки палаток.',
        weather: '💨 Шторм/Ветер',
        photoPath: '/photos/camp_day_2.jpg',
        createdAt: now,
      );

      final json = note.toJson();
      expect(json['id'], 'camp_note_1');
      expect(json['tripId'], 'trip_fisht_2026');
      expect(json['dayNumber'], 2);
      expect(json['authorName'], 'Денис');
      expect(json['authorRole'], 'repairMaster');
      expect(json['weather'], '💨 Шторм/Ветер');
      expect(json['photoPath'], '/photos/camp_day_2.jpg');

      final restored = DailyCampNote.fromJson(json);
      expect(restored.id, note.id);
      expect(restored.authorName, 'Денис');
      expect(restored.authorRole, TripRole.repairMaster);
      expect(restored.text, contains('Перевал прошли'));
      expect(restored.weather, '💨 Шторм/Ветер');
    });

    test('CampDebrief holds list of notes and serializes seamlessly', () {
      final note1 = DailyCampNote(
        id: 'n1',
        tripId: 't1',
        dayNumber: 1,
        authorName: 'Иван',
        authorRole: TripRole.leader,
        text: 'Хороший ходовой день',
        weather: '☀️ Ясно',
        createdAt: DateTime.now(),
      );
      final note2 = DailyCampNote(
        id: 'n2',
        tripId: 't1',
        dayNumber: 1,
        authorName: 'Ольга',
        authorRole: TripRole.medic,
        text: 'Мозолей нет, все здоровы',
        weather: '☀️ Ясно',
        createdAt: DateTime.now(),
      );

      const debrief = CampDebrief(
        dayIndex: 1,
        dayTitle: 'День 1: Подход к приюту',
        plannedDistanceKm: 15.0,
        actualDistanceKm: 16.2,
        plannedAscentMeters: 600,
        actualAscentMeters: 750,
        actualDescentMeters: 100,
        movingDurationSeconds: 14400,
        pauseDurationSeconds: 3600,
        avgMovingSpeedKmh: 4.05,
        plannedDailyCalories: 3200,
        actualCaloriesBurned: 3550,
        calorieDelta: 350,
        targetWaterLiters: 3.5,
        eveningWaterCompensationLiters: 1.2,
        electrolyteAdvice: 'Принять регидрон',
        nutritionRecommendations: ['Добавить быстрых углеводов'],
        dailyFoodWeightConsumedG: 650,
        dailyGasConsumedG: 45,
        estimatedMorningPackWeightKg: 18.5,
      );

      final debriefWithNotes = debrief.copyWith(notes: [note1, note2]);
      final json = debriefWithNotes.toJson();
      expect((json['notes'] as List).length, 2);

      final restored = CampDebrief.fromJson(json);
      expect(restored.notes.length, 2);
      expect(restored.notes[0].authorName, 'Иван');
      expect(restored.notes[1].authorName, 'Ольга');
    });

    test('DailyTrack embeds CampDebrief with notes and restores properly', () {
      final now = DateTime.now();
      final track = DailyTrack(
        id: 'track_1',
        dayIndex: 1,
        title: 'День 1',
        startTime: now,
        points: [
          GpsPoint(latitude: 43.1, longitude: 42.1, altitude: 1000, timestamp: now),
        ],
        waypoints: [
          WayPoint(
            id: 'wp1',
            title: 'Родник',
            type: WayPointType.water,
            latitude: 43.1,
            longitude: 42.1,
            altitude: 1000,
            timestamp: now,
            authorName: 'Иван',
          ),
        ],
        debrief: CampDebrief(
          dayIndex: 1,
          dayTitle: 'День 1',
          plannedDistanceKm: 10,
          actualDistanceKm: 10,
          plannedAscentMeters: 200,
          actualAscentMeters: 200,
          actualDescentMeters: 50,
          movingDurationSeconds: 7200,
          pauseDurationSeconds: 1800,
          avgMovingSpeedKmh: 5.0,
          plannedDailyCalories: 3000,
          actualCaloriesBurned: 3000,
          calorieDelta: 0,
          targetWaterLiters: 3,
          eveningWaterCompensationLiters: 1,
          electrolyteAdvice: 'Норма',
          nutritionRecommendations: const [],
          dailyFoodWeightConsumedG: 600,
          dailyGasConsumedG: 40,
          estimatedMorningPackWeightKg: 19.0,
          notes: [
            DailyCampNote(
              id: 'cn1',
              tripId: 't1',
              dayNumber: 1,
              authorName: 'Иван',
              text: 'Отличный лагерь',
              createdAt: now,
            ),
          ],
        ),
      );

      final json = track.toJson();
      expect(json['debrief'], isNotNull);
      expect(json['debrief']['notes'], isNotEmpty);

      final restored = DailyTrack.fromJson(json);
      expect(restored.debrief, isNotNull);
      expect(restored.debrief!.notes.first.authorName, 'Иван');
      expect(restored.waypoints.first.authorName, 'Иван');
    });
  });

  group('QR Sync Snapshot & Smart Merge Tests', () {
    test('Encodes and decodes full TripQrSnapshot with waypoints and camp notes', () {
      const service = QrSyncService();
      final profile = TripProfile(
        id: 'trip_100',
        title: 'Кавказ 2026',
        groupSize: 4,
        durationDays: 7,
        activeDays: 5,
        totalDistanceKm: 85.0,
        totalAscentMeters: 2400.0,
        season: Season.summer,
        activityType: ActivityType.mountain,
        createdAt: DateTime(2026, 9, 1),
      );

      final wp = WayPoint(
        id: 'wp_shared',
        title: 'Брод через Белую',
        type: WayPointType.obstacle,
        latitude: 43.99,
        longitude: 40.11,
        altitude: 1600.0,
        timestamp: DateTime(2026, 9, 1, 12, 0),
        note: 'Брод по колено, течение среднее',
        authorName: 'Денис',
        authorRole: TripRole.navigator,
      );

      final note = DailyCampNote(
        id: 'note_shared',
        tripId: 'trip_100',
        dayNumber: 1,
        authorName: 'Ольга',
        authorRole: TripRole.medic,
        text: 'Погода отличная, группа в хорошем темпе',
        weather: '☀️ Ясно',
        createdAt: DateTime(2026, 9, 1, 19, 0),
      );

      final snapshot = TripQrSnapshot(
        profile: profile,
        waypoints: [wp],
        campNotes: [note],
        isLeader: true,
        senderName: 'Иван',
      );

      final encoded = service.encodeTripSnapshot(snapshot);
      expect(encoded.startsWith('SURVIVALCALC:'), isTrue);

      final decoded = service.decodeTripSnapshot(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.profile.title, 'Кавказ 2026');
      expect(decoded.waypoints.length, 1);
      expect(decoded.waypoints.first.title, 'Брод через Белую');
      expect(decoded.waypoints.first.authorName, 'Денис');
      expect(decoded.campNotes.length, 1);
      expect(decoded.campNotes.first.authorName, 'Ольга');
      expect(decoded.campNotes.first.weather, '☀️ Ясно');
      expect(decoded.isLeader, isTrue);
      expect(decoded.senderName, 'Иван');
    });

    test('Backward compatibility: decodes v1 raw TripProfile JSON or string correctly', () {
      const service = QrSyncService();
      final profile = TripProfile(
        id: 'trip_v1',
        title: 'Старый поход v1',
        groupSize: 2,
        durationDays: 3,
        activeDays: 2,
        totalDistanceKm: 30.0,
        totalAscentMeters: 500.0,
        season: Season.spring_autumn,
        activityType: ActivityType.hiking,
        createdAt: DateTime(2026, 8, 15),
      );

      final legacyPayload = service.encodeTripProfile(profile);
      final decoded = service.decodeTripSnapshot(legacyPayload);
      expect(decoded, isNotNull);
      expect(decoded!.profile.title, 'Старый поход v1');
      expect(decoded.profile.groupSize, 2);
    });
  });
}
