import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/app_logo.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';

class LoadDistributionScreen extends ConsumerStatefulWidget {
  const LoadDistributionScreen({super.key});

  @override
  ConsumerState<LoadDistributionScreen> createState() =>
      _LoadDistributionScreenState();
}

class _LoadDistributionScreenState
    extends ConsumerState<LoadDistributionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDistribution();
    });
  }

  void _syncDistribution() {
    final result = ref.read(calculationResultProvider);
    if (result != null) {
      ref.read(groupParticipantsProvider.notifier).syncWithTrip(
            groupSize: result.profile.groupSize,
            allGear: result.gearList,
            shoppingList: result.shoppingList,
            personalGearWeightKg: result.totalPersonalGearWeightKg,
          );
    }
  }

  void _showEditParticipantDialog(BuildContext context, Participant p) {
    final nameController = TextEditingController(text: p.name);
    double ratio = p.strengthRatio;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: OutdoorTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '👤 Настройка участника',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: OutdoorTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя участника',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Коэффициент физ. силы / грузоподъемности:',
                  style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ChoiceChip(
                      label: const Text('0.8x (Легкий)'),
                      selected: ratio == 0.8,
                      onSelected: (val) {
                        if (val) setModalState(() => ratio = 0.8);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('1.0x (Норма)'),
                      selected: ratio == 1.0,
                      onSelected: (val) {
                        if (val) setModalState(() => ratio = 1.0);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('1.2x (Крепкий)'),
                      selected: ratio == 1.2,
                      onSelected: (val) {
                        if (val) setModalState(() => ratio = 1.2);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty) {
                      ref
                          .read(groupParticipantsProvider.notifier)
                          .updateParticipantName(p.id, newName);
                    }
                    ref
                        .read(groupParticipantsProvider.notifier)
                        .updateStrengthRatio(p.id, ratio);

                    final result = ref.read(calculationResultProvider);
                    if (result != null) {
                      ref.read(groupParticipantsProvider.notifier).rebalance(
                            allGear: result.gearList,
                            shoppingList: result.shoppingList,
                            personalGearWeightKg:
                                result.totalPersonalGearWeightKg,
                          );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Сохранить и пересчитать'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoveItemDialog({
    required BuildContext context,
    required String itemName,
    required String itemId,
    required bool isGear,
    required List<Participant> participants,
    required String currentParticipantId,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: OutdoorTheme.signalOrange),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Передать "$itemName"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: OutdoorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Выберите, кому переложить этот предмет:',
                style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ...participants.map((target) {
                final isCurrent = target.id == currentParticipantId;
                return ListTile(
                  dense: true,
                  enabled: !isCurrent,
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? OutdoorTheme.textMuted.withValues(alpha: 0.2)
                        : OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                    child: Text(
                      target.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: isCurrent
                            ? OutdoorTheme.textMuted
                            : OutdoorTheme.signalOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    target.name + (isCurrent ? ' (текущий)' : ''),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.normal : FontWeight.bold,
                      color: isCurrent
                          ? OutdoorTheme.textMuted
                          : OutdoorTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Рюкзак: ${target.totalPackWeightKg.toStringAsFixed(1)} кг',
                    style: const TextStyle(fontSize: 11, color: OutdoorTheme.textMuted),
                  ),
                  onTap: isCurrent
                      ? null
                      : () {
                          if (isGear) {
                            ref
                                .read(groupParticipantsProvider.notifier)
                                .moveGear(itemId, target.id);
                          } else {
                            ref
                                .read(groupParticipantsProvider.notifier)
                                .moveFood(itemId, target.id);
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ "$itemName" передан участнику ${target.name}'),
                              backgroundColor: OutdoorTheme.tacticalGreen,
                            ),
                          );
                        },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(calculationResultProvider);
    final participants = ref.watch(groupParticipantsProvider);
    final service = ref.watch(loadDistributionServiceProvider);

    if (result == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
        ),
      );
    }

    if (participants.isEmpty) {
      _syncDistribution();
    }

    final totalGroupWeightKg = participants.fold<double>(
        0.0, (sum, p) => sum + p.totalPackWeightKg);
    final avgWeightKg = participants.isNotEmpty
        ? totalGroupWeightKg / participants.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(height: 24),
            SizedBox(width: 8),
            Text('Кто что несёт'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Авто-балансировка веса',
            icon: const Icon(Icons.auto_fix_high, color: OutdoorTheme.signalOrange),
            onPressed: () {
              ref.read(groupParticipantsProvider.notifier).rebalance(
                    allGear: result.gearList,
                    shoppingList: result.shoppingList,
                    personalGearWeightKg: result.totalPersonalGearWeightKg,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚡ Вес группы автоматически сбалансирован'),
                  backgroundColor: OutdoorTheme.tacticalGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: OutdoorTheme.surfaceCardElevated,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat('Участников', '${participants.length} чел.', OutdoorTheme.signalOrange),
                  _buildHeaderStat('Средний рюкзак', '${avgWeightKg.toStringAsFixed(1)} кг', OutdoorTheme.electricCyan),
                  _buildHeaderStat('Общий вес группы', '${totalGroupWeightKg.toStringAsFixed(1)} кг', OutdoorTheme.signalAmber),
                ],
              ),
            ),

            // 2. Participants List
            Expanded(
              child: participants.isEmpty
                  ? const Center(child: Text('Нет данных об участниках'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final p = participants[index];
                        final diffKg = p.totalPackWeightKg - avgWeightKg;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: OutdoorTheme.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: CircleAvatar(
                              backgroundColor: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: OutdoorTheme.signalOrange,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: OutdoorTheme.signalOrange
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: OutdoorTheme.signalOrange
                                                  .withValues(alpha: 0.6)),
                                        ),
                                        child: Text(
                                          p.role.badgeTitle,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: OutdoorTheme.signalOrange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: OutdoorTheme.textMuted),
                                  onPressed: () => _showEditParticipantDialog(context, p),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  'Рюкзак: ${p.totalPackWeightKg.toStringAsFixed(1)} кг',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: OutdoorTheme.signalOrange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (diffKg.abs() < 0.3)
                                        ? OutdoorTheme.tacticalGreen.withValues(alpha: 0.2)
                                        : (diffKg > 0)
                                            ? OutdoorTheme.alertRed.withValues(alpha: 0.2)
                                            : OutdoorTheme.electricCyan.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    diffKg >= 0
                                        ? '+${diffKg.toStringAsFixed(1)} кг'
                                        : '${diffKg.toStringAsFixed(1)} кг',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (diffKg.abs() < 0.3)
                                          ? OutdoorTheme.tacticalGreen
                                          : (diffKg > 0)
                                              ? OutdoorTheme.alertRed
                                              : OutdoorTheme.electricCyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Weight distribution progress bar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Личное: ${p.personalGearWeightKg.toStringAsFixed(1)} кг • Групп: ${p.assignedGroupGearWeightKg.toStringAsFixed(1)} кг • Еда: ${p.assignedFoodWeightKg.toStringAsFixed(1)} кг • Вода: 1.5 кг',
                                          style: const TextStyle(fontSize: 10, color: OutdoorTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),

                                    // Personal Gear (Individual items)
                                    if (p.personalGear.isNotEmpty) ...[
                                      Theme(
                                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                        child: ExpansionTile(
                                          tilePadding: EdgeInsets.zero,
                                          childrenPadding: EdgeInsets.zero,
                                          leading: const Icon(Icons.person_outline, size: 18, color: OutdoorTheme.signalOrange),
                                          title: Text(
                                            '🎒 Личное снаряжение (${p.personalGear.length} предм. • ${p.personalGearWeightKg.toStringAsFixed(1)} кг)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: OutdoorTheme.textPrimary,
                                            ),
                                          ),
                                          children: p.personalGear.map((g) {
                                            return ListTile(
                                              dense: true,
                                              contentPadding: const EdgeInsets.only(left: 8),
                                              title: Text(
                                                g.nameRu,
                                                style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                                              ),
                                              trailing: Text(
                                                '${g.totalWeightG} г',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: OutdoorTheme.textMuted,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Assigned Group Gear
                                    if (p.assignedGear.isNotEmpty) ...[
                                      const Text(
                                        '🏕️ Групповое снаряжение:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: OutdoorTheme.signalAmber,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...p.assignedGear.map((g) {
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            '${g.nameRu} ${g.quantity > 1 ? '(x${g.quantity})' : ''}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${g.totalWeightG} г',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: OutdoorTheme.signalOrange,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.swap_horiz, size: 18, color: OutdoorTheme.electricCyan),
                                                tooltip: 'Передать другому',
                                                onPressed: () {
                                                  _showMoveItemDialog(
                                                    context: context,
                                                    itemName: g.nameRu,
                                                    itemId: g.id,
                                                    isGear: true,
                                                    participants: participants,
                                                    currentParticipantId: p.id,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 8),
                                    ],

                                    // Assigned Food Items
                                    if (p.assignedFood.isNotEmpty) ...[
                                      const Text(
                                        '🥫 Продуктовая раскладка:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: OutdoorTheme.tacticalGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...p.assignedFood.map((f) {
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            f.foodItem.nameRu,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${f.totalGrams} г',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: OutdoorTheme.tacticalGreen,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.swap_horiz, size: 18, color: OutdoorTheme.electricCyan),
                                                tooltip: 'Передать другому',
                                                onPressed: () {
                                                  _showMoveItemDialog(
                                                    context: context,
                                                    itemName: f.foodItem.nameRu,
                                                    itemId: f.foodItem.id,
                                                    isGear: false,
                                                    participants: participants,
                                                    currentParticipantId: p.id,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 8),
                                    ],

                                    // Copy participant report button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final dutyDays = result.dailyRations
                                              .where((r) => r.dutyParticipantIds.contains(p.id))
                                              .map((r) => r.dayNumber)
                                              .toList();
                                          final report = service.generateParticipantReport(p, dutyDays: dutyDays);
                                          await Clipboard.setData(ClipboardData(text: report));
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('✅ Список для участника ${p.name} скопирован в буфер!'),
                                                backgroundColor: OutdoorTheme.tacticalGreen,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: Text('Скопировать список для ${p.name}'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: OutdoorTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
