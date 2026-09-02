import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/features/tracking/data/repositories/track_storage_repository.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        trackStorageRepositoryProvider.overrideWithValue(
          TrackStorageRepository(prefs: prefs),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Route Simulation Tests', () {
    final sampleRoute = PlannedRoute(
      id: 'caucasus_demo',
      name: 'Кавказский перевал 30',
      totalDistanceKm: 15.4,
      totalAscentMeters: 850.0,
      totalDescentMeters: 400.0,
      minLat: 43.5,
      maxLat: 43.8,
      minLon: 40.2,
      maxLon: 40.6,
      importedAt: DateTime.now(),
      waypoints: [],
      points: [
        GpsPoint(
          latitude: 43.5100,
          longitude: 40.2100,
          altitude: 1200.0,
          timestamp: DateTime(2026, 8, 1, 9, 0),
        ),
        GpsPoint(
          latitude: 43.5200,
          longitude: 40.2200,
          altitude: 1350.0,
          timestamp: DateTime(2026, 8, 1, 9, 10),
        ),
        GpsPoint(
          latitude: 43.5350,
          longitude: 40.2350,
          altitude: 1550.0,
          timestamp: DateTime(2026, 8, 1, 9, 20),
        ),
      ],
    );

    test('startSimulation with PlannedRoute sets track title and simulation flag',
        () async {
      final notifier = container.read(trackingProvider.notifier);

      await notifier.startSimulation(route: sampleRoute);

      final state = container.read(trackingProvider);
      expect(state.status, equals(TrackingStatus.tracking));
      expect(state.activeTrack, isNotNull);
      expect(state.activeTrack!.isSimulation, isTrue);
      expect(state.activeTrack!.tripId, equals(DailyTrack.sandboxTripId));
      expect(state.activeTrack!.title, contains('Кавказский перевал 30'));

      await notifier.stopAndFinishDay();
    });

    test('startSimulation detects nearby waypoint and triggers alert',
        () async {
      final sampleRouteWithWp = PlannedRoute(
        id: 'caucasus_wp',
        name: 'Трек с родником',
        totalDistanceKm: 10.0,
        totalAscentMeters: 500.0,
        totalDescentMeters: 200.0,
        minLat: 43.5,
        maxLat: 43.8,
        minLon: 40.2,
        maxLon: 40.6,
        importedAt: DateTime.now(),
        waypoints: [
          WayPoint(
            id: 'wp_water_1',
            title: 'Родник под перевалом',
            type: WayPointType.water,
            latitude: 43.5102,
            longitude: 40.2102,
            altitude: 1210.0,
            timestamp: DateTime.now(),
          ),
        ],
        points: [
          GpsPoint(
            latitude: 43.5100,
            longitude: 40.2100,
            altitude: 1200.0,
            timestamp: DateTime(2026, 8, 1, 9, 0),
          ),
        ],
      );

      final notifier = container.read(trackingProvider.notifier);
      await notifier.startSimulation(route: sampleRouteWithWp);

      // Allow 1 timer tick to execute
      await Future.delayed(const Duration(milliseconds: 1100));

      final state = container.read(trackingProvider);
      expect(state.status, equals(TrackingStatus.tracking));
      expect(state.lastReachedWaypoint, isNotNull);
      expect(state.lastReachedWaypoint!.title, equals('Родник под перевалом'));
      expect(state.waypointNotification, contains('Родник под перевалом'));

      await notifier.stopAndFinishDay();
    });

    test('startSimulation without route uses fallback sandbox track',
        () async {
      final notifier = container.read(trackingProvider.notifier);

      await notifier.startSimulation();

      final state = container.read(trackingProvider);
      expect(state.status, equals(TrackingStatus.tracking));
      expect(state.activeTrack, isNotNull);
      expect(state.activeTrack!.isSimulation, isTrue);
      expect(state.activeTrack!.tripId, equals(DailyTrack.sandboxTripId));

      await notifier.stopAndFinishDay();
    });
  });
}
