import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/utils/external_links.dart';

class WebApkDownloadModal extends StatelessWidget {
  const WebApkDownloadModal({super.key});

  static const String apkDownloadUrl = ExternalLinks.apkRelease;

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WebApkDownloadModal(),
    );
  }

  Future<void> _launchDownloadUrl() => ExternalLinks.openApkDownload();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
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
                          Icons.android,
                          color: OutdoorTheme.signalOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Скачать приложение',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Android APK • Версия 1.0 (Офлайн)',
                            style: TextStyle(
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
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
                  data: apkDownloadUrl,
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
              const SizedBox(height: 14),
              const Text(
                'Отсканируйте камерой телефона для быстрой загрузки',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: OutdoorTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OutdoorTheme.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OutdoorTheme.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      color: OutdoorTheme.tacticalGreen,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% автономная работа без интернета, топографические карты, GPS-трекинг и расчет раскладки.',
                        style: TextStyle(
                          fontSize: 11,
                          color: OutdoorTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _launchDownloadUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OutdoorTheme.signalOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text(
                    'Скачать APK файл напрямую',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: ExternalLinks.openTelegram,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2CA5E0),
                    side: const BorderSide(color: Color(0xFF2CA5E0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Telegram-канал: @survivalcalc',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
