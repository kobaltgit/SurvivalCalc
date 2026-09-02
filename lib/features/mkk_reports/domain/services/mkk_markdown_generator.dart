import 'package:intl/intl.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_pdf_generator.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class MkkMarkdownGenerator {
  /// Generates the Markdown text for Document 1: Pre-trip Passport (Маршрутная книжка)
  static String generatePreTripPassportMarkdown({
    required TripProfile profile,
    required List<Participant> participants,
    required TripCalculationResult? calcResult,
  }) {
    final effectiveParticipants = MkkPdfGenerator.resolveEffectiveParticipants(
      participants: participants,
      calcResult: calcResult,
      groupSize: profile.groupSize,
    );
    final dateFormat = DateFormat('dd.MM.yyyy');
    final sb = StringBuffer();

    sb.writeln('# 📋 ПАСПОРТ МАРШРУТА И МАРШРУТНАЯ КНИЖКА');
    sb.writeln('**Походная группа:** ${profile.title}');
    if (profile.clubOrCity.isNotEmpty) {
      sb.writeln('**Организация / Турклуб:** ${profile.clubOrCity}');
    }
    if (profile.mkkName.isNotEmpty) {
      sb.writeln('**Выпускающая МКК:** ${profile.mkkName}');
    }
    sb.writeln('**Категория сложности:** ${profile.difficultyCategory}');
    if (profile.geographicalRegion.isNotEmpty) {
      sb.writeln('**Район похода:** ${profile.geographicalRegion}');
    }
    sb.writeln('**Сезон:** ${profile.season.displayNameRu} | **Вид активности:** ${profile.activityType.displayNameRu}');
    sb.writeln('**Дата составления:** ${dateFormat.format(profile.createdAt)}');
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 1. Справочные сведения о маршруте');
    sb.writeln('- **Продолжительность:** ${profile.durationDays} дн. (из них ходовых: ${profile.activeDays} дн.)');
    sb.writeln('- **Протяженность:** ${profile.totalDistanceKm.toStringAsFixed(1)} км');
    sb.writeln('- **Суммарный набор высоты:** ${profile.totalAscentMeters.toStringAsFixed(0)} м');
    sb.writeln('- **Количество участников:** ${profile.groupSize} чел.');
    if (calcResult != null) {
      sb.writeln('- **Суточная норма калорий на чел:** ${calcResult.targets.dailyCalories.toStringAsFixed(0)} ккал');
      sb.writeln('- **Стартовый вес рюкзака на чел (средний):** ${calcResult.startPackWeightPerPersonKg.toStringAsFixed(1)} кг (Снаряжение: ${calcResult.totalGearWeightPerPersonKg.toStringAsFixed(1)} кг, Еда: ${calcResult.totalFoodWeightPerPersonKg.toStringAsFixed(1)} кг)');
    }
    if (profile.emergencyExitRoutes.isNotEmpty) {
      sb.writeln('- **Аварийные и запасные варианты схода:** ${profile.emergencyExitRoutes}');
    }
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 2. Состав группы и распределение обязанностей');
    sb.writeln('| № | ФИО / Имя | Должность | Вес (кг) | Сила | Опыт / Контакты | Особенности / Диета |');
    sb.writeln('|:-:|:---|:---:|:-:|:-:|:---|:---|');
    for (int i = 0; i < effectiveParticipants.length; i++) {
      final p = effectiveParticipants[i];
      final expParts = <String>[];
      if (p.touristExperience.isNotEmpty) expParts.add('Опыт: ${p.touristExperience}');
      if (p.contactPhone.isNotEmpty) expParts.add('Тел: ${p.contactPhone}');
      final exp = expParts.isNotEmpty ? expParts.join('<br/>') : '—';
      final dietAndHealth = MkkPdfGenerator.formatHealthAndDiet(p, forPdf: false);
      sb.writeln('| ${i + 1} | ${p.displayName} | ${p.role.displayNameRu} | ${p.weightKg.toStringAsFixed(0)} | ${p.strengthRatio}x | $exp | $dietAndHealth |');
    }
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 3. Сводная весовая ведомость («Кто что несёт»)');
    sb.writeln('| № | Участник | Личное (кг) | Групп. снаряжение (кг) | Паек питания (кг) | ИТОГО на старте (кг) |');
    sb.writeln('|:-:|:---|:-:|:-:|:-:|:-:|');
    for (int i = 0; i < effectiveParticipants.length; i++) {
      final p = effectiveParticipants[i];
      sb.writeln('| ${i + 1} | ${p.displayName} | ${p.personalGearWeightKg.toStringAsFixed(2)} | ${p.assignedGroupGearWeightKg.toStringAsFixed(2)} | ${p.assignedFoodWeightKg.toStringAsFixed(2)} | **${p.totalPackWeightKg.toStringAsFixed(2)}** |');
    }
    sb.writeln();

    if (calcResult != null) {
      sb.writeln('---');
      sb.writeln('## 4. Схема питания и рацион');
      sb.writeln('- **Суточная калорийность на 1 участника:** ${calcResult.targets.dailyCalories.toStringAsFixed(0)} ккал');
      sb.writeln('- **Баланс БЖУ:** Белки: ${calcResult.targets.dailyProteinG.toStringAsFixed(0)} г | Жиры: ${calcResult.targets.dailyFatG.toStringAsFixed(0)} г | Углеводы: ${calcResult.targets.dailyCarbsG.toStringAsFixed(0)} г');
      sb.writeln('- **Электролиты (Na):** ${calcResult.targets.dailySodiumMg.toStringAsFixed(0)} мг | **Вода:** ${calcResult.targets.dailyWaterLiters.toStringAsFixed(1)} л/день');
      sb.writeln('- **Общий вес продуктовой раскладки на группу:** ${calcResult.totalFoodWeightAllGroupKg.toStringAsFixed(2)} кг');
      sb.writeln();
    }

    return sb.toString();
  }

  /// Generates the Markdown text for Document 2: Post-trip Technical Report (Итоговый отчет)
  static String generatePostTripReportMarkdown({
    required TripProfile profile,
    required List<Participant> participants,
    required List<DailyTrack> tracks,
    required List<WayPoint> waypoints,
    required List<DailyCampNote> campNotes,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final sb = StringBuffer();

    sb.writeln('# 🏔️ ИТОГОВЫЙ ТЕХНИЧЕСКИЙ ОТЧЕТ О ТУРИСТСКОМ ПОХОДЕ');
    sb.writeln('**Маршрут:** ${profile.title}');
    if (profile.clubOrCity.isNotEmpty) {
      sb.writeln('**Организация / Турклуб:** ${profile.clubOrCity}');
    }
    sb.writeln('**Категория сложности:** ${profile.difficultyCategory} | **Район:** ${profile.geographicalRegion.isNotEmpty ? profile.geographicalRegion : "Полевой"}');
    sb.writeln('**Дата формирования:** ${dateFormat.format(DateTime.now())}');
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 1. Сравнительная таблица «План / Факт»');
    final totalActualDist = tracks.fold<double>(0.0, (sum, t) => sum + t.totalDistanceKm);
    final totalActualAscent = tracks.fold<double>(0.0, (sum, t) => sum + t.elevationGainMeters);
    final totalActualMovingSec = tracks.fold<int>(0, (sum, t) => sum + t.movingDurationSeconds);
    final totalHours = (totalActualMovingSec / 3600.0).toStringAsFixed(1);

    sb.writeln('| Параметр | План | Факт | Разница |');
    sb.writeln('|:---|:-:|:-:|:-:|');
    sb.writeln('| **Дистанция (км)** | ${profile.totalDistanceKm.toStringAsFixed(1)} | ${totalActualDist.toStringAsFixed(1)} | ${(totalActualDist - profile.totalDistanceKm).toStringAsFixed(1)} |');
    sb.writeln('| **Набор высоты (м)** | ${profile.totalAscentMeters.toStringAsFixed(0)} | ${totalActualAscent.toStringAsFixed(0)} | ${(totalActualAscent - profile.totalAscentMeters).toStringAsFixed(0)} |');
    sb.writeln('| **Ходовых дней** | ${profile.activeDays} | ${tracks.length} | ${tracks.length - profile.activeDays} |');
    sb.writeln('| **Суммарное ходовое время** | — | $totalHours ч | — |');
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 2. График фактического движения по дням');
    sb.writeln('| День | Название участка / Трек | Дистанция (км) | Набор (м) | Сброс (м) | Время хода | Средн. скор. |');
    sb.writeln('|:-:|:---|:-:|:-:|:-:|:-:|:-:|');
    for (int i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      final h = t.movingDurationSeconds ~/ 3600;
      final m = (t.movingDurationSeconds % 3600) ~/ 60;
      final timeStr = '$hч $mм';
      sb.writeln('| ${i + 1} | ${t.title} | ${t.totalDistanceKm.toStringAsFixed(1)} | +${t.elevationGainMeters.toStringAsFixed(0)} | -${t.elevationLossMeters.toStringAsFixed(0)} | $timeStr | ${t.avgMovingSpeedKmh.toStringAsFixed(1)} км/ч |');
    }
    sb.writeln();

    if (waypoints.isNotEmpty) {
      sb.writeln('---');
      sb.writeln('## 3. Паспорт путевых точек и препятствий');
      sb.writeln('| № | Название точки | Категория | Координаты | Высота (м) | Автор | Фото |');
      sb.writeln('|:-:|:---|:---:|:---:|:-:|:---|:---:|');
      for (int i = 0; i < waypoints.length; i++) {
        final w = waypoints[i];
        final coords = '${w.latitude.toStringAsFixed(5)}, ${w.longitude.toStringAsFixed(5)}';
        final photo = (w.photoPath != null && w.photoPath!.isNotEmpty) ? '📷 Есть' : '—';
        final author = w.authorName ?? '—';
        sb.writeln('| ${i + 1} | ${w.title} | ${w.type.displayNameRu} | $coords | ${w.altitude.toStringAsFixed(0)} | $author | $photo |');
      }
      sb.writeln();
    }

    if (campNotes.isNotEmpty) {
      sb.writeln('---');
      sb.writeln('## 4. Дневник лагеря и погодная хроника');
      for (final note in campNotes) {
        final roleStr = note.authorRole != null ? ' (${note.authorRole!.displayNameRu})' : '';
        final weatherStr = note.weather != null ? ' — Погода: ${note.weather}' : '';
        sb.writeln('### 🏕️ Заметка: ${note.authorName}$roleStr$weatherStr');
        sb.writeln('> ${note.text}');
        sb.writeln();
      }
    }

    return sb.toString();
  }

  /// Converts Markdown tables and headings into clean HTML format for rich-text clipboard
  static String markdownToHtml(String markdown) {
    String html = markdown
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    // Headings
    html = html.replaceAllMapped(RegExp(r'^# (.+)$', multiLine: true), (m) => '<h1>${m[1]}</h1>');
    html = html.replaceAllMapped(RegExp(r'^## (.+)$', multiLine: true), (m) => '<h2>${m[1]}</h2>');
    html = html.replaceAllMapped(RegExp(r'^### (.+)$', multiLine: true), (m) => '<h3>${m[1]}</h3>');

    // Bold & italic
    html = html.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<b>${m[1]}</b>');
    html = html.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => '<i>${m[1]}</i>');

    // Simple markdown table parser to HTML table
    final lines = html.split('\n');
    final resultLines = <String>[];
    bool inTable = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('|') && line.endsWith('|')) {
        if (line.contains('---')) {
          continue; // skip separator
        }
        if (!inTable) {
          inTable = true;
          resultLines.add('<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; font-family: sans-serif;">');
        }
        final cells = line.split('|').where((c) => c.isNotEmpty).map((c) => c.trim()).toList();
        final tag = resultLines.last.contains('<table') ? 'th' : 'td';
        final row = cells.map((c) => '<$tag>$c</$tag>').join('');
        resultLines.add('<tr>$row</tr>');
      } else {
        if (inTable) {
          inTable = false;
          resultLines.add('</table><br/>');
        }
        if (line.startsWith('- ')) {
          resultLines.add('<li>${line.substring(2)}</li>');
        } else if (line.isNotEmpty) {
          resultLines.add('<p>$line</p>');
        }
      }
    }
    if (inTable) {
      resultLines.add('</table>');
    }

    final bodyContent = resultLines.join('\n');
    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Экспедиционная сводка - SurvivalCalc</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      line-height: 1.6;
      color: #1f2937;
      background-color: #ffffff;
      padding: 32px;
      max-width: 900px;
      margin: 0 auto;
    }
    h1 { color: #ea580c; border-bottom: 2px solid #ea580c; padding-bottom: 8px; }
    h2 { color: #1e293b; margin-top: 24px; }
    h3 { color: #475569; }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 16px 0;
      font-size: 14px;
    }
    th, td {
      border: 1px solid #cbd5e1;
      padding: 8px 12px;
      text-align: left;
    }
    th {
      background-color: #1e293b;
      color: #ffffff;
      font-weight: 600;
    }
    tr:nth-child(even) {
      background-color: #f8fafc;
    }
    blockquote {
      border-left: 4px solid #ea580c;
      padding-left: 16px;
      margin-left: 0;
      color: #4b5563;
      background-color: #fff7ed;
      padding: 8px 16px;
      border-radius: 0 6px 6px 0;
    }
    hr {
      border: 0;
      border-top: 1px solid #e2e8f0;
      margin: 24px 0;
    }
    li {
      margin-bottom: 4px;
    }
  </style>
</head>
<body>
$bodyContent
</body>
</html>''';
  }
}
