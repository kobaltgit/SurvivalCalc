import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/add_waypoint_dialog.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/camp_debrief_sheet.dart';
import 'package:survival_calc/features/tracking/presentation/widgets/track_history_sheet.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final MapController _mapController = MapController();
  bool _followUser = true;

  // Default initial center (generic coordinate before GPS fix)
  LatLng _lastCenter = const LatLng(43.3550, 42.4392);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialLocation();
    });
  }

  Future<void> _requestInitialLocation() async {
    final pt =
        await ref.read(trackingProvider.notifier).fetchInitialLocation();
    if (pt != null && mounted) {
      final target = LatLng(pt.latitude, pt.longitude);
      setState(() {
        _lastCenter = target;
        _followUser = true;
      });
      _mapController.move(target, 15.0);
    }
  }

  Future<void> _centerOnUser() async {
    final curPt = ref.read(trackingProvider).currentPoint;
    if (curPt != null) {
      final target = LatLng(curPt.latitude, curPt.longitude);
      setState(() {
        _lastCenter = target;
        _followUser = true;
      });
      _mapController.move(target, 16.0);
    } else {
      await _requestInitialLocation();
    }
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _openAddWaypointDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddWaypointDialog(
        onAdd: (title, type, note) {
          ref.read(trackingProvider.notifier).addWaypoint(
                title: title,
                type: type,
                note: note,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Метка "$title" добавлена на карту'),
              backgroundColor: OutdoorTheme.signalOrange,
            ),
          );
        },
      ),
    );
  }

  void _finishDay(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cabin, color: OutdoorTheme.signalOrange),
            SizedBox(width: 10),
            Text(
              'Завершить ходовой день?',
              style: TextStyle(
                color: OutdoorTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Запись трека будет остановлена, данные сохранены в дневник похода и сформирован вечерний метаболический отчет.',
          style: TextStyle(color: OutdoorTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: OutdoorTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
            ),
            child: const Text('Завершить день', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final activeTrack = ref.read(trackingProvider).activeTrack;
      final debrief =
          await ref.read(trackingProvider.notifier).stopAndFinishDay();

      if (context.mounted && debrief != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => FractionallySizedBox(
            heightFactor: 0.90,
            child: CampDebriefSheet(
              debrief: debrief,
              track: activeTrack,
            ),
          ),
        );
      }
    }
  }

  void _openTrackHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const FractionallySizedBox(
        heightFactor: 0.75,
        child: TrackHistorySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final track = state.activeTrack;
    final curPt = state.currentPoint;

    // Center map on live location if following
    if (curPt != null) {
      _lastCenter = LatLng(curPt.latitude, curPt.longitude);
      if (_followUser) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_lastCenter, _mapController.camera.zoom);
        });
      }
    }

    final List<LatLng> polylinePoints = track != null
        ? track.points.map((p) => LatLng(p.latitude, p.longitude)).toList()
        : [];

    return Scaffold(
      backgroundColor: OutdoorTheme.darkBackground,
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lastCenter,
              initialZoom: 15.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() {
                    _followUser = false;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.survivalcalc.app',
              ),
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.5,
                      color: OutdoorTheme.signalOrange,
                    ),
                  ],
                ),
              // Waypoint Markers
              if (track != null && track.waypoints.isNotEmpty)
                MarkerLayer(
                  markers: track.waypoints.map((wp) {
                    return Marker(
                      point: LatLng(wp.latitude, wp.longitude),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getWaypointColor(wp.type),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          _getWaypointIcon(wp.type),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // Current User Marker
              if (curPt != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(curPt.latitude, curPt.longitude),
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: OutdoorTheme.signalOrange.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: OutdoorTheme.signalOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 2. Top HUD Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildHudHeader(state),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Map Utility Floating Buttons
          PositionBar(
            onCenter: _centerOnUser,
            isFollowing: _followUser,
            onZoomIn: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            onZoomOut: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            onHistory: () => _openTrackHistory(context),
          ),

          // 4. Bottom Control Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildBottomControls(state, context),
          ),
        ],
      ),
    );
  }

  Widget _buildHudHeader(TrackingState state) {
    final track = state.activeTrack;
    final double dist = track?.totalDistanceKm ?? 0.0;
    final double ascent = track?.elevationGainMeters ?? 0.0;
    final double altitude = state.currentPoint?.altitude ?? 0.0;
    final double speed = state.liveSpeedKmh;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: state.isRecording
                          ? Colors.greenAccent
                          : (state.isPaused ? Colors.amber : Colors.grey),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.isRecording
                        ? 'ЗАПИСЬ ТРЕКА'
                        : (state.isPaused ? 'ПАУЗА' : 'ГОТОВ К СТАРТУ'),
                    style: const TextStyle(
                      color: OutdoorTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDuration(state.movingSeconds),
                style: const TextStyle(
                  color: OutdoorTheme.signalOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHudStat('Дистанция', '${dist.toStringAsFixed(1)} км', Icons.straighten),
              _buildHudStat('Скорость', '${speed.toStringAsFixed(1)} км/ч', Icons.speed),
              _buildHudStat('Высота', '${altitude.toStringAsFixed(0)} м', Icons.terrain),
              _buildHudStat('Набор', '+${ascent.toStringAsFixed(0)} м', Icons.arrow_upward),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: OutdoorTheme.textMuted, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: OutdoorTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(TrackingState state, BuildContext context) {
    if (!state.isActive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              ref.read(trackingProvider.notifier).startTracking();
            },
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'НАЧАТЬ ХОДОВОЙ ДЕНЬ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(trackingProvider.notifier).startSimulation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🧪 Включена симуляция движения по маршруту (5 км/ч)'),
                  backgroundColor: OutdoorTheme.signalOrange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.directions_walk, size: 20, color: OutdoorTheme.signalOrange),
            label: const Text(
              '🧪 Симуляция похода (Тест)',
              style: TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: OutdoorTheme.surfaceCard.withValues(alpha: 0.9),
              side: const BorderSide(color: OutdoorTheme.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Pause / Resume Button
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () {
              if (state.isRecording) {
                ref.read(trackingProvider.notifier).pauseTracking();
              } else {
                ref.read(trackingProvider.notifier).resumeTracking();
              }
            },
            icon: Icon(
              state.isRecording ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
            ),
            label: Text(
              state.isRecording ? 'Пауза' : 'Продолжить',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isRecording ? Colors.amber : Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Add Landmark / Waypoint Button
        IconButton.filled(
          onPressed: () => _openAddWaypointDialog(context),
          icon: const Icon(Icons.add_location_alt, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: OutdoorTheme.surfaceCard,
            padding: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: OutdoorTheme.borderSubtle),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Finish Day Button
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: () => _finishDay(context),
            icon: const Icon(Icons.cabin, color: Colors.black),
            label: const Text(
              'Лагерь',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Color _getWaypointColor(WayPointType type) {
    switch (type) {
      case WayPointType.water:
        return Colors.blue;
      case WayPointType.camp:
        return OutdoorTheme.signalOrange;
      case WayPointType.pass:
        return Colors.purple;
      case WayPointType.obstacle:
        return Colors.red;
      case WayPointType.viewpoint:
        return Colors.teal;
      case WayPointType.other:
        return Colors.grey;
    }
  }

  IconData _getWaypointIcon(WayPointType type) {
    switch (type) {
      case WayPointType.water:
        return Icons.water_drop;
      case WayPointType.camp:
        return Icons.cabin;
      case WayPointType.pass:
        return Icons.landscape;
      case WayPointType.obstacle:
        return Icons.warning;
      case WayPointType.viewpoint:
        return Icons.photo_camera;
      case WayPointType.other:
        return Icons.location_on;
    }
  }
}

class PositionBar extends StatelessWidget {
  final VoidCallback onCenter;
  final bool isFollowing;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onHistory;

  const PositionBar({
    super.key,
    required this.onCenter,
    required this.isFollowing,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 140,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'center_user',
            backgroundColor: isFollowing
                ? OutdoorTheme.signalOrange
                : OutdoorTheme.surfaceCard,
            foregroundColor: isFollowing ? Colors.black : Colors.white,
            onPressed: onCenter,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            backgroundColor: OutdoorTheme.surfaceCard,
            foregroundColor: Colors.white,
            onPressed: onZoomIn,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            backgroundColor: OutdoorTheme.surfaceCard,
            foregroundColor: Colors.white,
            onPressed: onZoomOut,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'track_history',
            backgroundColor: OutdoorTheme.surfaceCard,
            foregroundColor: OutdoorTheme.signalOrange,
            onPressed: onHistory,
            child: const Icon(Icons.history),
          ),
        ],
      ),
    );
  }
}
