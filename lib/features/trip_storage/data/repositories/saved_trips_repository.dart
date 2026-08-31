import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/features/trip_storage/domain/models/saved_trip_entry.dart';

class SavedTripsRepository {
  static const String _storageKey = 'survival_calc_saved_trips_v1';

  final SharedPreferences? _prefs;

  SavedTripsRepository([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<List<SavedTripEntry>> loadAll() async {
    final prefs = await _getPrefs();
    final rawJsonList = prefs.getStringList(_storageKey);
    if (rawJsonList == null || rawJsonList.isEmpty) {
      return [];
    }

    final entries = <SavedTripEntry>[];
    for (final raw in rawJsonList) {
      try {
        entries.add(SavedTripEntry.fromJson(raw));
      } catch (e) {
        // Skip corrupted entries
      }
    }
    // Sort by updatedAt descending
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  Future<void> saveEntry(SavedTripEntry entry) async {
    final prefs = await _getPrefs();
    final all = await loadAll();

    final existingIndex = all.indexWhere((e) => e.id == entry.id);
    if (existingIndex >= 0) {
      all[existingIndex] = entry.copyWith(updatedAt: DateTime.now());
    } else {
      all.insert(0, entry);
    }

    final stringList = all.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, stringList);
  }

  Future<void> deleteEntry(String id) async {
    final prefs = await _getPrefs();
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);

    final stringList = all.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, stringList);
  }

  Future<SavedTripEntry?> duplicateEntry(String id) async {
    final all = await loadAll();
    final existingIndex = all.indexWhere((e) => e.id == id);
    if (existingIndex < 0) return null;

    final original = all[existingIndex];
    final copy = original.copyWith(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      title: '${original.title} (Копия)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveEntry(copy);
    return copy;
  }
}
