import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:survival_calc/features/gear/presentation/screens/gear_checklist_screen.dart';
import 'package:survival_calc/features/ration/presentation/screens/food_breakdown_screen.dart';
import 'package:survival_calc/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/trip_setup/presentation/screens/trip_setup_screen.dart';
import 'package:survival_calc/features/web/domain/services/browser_history_sync/browser_history_sync.dart';
import 'package:survival_calc/features/web/presentation/widgets/topographic_background.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_expandable_promo_banner.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_header.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_preset_chips.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_qr_sync_modal.dart';

class WebLandingScreen extends ConsumerStatefulWidget {
  const WebLandingScreen({super.key});

  @override
  ConsumerState<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends ConsumerState<WebLandingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeWebLoadingIndicator();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPresetSelected(TripProfile preset) {
    ref.read(activeTripProfileProvider.notifier).updateProfile(preset);
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeTripProfileProvider);
    final calcResult = ref.watch(calculationResultProvider);

    return Scaffold(
      backgroundColor: OutdoorTheme.darkBackground,
      body: TopographicBackground(
        opacity: 0.35,
        child: Column(
          children: [
            // Top Navigation Header
            const WebHeader(),

            // Expandable Showcase Promo Banner
            const WebExpandablePromoBanner(),

            // Presets & Quick Actions Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: OutdoorTheme.surfaceCard.withValues(alpha: 0.7),
                border: const Border(
                  bottom: BorderSide(
                    color: OutdoorTheme.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: WebPresetChips(
                      onPresetSelected: _onPresetSelected,
                      currentProfile: activeProfile,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => WebQrSyncModal.show(
                      context,
                      activeProfile,
                      participants: ref.read(groupParticipantsProvider),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OutdoorTheme.signalOrange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2, size: 20),
                    label: const Text(
                      'Перенести в телефон',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main 2-Column Split Workspace
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: Trip Setup Form (Width 440px)
                  Container(
                    width: 440,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: OutdoorTheme.borderSubtle,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      child: TripSetupScreen(
                        onCalculatePressed: () {
                          _tabController.animateTo(0);
                        },
                      ),
                    ),
                  ),

                  // Right Column: Interactive Results Workspace
                  Expanded(
                    child: Column(
                      children: [
                        // Right Column Tab Bar
                        Container(
                          color: OutdoorTheme.surfaceCard,
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: OutdoorTheme.signalOrange,
                            indicatorWeight: 3,
                            labelColor: OutdoorTheme.signalOrange,
                            unselectedLabelColor: OutdoorTheme.textSecondary,
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.analytics, size: 18),
                                text: 'Дашборд и БЖУ',
                              ),
                              Tab(
                                icon: Icon(Icons.restaurant_menu, size: 18),
                                text: 'Раскладка еды',
                              ),
                              Tab(
                                icon: Icon(Icons.checklist_rtl, size: 18),
                                text: 'Снаряжение',
                              ),
                              Tab(
                                icon: Icon(Icons.explore, size: 18),
                                text: 'GPS и Карты',
                              ),
                            ],
                          ),
                        ),

                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              DashboardScreen(
                                onGoToRation: () => _tabController.animateTo(1),
                                onGoToGear: () => _tabController.animateTo(2),
                              ),
                              const FoodBreakdownScreen(),
                              const GearChecklistScreen(),
                              const TrackingScreen(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Status & Stats Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: const BoxDecoration(
                color: OutdoorTheme.surfaceCard,
                border: Border(
                  top: BorderSide(color: OutdoorTheme.borderSubtle, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_pin,
                    color: OutdoorTheme.tacticalGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '100% Offline Engine • 57 продуктов питания • 66 предметов снаряжения',
                    style: TextStyle(
                      fontSize: 11,
                      color: OutdoorTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (calcResult != null) ...[
                    Text(
                      'Суточная норма: ${calcResult.targets.dailyCalories.round()} ккал/чел • Вес рюкзака: ${calcResult.startPackWeightPerPersonKg.toStringAsFixed(1)} кг',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.signalOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    '© SurvivalCalc',
                    style: TextStyle(
                      fontSize: 11,
                      color: OutdoorTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
