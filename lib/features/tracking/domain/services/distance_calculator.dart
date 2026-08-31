import 'dart:math' as math;
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';

class DistanceCalculator {
  const DistanceCalculator();

  /// Earth radius in meters
  static const double earthRadiusMeters = 6371000.0;

  /// Calculate great-circle distance between two points using Haversine formula (returns meters)
  double distanceBetweenMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final double dLat = _degreesToRadians(endLat - startLat);
    final double dLng = _degreesToRadians(endLng - startLng);

    final double lat1 = _degreesToRadians(startLat);
    final double lat2 = _degreesToRadians(endLat);

    final double a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0) *
            math.cos(lat1) *
            math.cos(lat2);

    final double c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates total distance in Kilometers from a list of GpsPoints
  /// Uses cumulative dead-band algorithm to filter stationary noise jitter without dropping small genuine steps
  double calculateTotalDistanceKm(
    List<GpsPoint> points, {
    double minStepMeters = 2.0,
  }) {
    if (points.length < 2) return 0.0;

    double totalMeters = 0.0;
    GpsPoint lastAnchor = points.first;

    for (int i = 1; i < points.length; i++) {
      final curr = points[i];
      final d = distanceBetweenMeters(
        lastAnchor.latitude,
        lastAnchor.longitude,
        curr.latitude,
        curr.longitude,
      );

      // When accumulated movement from last anchor exceeds threshold, add it
      if (d >= minStepMeters) {
        totalMeters += d;
        lastAnchor = curr;
      }
    }

    return totalMeters / 1000.0;
  }

  /// Calculates elevation gain and loss in meters
  /// Uses cumulative threshold to filter barometric/GPS jitter while tracking continuous grade
  ({double gain, double loss}) calculateElevationProfile(
    List<GpsPoint> points, {
    double minElevationStepMeters = 1.0,
  }) {
    if (points.length < 2) return (gain: 0.0, loss: 0.0);

    double totalGain = 0.0;
    double totalLoss = 0.0;
    double anchorAlt = points.first.altitude;

    for (int i = 1; i < points.length; i++) {
      final double diff = points[i].altitude - anchorAlt;
      if (diff >= minElevationStepMeters) {
        totalGain += diff;
        anchorAlt = points[i].altitude;
      } else if (diff <= -minElevationStepMeters) {
        totalLoss += diff.abs();
        anchorAlt = points[i].altitude;
      }
    }

    return (gain: totalGain, loss: totalLoss);
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
