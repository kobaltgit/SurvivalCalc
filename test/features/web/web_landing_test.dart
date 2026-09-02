import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/group_distribution/domain/services/load_distribution_service.dart';
import 'package:survival_calc/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:survival_calc/features/trip_setup/data/repositories/trip_repository.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';
import 'package:survival_calc/features/web/domain/services/web_url_service.dart';
import 'package:survival_calc/features/web/presentation/widgets/topographic_background.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_expandable_promo_banner.dart';
import 'package:survival_calc/features/web/presentation/widgets/web_preset_chips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebUrlService Tests', () {
    test('Correctly parses full query parameters into TripProfile', () {
      final uri = Uri.parse(
        'https://survivalcalc.app/?days=7&group=4&active=6&dist=85&ascent=3200&season=spring_autumn&activity=mountain&weight=78.5&title=Тестовый+поход',
      );

      final profile = WebUrlService.parseProfileFromUri(uri);
      expect(profile, isNotNull);
      expect(profile!.durationDays, equals(7));
      expect(profile.groupSize, equals(4));
      expect(profile.activeDays, equals(6));
      expect(profile.totalDistanceKm, equals(85.0));
      expect(profile.totalAscentMeters, equals(3200.0));
      expect(profile.season, equals(Season.spring_autumn));
      expect(profile.activityType, equals(ActivityType.mountain));
      expect(profile.avgParticipantWeightKg, equals(78.5));
      expect(profile.title, equals('Тестовый поход'));
    });

    test('Returns null on empty or irrelevant query parameters', () {
      final uri = Uri.parse('https://survivalcalc.app/');
      final profile = WebUrlService.parseProfileFromUri(uri);
      expect(profile, isNull);
    });

    test('Builds valid shareable URL with parameters', () {
      final profile = TripProfile(
        id: 'trip_123',
        title: 'Горный поход',
        groupSize: 4,
        durationDays: 7,
        activeDays: 6,
        totalDistanceKm: 85.0,
        totalAscentMeters: 3200.0,
        season: Season.spring_autumn,
        activityType: ActivityType.mountain,
        createdAt: DateTime.now(),
      );

      final url = WebUrlService.buildShareUrl(profile);
      expect(url.startsWith('http'), isTrue);
      expect(url, contains('days=7'));
      expect(url, contains('group=4'));
      expect(url, contains('dist=85.0'));
      expect(url, contains('ascent=3200.0'));
      expect(url, contains('season=spring_autumn'));
      expect(url, contains('activity=mountain'));
    });

    test('Serializes and parses participants via URL parameters', () {
      final profile = TripProfile(
        id: 'trip_123',
        title: 'Поход с группой',
        groupSize: 2,
        durationDays: 5,
        activeDays: 4,
        totalDistanceKm: 60.0,
        totalAscentMeters: 1500.0,
        season: Season.summer,
        activityType: ActivityType.hiking,
        createdAt: DateTime.now(),
      );

      final participants = [
        const Participant(
          id: 'p_1',
          name: 'Иван',
          fullName: 'Иванов Иван Иванович',
          role: TripRole.leader,
          weightKg: 82.0,
          touristExperience: '3ЛУ, 2ПУ',
          contactPhone: '+79991234567',
        ),
        const Participant(
          id: 'p_2',
          name: 'Анна',
          fullName: 'Петрова Анна Сергеевна',
          role: TripRole.medic,
          weightKg: 58.0,
          dietaryRestrictions: [DietaryRestriction.vegetarian],
          medicalConditions: [MedicalCondition.asthma],
        ),
      ];

      final shareUrl = WebUrlService.buildShareUrl(profile, participants: participants);
      expect(shareUrl, contains('parts='));

      final parsedData = WebUrlService.parseDataFromUri(Uri.parse(shareUrl));
      expect(parsedData, isNotNull);
      expect(parsedData!.profile.durationDays, equals(5));
      expect(parsedData.profile.groupSize, equals(2));
      expect(parsedData.participants.length, equals(2));

      final p1 = parsedData.participants[0];
      expect(p1.fullName, equals('Иванов Иван Иванович'));
      expect(p1.role, equals(TripRole.leader));
      expect(p1.weightKg, equals(82.0));
      expect(p1.contactPhone, equals('+79991234567'));

      final p2 = parsedData.participants[1];
      expect(p2.fullName, equals('Петрова Анна Сергеевна'));
      expect(p2.role, equals(TripRole.medic));
      expect(p2.weightKg, equals(58.0));
      expect(p2.dietaryRestrictions, contains(DietaryRestriction.vegetarian));
      expect(p2.medicalConditions, contains(MedicalCondition.asthma));
    });

    test('GroupParticipantsNotifier persists and restores participants from LocalStorageTripRepository', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalStorageTripRepository();
      const service = LoadDistributionService();

      final notifier1 = GroupParticipantsNotifier(service, repo);
      notifier1.setParticipants([
        const Participant(
          id: 'p_1',
          name: 'Иван Руководитель',
          role: TripRole.leader,
          weightKg: 80.0,
        ),
        const Participant(
          id: 'p_2',
          name: 'Анна Завхоз',
          role: TripRole.foodMaster,
          weightKg: 60.0,
        ),
      ]);

      // Allow microtask to complete saving
      await Future.delayed(Duration.zero);

      final loaded = await repo.loadActiveParticipants();
      expect(loaded.length, equals(2));
      expect(loaded[0].name, equals('Иван Руководитель'));
      expect(loaded[1].name, equals('Анна Завхоз'));

      // Simulate app restart / page refresh: new notifier loads saved participants
      final notifier2 = GroupParticipantsNotifier(service, repo);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier2.state.length, equals(2));
      expect(notifier2.state[0].name, equals('Иван Руководитель'));
      expect(notifier2.state[1].role, equals(TripRole.foodMaster));
    });
  });

  group('WebPresetChips Tests', () {
    test('Contains standard outdoor presets', () {
      final presets = WebPresetChips.defaultPresets;
      expect(presets.length, equals(4));
      expect(presets.any((p) => p.profile.season == Season.summer), isTrue);
      expect(presets.any((p) => p.profile.season == Season.winter), isTrue);
      expect(
          presets.any((p) => p.profile.activityType == ActivityType.mountain),
          isTrue);
      expect(presets.any((p) => p.profile.activityType == ActivityType.water),
          isTrue);
    });

    testWidgets('Renders presets and fires callback on tap',
        (WidgetTester tester) async {
      TripProfile? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WebPresetChips(
              onPresetSelected: (preset) {
                selected = preset;
              },
            ),
          ),
        ),
      );

      expect(find.text('БЫСТРЫЕ ПРЕСЕТЫ ПОХОДОВ'), findsOneWidget);
      expect(find.text('Летний соло ПВД'), findsOneWidget);
      expect(find.text('Осенний горный трек'), findsOneWidget);

      await tester.tap(find.text('Зимняя автономка'));
      await tester.pump();

      expect(selected, isNotNull);
      expect(selected!.season, equals(Season.winter));
      expect(selected!.groupSize, equals(2));
      expect(selected!.durationDays, equals(10));
    });
  });

  group('WebExpandablePromoBanner Tests', () {
    testWidgets('Toggles expanded state on tap and displays feature pillars',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WebExpandablePromoBanner(),
            ),
          ),
        ),
      );

      expect(find.text('О проекте и возможностях'), findsOneWidget);
      expect(find.text('Профессиональный штурман для туризма и выживания'),
          findsNothing);

      // Tap to expand
      await tester.tap(find.text('О проекте и возможностях'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Свернуть промо'), findsOneWidget);
      expect(find.text('Профессиональный штурман для туризма и выживания'),
          findsOneWidget);
      expect(find.text('100% Офлайн и приватность'), findsOneWidget);
      expect(find.text('Научный метаболизм'), findsOneWidget);
      expect(find.text('Кто что несёт'), findsOneWidget);
      expect(find.text('GPS & Дневник лагеря'), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.text('Свернуть промо'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('О проекте и возможностях'), findsOneWidget);
    });
  });

  group('TopographicBackground & Responsive Tests', () {
    testWidgets('TopographicBackground renders child smoothly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TopographicBackground(
            child: Text('Outdoor Canvas Content'),
          ),
        ),
      );

      expect(find.text('Outdoor Canvas Content'), findsOneWidget);
    });

    testWidgets('MainNavigationScreen renders mobile navigation on narrow view',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Параметры'), findsOneWidget);
      expect(find.text('Дашборд'), findsOneWidget);
    });

    testWidgets('MainNavigationScreen renders WebLandingScreen on wide desktop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SurvivalCalc'), findsOneWidget);
      expect(find.text('100% OFFLINE'), findsOneWidget);
      expect(find.text('Скачать APK'), findsWidgets);
      expect(find.text('БЫСТРЫЕ ПРЕСЕТЫ ПОХОДОВ'), findsOneWidget);
      expect(find.text('Дашборд и БЖУ'), findsOneWidget);
    });
  });
}
