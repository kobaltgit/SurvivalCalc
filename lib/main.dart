import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline tile repository path
  await OfflineTileRepository.init();

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

  runApp(
    const ProviderScope(
      child: SurvivalCalcApp(),
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
      title: 'SurvivalCalc',
      debugShowCheckedModeBanner: false,
      theme: OutdoorTheme.darkTheme,
      scrollBehavior: const OutdoorScrollBehavior(),
      home: const MainNavigationScreen(),
    );
  }
}
