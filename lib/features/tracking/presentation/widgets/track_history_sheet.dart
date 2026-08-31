import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/camp_debrief_sheet.dart';

class TrackHistorySheet extends ConsumerStatefulWidget {
  const TrackHistorySheet({super.key});

  @override
  ConsumerState<TrackHistorySheet> createState() => _TrackHistorySheetState();
}

class _TrackHistorySheetState extends ConsumerState<TrackHistorySheet> {
  int _selectedTab = 0; // 0: Текущий поход, 1: Песочница

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hoursч $minutesм';
    }
    return '$minutes мин';
  }

  void _confirmDeleteTrack(BuildContext context, DailyTrack track) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              'Удалить трек?',
              style: TextStyle(
                color: OutdoorTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Вы уверены, что хотите удалить трек "${track.title}" (${track.totalDistanceKm.toStringAsFixed(1)} км)?\nЭто действие нельзя отменить.',
          style: const TextStyle(color: OutdoorTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: OutdoorTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(trackingProvider.notifier).deleteTrack(track.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Трек "${track.title}" удален'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _confirmClearSandbox(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: OutdoorTheme.signalOrange),
            SizedBox(width: 10),
            Text(
              'Очистить песочницу?',
              style: TextStyle(
                color: OutdoorTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Все сохраненные тестовые треки и симуляции будут удалены.',
          style: TextStyle(color: OutdoorTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: OutdoorTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
            ),
            child: const Text('Очистить',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(trackingProvider.notifier).clearSandboxTracks();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Песочница очищена'),
            backgroundColor: OutdoorTheme.signalOrange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTrip = ref.watch(activeTripProfileProvider);
    final tripTracksAsync = ref.watch(currentTripTracksProvider);
    final sandboxTracksAsync = ref.watch(sandboxTracksProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text(
                      'История треков',
                      style: TextStyle(
                        color: OutdoorTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: OutdoorTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Segmented Tab Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: OutdoorTheme.surfaceCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OutdoorTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? OutdoorTheme.signalOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏔️ ${activeTrip.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _selectedTab == 0
                                ? Colors.black
                                : OutdoorTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? OutdoorTheme.signalOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🧪 Песочница',
                          style: TextStyle(
                            color: _selectedTab == 1
                                ? Colors.black
                                : OutdoorTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildTrackList(
                      context,
                      tripTracksAsync,
                      emptyTitle: 'В этом походе еще нет треков',
                      emptySubtitle:
                          'Нажмите «Начать ходовой день», чтобы запустить запись первого перехода.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Тестовые симуляции',
                              style: TextStyle(
                                color: OutdoorTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _confirmClearSandbox(context),
                              icon: const Icon(Icons.delete_sweep,
                                  size: 16, color: Colors.redAccent),
                              label: const Text('Очистить всё',
                                  style: TextStyle(
                                      color: Colors.redAccent, fontSize: 12)),
                            ),
                          ],
                        ),
                        Expanded(
                          child: _buildTrackList(
                            context,
                            sandboxTracksAsync,
                            emptyTitle: 'Песочница пуста',
                            emptySubtitle:
                                'Запустите «🧪 Симуляция похода (Тест)» на экране карты, чтобы протестировать маршрут.',
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    AsyncValue<List<DailyTrack>> tracksAsync, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return tracksAsync.when(
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
                  Text(
                    emptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: OutdoorTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    t.isSimulation ? Icons.science : Icons.route,
                    color: OutdoorTheme.signalOrange,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.title,
                        style: const TextStyle(
                          color: OutdoorTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (t.isSimulation) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purpleAccent, width: 0.8),
                        ),
                        child: const Text(
                          'ТЕСТ',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${t.totalDistanceKm.toStringAsFixed(1)} км  •  +${t.elevationGainMeters.toStringAsFixed(0)} м  •  ${_formatDuration(t.movingDurationSeconds)}',
                  style:
                      const TextStyle(color: OutdoorTheme.textMuted, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDeleteTrack(context, t),
                      tooltip: 'Удалить трек',
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OutdoorTheme.signalOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(50, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                      child: const Text('Отчет',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
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
    );
  }
}
