import 'package:intl/intl.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_pdf_generator.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/planned_route.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/planned_day_schedule.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class MkkMarkdownGenerator {
  /// Converts Markdown text into a clean standalone HTML document with full table support
  static String markdownToHtml(String markdown, {String title = 'Отчет МКК'}) {
    final lines = markdown.split('\n');
    final out = StringBuffer();
    bool inTable = false;
    bool isFirstTableRow = true;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('|') && line.endsWith('|')) {
        // Table line
        if (line.contains('---')) {
          // Separator line, skip
          continue;
        }

        if (!inTable) {
          inTable = true;
          isFirstTableRow = true;
          out.writeln('<table>');
        }

        final rawCells = line.substring(1, line.length - 1).split('|');
        final cells = rawCells.map((c) => c.trim()).toList();

        out.write('  <tr>');
        for (final c in cells) {
          final formatted = _formatInline(c);
          if (isFirstTableRow) {
            out.write('<th>$formatted</th>');
          } else {
            out.write('<td>$formatted</td>');
          }
        }
        out.writeln('</tr>');
        isFirstTableRow = false;
      } else {
        if (inTable) {
          inTable = false;
          out.writeln('</table>');
        }

        if (line.startsWith('# ')) {
          out.writeln('<h1>${_formatInline(line.substring(2))}</h1>');
        } else if (line.startsWith('## ')) {
          out.writeln('<h2>${_formatInline(line.substring(3))}</h2>');
        } else if (line.startsWith('### ')) {
          out.writeln('<h3>${_formatInline(line.substring(4))}</h3>');
        } else if (line.startsWith('- ')) {
          out.writeln('<li>${_formatInline(line.substring(2))}</li>');
        } else if (line == '---') {
          out.writeln('<hr/>');
        } else if (line.isNotEmpty) {
          out.writeln('<p>${_formatInline(line)}</p>');
        }
      }
    }

    if (inTable) {
      out.writeln('</table>');
    }

    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; padding: 24px; color: #222; max-width: 900px; margin: 0 auto; background: #fff; }
    h1 { color: #d95d00; border-bottom: 2px solid #d95d00; padding-bottom: 8px; }
    h2 { color: #1e232b; margin-top: 24px; border-bottom: 1px solid #ddd; padding-bottom: 4px; }
    h3 { color: #333; margin-top: 16px; }
    table { border-collapse: collapse; width: 100%; margin: 16px 0; font-size: 14px; }
    th, td { border: 1px solid #ccc; padding: 8px 10px; text-align: left; }
    th { background-color: #1e232b; color: #fff; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    li { margin-bottom: 4px; }
  </style>
</head>
<body>
${out.toString()}
</body>
</html>''';
  }

  static String _formatInline(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>')
        .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => '<em>${m[1]}</em>');
  }

  /// Generates the Markdown text for Document 1: Form No. 5 Tour / MKK Route Book (ФСТР 2020)
  static String generatePreTripPassportMarkdown({
    required TripProfile profile,
    required List<Participant> participants,
    required TripCalculationResult? calcResult,
    PlannedRoute? plannedRoute,
    List<WayPoint> waypoints = const [],
  }) {
    final effectiveParticipants = MkkPdfGenerator.resolveEffectiveParticipants(
      participants: participants,
      calcResult: calcResult,
      groupSize: profile.groupSize,
    );

    // Collect all distinct waypoints
    final allWaypoints = <WayPoint>[];
    if (plannedRoute != null) {
      allWaypoints.addAll(plannedRoute.waypoints);
    }
    for (final w in waypoints) {
      if (!allWaypoints.any((existing) =>
          existing.id == w.id ||
          (existing.latitude == w.latitude && existing.longitude == w.longitude))) {
        allWaypoints.add(w);
      }
    }

    final dateFormat = DateFormat('dd.MM.yyyy');
    final sb = StringBuffer();

    final bookNo = profile.routeBookNumber.isNotEmpty ? profile.routeBookNumber : '______';
    final datesStr = (profile.startDate != null && profile.endDate != null)
        ? '${dateFormat.format(profile.startDate!)} – ${dateFormat.format(profile.endDate!)}'
        : 'Сроки: ${profile.durationDays} дн. (с ${dateFormat.format(profile.createdAt)})';

    sb.writeln('# 🇷🇺 ФЕДЕРАЦИЯ СПОРТИВНОГО ТУРИЗМА РОССИИ');
    sb.writeln('## МАРШРУТНАЯ КНИЖКА № $bookNo (ФОРМА № 5 – ТУР)');
    sb.writeln('**Маршрут:** ${profile.title}');
    sb.writeln('**Вид туризма:** ${profile.activityType.displayNameRu} | **Категория сложности:** ${profile.difficultyCategory}');
    sb.writeln('**Район похода:** ${profile.geographicalRegion.isNotEmpty ? profile.geographicalRegion : "Полевой"}');
    sb.writeln('**Сроки похода:** $datesStr');
    if (profile.clubOrCity.isNotEmpty) sb.writeln('**Проводящая организация:** ${profile.clubOrCity}');
    if (profile.mkkName.isNotEmpty) sb.writeln('**Выпускающая МКК:** ${profile.mkkName}');
    if (profile.mchsRegNumber.isNotEmpty) {
      sb.writeln('**Регистрационный номер МЧС (Приказ №42):** ${profile.mchsRegNumber}');
    } else {
      sb.writeln('**Регистрация МЧС:** Требуется подача онлайн-заявки на forms.mchs.ru');
    }
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 1. ОБЩИЕ СВЕДЕНИЯ О МАРШРУТЕ');
    final countWords = '${profile.groupSize} (${MkkPdfGenerator.numberToWordsRu(profile.groupSize)}) чел.';
    sb.writeln('| Параметр | Значение |');
    sb.writeln('|:---|:---|');
    sb.writeln('| Проводящая организация / Клуб | ${profile.clubOrCity.isNotEmpty ? profile.clubOrCity : "Самостоятельная группа"} |');
    sb.writeln('| Состав группы | $countWords |');
    sb.writeln('| Продолжительность | ${profile.durationDays} дней (из них ходовых: ${profile.activeDays}) |');
    sb.writeln('| Протяженность маршрута (активная) | ${profile.totalDistanceKm.toStringAsFixed(1)} км |');
    sb.writeln('| Суммарный набор высоты | +${profile.totalAscentMeters.toStringAsFixed(0)} м |');
    if (calcResult != null) {
      sb.writeln('| Расчетный рацион / калории | ${calcResult.targets.dailyCalories.toStringAsFixed(0)} ккал/чел/день |');
      sb.writeln('| Средний стартовый вес рюкзака | ${calcResult.startPackWeightPerPersonKg.toStringAsFixed(1)} кг (Еда: ${calcResult.totalFoodWeightPerPersonKg.toStringAsFixed(1)} кг) |');
    }
    if (profile.emergencyExitRoutes.isNotEmpty) {
      sb.writeln('| Аварийные сходы и запасные пути | ${profile.emergencyExitRoutes} |');
    }
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 2. СОСТАВ ГРУППЫ И РАСПРЕДЕЛЕНИЕ ОБЯЗАННОСТЕЙ');
    sb.writeln('| № | ФИО участника | Пол | Год | Проживание / Тел. | Экстренный контакт | Опыт / Должность | Диета / Мед |');
    sb.writeln('|:-:|:---|:---:|:---:|:---|:---|:---|:---|');
    for (int i = 0; i < effectiveParticipants.length; i++) {
      final p = effectiveParticipants[i];
      final residence = p.cityRegion.isNotEmpty ? p.cityRegion : '—';
      final phone = p.contactPhone.isNotEmpty ? 'Тел: ${p.contactPhone}' : '';
      final cityAndPhone = phone.isNotEmpty ? '$residence, $phone' : residence;
      final relatives = p.emergencyContactRelatives.isNotEmpty ? p.emergencyContactRelatives : '—';
      final exp = p.touristExperience.isNotEmpty ? '${p.touristExperience}, ${p.role.displayNameRu}' : p.role.displayNameRu;
      final dietMed = MkkPdfGenerator.formatHealthAndDiet(p, forPdf: false);
      final birthYear = p.birthYear != null ? '${p.birthYear}' : '—';

      sb.writeln('| ${i + 1} | **${p.displayName}** | ${p.gender.shortNameRu} | $birthYear | $cityAndPhone | $relatives | $exp | $dietMed |');
    }
    sb.writeln();
    sb.writeln('*Согласие на обработку персональных данных (ФЗ-152 от 27.07.2006) для рассмотрения маршрутных документов получено.*');
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 3.1. ПЛАН И ГРАФИК ДВИЖЕНИЯ ПО МАРШРУТУ');
    final List<PlannedDaySchedule> items = PlannedDaySchedule.generateDefaultSchedule(
      profile: profile,
      plannedRoute: plannedRoute,
      waypoints: allWaypoints,
    );

    sb.writeln('| День | Дата | Участок маршрута (Откуда – Куда) | Км | Способ передвижения | Препятствия / Ночевки |');
    sb.writeln('|:-:|:---:|:---|:---:|:---:|:---|');
    for (final d in items) {
      final dateStr = d.date != null ? dateFormat.format(d.date!) : 'День ${d.dayNumber}';
      final obs = d.obstacles.isNotEmpty ? d.obstacles : '—';
      sb.writeln('| ${d.dayNumber} | $dateStr | ${d.routeSection} | ${d.distanceKm.toStringAsFixed(1)} | ${d.movementType} | $obs |');
    }
    sb.writeln('| | **ИТОГО:** | **Активным способом передвижения** | **${profile.totalDistanceKm.toStringAsFixed(1)}** | **${profile.activityType.displayNameRu}** | |');
    sb.writeln();

    if (allWaypoints.isNotEmpty) {
      sb.writeln('---');
      sb.writeln('## 3.2. КООРДИНАТЫ КОНТРОЛЬНЫХ ТОЧЕК, ПЕРЕВАЛОВ И МЕСТ НОЧЕВОК (WGS-84)');
      sb.writeln('| № | Название точки / Стоянки | Тип | Координаты (WGS-84) | Высота | Описание |');
      sb.writeln('|:-:|:---|:---:|:---:|:-:|:---|');
      for (int i = 0; i < allWaypoints.length; i++) {
        final w = allWaypoints[i];
        final latSign = w.latitude >= 0 ? 'N' : 'S';
        final lonSign = w.longitude >= 0 ? 'E' : 'W';
        final coords = '${w.latitude.abs().toStringAsFixed(5)}° $latSign, ${w.longitude.abs().toStringAsFixed(5)}° $lonSign';
        final desc = (w.note != null && w.note!.isNotEmpty)
            ? w.note!
            : (w.authorName != null ? 'Автор: ${w.authorName}' : '—');
        sb.writeln('| ${i + 1} | **${w.title}** | ${w.type.displayNameRu} | $coords | ${w.altitude.round()} м | $desc |');
      }
      sb.writeln();
    }

    if (calcResult != null) {
      sb.writeln('---');
      sb.writeln('## 4. МАТЕРИАЛЬНОЕ ОБЕСПЕЧЕНИЕ И ВЕСОВЫЕ ХАРАКТЕРИСТИКИ (п. 4.6)');

      final males = effectiveParticipants.where((p) => p.gender == Gender.male).toList();
      final females = effectiveParticipants.where((p) => p.gender == Gender.female).toList();
      Participant? maxMale;
      for (final p in males) {
        if (maxMale == null || p.totalPackWeightKg > maxMale.totalPackWeightKg) maxMale = p;
      }
      Participant? maxFemale;
      for (final p in females) {
        if (maxFemale == null || p.totalPackWeightKg > maxFemale.totalPackWeightKg) maxFemale = p;
      }
      final totalFoodGrams = (calcResult.totalFoodWeightAllGroupKg * 1000).round();
      final foodPerPersonDayGrams = (totalFoodGrams / (profile.groupSize * profile.durationDays)).round();

      sb.writeln('| Наименование груза | На 1 человека | На группу (${profile.groupSize} чел) | Норматив / Примечание |');
      sb.writeln('|:---|:---:|:---:|:---|');
      sb.writeln('| Продукты питания (всего) | ${calcResult.totalFoodWeightPerPersonKg.toStringAsFixed(2)} кг | ${calcResult.totalFoodWeightAllGroupKg.toStringAsFixed(2)} кг | $foodPerPersonDayGrams г/чел/день |');
      sb.writeln('| Групповое снаряжение | ${calcResult.groupGearWeightPerPersonKg.toStringAsFixed(2)} кг | ${calcResult.totalGroupGearWeightKg.toStringAsFixed(2)} кг | Костры, палатки, связь |');
      sb.writeln('| Личное снаряжение | ${calcResult.totalPersonalGearWeightKg.toStringAsFixed(2)} кг | ${(calcResult.totalPersonalGearWeightKg * profile.groupSize).toStringAsFixed(2)} кг | Одежда, спальник, КЛМН |');
      sb.writeln('| **ИТОГО стартовый вес** | **${calcResult.startPackWeightPerPersonKg.toStringAsFixed(2)} кг** | **${(calcResult.startPackWeightPerPersonKg * profile.groupSize).toStringAsFixed(2)} кг** | **+1.5 л воды на старте** |');
      sb.writeln();
      sb.writeln('- **Максимальная нагрузка на 1 мужчину:** ${maxMale != null ? "${maxMale.totalPackWeightKg.toStringAsFixed(1)} кг (${maxMale.displayName})" : "В группе нет мужчин"}');
      sb.writeln('- **Максимальная нагрузка на 1 женщину:** ${maxFemale != null ? "${maxFemale.totalPackWeightKg.toStringAsFixed(1)} кг (${maxFemale.displayName})" : "В группе нет женщин"}');
      sb.writeln();

      sb.writeln('### Персональная весовая ведомость («Кто что несёт»)');
      sb.writeln('| № | Участник | Сила | Личное (кг) | Групп. снаряжение (кг) | Паек питания (кг) | ИТОГО на старте (кг) |');
      sb.writeln('|:-:|:---|:---:|:-:|:-:|:-:|:-:|');
      for (int i = 0; i < effectiveParticipants.length; i++) {
        final p = effectiveParticipants[i];
        sb.writeln('| ${i + 1} | ${p.displayName} | ${p.strengthRatio}x | ${p.personalGearWeightKg.toStringAsFixed(2)} | ${p.assignedGroupGearWeightKg.toStringAsFixed(2)} | ${p.assignedFoodWeightKg.toStringAsFixed(2)} | **${p.totalPackWeightKg.toStringAsFixed(2)}** |');
      }
      sb.writeln();
    }

    sb.writeln('---');
    sb.writeln('## 6. КОНТРОЛЬНЫЕ ПУНКТЫ, СРОКИ И СВЯЗЬ НА МАРШРУТЕ');
    final coordName = profile.coordinatorName.isNotEmpty ? profile.coordinatorName : 'Не назначен';
    final coordPhone = profile.coordinatorPhone.isNotEmpty ? profile.coordinatorPhone : '—';
    final coordEmail = profile.coordinatorEmail.isNotEmpty ? profile.coordinatorEmail : '—';
    sb.writeln('- **Координатор группы в городе:** $coordName (Тел: $coordPhone, Email: $coordEmail)');
    sb.writeln('- **Средства связи на маршруте:** ${profile.satellitePhone.isNotEmpty ? profile.satellitePhone : "Сотовая связь по зонам покрытия"}');
    sb.writeln('- **График и время сеансов связи:** ${profile.communicationSchedule.isNotEmpty ? profile.communicationSchedule : "Ежедневно в 20:00 (SMS)"}');
    sb.writeln('- **Региональный орган МЧС:** ${profile.mchsRegNumber.isNotEmpty ? "Регистрация № ${profile.mchsRegNumber}" : "forms.mchs.ru"}');
    sb.writeln();

    sb.writeln('---');
    sb.writeln('## 7–10. ЗАКЛЮЧЕНИЯ И ОТМЕТКИ МКК И МЧС');
    sb.writeln('Группа к прохождению маршрута: **[ ] ДОПУЩЕНА   [ ] НЕ ДОПУЩЕНА**');
    sb.writeln('Председатель МКК: _______________________ (___________________)');
    sb.writeln('Члены МКК: _______________________________ (___________________)');
    sb.writeln('М.П. / ШТАМП МКК');
    sb.writeln();

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
        final weatherStr = note.weather != null && note.weather!.isNotEmpty ? 'Погода: ${note.weather}' : 'Погода: Ясно';
        sb.writeln('### Лагерь (День ${note.dayNumber}) • $weatherStr');
        if (note.text.isNotEmpty) sb.writeln(note.text);
        sb.writeln();
      }
    }

    return sb.toString();
  }
}
