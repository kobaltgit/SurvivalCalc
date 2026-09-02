import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:survival_calc/core/services/media_storage_service.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';

class WaypointDetailsSheet extends StatelessWidget {
  final WayPoint waypoint;
  final VoidCallback? onDelete;

  const WaypointDetailsSheet({
    super.key,
    required this.waypoint,
    this.onDelete,
  });

  static void show(BuildContext context, WayPoint wp, {VoidCallback? onDelete}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => WaypointDetailsSheet(
        waypoint: wp,
        onDelete: onDelete,
      ),
    );
  }

  void _showFullscreenPhoto(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = waypoint;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: OutdoorTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Icon, Title and Type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OutdoorTheme.signalOrange),
                ),
                child: Icon(
                  wp.photoPath != null ? Icons.photo_camera : Icons.location_on,
                  color: OutdoorTheme.signalOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wp.title,
                      style: const TextStyle(
                        color: OutdoorTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wp.type.displayNameRu,
                      style: const TextStyle(
                        color: OutdoorTheme.signalOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: OutdoorTheme.alertRed),
                  tooltip: 'Удалить метку',
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Metadata row (Elevation, LatLng, Time)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OutdoorTheme.surfaceCardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Высота', '${wp.altitude.toStringAsFixed(0)} м', Icons.terrain),
                _buildStat(
                  'Координаты',
                  '${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)}',
                  Icons.gps_fixed,
                ),
                _buildStat(
                  'Время',
                  '${wp.timestamp.hour.toString().padLeft(2, '0')}:${wp.timestamp.minute.toString().padLeft(2, '0')}',
                  Icons.access_time,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Author attribution badge
          if (wp.authorName != null) ...[
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: OutdoorTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Автор: ${wp.authorName!} ${wp.authorRole != null ? '(${wp.authorRole!.badgeTitle})' : ''}',
                  style: const TextStyle(
                    color: OutdoorTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Note text if present
          if (wp.note != null && wp.note!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OutdoorTheme.surfaceCardElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OutdoorTheme.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 18, color: OutdoorTheme.signalOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wp.note!,
                      style: const TextStyle(
                        color: OutdoorTheme.textPrimary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Photo preview card if present
          if (wp.photoPath != null) ...[
            FutureBuilder<Uint8List?>(
              future: MediaStorageService.getImageBytes(wp.photoPath!),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
                  );
                }
                final bytes = snapshot.data;
                if (bytes == null) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                  onTap: () => _showFullscreenPhoto(context, bytes),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.4)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.memory(
                          bytes,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Нажмите для зума',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // Close button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: OutdoorTheme.signalOrange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Закрыть', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: OutdoorTheme.signalOrange),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: OutdoorTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: OutdoorTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
