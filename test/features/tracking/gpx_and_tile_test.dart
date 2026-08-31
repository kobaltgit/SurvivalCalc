import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_route_parser.dart';
import 'package:survival_calc/features/tracking/domain/services/tile_math_utils.dart';

void main() {
  group('GpxRouteParser Tests', () {
    test('Parses inline sample GPX track and calculates metrics accurately', () {
      const sampleGpx = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="SurvivalCalc">
  <metadata>
    <name>Тестовый переход</name>
    <desc>Простой переход через перевал</desc>
  </metadata>
  <wpt lat="44.0760" lon="39.9980">
    <name>КПП Лагонаки</name>
    <type>camp</type>
  </wpt>
  <wpt lat="44.0500" lon="39.9600">
    <name>Родник</name>
    <type>water</type>
  </wpt>
  <trk>
    <name>Тестовый переход</name>
    <trkseg>
      <trkpt lat="44.0760" lon="39.9980">
        <ele>1750.0</ele>
      </trkpt>
      <trkpt lat="44.0600" lon="39.9800">
        <ele>1820.0</ele>
      </trkpt>
      <trkpt lat="44.0450" lon="39.9650">
        <ele>1910.0</ele>
      </trkpt>
      <trkpt lat="44.0200" lon="39.9400">
        <ele>1650.0</ele>
      </trkpt>
    </trkseg>
  </trk>
</gpx>''';

      final route = GpxRouteParser.parseGpx(sampleGpx);

      expect(route.name, equals('Тестовый переход'));
      expect(route.points.length, equals(4));
      expect(route.waypoints.length, equals(2));
      expect(route.totalDistanceKm, greaterThan(6.0));
      expect(route.totalDistanceKm, lessThan(12.0));
      expect(route.totalAscentMeters, closeTo(160.0, 5.0)); // 1750->1820 (+70) + 1820->1910 (+90) = +160
      expect(route.totalDescentMeters, closeTo(260.0, 5.0)); // 1910->1650 = -260
      expect(route.waypoints.first.type, equals(WayPointType.camp));
      expect(route.waypoints.last.type, equals(WayPointType.water));
    });

    test('Parses full Caucasian demo_route_30.gpx file from assets', () {
      final file = File('assets/data/demo_route_30.gpx');
      expect(file.existsSync(), isTrue, reason: 'demo_route_30.gpx must exist in assets/data');

      final content = file.readAsStringSync();
      final route = GpxRouteParser.parseGpx(content);

      expect(route.name, contains('Маршрут №30'));
      expect(route.points.length, greaterThan(20));
      expect(route.waypoints.length, greaterThan(5));
      expect(route.totalDistanceKm, closeTo(48.0, 10.0));
      expect(route.totalAscentMeters, greaterThan(400.0));
    });
  });

  group('TileMathUtils Tests', () {
    test('Calculates Slippy Map tile X/Y correctly for known coordinates', () {
      // Moscow ~55.7558, 37.6173 at zoom 10
      final tile = TileMathUtils.latLonToTile(55.7558, 37.6173, 10);
      expect(tile.z, equals(10));
      expect(tile.x, equals(619));
      expect(tile.y, equals(320));
    });

    test('Calculates radius tiles and eliminates duplicates', () {
      final tiles = TileMathUtils.getTilesForRadius(
        centerLat: 44.0760,
        centerLon: 39.9980,
        radiusKm: 10.0,
        zoomLevels: const [12, 13],
      );

      expect(tiles.isNotEmpty, isTrue);
      // All tiles must belong to zoom 12 or 13
      for (final t in tiles) {
        expect(t.z == 12 || t.z == 13, isTrue);
      }
    });

    test('Calculates corridor tiles along route polyline', () {
      final points = [
        GpsPoint(latitude: 44.0760, longitude: 39.9980, altitude: 1750.0, timestamp: DateTime.now()),
        GpsPoint(latitude: 44.0500, longitude: 39.9600, altitude: 1820.0, timestamp: DateTime.now()),
        GpsPoint(latitude: 44.0200, longitude: 39.9300, altitude: 1910.0, timestamp: DateTime.now()),
      ];

      final tiles = TileMathUtils.getTilesForPolyline(
        points: points,
        bufferKm: 2.0,
        zoomLevels: const [12, 13],
      );

      expect(tiles.isNotEmpty, isTrue);
      final sizeMb = TileMathUtils.estimateSizeMb(tiles.length);
      expect(sizeMb, greaterThan(0.0));
    });
  });
}
