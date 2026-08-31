import 'dart:math' as math;
import 'package:xml/xml.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';

class GpxRouteParser {
  static PlannedRoute parseGpx(String gpxContent, {String? defaultName}) {
    final document = XmlDocument.parse(gpxContent);
    final gpxElement = document.rootElement;

    // 1. Metadata / Name
    String routeName = defaultName ?? 'Плановый маршрут';
    String description = '';

    final metaName = gpxElement.findElements('metadata').firstOrNull?.findElements('name').firstOrNull?.innerText;
    final metaDesc = gpxElement.findElements('metadata').firstOrNull?.findElements('desc').firstOrNull?.innerText;

    final trkName = gpxElement.findAllElements('trk').firstOrNull?.findElements('name').firstOrNull?.innerText;
    final trkDesc = gpxElement.findAllElements('trk').firstOrNull?.findElements('desc').firstOrNull?.innerText;

    if (trkName != null && trkName.trim().isNotEmpty) {
      routeName = trkName.trim();
    } else if (metaName != null && metaName.trim().isNotEmpty) {
      routeName = metaName.trim();
    }

    if (trkDesc != null && trkDesc.trim().isNotEmpty) {
      description = trkDesc.trim();
    } else if (metaDesc != null && metaDesc.trim().isNotEmpty) {
      description = metaDesc.trim();
    }

    // 2. Extract Track Points (<trkpt> or <rtept>)
    final List<GpsPoint> points = [];
    var trkpts = gpxElement.findAllElements('trkpt').toList();
    if (trkpts.isEmpty) {
      trkpts = gpxElement.findAllElements('rtept').toList();
    }

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLon = 180.0;
    double maxLon = -180.0;

    for (final pt in trkpts) {
      final latAttr = pt.getAttribute('lat');
      final lonAttr = pt.getAttribute('lon');
      if (latAttr == null || lonAttr == null) continue;

      final lat = double.tryParse(latAttr);
      final lon = double.tryParse(lonAttr);
      if (lat == null || lon == null) continue;

      final eleText = pt.findElements('ele').firstOrNull?.innerText;
      final ele = eleText != null ? double.tryParse(eleText) ?? 0.0 : 0.0;

      final timeText = pt.findElements('time').firstOrNull?.innerText;
      final time = timeText != null ? DateTime.tryParse(timeText) ?? DateTime.now() : DateTime.now();

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;

      points.add(GpsPoint(
        latitude: lat,
        longitude: lon,
        altitude: ele,
        timestamp: time,
      ));
    }

    // 3. Extract Waypoints (<wpt>)
    final List<WayPoint> waypoints = [];
    final wpts = gpxElement.findAllElements('wpt');

    for (final wpt in wpts) {
      final latAttr = wpt.getAttribute('lat');
      final lonAttr = wpt.getAttribute('lon');
      if (latAttr == null || lonAttr == null) continue;

      final lat = double.tryParse(latAttr);
      final lon = double.tryParse(lonAttr);
      if (lat == null || lon == null) continue;

      final name = wpt.findElements('name').firstOrNull?.innerText ?? 'Точка';
      final eleText = wpt.findElements('ele').firstOrNull?.innerText;
      final ele = eleText != null ? double.tryParse(eleText) ?? 0.0 : 0.0;
      final sym = wpt.findElements('sym').firstOrNull?.innerText.toLowerCase() ?? '';
      final typeStr = wpt.findElements('type').firstOrNull?.innerText.toLowerCase() ?? '';

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;

      WayPointType wpType = WayPointType.other;
      if (typeStr.contains('camp') || sym.contains('camp')) {
        wpType = WayPointType.camp;
      } else if (typeStr.contains('water') || sym.contains('water') || name.toLowerCase().contains('родник')) {
        wpType = WayPointType.water;
      } else if (typeStr.contains('pass') || sym.contains('peak') || name.toLowerCase().contains('перевал') || name.toLowerCase().contains('вершина')) {
        wpType = WayPointType.pass;
      } else if (typeStr.contains('danger') || sym.contains('danger') || name.toLowerCase().contains('опасн')) {
        wpType = WayPointType.obstacle;
      } else if (typeStr.contains('view') || name.toLowerCase().contains('обзор')) {
        wpType = WayPointType.viewpoint;
      }

      waypoints.add(WayPoint(
        id: 'wpt_${waypoints.length + 1}',
        title: name,
        latitude: lat,
        longitude: lon,
        altitude: ele,
        type: wpType,
        timestamp: DateTime.now(),
      ));
    }

    // 4. Calculate Distance and Elevation Metrics
    double totalDistanceKm = 0.0;
    double totalAscentMeters = 0.0;
    double totalDescentMeters = 0.0;

    if (points.isNotEmpty) {
      double lastEle = points.first.altitude;
      for (int i = 1; i < points.length; i++) {
        final p1 = points[i - 1];
        final p2 = points[i];

        final distFlatKm = _calculateHaversineDistance(
          p1.latitude,
          p1.longitude,
          p2.latitude,
          p2.longitude,
        );

        final eleDiffM = p2.altitude - p1.altitude;
        final eleDiffKm = eleDiffM / 1000.0;

        // 3D distance
        final dist3dKm = math.sqrt(distFlatKm * distFlatKm + eleDiffKm * eleDiffKm);
        totalDistanceKm += dist3dKm;

        // Ascent and Descent with 1.5m noise filter
        final eleStep = p2.altitude - lastEle;
        if (eleStep.abs() >= 1.5) {
          if (eleStep > 0) {
            totalAscentMeters += eleStep;
          } else {
            totalDescentMeters += eleStep.abs();
          }
          lastEle = p2.altitude;
        }
      }
    }

    if (minLat > maxLat) {
      minLat = 0.0;
      maxLat = 0.0;
      minLon = 0.0;
      maxLon = 0.0;
    }

    return PlannedRoute(
      id: 'planned_${DateTime.now().millisecondsSinceEpoch}',
      name: routeName,
      description: description,
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(1)),
      totalAscentMeters: totalAscentMeters.roundToDouble(),
      totalDescentMeters: totalDescentMeters.roundToDouble(),
      points: points,
      waypoints: waypoints,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      importedAt: DateTime.now(),
    );
  }

  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
}
