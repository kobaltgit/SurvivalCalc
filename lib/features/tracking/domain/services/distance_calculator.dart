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
  /// Filters out jitter/noise when movement is smaller than minimum threshold (e.g. 3 meters)
  double calculateTotalDistanceKm(
    List<GpsPoint> points, {
    double minStepMeters = 3.0,
  }) {
    if (points.length < 2) return 0.0;

    double totalMeters = 0.0;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final d = distanceBetweenMeters(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      // Filter out stationary noise jitter
      if (d >= minStepMeters) {
        totalMeters += d;
      }
    }

    return totalMeters / 1000.0;
  }

  /// Calculates elevation gain and loss in meters
  /// Uses a threshold (e.g. 2 meters) to ignore minor barometric/GPS jitter
  ({double gain, double loss}) calculateElevationProfile(
    List<GpsPoint> points, {
    double minElevationStepMeters = 2.0,
  }) {
    if (points.length < 2) return (gain: 0.0, loss: 0.0);

    double totalGain = 0.0;
    double totalLoss = 0.0;

    for (int i = 1; i < points.length; i++) {
      final double diff = points[i].altitude - points[i - 1].altitude;
      if (diff >= minElevationStepMeters) {
        totalGain += diff;
      } else if (diff <= -minElevationStepMeters) {
        totalLoss += diff.abs();
      }
    }

    return (gain: totalGain, loss: totalLoss);
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
