import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/domain/models/macronutrient_targets.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/expedition_archive_service.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_markdown_generator.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_pdf_generator.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late TripProfile testProfile;
  late List<Participant> testParticipants;
  late TripCalculationResult testCalcResult;
  late List<DailyTrack> testTracks;
  late List<WayPoint> testWaypoints;
  late List<DailyCampNote> testCampNotes;

  setUp(() {
    testProfile = TripProfile(
      id: 'trip_altai_2026',
      title: 'Северо-Чуйский Хребет',
      clubOrCity: 'ТК Вестра, Москва',
      difficultyCategory: '3 к.с.',
      geographicalRegion: 'Горный Алтай',
      emergencyExitRoutes: 'По долине реки Маашей к Чуйскому тракту',
      mkkName: 'МКК ФСТ-ОТМ № 177-00-56660000',
      groupSize: 4,
      durationDays: 10,
      activeDays: 8,
      totalDistanceKm: 120.0,
      totalAscentMeters: 4500.0,
      season: Season.summer,
      activityType: ActivityType.mountain,
      avgParticipantWeightKg: 76.0,
      createdAt: DateTime(2026, 7, 15),
    );

    testParticipants = [
      const Participant(
        id: 'p_1',
        name: 'Алексей',
        fullName: 'Смирнов Алексей Викторович',
        touristExperience: '3ГУ (рук), 4ГУ (уч)',
        contactPhone: '+7 999 123-45-67',
        weightKg: 78.0,
        role: TripRole.leader,
        personalGearWeightKg: 9.5,
      ),
      const Participant(
        id: 'p_2',
        name: 'Елена',
        fullName: 'Иванова Елена Сергеевна',
        touristExperience: '2ГУ (уч)',
        contactPhone: '+7 999 765-43-21',
        weightKg: 62.0,
        role: TripRole.medic,
        personalGearWeightKg: 8.0,
      ),
    ];

    testCalcResult = TripCalculationResult(
      profile: testProfile,
      targets: const MacronutrientTargets(
        dailyCalories: 3850.0,
        dailyProteinG: 136.0,
        dailyFatG: 128.0,
        dailyCarbsG: 538.0,
        dailySodiumMg: 3500.0,
        dailyWaterLiters: 3.5,
        dailyGasFuelG: 40.0,
        bmr: 1750.0,
        pal: 2.2,
        equivalentDistanceKm: 165.0,
        dailyEquivalentKm: 20.6,
        coldBonusKcal: 0.0,
      ),
      dailyRations: [],
      shoppingList: [],
      gearList: [],
      totalPersonalGearWeightKg: 32.0,
      totalGroupGearWeightKg: 14.0,
      groupGearWeightPerPersonKg: 3.5,
      totalGearWeightPerPersonKg: 11.5,
      foodWeightPerPersonPerDayKg: 0.7,
      totalFoodWeightPerPersonKg: 7.0,
      totalFoodWeightAllGroupKg: 28.0,
      startPackWeightPerPersonKg: 18.5,
      dailyPackWeightsPerPersonKg: [18.5, 17.8, 17.1],
    );

    testTracks = [
      DailyTrack(
        id: 'track_1',
        dayIndex: 1,
        tripId: 'trip_altai_2026',
        title: 'День 1: Альплагерь Актру — пер. Учитель',
        startTime: DateTime(2026, 7, 15, 8, 0),
        endTime: DateTime(2026, 7, 15, 16, 0),
        points: [],
        totalDistanceKm: 14.5,
        elevationGainMeters: 950.0,
        elevationLossMeters: 200.0,
        movingDurationSeconds: 18000,
        avgMovingSpeedKmh: 3.2,
      ),
    ];

    testWaypoints = [
      WayPoint(
        id: 'wpt_1',
        title: 'Перевал Учитель (1А, 3100м)',
        latitude: 50.1234,
        longitude: 87.5678,
        altitude: 3100.0,
        timestamp: DateTime(2026, 7, 15, 13, 0),
        type: WayPointType.pass,
        authorName: 'Смирнов А.В.',
        note: 'Снята записка группы из Новосибирска',
      ),
    ];

    testCampNotes = [
      DailyCampNote(
        id: 'note_1',
        tripId: 'trip_altai_2026',
        dayNumber: 1,
        authorName: 'Смирнов А.В.',
        authorRole: TripRole.leader,
        weather: '☀️ Ясно, +18°C, штиль',
        text: 'Группа чувствует себя отлично. Ночевка у Голубого озера.',
        createdAt: DateTime(2026, 7, 15, 20, 0),
      ),
    ];
  });

  group('MkkMarkdownGenerator Tests', () {
    test('generatePreTripPassportMarkdown contains all essential MKK sections', () {
      final md = MkkMarkdownGenerator.generatePreTripPassportMarkdown(
        profile: testProfile,
        participants: testParticipants,
        calcResult: testCalcResult,
      );

      expect(md, contains('Северо-Чуйский Хребет'));
      expect(md, contains('ТК Вестра, Москва'));
      expect(md, contains('3 к.с.'));
      expect(md, contains('МКК ФСТ-ОТМ'));
      expect(md, contains('Смирнов Алексей Викторович'));
      expect(md, contains('3ГУ (рук), 4ГУ (уч)'));
      expect(md, contains('Сводная весовая ведомость'));
    });

    test('generatePostTripReportMarkdown contains Plan/Fact, Tracks and Waypoints', () {
      final md = MkkMarkdownGenerator.generatePostTripReportMarkdown(
        profile: testProfile,
        participants: testParticipants,
        tracks: testTracks,
        waypoints: testWaypoints,
        campNotes: testCampNotes,
      );

      expect(md, contains('ИТОГОВЫЙ ТЕХНИЧЕСКИЙ ОТЧЕТ'));
      expect(md, contains('Сравнительная таблица «План / Факт»'));
      expect(md, contains('День 1: Альплагерь Актру'));
      expect(md, contains('Перевал Учитель (1А, 3100м)'));
      expect(md, contains('Дневник лагеря и погодная хроника'));
    });

    test('markdownToHtml converts markdown tables into valid HTML table structure', () {
      const sampleMd = '# Заголовок\n\n| Имя | Роль |\n|---|---|\n| Алексей | Руководитель |\n';
      final html = MkkMarkdownGenerator.markdownToHtml(sampleMd);

      expect(html, contains('<h1>Заголовок</h1>'));
      expect(html, contains('<table'));
      expect(html, contains('<th>Имя</th>'));
      expect(html, contains('<td>Алексей</td>'));
    });
  });

  group('MkkPdfGenerator Tests', () {
    test('generatePreTripPassportPdf returns non-empty valid PDF bytes', () async {
      final pdfBytes = await MkkPdfGenerator.generatePreTripPassportPdf(
        profile: testProfile,
        participants: testParticipants,
        calcResult: testCalcResult,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF magic header %PDF
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });

    test('generatePostTripReportPdf returns non-empty valid PDF bytes', () async {
      final pdfBytes = await MkkPdfGenerator.generatePostTripReportPdf(
        profile: testProfile,
        participants: testParticipants,
        tracks: testTracks,
        waypoints: testWaypoints,
        campNotes: testCampNotes,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });

  group('ExpeditionArchiveService Tests', () {
    test('createExpeditionZip generates valid ZIP containing PDFs, MD, HTML and GPX', () async {
      final zipBytes = await ExpeditionArchiveService.createExpeditionZip(
        profile: testProfile,
        participants: testParticipants,
        calcResult: testCalcResult,
        tracks: testTracks,
        waypoints: testWaypoints,
        campNotes: testCampNotes,
      );

      expect(zipBytes, isNotNull);
      expect(zipBytes.isNotEmpty, isTrue);

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final fileNames = archive.files.map((f) => f.name).toList();

      expect(fileNames, contains('Passport_MKK.pdf'));
      expect(fileNames, contains('Technical_Report.pdf'));
      expect(fileNames, contains('Trip_Summary.md'));
      expect(fileNames, contains('Trip_Summary.html'));
      expect(fileNames.any((name) => name.startsWith('Tracks/') && name.endsWith('.gpx')), isTrue);
    });
  });
}
