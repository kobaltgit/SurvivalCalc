import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:survival_calc/core/services/file_saver_service.dart';
import 'package:survival_calc/core/services/qr_sync_service.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_route_parser.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/web/domain/services/web_url_service.dart';

class WebQrSyncModal extends StatelessWidget {
  final TripProfile profile;
  final List<Participant> participants;
  final PlannedRoute? plannedRoute;

  const WebQrSyncModal({
    super.key,
    required this.profile,
    this.participants = const [],
    this.plannedRoute,
  });

  static void show(
    BuildContext context,
    TripProfile profile, {
    List<Participant> participants = const [],
    PlannedRoute? plannedRoute,
  }) {
    showDialog(
      context: context,
      builder: (context) => WebQrSyncModal(
        profile: profile,
        participants: participants,
        plannedRoute: plannedRoute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const qrService = QrSyncService();
    final qrPayload = qrService.encodeTripSnapshot(
      TripQrSnapshot(
        profile: profile,
        participants: participants,
      ),
    );
    final shareUrl = WebUrlService.buildShareUrl(
      profile,
      participants: participants,
      plannedRoute: plannedRoute,
    );

    return Dialog(
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        child: const Icon(
                          Icons.qr_code_2,
                          color: OutdoorTheme.signalOrange,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Перенос плана в телефон',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${profile.durationDays} дн. • ${profile.groupSize} чел. • ${profile.totalDistanceKm.toStringAsFixed(0)} км',
                            style: const TextStyle(
                              fontSize: 12,
                              color: OutdoorTheme.textSecondary,
                            ),
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
              const SizedBox(height: 16),

              // Crisp QR Code
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F1216),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F1216),
                  ),
                ),
              ),

              // Dedicated GPX Track Download Block
              if (plannedRoute != null)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route,
                            color: OutdoorTheme.tacticalGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plannedRoute!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: OutdoorTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${plannedRoute!.totalDistanceKm.toStringAsFixed(1)} км • +${plannedRoute!.totalAscentMeters.toStringAsFixed(0)} м • ${plannedRoute!.points.length} точек',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: OutdoorTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final gpxXml = GpxRouteParser.toGpx(plannedRoute!);
                            final cleanName = plannedRoute!.name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
                            final filename = '$cleanName.gpx';
                            await FileSaverService.saveAndShareFile(
                              bytes: utf8.encode(gpxXml),
                              filename: filename,
                              mimeType: 'application/gpx+xml',
                              subject: 'GPX Маршрут: ${plannedRoute!.name}',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🗺️ Файл маршрута "$filename" скачан / отправлен!'),
                                  backgroundColor: OutdoorTheme.tacticalGreen,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OutdoorTheme.tacticalGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text(
                            'Скачать GPX трек маршрута',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OutdoorTheme.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OutdoorTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.smartphone,
                          size: 16,
                          color: OutdoorTheme.signalOrange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Как перенести поход в приложение:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStepRow(
                      '1',
                      'Наведите камеру смартфона из SurvivalCalc на этот QR-код — состав группы и раскладка загрузятся мгновенно.',
                    ),
                    if (plannedRoute != null)
                      _buildStepRow(
                        '2',
                        'Файл GPX скачайте кнопкой выше и отправьте участникам (через Telegram/Bluetooth) для открытия в приложении или навигаторе.',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: qrPayload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Снимок QR скопирован в буфер!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OutdoorTheme.textPrimary,
                        side: const BorderSide(color: OutdoorTheme.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text(
                        'Копировать ключ QR',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ссылка на поход скопирована!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OutdoorTheme.signalOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text(
                        'Скопировать ссылку',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildStepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: OutdoorTheme.signalOrange,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: OutdoorTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
