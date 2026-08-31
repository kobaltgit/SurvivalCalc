import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';

class TrackStorageRepository {
  static const String _keyCompletedTracks = 'survival_calc_completed_tracks_v1';
  static const String _keyActiveTrack = 'survival_calc_active_track_v1';

  final SharedPreferences? prefs;

  TrackStorageRepository({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    if (prefs != null) return prefs!;
    return await SharedPreferences.getInstance();
  }

  /// Save completed track into persistent history
  Future<void> saveCompletedTrack(DailyTrack track) async {
    final prefs = await _getPrefs();
    final List<DailyTrack> list = await getCompletedTracks();
    final index = list.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      list[index] = track;
    } else {
      list.insert(0, track);
    }

    final String encoded =
        jsonEncode(list.map((t) => t.toJson()).toList());
    await prefs.setString(_keyCompletedTracks, encoded);
  }

  /// Retrieve all completed tracks
  Future<List<DailyTrack>> getCompletedTracks() async {
    final prefs = await _getPrefs();
    final String? raw = prefs.getString(_keyCompletedTracks);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => DailyTrack.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save active track snapshot (crash recovery)
  Future<void> saveActiveTrack(DailyTrack? track) async {
    final prefs = await _getPrefs();
    if (track == null) {
      await prefs.remove(_keyActiveTrack);
    } else {
      final String encoded = jsonEncode(track.toJson());
      await prefs.setString(_keyActiveTrack, encoded);
    }
  }

  /// Restore active track snapshot if app was closed during tracking
  Future<DailyTrack?> getActiveTrack() async {
    final prefs = await _getPrefs();
    final String? raw = prefs.getString(_keyActiveTrack);
    if (raw == null || raw.isEmpty) return null;

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return DailyTrack.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Delete a track by ID
  Future<void> deleteTrack(String trackId) async {
    final prefs = await _getPrefs();
    final List<DailyTrack> list = await getCompletedTracks();
    list.removeWhere((t) => t.id == trackId);
    final String encoded =
        jsonEncode(list.map((t) => t.toJson()).toList());
    await prefs.setString(_keyCompletedTracks, encoded);
  }
}
