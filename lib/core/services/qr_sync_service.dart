import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/qr_scanner_dialog.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class QrSyncService {
  const QrSyncService();

  static const String _qrPrefix = 'SURVIVALCALC:';

  /// Encodes a TripProfile into a compressed base64 QR payload
  String encodeTripProfile(TripProfile profile) {
    final jsonStr = profile.toJson();
    final bytes = utf8.encode(jsonStr);
    final base64Str = base64Url.encode(bytes);
    return '$_qrPrefix$base64Str';
  }

  /// Decodes a QR code string or raw JSON back into a TripProfile
  TripProfile? decodeTripProfile(String payload) {
    final cleanPayload = payload.trim();
    if (cleanPayload.isEmpty) return null;

    try {
      if (cleanPayload.startsWith(_qrPrefix)) {
        final base64Str = cleanPayload.substring(_qrPrefix.length);
        final bytes = base64Url.decode(base64Str);
        final jsonStr = utf8.decode(bytes);
        return TripProfile.fromJson(jsonStr);
      } else if (cleanPayload.startsWith('{') && cleanPayload.endsWith('}')) {
        return TripProfile.fromJson(cleanPayload);
      }
    } catch (_) {}
    return null;
  }

  /// Shows the QR code modal dialog for sharing the active trip
  void showQrShareModal(BuildContext context, TripProfile profile) {
    final payload = encodeTripProfile(profile);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '📱 Офлайн QR-Код',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Сканируйте этот QR-код для моментальной синхронизации похода (100% без интернета).',
                  style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // QR Code Container with High-Contrast White Background
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: OutdoorTheme.signalOrange.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 200.0,
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
                ),
                const SizedBox(height: 16),

                // Trip Brief Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        profile.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: OutdoorTheme.signalOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.groupSize} чел. • ${profile.durationDays} дн. • ${profile.totalDistanceKm.toStringAsFixed(0)} км • +${profile.totalAscentMeters.toStringAsFixed(0)} м',
                        style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Copy Raw Sync Key Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: payload));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Текстовый ключ синхронизации скопирован'),
                          backgroundColor: OutdoorTheme.tacticalGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Скопировать ключ похода'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the Import modal dialog for receiving a trip via QR / Text Key
  void showQrImportModal(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    TripProfile? previewProfile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: OutdoorTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                      const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: OutdoorTheme.signalOrange, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Импорт похода',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Отсканируйте QR-код камерой или вставьте текстовый ключ синхронизации:',
                    style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // 1. Primary Live Camera Scanner Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFE65100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: OutdoorTheme.signalOrange.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final scanned = await QrScannerDialog.show(context);
                        if (scanned != null && scanned.isNotEmpty) {
                          textController.text = scanned;
                          final parsed = decodeTripProfile(scanned);
                          setModalState(() => previewProfile = parsed);
                          if (parsed == null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Не удалось распознать поход из QR-кода'),
                                backgroundColor: OutdoorTheme.alertRed,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 22),
                      label: const Text(
                        '📷 Сканировать QR камерой',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider with Text
                  Row(
                    children: [
                      const Expanded(child: Divider(color: OutdoorTheme.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ИЛИ ВВЕДИТЕ КЛЮЧ ВРУЧНУЮ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: OutdoorTheme.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: OutdoorTheme.borderSubtle)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: textController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Вставьте ключ SURVIVALCALC:...',
                      hintStyle: const TextStyle(fontSize: 12, color: OutdoorTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, color: OutdoorTheme.signalOrange),
                        tooltip: 'Вставить из буфера',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            textController.text = data!.text!;
                            final parsed = decodeTripProfile(data.text!);
                            setModalState(() => previewProfile = parsed);
                          }
                        },
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = decodeTripProfile(val);
                      setModalState(() => previewProfile = parsed);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Preview Card if successfully decoded
                  if (previewProfile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.15),
                        border: Border.all(color: OutdoorTheme.tacticalGreen),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: OutdoorTheme.tacticalGreen, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Поход: ${previewProfile!.title}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: OutdoorTheme.tacticalGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Дней: ${previewProfile!.durationDays} • Участников: ${previewProfile!.groupSize} • Дистанция: ${previewProfile!.totalDistanceKm.toStringAsFixed(0)} км • ${previewProfile!.season.displayNameRu}',
                            style: const TextStyle(
                                fontSize: 11, color: OutdoorTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: previewProfile == null
                        ? null
                        : () {
                            ref
                                .read(activeTripProfileProvider.notifier)
                                .updateProfile(previewProfile!);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Поход "${previewProfile!.title}" успешно загружен!'),
                                backgroundColor: OutdoorTheme.tacticalGreen,
                              ),
                            );
                          },
                    icon: const Icon(Icons.download_done),
                    label: const Text('Загрузить и применить поход'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
