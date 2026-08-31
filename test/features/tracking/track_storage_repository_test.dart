import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/features/tracking/data/repositories/track_storage_repository.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TrackStorageRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = TrackStorageRepository(prefs: prefs);
  });

  group('TrackStorageRepository & Sandbox Tests', () {
    final track1 = DailyTrack(
      id: 'track_1',
      tripId: 'trip_altai',
      dayIndex: 1,
      segmentIndex: 1,
      title: 'День 1: Подъем',
      startTime: DateTime(2026, 8, 1, 9, 0),
      totalDistanceKm: 12.5,
      isSimulation: false,
    );

    final track2 = DailyTrack(
      id: 'track_2',
      tripId: 'trip_altai',
      dayIndex: 1,
      segmentIndex: 2,
      title: 'День 1: Радиалка',
      startTime: DateTime(2026, 8, 1, 15, 0),
      totalDistanceKm: 4.2,
      isSimulation: false,
    );

    final track3 = DailyTrack(
      id: 'track_3',
      tripId: 'trip_kavkaz',
      dayIndex: 1,
      segmentIndex: 1,
      title: 'День 1: Старт',
      startTime: DateTime(2026, 8, 5, 10, 0),
      totalDistanceKm: 10.0,
      isSimulation: false,
    );

    final simTrack1 = DailyTrack(
      id: 'sim_1',
      tripId: DailyTrack.sandboxTripId,
      dayIndex: 1,
      segmentIndex: 1,
      title: 'Тестовый переход #1',
      startTime: DateTime.now(),
      totalDistanceKm: 3.5,
      isSimulation: true,
    );

    final simTrack2 = DailyTrack(
      id: 'sim_2',
      tripId: DailyTrack.sandboxTripId,
      dayIndex: 2,
      segmentIndex: 1,
      title: 'Тестовый переход #2',
      startTime: DateTime.now(),
      totalDistanceKm: 4.0,
      isSimulation: true,
    );

    test('Saves and filters tracks by tripId strictly', () async {
      await repository.saveCompletedTrack(track1);
      await repository.saveCompletedTrack(track2);
      await repository.saveCompletedTrack(track3);
      await repository.saveCompletedTrack(simTrack1);

      final altaiTracks = await repository.getTracksForTrip('trip_altai');
      expect(altaiTracks.length, 2);
      expect(altaiTracks.map((t) => t.id), containsAll(['track_1', 'track_2']));

      final kavkazTracks = await repository.getTracksForTrip('trip_kavkaz');
      expect(kavkazTracks.length, 1);
      expect(kavkazTracks.first.id, 'track_3');
    });

    test('Isolates sandbox / simulation tracks from real trips', () async {
      await repository.saveCompletedTrack(track1);
      await repository.saveCompletedTrack(simTrack1);
      await repository.saveCompletedTrack(simTrack2);

      final sandboxTracks = await repository.getSandboxTracks();
      expect(sandboxTracks.length, 2);
      expect(sandboxTracks.every((t) => t.isSimulation), isTrue);

      final realTracks = await repository.getTracksForTrip('trip_altai');
      expect(realTracks.length, 1);
      expect(realTracks.first.id, 'track_1');
    });

    test('Deletes single track by ID', () async {
      await repository.saveCompletedTrack(track1);
      await repository.saveCompletedTrack(track2);

      var tracks = await repository.getCompletedTracks();
      expect(tracks.length, 2);

      await repository.deleteTrack('track_1');

      tracks = await repository.getCompletedTracks();
      expect(tracks.length, 1);
      expect(tracks.first.id, 'track_2');
    });

    test('Clears all sandbox tracks in one bulk operation without touching real trips', () async {
      await repository.saveCompletedTrack(track1);
      await repository.saveCompletedTrack(track2);
      await repository.saveCompletedTrack(simTrack1);
      await repository.saveCompletedTrack(simTrack2);

      var sandbox = await repository.getSandboxTracks();
      expect(sandbox.length, 2);

      await repository.clearSandboxTracks();

      sandbox = await repository.getSandboxTracks();
      expect(sandbox, isEmpty);

      final realTracks = await repository.getTracksForTrip('trip_altai');
      expect(realTracks.length, 2);
    });

    test('Serializes and deserializes DailyTrack with new sandbox and segment fields', () {
      final json = track1.toJson();
      expect(json['tripId'], 'trip_altai');
      expect(json['isSimulation'], false);
      expect(json['segmentIndex'], 1);

      final fromJson = DailyTrack.fromJson(json);
      expect(fromJson.tripId, 'trip_altai');
      expect(fromJson.isSimulation, false);
      expect(fromJson.segmentIndex, 1);
      expect(fromJson.totalDistanceKm, 12.5);
    });
  });
}
