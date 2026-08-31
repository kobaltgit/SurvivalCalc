import 'dart:math' as math;
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';

class TileCoord {
  final int z;
  final int x;
  final int y;

  const TileCoord({
    required this.z,
    required this.x,
    required this.y,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoord &&
          runtimeType == other.runtimeType &&
          z == other.z &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => z.hashCode ^ x.hashCode ^ y.hashCode;

  @override
  String toString() => '$z/$x/$y';
}

class TileMathUtils {
  /// Converts Latitude/Longitude to Slippy Map tile coordinates at zoom level [z]
  static TileCoord latLonToTile(double lat, double lon, int z) {
    final n = math.pow(2.0, z);
    final x = ((lon + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();

    final maxTile = (n - 1).toInt();
    final clampedX = x.clamp(0, maxTile);
    final clampedY = y.clamp(0, maxTile);

    return TileCoord(z: z, x: clampedX, y: clampedY);
  }

  /// Calculates the set of tiles for a circular area around [centerLat, centerLon] with [radiusKm]
  static Set<TileCoord> getTilesForRadius({
    required double centerLat,
    required double centerLon,
    required double radiusKm,
    required List<int> zoomLevels,
  }) {
    final Set<TileCoord> tiles = {};

    for (final z in zoomLevels) {
      final deltaLat = radiusKm / 111.0;
      final latRad = centerLat * math.pi / 180.0;
      final cosLat = math.cos(latRad).abs();
      final deltaLon = cosLat > 0.001 ? radiusKm / (111.0 * cosLat) : radiusKm / 111.0;

      final minLat = (centerLat - deltaLat).clamp(-85.0511, 85.0511);
      final maxLat = (centerLat + deltaLat).clamp(-85.0511, 85.0511);
      final minLon = (centerLon - deltaLon).clamp(-180.0, 180.0);
      final maxLon = (centerLon + deltaLon).clamp(-180.0, 180.0);

      final topLeft = latLonToTile(maxLat, minLon, z);
      final bottomRight = latLonToTile(minLat, maxLon, z);

      final minX = math.min(topLeft.x, bottomRight.x);
      final maxX = math.max(topLeft.x, bottomRight.x);
      final minY = math.min(topLeft.y, bottomRight.y);
      final maxY = math.max(topLeft.y, bottomRight.y);

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          tiles.add(TileCoord(z: z, x: x, y: y));
        }
      }
    }

    return tiles;
  }

  /// Calculates tiles for a polyline route corridor with [bufferKm]
  static Set<TileCoord> getTilesForPolyline({
    required List<GpsPoint> points,
    required double bufferKm,
    required List<int> zoomLevels,
  }) {
    final Set<TileCoord> tiles = {};
    if (points.isEmpty) return tiles;

    // Step through points with sampling to avoid excessive duplicate calculations
    const sampleDistKm = 1.5;
    final sampledPoints = <GpsPoint>[points.first];
    var lastPt = points.first;

    for (int i = 1; i < points.length; i++) {
      final curPt = points[i];
      final dist = _approxDistanceKm(lastPt.latitude, lastPt.longitude, curPt.latitude, curPt.longitude);
      if (dist >= sampleDistKm || i == points.length - 1) {
        sampledPoints.add(curPt);
        lastPt = curPt;
      }
    }

    for (final pt in sampledPoints) {
      final ptTiles = getTilesForRadius(
        centerLat: pt.latitude,
        centerLon: pt.longitude,
        radiusKm: bufferKm,
        zoomLevels: zoomLevels,
      );
      tiles.addAll(ptTiles);
    }

    return tiles;
  }

  /// Estimates approximate size in Megabytes for a given number of tiles (avg ~30 KB/tile)
  static double estimateSizeMb(int tileCount) {
    return double.parse((tileCount * 0.030).toStringAsFixed(1));
  }

  static double _approxDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1) * 111.0;
    final dLon = (lon2 - lon1) * 111.0 * math.cos(lat1 * math.pi / 180.0);
    return math.sqrt(dLat * dLat + dLon * dLon);
  }
}
