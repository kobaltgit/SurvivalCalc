import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/trip_storage/domain/models/saved_trip_entry.dart';
import 'package:survival_calc/features/trip_storage/presentation/providers/saved_trips_providers.dart';
import 'package:survival_calc/features/trip_storage/presentation/widgets/save_trip_dialog.dart';

class TripLibrarySheet extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const TripLibrarySheet({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripLibrarySheet(initialTabIndex: initialTabIndex),
    );
  }

  @override
  ConsumerState<TripLibrarySheet> createState() => _TripLibrarySheetState();
}

class _TripLibrarySheetState extends ConsumerState<TripLibrarySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realTrips = ref.watch(savedRealTripsProvider);
    final customTemplates = ref.watch(savedTemplatesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: OutdoorTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.folder_special_outlined, color: OutdoorTheme.signalOrange),
                const SizedBox(width: 10),
                const Text(
                  'Библиотека походов',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Сохранить текущий',
                  icon: const Icon(Icons.save_outlined, color: OutdoorTheme.signalOrange),
                  onPressed: () {
                    SaveTripDialog.show(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: OutdoorTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: OutdoorTheme.signalOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: OutdoorTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.terrain_outlined, size: 18),
                  text: 'Мои походы (${realTrips.length})',
                ),
                Tab(
                  icon: const Icon(Icons.content_copy_outlined, size: 18),
                  text: 'Шаблоны (${customTemplates.length + 3})',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRealTripsTab(context, realTrips),
                _buildTemplatesTab(context, customTemplates),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Real Trips Tab ---

  Widget _buildRealTripsTab(BuildContext context, List<SavedTripEntry> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.terrain_outlined, size: 64, color: OutdoorTheme.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'У вас пока нет сохраненных походов',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OutdoorTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Нажмите «Сохранить поход», чтобы зафиксировать текущий маршрут, состав участников и прогресс сборов в чек-листе.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: OutdoorTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  SaveTripDialog.show(context, initialIsTemplate: false);
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Сохранить текущий поход'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: trips.length,
      itemBuilder: (ctx, i) {
        final entry = trips[i];
        return _buildTripCard(context, entry, isTemplate: false);
      },
    );
  }

  // --- Templates Tab ---

  Widget _buildTemplatesTab(BuildContext context, List<SavedTripEntry> customTemplates) {
    final systemPresets = [
      _SystemPreset(
        title: '🌲 Летний ПВД соло (1 чел, 2 дня)',
        description: 'Легкоходный одиночный маршрут выходного дня без лишнего веса.',
        profile: TripProfile(
          id: 'preset_pvd',
          title: 'Летний ПВД соло',
          groupSize: 1,
          durationDays: 2,
          activeDays: 2,
          totalDistanceKm: 25.0,
          totalAscentMeters: 400.0,
          season: Season.summer,
          activityType: ActivityType.hiking,
          avgParticipantWeightKg: 75.0,
          createdAt: DateTime.now(),
        ),
      ),
      _SystemPreset(
        title: '🏔️ Осенний горный поход (4 чел, 7 дней)',
        description: 'Классический категорийный трек с автономным питанием и базовым лагерем.',
        profile: TripProfile(
          id: 'preset_mountain',
          title: 'Горный поход Кавказ',
          groupSize: 4,
          durationDays: 7,
          activeDays: 7,
          totalDistanceKm: 90.0,
          totalAscentMeters: 3200.0,
          season: Season.spring_autumn,
          activityType: ActivityType.mountain,
          avgParticipantWeightKg: 75.0,
          createdAt: DateTime.now(),
        ),
      ),
      _SystemPreset(
        title: '❄️ Зимняя экстремальная автономка (2 чел, 5 дней)',
        description: 'Поход в условиях глубокого снега, морозов и автономного растапливания воды.',
        profile: TripProfile(
          id: 'preset_winter',
          title: 'Зимняя автономка',
          groupSize: 2,
          durationDays: 5,
          activeDays: 5,
          totalDistanceKm: 60.0,
          totalAscentMeters: 1500.0,
          season: Season.extreme_cold,
          activityType: ActivityType.survival,
          avgParticipantWeightKg: 75.0,
          createdAt: DateTime.now(),
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // User Templates
        if (customTemplates.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'МОИ ШАБЛОНЫ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: OutdoorTheme.signalOrange,
              ),
            ),
          ),
          ...customTemplates.map((entry) => _buildTripCard(context, entry, isTemplate: true)),
          const SizedBox(height: 16),
        ],

        // System Presets
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'БАЗОВЫЕ ШАБЛОНЫ ЭКСПЕДИЦИЙ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: OutdoorTheme.textMuted,
            ),
          ),
        ),
        ...systemPresets.map((preset) => _buildSystemPresetCard(context, preset)),

        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              SaveTripDialog.show(context, initialIsTemplate: true);
            },
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text('Сохранить текущий как новый шаблон'),
          ),
        ),
      ],
    );
  }

  // --- Cards & Item Builders ---

  Widget _buildTripCard(BuildContext context, SavedTripEntry entry, {required bool isTemplate}) {
    final p = entry.profile;
    final dateStr = '${entry.updatedAt.day.toString().padLeft(2, '0')}.${entry.updatedAt.month.toString().padLeft(2, '0')}.${entry.updatedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTemplate
              ? OutdoorTheme.signalOrange.withValues(alpha: 0.3)
              : Colors.white12,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Обновлен: $dateStr',
                      style: const TextStyle(fontSize: 11, color: OutdoorTheme.textMuted),
                    ),
                  ],
                ),
              ),
              // Menu / Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: OutdoorTheme.textMuted),
                onSelected: (val) async {
                  if (val == 'duplicate') {
                    await ref.read(savedTripsProvider.notifier).duplicateEntry(entry.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Копия создана!')),
                      );
                    }
                  } else if (val == 'delete') {
                    final confirm = await _showDeleteConfirmDialog(context, entry.title);
                    if (confirm == true) {
                      await ref.read(savedTripsProvider.notifier).deleteEntry(entry.id);
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 16, color: OutdoorTheme.signalOrange),
                        SizedBox(width: 8),
                        Text('Сделать копию'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildBadge('⛺ ${p.durationDays} дн.', Colors.blueGrey),
              _buildBadge('👥 ${p.groupSize} чел.', Colors.blueGrey),
              _buildBadge('🚶 ${p.totalDistanceKm.toStringAsFixed(0)} км', Colors.blueGrey),
              _buildBadge(p.season.displayNameRu, OutdoorTheme.signalOrange.withValues(alpha: 0.8)),
              _buildBadge(p.activityType.displayNameRu, Colors.teal),
            ],
          ),

          // Real Trip: Checklist progress indicator
          if (!isTemplate && entry.checkedGearIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.checklist_rounded, size: 14, color: OutdoorTheme.tacticalGreen),
                const SizedBox(width: 6),
                Text(
                  'Собрано предметов: ${entry.checkedGearIds.length}',
                  style: const TextStyle(fontSize: 12, color: OutdoorTheme.tacticalGreen),
                ),
              ],
            ),
          ],

          // Note if present
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.note,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: OutdoorTheme.textSecondary),
            ),
          ],

          const SizedBox(height: 12),

          // Main Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isTemplate ? OutdoorTheme.surfaceCard : OutdoorTheme.signalOrange,
                foregroundColor: isTemplate ? OutdoorTheme.signalOrange : Colors.black,
                side: isTemplate ? const BorderSide(color: OutdoorTheme.signalOrange) : null,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                _loadEntry(context, entry);
              },
              icon: Icon(isTemplate ? Icons.play_arrow_rounded : Icons.folder_open, size: 18),
              label: Text(
                isTemplate ? 'Использовать шаблон' : 'Загрузить поход',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPresetCard(BuildContext context, _SystemPreset preset) {
    final p = preset.profile;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: OutdoorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preset.description,
            style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildBadge('⛺ ${p.durationDays} дн.', Colors.blueGrey),
              _buildBadge('👥 ${p.groupSize} чел.', Colors.blueGrey),
              _buildBadge('🚶 ${p.totalDistanceKm.toStringAsFixed(0)} км', Colors.blueGrey),
              _buildBadge(p.season.displayNameRu, OutdoorTheme.signalOrange.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: OutdoorTheme.signalOrange,
                side: const BorderSide(color: OutdoorTheme.signalOrange),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () {
                final entry = SavedTripEntry(
                  id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
                  title: preset.profile.title,
                  isTemplate: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  profile: preset.profile,
                );
                _loadEntry(context, entry);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Развернуть поход'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color is MaterialColor ? Colors.white : color,
        ),
      ),
    );
  }

  void _loadEntry(BuildContext context, SavedTripEntry entry) {
    ref.read(savedTripsProvider.notifier).loadIntoActiveTrip(ref, entry);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          entry.isTemplate
              ? 'Шаблон «${entry.title}» развернут в новый поход!'
              : 'Поход «${entry.title}» успешно загружен!',
        ),
        backgroundColor: OutdoorTheme.tacticalGreen,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        title: const Text('Удаление записи'),
        content: Text('Вы действительно хотите удалить «$title»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SystemPreset {
  final String title;
  final String description;
  final TripProfile profile;

  const _SystemPreset({
    required this.title,
    required this.description,
    required this.profile,
  });
}
