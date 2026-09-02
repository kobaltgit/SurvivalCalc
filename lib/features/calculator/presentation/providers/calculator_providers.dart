import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/services/export_service.dart';
import 'package:survival_calc/core/services/qr_sync_service.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/calculator/domain/services/trip_calculator_engine.dart';
import 'package:survival_calc/features/gear/data/repositories/gear_repository.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/group_distribution/domain/services/load_distribution_service.dart';
import 'package:survival_calc/features/ration/data/repositories/food_repository.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/trip_setup/data/repositories/trip_repository.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

// --- Repositories and Services ---

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return AssetFoodRepository();
});

final gearRepositoryProvider = Provider<GearRepository>((ref) {
  return AssetGearRepository();
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return LocalStorageTripRepository();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return const ExportService();
});

final qrSyncServiceProvider = Provider<QrSyncService>((ref) {
  return const QrSyncService();
});

final loadDistributionServiceProvider = Provider<LoadDistributionService>((ref) {
  return const LoadDistributionService();
});

final tripEngineProvider = Provider<TripCalculatorEngine>((ref) {
  return const TripCalculatorEngine();
});

// --- Data Lists ---

final availableFoodsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repo = ref.watch(foodRepositoryProvider);
  return repo.loadFoods();
});

final allGearProvider = FutureProvider<List<GearItem>>((ref) async {
  final repo = ref.watch(gearRepositoryProvider);
  return repo.loadGear();
});

// --- State Notifiers ---

class TripProfileNotifier extends StateNotifier<TripProfile> {
  final TripRepository _repo;

  TripProfileNotifier(this._repo, [TripProfile? initialProfile])
      : super(initialProfile ?? TripProfile.createDefault()) {
    if (initialProfile == null) {
      _init();
    }
  }

  Future<void> _init() async {
    final active = await _repo.loadActiveTrip();
    state = active;
  }

  void updateProfile(TripProfile profile) {
    state = profile;
    _repo.saveActiveTrip(profile);
  }

  void updateTitle(String title) {
    updateProfile(state.copyWith(title: title));
  }

  void updateGroupSize(int groupSize) {
    updateProfile(state.copyWith(groupSize: groupSize));
  }

  void updateDurationDays(int days) {
    final activeDays =
        state.activeDays > days ? days : (state.activeDays == 0 ? days : state.activeDays);
    updateProfile(state.copyWith(durationDays: days, activeDays: activeDays));
  }

  void updateActiveDays(int activeDays) {
    updateProfile(state.copyWith(activeDays: activeDays));
  }

  void updateDistanceKm(double distanceKm) {
    updateProfile(state.copyWith(totalDistanceKm: distanceKm));
  }

  void updateAscentMeters(double ascentMeters) {
    updateProfile(state.copyWith(totalAscentMeters: ascentMeters));
  }

  void updateSeason(dynamic season) {
    updateProfile(state.copyWith(season: season));
  }

  void updateActivityType(dynamic activity) {
    updateProfile(state.copyWith(activityType: activity));
  }

  void updateWeightKg(double weightKg) {
    updateProfile(state.copyWith(avgParticipantWeightKg: weightKg));
  }
}

final activeTripProfileProvider =
    StateNotifierProvider<TripProfileNotifier, TripProfile>((ref) {
  final repo = ref.watch(tripRepositoryProvider);
  return TripProfileNotifier(repo);
});

class GearCheckedNotifier extends StateNotifier<Map<String, bool>> {
  final TripRepository _repo;
  String _currentTripId;

  GearCheckedNotifier(this._repo, this._currentTripId) : super({}) {
    _loadState();
  }

  Future<void> _loadState() async {
    final map = await _repo.loadGearCheckedState(_currentTripId);
    if (mounted) {
      state = map;
    }
  }

  void updateTripId(String tripId) {
    if (_currentTripId != tripId) {
      _currentTripId = tripId;
      _loadState();
    }
  }

  void setStates(Map<String, bool> newStates) {
    state = Map<String, bool>.from(newStates);
    _repo.saveGearCheckedState(_currentTripId, state);
  }

  void clear() {
    state = {};
    _repo.saveGearCheckedState(_currentTripId, {});
  }

  void toggleItem(String gearId, bool isChecked) {
    final updated = Map<String, bool>.from(state);
    updated[gearId] = isChecked;
    state = updated;
    _repo.saveGearCheckedState(_currentTripId, updated);
  }

  void toggleAll(List<GearItem> currentList, bool targetState) {
    final updated = Map<String, bool>.from(state);
    for (final g in currentList) {
      updated[g.id] = targetState;
    }
    state = updated;
    _repo.saveGearCheckedState(_currentTripId, updated);
  }
}

final gearCheckedStateProvider =
    StateNotifierProvider<GearCheckedNotifier, Map<String, bool>>((ref) {
  final repo = ref.watch(tripRepositoryProvider);
  final tripProfile = ref.watch(activeTripProfileProvider);
  return GearCheckedNotifier(repo, tripProfile.id);
});

class CustomGearNotifier extends StateNotifier<List<GearItem>> {
  final TripRepository _repo;

  CustomGearNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.loadCustomGear();
    state = items;
  }

  void addGearItem(GearItem item) {
    state = [...state, item];
    _repo.saveCustomGear(state);
  }

  void removeGearItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _repo.saveCustomGear(state);
  }
}

final customGearProvider =
    StateNotifierProvider<CustomGearNotifier, List<GearItem>>((ref) {
  final repo = ref.watch(tripRepositoryProvider);
  return CustomGearNotifier(repo);
});

class CustomFoodNotifier extends StateNotifier<List<FoodItem>> {
  final TripRepository _repo;

  CustomFoodNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.loadCustomFoods();
    state = items;
  }

  void addFoodItem(FoodItem item) {
    state = [...state, item];
    _repo.saveCustomFoods(state);
  }

  void removeFoodItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _repo.saveCustomFoods(state);
  }
}

final customFoodProvider =
    StateNotifierProvider<CustomFoodNotifier, List<FoodItem>>((ref) {
  final repo = ref.watch(tripRepositoryProvider);
  return CustomFoodNotifier(repo);
});

// --- Group Load Distribution Notifier ---

class GroupParticipantsNotifier extends StateNotifier<List<Participant>> {
  final LoadDistributionService _service;

  GroupParticipantsNotifier(this._service) : super([]);

  void setParticipants(List<Participant> participants) {
    state = List.from(participants);
  }

  void syncWithTrip({
    required int groupSize,
    required List<GearItem> allGear,
    required List<ShoppingListItem> shoppingList,
    required double personalGearWeightKg,
  }) {
    // Generate default participants if list size differs
    List<Participant> list = List.from(state);
    if (list.length != groupSize) {
      list = List.generate(groupSize, (i) {
        final id = 'p_${i + 1}';
        final existing = state.where((p) => p.id == id).firstOrNull;
        return existing ??
            Participant(
              id: id,
              name: 'Участник ${i + 1}',
              strengthRatio: 1.0,
            );
      });
    }

    final distributed = _service.autoDistribute(
      participants: list,
      allGear: allGear,
      shoppingList: shoppingList,
      personalGearWeightKg: personalGearWeightKg,
    );

    state = distributed;
  }

  void updateParticipantName(String id, String newName) {
    state = state.map((p) => p.id == id ? p.copyWith(name: newName) : p).toList();
  }

  void updateParticipantWeight(String id, double weightKg) {
    state = state.map((p) => p.id == id ? p.copyWith(weightKg: weightKg) : p).toList();
  }

  void updateStrengthRatio(String id, double ratio) {
    state = state.map((p) => p.id == id ? p.copyWith(strengthRatio: ratio) : p).toList();
  }

  void updateParticipantRole(String id, TripRole role) {
    state = state.map((p) => p.id == id ? p.copyWith(role: role) : p).toList();
  }

  void toggleDietaryRestriction(String id, DietaryRestriction diet) {
    state = state.map((p) {
      if (p.id != id) return p;
      final current = List<DietaryRestriction>.from(p.dietaryRestrictions);
      if (diet == DietaryRestriction.none) {
        return p.copyWith(dietaryRestrictions: [DietaryRestriction.none]);
      }
      current.remove(DietaryRestriction.none);
      if (current.contains(diet)) {
        current.remove(diet);
        if (current.isEmpty) current.add(DietaryRestriction.none);
      } else {
        current.add(diet);
      }
      return p.copyWith(dietaryRestrictions: current);
    }).toList();
  }

  void toggleMedicalCondition(String id, MedicalCondition med) {
    state = state.map((p) {
      if (p.id != id) return p;
      final current = List<MedicalCondition>.from(p.medicalConditions);
      if (med == MedicalCondition.none) {
        return p.copyWith(medicalConditions: [MedicalCondition.none]);
      }
      current.remove(MedicalCondition.none);
      if (current.contains(med)) {
        current.remove(med);
        if (current.isEmpty) current.add(MedicalCondition.none);
      } else {
        current.add(med);
      }
      return p.copyWith(medicalConditions: current);
    }).toList();
  }

  void addParticipant() {
    final newId = 'p_${state.length + 1}';
    final newP = Participant(
      id: newId,
      name: 'Участник ${state.length + 1}',
      weightKg: 75.0,
      strengthRatio: 1.0,
    );
    state = [...state, newP];
  }

  void removeParticipant(String id) {
    if (state.length <= 1) return;
    state = state.where((p) => p.id != id).toList();
  }

  void rebalance({
    required List<GearItem> allGear,
    required List<ShoppingListItem> shoppingList,
    required double personalGearWeightKg,
  }) {
    state = _service.autoDistribute(
      participants: state,
      allGear: allGear,
      shoppingList: shoppingList,
      personalGearWeightKg: personalGearWeightKg,
    );
  }

  void moveGear(String gearId, String targetParticipantId) {
    state = _service.reassignGearItem(
      participants: state,
      gearId: gearId,
      targetParticipantId: targetParticipantId,
    );
  }

  void moveFood(String foodId, String targetParticipantId) {
    state = _service.reassignFoodItem(
      participants: state,
      foodId: foodId,
      targetParticipantId: targetParticipantId,
    );
  }
}

final groupParticipantsProvider =
    StateNotifierProvider<GroupParticipantsNotifier, List<Participant>>((ref) {
  final service = ref.watch(loadDistributionServiceProvider);
  return GroupParticipantsNotifier(service);
});

// --- Calculation Result Provider ---

final calculationResultProvider = Provider<TripCalculationResult?>((ref) {
  final foodsAsync = ref.watch(availableFoodsProvider);
  final gearAsync = ref.watch(allGearProvider);
  final profile = ref.watch(activeTripProfileProvider);
  final checkedMap = ref.watch(gearCheckedStateProvider);
  final customGear = ref.watch(customGearProvider);
  final customFoods = ref.watch(customFoodProvider);
  final participants = ref.watch(groupParticipantsProvider);
  final engine = ref.watch(tripEngineProvider);

  if (foodsAsync.isLoading || gearAsync.isLoading) {
    return null;
  }

  final foods = foodsAsync.value ?? [];
  final gear = gearAsync.value ?? [];

  if (foods.isEmpty || gear.isEmpty) {
    return null;
  }

  final mergedFoods = [...foods, ...customFoods];
  final mergedGear = [...gear, ...customGear];

  // Apply checked states to gear
  final scaledGear = engine.gearCalculatorService.filterAndScaleGear(
    profile: profile,
    targets: engine.metabolicCalculator.calculate(profile),
    allGear: mergedGear,
    participants: participants,
  ).map((g) {
    final isChecked = checkedMap[g.id] ?? false;
    return g.copyWith(isChecked: isChecked);
  }).toList();

  return engine.calculate(
    profile: profile,
    availableFoods: mergedFoods,
    allGear: mergedGear,
    customGearOverride: scaledGear,
    participants: participants,
  );
});
