import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/trip_storage/presentation/widgets/save_trip_dialog.dart';
import 'package:survival_calc/features/web/domain/services/browser_history_sync/browser_history_sync.dart';

class TripLifecycleDialogs {
  /// Shows confirmation dialog to create a new trip from scratch
  static Future<void> showNewTripConfirmation(BuildContext context, WidgetRef ref) async {
    final curProfile = ref.read(activeTripProfileProvider);
    final isCustomized = curProfile.title != 'Новый поход' ||
        curProfile.totalDistanceKm != 50.0 ||
        curProfile.durationDays != 3;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: OutdoorTheme.signalOrange, size: 24),
            SizedBox(width: 8),
            Text(
              'Новый поход',
              style: TextStyle(color: OutdoorTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Начать планирование похода с чистого листа?',
              style: TextStyle(color: OutdoorTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Параметры маршрута, загруженный GPX-трек, чек-лист снаряжения и график движения будут сброшены к базовым значениям.',
              style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            if (isCustomized) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OutdoorTheme.signalAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OutdoorTheme.signalAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: OutdoorTheme.signalAmber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Текущий поход: «${curProfile.title}»',
                        style: const TextStyle(color: OutdoorTheme.signalAmber, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Отмена', style: TextStyle(color: OutdoorTheme.textSecondary)),
          ),
          if (isCustomized)
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'save_first'),
              style: OutlinedButton.styleFrom(
                foregroundColor: OutdoorTheme.signalOrange,
                side: const BorderSide(color: OutdoorTheme.signalOrange),
              ),
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Сохранить'),
            ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'create_new'),
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.add_circle, size: 18),
            label: const Text('Создать с нуля', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == 'save_first') {
      if (context.mounted) {
        SaveTripDialog.show(context);
      }
    } else if (result == 'create_new') {
      resetToNewTrip(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Новый поход создан! Начните планирование с чистого листа.'),
            backgroundColor: OutdoorTheme.tacticalGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Resets all trip state to a fresh default trip
  static void resetToNewTrip(WidgetRef ref) {
    // 1. Reset Trip Profile
    final defaultProfile = TripProfile.createDefault();
    ref.read(activeTripProfileProvider.notifier).updateProfile(defaultProfile);

    // 2. Clear Planned Route GPX
    ref.read(plannedRouteProvider.notifier).clearPlannedRoute();

    // 3. Clear Gear Checklist
    ref.read(gearCheckedStateProvider.notifier).clear();

    // 4. Reset Participants to default
    ref.read(groupParticipantsProvider.notifier).setParticipants([
      const Participant(
        id: 'p_1',
        name: 'Участник 1',
        role: TripRole.leader,
        weightKg: 75.0,
      ),
    ]);

    // 5. If Web, sync browser URL to clean path
    if (kIsWeb) {
      try {
        final currentUri = Uri.base;
        final cleanUri = currentUri.replace(queryParameters: {});
        syncUrlToBrowserHistory(cleanUri.toString());
      } catch (_) {}
    }
  }
}
