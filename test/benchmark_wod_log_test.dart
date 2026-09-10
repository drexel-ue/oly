import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/views/wod_hub_screen.dart';
import 'package:oly/widgets/log_wod_score_sheet.dart';
import 'package:oly/widgets/wod_history_sheet.dart';
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

  group('BenchmarkWodLog Model & PR Evaluation Tests', () {
    test('BenchmarkWodLog serialization and deserialization works cleanly', () {
      final BenchmarkWodLog log = BenchmarkWodLog.create(
        wodId: 'cf_hero_murph',
        wodName: 'Murph',
        format: 'forTime',
        date: DateTime(2026, 9, 10, 10, 0),
        durationSeconds: 2435, // 40:35
        scoreDisplay: '40:35',
        category: 'Hero Benchmark',
        isRx: true,
        rpe: 9,
        scalingModifications: '20lb vest',
        notes: 'Felt strong on the second mile run.',
      );

      final Map<String, dynamic> json = log.toJson();
      expect(json['wodId'], 'cf_hero_murph');
      expect(json['wodName'], 'Murph');
      expect(json['format'], 'forTime');
      expect(json['durationSeconds'], 2435);
      expect(json['scoreDisplay'], '40:35');
      expect(json['isRx'], isTrue);
      expect(json['rpe'], 9);

      final BenchmarkWodLog fromJson = BenchmarkWodLog.fromJson(json);
      expect(fromJson.wodId, log.wodId);
      expect(fromJson.durationSeconds, log.durationSeconds);
      expect(fromJson.scoreDisplay, log.scoreDisplay);
      expect(fromJson.scalingModifications, '20lb vest');
      expect(fromJson.notes, 'Felt strong on the second mile run.');
    });

    test('isBetterScoreThan evaluates For Time (lower is better)', () {
      final BenchmarkWodLog fast = BenchmarkWodLog.create(
        wodId: 'fran',
        wodName: 'Fran',
        format: 'forTime',
        date: DateTime.now(),
        durationSeconds: 165, // 2:45
        scoreDisplay: '02:45',
      );

      final BenchmarkWodLog slow = BenchmarkWodLog.create(
        wodId: 'fran',
        wodName: 'Fran',
        format: 'forTime',
        date: DateTime.now(),
        durationSeconds: 220, // 3:40
        scoreDisplay: '03:40',
      );

      expect(fast.isBetterScoreThan(slow), isTrue);
      expect(slow.isBetterScoreThan(fast), isFalse);
    });

    test('isBetterScoreThan evaluates AMRAP (higher rounds and reps is better)', () {
      final BenchmarkWodLog moreRounds = BenchmarkWodLog.create(
        wodId: 'cindy',
        wodName: 'Cindy',
        format: 'amrap',
        date: DateTime.now(),
        durationSeconds: 1200,
        completedRounds: 22,
        completedReps: 5,
        scoreDisplay: '22 Rds + 5 Reps',
      );

      final BenchmarkWodLog fewerRounds = BenchmarkWodLog.create(
        wodId: 'cindy',
        wodName: 'Cindy',
        format: 'amrap',
        date: DateTime.now(),
        durationSeconds: 1200,
        completedRounds: 20,
        completedReps: 15,
        scoreDisplay: '20 Rds + 15 Reps',
      );

      final BenchmarkWodLog sameRoundsMoreReps = BenchmarkWodLog.create(
        wodId: 'cindy',
        wodName: 'Cindy',
        format: 'amrap',
        date: DateTime.now(),
        durationSeconds: 1200,
        completedRounds: 22,
        completedReps: 12,
        scoreDisplay: '22 Rds + 12 Reps',
      );

      expect(moreRounds.isBetterScoreThan(fewerRounds), isTrue);
      expect(fewerRounds.isBetterScoreThan(moreRounds), isFalse);
      expect(sameRoundsMoreReps.isBetterScoreThan(moreRounds), isTrue);
    });
  });

  group('StorageService & RecoveryProvider Benchmark Logging Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs first attempt as PR and updates PR upon subsequent faster attempt', () async {
      // First attempt: 45:00
      final BenchmarkWodLog attempt1 = BenchmarkWodLog.create(
        wodId: 'cf_hero_murph',
        wodName: 'Murph',
        format: 'forTime',
        date: DateTime(2026, 8, 1),
        durationSeconds: 2700,
        scoreDisplay: '45:00',
        category: 'Hero Benchmark',
        isRx: true,
      );

      final BenchmarkWodLog logged1 = await recovery.logBenchmarkWod(attempt1);
      expect(logged1.isPr, isTrue);

      BenchmarkWodLog? pr = recovery.getBenchmarkWodPersonalRecord('cf_hero_murph');
      expect(pr, isNotNull);
      expect(pr!.scoreDisplay, '45:00');

      // Second attempt: 48:00 (slower -> not a PR)
      final BenchmarkWodLog attempt2 = BenchmarkWodLog.create(
        wodId: 'cf_hero_murph',
        wodName: 'Murph',
        format: 'forTime',
        date: DateTime(2026, 8, 15),
        durationSeconds: 2880,
        scoreDisplay: '48:00',
        category: 'Hero Benchmark',
        isRx: true,
      );

      final BenchmarkWodLog logged2 = await recovery.logBenchmarkWod(attempt2);
      expect(logged2.isPr, isFalse);

      pr = recovery.getBenchmarkWodPersonalRecord('cf_hero_murph');
      expect(pr!.scoreDisplay, '45:00');

      // Third attempt: 41:20 (faster -> new PR)
      final BenchmarkWodLog attempt3 = BenchmarkWodLog.create(
        wodId: 'cf_hero_murph',
        wodName: 'Murph',
        format: 'forTime',
        date: DateTime(2026, 9, 1),
        durationSeconds: 2480,
        scoreDisplay: '41:20',
        category: 'Hero Benchmark',
        isRx: true,
      );

      final BenchmarkWodLog logged3 = await recovery.logBenchmarkWod(attempt3);
      expect(logged3.isPr, isTrue);

      pr = recovery.getBenchmarkWodPersonalRecord('cf_hero_murph');
      expect(pr!.scoreDisplay, '41:20');

      // History should have 3 attempts
      final List<BenchmarkWodLog> history = recovery.getBenchmarkWodHistory('cf_hero_murph');
      expect(history.length, 3);

      // Hero count should be 1
      expect(recovery.totalCompletedHeroWodsCount, 1);
    });

    test('Deleting fastest log recalculates PR to next best attempt', () async {
      final BenchmarkWodLog fast = BenchmarkWodLog.create(
        wodId: 'cf_hero_michael',
        wodName: 'Michael',
        format: 'forTime',
        date: DateTime(2026, 9, 1),
        durationSeconds: 1200, // 20:00
        scoreDisplay: '20:00',
        category: 'Hero Benchmark',
      );
      final BenchmarkWodLog loggedFast = await recovery.logBenchmarkWod(fast);

      final BenchmarkWodLog slow = BenchmarkWodLog.create(
        wodId: 'cf_hero_michael',
        wodName: 'Michael',
        format: 'forTime',
        date: DateTime(2026, 8, 1),
        durationSeconds: 1400, // 23:20
        scoreDisplay: '23:20',
        category: 'Hero Benchmark',
      );
      await recovery.logBenchmarkWod(slow);

      expect(recovery.getBenchmarkWodPersonalRecord('cf_hero_michael')?.scoreDisplay, '20:00');

      // Delete fastest
      await recovery.deleteBenchmarkWodLog(loggedFast.id);

      final BenchmarkWodLog? remainingPr =
          recovery.getBenchmarkWodPersonalRecord('cf_hero_michael');
      expect(remainingPr, isNotNull);
      expect(remainingPr!.scoreDisplay, '23:20');
      expect(remainingPr.isPr, isTrue);
    });
  });

  group('WOD Hub & Analytics UI Verification Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;
    late SettingsProvider settings;
    late ProgramProvider program;
    late LiftProvider lifts;
    late BodyCompProvider bodyComp;
    late NutritionProvider nutrition;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
      settings = SettingsProvider(storage);
      program = ProgramProvider(storage);
      lifts = LiftProvider(storage);
      bodyComp = BodyCompProvider(storage);
      nutrition = NutritionProvider(storage);

      // Seed a Hero WOD log
      await recovery.logBenchmarkWod(
        BenchmarkWodLog.create(
          wodId: 'cf_hero_murph',
          wodName: 'Murph',
          format: 'forTime',
          date: DateTime(2026, 9, 10),
          durationSeconds: 2410,
          scoreDisplay: '40:10',
          category: 'Hero Benchmark',
          isRx: true,
        ),
      );
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<RecoveryProvider>.value(value: recovery),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ProgramProvider>.value(value: program),
          ChangeNotifierProvider<LiftProvider>.value(value: lifts),
          ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
          ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('WodHubScreen switches between Catalog and Progress tabs seamlessly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.runAsync(() async {
        await tester.pumpWidget(createTestApp(const WodHubScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Tab selector should show both tabs
      expect(find.text('WOD CATALOG'), findsOneWidget);
      expect(find.text('PROGRESS & PRS'), findsOneWidget);

      // Initially on Catalog tab
      expect(find.text('Shuffle Random WOD'), findsOneWidget);

      // Switch to Progress tab
      await tester.tap(find.text('PROGRESS & PRS'));
      await tester.pumpAndSettle();

      // Progress tab elements
      expect(find.text('HERO WOD ODYSSEY'), findsOneWidget);
      expect(find.text('TOTAL LOGS'), findsOneWidget);
      expect(find.text('HERO TRIBUTES'), findsOneWidget);
      expect(find.text('ALL-TIME PRS'), findsOneWidget);
      expect(find.text('+ LOG WOD SCORE / PR'), findsOneWidget);
      expect(find.text('BENCHMARK PR LEADERBOARD'), findsOneWidget);

      // Murph PR should be listed in the leaderboard
      expect(find.text('Murph'), findsWidgets);
      expect(find.text('PR: 40:10'), findsOneWidget);
    });

    testWidgets('Opens WodHistorySheet and displays PR trophy card and history',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    WodHistorySheet.show(
                      context,
                      wodId: 'cf_hero_murph',
                      wodName: 'Murph',
                      wodFormat: 'forTime',
                    );
                  },
                  child: const Text('OPEN HISTORY'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN HISTORY'));
      await tester.pumpAndSettle();

      expect(find.text('Murph History'), findsOneWidget);
      expect(find.text('ALL-TIME PERSONAL BEST'), findsOneWidget);
      expect(find.text('40:10'), findsNWidgets(2));
      expect(find.text('Rx'), findsWidgets);
      expect(find.text('ATTEMPT HISTORY (1)'), findsOneWidget);
      expect(find.text('+ LOG NEW SCORE'), findsOneWidget);
    });

    testWidgets('Opens LogWodScoreSheet and saves a new score',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    LogWodScoreSheet.show(
                      context,
                      wodId: 'jackie',
                      wodName: 'Jackie',
                      wodFormat: 'forTime',
                    );
                  },
                  child: const Text('OPEN LOG SCORE'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN LOG SCORE'));
      await tester.pumpAndSettle();

      expect(find.text('Log WOD Score'), findsOneWidget);
      expect(find.text('Rx (As Prescribed)'), findsOneWidget);
      expect(find.text('Scaled'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'RECORD SCORE (15:00)'), findsOneWidget);

      // Tap Record Score
      await tester.tap(find.widgetWithText(ElevatedButton, 'RECORD SCORE (15:00)'));
      await tester.pumpAndSettle();

      // Jackie should now have a logged score
      final BenchmarkWodLog? jackiePr = recovery.getBenchmarkWodPersonalRecord('jackie');
      expect(jackiePr, isNotNull);
      expect(jackiePr!.wodName, 'Jackie');
    });

    testWidgets('AnalyticsScreen displays WODs & Heroes tab with completion progress',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const AnalyticsScreen()));
      await tester.pumpAndSettle();

      // 5 tabs present
      expect(find.widgetWithText(Tab, 'Workouts'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'WODs & Heroes'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Accessories'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Breathwork'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Ratios'), findsOneWidget);

      // Tap 'WODs & Heroes'
      await tester.tap(find.text('WODs & Heroes'));
      await tester.pumpAndSettle();

      expect(find.text('CROSSFIT HERO WOD ODYSSEY'), findsOneWidget);
      expect(find.text('BENCHMARK PERSONAL RECORDS'), findsOneWidget);
      expect(find.text('Murph'), findsWidgets);
      expect(find.text('PR: 40:10'), findsOneWidget);
    });
  });
}
