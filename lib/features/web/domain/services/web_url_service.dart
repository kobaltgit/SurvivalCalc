import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/utils/polyline_utils.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/web/domain/services/browser_history_sync/browser_history_sync.dart';

class TripUrlData {
  final TripProfile profile;
  final List<Participant> participants;
  final PlannedRoute? plannedRoute;

  const TripUrlData({
    required this.profile,
    this.participants = const [],
    this.plannedRoute,
  });
}

class WebUrlService {
  const WebUrlService();

  static const String defaultProductionUrl = 'https://kobaltgit.github.io/SurvivalCalc/';

  /// Parses URL query parameters into a TripProfile if present
  static TripProfile? parseProfileFromUri(Uri uri) {
    return parseDataFromUri(uri)?.profile;
  }

  /// Parses full trip data including participants and GPX track from URL query parameters
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

      // Decode track geometry if present
      PlannedRoute? plannedRoute;
      final trkRaw = query['trk'] ?? query['track'];
      if (trkRaw != null && trkRaw.trim().isNotEmpty) {
        try {
          final points = PolylineUtils.decode(trkRaw.trim());
          if (points.isNotEmpty) {
            double minLat = points.first.latitude;
            double maxLat = points.first.latitude;
            double minLon = points.first.longitude;
            double maxLon = points.first.longitude;
            for (final p in points) {
              if (p.latitude < minLat) minLat = p.latitude;
              if (p.latitude > maxLat) maxLat = p.latitude;
              if (p.longitude < minLon) minLon = p.longitude;
              if (p.longitude > maxLon) maxLon = p.longitude;
            }

            final trackName = query['trkname'] ?? query['title'] ?? 'Импортированный трек';
            plannedRoute = PlannedRoute(
              id: 'url_route_${DateTime.now().millisecondsSinceEpoch}',
              name: trackName,
              totalDistanceKm: dist ?? 15.0,
              totalAscentMeters: ascent ?? 200.0,
              totalDescentMeters: 0.0,
              points: points,
              waypoints: [],
              minLat: minLat,
              maxLat: maxLat,
              minLon: minLon,
              maxLon: maxLon,
              importedAt: DateTime.now(),
            );
          }
        } catch (_) {}
      }

      DateTime? startDate;
      if (query['start'] != null) {
        startDate = DateTime.tryParse(query['start']!);
      }
      DateTime? endDate;
      if (query['end'] != null) {
        endDate = DateTime.tryParse(query['end']!);
      }

      final profile = TripProfile(
        id: 'shared_trip_${DateTime.now().millisecondsSinceEpoch}',
        title: query['title'] ?? 'Поход из ссылки',
        groupSize: g,
        durationDays: d,
        activeDays: active ?? d,
        totalDistanceKm: dist ?? (plannedRoute != null ? plannedRoute.totalDistanceKm : 15.0),
        totalAscentMeters: ascent ?? (plannedRoute != null ? plannedRoute.totalAscentMeters : 200.0),
        season: season,
        activityType: activity,
        avgParticipantWeightKg: weight ?? 75.0,
        clubOrCity: query['club'] ?? '',
        difficultyCategory: query['cat'] ?? 'н/к',
        geographicalRegion: query['region'] ?? '',
        emergencyExitRoutes: query['exit'] ?? '',
        mkkName: query['mkk'] ?? '',
        routeBookNumber: query['rb'] ?? '',
        startDate: startDate,
        endDate: endDate,
        mchsRegNumber: query['mchs'] ?? '',
        coordinatorName: query['coord'] ?? '',
        coordinatorPhone: query['cphone'] ?? '',
        coordinatorEmail: query['cemail'] ?? '',
        satellitePhone: query['sat'] ?? '',
        communicationSchedule: query['csched'] ?? '',
        deputyLeaderName: query['dep'] ?? '',
        deputyLeaderPhone: query['dphone'] ?? '',
        createdAt: DateTime.now(),
      );

      return TripUrlData(
        profile: profile,
        participants: participants,
        plannedRoute: plannedRoute,
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds query parameters URL for sharing (including participants and track if provided)
  static String buildShareUrl(
    TripProfile profile, {
    List<Participant>? participants,
    PlannedRoute? plannedRoute,
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
    } else if (baseUrl == 'https://kobaltgit.github.io/SurvivalCalc/') {
      // Force canonical format with trailing slash
      hostUrl = 'https://kobaltgit.github.io/SurvivalCalc/';
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
      if (profile.clubOrCity.isNotEmpty) 'club': profile.clubOrCity,
      if (profile.difficultyCategory != 'н/к') 'cat': profile.difficultyCategory,
      if (profile.geographicalRegion.isNotEmpty) 'region': profile.geographicalRegion,
      if (profile.emergencyExitRoutes.isNotEmpty) 'exit': profile.emergencyExitRoutes,
      if (profile.mkkName.isNotEmpty) 'mkk': profile.mkkName,
      if (profile.routeBookNumber.isNotEmpty) 'rb': profile.routeBookNumber,
      if (profile.mchsRegNumber.isNotEmpty) 'mchs': profile.mchsRegNumber,
      if (profile.coordinatorName.isNotEmpty) 'coord': profile.coordinatorName,
      if (profile.coordinatorPhone.isNotEmpty) 'cphone': profile.coordinatorPhone,
      if (profile.coordinatorEmail.isNotEmpty) 'cemail': profile.coordinatorEmail,
      if (profile.satellitePhone.isNotEmpty) 'sat': profile.satellitePhone,
      if (profile.communicationSchedule.isNotEmpty) 'csched': profile.communicationSchedule,
      if (profile.deputyLeaderName.isNotEmpty) 'dep': profile.deputyLeaderName,
      if (profile.deputyLeaderPhone.isNotEmpty) 'dphone': profile.deputyLeaderPhone,
      if (profile.startDate != null) 'start': profile.startDate!.toIso8601String(),
      if (profile.endDate != null) 'end': profile.endDate!.toIso8601String(),
    };

    if (participants != null && participants.isNotEmpty) {
      try {
        final partsList = participants.map((p) => p.toMap()).toList();
        final jsonStr = jsonEncode(partsList);
        final base64Parts = base64Url.encode(utf8.encode(jsonStr));
        queryParams['parts'] = base64Parts;
      } catch (_) {}
    }

    if (plannedRoute != null && plannedRoute.points.isNotEmpty) {
      try {
        final encodedTrk = PolylineUtils.encode(plannedRoute.points);
        if (encodedTrk.isNotEmpty) {
          queryParams['trk'] = encodedTrk;
          if (plannedRoute.name.isNotEmpty) {
            queryParams['trkname'] = plannedRoute.name;
          }
        }
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
    PlannedRoute? plannedRoute,
  ]) {
    if (!kIsWeb) return;
    try {
      final shareUrl = buildShareUrl(
        profile,
        participants: participants,
        plannedRoute: plannedRoute,
      );
      syncUrlToBrowserHistory(shareUrl);
    } catch (_) {}
  }
}
