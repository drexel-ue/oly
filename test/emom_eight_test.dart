import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/providers/gtg_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/activity_expenditure_service.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EMOM 8 Track Tests', () {
    late StorageService storage;
    late GoalProvider goalProvider;
    late ProgramProvider programProvider;
    late LiftProvider liftProvider;
    late SettingsProvider settingsProvider;
    late InjuryProvider injuryProvider;
    late RecoveryProvider recoveryProvider;
    late BodyCompProvider bodyCompProvider;
    late NutritionProvider nutritionProvider;
    late GripHangProvider gripHangProvider;
    late C25kProvider c25kProvider;
    late BreathingProvider breathingProvider;
    late FastingProvider fastingProvider;
    late GtgProvider gtgProvider;
    late ActiveSessionProvider activeSessionProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      goalProvider = GoalProvider(storage);
      programProvider = ProgramProvider(storage);
      liftProvider = LiftProvider(storage);
      settingsProvider = SettingsProvider(storage);
      injuryProvider = InjuryProvider(storage);
      recoveryProvider = RecoveryProvider(storage);
      bodyCompProvider = BodyCompProvider(storage);
      nutritionProvider = NutritionProvider(storage);
      gripHangProvider = GripHangProvider(storage);
      c25kProvider = C25kProvider(storage);
      breathingProvider = BreathingProvider(storage);
      fastingProvider = FastingProvider(storage);
      gtgProvider = GtgProvider(storage);
      activeSessionProvider = ActiveSessionProvider();
    });

    test('EMOM 8 program generates 8 continuous movement days covering all patterns', () {
      final List<DayTemplate> emomDays = ProgramCycle.getEmomEightProgram();
      expect(emomDays.length, equals(8));

      // Day 1: Vertical Pull (Pull-ups)
      expect(emomDays[0].dayNumber, equals(1));
      expect(emomDays[0].title, contains('Vertical Pull'));
      expect(emomDays[0].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_pull_ups')), isTrue);
      final ExerciseTemplate pullUp = emomDays[0].phases.expand((p) => p.exercises).firstWhere((e) => e.liftId == 'emom_pull_ups');
      expect(pullUp.setScheme, contains('10–30 Min EMOM'));
      expect(pullUp.name, contains('1–10 Method'));
      expect(pullUp.notes, contains('Submaximal quality volume'));

      // Day 2: Downward Push (Dips)
      expect(emomDays[1].dayNumber, equals(2));
      expect(emomDays[1].title, contains('Downward Push'));
      expect(emomDays[1].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_dips')), isTrue);

      // Day 3: Knee Dominant / Squat
      expect(emomDays[2].dayNumber, equals(3));
      expect(emomDays[2].title, contains('Knee Dominant'));
      expect(emomDays[2].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_squats')), isTrue);

      // Day 4: Horizontal Pull (Inverted Rows)
      expect(emomDays[3].dayNumber, equals(4));
      expect(emomDays[3].title, contains('Horizontal Pull'));
      expect(emomDays[3].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_inverted_rows')), isTrue);

      // Day 5: Horizontal Push (Push-ups)
      expect(emomDays[4].dayNumber, equals(5));
      expect(emomDays[4].title, contains('Horizontal Push'));
      expect(emomDays[4].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_push_ups')), isTrue);

      // Day 6: Unilateral Leg (Lunges)
      expect(emomDays[5].dayNumber, equals(6));
      expect(emomDays[5].title, contains('Unilateral Leg'));
      expect(emomDays[5].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_lunges')), isTrue);

      // Day 7: Vertical Push (Pike Push-ups)
      expect(emomDays[6].dayNumber, equals(7));
      expect(emomDays[6].title, contains('Vertical Push'));
      expect(emomDays[6].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_pike_push_ups')), isTrue);

      // Day 8: Hip Hinge / Posterior Chain (RDLs / Swings)
      expect(emomDays[7].dayNumber, equals(8));
      expect(emomDays[7].title, contains('Hip Hinge'));
      expect(emomDays[7].phases.any((p) => p.exercises.any((e) => e.liftId == 'emom_hinges')), isTrue);
    });

    test('ProgramProvider rolling cycle progression and rest day shift toggle', () async {
      programProvider.setTrainingTrack(TrainingTrack.emomEight);
      expect(programProvider.activeTrack, equals(TrainingTrack.emomEight));
      expect(programProvider.isEmomTrack, isTrue);
      expect(programProvider.days.length, equals(8));

      // Initial day is 1
      programProvider.selectDay(1);
      expect(programProvider.currentDay, equals(1));
      expect(programProvider.isEmomRestDay, isFalse);

      // Toggle rest day (shift today)
      programProvider.toggleEmomRestDay(forceState: true);
      expect(programProvider.isEmomRestDay, isTrue);
      expect(programProvider.cycle.isEmomRestDay, isTrue);
      expect(programProvider.cycle.emomRestDayDate, isNotNull);

      // Current workout remains queued on Day 1
      expect(programProvider.currentDay, equals(1));

      // Toggle rest day off
      programProvider.toggleEmomRestDay(forceState: false);
      expect(programProvider.isEmomRestDay, isFalse);
      expect(programProvider.cycle.isEmomRestDay, isFalse);

      // Save a workout session on Day 1 -> advances rolling queue to Day 2
      final WorkoutSession session = WorkoutSession(
        id: 'emom_session_1',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        track: TrainingTrack.emomEight.name,
        sessionTitle: 'Day 1: Vertical Pull (Pull-ups / Chin-ups)',
        logs: <ExerciseLog>[],
      );
      await programProvider.saveWorkoutSession(session);

      expect(programProvider.currentDay, equals(2));
      expect(programProvider.isEmomRestDay, isFalse);

      // Complete Day 8 -> rolls over to Day 1, Cycle 2
      programProvider.selectDay(8);
      final WorkoutSession session8 = WorkoutSession(
        id: 'emom_session_8',
        date: DateTime.now(),
        dayNumber: 8,
        weekNumber: 1,
        cycleNumber: 1,
        track: TrainingTrack.emomEight.name,
        sessionTitle: 'Day 8: Hip Hinge / Posterior Chain',
        logs: <ExerciseLog>[],
      );
      await programProvider.saveWorkoutSession(session8);

      expect(programProvider.currentDay, equals(1));
      expect(programProvider.currentCycle, equals(2));
    });

    test('WorkoutSession correctly detects and infers emomEight track and format display title', () {
      final WorkoutSession session = WorkoutSession(
        id: 'session_emom',
        date: DateTime.now(),
        dayNumber: 2,
        weekNumber: 1,
        cycleNumber: 1,
        track: 'emomeight',
        logs: <ExerciseLog>[
          ExerciseLog(
            exerciseName: 'Parallel Bar Dips',
            liftId: 'emom_dips',
            sets: <CompletedSet>[
              CompletedSet(setIndex: 1, reps: 10, weight: 0),
            ],
          ),
        ],
      );

      expect(session.inferredTrack, equals(TrainingTrack.emomEight));
      expect(session.displayTitle, contains('Day 2: Downward Push (Dips)'));
    });

    test('ActivityExpenditureService calculates EMOM 8 workout expenditure with MET 6.0', () {
      final WorkoutSession session = WorkoutSession(
        id: 'session_emom_burn',
        date: DateTime.now(),
        dayNumber: 3,
        weekNumber: 1,
        cycleNumber: 1,
        track: TrainingTrack.emomEight.name,
        logs: <ExerciseLog>[],
      );

      final double met = ActivityExpenditureService.calculateSessionMet(session);
      expect(met, equals(6.0));

      final String activityName = ActivityExpenditureService.formatSessionActivityName(session);
      expect(activityName, contains('EMOM 8'));
    });

    test('RecoveryEngineService returns dedicated EMOM 8 active recovery prescription', () {
      final GeneratedRecoveryRoutine routine = RecoveryEngineService.generateRoutine(
        ratioAnalyses: <LiftRatioAnalysis>[],
        lastSession: null,
        trainingTrack: TrainingTrack.emomEight,
      );

      expect(routine.phaseGroups.length, equals(4));
      expect(routine.diagnosticReasons.first, contains('EMOM 8 Active Recovery'));
      expect(routine.exercises.any((e) => e.id == 'barbell_dead_hang' || e.id == 'kettlebell_mile'), isTrue);
    });

    testWidgets('DashboardScreen renders EMOM 8 track selector, day pills, and Rest Day Shift button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      programProvider.setTrainingTrack(TrainingTrack.emomEight);
      programProvider.selectDay(1);

      await tester.pumpWidget(
        MultiProvider(
          providers: <ChangeNotifierProvider<dynamic>>[
            ChangeNotifierProvider<GoalProvider>.value(value: goalProvider),
            ChangeNotifierProvider<ProgramProvider>.value(value: programProvider),
            ChangeNotifierProvider<LiftProvider>.value(value: liftProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
            ChangeNotifierProvider<InjuryProvider>.value(value: injuryProvider),
            ChangeNotifierProvider<RecoveryProvider>.value(value: recoveryProvider),
            ChangeNotifierProvider<BodyCompProvider>.value(value: bodyCompProvider),
            ChangeNotifierProvider<NutritionProvider>.value(value: nutritionProvider),
            ChangeNotifierProvider<GripHangProvider>.value(value: gripHangProvider),
            ChangeNotifierProvider<C25kProvider>.value(value: c25kProvider),
            ChangeNotifierProvider<BreathingProvider>.value(value: breathingProvider),
            ChangeNotifierProvider<FastingProvider>.value(value: fastingProvider),
            ChangeNotifierProvider<GtgProvider>.value(value: gtgProvider),
            ChangeNotifierProvider<ActiveSessionProvider>.value(value: activeSessionProvider),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header Track Card
      expect(find.text('EMOM 8 (1 Exercise/Day)'), findsOneWidget);
      expect(find.text('MINIMALIST DENSITY'), findsOneWidget);

      // Check Session Card
      expect(find.text("TODAY'S EMOM 8 SESSION"), findsOneWidget);
      expect(find.text('1. Pull'), findsOneWidget);
      expect(find.text('2. Dip'), findsOneWidget);
      expect(find.text('3. Squat'), findsOneWidget);
      expect(find.text('8. Hinge'), findsOneWidget);

      // Check Rest Day Shift button
      final Finder shiftButton = find.text('Take Rest Day (Shift Cycle +1)');
      expect(shiftButton, findsOneWidget);
      await tester.ensureVisible(shiftButton);

      // Tap the Shift Cycle / Rest Day button
      await tester.tap(shiftButton);
      await tester.pumpAndSettle();

      // Confirm Rest Day state is now active on the Dashboard
      expect(programProvider.isEmomRestDay, isTrue);
      expect(find.text('EMOM 8 • REST & RECOVERY ACTIVE'), findsOneWidget);
      expect(find.text('Rest Day'), findsOneWidget);
      expect(find.text('Rest & Recovery Mode Active'), findsOneWidget);
      final Finder resumeButton = find.text('Resume Workout / Cancel Rest Day');
      expect(resumeButton, findsOneWidget);
      await tester.ensureVisible(resumeButton);

      // Tap Resume Workout
      await tester.tap(resumeButton);
      await tester.pumpAndSettle();

      expect(programProvider.isEmomRestDay, isFalse);
      expect(find.text("TODAY'S EMOM 8 SESSION"), findsOneWidget);
    });
  });
}
