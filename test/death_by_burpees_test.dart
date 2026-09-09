import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/death_by_burpees_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/death_by_burpees_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeathByBurpeesLog Model Tests', () {
    test('Calculates total reps accurately from completed minutes and partial reps', () {
      // 1 minute: 1 rep
      final DeathByBurpeesLog log1 = DeathByBurpeesLog(completedMinutes: 1, partialReps: 0);
      expect(log1.totalReps, equals(1));

      // 5 minutes: 1 + 2 + 3 + 4 + 5 = 15 reps
      final DeathByBurpeesLog log5 = DeathByBurpeesLog(completedMinutes: 5, partialReps: 0);
      expect(log5.totalReps, equals(15));

      // 12 minutes: 12 * 13 / 2 = 78 reps
      final DeathByBurpeesLog log12 = DeathByBurpeesLog(completedMinutes: 12, partialReps: 0);
      expect(log12.totalReps, equals(78));

      // 15 minutes + 8 partial reps: 15 * 16 / 2 + 8 = 120 + 8 = 128 reps
      final DeathByBurpeesLog log15plus8 = DeathByBurpeesLog(
        completedMinutes: 15,
        partialReps: 8,
        burpeeVariation: 'standard',
      );
      expect(log15plus8.totalReps, equals(128));
      expect(log15plus8.scalingTier, equals('Rx'));
      expect(log15plus8.scoreDisplay, equals('15 Mins + 8 Reps (128 Burpees, Rx)'));
    });

    test('Detects variations and scaling tiers', () {
      final DeathByBurpeesLog standard = DeathByBurpeesLog(
        completedMinutes: 14,
        burpeeVariation: 'standard',
      );
      expect(standard.scalingTier, equals('Rx'));
      expect(standard.variationDisplayName, equals('Chest-to-Floor (Rx)'));

      final DeathByBurpeesLog noPushup = DeathByBurpeesLog(
        completedMinutes: 16,
        burpeeVariation: 'no_pushup',
      );
      expect(noPushup.scalingTier, equals('Scaled'));
      expect(noPushup.variationDisplayName, equals('No-Pushup Burpees (Scaled)'));

      final DeathByBurpeesLog boxElevated = DeathByBurpeesLog(
        completedMinutes: 10,
        burpeeVariation: 'box_elevated',
      );
      expect(boxElevated.scalingTier, equals('Scaled'));
      expect(boxElevated.variationDisplayName, equals('Elevated Hands (Scaled)'));
    });

    test('JSON serialization roundtrip maintains all fields', () {
      final DeathByBurpeesLog original = DeathByBurpeesLog(
        completedMinutes: 13,
        partialReps: 5,
        totalDurationSeconds: 810,
        burpeeVariation: 'standard',
        notes: 'Paced well until minute 12',
        isPr: true,
      );

      final Map<String, dynamic> json = original.toJson();
      final DeathByBurpeesLog restored = DeathByBurpeesLog.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.completedMinutes, equals(13));
      expect(restored.partialReps, equals(5));
      expect(restored.totalReps, equals(13 * 14 ~/ 2 + 5)); // 96
      expect(restored.totalDurationSeconds, equals(810));
      expect(restored.burpeeVariation, equals('standard'));
      expect(restored.scalingTier, equals('Rx'));
      expect(restored.isPr, isTrue);
      expect(restored.notes, equals('Paced well until minute 12'));
    });
  });

  group('Death By Burpees Storage & PR Logic Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs Death by Burpees session and calculates PR (higher reps is better)', () async {
      // First session: 12 minutes (78 reps) -> should be PR
      final DeathByBurpeesLog log1 = DeathByBurpeesLog(
        completedMinutes: 12,
        partialReps: 0,
        burpeeVariation: 'standard',
      );
      final DeathByBurpeesLog saved1 = await recovery.logDeathByBurpees(log1);
      expect(saved1.isPr, isTrue);
      expect(recovery.deathByBurpeesLogs.length, equals(1));
      expect(recovery.getDeathByBurpeesPersonalRecord(tier: 'Rx')?.totalReps, equals(78));

      // Second session: 10 minutes (55 reps) -> NOT PR
      final DeathByBurpeesLog log2 = DeathByBurpeesLog(
        completedMinutes: 10,
        partialReps: 0,
        burpeeVariation: 'standard',
      );
      final DeathByBurpeesLog saved2 = await recovery.logDeathByBurpees(log2);
      expect(saved2.isPr, isFalse);
      expect(recovery.deathByBurpeesLogs.length, equals(2));
      expect(recovery.getDeathByBurpeesPersonalRecord(tier: 'Rx')?.totalReps, equals(78));

      // Third session: 14 minutes + 6 partial reps (111 reps) -> NEW PR
      final DeathByBurpeesLog log3 = DeathByBurpeesLog(
        completedMinutes: 14,
        partialReps: 6,
        burpeeVariation: 'standard',
      );
      final DeathByBurpeesLog saved3 = await recovery.logDeathByBurpees(log3);
      expect(saved3.isPr, isTrue);
      expect(recovery.getDeathByBurpeesPersonalRecord(tier: 'Rx')?.totalReps, equals(111));
      expect(recovery.latestDeathByBurpeesLog?.id, equals(saved3.id));
    });

    test('Filters PR and history by scaling tier', () async {
      final DeathByBurpeesLog rxLog = DeathByBurpeesLog(
        completedMinutes: 13,
        partialReps: 0,
        burpeeVariation: 'standard',
      );
      await recovery.logDeathByBurpees(rxLog);

      final DeathByBurpeesLog scaledLog = DeathByBurpeesLog(
        completedMinutes: 17,
        partialReps: 0,
        burpeeVariation: 'no_pushup',
      );
      await recovery.logDeathByBurpees(scaledLog);

      expect(recovery.getDeathByBurpeesPersonalRecord(tier: 'Rx')?.completedMinutes, equals(13));
      expect(recovery.getDeathByBurpeesPersonalRecord(tier: 'Scaled')?.completedMinutes, equals(17));
    });

    test('Export and import app data includes death by burpees logs', () async {
      final DeathByBurpeesLog log = DeathByBurpeesLog(
        completedMinutes: 15,
        partialReps: 4,
        burpeeVariation: 'standard',
      );
      await storage.logDeathByBurpees(log);

      final String exportedJson = storage.exportFullAppDataJson();
      expect(exportedJson, contains('deathByBurpeesLogs'));
      expect(exportedJson, contains(log.id));

      // Clear storage and re-import
      await prefs.clear();
      expect(storage.loadDeathByBurpeesLogs(), isEmpty);

      final bool imported = await storage.importAppDataJson(exportedJson);
      expect(imported, isTrue);

      final List<DeathByBurpeesLog> reloaded = storage.loadDeathByBurpeesLogs();
      expect(reloaded.length, equals(1));
      expect(reloaded.first.completedMinutes, equals(15));
      expect(reloaded.first.partialReps, equals(4));
    });
  });

  group('DeathByBurpeesWodCard Widget Tests', () {
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
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );
    }

    testWidgets('Renders interactive EMOM card with timer, targets, and rep controls',
        (WidgetTester tester) async {
      final MobilityExerciseModel exercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'death_by_burpees_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          DeathByBurpeesWodCard(
            exercise: exercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEATH BY BURPEES'), findsOneWidget);
      expect(find.text('EMOM'), findsOneWidget);
      expect(find.text('LIVE EMOM TRACKER'), findsOneWidget);
      expect(find.text('MANUAL SCORE LOG'), findsOneWidget);
      expect(find.text('MINUTE 1'), findsOneWidget);
      expect(find.text('START EMOM'), findsOneWidget);
      expect(find.text('TARGET MET ✓'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('Stepping reps marks target complete and shows rest / advance button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel exercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'death_by_burpees_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          DeathByBurpeesWodCard(
            exercise: exercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Minute 1 target is 1 burpee. Tap '+1'
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      expect(find.text('Target met! Rest until next minute'), findsOneWidget);
      expect(find.text('ADVANCE TO NEXT MINUTE NOW'), findsOneWidget);

      // Tap Advance to Next Minute Now
      await tester.tap(find.text('ADVANCE TO NEXT MINUTE NOW'));
      await tester.pumpAndSettle();

      expect(find.text('MINUTE 2'), findsOneWidget);
      expect(find.text('2 BURPEES'), findsOneWidget);
      expect(find.text('Total Reps Done: 1'), findsOneWidget);
    });

    testWidgets('Manual score entry opens completion dialog and saves log',
        (WidgetTester tester) async {
      final MobilityExerciseModel exercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'death_by_burpees_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          DeathByBurpeesWodCard(
            exercise: exercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Manual Mode
      await tester.tap(find.text('MANUAL SCORE LOG'));
      await tester.pumpAndSettle();

      expect(find.text('Completed Minutes'), findsOneWidget);
      expect(find.text('Partial Reps (Final Min)'), findsOneWidget);

      // Tap Log Benchmark Score
      await tester.tap(find.text('LOG BENCHMARK SCORE'));
      await tester.pumpAndSettle();

      // Completion dialog should appear
      expect(find.text('DEATH BY BURPEES SCORE'), findsOneWidget);
      expect(find.text('SAVE TO LOGS'), findsOneWidget);

      // Tap SAVE TO LOGS
      await tester.tap(find.text('SAVE TO LOGS'));
      await tester.pumpAndSettle();

      expect(recovery.deathByBurpeesLogs.length, equals(1));
    });
  });
}
