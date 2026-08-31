import 'package:survival_calc/core/enums/trip_enums.dart';

class FoodItem {
  final String id;
  final String nameRu;
  final FoodCategory category;
  final double calories100g;
  final double protein100g;
  final double fat100g;
  final double carbs100g;
  final double potassiumMg100g;
  final double magnesiumMg100g;
  final double sodiumMg100g;
  final double ironMg100g;
  final double vitCMg100g;
  final int portionG;
  final int shelfLifeDays;
  final bool isCustom;

  const FoodItem({
    required this.id,
    required this.nameRu,
    required this.category,
    required this.calories100g,
    required this.protein100g,
    required this.fat100g,
    required this.carbs100g,
    required this.potassiumMg100g,
    required this.magnesiumMg100g,
    required this.sodiumMg100g,
    required this.ironMg100g,
    required this.vitCMg100g,
    required this.portionG,
    required this.shelfLifeDays,
    this.isCustom = false,
  });

  /// Caloric density: kcal per gram
  double get caloricDensity => calories100g / 100.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameRu': nameRu,
      'category': category.name,
      'calories100g': calories100g,
      'protein100g': protein100g,
      'fat100g': fat100g,
      'carbs100g': carbs100g,
      'potassiumMg100g': potassiumMg100g,
      'magnesiumMg100g': magnesiumMg100g,
      'sodiumMg100g': sodiumMg100g,
      'ironMg100g': ironMg100g,
      'vitCMg100g': vitCMg100g,
      'portionG': portionG,
      'shelfLifeDays': shelfLifeDays,
      'isCustom': isCustom,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      category: FoodCategory.fromString(map['category'] as String? ?? 'grains'),
      calories100g: (map['calories100g'] as num?)?.toDouble() ?? 0.0,
      protein100g: (map['protein100g'] as num?)?.toDouble() ?? 0.0,
      fat100g: (map['fat100g'] as num?)?.toDouble() ?? 0.0,
      carbs100g: (map['carbs100g'] as num?)?.toDouble() ?? 0.0,
      potassiumMg100g: (map['potassiumMg100g'] as num?)?.toDouble() ?? 0.0,
      magnesiumMg100g: (map['magnesiumMg100g'] as num?)?.toDouble() ?? 0.0,
      sodiumMg100g: (map['sodiumMg100g'] as num?)?.toDouble() ?? 0.0,
      ironMg100g: (map['ironMg100g'] as num?)?.toDouble() ?? 0.0,
      vitCMg100g: (map['vitCMg100g'] as num?)?.toDouble() ?? 0.0,
      portionG: (map['portionG'] as num?)?.toInt() ?? 50,
      shelfLifeDays: (map['shelfLifeDays'] as num?)?.toInt() ?? 365,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  FoodItem copyWith({
    String? id,
    String? nameRu,
    FoodCategory? category,
    double? calories100g,
    double? protein100g,
    double? fat100g,
    double? carbs100g,
    double? potassiumMg100g,
    double? magnesiumMg100g,
    double? sodiumMg100g,
    double? ironMg100g,
    double? vitCMg100g,
    int? portionG,
    int? shelfLifeDays,
    bool? isCustom,
  }) {
    return FoodItem(
      id: id ?? this.id,
      nameRu: nameRu ?? this.nameRu,
      category: category ?? this.category,
      calories100g: calories100g ?? this.calories100g,
      protein100g: protein100g ?? this.protein100g,
      fat100g: fat100g ?? this.fat100g,
      carbs100g: carbs100g ?? this.carbs100g,
      potassiumMg100g: potassiumMg100g ?? this.potassiumMg100g,
      magnesiumMg100g: magnesiumMg100g ?? this.magnesiumMg100g,
      sodiumMg100g: sodiumMg100g ?? this.sodiumMg100g,
      ironMg100g: ironMg100g ?? this.ironMg100g,
      vitCMg100g: vitCMg100g ?? this.vitCMg100g,
      portionG: portionG ?? this.portionG,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
