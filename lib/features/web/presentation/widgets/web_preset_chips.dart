import 'package:flutter/material.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class TripPreset {
  final String label;
  final String description;
  final IconData icon;
  final Color accentColor;
  final TripProfile profile;

  const TripPreset({
    required this.label,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.profile,
  });
}

class WebPresetChips extends StatelessWidget {
  final ValueChanged<TripProfile> onPresetSelected;
  final TripProfile? currentProfile;

  const WebPresetChips({
    super.key,
    required this.onPresetSelected,
    this.currentProfile,
  });

  static List<TripPreset> get defaultPresets {
    final now = DateTime.now();
    return [
      TripPreset(
        label: 'Летний соло ПВД',
        description: '1 день • 1 чел • 18 км • Лето',
        icon: Icons.hiking,
        accentColor: OutdoorTheme.signalOrange,
        profile: TripProfile(
          id: 'preset_summer_solo',
          title: 'Летний соло ПВД',
          groupSize: 1,
          durationDays: 1,
          activeDays: 1,
          totalDistanceKm: 18.0,
          totalAscentMeters: 300.0,
          season: Season.summer,
          activityType: ActivityType.hiking,
          avgParticipantWeightKg: 75.0,
          createdAt: now,
        ),
      ),
      TripPreset(
        label: 'Осенний горный трек',
        description: '7 дней • 4 чел • 85 км • 3200 м набора',
        icon: Icons.terrain,
        accentColor: OutdoorTheme.signalAmber,
        profile: TripProfile(
          id: 'preset_mountain_trek',
          title: 'Осенний горный трек',
          groupSize: 4,
          durationDays: 7,
          activeDays: 6,
          totalDistanceKm: 85.0,
          totalAscentMeters: 3200.0,
          season: Season.spring_autumn,
          activityType: ActivityType.mountain,
          avgParticipantWeightKg: 75.0,
          createdAt: now,
        ),
      ),
      TripPreset(
        label: 'Зимняя автономка',
        description: '10 дней • 2 чел • 120 км • Зима / Снег',
        icon: Icons.ac_unit,
        accentColor: OutdoorTheme.electricCyan,
        profile: TripProfile(
          id: 'preset_winter_survival',
          title: 'Зимняя автономка',
          groupSize: 2,
          durationDays: 10,
          activeDays: 8,
          totalDistanceKm: 120.0,
          totalAscentMeters: 1500.0,
          season: Season.winter,
          activityType: ActivityType.survival,
          avgParticipantWeightKg: 78.0,
          createdAt: now,
        ),
      ),
      TripPreset(
        label: 'Водный сплав',
        description: '5 дней • 6 чел • 90 км • Водный',
        icon: Icons.kayaking,
        accentColor: OutdoorTheme.tacticalGreen,
        profile: TripProfile(
          id: 'preset_water_kayak',
          title: 'Водный сплав',
          groupSize: 6,
          durationDays: 5,
          activeDays: 4,
          totalDistanceKm: 90.0,
          totalAscentMeters: 0.0,
          season: Season.summer,
          activityType: ActivityType.water,
          avgParticipantWeightKg: 75.0,
          createdAt: now,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final presets = defaultPresets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flash_on,
              size: 16,
              color: OutdoorTheme.signalOrange,
            ),
            const SizedBox(width: 6),
            Text(
              'БЫСТРЫЕ ПРЕСЕТЫ ПОХОДОВ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: OutdoorTheme.textSecondary.withValues(alpha: 0.9),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isSelected = currentProfile?.title == preset.profile.title ||
                (currentProfile?.durationDays == preset.profile.durationDays &&
                    currentProfile?.groupSize == preset.profile.groupSize &&
                    currentProfile?.season == preset.profile.season &&
                    currentProfile?.activityType == preset.profile.activityType);

            return InkWell(
              onTap: () => onPresetSelected(preset.profile),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? preset.accentColor.withValues(alpha: 0.18)
                      : OutdoorTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? preset.accentColor
                        : OutdoorTheme.borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: preset.accentColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      preset.icon,
                      size: 18,
                      color: isSelected ? preset.accentColor : OutdoorTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : OutdoorTheme.textPrimary,
                          ),
                        ),
                        Text(
                          preset.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: OutdoorTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
