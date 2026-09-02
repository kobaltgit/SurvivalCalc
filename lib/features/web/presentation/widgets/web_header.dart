import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_apk_download_modal.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_qr_sync_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class WebHeader extends ConsumerWidget {
  const WebHeader({super.key});

  static const String githubRepoUrl =
      'https://github.com/kobaltgit/SurvivalCalc';

  Future<void> _openGithub() async {
    final uri = Uri.parse(githubRepoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeTripProfileProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: OutdoorTheme.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo & Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OutdoorTheme.signalOrange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: OutdoorTheme.signalOrange.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.terrain,
                  color: OutdoorTheme.signalOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SurvivalCalc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: OutdoorTheme.textPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.7),
                          ),
                        ),
                        child: const Text(
                          '100% OFFLINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.tacticalGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Калькулятор походного рациона и снаряжения',
                    style: TextStyle(
                      fontSize: 11,
                      color: OutdoorTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Action buttons
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => WebQrSyncModal.show(context, activeProfile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OutdoorTheme.signalOrange,
                  side: const BorderSide(color: OutdoorTheme.signalOrange),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text(
                  'Перенести в телефон',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => WebApkDownloadModal.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OutdoorTheme.signalOrange,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.android, size: 18),
                label: const Text(
                  'Скачать APK',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _openGithub,
                tooltip: 'Исходный код на GitHub',
                icon: const Icon(
                  Icons.code,
                  color: OutdoorTheme.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
