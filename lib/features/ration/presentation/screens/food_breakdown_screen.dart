import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/app_logo.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/ration/domain/models/daily_ration.dart';
import 'package:survival_calc/features/ration/domain/models/food_item.dart';

class FoodBreakdownScreen extends ConsumerStatefulWidget {
  const FoodBreakdownScreen({super.key});

  @override
  ConsumerState<FoodBreakdownScreen> createState() => _FoodBreakdownScreenState();
}

class _FoodBreakdownScreenState extends ConsumerState<FoodBreakdownScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;
  bool _showForGroup = false;
  String _searchQuery = '';
  FoodCategory? _selectedCategory;
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCustomFoodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController(text: '350');
    final proteinController = TextEditingController(text: '15');
    final fatController = TextEditingController(text: '10');
    final carbsController = TextEditingController(text: '50');
    final portionController = TextEditingController(text: '70');
    FoodCategory category = FoodCategory.grains;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '➕ Добавить свой продукт',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название продукта *',
                    hintText: 'Например: Сублимат борщ Гала-Гала, сушеное мясо...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FoodCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Категория *'),
                  dropdownColor: OutdoorTheme.surfaceCardElevated,
                  items: FoodCategory.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c.displayNameRu),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ккал на 100г *',
                          suffixText: 'ккал',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: portionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Порция *',
                          suffixText: 'г',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Белки/100г',
                          suffixText: 'г',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Жиры/100г',
                          suffixText: 'г',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Углев/100г',
                          suffixText: 'г',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final cal = double.tryParse(caloriesController.text) ?? 300.0;
                    final prot = double.tryParse(proteinController.text) ?? 10.0;
                    final fat = double.tryParse(fatController.text) ?? 5.0;
                    final carbs = double.tryParse(carbsController.text) ?? 50.0;
                    final portion = int.tryParse(portionController.text) ?? 70;

                    if (name.isNotEmpty) {
                      final newFood = FoodItem(
                        id: 'custom_food_${DateTime.now().millisecondsSinceEpoch}',
                        nameRu: name,
                        category: category,
                        calories100g: cal,
                        protein100g: prot,
                        fat100g: fat,
                        carbs100g: carbs,
                        potassiumMg100g: 200.0,
                        magnesiumMg100g: 50.0,
                        sodiumMg100g: 100.0,
                        ironMg100g: 2.0,
                        vitCMg100g: 0.0,
                        portionG: portion,
                        shelfLifeDays: 365,
                        isCustom: true,
                      );

                      ref.read(customFoodProvider.notifier).addFoodItem(newFood);
                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Продукт "$name" добавлен в базу'),
                          backgroundColor: OutdoorTheme.tacticalGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('Сохранить в базу продуктов'),
                ),
              ],
            ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(height: 24),
            SizedBox(width: 8),
            Text('Раскладка продуктов'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Добавить свой продукт',
            icon: const Icon(Icons.add_circle_outline, color: OutdoorTheme.signalOrange),
            onPressed: () => _showAddCustomFoodDialog(context),
          ),
          IconButton(
            tooltip: 'Копировать список покупок',
            icon: const Icon(Icons.copy_all, color: OutdoorTheme.signalOrange),
            onPressed: () async {
              await exportService.copyToClipboard(result);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Список продуктов скопирован в буфер обмена'),
                    backgroundColor: OutdoorTheme.tacticalGreen,
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: OutdoorTheme.signalOrange,
          labelColor: OutdoorTheme.signalOrange,
          unselectedLabelColor: OutdoorTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_basket_outlined), text: 'Список покупок'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Меню по дням'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShoppingListTab(result),
          _buildDailyMenuTab(result),
        ],
      ),
    );
  }

  // --- TAB 1: SHOPPING LIST ---

  Widget _buildShoppingListTab(TripCalculationResult result) {
    var items = result.shoppingList;

    if (_selectedCategory != null) {
      items = items.where((i) => i.foodItem.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      items = items
          .where((i) => i.foodItem.nameRu
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    final totalKg = result.totalFoodWeightAllGroupKg.toStringAsFixed(2);
    final perPersonKg = result.totalFoodWeightPerPersonKg.toStringAsFixed(2);

    return Column(
      children: [
        // Summary Header Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: OutdoorTheme.surfaceCardElevated,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Всего на группу', '$totalKg кг', OutdoorTheme.signalOrange),
              _buildHeaderStat('На 1 участника', '$perPersonKg кг', OutdoorTheme.electricCyan),
              _buildHeaderStat('Позиций в чеке', '${result.shoppingList.length}', OutdoorTheme.signalAmber),
            ],
          ),
        ),

        // Search Input
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск продуктов...',
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

        // Category Filter Chips
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
              ...FoodCategory.values.map((cat) {
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

        // Items List
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Продукты не найдены',
                    style: TextStyle(color: OutdoorTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isCustom = item.foodItem.isCustom;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: OutdoorTheme.signalOrange.withValues(alpha: 0.15),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: OutdoorTheme.signalOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.foodItem.nameRu,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            if (isCustom)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: OutdoorTheme.electricCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'СВОЙ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: OutdoorTheme.electricCyan,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${item.foodItem.category.displayNameRu} • ${item.totalPortions} порц. • ${item.foodItem.calories100g.toInt()} ккал/100г',
                          style: const TextStyle(fontSize: 11, color: OutdoorTheme.textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.totalGrams} г',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: OutdoorTheme.signalOrange,
                              ),
                            ),
                            if (isCustom)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: OutdoorTheme.alertRed),
                                onPressed: () {
                                  ref.read(customFoodProvider.notifier).removeFoodItem(item.foodItem.id);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _selectedDietTargetId = 'common';

  // --- TAB 2: DAILY MENU ---

  Widget _buildDailyMenuTab(TripCalculationResult result) {
    final participantsWithDiet = result.participants.where((p) => p.hasSpecialDiet).toList();
    final isIndividual = _selectedDietTargetId != 'common';
    final currentRationList = isIndividual
        ? (result.individualRations[_selectedDietTargetId] ?? result.dailyRations)
        : result.dailyRations;

    if (currentRationList.isEmpty) {
      return const Center(child: Text('Нет данных меню'));
    }

    final currentRation = currentRationList[_selectedDayIndex.clamp(0, currentRationList.length - 1)];
    final selectedParticipant = isIndividual
        ? result.participants.where((p) => p.id == _selectedDietTargetId).firstOrNull
        : null;

    final int targetGroupCount = isIndividual
        ? 1
        : (participantsWithDiet.isNotEmpty
            ? (result.profile.groupSize - participantsWithDiet.length).clamp(1, result.profile.groupSize)
            : result.profile.groupSize);

    final int scale = _showForGroup ? targetGroupCount : 1;

    return Column(
      children: [
        // 1. Shared vs Individual Diet Selector Bar (if there are special diets)
        if (participantsWithDiet.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: OutdoorTheme.surfaceCardElevated,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.group, size: 16),
                    label: Text(
                      '🥘 Общий котёл (${result.profile.groupSize - participantsWithDiet.length} чел.)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    selected: _selectedDietTargetId == 'common',
                    onSelected: (val) {
                      if (val) setState(() => _selectedDietTargetId = 'common');
                    },
                  ),
                  const SizedBox(width: 8),
                  ...participantsWithDiet.map((p) {
                    final isSel = _selectedDietTargetId == p.id;
                    final dietTag = p.dietaryRestrictions
                        .where((d) => d != DietaryRestriction.none)
                        .map((d) => d.shortTag)
                        .join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.person, size: 16, color: OutdoorTheme.tacticalGreen),
                        label: Text(
                          '🥦 ${p.name} ($dietTag)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => _selectedDietTargetId = p.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Diet Info Badge if individual diet selected
        if (isIndividual && selectedParticipant != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: OutdoorTheme.tacticalGreen, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Индивидуальный рацион для: ${selectedParticipant.name} • Спец-порции без аллергенов',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: OutdoorTheme.tacticalGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Portion scale selector (1 person vs Group)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: OutdoorTheme.surfaceCardElevated,
            border: Border(
              bottom: BorderSide(
                color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _showForGroup ? Icons.groups : Icons.person,
                    size: 18,
                    color: OutdoorTheme.signalOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showForGroup
                        ? 'Закладка: На группу ($targetGroupCount чел)'
                        : 'Порция: На 1 человека',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: OutdoorTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SegmentedButton<bool>(
                segments: [
                  const ButtonSegment<bool>(
                    value: false,
                    label: Text('1 чел', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.person, size: 14),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('$targetGroupCount чел', style: TextStyle(fontSize: 11)),
                    icon: const Icon(Icons.groups, size: 14),
                  ),
                ],
                selected: {_showForGroup},
                onSelectionChanged: (newVal) {
                  setState(() => _showForGroup = newVal.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Day Selector Horizontal Bar
        Container(
          height: 54,
          color: OutdoorTheme.surfaceCard,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: currentRationList.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedDayIndex;
              final day = currentRationList[index];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('День ${day.dayNumber}'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedDayIndex = index);
                  },
                ),
              );
            },
          ),
        ),

        // Duty Officers Banner for the day (if group > 1)
        if (result.profile.groupSize > 1 && currentRation.dutyParticipantIds.isNotEmpty) ...[
          Builder(builder: (context) {
            final dutyNames = currentRation.dutyParticipantIds.map((id) {
              final p = result.participants.where((part) => part.id == id).firstOrNull;
              return p != null ? '${p.name} ${p.role.emoji}' : 'Участник';
            }).join(', ');

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: OutdoorTheme.signalOrange.withValues(alpha: 0.12),
                border: Border(
                  bottom: BorderSide(
                    color: OutdoorTheme.signalOrange.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 16, color: OutdoorTheme.signalOrange),
                  const SizedBox(width: 6),
                  const Text(
                    '🔥 Дежурные дня: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: OutdoorTheme.signalOrange,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dutyNames,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OutdoorTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Day Summary Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: OutdoorTheme.surfaceCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                scale == 1 ? 'Калории / чел' : 'Калории ($scale чел)',
                '${(currentRation.totalCalories * scale).toInt()} ккал',
                OutdoorTheme.signalOrange,
              ),
              _buildHeaderStat(
                scale == 1 ? 'Вес / чел' : 'Вес ($scale чел)',
                scale == 1
                    ? '${currentRation.totalWeightG} г'
                    : (currentRation.totalWeightG * scale >= 1000
                        ? '${((currentRation.totalWeightG * scale) / 1000.0).toStringAsFixed(2)} кг'
                        : '${currentRation.totalWeightG * scale} г'),
                OutdoorTheme.signalAmber,
              ),
              _buildHeaderStat(
                scale == 1 ? 'БЖУ / чел' : 'БЖУ ($scale чел)',
                '${(currentRation.totalProteinG * scale).toInt()} / ${(currentRation.totalFatG * scale).toInt()} / ${(currentRation.totalCarbsG * scale).toInt()}',
                OutdoorTheme.electricCyan,
              ),
            ],
          ),
        ),

        // 4 Meal Slots Accordion
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
            children: currentRation.mealSlots.map((slot) => _buildMealSlotCard(slot, scale)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSlotCard(DailyMealSlot slot, int scale) {
    final weightFormatted = slot.totalWeightG * scale >= 1000
        ? '${((slot.totalWeightG * scale) / 1000.0).toStringAsFixed(2)} кг'
        : '${slot.totalWeightG * scale} г';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          _getSlotIcon(slot.slotType),
          color: OutdoorTheme.signalOrange,
        ),
        title: Text(
          slot.slotType.displayNameRu,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${(slot.totalCalories * scale).toInt()} ккал • $weightFormatted • Б:${(slot.totalProteinG * scale).toInt()} Ж:${(slot.totalFatG * scale).toInt()} У:${(slot.totalCarbsG * scale).toInt()}',
          style: const TextStyle(fontSize: 11, color: OutdoorTheme.textSecondary),
        ),
        children: slot.items.map((item) {
          final itemWeightFormatted = item.grams * scale >= 1000
              ? '${((item.grams * scale) / 1000.0).toStringAsFixed(2)} кг'
              : '${item.grams * scale} г';

          return ListTile(
            dense: true,
            title: Text(
              item.foodItem.nameRu,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              scale > 1
                  ? '${item.foodItem.category.displayNameRu} • ${item.grams} г/чел × $scale чел'
                  : '${item.foodItem.category.displayNameRu} • ${item.foodItem.calories100g.toInt()} ккал/100г',
              style: const TextStyle(fontSize: 10, color: OutdoorTheme.textMuted),
            ),
            trailing: Text(
              itemWeightFormatted,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: OutdoorTheme.signalOrange,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getSlotIcon(MealSlotType type) {
    switch (type) {
      case MealSlotType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealSlotType.lunch_snack:
        return Icons.hiking_outlined;
      case MealSlotType.dinner:
        return Icons.nightlight_round_outlined;
      case MealSlotType.pocket_food:
        return Icons.backpack_outlined;
    }
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: OutdoorTheme.textMuted,
            ),
          ),
        ),
      ],
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
