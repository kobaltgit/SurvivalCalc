import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';
import 'package:survival_calc/features/trip_setup/domain/models/planned_day_schedule.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class PlannedItineraryDialog extends ConsumerStatefulWidget {
  final TripProfile profile;

  const PlannedItineraryDialog({super.key, required this.profile});

  static Future<void> show(BuildContext context, TripProfile profile) {
    return showDialog(
      context: context,
      builder: (context) => PlannedItineraryDialog(profile: profile),
    );
  }

  @override
  ConsumerState<PlannedItineraryDialog> createState() => _PlannedItineraryDialogState();
}

class _PlannedItineraryDialogState extends ConsumerState<PlannedItineraryDialog> {
  late List<PlannedDaySchedule> _items;

  @override
  void initState() {
    super.initState();
    if (widget.profile.plannedItinerary.isNotEmpty) {
      _items = List.from(widget.profile.plannedItinerary);
    } else {
      final plannedRoute = ref.read(plannedRouteProvider);
      _items = PlannedDaySchedule.generateDefaultSchedule(
        profile: widget.profile,
        plannedRoute: plannedRoute,
        waypoints: plannedRoute?.waypoints ?? const [],
      );
    }
  }

  void _save() {
    ref.read(activeTripProfileProvider.notifier).updateMkkDetails(
          plannedItinerary: _items,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Dialog(
      backgroundColor: OutdoorTheme.darkBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OutdoorTheme.signalOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.route, color: OutdoorTheme.signalOrange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Заявленный график движения',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Раздел 3.1 Маршрутной книжки (ФСТР 2020)',
                            style: TextStyle(fontSize: 11, color: OutdoorTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: OutdoorTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: OutdoorTheme.borderSubtle),
              const SizedBox(height: 10),

              // List of Day Schedules
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final dateStr = item.date != null ? dateFormat.format(item.date!) : 'День ${item.dayNumber}';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OutdoorTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OutdoorTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'День ${item.dayNumber} • $dateStr',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: OutdoorTheme.signalOrange,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  initialValue: item.distanceKm.toStringAsFixed(1),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 12, color: OutdoorTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Км',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  ),
                                  onChanged: (val) {
                                    final km = double.tryParse(val.replaceAll(',', '.'));
                                    if (km != null) {
                                      _items[index] = item.copyWith(distanceKm: km);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: item.routeSection,
                            style: const TextStyle(fontSize: 13, color: OutdoorTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Участок маршрута (Откуда — Куда, ориентиры)',
                              isDense: true,
                              prefixIcon: Icon(Icons.place_outlined, size: 18),
                            ),
                            onChanged: (val) {
                              _items[index] = item.copyWith(routeSection: val.trim());
                            },
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: item.obstacles,
                            style: const TextStyle(fontSize: 12, color: OutdoorTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Препятствия, перевалы, ночевка',
                              isDense: true,
                              prefixIcon: Icon(Icons.terrain_outlined, size: 18),
                            ),
                            onChanged: (val) {
                              _items[index] = item.copyWith(obstacles: val.trim());
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Сохранить график маршрута'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OutdoorTheme.signalOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
