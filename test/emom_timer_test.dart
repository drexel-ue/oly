import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/emom_timer_card.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EMOM Interval Timer vs Hold Timer Tests', () {
    test('WorkoutWeightHelper differentiates EMOM workouts from isometric holds', () {
      // EMOM exercises MUST NOT be classified as timed holds
      expect(
        WorkoutWeightHelper.isEmomExercise(
          'Pull-ups / Chin-ups (1–10 Method)',
          '10–30 Min EMOM (1–10 Reps/Min)',
          'emom_pull_ups',
        ),
        isTrue,
      );
      expect(
        WorkoutWeightHelper.isTimedExercise(
          'Pull-ups / Chin-ups (1–10 Method)',
          '10–30 Min EMOM (1–10 Reps/Min)',
        ),
        isFalse,
      );

      // Extract reps count returns target reps per minute, NOT minute duration in seconds
      final int reps = WorkoutWeightHelper.extractRepsCount('10–30 Min EMOM (1–10 Reps/Min)');
      expect(reps, equals(5)); // (1+10)~/2 = 5 reps/min, NOT 600s

      // Pure isometric holds ARE classified as timed holds
      expect(
        WorkoutWeightHelper.isTimedExercise('Passive Bar Hang / Decompression', '2 Sets of 60s Hold'),
        isTrue,
      );
      expect(
        WorkoutWeightHelper.isEmomExercise('Passive Bar Hang / Decompression', '2 Sets of 60s Hold', 'active_hang'),
        isFalse,
      );
    });

    testWidgets('EmomTimerCard renders interval controls, minute countdown, and work/rest states', (tester) async {
      int completedRound = -1;
      int completedReps = -1;
      int updatedTotalRounds = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmomTimerCard(
                exerciseName: 'Pull-ups / Chin-ups',
                targetRepsPerMin: 5,
                activeRoundIndex: 0,
                totalRounds: 20,
                isAllCompleted: false,
                onRoundCompleted: ({required roundIndex, required reps, required weight}) {
                  completedRound = roundIndex;
                  completedReps = reps;
                },
                onTotalRoundsChanged: (newRounds) {
                  updatedTotalRounds = newRounds;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('EMOM INTERVAL TIMER'), findsOneWidget);
      expect(find.text('BEEP ON'), findsOneWidget);

      // Verify Round and Initial Countdown
      expect(find.text('ROUND 1 OF 20'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('WORK'), findsOneWidget);
      expect(find.text('Perform 5 reps'), findsOneWidget);

      // Verify Duration Presets
      expect(find.text('10m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('20m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);

      // Test changing duration preset to 15m
      await tester.tap(find.text('15m'));
      await tester.pumpAndSettle();
      expect(updatedTotalRounds, equals(15));
      expect(find.text('ROUND 1 OF 15'), findsOneWidget);

      // Verify Buttons
      expect(find.text('START EMOM'), findsOneWidget);

      // Start the timer
      await tester.tap(find.text('START EMOM'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('REST NOW'), findsOneWidget);

      // Tap REST NOW to transition to rest phase
      await tester.tap(find.text('REST NOW'));
      await tester.pumpAndSettle();

      expect(find.text('REST'), findsOneWidget);
      expect(completedRound, equals(0));
      expect(completedReps, equals(5));
    });

    testWidgets('WorkoutSessionScreen renders EmomTimerCard for EMOM track and avoids HoldStopwatchCard for EMOM exercise', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);

      final ProgramProvider program = ProgramProvider(storage);
      program.setTrainingTrack(TrainingTrack.emomEight);

      final LiftProvider lifts = LiftProvider(storage);
      final SettingsProvider settings = SettingsProvider(storage);
      final InjuryProvider injury = InjuryProvider(storage);
      final BodyCompProvider bodyComp = BodyCompProvider(storage);
      final ActiveSessionProvider activeSession = ActiveSessionProvider();

      final DayTemplate emomDay1 = ProgramCycle.getEmomEightProgram().first;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProgramProvider>.value(value: program),
            ChangeNotifierProvider<LiftProvider>.value(value: lifts),
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<InjuryProvider>.value(value: injury),
            ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
            ChangeNotifierProvider<ActiveSessionProvider>.value(value: activeSession),
          ],
          child: MaterialApp(
            home: WorkoutSessionScreen(
              dayTemplate: emomDay1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure EmomTimerCard is rendered for the EMOM exercise
      expect(find.byType(EmomTimerCard), findsOneWidget);

      // Ensure the EMOM chips are labeled 'Min 1: 5 reps' instead of 'Set 1: 600s'
      expect(find.text('Min 1: 5 reps'), findsOneWidget);
      expect(find.text('Min 2: 5 reps'), findsOneWidget);

      // Verify that the EMOM header and target text are displayed
      expect(find.text('EMOM INTERVAL TIMER'), findsOneWidget);
      expect(find.textContaining('reps/min EMOM'), findsOneWidget);
    });
  });
}
