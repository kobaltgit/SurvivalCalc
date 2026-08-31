import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/tracking/domain/models/camp_debrief.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_exporter.dart';

class CampDebriefSheet extends StatelessWidget {
  final CampDebrief debrief;
  final DailyTrack? track;

  const CampDebriefSheet({
    super.key,
    required this.debrief,
    this.track,
  });

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hoursч $minutesм';
    }
    return '$minutes мин';
  }

  void _shareGpx(BuildContext context) async {
    if (track == null || track!.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет точек трека для экспорта')),
      );
      return;
    }

    const exporter = GpxExporter();
    final String gpxContent = exporter.exportTrackToGpx(track!);

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: gpxContent,
          subject: 'Трек ${track!.title} (SurvivalCalc GPX)',
        ),
      );
    } catch (_) {
      // Fallback copy to clipboard
      await Clipboard.setData(ClipboardData(text: gpxContent));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPX XML скопирован в буфер обмена')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cabin,
                      color: OutdoorTheme.signalOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debrief.dayTitle,
                          style: const TextStyle(
                            color: OutdoorTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Вечерний дебрифинг & Метаболический баланс',
                          style: TextStyle(
                            color: OutdoorTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Key physical metrics comparison
              _buildPhysicalMetricsGrid(),
              const SizedBox(height: 20),

              // Elevation Chart Profile
              if (track != null && track!.points.length >= 2) ...[
                _buildElevationChart(),
                const SizedBox(height: 20),
              ],

              // Metabolic & Energy Section
              _buildMetabolicBalanceCard(),
              const SizedBox(height: 16),

              // Nutrition Recommendations
              _buildNutritionRecommendationsCard(),
              const SizedBox(height: 16),

              // Hydration & Electrolytes
              _buildHydrationCard(),
              const SizedBox(height: 16),

              // Backpack Weight Melt Card
              _buildBackpackMeltCard(),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (track != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareGpx(context),
                        icon: const Icon(Icons.share, color: OutdoorTheme.signalOrange),
                        label: const Text(
                          'GPX Экспорт',
                          style: TextStyle(
                            color: OutdoorTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: OutdoorTheme.signalOrange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (track != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OutdoorTheme.signalOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Принять отчет',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📍 ДИСТАНЦИЯ И ДВИЖЕНИЕ',
            style: TextStyle(
              color: OutdoorTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Пройдено',
                  value: '${debrief.actualDistanceKm.toStringAsFixed(1)} км',
                  subValue: 'План: ${debrief.plannedDistanceKm.toStringAsFixed(1)} км',
                  icon: Icons.directions_walk,
                  highlight: debrief.actualDistanceKm >= debrief.plannedDistanceKm,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Набор высоты',
                  value: '+${debrief.actualAscentMeters.toStringAsFixed(0)} м',
                  subValue: 'План: +${debrief.plannedAscentMeters.toStringAsFixed(0)} м',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const Divider(color: OutdoorTheme.surfaceCard, height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Время в пути',
                  value: _formatDuration(debrief.movingDurationSeconds),
                  subValue: 'Привалы: ${_formatDuration(debrief.pauseDurationSeconds)}',
                  icon: Icons.timer,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Средняя скорость',
                  value: '${debrief.avgMovingSpeedKmh.toStringAsFixed(1)} км/ч',
                  subValue: 'Сброс: -${debrief.actualDescentMeters.toStringAsFixed(0)} м',
                  icon: Icons.speed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: highlight ? OutdoorTheme.signalOrange : OutdoorTheme.textSecondary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: OutdoorTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subValue,
                style: const TextStyle(color: OutdoorTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElevationChart() {
    final pts = track!.points;
    if (pts.length < 2) return const SizedBox.shrink();

    // Sample down to at most 30 points for smooth graph
    final int step = (pts.length / 30).ceil().clamp(1, 100);
    final List<FlSpot> spots = [];
    double distKm = 0.0;

    for (int i = 0; i < pts.length; i += step) {
      if (i > 0) {
        distKm = (i / pts.length) * track!.totalDistanceKm;
      }
      spots.add(FlSpot(distKm, pts[i].altitude));
    }
    if (spots.last.x != track!.totalDistanceKm) {
      spots.add(FlSpot(track!.totalDistanceKm, pts.last.altitude));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📈 ПРОФИЛЬ ВЫСОТ ДНЯ (м / км)',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Icon(Icons.landscape, color: OutdoorTheme.signalOrange, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toStringAsFixed(0)}k',
                          style: const TextStyle(color: OutdoorTheme.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toStringAsFixed(0)}m',
                          style: const TextStyle(color: OutdoorTheme.textMuted, fontSize: 10),
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
                    color: OutdoorTheme.signalOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicBalanceCard() {
    final isDeficit = debrief.calorieDelta > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDeficit
            ? Colors.orange.withValues(alpha: 0.12)
            : OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeficit
              ? OutdoorTheme.signalOrange.withValues(alpha: 0.5)
              : OutdoorTheme.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔥 ЭНЕРГОЗАТРАТЫ ДНЯ',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDeficit ? OutdoorTheme.signalOrange : Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDeficit
                      ? 'Дефицит +${debrief.calorieDelta.toStringAsFixed(0)} ккал'
                      : 'Норма (${debrief.calorieDelta.toStringAsFixed(0)} ккал)',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Сожжено по факту', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${debrief.actualCaloriesBurned.toStringAsFixed(0)} ккал',
                    style: const TextStyle(
                      color: OutdoorTheme.signalOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 35, color: OutdoorTheme.surfaceCard),
              Column(
                children: [
                  const Text('Заложено в план', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${debrief.plannedDailyCalories.toStringAsFixed(0)} ккал',
                    style: const TextStyle(
                      color: OutdoorTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant, color: OutdoorTheme.signalOrange, size: 18),
              SizedBox(width: 8),
              Text(
                'СОВЕТЫ ПО ВЕЧЕРНЕМУ ПИТАНИЮ',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...debrief.nutritionRecommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                rec,
                style: const TextStyle(
                  color: OutdoorTheme.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'ГИДРАТАЦИЯ И ЭЛЕКТРОЛИТЫ',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Восполнить жидкости до сна:',
                style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13),
              ),
              Text(
                '≥ ${debrief.eveningWaterCompensationLiters.toStringAsFixed(1)} л',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            debrief.electrolyteAdvice,
            style: const TextStyle(
              color: OutdoorTheme.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackpackMeltCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.backpack, color: OutdoorTheme.signalOrange, size: 18),
              SizedBox(width: 8),
              Text(
                'ТАЯНИЕ ВЕСА РЮКЗАКА',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Съедено за день', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '-${debrief.dailyFoodWeightConsumedG.toStringAsFixed(0)} г еды',
                    style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сожжено топлива', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '-${debrief.dailyGasConsumedG.toStringAsFixed(0)} г газа',
                    style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Вес на завтра', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '~${debrief.estimatedMorningPackWeightKg.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      color: OutdoorTheme.signalOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
