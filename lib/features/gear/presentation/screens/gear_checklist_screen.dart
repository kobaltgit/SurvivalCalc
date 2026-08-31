import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/app_logo.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/gear/domain/models/gear_item.dart';

class GearChecklistScreen extends ConsumerStatefulWidget {
  const GearChecklistScreen({super.key});

  @override
  ConsumerState<GearChecklistScreen> createState() =>
      _GearChecklistScreenState();
}

class _GearChecklistScreenState extends ConsumerState<GearChecklistScreen> {
  GearType? _selectedTypeFilter;
  GearCategory? _selectedCategory;
  String _searchQuery = '';
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _categoryScrollController.hasClients) {
        _categoryScrollController
            .animateTo(
              80.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
          if (mounted && _categoryScrollController.hasClients) {
            _hintTimer = Timer(const Duration(milliseconds: 100), () {
              if (mounted && _categoryScrollController.hasClients) {
                _categoryScrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _showAddCustomGearDialog(BuildContext context) {
    final nameController = TextEditingController();
    final weightController = TextEditingController(text: '200');
    GearCategory category = GearCategory.tools;
    GearType type = GearType.personal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '➕ Добавить свой предмет',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OutdoorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Название предмета',
                  hintText: 'Например: Запасные очки, карабин...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Вес (в граммах)',
                  suffixText: 'г',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Тип: ',
                      style: TextStyle(color: OutdoorTheme.textSecondary)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Личное'),
                    selected: type == GearType.personal,
                    onSelected: (val) =>
                        setModalState(() => type = GearType.personal),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Групповое'),
                    selected: type == GearType.group,
                    onSelected: (val) =>
                        setModalState(() => type = GearType.group),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GearCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Категория'),
                dropdownColor: OutdoorTheme.surfaceCardElevated,
                items: GearCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.displayNameRu),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => category = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final weight = int.tryParse(weightController.text) ?? 100;
                  if (name.isNotEmpty) {
                    final newGear = GearItem(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      nameRu: name,
                      category: category,
                      type: type,
                      weightG: weight,
                      season: GearSeason.all,
                      isMandatory: false,
                      isCustom: true,
                    );
                    ref
                        .read(customGearProvider.notifier)
                        .addGearItem(newGear);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сохранить предмет'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

    var items = result.gearList;

    if (_selectedTypeFilter != null) {
      items = items.where((g) => g.type == _selectedTypeFilter).toList();
    }

    if (_selectedCategory != null) {
      items = items.where((g) => g.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      items = items
          .where((g) =>
              g.nameRu.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    final checkedCount = result.gearList.where((g) => g.isChecked).length;
    final totalCount = result.gearList.length;
    final double progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(height: 24),
            SizedBox(width: 8),
            Text('Чек-лист снаряжения'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Добавить предмет',
            icon: const Icon(Icons.add_circle_outline,
                color: OutdoorTheme.signalOrange),
            onPressed: () => _showAddCustomGearDialog(context),
          ),
          IconButton(
            tooltip: 'Копировать чек-лист',
            icon: const Icon(Icons.copy_all, color: OutdoorTheme.signalOrange),
            onPressed: () async {
              await exportService.copyToClipboard(result);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Чек-лист скопирован в буфер обмена'),
                    backgroundColor: OutdoorTheme.tacticalGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Progress Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: OutdoorTheme.surfaceCardElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Собрано: $checkedCount из $totalCount (${(progress * 100).toInt()}%)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ref
                                .read(gearCheckedStateProvider.notifier)
                                .toggleAll(result.gearList, true);
                          },
                          child: const Text('Все',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: OutdoorTheme.signalOrange)),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(gearCheckedStateProvider.notifier)
                                .toggleAll(result.gearList, false);
                          },
                          child: const Text('Снять',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: OutdoorTheme.textMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: OutdoorTheme.surfaceCard,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? OutdoorTheme.tacticalGreen
                          : OutdoorTheme.signalOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск снаряжения...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // 3. Type Filter Chips (Horizontal scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Все типы',
                  isSelected: _selectedTypeFilter == null,
                  onTap: () => setState(() => _selectedTypeFilter = null),
                ),
                _buildFilterChip(
                  label: '👤 Личное',
                  isSelected: _selectedTypeFilter == GearType.personal,
                  selectedColor: OutdoorTheme.electricCyan,
                  onTap: () => setState(() => _selectedTypeFilter =
                      _selectedTypeFilter == GearType.personal
                          ? null
                          : GearType.personal),
                ),
                _buildFilterChip(
                  label: '👥 Групповое',
                  isSelected: _selectedTypeFilter == GearType.group,
                  selectedColor: OutdoorTheme.signalAmber,
                  onTap: () => setState(() => _selectedTypeFilter =
                      _selectedTypeFilter == GearType.group
                          ? null
                          : GearType.group),
                ),
              ],
            ),
          ),

          // 4. Category Filter Chips (Full names with horizontal swipe scroll)
          SingleChildScrollView(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Все категории',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...GearCategory.values.map((cat) {
                  return _buildFilterChip(
                    label: cat.displayNameRu,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() =>
                        _selectedCategory = _selectedCategory == cat ? null : cat),
                  );
                }),
              ],
            ),
          ),

          // 5. Gear Items List
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('Предметы не найдены',
                        style: TextStyle(color: OutdoorTheme.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isChecked = item.isChecked;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: isChecked
                            ? OutdoorTheme.surfaceCard.withValues(alpha: 0.5)
                            : OutdoorTheme.surfaceCard,
                        child: CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          activeColor: OutdoorTheme.signalOrange,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          onChanged: (val) {
                            ref
                                .read(gearCheckedStateProvider.notifier)
                                .toggleItem(item.id, val ?? false);
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.nameRu +
                                      (item.quantity > 1
                                          ? ' (x${item.quantity})'
                                          : ''),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isChecked
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isChecked
                                        ? OutdoorTheme.textMuted
                                        : OutdoorTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (item.isMandatory)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: OutdoorTheme.alertRed
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ОБЯЗ.',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: OutdoorTheme.alertRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.category.displayNameRu,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: OutdoorTheme.textMuted),
                                ),
                              ),
                              const Text(' • ',
                                  style:
                                      TextStyle(color: OutdoorTheme.textMuted)),
                              Text(
                                item.type == GearType.personal
                                    ? 'Личное'
                                    : 'Групповое',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item.type == GearType.personal
                                      ? OutdoorTheme.electricCyan
                                      : OutdoorTheme.signalAmber,
                                ),
                              ),
                            ],
                          ),
                          secondary: Text(
                            '${item.totalWeightG} г',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isChecked
                                  ? OutdoorTheme.textMuted
                                  : OutdoorTheme.signalOrange,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? OutdoorTheme.signalOrange;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.22)
                  : OutdoorTheme.surfaceCardElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? activeColor
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
