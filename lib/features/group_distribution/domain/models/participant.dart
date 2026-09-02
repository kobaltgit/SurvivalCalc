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
  final String fullName;
  final String touristExperience;
  final String contactPhone;

  // New MKK 2020 Standard Fields
  final Gender gender;
  final int? birthYear;
  final String cityRegion;
  final String emergencyContactRelatives;

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
    this.fullName = '',
    this.touristExperience = '',
    this.contactPhone = '',
    this.gender = Gender.male,
    this.birthYear,
    this.cityRegion = '',
    this.emergencyContactRelatives = '',
  });

  /// Display name (full name if provided, otherwise standard name)
  String get displayName => fullName.trim().isNotEmpty ? fullName : name;

  /// True if this participant requires an isolated/individual meal pack
  bool get hasSpecialDiet =>
      dietaryRestrictions.any((d) => d != DietaryRestriction.none);

  /// True if participant has medical conditions requiring specific first-aid meds
  bool get hasMedicalNeeds =>
      medicalConditions.any((m) => m != MedicalCondition.none);

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
    String? fullName,
    String? touristExperience,
    String? contactPhone,
    Gender? gender,
    int? birthYear,
    String? cityRegion,
    String? emergencyContactRelatives,
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
      fullName: fullName ?? this.fullName,
      touristExperience: touristExperience ?? this.touristExperience,
      contactPhone: contactPhone ?? this.contactPhone,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      cityRegion: cityRegion ?? this.cityRegion,
      emergencyContactRelatives:
          emergencyContactRelatives ?? this.emergencyContactRelatives,
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
      'fullName': fullName,
      'touristExperience': touristExperience,
      'contactPhone': contactPhone,
      'gender': gender.name,
      'birthYear': birthYear,
      'cityRegion': cityRegion,
      'emergencyContactRelatives': emergencyContactRelatives,
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
      fullName: map['fullName'] as String? ?? '',
      touristExperience: map['touristExperience'] as String? ?? '',
      contactPhone: map['contactPhone'] as String? ?? '',
      gender: map['gender'] != null
          ? Gender.fromString(map['gender'].toString())
          : Gender.male,
      birthYear: (map['birthYear'] as num?)?.toInt(),
      cityRegion: map['cityRegion'] as String? ?? '',
      emergencyContactRelatives:
          map['emergencyContactRelatives'] as String? ?? '',
    );
  }
}
