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

      final rawLat = double.tryParse(latAttr);
      final rawLon = double.tryParse(lonAttr);
      if (rawLat == null || rawLon == null) continue;

      final sanitizedCoords = sanitizeCoordinates(rawLat, rawLon);
      if (sanitizedCoords == null) continue;

      final lat = sanitizedCoords.$1;
      final lon = sanitizedCoords.$2;

      final eleText = pt.findElements('ele').firstOrNull?.innerText;
      final rawEle = eleText != null ? double.tryParse(eleText) ?? 0.0 : 0.0;
      final ele = sanitizeElevation(rawEle);

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

      final rawLat = double.tryParse(latAttr);
      final rawLon = double.tryParse(lonAttr);
      if (rawLat == null || rawLon == null) continue;

      final sanitizedCoords = sanitizeCoordinates(rawLat, rawLon);
      if (sanitizedCoords == null) continue;

      final lat = sanitizedCoords.$1;
      final lon = sanitizedCoords.$2;

      final name = wpt.findElements('name').firstOrNull?.innerText ?? 'Точка';
      final desc = wpt.findElements('desc').firstOrNull?.innerText ?? '';
      final cmt = wpt.findElements('cmt').firstOrNull?.innerText ?? '';
      final eleText = wpt.findElements('ele').firstOrNull?.innerText;
      final rawEle = eleText != null ? double.tryParse(eleText) ?? 0.0 : 0.0;
      final ele = sanitizeElevation(rawEle);
      final sym = wpt.findElements('sym').firstOrNull?.innerText.toLowerCase() ?? '';
      final typeStr = wpt.findElements('type').firstOrNull?.innerText.toLowerCase() ?? '';

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;

      final combined = '$name $desc $cmt $sym $typeStr'.toLowerCase();

      WayPointType wpType = WayPointType.other;
      if (combined.contains('camp') ||
          combined.contains('лагер') ||
          combined.contains('приют') ||
          combined.contains('ночевк') ||
          combined.contains('стоян') ||
          combined.contains('бивак') ||
          combined.contains('бивуак') ||
          combined.contains('база') ||
          combined.contains('изба') ||
          combined.contains('кордон') ||
          combined.contains('палатк') ||
          combined.contains('кемпинг') ||
          combined.contains('shelter') ||
          combined.contains('cabin') ||
          combined.contains('hut') ||
          combined.contains('турбаза')) {
        wpType = WayPointType.camp;
      } else if (combined.contains('water') ||
          combined.contains('родник') ||
          combined.contains('источник') ||
          combined.contains('ручей') ||
          combined.contains('река') ||
          combined.contains('озер') ||
          combined.contains('ключ') ||
          combined.contains('колодец') ||
          combined.contains('водопад') ||
          combined.contains('spring') ||
          combined.contains('stream') ||
          combined.contains('creek') ||
          combined.contains('lake') ||
          combined.contains('river') ||
          combined.contains('well') ||
          combined.contains('пруд') ||
          combined.contains('водоем')) {
        wpType = WayPointType.water;
      } else if (combined.contains('pass') ||
          combined.contains('peak') ||
          combined.contains('summit') ||
          combined.contains('mountain') ||
          combined.contains('перевал') ||
          combined.contains('вершин') ||
          combined.contains('пик') ||
          combined.contains('гора') ||
          combined.contains('хребет') ||
          combined.contains('сопк') ||
          combined.contains('холм') ||
          combined.contains('седловин') ||
          combined.contains('скал') ||
          combined.contains('пер. ') ||
          combined.contains('пер.') ||
          combined.contains('г. ')) {
        wpType = WayPointType.pass;
      } else if (combined.contains('danger') ||
          combined.contains('hazard') ||
          combined.contains('опасн') ||
          combined.contains('брод') ||
          combined.contains('завал') ||
          combined.contains('курум') ||
          combined.contains('обрыв') ||
          combined.contains('переправ') ||
          combined.contains('сыпух') ||
          combined.contains('ледник') ||
          combined.contains('болот') ||
          combined.contains('порог') ||
          combined.contains('ford') ||
          combined.contains('swamp')) {
        wpType = WayPointType.obstacle;
      } else if (combined.contains('view') ||
          combined.contains('обзор') ||
          combined.contains('смотров') ||
          combined.contains('панорам') ||
          combined.contains('lookout') ||
          combined.contains('scenic') ||
          combined.contains('вышка')) {
        wpType = WayPointType.viewpoint;
      }

      final noteText = desc.isNotEmpty ? desc : (cmt.isNotEmpty ? cmt : null);

      waypoints.add(WayPoint(
        id: 'wpt_${waypoints.length + 1}',
        title: name,
        note: noteText,
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

  /// Generates a standard GPX 1.1 XML string from a PlannedRoute
  static String toGpx(PlannedRoute route) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', attributes: {
      'version': '1.1',
      'creator': 'SurvivalCalc',
      'xmlns': 'http://www.topografix.com/GPX/1/1',
    }, nest: () {
      builder.element('metadata', nest: () {
        builder.element('name', nest: route.name);
        if (route.description.isNotEmpty) {
          builder.element('desc', nest: route.description);
        }
        builder.element('time', nest: DateTime.now().toIso8601String());
      });

      // Waypoints
      for (final wp in route.waypoints) {
        builder.element('wpt', attributes: {
          'lat': wp.latitude.toStringAsFixed(6),
          'lon': wp.longitude.toStringAsFixed(6),
        }, nest: () {
          builder.element('name', nest: wp.title);
          if (wp.note != null && wp.note!.isNotEmpty) {
            builder.element('desc', nest: wp.note!);
          }
          builder.element('sym', nest: wp.type.name);
          builder.element('type', nest: wp.type.name);
        });
      }

      // Track
      builder.element('trk', nest: () {
        builder.element('name', nest: route.name);
        builder.element('trkseg', nest: () {
          for (final pt in route.points) {
            builder.element('trkpt', attributes: {
              'lat': pt.latitude.toStringAsFixed(6),
              'lon': pt.longitude.toStringAsFixed(6),
            }, nest: () {
              builder.element('ele', nest: pt.altitude.toStringAsFixed(1));
              builder.element('time', nest: pt.timestamp.toIso8601String());
            });
          }
        });
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Validates and converts coordinates (supporting EPSG:3857 Web Mercator meters or WGS-84 degrees)
  static (double, double)? sanitizeCoordinates(double rawLat, double rawLon) {
    // If already standard valid WGS-84 degrees
    if (rawLat >= -90.0 && rawLat <= 90.0 && rawLon >= -180.0 && rawLon <= 180.0) {
      return (rawLat, rawLon);
    }

    // Check if coordinates were exported in Web Mercator (EPSG:3857 in meters)
    if (rawLat.abs() <= 20037508.34 &&
        rawLon.abs() <= 20037508.34 &&
        (rawLat.abs() > 90.0 || rawLon.abs() > 180.0)) {
      try {
        final lonDeg = (rawLon / 20037508.34) * 180.0;
        final latDeg = (math.atan(math.exp(rawLat / 6378137.0)) * 2.0 - (math.pi / 2.0)) * (180.0 / math.pi);
        if (latDeg >= -85.05112878 && latDeg <= 85.05112878 && lonDeg >= -180.0 && lonDeg <= 180.0) {
          return (latDeg, lonDeg);
        }
      } catch (_) {}
    }

    // Corrupted or invalid coordinates
    return null;
  }

  /// Filters out unrealistic elevations (e.g. timestamps or corrupt floating point values)
  static double sanitizeElevation(double rawEle) {
    if (rawEle.isNaN || rawEle.isInfinite || rawEle < -500.0 || rawEle > 9000.0) {
      return 0.0;
    }
    return rawEle;
  }
}
