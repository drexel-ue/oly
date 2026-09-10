import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/wod_hub_screen.dart';
import 'package:oly/widgets/hero_wod_detail_sheet.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    final String dbPath = '${Directory.current.path}/assets/data/exercises.db';
    ExerciseDatabaseService.setMockInstance(ExerciseDatabaseService(dbPath: dbPath));
    await ExerciseDatabaseService.instance.initDatabase();
  });

  group('WodCatalog Model Tests', () {
    test('WodCatalog contains all classic seeded benchmarks', () {
      const List<WodDefinition> all = WodCatalog.allWods;
      expect(all.length, greaterThanOrEqualTo(7));

      final WodDefinition? cindy = WodCatalog.getById('cindy');
      expect(cindy, isNotNull);
      expect(cindy!.format, equals(WodFormat.amrap));
      expect(cindy.hasInteractiveTracker, isTrue);

      final WodDefinition? jackie = WodCatalog.getById('jackie');
      expect(jackie, isNotNull);
      expect(jackie!.format, equals(WodFormat.forTime));
      expect(jackie.hasInteractiveTracker, isTrue);
      expect(jackie.equipment, contains('Concept2 Indoor Rower'));
      expect(jackie.equipment, contains('Olympic Barbell (45 lb / 20.4 kg)'));
      expect(jackie.equipment, contains('Pull-up Rig / Bar'));

      final WodDefinition? fran = WodCatalog.getById('fran');
      expect(fran, isNotNull);
      expect(fran!.format, equals(WodFormat.forTime));

      final WodDefinition? helen = WodCatalog.getById('helen');
      expect(helen, isNotNull);
      expect(helen!.format, equals(WodFormat.forTime));
      expect(helen.hasInteractiveTracker, isTrue);

      final WodDefinition? grace = WodCatalog.getById('grace');
      expect(grace, isNotNull);
      expect(grace!.format, equals(WodFormat.forTime));
      expect(grace.hasInteractiveTracker, isTrue);

      final WodDefinition? dt = WodCatalog.getById('dt');
      expect(dt, isNotNull);
      expect(dt!.format, equals(WodFormat.forTime));
      expect(dt.hasInteractiveTracker, isTrue);
      expect(dt.equipment, contains('Olympic Barbell (155 lb men / 105 lb women)'));

      final WodDefinition? burpees = WodCatalog.getById('death_by_burpees');
      expect(burpees, isNotNull);
      expect(burpees!.format, equals(WodFormat.emom));
      expect(burpees.hasInteractiveTracker, isTrue);
    });

    test('WodCatalog getRandomWod returns a valid benchmark and respects exclusions', () {
      final WodDefinition randomWod = WodCatalog.getRandomWod();
      expect(randomWod, isNotNull);
      expect(randomWod.name, isNotEmpty);

      final WodDefinition nonCindy = WodCatalog.getRandomWod(excludeId: 'cindy');
      expect(nonCindy.id, isNot('cindy'));
    });

    test('WodSetupExplainer contains structured details for Jackie', () {
      const WodDefinition jackie = WodCatalog.jackie;
      final WodSetupExplainer setup = jackie.setupExplainer;

      expect(setup.floorPlanAdvice, contains('Position the Concept2 Rower'));
      expect(setup.equipmentChecklist.any((String item) => item.contains('Concept2 Rower')), isTrue);
      expect(setup.movementStandards.length, 3);
      expect(setup.movementStandards[0].movementName, '1,000m Row');
      expect(setup.movementStandards[1].movementName, 'Barbell Thruster');
      expect(setup.movementStandards[2].movementName, 'Pull-up');
      expect(setup.pacingStrategy.length, greaterThanOrEqualTo(3));
      expect(setup.targetTimes.containsKey('Elite'), isTrue);
      expect(setup.scalingOptions.containsKey('Rx'), isTrue);
    });
  });

  group('WodHubScreen Widget Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;
    late SettingsProvider settings;
    late BodyCompProvider bodyComp;
    late NutritionProvider nutrition;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
      settings = SettingsProvider(storage);
      bodyComp = BodyCompProvider(storage);
      nutrition = NutritionProvider(storage);
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<RecoveryProvider>.value(value: recovery),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
          ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Renders WodHubScreen with Shuffle Hero, Search bar, and WOD list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp(const WodHubScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('CrossFit WOD Hub'), findsOneWidget);
      expect(find.text('Shuffle Random WOD'), findsOneWidget);
      expect(find.text('SHUFFLE'), findsOneWidget);
      expect(find.text('Hero WODs'), findsOneWidget);
      expect(find.text('Cindy'), findsOneWidget);
      expect(find.text('Jackie'), findsOneWidget);
      expect(find.text('Fran'), findsOneWidget);
      expect(find.text('Helen'), findsOneWidget);
      expect(find.text('Grace'), findsOneWidget);
      expect(find.text('DT'), findsNWidgets(2)); // Stats bar label + WOD card title
      expect(find.text('BURPEES'), findsOneWidget);
    });

    testWidgets('Filters WODs via search input', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp(const WodHubScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Enter 'rower' or 'row'
      await tester.enterText(find.byType(TextField), 'rower');
      await tester.pumpAndSettle();

      // Jackie has Concept2 Rower
      expect(find.text('Jackie'), findsOneWidget);
      // Cindy doesn't have rower
      expect(find.text('Cindy'), findsNothing);
    });

    testWidgets('Opens Shuffle modal and can reroll or view setup',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp(const WodHubScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Tap SHUFFLE button
      await tester.tap(find.widgetWithText(ElevatedButton, 'SHUFFLE'));
      await tester.pumpAndSettle();

      expect(find.text('RANDOM WOD SELECTED'), findsOneWidget);
      expect(find.text('REROLL'), findsOneWidget);

      // Tap REROLL
      await tester.tap(find.text('REROLL'));
      await tester.pumpAndSettle();

      expect(find.text('RANDOM WOD SELECTED'), findsOneWidget);
    });

    testWidgets('Filters Hero WODs via category chip and views Hero Tribute Sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp(const WodHubScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Tap 'Hero WODs' chip
      await tester.tap(find.text('Hero WODs'));
      await tester.pumpAndSettle();

      // Hero WODs category should show DT
      expect(find.text('DT'), findsWidgets);

      // Tap 'Hero Tribute' on a Hero WOD
      final heroTributeFinder = find.text('Hero Tribute');
      expect(heroTributeFinder, findsWidgets);
      await tester.tap(heroTributeFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(HeroWodDetailSheet), findsOneWidget);
      expect(find.text('FALLEN HERO MEMORIAL'), findsOneWidget);
    });

    testWidgets('Opens Setup Explainer Sheet for Jackie', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    WodSetupExplainerSheet.show(context, WodCatalog.jackie);
                  },
                  child: const Text('OPEN EXPLAINER'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN EXPLAINER'));
      await tester.pumpAndSettle();

      expect(find.text('Jackie'), findsOneWidget);
      expect(find.text('Setup & Floor Plan'), findsOneWidget);
      expect(find.text('Movement Standards'), findsOneWidget);
      expect(find.text('Strategy & Pacing'), findsOneWidget);
      expect(find.text('Scaling Matrix'), findsOneWidget);
      expect(find.text('Gym Floor Plan & Spacing'), findsOneWidget);
      expect(find.text('Equipment Checklist'), findsOneWidget);
    });
  });
}
