import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/web/domain/services/browser_history_sync/browser_history_sync.dart';

class TripUrlData {
  final TripProfile profile;
  final List<Participant> participants;

  const TripUrlData({
    required this.profile,
    this.participants = const [],
  });
}

class WebUrlService {
  const WebUrlService();

  static const String defaultProductionUrl = 'https://kobaltgit.github.io/SurvivalCalc/';

  /// Parses URL query parameters into a TripProfile if present
  static TripProfile? parseProfileFromUri(Uri uri) {
    return parseDataFromUri(uri)?.profile;
  }

  /// Parses full trip data including participants from URL query parameters
  static TripUrlData? parseDataFromUri(Uri uri) {
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
      var g = group ?? 1;

      // Decode participants if present
      final List<Participant> participants = [];
      final partsRaw = query['parts'];
      if (partsRaw != null && partsRaw.trim().isNotEmpty) {
        try {
          final normalizedBase64 = base64Url.normalize(partsRaw.trim());
          final decodedJson = utf8.decode(base64Url.decode(normalizedBase64));
          final rawList = jsonDecode(decodedJson) as List<dynamic>;
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              participants.add(Participant.fromMap(item));
            }
          }
          if (participants.isNotEmpty) {
            g = participants.length;
          }
        } catch (_) {
          // If corrupted or version mismatch, continue with basic parameters
        }
      }

      final profile = TripProfile(
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

      return TripUrlData(
        profile: profile,
        participants: participants,
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds query parameters URL for sharing (including participants if provided)
  static String buildShareUrl(
    TripProfile profile, {
    List<Participant>? participants,
    String? baseUrl,
  }) {
    String hostUrl = baseUrl ?? '';
    if (hostUrl.isEmpty) {
      if (kIsWeb) {
        final current = Uri.base;
        if (current.hasScheme && (current.scheme == 'http' || current.scheme == 'https')) {
          final path = current.path.endsWith('/') ? current.path : '${current.path}/';
          hostUrl = '${current.origin}$path';
        } else {
          hostUrl = defaultProductionUrl;
        }
      } else {
        hostUrl = defaultProductionUrl;
      }
    }

    final queryParams = <String, String>{
      'days': profile.durationDays.toString(),
      'group': profile.groupSize.toString(),
      'active': profile.activeDays.toString(),
      'dist': profile.totalDistanceKm.toString(),
      'ascent': profile.totalAscentMeters.toString(),
      'season': profile.season.name,
      'activity': profile.activityType.name,
      'weight': profile.avgParticipantWeightKg.toString(),
      if (profile.title != 'Новый поход' && profile.title.trim().isNotEmpty)
        'title': profile.title,
    };

    if (participants != null && participants.isNotEmpty) {
      try {
        final partsList = participants.map((p) => p.toMap()).toList();
        final jsonStr = jsonEncode(partsList);
        final base64Parts = base64Url.encode(utf8.encode(jsonStr));
        queryParams['parts'] = base64Parts;
      } catch (_) {}
    }

    final parsedBase = Uri.parse(hostUrl);
    final finalUri = parsedBase.replace(queryParameters: queryParams);
    return finalUri.toString();
  }

  /// Dynamically updates browser address bar URL without reloading
  static void syncCurrentStateToBrowserUrl(
    TripProfile profile, [
    List<Participant>? participants,
  ]) {
    if (!kIsWeb) return;
    try {
      final shareUrl = buildShareUrl(profile, participants: participants);
      syncUrlToBrowserHistory(shareUrl);
    } catch (_) {}
  }
}
