import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:survival_calc/features/gear/presentation/screens/gear_checklist_screen.dart';
import 'package:survival_calc/features/ration/presentation/screens/food_breakdown_screen.dart';
import 'package:survival_calc/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:survival_calc/features/trip_setup/presentation/screens/trip_setup_screen.dart';
import 'package:survival_calc/features/web/domain/services/browser_history_sync/browser_history_sync.dart';
import 'package:survival_calc/features/web/domain/services/web_url_service.dart';
import 'package:survival_calc/features/web/presentation/screens/web_landing_screen.dart';
import 'package:survival_calc/features/web/presentation/widgets/topographic_background.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_apk_download_modal.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _hideWebBanner = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removeWebLoadingIndicator();
      });
    }
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      ref.listen(activeTripProfileProvider, (prev, next) {
        final participants = ref.read(groupParticipantsProvider);
        WebUrlService.syncCurrentStateToBrowserUrl(next, participants);
      });
      ref.listen(groupParticipantsProvider, (prev, next) {
        final profile = ref.read(activeTripProfileProvider);
        WebUrlService.syncCurrentStateToBrowserUrl(profile, next);
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Wide desktop web layout
    if (screenWidth >= 900) {
      return const WebLandingScreen();
    }

    final screens = [
      TripSetupScreen(onCalculatePressed: () => _switchTab(1)),
      DashboardScreen(
        onGoToRation: () => _switchTab(3),
        onGoToGear: () => _switchTab(4),
      ),
      const TrackingScreen(),
      const FoodBreakdownScreen(),
      const GearChecklistScreen(),
    ];

    return Scaffold(
      body: TopographicBackground(
        opacity: 0.15,
        child: Column(
          children: [
            // Mobile Web promotion banner (only on Web when banner not dismissed)
            if (kIsWeb && !_hideWebBanner)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: OutdoorTheme.surfaceCardElevated,
                  border: const Border(
                    bottom:
                        BorderSide(color: OutdoorTheme.signalOrange, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.android,
                      size: 18,
                      color: OutdoorTheme.signalOrange,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Доступно офлайн-приложение Android',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => WebApkDownloadModal.show(context),
                      style: TextButton.styleFrom(
                        foregroundColor: OutdoorTheme.signalOrange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Скачать APK',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 14, color: OutdoorTheme.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _hideWebBanner = true),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: OutdoorTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: OutdoorTheme.borderSubtle.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.transparent,
              selectedIndex: _currentIndex,
              onDestinationSelected: _switchTab,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.tune),
                  selectedIcon:
                      Icon(Icons.tune, color: OutdoorTheme.signalOrange),
                  label: 'Параметры',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon:
                      Icon(Icons.analytics, color: OutdoorTheme.signalOrange),
                  label: 'Дашборд',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon:
                      Icon(Icons.explore, color: OutdoorTheme.signalOrange),
                  label: 'В пути',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu),
                  selectedIcon: Icon(Icons.restaurant_menu,
                      color: OutdoorTheme.signalOrange),
                  label: 'Раскладка',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_rtl),
                  selectedIcon: Icon(Icons.checklist_rtl,
                      color: OutdoorTheme.signalOrange),
                  label: 'Снаряжение',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
