import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:survival_calc/features/gear/presentation/screens/gear_checklist_screen.dart';
import 'package:survival_calc/features/ration/presentation/screens/food_breakdown_screen.dart';
import 'package:survival_calc/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:survival_calc/features/trip_setup/presentation/screens/trip_setup_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
                  selectedIcon: Icon(Icons.tune, color: OutdoorTheme.signalOrange),
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
                  selectedIcon:
                      Icon(Icons.restaurant_menu, color: OutdoorTheme.signalOrange),
                  label: 'Раскладка',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_rtl),
                  selectedIcon:
                      Icon(Icons.checklist_rtl, color: OutdoorTheme.signalOrange),
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
