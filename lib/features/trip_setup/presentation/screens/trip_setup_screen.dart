import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/app_logo.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/mkk_reports/presentation/dialogs/mkk_export_sheet.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/gpx_import_dialog.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/offline_maps_sheet.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/trip_storage/presentation/widgets/save_trip_dialog.dart';
import 'package:survival_calc/features/trip_storage/presentation/widgets/trip_library_sheet.dart';
import 'package:survival_calc/features/wiki/presentation/screens/wiki_screen.dart';

class TripSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCalculatePressed;

  const TripSetupScreen({super.key, this.onCalculatePressed});

  @override
  ConsumerState<TripSetupScreen> createState() => _TripSetupScreenState();
}

class _TripSetupScreenState extends ConsumerState<TripSetupScreen> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(activeTripProfileProvider);
    _titleController = TextEditingController(text: profile.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeTripProfileProvider);
    final result = ref.watch(calculationResultProvider);
    final plannedRoute = ref.watch(plannedRouteProvider);

    final isWide = MediaQuery.of(context).size.width >= 650;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(height: 26),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Параметры похода',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'База знаний & Википедия',
            icon: const Icon(Icons.menu_book_rounded, color: Colors.cyanAccent),
            onPressed: () {
              WikiScreen.navigate(context);
            },
          ),
          if (isWide) ...[
            IconButton(
              tooltip: 'Документы МКК / Отчеты',
              icon: const Icon(Icons.picture_as_pdf, color: OutdoorTheme.signalOrange),
              onPressed: () {
                MkkExportSheet.show(context);
              },
            ),
            IconButton(
              tooltip: 'Импорт GPX трека',
              icon: const Icon(Icons.alt_route, color: OutdoorTheme.signalOrange),
              onPressed: () async {
                final route = await GpxImportDialog.show(context);
                if (route != null) {
                  setState(() {
                    _titleController.text = route.name;
                  });
                }
              },
            ),
            IconButton(
              tooltip: 'Сохранить поход / шаблон',
              icon: const Icon(Icons.save_outlined, color: OutdoorTheme.signalOrange),
              onPressed: () {
                SaveTripDialog.show(context);
              },
            ),
            IconButton(
              tooltip: 'Мои походы и шаблоны',
              icon: const Icon(Icons.folder_special_outlined, color: OutdoorTheme.signalOrange),
              onPressed: () {
                TripLibrarySheet.show(context);
              },
            ),
          ],
          PopupMenuButton<String>(
            tooltip: 'Меню и инструменты',
            icon: const Icon(Icons.more_vert, color: OutdoorTheme.signalOrange),
            onSelected: (val) async {
              if (val == 'wiki') {
                WikiScreen.navigate(context);
              } else if (val == 'mkk_export') {
                MkkExportSheet.show(context);
              } else if (val == 'gpx_import') {
                final route = await GpxImportDialog.show(context);
                if (route != null) {
                  setState(() {
                    _titleController.text = route.name;
                  });
                }
              } else if (val == 'save_trip') {
                SaveTripDialog.show(context);
              } else if (val == 'library') {
                TripLibrarySheet.show(context);
              } else if (val == 'share_qr') {
                ref.read(qrSyncServiceProvider).showQrShareModal(context, ref);
              } else if (val == 'import_qr') {
                ref.read(qrSyncServiceProvider).showQrImportModal(context, ref);
              } else if (val == 'library_templates') {
                TripLibrarySheet.show(context, initialTabIndex: 1);
              }
            },
            itemBuilder: (ctx) => [
              if (!isWide) ...[
                const PopupMenuItem(
                  value: 'save_trip',
                  child: Row(
                    children: [
                      Icon(Icons.save_outlined, size: 18, color: OutdoorTheme.signalOrange),
                      SizedBox(width: 8),
                      Text('Сохранить поход'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'library',
                  child: Row(
                    children: [
                      Icon(Icons.folder_special_outlined, size: 18, color: OutdoorTheme.signalOrange),
                      SizedBox(width: 8),
                      Text('Мои походы'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'gpx_import',
                  child: Row(
                    children: [
                      Icon(Icons.alt_route, size: 18, color: OutdoorTheme.signalOrange),
                      SizedBox(width: 8),
                      Text('Импорт GPX трека'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mkk_export',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 18, color: OutdoorTheme.signalOrange),
                      SizedBox(width: 8),
                      Text('Документы МКК / Отчет'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: 'share_qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2, size: 18, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text('Поделиться по QR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_qr',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, size: 18, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text('Импортировать по QR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'library_templates',
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 18, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text('Готовые шаблоны походов'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Trip Name input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название маршрута / похода',
                    prefixIcon: Icon(Icons.edit_note, color: OutdoorTheme.signalOrange),
                  ),
                  onChanged: (val) {
                    ref.read(activeTripProfileProvider.notifier).updateTitle(val);
                  },
                ),
              ),

              // 1.1. Planned GPX Route Banner/Card
              _buildPlannedRouteCard(context, plannedRoute, ref),

              // 2. Group Size, Dietary & Medical Conditions Card
              _buildParticipantsCard(context, profile, ref),

              // 3. Duration & Days Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⏱️ Продолжительность похода',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Всего дней в походе:',
                              style: TextStyle(fontSize: 14, color: OutdoorTheme.textSecondary)),
                          Text(
                            '${profile.durationDays} дн.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.signalOrange,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: profile.durationDays.toDouble(),
                        min: 1.0,
                        max: 30.0,
                        divisions: 29,
                        label: '${profile.durationDays} дней',
                        onChanged: (val) {
                          ref
                              .read(activeTripProfileProvider.notifier)
                              .updateDurationDays(val.toInt());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Из них ходовых дней:',
                              style: TextStyle(fontSize: 14, color: OutdoorTheme.textSecondary)),
                          Text(
                            '${profile.activeDays} дн.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.signalAmber,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: profile.activeDays.toDouble().clamp(1.0, profile.durationDays.toDouble()),
                        min: 1.0,
                        max: profile.durationDays.toDouble(),
                        divisions: profile.durationDays > 1 ? profile.durationDays - 1 : 1,
                        label: '${profile.activeDays} ходовых',
                        onChanged: (val) {
                          ref
                              .read(activeTripProfileProvider.notifier)
                              .updateActiveDays(val.toInt());
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Distance and Elevation Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🗺️ Маршрут и рельеф',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Общая дистанция:',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: OutdoorTheme.textSecondary)),
                          ),
                          Text(
                            '${profile.totalDistanceKm.toStringAsFixed(0)} км',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.signalOrange,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: profile.totalDistanceKm.clamp(1.0, 300.0),
                        min: 1.0,
                        max: 300.0,
                        divisions: 299,
                        label: '${profile.totalDistanceKm.toInt()} км',
                        onChanged: (val) {
                          ref
                              .read(activeTripProfileProvider.notifier)
                              .updateDistanceKm(val);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Суммарный набор высоты:',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: OutdoorTheme.textSecondary)),
                          ),
                          Text(
                            '${profile.totalAscentMeters.toInt()} м',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.electricCyan,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: profile.totalAscentMeters.clamp(0.0, 7000.0),
                        min: 0.0,
                        max: 7000.0,
                        divisions: 70,
                        label: '${profile.totalAscentMeters.toInt()} м',
                        onChanged: (val) {
                          ref
                              .read(activeTripProfileProvider.notifier)
                              .updateAscentMeters(val);
                        },
                      ),
                      if (result != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: OutdoorTheme.surfaceCardElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.show_chart,
                                  color: OutdoorTheme.signalAmber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Эквивалентная нагрузка с учетом рельефа: ${result.targets.equivalentDistanceKm.toStringAsFixed(1)} км (${result.targets.dailyEquivalentKm.toStringAsFixed(1)} км/день)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: OutdoorTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 5. Season Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌡️ Сезон и погодные условия',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...Season.values.map((s) {
                        final isSelected = profile.season == s;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(activeTripProfileProvider.notifier)
                                  .updateSeason(s);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? OutdoorTheme.signalOrange.withValues(alpha: 0.18)
                                    : OutdoorTheme.surfaceCardElevated,
                                border: Border.all(
                                  color: isSelected
                                      ? OutdoorTheme.signalOrange
                                      : OutdoorTheme.borderSubtle,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    s == Season.summer
                                        ? Icons.wb_sunny_outlined
                                        : s == Season.spring_autumn
                                            ? Icons.park_outlined
                                            : s == Season.winter
                                                ? Icons.ac_unit
                                                : Icons.severe_cold,
                                    color: isSelected
                                        ? OutdoorTheme.signalOrange
                                        : OutdoorTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.displayNameRu,
                                      style: TextStyle(
                                        color: isSelected
                                            ? OutdoorTheme.signalOrange
                                            : OutdoorTheme.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: OutdoorTheme.signalOrange, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // 6. Activity Type Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧗 Тип активности',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ActivityType.values.map((a) {
                          final isSelected = profile.activityType == a;
                          return ChoiceChip(
                            label: Text(a.displayNameRu),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                ref
                                    .read(activeTripProfileProvider.notifier)
                                    .updateActivityType(a);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 6.5. MKK and Sports Tourism Section
              _buildMkkSection(context, profile, ref),

              // 7. Summary CTA Banner
              if (result != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: OutdoorTheme.surfaceCardElevated,
                      border: Border.all(color: OutdoorTheme.signalOrange, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        // Activity specs badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: OutdoorTheme.signalOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.activityType == ActivityType.survival
                                ? '⚡ Выживание (PAL 2.6 • Белок 2.0 г/кг)'
                                : profile.activityType == ActivityType.mountain
                                    ? '🏔️ Горный (+250 ккал • Белок 1.8 г/кг)'
                                    : profile.activityType == ActivityType.water
                                        ? '🚣 Водный (+150 ккал • Белок 1.7 г/кг)'
                                        : '🌲 Пеший туризм (Белок 1.6 г/кг)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.signalOrange,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickStat(
                                'Калории',
                                '${result.targets.dailyCalories.toInt()} ккал',
                                OutdoorTheme.signalOrange,
                              ),
                            ),
                            Expanded(
                              child: _buildQuickStat(
                                'Белки',
                                '${result.targets.dailyProteinG.toInt()} г/д',
                                OutdoorTheme.electricCyan,
                              ),
                            ),
                            Expanded(
                              child: _buildQuickStat(
                                'Рюкзак',
                                '${result.startPackWeightPerPersonKg.toStringAsFixed(1)} кг',
                                OutdoorTheme.signalAmber,
                              ),
                            ),
                            Expanded(
                              child: _buildQuickStat(
                                'Еда/день',
                                '${(result.foodWeightPerPersonPerDayKg * 1000).toInt()} г',
                                OutdoorTheme.tacticalGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                onPressed: () => MkkExportSheet.show(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: OutdoorTheme.signalOrange,
                                  side: const BorderSide(color: OutdoorTheme.signalOrange),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                ),
                                icon: const Icon(Icons.picture_as_pdf, size: 16),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'МКК / Отчет',
                                    maxLines: 1,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: ElevatedButton.icon(
                                onPressed: widget.onCalculatePressed,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'К дашборду',
                                    maxLines: 1,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMkkSection(BuildContext context, TripProfile profile, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: profile.clubOrCity.isNotEmpty || profile.difficultyCategory != 'н/к',
        leading: const Icon(Icons.military_tech, color: OutdoorTheme.signalOrange),
        title: const Text(
          '🏅 Спортивный туризм и реквизиты МКК',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: OutdoorTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          'Кат. сл.: ${profile.difficultyCategory} • ${profile.clubOrCity.isNotEmpty ? profile.clubOrCity : "Клуб не указан"}',
          style: const TextStyle(fontSize: 11, color: OutdoorTheme.textSecondary),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Text(
            'Заполните официальные данные для маршрутной книжки и отчета МКК:',
            style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          // Category of difficulty chips
          const Text('Категория сложности (к.с.):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OutdoorTheme.textPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['н/к', '1 к.с.', '2 к.с.', '3 к.с.', '4 к.с.', '5 к.с.', '6 к.с.', 'ПВД'].map((cat) {
              final isSelected = profile.difficultyCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    ref.read(activeTripProfileProvider.notifier).updateMkkDetails(difficultyCategory: cat);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextFormField(
            initialValue: profile.clubOrCity,
            decoration: const InputDecoration(
              labelText: 'Турклуб / Город / Организация',
              prefixIcon: Icon(Icons.home_work_outlined),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeTripProfileProvider.notifier).updateMkkDetails(clubOrCity: val.trim());
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            initialValue: profile.mkkName,
            decoration: const InputDecoration(
              labelText: 'Выпускающая МКК (номер/название)',
              prefixIcon: Icon(Icons.verified_user_outlined),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeTripProfileProvider.notifier).updateMkkDetails(mkkName: val.trim());
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            initialValue: profile.geographicalRegion,
            decoration: const InputDecoration(
              labelText: 'Географический район похода',
              prefixIcon: Icon(Icons.map_outlined),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeTripProfileProvider.notifier).updateMkkDetails(geographicalRegion: val.trim());
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            initialValue: profile.emergencyExitRoutes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Аварийные сходы и запасные пути',
              prefixIcon: Icon(Icons.warning_amber_outlined),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeTripProfileProvider.notifier).updateMkkDetails(emergencyExitRoutes: val.trim());
            },
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => MkkExportSheet.show(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: OutdoorTheme.signalOrange,
                side: const BorderSide(color: OutdoorTheme.signalOrange),
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Сформировать документы МКК (PDF / ZIP)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: OutdoorTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsCard(
      BuildContext context, TripProfile profile, WidgetRef ref) {
    final participants = ref.watch(groupParticipantsProvider);

    // If participants list is empty or length differs from groupSize, sync it
    if (participants.isEmpty || participants.length != profile.groupSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final result = ref.read(calculationResultProvider);
        ref.read(groupParticipantsProvider.notifier).syncWithTrip(
              groupSize: profile.groupSize,
              allGear: result?.gearList ?? [],
              shoppingList: result?.shoppingList ?? [],
              personalGearWeightKg: result?.totalPersonalGearWeightKg ?? 8.0,
            );
      });
    }

    final avgWeight = participants.isNotEmpty
        ? participants.fold<double>(0.0, (s, p) => s + p.weightKg) /
            participants.length
        : profile.avgParticipantWeightKg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '👥 Состав группы',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: OutdoorTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: profile.groupSize > 1
                          ? () {
                              final newSize = profile.groupSize - 1;
                              ref
                                  .read(activeTripProfileProvider.notifier)
                                  .updateGroupSize(newSize);
                              if (participants.isNotEmpty) {
                                ref
                                    .read(groupParticipantsProvider.notifier)
                                    .removeParticipant(participants.last.id);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.remove, size: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${profile.groupSize} чел.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.signalOrange,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: profile.groupSize < 25
                          ? () {
                              final newSize = profile.groupSize + 1;
                              ref
                                  .read(activeTripProfileProvider.notifier)
                                  .updateGroupSize(newSize);
                              ref
                                  .read(groupParticipantsProvider.notifier)
                                  .addParticipant();
                            }
                          : null,
                      icon: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Укажите вес, диеты и заболевания участников для персонального меню и аптечки:',
              style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
            ),
            const SizedBox(height: 12),

            // Participant Tiles List
            ...participants.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: OutdoorTheme.surfaceCardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (p.hasSpecialDiet || p.hasMedicalNeeds)
                        ? OutdoorTheme.signalOrange.withValues(alpha: 0.5)
                        : OutdoorTheme.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                      child: Text(
                        p.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.signalOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: OutdoorTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${p.weightKg.toInt()} кг • ${p.strengthRatio}x',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: OutdoorTheme.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: OutdoorTheme.signalOrange
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: OutdoorTheme.signalOrange
                                          .withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  p.role.badgeTitle,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: OutdoorTheme.signalOrange,
                                  ),
                                ),
                              ),
                              if (p.hasSpecialDiet)
                                ...p.dietaryRestrictions
                                    .where((d) => d != DietaryRestriction.none)
                                    .map((d) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: OutdoorTheme.tacticalGreen
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color:
                                                    OutdoorTheme.tacticalGreen),
                                          ),
                                          child: Text(
                                            d.shortTag,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: OutdoorTheme.tacticalGreen,
                                            ),
                                          ),
                                        )),
                              if (p.hasMedicalNeeds)
                                ...p.medicalConditions
                                    .where((m) => m != MedicalCondition.none)
                                    .map((m) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: OutdoorTheme.alertRed
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: OutdoorTheme.alertRed),
                                          ),
                                          child: Text(
                                            m.displayNameRu.split(' ').first,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: OutdoorTheme.alertRed,
                                            ),
                                          ),
                                        )),
                              if (!p.hasSpecialDiet && !p.hasMedicalNeeds)
                                const Text(
                                  'Обычный рацион • Здоров',
                                  style: TextStyle(fontSize: 10, color: OutdoorTheme.textMuted),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: OutdoorTheme.signalOrange, size: 20),
                      tooltip: 'Настроить диету и здоровье',
                      onPressed: () => _showParticipantDetailDialog(context, p, ref),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 16, color: OutdoorTheme.borderSubtle),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Средний вес по группе:',
                    style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary)),
                Text(
                  '${avgWeight.toStringAsFixed(1)} кг',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.signalOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantDetailDialog(
      BuildContext context, Participant p, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: p.name);
    double weight = p.weightKg;
    double ratio = p.strengthRatio;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentP = ref
              .watch(groupParticipantsProvider)
              .firstWhere((item) => item.id == p.id, orElse: () => p);

          return Dialog(
            backgroundColor: OutdoorTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '👤 Анкета участника',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Имя участника',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (val) {
                        ref
                            .read(groupParticipantsProvider.notifier)
                            .updateParticipantName(p.id, val.trim());
                      },
                    ),
                    const SizedBox(height: 16),

                    // Weight slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Вес участника:',
                            style: TextStyle(fontSize: 13, color: OutdoorTheme.textSecondary)),
                        Text(
                          '${weight.toInt()} кг',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.signalOrange,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: weight,
                      min: 40.0,
                      max: 130.0,
                      divisions: 90,
                      label: '${weight.toInt()} кг',
                      onChanged: (val) {
                        setModalState(() => weight = val);
                        ref
                            .read(groupParticipantsProvider.notifier)
                            .updateParticipantWeight(p.id, val);

                        // Also update average group weight in profile
                        final all = ref.read(groupParticipantsProvider);
                        final newAvg = all.fold<double>(0.0, (s, x) => s + x.weightKg) / all.length;
                        ref.read(activeTripProfileProvider.notifier).updateWeightKg(newAvg);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Strength ratio
                    const Text('Сила / Нагрузка:',
                        style: TextStyle(fontSize: 13, color: OutdoorTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ChoiceChip(
                          label: const Text('0.8x (Легкий)'),
                          selected: ratio == 0.8,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => ratio = 0.8);
                              ref
                                  .read(groupParticipantsProvider.notifier)
                                  .updateStrengthRatio(p.id, 0.8);
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('1.0x (Норма)'),
                          selected: ratio == 1.0,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => ratio = 1.0);
                              ref
                                  .read(groupParticipantsProvider.notifier)
                                  .updateStrengthRatio(p.id, 1.0);
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('1.2x (Крепкий)'),
                          selected: ratio == 1.2,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => ratio = 1.2);
                              ref
                                  .read(groupParticipantsProvider.notifier)
                                  .updateStrengthRatio(p.id, 1.2);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Trip Role Selector
                    const Text(
                      '👑 Должность в походе:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.signalOrange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: TripRole.values.map((r) {
                        final isSelected = currentP.role == r;
                        return ChoiceChip(
                          label: Text(r.badgeTitle),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              ref
                                  .read(groupParticipantsProvider.notifier)
                                  .updateParticipantRole(p.id, r);
                              setModalState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),

                    // Dietary Restrictions Chips
                    const Text(
                      '🥦 Ограничения по питанию (Спец-рацион):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.tacticalGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: DietaryRestriction.values.map((diet) {
                        final isSelected =
                            currentP.dietaryRestrictions.contains(diet);
                        return FilterChip(
                          label: Text(diet.displayNameRu),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(groupParticipantsProvider.notifier)
                                .toggleDietaryRestriction(p.id, diet);
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),

                    // Medical Conditions Chips
                    const Text(
                      '🩺 Заболевания и аптечка:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.alertRed,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: MedicalCondition.values.map((med) {
                        final isSelected =
                            currentP.medicalConditions.contains(med);
                        return FilterChip(
                          label: Text(med.displayNameRu),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(groupParticipantsProvider.notifier)
                                .toggleMedicalCondition(p.id, med);
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),

                    // MKK and Sports Tourism Fields
                    const Text(
                      '📋 Данные для МКК и маршрутной книжки:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.signalOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: currentP.fullName,
                      decoration: const InputDecoration(
                        labelText: 'ФИО полностью',
                        prefixIcon: Icon(Icons.badge_outlined),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(groupParticipantsProvider.notifier).updateParticipantMkkDetails(
                          id: p.id,
                          fullName: val.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: currentP.touristExperience,
                      decoration: const InputDecoration(
                        labelText: 'Туристский опыт (к.с., перевалы)',
                        prefixIcon: Icon(Icons.hiking_outlined),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(groupParticipantsProvider.notifier).updateParticipantMkkDetails(
                          id: p.id,
                          touristExperience: val.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: currentP.contactPhone,
                      decoration: const InputDecoration(
                        labelText: 'Телефон / Экстренный контакт',
                        prefixIcon: Icon(Icons.phone_outlined),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(groupParticipantsProvider.notifier).updateParticipantMkkDetails(
                          id: p.id,
                          contactPhone: val.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Применить анкету'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlannedRouteCard(
    BuildContext context,
    PlannedRoute? route,
    WidgetRef ref,
  ) {
    if (route == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () async {
            final imported = await GpxImportDialog.show(context);
            if (imported != null) {
              setState(() {
                _titleController.text = imported.name;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: OutdoorTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.signalOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alt_route, color: OutdoorTheme.signalOrange, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Загрузить GPX трек маршрута',
                        style: TextStyle(
                          color: OutdoorTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Авто-подстановка длины, высот и скачивание карты',
                        style: TextStyle(
                          color: OutdoorTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: OutdoorTheme.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OutdoorTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: OutdoorTheme.signalOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    style: const TextStyle(
                      color: OutdoorTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Сбросить плановый маршрут',
                  icon: const Icon(Icons.close, size: 18, color: OutdoorTheme.textSecondary),
                  onPressed: () {
                    ref.read(plannedRouteProvider.notifier).clearPlannedRoute();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${route.totalDistanceKm} км  •  +${route.totalAscentMeters.toInt()} м набора  •  ${route.points.length} точек',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => FractionallySizedBox(
                          heightFactor: 0.80,
                          child: OfflineMapsSheet(
                            currentCenter: route.points.isNotEmpty
                                ? LatLng(route.points.first.latitude, route.points.first.longitude)
                                : LatLng(44.0760, 39.9980),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OutdoorTheme.signalOrange,
                      side: const BorderSide(color: OutdoorTheme.signalOrange),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_for_offline, size: 16),
                    label: const Text('Скачать карту района', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Заменить GPX трек',
                  icon: const Icon(Icons.folder_open, color: OutdoorTheme.textSecondary, size: 20),
                  onPressed: () async {
                    final imported = await GpxImportDialog.show(context);
                    if (imported != null) {
                      setState(() {
                        _titleController.text = imported.name;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

