import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/camp_debrief_sheet.dart';

class TrackHistorySheet extends ConsumerWidget {
  const TrackHistorySheet({super.key});

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hoursч $minutesм';
    }
    return '$minutes мин';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(completedTracksProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text(
                      'История треков похода',
                      style: TextStyle(
                        color: OutdoorTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: OutdoorTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: OutdoorTheme.borderSubtle),
            Expanded(
              child: tracksAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: OutdoorTheme.surfaceCardElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.route,
                                color: OutdoorTheme.textMuted,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Нет сохраненных треков',
                              style: TextStyle(
                                color: OutdoorTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Нажмите «Начать ходовой день», чтобы записать первый трек и получить вечерний отчет по калориям и высотам.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: OutdoorTheme.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (ctx, index) {
                      final t = tracks[index];
                      return Card(
                        color: OutdoorTheme.surfaceCardElevated,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: OutdoorTheme.borderSubtle),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.route, color: OutdoorTheme.signalOrange),
                          ),
                          title: Text(
                            t.title,
                            style: const TextStyle(
                              color: OutdoorTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${t.totalDistanceKm.toStringAsFixed(1)} км  •  +${t.elevationGainMeters.toStringAsFixed(0)} м  •  ${_formatDuration(t.movingDurationSeconds)}',
                            style: const TextStyle(color: OutdoorTheme.textMuted, fontSize: 12),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OutdoorTheme.signalOrange,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.analytics, size: 16),
                            label: const Text('Отчет', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              final profile = ref.read(activeTripProfileProvider);
                              final planResult = ref.read(calculationResultProvider);
                              if (planResult != null) {
                                final debrief = ref
                                    .read(campDebriefCalculatorProvider)
                                    .generateDebrief(
                                      track: t,
                                      profile: profile,
                                      planResult: planResult,
                                    );
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (c) => FractionallySizedBox(
                                    heightFactor: 0.90,
                                    child: CampDebriefSheet(
                                      debrief: debrief,
                                      track: t,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
                ),
                error: (e, _) => Center(
                  child: Text('Ошибка: $e', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
