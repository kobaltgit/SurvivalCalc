import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';

class GpxImportDialog extends ConsumerStatefulWidget {
  const GpxImportDialog({super.key});

  static Future<PlannedRoute?> show(BuildContext context) {
    return showDialog<PlannedRoute>(
      context: context,
      builder: (ctx) => const GpxImportDialog(),
    );
  }

  @override
  ConsumerState<GpxImportDialog> createState() => _GpxImportDialogState();
}

class _GpxImportDialogState extends ConsumerState<GpxImportDialog> {
  PlannedRoute? _previewRoute;
  bool _isLoading = false;
  String? _errorMessage;
  bool _autoApplyToProfile = true;

  Future<void> _pickGpxFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        final content = utf8.decode(bytes);

        if (content.isNotEmpty) {
          final route = await ref
              .read(plannedRouteProvider.notifier)
              .importFromGpx(content, defaultName: file.name.replaceAll('.gpx', ''));
          setState(() {
            _previewRoute = route;
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка чтения GPX файла: $e';
      });
    }
  }

  Future<void> _loadDemoRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await rootBundle.loadString('assets/data/demo_route_30.gpx');
      final route = await ref
          .read(plannedRouteProvider.notifier)
          .importFromGpx(content, defaultName: 'Легендарная Тридцатка (Лагонаки - Фишт)');
      setState(() {
        _previewRoute = route;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка загрузки демо-трека: $e';
      });
    }
  }

  void _applyAndFinish() {
    final route = _previewRoute;
    if (route == null) return;

    if (_autoApplyToProfile) {
      final curProfile = ref.read(activeTripProfileProvider);
      ref.read(activeTripProfileProvider.notifier).updateProfile(
        curProfile.copyWith(
          title: route.name,
          totalDistanceKm: route.totalDistanceKm,
          totalAscentMeters: route.totalAscentMeters,
        ),
      );
    }

    Navigator.pop(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.alt_route, color: OutdoorTheme.signalOrange, size: 24),
          SizedBox(width: 8),
          Text(
            'Импорт GPX трека',
            style: TextStyle(color: OutdoorTheme.textPrimary, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
                  ),
                )
              else if (_previewRoute != null)
                _buildRoutePreviewCard(_previewRoute!)
              else ...[
                const Text(
                  'Загрузите заранее подготовленный GPX трек маршрута (из Nakarte, Locus, Strava, AllTrails).',
                  style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickGpxFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OutdoorTheme.signalOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_open, fontWeight: FontWeight.bold),
                  label: const Text(
                    'Выбрать .GPX файл с устройства',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadDemoRoute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OutdoorTheme.signalOrange,
                    side: const BorderSide(color: OutdoorTheme.signalOrange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.terrain, size: 20),
                  label: const Text(
                    'Загрузить демо: «Маршрут №30 (Фишт)»',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть', style: TextStyle(color: OutdoorTheme.textSecondary)),
        ),
        if (_previewRoute != null)
          ElevatedButton(
            onPressed: _applyAndFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Применить маршрут', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildRoutePreviewCard(PlannedRoute route) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OutdoorTheme.darkBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.name,
                  style: const TextStyle(
                    color: OutdoorTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (route.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              route.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Дистанция', '${route.totalDistanceKm} км', Colors.cyanAccent),
                _buildStatItem('Набор высоты', '+${route.totalAscentMeters.toInt()} м', OutdoorTheme.signalOrange),
                _buildStatItem('Точек', '${route.points.length}', Colors.white70),
                _buildStatItem('Меток', '${route.waypoints.length}', Colors.amberAccent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: OutdoorTheme.signalOrange,
            title: const Text(
              'Подставить дистанцию и набор высоты в параметры похода',
              style: TextStyle(color: OutdoorTheme.textPrimary, fontSize: 12),
            ),
            value: _autoApplyToProfile,
            onChanged: (v) => setState(() => _autoApplyToProfile = v ?? true),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
