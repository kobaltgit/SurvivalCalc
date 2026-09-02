import 'dart:convert';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class SavedTripEntry {
  final String id;
  final String title;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripProfile profile;
  final List<String> checkedGearIds;
  final List<Participant> participants;
  final List<FoodItem> customFoods;
  final List<GearItem> customGear;
  final PlannedRoute? plannedRoute;
  final String note;

  const SavedTripEntry({
    required this.id,
    required this.title,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
    required this.profile,
    this.checkedGearIds = const [],
    this.participants = const [],
    this.customFoods = const [],
    this.customGear = const [],
    this.plannedRoute,
    this.note = '',
  });

  SavedTripEntry copyWith({
    String? id,
    String? title,
    bool? isTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
    TripProfile? profile,
    List<String>? checkedGearIds,
    List<Participant>? participants,
    List<FoodItem>? customFoods,
    List<GearItem>? customGear,
    PlannedRoute? plannedRoute,
    String? note,
  }) {
    return SavedTripEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      isTemplate: isTemplate ?? this.isTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
      checkedGearIds: checkedGearIds ?? this.checkedGearIds,
      participants: participants ?? this.participants,
      customFoods: customFoods ?? this.customFoods,
      customGear: customGear ?? this.customGear,
      plannedRoute: plannedRoute ?? this.plannedRoute,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isTemplate': isTemplate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profile': profile.toMap(),
      'checkedGearIds': checkedGearIds,
      'participants': participants.map((p) => p.toMap()).toList(),
      'customFoods': customFoods.map((f) => f.toMap()).toList(),
      'customGear': customGear.map((g) => g.toMap()).toList(),
      if (plannedRoute != null) 'plannedRoute': plannedRoute!.toMap(),
      'note': note,
    };
  }

  factory SavedTripEntry.fromMap(Map<String, dynamic> map) {
    return SavedTripEntry(
      id: map['id'] as String? ?? 'saved_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Сохраненный поход',
      isTemplate: map['isTemplate'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      profile: map['profile'] != null
          ? TripProfile.fromMap(map['profile'] as Map<String, dynamic>)
          : TripProfile.createDefault(),
      checkedGearIds: (map['checkedGearIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      participants: (map['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          const [],
      customFoods: (map['customFoods'] as List<dynamic>?)
              ?.map((f) => FoodItem.fromMap(f as Map<String, dynamic>))
              .toList() ??
          const [],
      customGear: (map['customGear'] as List<dynamic>?)
              ?.map((g) => GearItem.fromMap(g as Map<String, dynamic>))
              .toList() ??
          const [],
      plannedRoute: map['plannedRoute'] != null
          ? PlannedRoute.fromMap(map['plannedRoute'] as Map<String, dynamic>)
          : null,
      note: map['note'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory SavedTripEntry.fromJson(String source) =>
      SavedTripEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
