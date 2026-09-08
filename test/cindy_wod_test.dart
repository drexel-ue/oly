import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/cindy_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cindy Model & Progression Tests', () {
    test('CindyRoundDetail serializes and deserializes with tier calculation', () {
      final CindyRoundDetail rxRound = CindyRoundDetail(
        roundNumber: 1,
        pullupVariation: 'standard',
        pushupVariation: 'standard',
        squatVariation: 'standard',
        splitTimeSeconds: 58,
        roundDurationSeconds: 58,
      );

      expect(rxRound.roundTier, equals('Rx'));
      expect(rxRound.pullupDisplayName, contains('Strict'));
      expect(rxRound.formattedSplit, equals('00:58'));

      final CindyRoundDetail scaledRound = CindyRoundDetail(
        roundNumber: 6,
        pullupVariation: 'band_assisted',
        pullupBandAssistance: 'medium',
        pushupVariation: 'knee',
        squatVariation: 'standard',
        splitTimeSeconds: 420,
        roundDurationSeconds: 75,
      );

      expect(scaledRound.roundTier, equals('Scaled'));
      expect(scaledRound.pullupDisplayName, contains('Banded'));
      expect(scaledRound.pushupDisplayName, contains('Knee'));

      final CindyRoundDetail weightedRound = CindyRoundDetail(
        roundNumber: 1,
        pullupVariation: 'weighted',
        pullupAddedWeightKg: 10.0,
        pushupVariation: 'standard',
        squatVariation: 'goblet',
        squatAddedWeightKg: 24.0,
        splitTimeSeconds: 65,
        roundDurationSeconds: 65,
      );

      expect(weightedRound.roundTier, equals('Weighted'));
      expect(weightedRound.pullupDisplayName, contains('+10.0kg'));
      expect(weightedRound.squatDisplayName, contains('24.0kg'));

      // Test JSON roundtrip
      final Map<String, dynamic> json = scaledRound.toJson();
      final CindyRoundDetail restored = CindyRoundDetail.fromJson(json);
      expect(restored.roundNumber, equals(6));
      expect(restored.pullupVariation, equals('band_assisted'));
      expect(restored.pullupBandAssistance, equals('medium'));
      expect(restored.roundTier, equals('Scaled'));
    });

    test('CindyWorkoutLog calculates total reps and multi-tier progression breakdown', () {
      final List<CindyRoundDetail> rounds = <CindyRoundDetail>[
        // Rounds 1-3 Strict Rx
        CindyRoundDetail(roundNumber: 1, splitTimeSeconds: 60),
        CindyRoundDetail(roundNumber: 2, splitTimeSeconds: 125),
        CindyRoundDetail(roundNumber: 3, splitTimeSeconds: 195),
        // Rounds 4-6 Banded Scaled
        CindyRoundDetail(roundNumber: 4, pullupVariation: 'band_assisted', splitTimeSeconds: 270),
        CindyRoundDetail(roundNumber: 5, pullupVariation: 'band_assisted', splitTimeSeconds: 350),
        CindyRoundDetail(roundNumber: 6, pullupVariation: 'band_assisted', splitTimeSeconds: 435),
      ];

      final CindyWorkoutLog log = CindyWorkoutLog(
        completedRounds: 6,
        partialPullups: 5,
        partialPushups: 8,
        partialSquats: 0,
        rounds: rounds,
      );

      // Total reps = (6 * 30) + 5 + 8 + 0 = 193 reps
      expect(log.totalReps, equals(193));
      expect(log.partialReps, equals(13));
      expect(log.scoreDisplay, equals('6 Rds + 13 Reps (193 reps)'));

      // Overall tier should be Scaled because rounds 4-6 used band assistance
      expect(log.scalingTier, equals('Scaled'));
      expect(log.rxRoundCount, equals(3));
      expect(log.scaledRoundCount, equals(3));
      expect(log.weightedRoundCount, equals(0));
      expect(log.progressionSummary, contains('3 Rx'));
      expect(log.progressionSummary, contains('3 Scaled'));

      // JSON roundtrip
      final Map<String, dynamic> json = log.toJson();
      final CindyWorkoutLog restored = CindyWorkoutLog.fromJson(json);
      expect(restored.completedRounds, equals(6));
      expect(restored.totalReps, equals(193));
      expect(restored.scalingTier, equals('Scaled'));
      expect(restored.rounds.length, equals(6));
    });

    test('CindyWorkoutLog correctly marks pure Rx and pure Weighted sessions', () {
      final CindyWorkoutLog rxLog = CindyWorkoutLog(
        completedRounds: 20,
        partialPullups: 5,
        partialPushups: 3,
        rounds: List.generate(
          20,
          (int i) => CindyRoundDetail(roundNumber: i + 1, splitTimeSeconds: (i + 1) * 58),
        ),
      );

      expect(rxLog.scalingTier, equals('Rx'));
      expect(rxLog.rxRoundCount, equals(20));
      expect(rxLog.progressionSummary, equals('All 20 Rounds Strict Rx'));
      expect(rxLog.totalReps, equals(608)); // (20 * 30) + 5 + 3

      final CindyWorkoutLog weightedLog = CindyWorkoutLog(
        completedRounds: 14,
        rounds: List.generate(
          14,
          (int i) => CindyRoundDetail(
            roundNumber: i + 1,
            pullupVariation: 'weighted',
            pullupAddedWeightKg: 10.0,
            splitTimeSeconds: (i + 1) * 80,
          ),
        ),
      );

      expect(weightedLog.scalingTier, equals('Weighted'));
      expect(weightedLog.weightedRoundCount, equals(14));
      expect(weightedLog.progressionSummary, equals('All 14 Rounds Weighted'));
      expect(weightedLog.totalReps, equals(420));
    });

    test('Mid-workout regression from strict to banded tracks per-round variations accurately', () {
      final List<CindyRoundDetail> rounds = <CindyRoundDetail>[
        CindyRoundDetail(
          roundNumber: 1,
          pullupVariation: 'standard',
          splitTimeSeconds: 52,
        ),
        CindyRoundDetail(
          roundNumber: 2,
          pullupVariation: 'standard',
          splitTimeSeconds: 110,
        ),
        CindyRoundDetail(
          roundNumber: 3,
          pullupVariation: 'band_assisted',
          pullupBandAssistance: 'medium',
          splitTimeSeconds: 172,
        ),
        CindyRoundDetail(
          roundNumber: 4,
          pullupVariation: 'band_assisted',
          pullupBandAssistance: 'medium',
          splitTimeSeconds: 238,
        ),
      ];

      final CindyWorkoutLog log = CindyWorkoutLog(
        completedRounds: 4,
        partialPullups: 5,
        partialPushups: 4,
        rounds: rounds,
      );

      expect(log.rounds[0].roundTier, equals('Rx'));
      expect(log.rounds[1].roundTier, equals('Rx'));
      expect(log.rounds[2].roundTier, equals('Scaled'));
      expect(log.rounds[3].roundTier, equals('Scaled'));

      expect(log.rxRoundCount, equals(2));
      expect(log.scaledRoundCount, equals(2));
      expect(log.scalingTier, equals('Scaled'));
      expect(log.progressionSummary, equals('2 Rx, 2 Scaled'));
      expect(log.totalReps, equals(129)); // (4 * 30) + 5 + 4
    });
  });

  group('StorageService & RecoveryProvider Cindy Persistence Tests', () {
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('StorageService persists, retrieves history and determines PR per tier', () async {
      expect(storage.loadCindyWorkoutLogs(), isEmpty);

      // Log session 1: Rx 18 rounds
      final CindyWorkoutLog session1 = await storage.logCindyWorkout(
        CindyWorkoutLog(
          completedRounds: 18,
          partialPullups: 5,
          rounds: List.generate(18, (int i) => CindyRoundDetail(roundNumber: i + 1)),
        ),
      );
      expect(session1.isPr, isTrue); // First Rx session is a PR

      // Log session 2: Rx 16 rounds (lower than 18)
      final CindyWorkoutLog session2 = await storage.logCindyWorkout(
        CindyWorkoutLog(
          completedRounds: 16,
          rounds: List.generate(16, (int i) => CindyRoundDetail(roundNumber: i + 1)),
        ),
      );
      expect(session2.isPr, isFalse);

      // Log session 3: Rx 21 rounds (higher than 18)
      final CindyWorkoutLog session3 = await storage.logCindyWorkout(
        CindyWorkoutLog(
          completedRounds: 21,
          rounds: List.generate(21, (int i) => CindyRoundDetail(roundNumber: i + 1)),
        ),
      );
      expect(session3.isPr, isTrue); // New Rx PR!

      // Log session 4: Weighted 12 rounds
      final CindyWorkoutLog session4 = await storage.logCindyWorkout(
        CindyWorkoutLog(
          completedRounds: 12,
          rounds: List.generate(
            12,
            (int i) => CindyRoundDetail(
              roundNumber: i + 1,
              pullupVariation: 'weighted',
              pullupAddedWeightKg: 10.0,
            ),
          ),
        ),
      );
      expect(session4.isPr, isTrue); // First Weighted session is PR for Weighted tier

      // Query PRs
      final CindyWorkoutLog? rxPr = storage.getCindyPersonalRecord(tier: 'Rx');
      expect(rxPr?.completedRounds, equals(21));

      final CindyWorkoutLog? weightedPr = storage.getCindyPersonalRecord(tier: 'Weighted');
      expect(weightedPr?.completedRounds, equals(12));

      final List<CindyWorkoutLog> history = storage.getCindyWorkoutHistory();
      expect(history.length, equals(4));
    });

    test('RecoveryProvider manages Cindy logs and notifies listeners', () async {
      expect(recovery.cindyWorkoutLogs, isEmpty);
      expect(recovery.latestCindyWorkoutLog, isNull);

      bool notified = false;
      recovery.addListener(() => notified = true);

      await recovery.logCindyWorkout(
        CindyWorkoutLog(
          completedRounds: 19,
          partialPullups: 5,
          partialPushups: 10,
          rounds: List.generate(19, (int i) => CindyRoundDetail(roundNumber: i + 1)),
        ),
      );

      expect(notified, isTrue);
      expect(recovery.cindyWorkoutLogs.length, equals(1));
      expect(recovery.latestCindyWorkoutLog?.completedRounds, equals(19));
      expect(recovery.getCindyPersonalRecord()?.totalReps, equals(585)); // (19 * 30) + 15
    });

    test('StorageService and SettingsProvider manage cindyEmomBeepEnabled', () async {
      final SettingsProvider settings = SettingsProvider(storage);
      expect(storage.loadCindyEmomBeep(), isFalse);
      expect(settings.cindyEmomBeepEnabled, isFalse);

      bool notified = false;
      settings.addListener(() => notified = true);

      settings.setCindyEmomBeepEnabled(true);
      expect(notified, isTrue);
      expect(settings.cindyEmomBeepEnabled, isTrue);
      expect(storage.loadCindyEmomBeep(), isTrue);

      settings.toggleCindyEmomBeep();
      expect(settings.cindyEmomBeepEnabled, isFalse);
      expect(storage.loadCindyEmomBeep(), isFalse);
    });
  });

  group('CindyWodCard Widget Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
    });

    testWidgets('Renders 20m AMRAP timer, movement checklist, and switches to manual mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel cindy =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'cindy_wod',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider(storage)),
            ChangeNotifierProvider<RecoveryProvider>(create: (_) => RecoveryProvider(storage)),
            ChangeNotifierProvider<BodyCompProvider>(create: (_) => BodyCompProvider(storage)),
            ChangeNotifierProvider<NutritionProvider>(create: (_) => NutritionProvider(storage)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CindyWodCard(
                  exercise: cindy,
                  onCompleted: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title and AMRAP badge
      expect(find.text('Cindy (AMRAP 20)'), findsOneWidget);
      expect(find.text('20M AMRAP'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);

      // Verify movement rows
      expect(find.text('5 Pull-ups'), findsOneWidget);
      expect(find.text('10 Push-ups'), findsOneWidget);
      expect(find.text('15 Squats'), findsOneWidget);

      // Tap to complete 1 round
      await tester.tap(find.text('+1 ROUND COMPLETE'));
      await tester.pumpAndSettle();

      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Live Score: 1 Rds + 0 Reps (30 reps)'), findsOneWidget);
      expect(find.text('ROUND SPLIT TIMELINE (1 Completed)'), findsOneWidget);

      // Switch to Manual Entry Tab
      await tester.tap(find.text('Manual Score Entry'));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL AMRAP ENTRY'), findsOneWidget);
      expect(find.text('Save Manual WOD Score'), findsOneWidget);

      // Switch back to Live Tab
      await tester.tap(find.text('Live AMRAP Timer'));
      await tester.pumpAndSettle();

      // Tap variation pill on pull-ups to open modal
      await tester.tap(find.text('Strict').first);
      await tester.pumpAndSettle();

      expect(find.text('Movement Progressions'), findsOneWidget);
      expect(find.text('1. PULL-UPS (5 REPS)'), findsOneWidget);
      expect(find.text('Banded'), findsOneWidget);

      // Select Banded
      await tester.tap(find.text('Banded'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply Progressions (Scaled)'));
      await tester.pumpAndSettle();

      // Pull-ups row should now show Banded
      expect(find.text('Banded'), findsOneWidget);
    });

    testWidgets('Renders Preview Mode banner and allows switching to Live Mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel cindy =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'cindy_wod',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider(storage)),
            ChangeNotifierProvider<RecoveryProvider>(create: (_) => RecoveryProvider(storage)),
            ChangeNotifierProvider<BodyCompProvider>(create: (_) => BodyCompProvider(storage)),
            ChangeNotifierProvider<NutritionProvider>(create: (_) => NutritionProvider(storage)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CindyWodCard(
                  exercise: cindy,
                  isPreviewMode: true,
                  onCompleted: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for Preview Mode Banner
      expect(find.text('PREVIEW MODE — Test timers & scalings without saving.'), findsOneWidget);
      expect(find.text('GO LIVE'), findsOneWidget);

      // Tap GO LIVE
      await tester.tap(find.text('GO LIVE'));
      await tester.pumpAndSettle();

      // Banner should now be dismissed
      expect(find.text('PREVIEW MODE — Test timers & scalings without saving.'), findsNothing);
    });

    testWidgets('Toggles EMOM Beep mode and renders EMOM pacer indicators',
        (WidgetTester tester) async {
      final MobilityExerciseModel cindy =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'cindy_wod',
      );

      final SettingsProvider settings = SettingsProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<RecoveryProvider>(create: (_) => RecoveryProvider(storage)),
            ChangeNotifierProvider<BodyCompProvider>(create: (_) => BodyCompProvider(storage)),
            ChangeNotifierProvider<NutritionProvider>(create: (_) => NutritionProvider(storage)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CindyWodCard(
                  exercise: cindy,
                  onCompleted: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // By default EMOM Beep is OFF
      expect(find.text('EMOM BEEP OFF'), findsOneWidget);
      expect(find.textContaining('EMOM Min'), findsNothing);

      // Tap to toggle EMOM Beep ON
      await tester.tap(find.text('EMOM BEEP OFF'));
      await tester.pumpAndSettle();

      expect(find.text('EMOM BEEP ON'), findsOneWidget);
      expect(settings.cindyEmomBeepEnabled, isTrue);
      expect(find.text('EMOM Min 1 of 20'), findsOneWidget);
      expect(find.text('Beep in 60s'), findsOneWidget);

      // Start timer and advance 10 seconds
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('19:50'), findsOneWidget);
      expect(find.text('Beep in 50s'), findsOneWidget);
      expect(find.text('EMOM Min 1 of 20'), findsOneWidget);

      // Advance past the first minute mark (total 65 seconds elapsed -> 18:55 remaining)
      await tester.pump(const Duration(seconds: 55));
      expect(find.text('18:55'), findsOneWidget);
      expect(find.text('EMOM Min 2 of 20'), findsOneWidget);
      expect(find.text('Beep in 55s'), findsOneWidget);

      // Pause timer
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      // Tap to toggle EMOM Beep OFF
      await tester.tap(find.text('EMOM BEEP ON'));
      await tester.pumpAndSettle();

      expect(find.text('EMOM BEEP OFF'), findsOneWidget);
      expect(settings.cindyEmomBeepEnabled, isFalse);
      expect(find.textContaining('EMOM Min'), findsNothing);
    });
  });
}
