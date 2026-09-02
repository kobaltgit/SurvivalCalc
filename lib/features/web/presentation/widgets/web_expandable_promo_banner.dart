import 'package:flutter/material.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_apk_download_modal.dart';

class WebExpandablePromoBanner extends StatefulWidget {
  final bool initialExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const WebExpandablePromoBanner({
    super.key,
    this.initialExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<WebExpandablePromoBanner> createState() =>
      _WebExpandablePromoBannerState();
}

class _WebExpandablePromoBannerState extends State<WebExpandablePromoBanner>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: _isExpanded
            ? OutdoorTheme.surfaceCard
            : OutdoorTheme.surfaceCardElevated.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: _isExpanded
                ? OutdoorTheme.signalOrange.withValues(alpha: 0.8)
                : OutdoorTheme.borderSubtle,
            width: _isExpanded ? 1.5 : 1.0,
          ),
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsed / Toggle Header Bar
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: OutdoorTheme.signalOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isExpanded ? Icons.auto_awesome : Icons.explore,
                      size: 16,
                      color: OutdoorTheme.signalOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'SurvivalCalc — Автономный экспедиционный калькулятор рациона, развесовки и GPS-навигации',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: OutdoorTheme.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isExpanded
                          ? OutdoorTheme.signalOrange.withValues(alpha: 0.2)
                          : OutdoorTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isExpanded
                            ? OutdoorTheme.signalOrange
                            : OutdoorTheme.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded
                              ? 'Свернуть промо'
                              : 'О проекте и возможностях',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isExpanded
                                ? OutdoorTheme.signalOrange
                                : OutdoorTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: _isExpanded
                              ? OutdoorTheme.signalOrange
                              : OutdoorTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Showcase Content
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                            color: OutdoorTheme.borderSubtle, height: 1),
                        const SizedBox(height: 18),

                  // Hero Headline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Профессиональный штурман для туризма и выживания',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: OutdoorTheme.textPrimary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Точный физиологический расчет калорий, БЖУ, воды и электролитов. Умная развесовка группового снаряжения, полевой GPS-трекинг и мгновенный перенос готового плана в телефон без интернета и регистрации.',
                              style: TextStyle(
                                fontSize: 13,
                                color: OutdoorTheme.textSecondary
                                    .withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => WebApkDownloadModal.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OutdoorTheme.signalOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.android, size: 18),
                        label: const Text(
                          'Скачать APK',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4 Feature Pillars Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final cardWidth = isWide
                          ? (constraints.maxWidth - 36) / 4
                          : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildPillarCard(
                            width: cardWidth,
                            icon: const Icon(
                              Icons.offline_pin,
                              size: 20,
                              color: OutdoorTheme.tacticalGreen,
                            ),
                            iconBgColor: OutdoorTheme.tacticalGreen,
                            title: '100% Офлайн и приватность',
                            description:
                                'Полная автономность в авиарежиме. Никаких серверов, облаков или авторизаций — данные принадлежат только вам.',
                          ),
                          _buildPillarCard(
                            width: cardWidth,
                            icon: const Icon(
                              Icons.local_fire_department,
                              size: 20,
                              color: OutdoorTheme.signalOrange,
                            ),
                            iconBgColor: OutdoorTheme.signalOrange,
                            title: 'Научный метаболизм',
                            description:
                                'Формулы Миффлина-Сан Жеора, учет набора высоты, поправка на мороз и сбалансированная раскладка 57 продуктов.',
                          ),
                          _buildPillarCard(
                            width: cardWidth,
                            icon: const Icon(
                              Icons.balance,
                              size: 20,
                              color: OutdoorTheme.signalAmber,
                            ),
                            iconBgColor: OutdoorTheme.signalAmber,
                            title: 'Кто что несёт',
                            description:
                                'Авто-балансировка веса по силе участников (0.8x / 1.0x / 1.2x), учет спец-диет, аллергий и график дежурств.',
                          ),
                          _buildPillarCard(
                            width: cardWidth,
                            icon: const Icon(
                              Icons.explore,
                              size: 20,
                              color: OutdoorTheme.electricCyan,
                            ),
                            iconBgColor: OutdoorTheme.electricCyan,
                            title: 'GPS & Дневник лагеря',
                            description:
                                'Офлайн-карты, фото-метки путевых точек, вечерний дебрифинг План vs Факт и умное QR-слияние данных группы.',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // 3 Steps Guide Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: OutdoorTheme.darkBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OutdoorTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sync,
                          size: 18,
                          color: OutdoorTheme.signalOrange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              _buildStepPill(
                                  '1', 'Рассчитайте параметры похода ниже'),
                              _buildStepPill('2',
                                  'Нажмите «Перенести в телефон (QR)»'),
                              _buildStepPill('3',
                                  'Отсканируйте код камерой смартфона'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

  Widget _buildPillarCard({
    required double width,
    required Widget icon,
    required Color iconBgColor,
    required String title,
    required String description,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OutdoorTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: OutdoorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: OutdoorTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(String num, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: OutdoorTheme.signalOrange,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: OutdoorTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
