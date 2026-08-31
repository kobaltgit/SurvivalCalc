import 'package:survival_calc/core/enums/trip_enums.dart';

class GearItem {
  final String id;
  final String nameRu;
  final GearCategory category;
  final GearType type;
  final int weightG;
  final GearSeason season;
  final bool isMandatory;
  final int quantity;
  final bool isChecked;
  final bool isCustom;

  const GearItem({
    required this.id,
    required this.nameRu,
    required this.category,
    required this.type,
    required this.weightG,
    required this.season,
    required this.isMandatory,
    this.quantity = 1,
    this.isChecked = false,
    this.isCustom = false,
  });

  int get totalWeightG => weightG * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameRu': nameRu,
      'category': category.name,
      'type': type.name,
      'weightG': weightG,
      'season': season.name,
      'isMandatory': isMandatory,
      'quantity': quantity,
      'isChecked': isChecked,
      'isCustom': isCustom,
    };
  }

  factory GearItem.fromMap(Map<String, dynamic> map) {
    return GearItem(
      id: map['id'] as String? ?? '',
      nameRu: map['nameRu'] as String? ?? '',
      category:
          GearCategory.fromString(map['category'] as String? ?? 'shelter'),
      type: GearType.fromString(map['type'] as String? ?? 'personal'),
      weightG: (map['weightG'] as num?)?.toInt() ?? 0,
      season: GearSeason.fromString(map['season'] as String? ?? 'all'),
      isMandatory: map['isMandatory'] as bool? ?? false,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isChecked: map['isChecked'] as bool? ?? false,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  GearItem copyWith({
    String? id,
    String? nameRu,
    GearCategory? category,
    GearType? type,
    int? weightG,
    GearSeason? season,
    bool? isMandatory,
    int? quantity,
    bool? isChecked,
    bool? isCustom,
  }) {
    return GearItem(
      id: id ?? this.id,
      nameRu: nameRu ?? this.nameRu,
      category: category ?? this.category,
      type: type ?? this.type,
      weightG: weightG ?? this.weightG,
      season: season ?? this.season,
      isMandatory: isMandatory ?? this.isMandatory,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
