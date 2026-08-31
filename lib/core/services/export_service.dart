import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';

class ExportService {
  const ExportService();

  String generateMarkdownReport(TripCalculationResult result) {
    final buffer = StringBuffer();
    final p = result.profile;
    final t = result.targets;

    buffer.writeln('# 🌲 ПОХОДНЫЙ ОТЧЕТ И РАСКЛАДКА: ${p.title}');
    buffer.writeln('📅 Дата формирования: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln();

    buffer.writeln('## 📌 Параметры похода');
    buffer.writeln('- **Количество участников:** ${p.groupSize} чел.');
    buffer.writeln('- **Продолжительность:** ${p.durationDays} дн. (ходовых: ${p.activeDays})');
    buffer.writeln('- **Дистанция:** ${p.totalDistanceKm} км (набор высоты: ${p.totalAscentMeters.toInt()} м)');
    buffer.writeln('- **Эквивалентная дистанция:** ${t.equivalentDistanceKm.toStringAsFixed(1)} км');
    buffer.writeln('- **Сезон:** ${p.season.displayNameRu}');
    buffer.writeln('- **Тип похода:** ${p.activityType.displayNameRu}');
    buffer.writeln();

    buffer.writeln('## ⚡ Физиологические нормы (на 1 человека в сутки)');
    buffer.writeln('- **Целевая калорийность:** ${t.dailyCalories.toInt()} ккал (BMR: ${t.bmr.toInt()}, PAL: ${t.pal})');
    buffer.writeln('- **Белки:** ${t.dailyProteinG.toStringAsFixed(1)} г (${t.proteinCalPercent.toStringAsFixed(0)}%)');
    buffer.writeln('- **Жиры:** ${t.dailyFatG.toStringAsFixed(1)} г (${t.fatCalPercent.toStringAsFixed(0)}%)');
    buffer.writeln('- **Углеводы:** ${t.dailyCarbsG.toStringAsFixed(1)} г (${t.carbsCalPercent.toStringAsFixed(0)}%)');
    buffer.writeln('- **Натрий (Na):** ${t.dailySodiumMg.toInt()} мг');
    buffer.writeln('- **Вода:** ${t.dailyWaterLiters.toStringAsFixed(1)} л/день');
    buffer.writeln('- **Топливо/газ:** ${t.dailyGasFuelG.toInt()} г/день');
    buffer.writeln();

    buffer.writeln('## ⚖️ Сводка по весу рюкзака');
    buffer.writeln('- **Стартовый вес рюкзака на чел:** ${result.startPackWeightPerPersonKg.toStringAsFixed(2)} кг');
    buffer.writeln('- **Личное снаряжение:** ${result.totalPersonalGearWeightKg.toStringAsFixed(2)} кг');
    buffer.writeln('- **Групповое снаряжение на чел:** ${result.groupGearWeightPerPersonKg.toStringAsFixed(2)} кг (всего группы: ${result.totalGroupGearWeightKg.toStringAsFixed(2)} кг)');
    buffer.writeln('- **Вес еды на человека в день:** ${(result.foodWeightPerPersonPerDayKg * 1000).toInt()} г');
    buffer.writeln('- **Суммарный вес еды на чел на весь поход:** ${result.totalFoodWeightPerPersonKg.toStringAsFixed(2)} кг (на группу: ${result.totalFoodWeightAllGroupKg.toStringAsFixed(2)} кг)');
    buffer.writeln();

    buffer.writeln('## 🛒 Сводный список покупок (на всю группу: ${p.groupSize} чел)');
    buffer.writeln('| Продукт | Категория | Общий вес | Порций | Калории |');
    buffer.writeln('| :--- | :--- | :---: | :---: | :---: |');
    for (final item in result.shoppingList) {
      final weightStr = item.totalGrams >= 1000
          ? '${(item.totalGrams / 1000.0).toStringAsFixed(2)} кг'
          : '${item.totalGrams} г';
      buffer.writeln(
          '| ${item.foodItem.nameRu} | ${item.foodItem.category.displayNameRu} | $weightStr | ${item.totalPortions} | ${item.totalCalories.toInt()} ккал |');
    }
    buffer.writeln();

    buffer.writeln('## 🎒 Чек-лист снаряжения');
    buffer.writeln('### Личное снаряжение:');
    final personalGear =
        result.gearList.where((g) => g.type.name == 'personal').toList();
    for (final g in personalGear) {
      final mark = g.isChecked ? '[x]' : '[ ]';
      final mandatory = g.isMandatory ? ' *(Обязательно)*' : '';
      buffer.writeln('- $mark ${g.nameRu} (${g.totalWeightG} г)$mandatory');
    }
    buffer.writeln();

    buffer.writeln('### Групповое снаряжение:');
    final groupGear =
        result.gearList.where((g) => g.type.name == 'group').toList();
    for (final g in groupGear) {
      final mark = g.isChecked ? '[x]' : '[ ]';
      final count = g.quantity > 1 ? ' x${g.quantity} шт' : '';
      final mandatory = g.isMandatory ? ' *(Обязательно)*' : '';
      buffer.writeln(
          '- $mark ${g.nameRu}$count (всего: ${g.totalWeightG} г)$mandatory');
    }
    buffer.writeln();

    buffer.writeln('---');
    buffer.writeln('*Сгенерировано в приложении SurvivalCalc (Офлайн-калькулятор похода)*');

    return buffer.toString();
  }

  Future<void> copyToClipboard(TripCalculationResult result) async {
    final text = generateMarkdownReport(result);
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> shareReport(TripCalculationResult result) async {
    final text = generateMarkdownReport(result);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Походная раскладка: ${result.profile.title}',
      ),
    );
  }
}
