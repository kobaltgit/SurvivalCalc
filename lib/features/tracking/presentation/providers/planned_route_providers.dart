import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_route_parser.dart';

class PlannedRouteNotifier extends StateNotifier<PlannedRoute?> {
  static const String _plannedRoutePrefKey = 'planned_route_current_v1';

  PlannedRouteNotifier() : super(null) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_plannedRoutePrefKey);
    if (jsonStr != null) {
      try {
        state = PlannedRoute.fromJson(jsonStr);
      } catch (_) {}
    }
  }

  Future<PlannedRoute> importFromGpx(String gpxContent, {String? defaultName}) async {
    final route = GpxRouteParser.parseGpx(gpxContent, defaultName: defaultName);
    state = route;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plannedRoutePrefKey, route.toJson());
    return route;
  }

  Future<void> setPlannedRoute(PlannedRoute route) async {
    state = route;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plannedRoutePrefKey, route.toJson());
  }

  Future<void> clearPlannedRoute() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_plannedRoutePrefKey);
  }
}

final plannedRouteProvider =
    StateNotifierProvider<PlannedRouteNotifier, PlannedRoute?>((ref) {
  return PlannedRouteNotifier();
});

class OfflineRegionsNotifier extends StateNotifier<List<OfflineRegion>> {
  OfflineRegionsNotifier() : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    final regions = await OfflineTileRepository.getSavedRegions();
    state = regions;
  }

  Future<void> deleteRegion(String id) async {
    await OfflineTileRepository.deleteRegion(id);
    await refresh();
  }

  Future<void> clearAll() async {
    await OfflineTileRepository.clearAllTiles();
    await refresh();
  }
}

final offlineRegionsProvider =
    StateNotifierProvider<OfflineRegionsNotifier, List<OfflineRegion>>((ref) {
  return OfflineRegionsNotifier();
});
