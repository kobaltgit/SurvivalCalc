import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineRegion {
  final String id;
  final String name;
  final int tileCount;
  final double sizeMb;
  final DateTime createdAt;
  final double? centerLat;
  final double? centerLon;
  final double? radiusKm;

  const OfflineRegion({
    required this.id,
    required this.name,
    required this.tileCount,
    required this.sizeMb,
    required this.createdAt,
    this.centerLat,
    this.centerLon,
    this.radiusKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tileCount': tileCount,
      'sizeMb': sizeMb,
      'createdAt': createdAt.toIso8601String(),
      'centerLat': centerLat,
      'centerLon': centerLon,
      'radiusKm': radiusKm,
    };
  }

  factory OfflineRegion.fromMap(Map<String, dynamic> map) {
    return OfflineRegion(
      id: map['id'] as String? ?? 'region_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Офлайн карта',
      tileCount: (map['tileCount'] as num?)?.toInt() ?? 0,
      sizeMb: (map['sizeMb'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      centerLat: (map['centerLat'] as num?)?.toDouble(),
      centerLon: (map['centerLon'] as num?)?.toDouble(),
      radiusKm: (map['radiusKm'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());
  factory OfflineRegion.fromJson(String source) =>
      OfflineRegion.fromMap(json.decode(source) as Map<String, dynamic>);
}

class OfflineTileRepository {
  static const String _regionsPrefKey = 'offline_map_regions_v1';
  static String? _tilesBasePath;

  static Future<void> init() async {
    await getTilesBasePath();
  }

  static String? get tilesBasePathSync => _tilesBasePath;

  static Future<String> getTilesBasePath() async {
    if (_tilesBasePath != null) return _tilesBasePath!;
    if (kIsWeb) {
      _tilesBasePath = '/offline_tiles';
      return _tilesBasePath!;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/offline_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tilesBasePath = dir.path;
    return _tilesBasePath!;
  }

  static Future<File> getTileFile(int z, int x, int y) async {
    final basePath = await getTilesBasePath();
    return File('$basePath/$z/$x/$y.png');
  }

  static Future<bool> hasTile(int z, int x, int y) async {
    if (kIsWeb) return false;
    final file = await getTileFile(z, x, y);
    return file.exists();
  }

  static Future<void> saveTile(int z, int x, int y, List<int> bytes) async {
    if (kIsWeb) return;
    final file = await getTileFile(z, x, y);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: false);
  }

  static Future<List<OfflineRegion>> getSavedRegions() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList(_regionsPrefKey) ?? [];
    return listJson.map((str) => OfflineRegion.fromJson(str)).toList();
  }

  static Future<void> saveRegion(OfflineRegion region) async {
    final prefs = await SharedPreferences.getInstance();
    final regions = await getSavedRegions();
    regions.removeWhere((r) => r.id == region.id);
    regions.insert(0, region);
    final listJson = regions.map((r) => r.toJson()).toList();
    await prefs.setStringList(_regionsPrefKey, listJson);
  }

  static Future<void> deleteRegion(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    final regions = await getSavedRegions();
    regions.removeWhere((r) => r.id == regionId);
    final listJson = regions.map((r) => r.toJson()).toList();
    await prefs.setStringList(_regionsPrefKey, listJson);
  }

  static Future<void> clearAllTiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_regionsPrefKey);
    if (!kIsWeb) {
      final basePath = await getTilesBasePath();
      final dir = Directory(basePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    }
  }

  static Future<double> getTotalCacheSizeMb() async {
    if (kIsWeb) return 0.0;
    try {
      final basePath = await getTilesBasePath();
      final dir = Directory(basePath);
      if (!await dir.exists()) return 0.0;

      int totalBytes = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return double.parse((totalBytes / (1024 * 1024)).toStringAsFixed(1));
    } catch (_) {
      return 0.0;
    }
  }
}
