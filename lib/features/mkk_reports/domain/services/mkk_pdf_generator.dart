import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/group_distribution/domain/services/load_distribution_service.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class MkkPdfGenerator {
  static const PdfColor primaryOrange = PdfColor.fromInt(0xFFFF7300);
  static const PdfColor darkHeader = PdfColor.fromInt(0xFF1E232B);
  static const PdfColor alternateRowBg = PdfColor.fromInt(0xFFF4F6F8);
  static const PdfColor borderGray = PdfColor.fromInt(0xFFD1D5DB);

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

  /// Generates PDF bytes for Document 1: Pre-Trip Route Passport / MKK Route Book
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

    final pdf = pw.Document(title: 'Маршрутная книжка - ${profile.title}', author: 'SurvivalCalc');
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
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader('МАРШРУТНАЯ КНИЖКА / ЗАЯВКА В МКК', profile.title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitleSection(profile, dateFormat),
          pw.SizedBox(height: 14),
          _buildRouteOverviewTable(profile, calcResult),
          pw.SizedBox(height: 18),
          _buildSectionHeader('1. Состав группы и распределение обязанностей'),
          _buildGroupMembersTable(effectiveParticipants),
          pw.SizedBox(height: 18),
          _buildSectionHeader('2. Сводная весовая ведомость («Кто что несёт»)'),
          _buildWeightDistributionTable(effectiveParticipants),
          pw.SizedBox(height: 18),
          if (calcResult != null) ...[
            _buildSectionHeader('3. Параметры рациона и обеспечение безопасности'),
            _buildNutritionAndSafetySection(profile, calcResult),
          ],
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
        margin: const pw.EdgeInsets.all(32),
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

  // Helper widgets for PDF generation

  static pw.Widget _buildHeader(String documentType, String tripTitle) {
    final truncatedTitle = tripTitle.length > 40 ? '${tripTitle.substring(0, 37)}...' : tripTitle;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
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
      margin: const pw.EdgeInsets.only(top: 14),
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
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF3F4F6),
        border: pw.Border(left: pw.BorderSide(color: primaryOrange, width: 3.5)),
      ),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkHeader)),
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

  static pw.Widget _buildRouteOverviewTable(TripProfile profile, TripCalculationResult? calcResult) {
    final caloriesStr = calcResult != null ? '${calcResult.targets.dailyCalories.toStringAsFixed(0)} ккал/чел/день' : '—';
    final packWeightStr = calcResult != null
        ? '${calcResult.startPackWeightPerPersonKg.toStringAsFixed(1)} кг (Еда: ${calcResult.totalFoodWeightPerPersonKg.toStringAsFixed(1)} кг)'
        : '—';

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _tableCell('Продолжительность', '${profile.durationDays} дн. (ходовых: ${profile.activeDays} дн.)'),
            _tableCell('Протяженность', '${profile.totalDistanceKm.toStringAsFixed(1)} км'),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: alternateRowBg),
          children: [
            _tableCell('Суммарный набор высоты', '${profile.totalAscentMeters.toStringAsFixed(0)} м'),
            _tableCell('Состав группы', '${profile.groupSize} чел.'),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _tableCell('Суточный калораж', caloriesStr),
            _tableCell('Стартовый вес рюкзака (ср.)', packWeightStr),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          text: '$title: ',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkHeader),
          children: [
            pw.TextSpan(text: value, style: pw.TextStyle(fontWeight: pw.FontWeight.normal, color: PdfColors.black)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildGroupMembersTable(List<Participant> participants) {
    final headers = ['№', 'ФИО / Имя', 'Должность', 'Вес', 'Сила', 'Туристский опыт / Телефон', 'Диеты / Здоровье'];
    final data = participants.asMap().entries.map((e) {
      final idx = e.key + 1;
      final p = e.value;
      final expParts = <String>[];
      if (p.touristExperience.isNotEmpty) expParts.add('Опыт: ${p.touristExperience}');
      if (p.contactPhone.isNotEmpty) expParts.add('Тел: ${p.contactPhone}');
      final exp = expParts.isNotEmpty ? expParts.join('\n') : '—';
      final diet = p.dietaryRestrictions.map((d) => d.displayNameRu).join(', ');
      return [
        '$idx',
        p.displayName,
        p.role.displayNameRu,
        '${p.weightKg.toStringAsFixed(0)} кг',
        '${p.strengthRatio}x',
        exp,
        diet,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: darkHeader),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: alternateRowBg),
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
    );
  }

  static pw.Widget _buildWeightDistributionTable(List<Participant> participants) {
    final headers = ['№', 'Участник', 'Личное', 'Групповое', 'Продукты', 'ИТОГО на старте'];
    final data = participants.asMap().entries.map((e) {
      final idx = e.key + 1;
      final p = e.value;
      return [
        '$idx',
        p.displayName,
        '${p.personalGearWeightKg.toStringAsFixed(2)} кг',
        '${p.assignedGroupGearWeightKg.toStringAsFixed(2)} кг',
        '${p.assignedFoodWeightKg.toStringAsFixed(2)} кг',
        '${p.totalPackWeightKg.toStringAsFixed(2)} кг',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: darkHeader),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: alternateRowBg),
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
    );
  }

  static pw.Widget _buildNutritionAndSafetySection(TripProfile profile, TripCalculationResult calcResult) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGray, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'БЖУ и микронутриенты: Белки: ${calcResult.targets.dailyProteinG.toStringAsFixed(0)} г | Жиры: ${calcResult.targets.dailyFatG.toStringAsFixed(0)} г | Углеводы: ${calcResult.targets.dailyCarbsG.toStringAsFixed(0)} г | Натрий: ${calcResult.targets.dailySodiumMg.toStringAsFixed(0)} мг',
            style: const pw.TextStyle(fontSize: 8.5),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Норма гидратации: ${calcResult.targets.dailyWaterLiters.toStringAsFixed(1)} л/чел/день | Суммарный вес продуктов на всю группу: ${calcResult.totalFoodWeightAllGroupKg.toStringAsFixed(2)} кг',
            style: const pw.TextStyle(fontSize: 8.5),
          ),
          if (profile.emergencyExitRoutes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Аварийные сходы и запасные пути: ${profile.emergencyExitRoutes}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPlanFactTable(TripProfile profile, List<DailyTrack> tracks) {
    final totalActualDist = tracks.fold<double>(0.0, (sum, t) => sum + t.totalDistanceKm);
    final totalActualAscent = tracks.fold<double>(0.0, (sum, t) => sum + t.elevationGainMeters);
    final totalActualMovingSec = tracks.fold<int>(0, (sum, t) => sum + t.movingDurationSeconds);
    final totalHours = (totalActualMovingSec / 3600.0).toStringAsFixed(1);

    final headers = ['Параметр', 'План', 'Факт', 'Разница'];
    final data = [
      ['Дистанция маршрута', '${profile.totalDistanceKm.toStringAsFixed(1)} км', '${totalActualDist.toStringAsFixed(1)} км', '${(totalActualDist - profile.totalDistanceKm).toStringAsFixed(1)} км'],
      ['Суммарный набор высоты', '${profile.totalAscentMeters.toStringAsFixed(0)} м', '${totalActualAscent.toStringAsFixed(0)} м', '${(totalActualAscent - profile.totalAscentMeters).toStringAsFixed(0)} м'],
      ['Ходовые дни', '${profile.activeDays} дн.', '${tracks.length} дн.', '${tracks.length - profile.activeDays} дн.'],
      ['Суммарное ходовое время', '—', '$totalHours ч', '—'],
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: darkHeader),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
    );
  }

  static pw.Widget _buildTracksTable(List<DailyTrack> tracks) {
    final headers = ['День', 'Участок / Трек', 'Дистанция', 'Набор', 'Сброс', 'Время хода', 'Ср. скор.'];
    final data = tracks.asMap().entries.map((e) {
      final idx = e.key + 1;
      final t = e.value;
      final h = t.movingDurationSeconds ~/ 3600;
      final m = (t.movingDurationSeconds % 3600) ~/ 60;
      final timeStr = '$hч $mм';
      return [
        '$idx',
        t.title,
        '${t.totalDistanceKm.toStringAsFixed(1)} км',
        '+${t.elevationGainMeters.toStringAsFixed(0)} м',
        '-${t.elevationLossMeters.toStringAsFixed(0)} м',
        timeStr,
        '${t.avgMovingSpeedKmh.toStringAsFixed(1)} км/ч',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: darkHeader),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
    );
  }

  static pw.Widget _buildWaypointsTable(List<WayPoint> waypoints) {
    final headers = ['№', 'Название точки', 'Тип', 'Координаты', 'Высота', 'Автор'];
    final data = waypoints.asMap().entries.map((e) {
      final idx = e.key + 1;
      final w = e.value;
      final coords = '${w.latitude.toStringAsFixed(4)}, ${w.longitude.toStringAsFixed(4)}';
      return [
        '$idx',
        w.title,
        w.type.displayNameRu,
        coords,
        '${w.altitude.toStringAsFixed(0)} м',
        w.authorName ?? '—',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: darkHeader),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      border: pw.TableBorder.all(color: borderGray, width: 0.5),
    );
  }

  static pw.Widget _buildCampNotesSection(List<DailyCampNote> campNotes) {
    final widgets = <pw.Widget>[];
    for (final note in campNotes) {
      final roleStr = note.authorRole != null ? ' (${note.authorRole!.displayNameRu})' : '';
      final weatherStr = note.weather != null ? ' • Погода: ${note.weather}' : '';
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: alternateRowBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: borderGray, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Заметка: ${note.authorName}$roleStr$weatherStr',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: primaryOrange),
              ),
              pw.SizedBox(height: 2),
              pw.Text(note.text, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
