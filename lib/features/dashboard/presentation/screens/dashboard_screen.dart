import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/app_logo.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/group_distribution/presentation/screens/load_distribution_screen.dart';
import 'package:survival_calc/features/trip_storage/presentation/widgets/save_trip_dialog.dart';
import 'package:survival_calc/features/trip_storage/presentation/widgets/trip_library_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onGoToRation;
  final VoidCallback? onGoToGear;

  const DashboardScreen({
    super.key,
    this.onGoToRation,
    this.onGoToGear,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedPieTab = 0; // 0: Рюкзак, 1: БЖУ, 2: Категории снаряжения
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(calculationResultProvider);
    final exportService = ref.watch(exportServiceProvider);

    if (result == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(height: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.profile.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Сохранить поход / шаблон',
            icon: const Icon(Icons.save_outlined, color: OutdoorTheme.signalOrange),
            onPressed: () {
              SaveTripDialog.show(context);
            },
          ),
          IconButton(
            tooltip: 'Мои походы и шаблоны',
            icon: const Icon(Icons.folder_special_outlined, color: OutdoorTheme.signalOrange),
            onPressed: () {
              TripLibrarySheet.show(context);
            },
          ),
          IconButton(
            tooltip: 'Кто что несёт',
            icon: const Icon(Icons.people_alt_outlined, color: OutdoorTheme.electricCyan),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoadDistributionScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Экспорт и обмен',
            icon: const Icon(Icons.more_vert, color: OutdoorTheme.signalOrange),
            onSelected: (val) async {
              if (val == 'share_qr') {
                ref.read(qrSyncServiceProvider).showQrShareModal(context, result.profile);
              } else if (val == 'copy_report') {
                await exportService.copyToClipboard(result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Отчет и раскладка скопированы в буфер обмена'),
                      backgroundColor: OutdoorTheme.tacticalGreen,
                    ),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'share_qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2, size: 18, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text('Поделиться по QR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_report',
                child: Row(
                  children: [
                    Icon(Icons.copy_all, size: 18, color: OutdoorTheme.signalOrange),
                    SizedBox(width: 8),
                    Text('Копировать отчет'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Weight Card
              _buildHeroWeightCard(context, result),

              // 2. Weight Breakdown Mini-Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        title: 'Личное снаряжение',
                        value: '${result.totalPersonalGearWeightKg.toStringAsFixed(2)} кг',
                        subtitle: 'в рюкзаке',
                        icon: Icons.person_outline,
                        iconColor: OutdoorTheme.electricCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStatCard(
                        title: 'Групповое на чел.',
                        value: '${result.groupGearWeightPerPersonKg.toStringAsFixed(2)} кг',
                        subtitle: 'всего: ${result.totalGroupGearWeightKg.toStringAsFixed(1)} кг',
                        icon: Icons.group_outlined,
                        iconColor: OutdoorTheme.signalAmber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        title: 'Рацион на человека',
                        value: '${result.totalFoodWeightPerPersonKg.toStringAsFixed(2)} кг',
                        subtitle: '${(result.foodWeightPerPersonPerDayKg * 1000).toInt()} г/день',
                        icon: Icons.restaurant_outlined,
                        iconColor: OutdoorTheme.signalOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStatCard(
                        title: 'Вся еда на группу',
                        value: '${result.totalFoodWeightAllGroupKg.toStringAsFixed(1)} кг',
                        subtitle: '${result.profile.groupSize} чел. • ${result.profile.durationDays} дн.',
                        icon: Icons.shopping_basket_outlined,
                        iconColor: OutdoorTheme.tacticalGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Interactive Pie Chart Breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildPieChartCard(result),
              ),
              const SizedBox(height: 12),

              // 4. Weight Decay Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildWeightDecayChartCard(result),
              ),
              const SizedBox(height: 12),

              // 5. Daily Calories & Macro Target Bars
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildNutrientCard(result),
              ),
              const SizedBox(height: 12),

              // 6. Water, Electrolytes & Fuel Essentials
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _buildDailyEssentialsCard(result),
              ),
              const SizedBox(height: 16),

              // 7. Navigation Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onGoToRation,
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('К раскладке'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onGoToGear,
                        icon: const Icon(Icons.checklist),
                        label: const Text('К снаряжению'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 8. Group Load Distribution Banner (if group > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoadDistributionScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OutdoorTheme.surfaceCardElevated,
                      border: Border.all(
                        color: OutdoorTheme.electricCyan.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: OutdoorTheme.electricCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people_alt,
                            color: OutdoorTheme.electricCyan,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Модуль «Кто что несёт»',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: OutdoorTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Развесовка снаряжения и еды по ${result.profile.groupSize} участникам',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: OutdoorTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: OutdoorTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroWeightCard(
      BuildContext context, TripCalculationResult result) {
    return Card(
      color: OutdoorTheme.surfaceCardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'СТАРТОВЫЙ ВЕС РЮКЗАКА',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'на одного участника на старте',
                      style: TextStyle(
                        fontSize: 11,
                        color: OutdoorTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.profile.season.displayNameRu.split(' ')[0],
                    style: const TextStyle(
                      color: OutdoorTheme.signalOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  result.startPackWeightPerPersonKg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: OutdoorTheme.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'кг',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.signalOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Снаряжение: ${result.totalGearWeightPerPersonKg.toStringAsFixed(1)} кг • Еда: ${result.totalFoodWeightPerPersonKg.toStringAsFixed(1)} кг • Вода: 1.5 кг',
              style: const TextStyle(
                fontSize: 12,
                color: OutdoorTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OutdoorTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: iconColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: OutdoorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: OutdoorTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PIE CHART SECTION ---

  Widget _buildPieChartCard(TripCalculationResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '🍩 Круговые диаграммы развесовки',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OutdoorTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.pie_chart_outline, color: OutdoorTheme.signalOrange, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip(
                    label: '🎒 Рюкзак',
                    isSelected: _selectedPieTab == 0,
                    onTap: () => setState(() { _selectedPieTab = 0; _touchedIndex = -1; }),
                  ),
                  _buildTabChip(
                    label: '🥩 БЖУ',
                    isSelected: _selectedPieTab == 1,
                    onTap: () => setState(() { _selectedPieTab = 1; _touchedIndex = -1; }),
                  ),
                  _buildTabChip(
                    label: '⛺ Снаряжение',
                    isSelected: _selectedPieTab == 2,
                    onTap: () => setState(() { _selectedPieTab = 2; _touchedIndex = -1; }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedPieTab == 0)
              _buildPackWeightPieChart(result)
            else if (_selectedPieTab == 1)
              _buildMacroNutrientPieChart(result)
            else
              _buildGearCategoriesPieChart(result),
          ],
        ),
      ),
    );
  }

  Widget _buildPackWeightPieChart(TripCalculationResult result) {
    final personalKg = result.totalPersonalGearWeightKg;
    final groupKg = result.groupGearWeightPerPersonKg;
    final foodKg = result.totalFoodWeightPerPersonKg;
    const waterKg = 1.5;
    final totalKg = personalKg + groupKg + foodKg + waterKg;

    final data = [
      _PieSegmentData('Личное снаряжение', personalKg, OutdoorTheme.electricCyan, '${personalKg.toStringAsFixed(1)} кг'),
      _PieSegmentData('Групповое (доля)', groupKg, OutdoorTheme.signalAmber, '${groupKg.toStringAsFixed(1)} кг'),
      _PieSegmentData('Рацион (еда)', foodKg, OutdoorTheme.signalOrange, '${foodKg.toStringAsFixed(1)} кг'),
      _PieSegmentData('Носимая вода', waterKg, OutdoorTheme.tacticalGreen, '$waterKg кг'),
    ];

    return _renderPieWithLegend(
      data: data,
      totalValue: totalKg,
      centerTitle: '${totalKg.toStringAsFixed(1)} кг',
      centerSubtitle: 'Стартовый вес',
    );
  }

  Widget _buildMacroNutrientPieChart(TripCalculationResult result) {
    final t = result.targets;
    final proteinCal = t.dailyProteinG * 4.0;
    final fatCal = t.dailyFatG * 9.0;
    final carbsCal = t.dailyCarbsG * 4.0;
    final totalCal = proteinCal + fatCal + carbsCal;

    final data = [
      _PieSegmentData('Белки (${t.dailyProteinG.toInt()}г)', proteinCal, OutdoorTheme.electricCyan, '${t.proteinCalPercent.toInt()}%'),
      _PieSegmentData('Жиры (${t.dailyFatG.toInt()}г)', fatCal, OutdoorTheme.signalAmber, '${t.fatCalPercent.toInt()}%'),
      _PieSegmentData('Углеводы (${t.dailyCarbsG.toInt()}г)', carbsCal, OutdoorTheme.tacticalGreen, '${t.carbsCalPercent.toInt()}%'),
    ];

    return _renderPieWithLegend(
      data: data,
      totalValue: totalCal,
      centerTitle: '${totalCal.toInt()} ккал',
      centerSubtitle: 'Суточный баланс',
    );
  }

  Widget _buildGearCategoriesPieChart(TripCalculationResult result) {
    final catWeights = <GearCategory, int>{};
    for (final item in result.gearList) {
      catWeights[item.category] = (catWeights[item.category] ?? 0) + item.totalWeightG;
    }

    final totalG = catWeights.values.fold<int>(0, (sum, g) => sum + g);
    final colors = [
      OutdoorTheme.signalOrange,
      OutdoorTheme.electricCyan,
      OutdoorTheme.signalAmber,
      OutdoorTheme.tacticalGreen,
      OutdoorTheme.alertRed,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.indigoAccent,
    ];

    int colorIdx = 0;
    final data = <_PieSegmentData>[];
    catWeights.forEach((cat, grams) {
      if (grams > 0) {
        final kg = grams / 1000.0;
        final color = colors[colorIdx % colors.length];
        colorIdx++;
        data.add(_PieSegmentData(
          cat.displayNameRu,
          grams.toDouble(),
          color,
          '${kg.toStringAsFixed(1)} кг',
        ));
      }
    });

    return _renderPieWithLegend(
      data: data,
      totalValue: totalG.toDouble(),
      centerTitle: '${(totalG / 1000.0).toStringAsFixed(1)} кг',
      centerSubtitle: 'Весь экип',
    );
  }

  Widget _renderPieWithLegend({
    required List<_PieSegmentData> data,
    required double totalValue,
    required String centerTitle,
    required String centerSubtitle,
  }) {
    if (totalValue <= 0) {
      return const Center(child: Text('Нет данных'));
    }

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 42,
                  sections: List.generate(data.length, (i) {
                    final item = data[i];
                    final isTouched = i == _touchedIndex;
                    final radius = isTouched ? 48.0 : 40.0;
                    final pct = (item.value / totalValue) * 100.0;

                    return PieChartSectionData(
                      color: item.color,
                      value: item.value,
                      title: pct >= 8.0 ? '${pct.toInt()}%' : '',
                      radius: radius,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OutdoorTheme.textPrimary,
                    ),
                  ),
                  Text(
                    centerSubtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: OutdoorTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Legend Rows
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: data.map((item) {
            final pct = (item.value / totalValue) * 100.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${item.label}: ',
                  style: const TextStyle(fontSize: 11, color: OutdoorTheme.textSecondary),
                ),
                Text(
                  '${item.formattedValue} (${pct.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeightDecayChartCard(TripCalculationResult result) {
    final weights = result.dailyPackWeightsPerPersonKg;
    final spots = <FlSpot>[];
    for (int i = 0; i < weights.length; i++) {
      spots.add(FlSpot(i.toDouble(), weights[i]));
    }

    final double minY = (result.totalGearWeightPerPersonKg - 1.0).clamp(0.0, 100.0);
    final double maxY = result.startPackWeightPerPersonKg + 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '📉 Таяние веса рюкзака по дням',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OutdoorTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.trending_down, color: OutdoorTheme.signalOrange, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Динамика облегчения рюкзака по мере съедания рациона (в кг)',
              style: TextStyle(fontSize: 11, color: OutdoorTheme.textMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: OutdoorTheme.borderSubtle,
                      strokeWidth: 0.8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (val, meta) {
                          final day = val.toInt();
                          if (day == 0) return const Text('Старт', style: TextStyle(fontSize: 10, color: OutdoorTheme.textMuted));
                          if (day == weights.length - 1) return Text('Д${result.profile.durationDays}', style: const TextStyle(fontSize: 10, color: OutdoorTheme.textMuted));
                          return Text('Д$day', style: const TextStyle(fontSize: 10, color: OutdoorTheme.textMuted));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            '${val.toInt()}к',
                            style: const TextStyle(
                              fontSize: 10,
                              color: OutdoorTheme.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: OutdoorTheme.signalOrange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: OutdoorTheme.signalOrange.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(TripCalculationResult result) {
    final t = result.targets;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚡ Суточный калораж и БЖУ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.textPrimary,
                  ),
                ),
                Text(
                  '${t.dailyCalories.toInt()} ккал',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.signalOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildMacroBar('Белки (1.6-2.0 г/кг)', '${t.dailyProteinG.toStringAsFixed(0)} г',
                '${t.proteinCalPercent.toStringAsFixed(0)}%', t.proteinCalPercent / 100.0, OutdoorTheme.electricCyan),
            const SizedBox(height: 10),
            _buildMacroBar('Жиры (30-40%)', '${t.dailyFatG.toStringAsFixed(0)} г',
                '${t.fatCalPercent.toStringAsFixed(0)}%', t.fatCalPercent / 100.0, OutdoorTheme.signalAmber),
            const SizedBox(height: 10),
            _buildMacroBar('Углеводы (остаток энергии)', '${t.dailyCarbsG.toStringAsFixed(0)} г',
                '${t.carbsCalPercent.toStringAsFixed(0)}%', t.carbsCalPercent / 100.0, OutdoorTheme.tacticalGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(
      String title, String grams, String percent, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary)),
            Text('$grams ($percent)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: OutdoorTheme.surfaceCardElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyEssentialsCard(TripCalculationResult result) {
    final t = result.targets;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💧 Вода, Электролиты и Топливо',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: OutdoorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEssentialItem(
                  icon: Icons.water_drop_outlined,
                  color: OutdoorTheme.electricCyan,
                  label: 'Вода в день',
                  value: '${t.dailyWaterLiters.toStringAsFixed(1)} л',
                ),
                _buildEssentialItem(
                  icon: Icons.local_fire_department_outlined,
                  color: OutdoorTheme.signalOrange,
                  label: 'Газ / Топливо',
                  value: '${t.dailyGasFuelG.toInt()} г/чел',
                ),
                _buildEssentialItem(
                  icon: Icons.science_outlined,
                  color: OutdoorTheme.signalAmber,
                  label: 'Натрий (Na)',
                  value: '${t.dailySodiumMg.toInt()} мг',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: OutdoorTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: OutdoorTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? OutdoorTheme.signalOrange.withValues(alpha: 0.22)
                  : OutdoorTheme.surfaceCardElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? OutdoorTheme.signalOrange
                    : OutdoorTheme.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? OutdoorTheme.textPrimary : OutdoorTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _PieSegmentData {
  final String label;
  final double value;
  final Color color;
  final String formattedValue;

  const _PieSegmentData(this.label, this.value, this.color, this.formattedValue);
}
