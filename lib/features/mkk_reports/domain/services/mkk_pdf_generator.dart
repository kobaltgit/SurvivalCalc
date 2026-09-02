import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/group_distribution/domain/services/load_distribution_service.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/planned_day_schedule.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class MkkPdfGenerator {
  static const PdfColor primaryOrange = PdfColor.fromInt(0xFFFF7300);
  static const PdfColor darkHeader = PdfColor.fromInt(0xFF1E232B);
  static const PdfColor alternateRowBg = PdfColor.fromInt(0xFFF4F6F8);
  static const PdfColor borderGray = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor subtleBg = PdfColor.fromInt(0xFFF9FAFB);

  static pw.Font? _cachedFont;

  static Future<pw.Font> _resolveFont() async {
    if (_cachedFont != null) return _cachedFont!;
    try {
      final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      _cachedFont = pw.Font.ttf(data);
      return _cachedFont!;
    } catch (_) {
      try {
        _cachedFont = await PdfGoogleFonts.robotoRegular();
        return _cachedFont!;
      } catch (_) {
        return pw.Font.helvetica();
      }
    }
  }

  static String numberToWordsRu(int n) {
    const words = [
      'ноль', 'один', 'два', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять',
      'десять', 'одиннадцать', 'двенадцать', 'тринадцать', 'четырнадцать', 'пятнадцать',
      'шестнадцать', 'семнадцать', 'восемнадцать', 'девятнадцать', 'двадцать'
    ];
    if (n >= 0 && n < words.length) return words[n];
    return n.toString();
  }

  /// Automatically ensures participants have distributed gear and food if not already distributed
  static List<Participant> resolveEffectiveParticipants({
    required List<Participant> participants,
    required TripCalculationResult? calcResult,
    required int groupSize,
  }) {
    if (calcResult == null) return participants;

    if (calcResult.participants.isNotEmpty &&
        calcResult.participants.any((p) => p.assignedGear.isNotEmpty || p.assignedFood.isNotEmpty)) {
      return calcResult.participants;
    }

    List<Participant> list = List.from(participants);
    if (list.isEmpty || list.length != groupSize) {
      list = List.generate(groupSize, (i) {
        final id = 'p_${i + 1}';
        final existing = participants.where((p) => p.id == id).firstOrNull;
        return existing ??
            Participant(
              id: id,
              name: 'Участник ${i + 1}',
              strengthRatio: 1.0,
            );
      });
    }

    final needsAutoDistribute = list.every((p) => p.assignedGear.isEmpty && p.assignedFood.isEmpty);
    if (needsAutoDistribute) {
      return const LoadDistributionService().autoDistribute(
        participants: list,
        allGear: calcResult.gearList,
        shoppingList: calcResult.shoppingList,
        personalGearWeightKg: calcResult.totalPersonalGearWeightKg,
      );
    }
    return list;
  }

  /// Formats dietary and medical needs
  static String formatHealthAndDiet(Participant p, {bool forPdf = true}) {
    final parts = <String>[];
    if (p.hasSpecialDiet) {
      final diets = p.dietaryRestrictions
          .where((d) => d != DietaryRestriction.none)
          .map((d) => d.displayNameRu)
          .join(', ');
      parts.add('Диета: $diets');
    }
    if (p.hasMedicalNeeds) {
      final meds = p.medicalConditions
          .where((m) => m != MedicalCondition.none)
          .map((m) => m.displayNameRu)
          .join(', ');
      parts.add('Мед: $meds');
    }
    return parts.isEmpty ? 'Стандарт' : parts.join(forPdf ? '\n' : ', ');
  }

  /// Generates PDF bytes for Document 1: Pre-Trip Route Passport / MKK Route Book (Form No. 5 Tour)
  static Future<Uint8List> generatePreTripPassportPdf({
    required TripProfile profile,
    required List<Participant> participants,
    required TripCalculationResult? calcResult,
    pw.Font? regularFont,
    pw.Font? boldFont,
    pw.Font? italicFont,
  }) async {
    final effectiveParticipants = resolveEffectiveParticipants(
      participants: participants,
      calcResult: calcResult,
      groupSize: profile.groupSize,
    );

    final pdf = pw.Document(
      title: 'Маршрутная книжка - ${profile.title}',
      author: 'SurvivalCalc (ФСТР Форма №5)',
    );
    final font = regularFont ?? await _resolveFont();
    final fontBold = boldFont ?? font;
    final fontItalic = italicFont ?? font;
    final dateFormat = DateFormat('dd.MM.yyyy');

    final baseTheme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: fontItalic,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: baseTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => _buildHeader('ФОРМА № 5 – ТУР (МАРШРУТНАЯ КНИЖКА ФСТР)', profile.title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // 0. Official Title Block & Legal / MCHS Header
          _buildFstrTitleBlock(profile, dateFormat),
          pw.SizedBox(height: 12),

          // 1. General Info (Section 1)
          _buildSectionHeader('1. ОБЩИЕ СВЕДЕНИЯ О МАРШРУТЕ'),
          _buildRouteOverviewTable(profile, calcResult, dateFormat),
          pw.SizedBox(height: 14),

          // 2. Group Composition (Section 2)
          _buildSectionHeader('2. СОСТАВ ГРУППЫ И РАСПРЕДЕЛЕНИЕ ОБЯЗАННОСТЕЙ'),
          _buildGroupMembersTable(effectiveParticipants),
          pw.SizedBox(height: 4),
          pw.Text(
            '* Согласие на обработку персональных данных (ФЗ-152 от 27.07.2006) для рассмотрения маршрутных документов получено.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 14),

          // 3. Planned Itinerary (Section 3)
          _buildSectionHeader('3. ПЛАН И ГРАФИК ДВИЖЕНИЯ ПО МАРШРУТУ'),
          _buildPlannedItineraryTable(profile, dateFormat),
          pw.SizedBox(height: 14),

          // 4. Material Support & Weight Characteristics (Section 4 & 4.6)
          _buildSectionHeader('4. МАТЕРИАЛЬНОЕ ОБЕСПЕЧЕНИЕ И ВЕСОВЫЕ ХАРАКТЕРИСТИКИ (п. 4.6)'),
          _buildMkkWeightCharacteristicsSection(profile, effectiveParticipants, calcResult),
          pw.SizedBox(height: 10),
          _buildSectionHeader('Персональная весовая ведомость («Кто что несёт»)'),
          _buildWeightDistributionTable(effectiveParticipants),
          pw.SizedBox(height: 14),

          // 5. Emergency Contacts, Coordinator & Communication (Section 6)
          _buildSectionHeader('6. КОНТРОЛЬНЫЕ ПУНКТЫ, СРОКИ И СВЯЗЬ НА МАРШРУТЕ'),
          _buildCommunicationAndCoordinatorSection(profile),
          pw.SizedBox(height: 14),

          // 6. MKK Decisions & Approval Box (Sections 7-10)
          _buildSectionHeader('7–10. ЗАКЛЮЧЕНИЯ И ОТМЕТКИ МКК И МЧС'),
          _buildMkkSignaturesAndApprovalSection(profile),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates PDF bytes for Document 2: Post-Trip Technical Report
  static Future<Uint8List> generatePostTripReportPdf({
    required TripProfile profile,
    required List<Participant> participants,
    required List<DailyTrack> tracks,
    required List<WayPoint> waypoints,
    required List<DailyCampNote> campNotes,
    pw.Font? regularFont,
    pw.Font? boldFont,
    pw.Font? italicFont,
  }) async {
    final pdf = pw.Document(title: 'Итоговый отчет - ${profile.title}', author: 'SurvivalCalc');
    final font = regularFont ?? await _resolveFont();
    final fontBold = boldFont ?? font;
    final fontItalic = italicFont ?? font;
    final dateFormat = DateFormat('dd.MM.yyyy');

    final baseTheme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: fontItalic,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: baseTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => _buildHeader('ИТОГОВЫЙ ТЕХНИЧЕСКИЙ ОТЧЕТ О ПОХОДЕ', profile.title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitleSection(profile, dateFormat, isReport: true),
          pw.SizedBox(height: 14),
          _buildPlanFactTable(profile, tracks),
          pw.SizedBox(height: 18),
          _buildSectionHeader('1. График фактического движения по дням'),
          _buildTracksTable(tracks),
          pw.SizedBox(height: 18),
          if (waypoints.isNotEmpty) ...[
            _buildSectionHeader('2. Паспорт путевых точек и препятствий'),
            _buildWaypointsTable(waypoints),
            pw.SizedBox(height: 18),
          ],
          if (campNotes.isNotEmpty) ...[
            _buildSectionHeader('3. Дневник лагеря и метеорологические наблюдения'),
            _buildCampNotesSection(campNotes),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // --- PDF WIDGET BUILDERS ---

  static pw.Widget _buildHeader(String documentType, String tripTitle) {
    final truncatedTitle = tripTitle.length > 40 ? '${tripTitle.substring(0, 37)}...' : tripTitle;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryOrange, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('SurvivalCalc • ЭКСПЕДИЦИОННЫЙ ПАКЕТ',
              style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Text(
              '$documentType • $truncatedTitle',
              textAlign: pw.TextAlign.right,
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderGray, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Сгенерировано в SurvivalCalc (100% Offline Assistant)',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Стр. ${context.pageNumber} из ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF3F4F6),
        border: pw.Border(left: pw.BorderSide(color: primaryOrange, width: 3.5)),
      ),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkHeader)),
    );
  }

  /// Official FSTR Title Block (Form No. 5 Tour) with modern SurvivalCalc styling
  static pw.Widget _buildFstrTitleBlock(TripProfile profile, DateFormat dateFormat) {
    final bookNo = profile.routeBookNumber.isNotEmpty ? profile.routeBookNumber : '______';
    final datesStr = (profile.startDate != null && profile.endDate != null)
        ? '${dateFormat.format(profile.startDate!)} – ${dateFormat.format(profile.endDate!)}'
        : 'Сроки: ${profile.durationDays} дн. (с ${dateFormat.format(profile.createdAt)})';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: alternateRowBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderGray, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ФЕДЕРАЦИЯ СПОРТИВНОГО ТУРИЗМА РОССИИ',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.Text('МАРШРУТНАЯ КНИЖКА № $bookNo',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryOrange)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: darkHeader,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'Форма № 5 – Тур',
                  style: pw.TextStyle(fontSize: 8.5, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Маршрут: ${profile.title}', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Вид туризма: ${profile.activityType.displayNameRu}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Категория сложности: ${profile.difficultyCategory}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Район: ${profile.geographicalRegion.isNotEmpty ? profile.geographicalRegion : "Полевой"}', style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Сроки похода: $datesStr', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Организация: ${profile.clubOrCity.isNotEmpty ? profile.clubOrCity : "Не указано"}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Выпускающая МКК: ${profile.mkkName.isNotEmpty ? profile.mkkName : "Не указана"}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                      'Рег. МЧС (Приказ №42): ${profile.mchsRegNumber.isNotEmpty ? profile.mchsRegNumber : "Требуется подача на forms.mchs.ru"}',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        color: profile.mchsRegNumber.isNotEmpty ? PdfColors.green800 : PdfColors.red800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleSection(TripProfile profile, DateFormat dateFormat, {bool isReport = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: alternateRowBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderGray, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isReport ? 'ИТОГОВЫЙ ТЕХНИЧЕСКИЙ ОТЧЕТ О ПОХОДЕ' : 'МАРШРУТНАЯ КНИЖКА / ПАСПОРТ МАРШРУТА',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryOrange),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Маршрут: ${profile.title}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Категория: ${profile.difficultyCategory}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Район: ${profile.geographicalRegion.isNotEmpty ? profile.geographicalRegion : "Полевой"}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Клуб/Организация: ${profile.clubOrCity.isNotEmpty ? profile.clubOrCity : "Не указано"}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Сезон: ${profile.season.displayNameRu}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Вид туризма: ${profile.activityType.displayNameRu}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Дата: ${dateFormat.format(profile.createdAt)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRouteOverviewTable(TripProfile profile, TripCalculationResult? calcResult, DateFormat dateFormat) {
    final caloriesStr = calcResult != null ? '${calcResult.targets.dailyCalories.toStringAsFixed(0)} ккал/чел/день' : '—';
    final packWeightStr = calcResult != null
        ? '${calcResult.startPackWeightPerPersonKg.toStringAsFixed(1)} кг (Еда: ${calcResult.totalFoodWeightPerPersonKg.toStringAsFixed(1)} кг)'
        : '—';
    final countWords = '${profile.groupSize} (${numberToWordsRu(profile.groupSize)}) чел.';

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      children: [
        _buildTableRow(['Параметр', 'Значение'], isHeader: true),
        _buildTableRow(['Проводящая организация / Клуб', profile.clubOrCity.isNotEmpty ? profile.clubOrCity : 'Самостоятельная группа']),
        _buildTableRow(['Состав группы', countWords]),
        _buildTableRow(['Продолжительность похода', '${profile.durationDays} дней (из них ходовых: ${profile.activeDays})']),
        _buildTableRow(['Протяженность маршрута (активная)', '${profile.totalDistanceKm.toStringAsFixed(1)} км']),
        _buildTableRow(['Суммарный набор высоты', '+${profile.totalAscentMeters.toStringAsFixed(0)} м']),
        _buildTableRow(['Расчетный рацион / калории', caloriesStr]),
        _buildTableRow(['Средний стартовый вес рюкзака', packWeightStr]),
        if (profile.emergencyExitRoutes.isNotEmpty)
          _buildTableRow(['Аварийные сходы и запасные пути', profile.emergencyExitRoutes]),
      ],
    );
  }

  static pw.Widget _buildGroupMembersTable(List<Participant> participants) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FixedColumnWidth(30),
        3: const pw.FixedColumnWidth(32),
        4: const pw.FlexColumnWidth(2.0),
        5: const pw.FlexColumnWidth(2.0),
        6: const pw.FlexColumnWidth(1.8),
        7: const pw.FlexColumnWidth(1.6),
      },
      children: [
        _buildTableRow(
          ['№', 'ФИО участника', 'Пол', 'Год', 'Проживание / Тел.', 'Экстренный контакт', 'Опыт / Должность', 'Диета/Мед'],
          isHeader: true,
        ),
        ...participants.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final residence = p.cityRegion.isNotEmpty ? p.cityRegion : '—';
          final phoneStr = p.contactPhone.isNotEmpty ? p.contactPhone : '';
          final cityAndPhone = phoneStr.isNotEmpty ? '$residence\nТел: $phoneStr' : residence;
          final relativeContact = p.emergencyContactRelatives.isNotEmpty ? p.emergencyContactRelatives : '—';
          final expParts = <String>[];
          if (p.touristExperience.isNotEmpty) expParts.add(p.touristExperience);
          expParts.add(p.role.displayNameRu);
          final expStr = expParts.join('\n');
          final dietAndHealth = formatHealthAndDiet(p, forPdf: true);
          final birthYearStr = p.birthYear != null ? '${p.birthYear}' : '—';

          return _buildTableRow(
            [
              '${i + 1}',
              p.displayName,
              p.gender.shortNameRu,
              birthYearStr,
              cityAndPhone,
              relativeContact,
              expStr,
              dietAndHealth,
            ],
            isAlt: i % 2 == 1,
          );
        }),
      ],
    );
  }

  /// Planned Itinerary Table (Section 3)
  static pw.Widget _buildPlannedItineraryTable(TripProfile profile, DateFormat dateFormat) {
    final List<PlannedDaySchedule> items = profile.plannedItinerary.isNotEmpty
        ? profile.plannedItinerary
        : List.generate(profile.activeDays, (index) {
            final dayNum = index + 1;
            final dist = (profile.totalDistanceKm / (profile.activeDays > 0 ? profile.activeDays : 1));
            return PlannedDaySchedule(
              dayNumber: dayNum,
              date: profile.startDate?.add(Duration(days: index)),
              routeSection: 'Ходовой переход $dayNum (участок маршрута)',
              distanceKm: dist,
              movementType: profile.activityType.displayNameRu,
              obstacles: 'Полевой рельеф',
            );
          });

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FixedColumnWidth(55),
        2: const pw.FlexColumnWidth(3.0),
        3: const pw.FixedColumnWidth(35),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(2.0),
      },
      children: [
        _buildTableRow(
          ['День', 'Дата', 'Участок маршрута (Откуда – Куда)', 'Км', 'Способ', 'Препятствия / Ночевки'],
          isHeader: true,
        ),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final dateStr = d.date != null ? dateFormat.format(d.date!) : 'День ${d.dayNumber}';
          return _buildTableRow(
            [
              '${d.dayNumber}',
              dateStr,
              d.routeSection,
              d.distanceKm.toStringAsFixed(1),
              d.movementType,
              d.obstacles.isNotEmpty ? d.obstacles : '—',
            ],
            isAlt: i % 2 == 1,
          );
        }),
        _buildTableRow(
          ['', 'ИТОГО:', 'Активным способом передвижения', profile.totalDistanceKm.toStringAsFixed(1), profile.activityType.displayNameRu, ''],
          isHeader: true,
        ),
      ],
    );
  }

  /// Material Support and Weight Table (Section 4 & 4.6 FSTR Standard)
  static pw.Widget _buildMkkWeightCharacteristicsSection(
    TripProfile profile,
    List<Participant> participants,
    TripCalculationResult? calcResult,
  ) {
    if (calcResult == null) return pw.SizedBox();

    // Calculate max weights for male and female
    final males = participants.where((p) => p.gender == Gender.male).toList();
    final females = participants.where((p) => p.gender == Gender.female).toList();

    Participant? maxMale;
    for (final p in males) {
      if (maxMale == null || p.totalPackWeightKg > maxMale.totalPackWeightKg) {
        maxMale = p;
      }
    }

    Participant? maxFemale;
    for (final p in females) {
      if (maxFemale == null || p.totalPackWeightKg > maxFemale.totalPackWeightKg) {
        maxFemale = p;
      }
    }

    final totalFoodGrams = (calcResult.totalFoodWeightAllGroupKg * 1000).round();
    final foodPerPersonDayGrams = (totalFoodGrams / (profile.groupSize * profile.durationDays)).round();

    final maxMaleStr = maxMale != null
        ? '${maxMale.totalPackWeightKg.toStringAsFixed(1)} кг (${maxMale.displayName})'
        : 'В группе нет мужчин';
    final maxFemaleStr = maxFemale != null
        ? '${maxFemale.totalPackWeightKg.toStringAsFixed(1)} кг (${maxFemale.displayName})'
        : 'В группе нет женщин';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: borderGray, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.8),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(2.0),
          },
          children: [
            _buildTableRow(['Наименование груза', 'На 1 человека', 'На всю группу (${profile.groupSize} чел)', 'Норматив / Примечание'], isHeader: true),
            _buildTableRow([
              'Продукты питания (всего)',
              '${calcResult.totalFoodWeightPerPersonKg.toStringAsFixed(2)} кг',
              '${calcResult.totalFoodWeightAllGroupKg.toStringAsFixed(2)} кг',
              '$foodPerPersonDayGrams г/чел/день',
            ]),
            _buildTableRow([
              'Групповое снаряжение',
              '${calcResult.groupGearWeightPerPersonKg.toStringAsFixed(2)} кг',
              '${calcResult.totalGroupGearWeightKg.toStringAsFixed(2)} кг',
              'Костры, палатки, связь',
            ]),
            _buildTableRow([
              'Личное снаряжение',
              '${calcResult.totalPersonalGearWeightKg.toStringAsFixed(2)} кг',
              '${(calcResult.totalPersonalGearWeightKg * profile.groupSize).toStringAsFixed(2)} кг',
              'Одежда, спальник, КЛМН',
            ]),
            _buildTableRow([
              'ИТОГО стартовый вес груза',
              '${calcResult.startPackWeightPerPersonKg.toStringAsFixed(2)} кг',
              '${(calcResult.startPackWeightPerPersonKg * profile.groupSize).toStringAsFixed(2)} кг',
              '+1.5 л воды на старте',
            ], isHeader: true),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: subtleBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: borderGray, width: 0.5),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('• Максимальная нагрузка на 1 мужчину: $maxMaleStr',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkHeader)),
              ),
              pw.Expanded(
                child: pw.Text('• Максимальная нагрузка на 1 женщину: $maxFemaleStr',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkHeader)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildWeightDistributionTable(List<Participant> participants) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.8),
      },
      children: [
        _buildTableRow(
          ['№', 'Участник', 'Сила', 'Личное (кг)', 'Групповое (кг)', 'Питание (кг)', 'ИТОГО на старте'],
          isHeader: true,
        ),
        ...participants.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return _buildTableRow(
            [
              '${i + 1}',
              p.displayName,
              '${p.strengthRatio}x',
              p.personalGearWeightKg.toStringAsFixed(2),
              p.assignedGroupGearWeightKg.toStringAsFixed(2),
              p.assignedFoodWeightKg.toStringAsFixed(2),
              '${p.totalPackWeightKg.toStringAsFixed(2)} кг',
            ],
            isAlt: i % 2 == 1,
          );
        }),
      ],
    );
  }

  static pw.Widget _buildCommunicationAndCoordinatorSection(TripProfile profile) {
    final coordName = profile.coordinatorName.isNotEmpty ? profile.coordinatorName : 'Не назначен';
    final coordPhone = profile.coordinatorPhone.isNotEmpty ? profile.coordinatorPhone : '—';
    final coordEmail = profile.coordinatorEmail.isNotEmpty ? profile.coordinatorEmail : '—';
    final satPhone = profile.satellitePhone.isNotEmpty ? profile.satellitePhone : 'Сотовая связь по зонам покрытия';
    final sched = profile.communicationSchedule.isNotEmpty ? profile.communicationSchedule : 'Ежедневно в 20:00 (SMS)';

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      children: [
        _buildTableRow(['Реквизит связи', 'Контакты и параметры'], isHeader: true),
        _buildTableRow(['Координатор группы в городе', '$coordName (Тел: $coordPhone, Email: $coordEmail)']),
        _buildTableRow(['Средства связи группы на маршруте', satPhone]),
        _buildTableRow(['График и время сеансов связи', sched]),
        _buildTableRow(['Региональный орган МЧС / ПСС', profile.mchsRegNumber.isNotEmpty ? 'Регистрация № ${profile.mchsRegNumber}' : 'forms.mchs.ru']),
      ],
    );
  }

  static pw.Widget _buildMkkSignaturesAndApprovalSection(TripProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGray, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('8–9. ЗАКЛЮЧЕНИЕ МКК О ВЫПУСКЕ:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkHeader)),
                pw.SizedBox(height: 4),
                pw.Text('Группа к прохождению маршрута: [  ] ДОПУЩЕНА   [  ] НЕ ДОПУЩЕНА', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 6),
                pw.Text('Председатель МКК: _________________ (                       )', style: const pw.TextStyle(fontSize: 7.5)),
                pw.SizedBox(height: 4),
                pw.Text('Члены МКК: _______________________ (                       )', style: const pw.TextStyle(fontSize: 7.5)),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: 100,
            height: 55,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 0.8, style: pw.BorderStyle.dashed),
            ),
            child: pw.Center(
              child: pw.Text('М.П. / ШТАМП МКК', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Post-Trip Report Helpers ---

  static pw.Widget _buildPlanFactTable(TripProfile profile, List<DailyTrack> tracks) {
    final actualDist = tracks.fold<double>(0.0, (sum, t) => sum + t.totalDistanceKm);
    final actualAscent = tracks.fold<double>(0.0, (sum, t) => sum + t.elevationGainMeters);
    final actualMovingSec = tracks.fold<int>(0, (sum, t) => sum + t.movingDurationSeconds);
    final hours = (actualMovingSec / 3600.0).toStringAsFixed(1);

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      children: [
        _buildTableRow(['Параметр маршрута', 'План', 'Факт', 'Отклонение'], isHeader: true),
        _buildTableRow([
          'Дистанция (км)',
          profile.totalDistanceKm.toStringAsFixed(1),
          actualDist.toStringAsFixed(1),
          (actualDist - profile.totalDistanceKm) >= 0
              ? '+${(actualDist - profile.totalDistanceKm).toStringAsFixed(1)}'
              : (actualDist - profile.totalDistanceKm).toStringAsFixed(1),
        ]),
        _buildTableRow([
          'Набор высоты (м)',
          profile.totalAscentMeters.toStringAsFixed(0),
          actualAscent.toStringAsFixed(0),
          (actualAscent - profile.totalAscentMeters) >= 0
              ? '+${(actualAscent - profile.totalAscentMeters).toStringAsFixed(0)}'
              : (actualAscent - profile.totalAscentMeters).toStringAsFixed(0),
        ]),
        _buildTableRow([
          'Ходовых дней',
          '${profile.activeDays}',
          '${tracks.length}',
          '${tracks.length - profile.activeDays}',
        ]),
        _buildTableRow([
          'Чистое ходовое время',
          '—',
          '$hours ч',
          '—',
        ]),
      ],
    );
  }

  static pw.Widget _buildTracksTable(List<DailyTrack> tracks) {
    if (tracks.isEmpty) {
      return pw.Text('Фактические треки пока не записаны.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      children: [
        _buildTableRow(['День', 'Трек / Участок', 'Км', 'Набор', 'Сброс', 'Время', 'Ср. скор.'], isHeader: true),
        ...tracks.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final h = t.movingDurationSeconds ~/ 3600;
          final m = (t.movingDurationSeconds % 3600) ~/ 60;
          return _buildTableRow([
            '${i + 1}',
            t.title,
            t.totalDistanceKm.toStringAsFixed(1),
            '+${t.elevationGainMeters.toStringAsFixed(0)} м',
            '-${t.elevationLossMeters.toStringAsFixed(0)} м',
            '$hч $mм',
            '${t.avgMovingSpeedKmh.toStringAsFixed(1)} км/ч',
          ], isAlt: i % 2 == 1);
        }),
      ],
    );
  }

  static pw.Widget _buildWaypointsTable(List<WayPoint> waypoints) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      children: [
        _buildTableRow(['№', 'Название точки', 'Тип', 'Координаты', 'Высота', 'Фото'], isHeader: true),
        ...waypoints.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          return _buildTableRow([
            '${i + 1}',
            w.title,
            w.type.displayNameRu,
            '${w.latitude.toStringAsFixed(4)}, ${w.longitude.toStringAsFixed(4)}',
            '${w.altitude.toStringAsFixed(0)} м',
            w.photoPath != null && w.photoPath!.isNotEmpty ? '📷 Есть' : '—',
          ], isAlt: i % 2 == 1);
        }),
      ],
    );
  }

  static pw.Widget _buildCampNotesSection(List<DailyCampNote> campNotes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: campNotes.map((n) {
        final weatherStr = n.weather != null && n.weather!.isNotEmpty ? 'Погода: ${n.weather}' : 'Погода: Ясно';
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: alternateRowBg,
            border: pw.Border.all(color: borderGray, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Лагерь / Стоянка (День ${n.dayNumber}) • $weatherStr',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkHeader)),
              if (n.text.isNotEmpty) pw.Text(n.text, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.TableRow _buildTableRow(List<String> cells, {bool isHeader = false, bool isAlt = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHeader
            ? darkHeader
            : isAlt
                ? alternateRowBg
                : PdfColors.white,
      ),
      children: cells.map((c) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
          child: pw.Text(
            c,
            style: pw.TextStyle(
              fontSize: isHeader ? 8.5 : 8,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.white : darkHeader,
            ),
          ),
        );
      }).toList(),
    );
  }
}
