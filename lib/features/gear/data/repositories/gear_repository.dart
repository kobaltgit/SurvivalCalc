import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';

abstract class GearRepository {
  Future<List<GearItem>> loadGear();
  Future<void> saveCustomGear(GearItem gear);
}

class AssetGearRepository implements GearRepository {
  static const String _assetPath = 'assets/data/gear_db.json';
  List<GearItem>? _cachedGear;

  @override
  Future<List<GearItem>> loadGear() async {
    if (_cachedGear != null) {
      return _cachedGear!;
    }

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      _cachedGear = jsonList
          .map((item) => GearItem.fromMap(item as Map<String, dynamic>))
          .toList();
      return _cachedGear!;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveCustomGear(GearItem gear) async {
    _cachedGear ??= await loadGear();
    _cachedGear!.add(gear);
  }
}
