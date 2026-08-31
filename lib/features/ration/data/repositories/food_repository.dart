import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';

abstract class FoodRepository {
  Future<List<FoodItem>> loadFoods();
  Future<void> saveCustomFood(FoodItem food);
}

class AssetFoodRepository implements FoodRepository {
  static const String _assetPath = 'assets/data/food_db.json';
  List<FoodItem>? _cachedFoods;

  @override
  Future<List<FoodItem>> loadFoods() async {
    if (_cachedFoods != null) {
      return _cachedFoods!;
    }

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      _cachedFoods = jsonList
          .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList();
      return _cachedFoods!;
    } catch (e) {
      // Fallback if asset loading fails
      return [];
    }
  }

  @override
  Future<void> saveCustomFood(FoodItem food) async {
    _cachedFoods ??= await loadFoods();
    _cachedFoods!.add(food);
  }
}
