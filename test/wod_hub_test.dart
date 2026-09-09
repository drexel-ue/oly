import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/wod_hub_screen.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      final WodDefinition? burpees = WodCatalog.getById('death_by_burpees');
      expect(burpees, isNotNull);
      expect(burpees!.format, equals(WodFormat.emom));
      expect(burpees.hasInteractiveTracker, isTrue);

      final WodDefinition? murph = WodCatalog.getById('murph');
      expect(murph, isNotNull);
    });

    test('WodCatalog getRandomWod returns a valid benchmark and respects exclusions', () {
      final WodDefinition randomWod = WodCatalog.getRandomWod();
      expect(WodCatalog.allWods, contains(randomWod));

      // Test excluding an ID
      for (int i = 0; i < 20; i++) {
        final WodDefinition randomExcludingCindy = WodCatalog.getRandomWod(excludeId: 'cindy');
        expect(randomExcludingCindy.id, isNot(equals('cindy')));
      }
    });

    test('WodSetupExplainer contains structured details for Jackie', () {
      const WodDefinition jackie = WodCatalog.jackie;
      final WodSetupExplainer explainer = jackie.setupExplainer;

      expect(explainer.floorPlanAdvice, contains('Concept2 Rower'));
      expect(explainer.equipmentChecklist.isNotEmpty, isTrue);
      expect(explainer.movementStandards.length, equals(3));
      expect(explainer.movementStandards[0].movementName, equals('1,000m Row'));
      expect(explainer.movementStandards[1].movementName, equals('Barbell Thruster'));
      expect(explainer.movementStandards[2].movementName, equals('Pull-up'));
      expect(explainer.targetTimes.containsKey('Elite'), isTrue);
      expect(explainer.scalingOptions.containsKey('Rx'), isTrue);
      expect(explainer.scalingOptions.containsKey('Scaled'), isTrue);
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

      await tester.pumpWidget(createTestApp(const WodHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('CrossFit WOD Hub'), findsOneWidget);
      expect(find.text('Shuffle Random WOD'), findsOneWidget);
      expect(find.text('SHUFFLE'), findsOneWidget);
      expect(find.text('Cindy'), findsOneWidget);
      expect(find.text('Jackie'), findsOneWidget);
      expect(find.text('Fran'), findsOneWidget);
      expect(find.text('Helen'), findsOneWidget);
      expect(find.text('Grace'), findsOneWidget);
      expect(find.text('DT'), findsNWidgets(2)); // Stats bar label + WOD card title
      expect(find.text('BURPEES'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Death By Burpees'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Death By Burpees'), findsOneWidget);
    });

    testWidgets('Filters WODs via search input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const WodHubScreen()));
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
      await tester.pumpWidget(createTestApp(const WodHubScreen()));
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
