import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/trip_setup/domain/models/planned_day_schedule.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/trip_storage/data/repositories/saved_trips_repository.dart';
import 'package:survival_calc/features/trip_storage/domain/models/saved_trip_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavedTripEntry & SavedTripsRepository Tests', () {
    late SavedTripsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = SavedTripsRepository();
    });

    final sampleProfile = TripProfile(
      id: 'trip_100',
      title: 'Алтай: Шавлинские озёра',
      groupSize: 4,
      durationDays: 7,
      activeDays: 6,
      totalDistanceKm: 80.0,
      totalAscentMeters: 2400.0,
      season: Season.summer,
      activityType: ActivityType.mountain,
      avgParticipantWeightKg: 72.0,
      createdAt: DateTime(2026, 7, 10),
    );

    test('Serializes and deserializes SavedTripEntry correctly', () {
      final entry = SavedTripEntry(
        id: 'entry_1',
        title: 'Алтай: Шавлинские озёра',
        isTemplate: false,
        createdAt: DateTime(2026, 7, 10, 10, 0),
        updatedAt: DateTime(2026, 7, 10, 12, 0),
        profile: sampleProfile,
        checkedGearIds: ['g_tent_3p', 'g_pot_3l'],
        participants: [
          const Participant(id: 'p_1', name: 'Иван', weightKg: 80.0),
          const Participant(id: 'p_2', name: 'Мария', weightKg: 60.0),
        ],
        note: 'Красивый маршрут по тропе',
      );

      final jsonString = entry.toJson();
      final decoded = SavedTripEntry.fromJson(jsonString);

      expect(decoded.id, equals('entry_1'));
      expect(decoded.title, equals('Алтай: Шавлинские озёра'));
      expect(decoded.isTemplate, isFalse);
      expect(decoded.checkedGearIds, equals(['g_tent_3p', 'g_pot_3l']));
      expect(decoded.participants.length, equals(2));
      expect(decoded.participants.first.name, equals('Иван'));
      expect(decoded.profile.groupSize, equals(4));
      expect(decoded.profile.totalDistanceKm, equals(80.0));
      expect(decoded.note, equals('Красивый маршрут по тропе'));
    });

    test('Saves and loads real trips and templates separately', () async {
      final tripEntry = SavedTripEntry(
        id: 'trip_entry_1',
        title: 'Реальный поход на Кавказ',
        isTemplate: false,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        profile: sampleProfile.copyWith(title: 'Реальный поход на Кавказ'),
        checkedGearIds: ['g_tent_3p'],
      );

      final templateEntry = SavedTripEntry(
        id: 'template_entry_1',
        title: 'Шаблон: Быстрый ПВД',
        isTemplate: true,
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
        profile: sampleProfile.copyWith(title: 'Шаблон: Быстрый ПВД', groupSize: 1, durationDays: 2),
        checkedGearIds: [], // Templates have empty checked list
      );

      await repository.saveEntry(tripEntry);
      await repository.saveEntry(templateEntry);

      final all = await repository.loadAll();
      expect(all.length, equals(2));

      final realTrips = all.where((e) => !e.isTemplate).toList();
      final templates = all.where((e) => e.isTemplate).toList();

      expect(realTrips.length, equals(1));
      expect(realTrips.first.title, equals('Реальный поход на Кавказ'));
      expect(realTrips.first.checkedGearIds, equals(['g_tent_3p']));

      expect(templates.length, equals(1));
      expect(templates.first.title, equals('Шаблон: Быстрый ПВД'));
      expect(templates.first.checkedGearIds, isEmpty);
    });

    test('Duplicates an existing trip and creates a distinct copy', () async {
      final original = SavedTripEntry(
        id: 'orig_1',
        title: 'Хибины Зима',
        isTemplate: false,
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
        profile: sampleProfile.copyWith(title: 'Хибины Зима', season: Season.winter),
        checkedGearIds: ['g_shovel', 'g_tent_winter'],
      );

      await repository.saveEntry(original);
      final copy = await repository.duplicateEntry('orig_1');

      expect(copy, isNotNull);
      expect(copy!.id, isNot(equals('orig_1')));
      expect(copy.title, equals('Хибины Зима (Копия)'));
      expect(copy.checkedGearIds, equals(['g_shovel', 'g_tent_winter']));

      final all = await repository.loadAll();
      expect(all.length, equals(2));
    });

    test('Deletes an entry cleanly', () async {
      final entry1 = SavedTripEntry(
        id: 'del_1',
        title: 'Удаляемый поход',
        isTemplate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: sampleProfile,
      );
      final entry2 = SavedTripEntry(
        id: 'keep_2',
        title: 'Остающийся поход',
        isTemplate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: sampleProfile,
      );

      await repository.saveEntry(entry1);
      await repository.saveEntry(entry2);

      await repository.deleteEntry('del_1');

      final all = await repository.loadAll();
      expect(all.length, equals(1));
      expect(all.first.id, equals('keep_2'));
    });
  });

  group('Trip Lifecycle & Itinerary Schedule Tests', () {
    test('PlannedDaySchedule dynamically regenerates when plannedItinerary is empty', () {
      final profile = TripProfile(
        id: 'trip_fresh',
        title: 'Свежий маршрут',
        groupSize: 2,
        durationDays: 4,
        activeDays: 4,
        totalDistanceKm: 40.0,
        totalAscentMeters: 800.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
        plannedItinerary: const [], // empty
      );

      final schedule = PlannedDaySchedule.generateDefaultSchedule(profile: profile);
      expect(schedule.length, equals(4));
      expect(schedule[0].dayNumber, equals(1));
      expect(schedule[0].distanceKm, equals(10.0));
      expect(schedule[3].dayNumber, equals(4));
    });

    test('PlannedDaySchedule ignores stale plannedItinerary if activeDays mismatch', () {
      final staleItinerary = [
        const PlannedDaySchedule(dayNumber: 1, routeSection: 'Старый переход 1', distanceKm: 15.0),
        const PlannedDaySchedule(dayNumber: 2, routeSection: 'Старый переход 2', distanceKm: 15.0),
      ];

      // Profile changed to 4 days, but still held 2 days in plannedItinerary
      final profile = TripProfile(
        id: 'trip_updated',
        title: 'Обновленный маршрут',
        groupSize: 2,
        durationDays: 4,
        activeDays: 4,
        totalDistanceKm: 60.0,
        totalAscentMeters: 1200.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        avgParticipantWeightKg: 75.0,
        createdAt: DateTime.now(),
        plannedItinerary: staleItinerary,
      );

      final schedule = PlannedDaySchedule.generateDefaultSchedule(profile: profile);
      // Stale 2-day itinerary must be invalidated and 4 fresh days generated
      expect(schedule.length, equals(4));
      expect(schedule[0].distanceKm, equals(15.0));
      expect(schedule[0].routeSection, contains('Ходовой переход 1'));
    });
  });
}
