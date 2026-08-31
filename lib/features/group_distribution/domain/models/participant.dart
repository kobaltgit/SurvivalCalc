import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';

class Participant {
  final String id;
  final String name;
  final double weightKg;
  final double strengthRatio; // 1.0 = standard, 1.2 = strong, 0.8 = light
  final List<DietaryRestriction> dietaryRestrictions;
  final List<MedicalCondition> medicalConditions;
  final TripRole role;
  final List<GearItem> personalGear;
  final List<GearItem> assignedGear;
  final List<ShoppingListItem> assignedFood;
  final double personalGearWeightKg;

  const Participant({
    required this.id,
    required this.name,
    this.weightKg = 75.0,
    this.strengthRatio = 1.0,
    this.dietaryRestrictions = const [DietaryRestriction.none],
    this.medicalConditions = const [MedicalCondition.none],
    this.role = TripRole.member,
    this.personalGear = const [],
    this.assignedGear = const [],
    this.assignedFood = const [],
    this.personalGearWeightKg = 0.0,
  });

  /// True if this participant requires an isolated/individual meal pack
  bool get hasSpecialDiet => dietaryRestrictions.any((d) => d != DietaryRestriction.none);

  /// True if participant has medical conditions requiring specific first-aid meds
  bool get hasMedicalNeeds => medicalConditions.any((m) => m != MedicalCondition.none);

  /// Total assigned group gear weight in kg
  double get assignedGroupGearWeightKg {
    final grams = assignedGear.fold<int>(0, (sum, g) => sum + g.totalWeightG);
    return grams / 1000.0;
  }

  /// Total assigned food weight in kg
  double get assignedFoodWeightKg {
    final grams = assignedFood.fold<int>(0, (sum, f) => sum + f.totalGrams);
    return grams / 1000.0;
  }

  /// Total backpack start weight on this participant (Personal + Assigned Group + Assigned Food + 1.5L water)
  double get totalPackWeightKg =>
      personalGearWeightKg +
      assignedGroupGearWeightKg +
      assignedFoodWeightKg +
      1.5;

  Participant copyWith({
    String? id,
    String? name,
    double? weightKg,
    double? strengthRatio,
    List<DietaryRestriction>? dietaryRestrictions,
    List<MedicalCondition>? medicalConditions,
    TripRole? role,
    List<GearItem>? personalGear,
    List<GearItem>? assignedGear,
    List<ShoppingListItem>? assignedFood,
    double? personalGearWeightKg,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      strengthRatio: strengthRatio ?? this.strengthRatio,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      role: role ?? this.role,
      personalGear: personalGear ?? this.personalGear,
      assignedGear: assignedGear ?? this.assignedGear,
      assignedFood: assignedFood ?? this.assignedFood,
      personalGearWeightKg: personalGearWeightKg ?? this.personalGearWeightKg,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weightKg': weightKg,
      'strengthRatio': strengthRatio,
      'dietaryRestrictions': dietaryRestrictions.map((d) => d.name).toList(),
      'medicalConditions': medicalConditions.map((m) => m.name).toList(),
      'role': role.name,
      'personalGearIds': personalGear.map((g) => g.id).toList(),
      'assignedGearIds': assignedGear.map((g) => g.id).toList(),
      'assignedFoodIds': assignedFood.map((f) => f.foodItem.id).toList(),
      'personalGearWeightKg': personalGearWeightKg,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'] as String? ?? 'p_1',
      name: map['name'] as String? ?? 'Участник',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 75.0,
      strengthRatio: (map['strengthRatio'] as num?)?.toDouble() ?? 1.0,
      dietaryRestrictions: (map['dietaryRestrictions'] as List<dynamic>?)
              ?.map((e) => DietaryRestriction.fromString(e.toString()))
              .toList() ??
          const [DietaryRestriction.none],
      medicalConditions: (map['medicalConditions'] as List<dynamic>?)
              ?.map((e) => MedicalCondition.fromString(e.toString()))
              .toList() ??
          const [MedicalCondition.none],
      role: map['role'] != null
          ? TripRole.fromString(map['role'].toString())
          : TripRole.member,
      personalGearWeightKg:
          (map['personalGearWeightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
