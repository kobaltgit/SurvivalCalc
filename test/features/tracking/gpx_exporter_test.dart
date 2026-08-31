import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_exporter.dart';

void main() {
  group('GpxExporter Tests', () {
    const exporter = GpxExporter();

    test('Exports valid GPX 1.1 with track points and waypoints', () {
      final now = DateTime.utc(2026, 8, 31, 10, 0, 0);
      final track = DailyTrack(
        id: 'track_101',
        dayIndex: 2,
        title: 'Перевал Псеашхо',
        startTime: now,
        points: [
          GpsPoint(
            latitude: 43.6821,
            longitude: 40.3812,
            altitude: 2150.0,
            timestamp: now,
          ),
          GpsPoint(
            latitude: 43.6850,
            longitude: 40.3850,
            altitude: 2300.0,
            timestamp: now.add(const Duration(minutes: 30)),
          ),
        ],
        waypoints: [
          WayPoint(
            id: 'wp_1',
            title: 'Родник Чистый',
            note: 'Дебит 2 л/мин',
            type: WayPointType.water,
            latitude: 43.6830,
            longitude: 40.3820,
            altitude: 2180.0,
            timestamp: now.add(const Duration(minutes: 10)),
          ),
        ],
      );

      final gpxString = exporter.exportTrackToGpx(track);

      expect(gpxString.contains('<?xml version="1.0" encoding="UTF-8"?>'), isTrue);
      expect(gpxString.contains('<gpx version="1.1"'), isTrue);
      expect(gpxString.contains('<name>Перевал Псеашхо</name>'), isTrue);
      expect(gpxString.contains('<wpt lat="43.6830000" lon="40.3820000">'), isTrue);
      expect(gpxString.contains('<name>Родник Чистый</name>'), isTrue);
      expect(gpxString.contains('<desc>Дебит 2 л/мин</desc>'), isTrue);
      expect(gpxString.contains('<trkpt lat="43.6821000" lon="40.3812000">'), isTrue);
      expect(gpxString.contains('<ele>2150.0</ele>'), isTrue);
    });
  });
}
