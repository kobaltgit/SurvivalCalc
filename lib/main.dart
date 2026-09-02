import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart';
import 'package:survival_calc/features/web/domain/services/web_url_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline tile repository path
  await OfflineTileRepository.init();

  if (!kIsWeb) {
    // Enable immersive sticky fullscreen mode (hides Android navigation bar and status bar)
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    // Set system navigation and status bar style to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Parse initial trip profile and participants from URL if opened with query parameters
  final initialUrlData =
      kIsWeb ? WebUrlService.parseDataFromUri(Uri.base) : null;

  runApp(
    ProviderScope(
      overrides: [
        if (initialUrlData != null) ...[
          activeTripProfileProvider.overrideWith(
            (ref) => TripProfileNotifier(
              ref.watch(tripRepositoryProvider),
              initialUrlData.profile,
            ),
          ),
          if (initialUrlData.participants.isNotEmpty)
            groupParticipantsProvider.overrideWith(
              (ref) => GroupParticipantsNotifier(
                ref.watch(loadDistributionServiceProvider),
              )..setParticipants(initialUrlData.participants),
            ),
        ],
      ],
      child: const SurvivalCalcApp(),
    ),
  );
}

class OutdoorScrollBehavior extends MaterialScrollBehavior {
  const OutdoorScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class SurvivalCalcApp extends StatelessWidget {
  const SurvivalCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SurvivalCalc — Офлайн калькулятор походного рациона и снаряжения',
      debugShowCheckedModeBanner: false,
      theme: OutdoorTheme.darkTheme,
      scrollBehavior: const OutdoorScrollBehavior(),
      home: const MainNavigationScreen(),
    );
  }
}
