import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/trip_storage/data/repositories/saved_trips_repository.dart';
import 'package:survival_calc/features/trip_storage/domain/models/saved_trip_entry.dart';

final savedTripsRepositoryProvider = Provider<SavedTripsRepository>((ref) {
  return SavedTripsRepository();
});

class SavedTripsNotifier extends StateNotifier<AsyncValue<List<SavedTripEntry>>> {
  final SavedTripsRepository _repo;

  SavedTripsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.loadAll();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SavedTripEntry> saveCurrent({
    required String title,
    required bool isTemplate,
    required TripProfile profile,
    required Map<String, bool> checkedGearMap,
    required List<Participant> participants,
    required List<FoodItem> customFoods,
    required List<GearItem> customGear,
    PlannedRoute? plannedRoute,
    String note = '',
  }) async {
    final checkedIds = isTemplate
        ? <String>[] // Templates do NOT keep checked state
        : checkedGearMap.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

    final entry = SavedTripEntry(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? profile.title : title.trim(),
      isTemplate: isTemplate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profile: profile.copyWith(
        id: isTemplate ? 'tpl_${DateTime.now().millisecondsSinceEpoch}' : profile.id,
        title: title.trim().isEmpty ? profile.title : title.trim(),
      ),
      checkedGearIds: checkedIds,
      participants: participants,
      customFoods: customFoods,
      customGear: customGear,
      plannedRoute: plannedRoute,
      note: note,
    );

    await _repo.saveEntry(entry);
    await loadAll();
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    await loadAll();
  }

  Future<SavedTripEntry?> duplicateEntry(String id) async {
    final copy = await _repo.duplicateEntry(id);
    await loadAll();
    return copy;
  }

  void loadIntoActiveTrip(WidgetRef ref, SavedTripEntry entry) {
    // 1. Set active trip profile
    ref.read(activeTripProfileProvider.notifier).updateProfile(
          entry.profile.copyWith(
            id: entry.isTemplate
                ? 'trip_${DateTime.now().millisecondsSinceEpoch}'
                : entry.profile.id,
          ),
        );

    // 2. Set checked gear state
    final checkedNotifier = ref.read(gearCheckedStateProvider.notifier);
    if (entry.isTemplate) {
      checkedNotifier.clear();
    } else {
      final map = <String, bool>{};
      for (final id in entry.checkedGearIds) {
        map[id] = true;
      }
      checkedNotifier.setStates(map);
    }

    // 3. Set participants if available
    if (entry.participants.isNotEmpty) {
      ref.read(groupParticipantsProvider.notifier).setParticipants(entry.participants);
    }

    // 4. Set planned route if available
    if (entry.plannedRoute != null) {
      ref.read(plannedRouteProvider.notifier).setPlannedRoute(entry.plannedRoute!);
    }
  }
}

final savedTripsProvider =
    StateNotifierProvider<SavedTripsNotifier, AsyncValue<List<SavedTripEntry>>>((ref) {
  final repo = ref.watch(savedTripsRepositoryProvider);
  return SavedTripsNotifier(repo);
});

/// Filtered provider for real trips
final savedRealTripsProvider = Provider<List<SavedTripEntry>>((ref) {
  final allAsync = ref.watch(savedTripsProvider);
  return allAsync.maybeWhen(
    data: (list) => list.where((e) => !e.isTemplate).toList(),
    orElse: () => [],
  );
});

/// Filtered provider for templates
final savedTemplatesProvider = Provider<List<SavedTripEntry>>((ref) {
  final allAsync = ref.watch(savedTripsProvider);
  return allAsync.maybeWhen(
    data: (list) => list.where((e) => e.isTemplate).toList(),
    orElse: () => [],
  );
});
