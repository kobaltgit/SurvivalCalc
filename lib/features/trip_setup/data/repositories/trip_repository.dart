import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

abstract class TripRepository {
  Future<TripProfile> loadActiveTrip();
  Future<void> saveActiveTrip(TripProfile trip);
  Future<List<TripProfile>> loadTripHistory();
  Future<void> saveTripToHistory(TripProfile trip);
  Future<Map<String, bool>> loadGearCheckedState(String tripId);
  Future<void> saveGearCheckedState(String tripId, Map<String, bool> checkedMap);
  Future<List<FoodItem>> loadCustomFoods();
  Future<void> saveCustomFoods(List<FoodItem> foods);
  Future<List<GearItem>> loadCustomGear();
  Future<void> saveCustomGear(List<GearItem> gear);
  Future<List<Participant>> loadActiveParticipants([String? tripId]);
  Future<void> saveActiveParticipants(List<Participant> participants, [String? tripId]);
}

class LocalStorageTripRepository implements TripRepository {
  static const String _activeTripKey = 'active_trip_profile';
  static const String _activeParticipantsKey = 'active_trip_participants';
  static const String _tripHistoryKey = 'trip_history_profiles';
  static const String _gearCheckedPrefix = 'gear_checked_';
  static const String _customFoodsKey = 'custom_food_items_list';
  static const String _customGearKey = 'custom_gear_items_list';

  @override
  Future<TripProfile> loadActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_activeTripKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return TripProfile.fromJson(jsonString);
      } catch (_) {}
    }
    return TripProfile.createDefault();
  }

  @override
  Future<void> saveActiveTrip(TripProfile trip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTripKey, trip.toJson());
  }

  @override
  Future<List<TripProfile>> loadTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_tripHistoryKey) ?? [];
    return jsonList
        .map((str) {
          try {
            return TripProfile.fromJson(str);
          } catch (_) {
            return null;
          }
        })
        .whereType<TripProfile>()
        .toList();
  }

  @override
  Future<void> saveTripToHistory(TripProfile trip) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadTripHistory();
    history.removeWhere((t) => t.id == trip.id);
    history.insert(0, trip);

    final stringList = history.map((t) => t.toJson()).toList();
    await prefs.setStringList(_tripHistoryKey, stringList);
  }

  @override
  Future<Map<String, bool>> loadGearCheckedState(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_gearCheckedPrefix$tripId');
    if (jsonStr != null) {
      try {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {}
    }
    return {};
  }

  @override
  Future<void> saveGearCheckedState(
      String tripId, Map<String, bool> checkedMap) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(checkedMap);
    await prefs.setString('$_gearCheckedPrefix$tripId', jsonStr);
  }

  @override
  Future<List<FoodItem>> loadCustomFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_customFoodsKey) ?? [];
    return jsonList
        .map((str) {
          try {
            final map = json.decode(str) as Map<String, dynamic>;
            return FoodItem.fromMap(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<FoodItem>()
        .toList();
  }

  @override
  Future<void> saveCustomFoods(List<FoodItem> foods) async {
    final prefs = await SharedPreferences.getInstance();
    final list = foods.map((f) => json.encode(f.toMap())).toList();
    await prefs.setStringList(_customFoodsKey, list);
  }

  @override
  Future<List<GearItem>> loadCustomGear() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_customGearKey) ?? [];
    return jsonList
        .map((str) {
          try {
            final map = json.decode(str) as Map<String, dynamic>;
            return GearItem.fromMap(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<GearItem>()
        .toList();
  }

  @override
  Future<void> saveCustomGear(List<GearItem> gear) async {
    final prefs = await SharedPreferences.getInstance();
    final list = gear.map((g) => json.encode(g.toMap())).toList();
    await prefs.setStringList(_customGearKey, list);
  }

  @override
  Future<List<Participant>> loadActiveParticipants([String? tripId]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = tripId != null ? 'participants_$tripId' : _activeParticipantsKey;
    final jsonList = prefs.getStringList(key);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList
        .map((str) {
          try {
            final map = json.decode(str) as Map<String, dynamic>;
            return Participant.fromMap(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<Participant>()
        .toList();
  }

  @override
  Future<void> saveActiveParticipants(List<Participant> participants, [String? tripId]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = tripId != null ? 'participants_$tripId' : _activeParticipantsKey;
    final list = participants.map((p) => json.encode(p.toMap())).toList();
    await prefs.setStringList(key, list);
  }
}
