import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';

/// Ultra-compact URL-safe polyline encoder & decoder for GPX coordinates and elevation.
class PolylineUtils {
  const PolylineUtils._();

  /// Encodes GPS points into a compact URL-safe polyline string.
  /// If track has more than [maxPoints], evenly samples to keep URL length within safe limits (~2KB).
  static String encode(List<GpsPoint> points, {int maxPoints = 350}) {
    if (points.isEmpty) return '';

    List<GpsPoint> sampled = points;
    if (points.length > maxPoints) {
      sampled = [];
      final double step = (points.length - 1) / (maxPoints - 1);
      for (int i = 0; i < maxPoints - 1; i++) {
        sampled.add(points[(i * step).round()]);
      }
      sampled.add(points.last);
    }

    final StringBuffer buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;
    int prevAlt = 0;

    for (final point in sampled) {
      final int lat = (point.latitude * 1e5).round();
      final int lng = (point.longitude * 1e5).round();
      final int alt = point.altitude.round();

      _encodeValue(lat - prevLat, buffer);
      _encodeValue(lng - prevLng, buffer);
      _encodeValue(alt - prevAlt, buffer);

      prevLat = lat;
      prevLng = lng;
      prevAlt = alt;
    }

    return buffer.toString();
  }

  /// Decodes a polyline string back into a list of [GpsPoint].
  static List<GpsPoint> decode(String encoded) {
    final List<GpsPoint> points = [];
    if (encoded.isEmpty) return points;

    int index = 0;
    int lat = 0;
    int lng = 0;
    int alt = 0;

    final now = DateTime.now();

    while (index < encoded.length) {
      final latDelta = _decodeValue(encoded, index);
      if (latDelta == null) break;
      lat += latDelta.value;
      index = latDelta.nextIndex;

      final lngDelta = _decodeValue(encoded, index);
      if (lngDelta == null) break;
      lng += lngDelta.value;
      index = lngDelta.nextIndex;

      final altDelta = _decodeValue(encoded, index);
      if (altDelta == null) break;
      alt += altDelta.value;
      index = altDelta.nextIndex;

      points.add(
        GpsPoint(
          latitude: lat / 1e5,
          longitude: lng / 1e5,
          altitude: alt.toDouble(),
          timestamp: now,
        ),
      );
    }

    return points;
  }

  static void _encodeValue(int val, StringBuffer buffer) {
    int v = val < 0 ? ~(val << 1) : (val << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static ({int value, int nextIndex})? _decodeValue(String str, int startIndex) {
    if (startIndex >= str.length) return null;
    int result = 0;
    int shift = 0;
    int index = startIndex;

    while (index < str.length) {
      final int code = str.codeUnitAt(index++);
      final int b = code - 63;
      if (b < 0 || b > 63) return null;
      result |= (b & 0x1f) << shift;
      shift += 5;
      if (b < 0x20) break;
    }

    final int val = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    return (value: val, nextIndex: index);
  }
}
