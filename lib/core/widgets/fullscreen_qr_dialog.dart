import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';

class FullscreenQrDialog extends StatelessWidget {
  final String payload;
  final String title;
  final String subtitle;

  const FullscreenQrDialog({
    super.key,
    required this.payload,
    required this.title,
    required this.subtitle,
  });

  static void show(
    BuildContext context, {
    required String payload,
    required String title,
    required String subtitle,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => FullscreenQrDialog(
        payload: payload,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final qrSize = math.min(screenSize.width * 0.75, math.min(screenSize.height * 0.55, 420.0));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: OutdoorTheme.surfaceCardElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: OutdoorTheme.signalOrange, width: 2),
            boxShadow: [
              BoxShadow(
                color: OutdoorTheme.signalOrange.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.signalOrange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: OutdoorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: OutdoorTheme.textMuted, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Large QR Image Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: qrSize,
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
              const SizedBox(height: 18),

              // Instruction Hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: OutdoorTheme.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OutdoorTheme.borderSubtle),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: OutdoorTheme.signalOrange, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Наведите камеру смартфона для сканирования QR-кода',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: OutdoorTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OutdoorTheme.surfaceCard,
                    foregroundColor: OutdoorTheme.textPrimary,
                    side: const BorderSide(color: OutdoorTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.fullscreen_exit, size: 20),
                  label: const Text(
                    'Свернуть QR-код',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
