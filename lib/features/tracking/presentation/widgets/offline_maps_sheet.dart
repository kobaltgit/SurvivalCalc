import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/domain/services/offline_tile_downloader.dart';
import 'package:survival_calc/features/tracking/domain/services/tile_math_utils.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';

class OfflineMapsSheet extends ConsumerStatefulWidget {
  final LatLng currentCenter;

  const OfflineMapsSheet({
    super.key,
    required this.currentCenter,
  });

  @override
  ConsumerState<OfflineMapsSheet> createState() => _OfflineMapsSheetState();
}

class _OfflineMapsSheetState extends ConsumerState<OfflineMapsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _radiusKm = 10.0;
  double _corridorBufferKm = 2.5;

  OfflineTileDownloader? _downloader;
  StreamSubscription<DownloadProgress>? _sub;
  DownloadProgress? _currentProgress;
  bool _isDownloading = false;
  String? _downloadStatusText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startRadiusDownload() {
    final center = widget.currentCenter;
    const zoomLevels = [11, 12, 13, 14, 15];
    final tiles = TileMathUtils.getTilesForRadius(
      centerLat: center.latitude,
      centerLon: center.longitude,
      radiusKm: _radiusKm,
      zoomLevels: zoomLevels,
    );

    _startDownload(
      tiles,
      regionName: 'Район (${center.latitude.toStringAsFixed(2)}, ${center.longitude.toStringAsFixed(2)}) • ${_radiusKm.toInt()} км',
      centerLat: center.latitude,
      centerLon: center.longitude,
      radiusKm: _radiusKm,
    );
  }

  void _startCorridorDownload() {
    final plannedRoute = ref.read(plannedRouteProvider);
    if (plannedRoute == null || plannedRoute.points.isEmpty) return;

    const zoomLevels = [11, 12, 13, 14, 15];
    final tiles = TileMathUtils.getTilesForPolyline(
      points: plannedRoute.points,
      bufferKm: _corridorBufferKm,
      zoomLevels: zoomLevels,
    );

    _startDownload(
      tiles,
      regionName: 'Коридор: ${plannedRoute.name} (±${_corridorBufferKm.toStringAsFixed(1)} км)',
      centerLat: plannedRoute.points.first.latitude,
      centerLon: plannedRoute.points.first.longitude,
      radiusKm: _corridorBufferKm,
    );
  }

  void _startDownload(
    Set<TileCoord> tiles, {
    required String regionName,
    double? centerLat,
    double? centerLon,
    double? radiusKm,
  }) {
    _downloader?.cancel();
    _sub?.cancel();

    _downloader = OfflineTileDownloader();
    setState(() {
      _isDownloading = true;
      _currentProgress = DownloadProgress(downloaded: 0, total: tiles.length);
      _downloadStatusText = 'Загрузка тайлов...';
    });

    _sub = _downloader!
        .downloadTiles(
          tiles,
          regionName: regionName,
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: radiusKm,
        )
        .listen(
          (progress) {
            setState(() {
              _currentProgress = progress;
              if (progress.isDone) {
                _isDownloading = false;
                _downloadStatusText = 'Готово! Скачано ${progress.downloaded} тайлов.';
                ref.read(offlineRegionsProvider.notifier).refresh();
              } else if (progress.isCancelled) {
                _isDownloading = false;
                _downloadStatusText = 'Загрузка отменена.';
              }
            });
          },
          onError: (e) {
            setState(() {
              _isDownloading = false;
              _downloadStatusText = 'Ошибка загрузки: $e';
            });
          },
        );
  }

  void _cancelDownload() {
    _downloader?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadStatusText = 'Загрузка остановлена';
    });
  }

  @override
  Widget build(BuildContext context) {
    final plannedRoute = ref.watch(plannedRouteProvider);
    final savedRegions = ref.watch(offlineRegionsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.download_for_offline, color: OutdoorTheme.signalOrange, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Офлайн-карты',
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
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: OutdoorTheme.signalOrange,
            labelColor: OutdoorTheme.signalOrange,
            unselectedLabelColor: OutdoorTheme.textSecondary,
            tabs: const [
              Tab(text: 'По радиусу'),
              Tab(text: 'Вдоль трека'),
              Tab(text: 'Сохраненные'),
            ],
          ),

          // Downloading progress bar (if active)
          if (_isDownloading || _downloadStatusText != null)
            _buildDownloadProgressBanner(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRadiusTab(),
                _buildCorridorTab(plannedRoute),
                _buildSavedTab(savedRegions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgressBanner() {
    final progress = _currentProgress;
    final pct = progress?.percent ?? 0.0;
    final downloaded = progress?.downloaded ?? 0;
    final total = progress?.total ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OutdoorTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _downloadStatusText ?? 'Загрузка...',
                style: const TextStyle(
                  color: OutdoorTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isDownloading)
                Text(
                  '${(pct * 100).toInt()}% ($downloaded / $total)',
                  style: const TextStyle(
                    color: OutdoorTheme.signalOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? pct : null,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(OutdoorTheme.signalOrange),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _cancelDownload,
                icon: const Icon(Icons.cancel, size: 16, color: Colors.redAccent),
                label: const Text('Отменить', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadiusTab() {
    final center = widget.currentCenter;
    final tiles = TileMathUtils.getTilesForRadius(
      centerLat: center.latitude,
      centerLon: center.longitude,
      radiusKm: _radiusKm,
      zoomLevels: const [11, 12, 13, 14, 15],
    );
    final sizeMb = TileMathUtils.estimateSizeMb(tiles.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OutdoorTheme.darkBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Центр: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: OutdoorTheme.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Радиус района:', style: TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.w600)),
              Text('${_radiusKm.toInt()} км', style: const TextStyle(color: OutdoorTheme.signalOrange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            value: _radiusKm,
            min: 5.0,
            max: 50.0,
            divisions: 9,
            activeColor: OutdoorTheme.signalOrange,
            inactiveColor: Colors.white12,
            label: '${_radiusKm.toInt()} км',
            onChanged: _isDownloading ? null : (v) => setState(() => _radiusKm = v),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoMetric('Зумы', 'Z11 – Z15'),
                _buildInfoMetric('Тайлов', '${tiles.length} шт.'),
                _buildInfoMetric('Объем', '~$sizeMb МБ'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startRadiusDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: OutdoorTheme.signalOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download, fontWeight: FontWeight.bold),
              label: const Text('Скачать район в память', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorTab(PlannedRoute? plannedRoute) {
    if (plannedRoute == null || plannedRoute.points.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alt_route, size: 48, color: OutdoorTheme.textSecondary),
              const SizedBox(height: 12),
              const Text(
                'Плановый GPX-трек не загружен',
                style: TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Загрузите GPX-трек на экране «Параметры» или через кнопку импорта, чтобы скачать коридор карты вдоль маршрута.',
                textAlign: TextAlign.center,
                style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final tiles = TileMathUtils.getTilesForPolyline(
      points: plannedRoute.points,
      bufferKm: _corridorBufferKm,
      zoomLevels: const [11, 12, 13, 14, 15],
    );
    final sizeMb = TileMathUtils.estimateSizeMb(tiles.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OutdoorTheme.darkBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plannedRoute.name,
                  style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plannedRoute.totalDistanceKm} км • +${plannedRoute.totalAscentMeters.toInt()} м набора • ${plannedRoute.points.length} точек',
                  style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ширина буфера коридора:', style: TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.w600)),
              Text('±${_corridorBufferKm.toStringAsFixed(1)} км', style: const TextStyle(color: OutdoorTheme.signalOrange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            value: _corridorBufferKm,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            activeColor: OutdoorTheme.signalOrange,
            inactiveColor: Colors.white12,
            label: '±${_corridorBufferKm.toStringAsFixed(1)} км',
            onChanged: _isDownloading ? null : (v) => setState(() => _corridorBufferKm = v),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoMetric('Зумы', 'Z11 – Z15'),
                _buildInfoMetric('Тайлов', '${tiles.length} шт.'),
                _buildInfoMetric('Объем', '~$sizeMb МБ'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startCorridorDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: OutdoorTheme.signalOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download, fontWeight: FontWeight.bold),
              label: const Text('Скачать карту вдоль трека', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedTab(List<OfflineRegion> savedRegions) {
    if (savedRegions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_off, size: 48, color: OutdoorTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'Нет сохраненных офлайн-карт',
                style: TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Скачайте район по радиусу или вдоль трека, чтобы они появились здесь.',
                textAlign: TextAlign.center,
                style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сохранено районов: ${savedRegions.length}',
                style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: OutdoorTheme.surfaceCard,
                      title: const Text('Очистить весь кэш карт?'),
                      content: const Text('Все скачанные офлайн-тайлы будут удалены с устройства.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Отмена', style: TextStyle(color: OutdoorTheme.textSecondary)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Удалить всё', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(offlineRegionsProvider.notifier).clearAll();
                  }
                },
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                label: const Text('Очистить всё', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: savedRegions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final region = savedRegions[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OutdoorTheme.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: OutdoorTheme.signalOrange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region.name,
                            style: const TextStyle(
                              color: OutdoorTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${region.tileCount} тайлов • ${region.sizeMb} МБ',
                            style: const TextStyle(
                              color: OutdoorTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        ref.read(offlineRegionsProvider.notifier).deleteRegion(region.id);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMetric(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
