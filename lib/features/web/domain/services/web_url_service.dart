import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class WebUrlService {
  const WebUrlService();

  /// Parses URL query parameters into a TripProfile if present
  static TripProfile? parseProfileFromUri(Uri uri) {
    try {
      final query = uri.queryParameters;
      if (query.isEmpty) return null;

      final days = int.tryParse(query['days'] ?? '');
      final group = int.tryParse(query['group'] ?? '');
      final active = int.tryParse(query['active'] ?? '');
      final dist = double.tryParse(query['dist'] ?? '');
      final ascent = double.tryParse(query['ascent'] ?? '');
      final weight = double.tryParse(query['weight'] ?? '');
      final seasonStr = query['season'];
      final actStr = query['activity'] ?? query['act'];

      if (days == null && group == null && dist == null) return null;

      Season season = Season.summer;
      if (seasonStr != null) {
        season = Season.values.firstWhere(
          (s) => s.name.toLowerCase() == seasonStr.toLowerCase(),
          orElse: () => Season.summer,
        );
      }

      ActivityType activity = ActivityType.hiking;
      if (actStr != null) {
        activity = ActivityType.values.firstWhere(
          (a) => a.name.toLowerCase() == actStr.toLowerCase(),
          orElse: () => ActivityType.hiking,
        );
      }

      final d = days ?? 1;
      final g = group ?? 1;

      return TripProfile(
        id: 'shared_trip_${DateTime.now().millisecondsSinceEpoch}',
        title: query['title'] ?? 'Поход из ссылки',
        groupSize: g,
        durationDays: d,
        activeDays: active ?? d,
        totalDistanceKm: dist ?? 15.0,
        totalAscentMeters: ascent ?? 200.0,
        season: season,
        activityType: activity,
        avgParticipantWeightKg: weight ?? 75.0,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds query parameters URL for sharing
  static String buildShareUrl(TripProfile profile, {String baseUrl = ''}) {
    final uri = Uri(
      path: baseUrl.isEmpty ? '/' : baseUrl,
      queryParameters: {
        'days': profile.durationDays.toString(),
        'group': profile.groupSize.toString(),
        'active': profile.activeDays.toString(),
        'dist': profile.totalDistanceKm.toString(),
        'ascent': profile.totalAscentMeters.toString(),
        'season': profile.season.name,
        'activity': profile.activityType.name,
        'weight': profile.avgParticipantWeightKg.toString(),
        if (profile.title != 'Новый поход') 'title': profile.title,
      },
    );
    return uri.toString();
  }
}
