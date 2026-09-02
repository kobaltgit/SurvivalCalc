import 'package:survival_calc/core/enums/trip_enums.dart';

class DailyCampNote {
  final String id;
  final String tripId;
  final int dayNumber;
  final String authorName;
  final TripRole? authorRole;
  final String text;
  final String? weather;
  final String? photoPath;
  final DateTime createdAt;

  const DailyCampNote({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.authorName,
    this.authorRole,
    required this.text,
    this.weather,
    this.photoPath,
    required this.createdAt,
  });

  DailyCampNote copyWith({
    String? id,
    String? tripId,
    int? dayNumber,
    String? authorName,
    TripRole? authorRole,
    String? text,
    String? weather,
    String? photoPath,
    DateTime? createdAt,
  }) {
    return DailyCampNote(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      text: text ?? this.text,
      weather: weather ?? this.weather,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'dayNumber': dayNumber,
      'authorName': authorName,
      if (authorRole != null) 'authorRole': authorRole!.name,
      'text': text,
      if (weather != null) 'weather': weather,
      if (photoPath != null) 'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyCampNote.fromJson(Map<String, dynamic> json) {
    return DailyCampNote(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? '',
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
      authorName: json['authorName'] as String? ?? 'Участник',
      authorRole: json['authorRole'] != null
          ? TripRole.fromString(json['authorRole'] as String)
          : null,
      text: json['text'] as String? ?? '',
      weather: json['weather'] as String?,
      photoPath: json['photoPath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
