import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
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

  group('ATG Standards Track Tests', () {
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

    test('ATG Standards cycle generates 7 structured days with valid phases', () {
      final List<DayTemplate> atgDays = ProgramCycle.getAtgStandardsProgram();
      expect(atgDays.length, equals(7));

      // Day 1: Anterior Knee & VMO Armor
      expect(atgDays[0].dayNumber, equals(1));
      expect(atgDays[0].title, contains('Anterior Knee & VMO Armor'));
      expect(atgDays[0].phases.length, greaterThanOrEqualTo(4));

      // Check Poliquin Step-Up
      final ExerciseTemplate poliquin = atgDays[0]
          .phases
          .expand((p) => p.exercises)
          .firstWhere((e) => e.liftId == 'poliquin_step_up');
      expect(poliquin.bodyweightPercentage, equals(66));
      expect(poliquin.setScheme, contains('5 Sets of 20 Reps'));

      // Check Jefferson Curl
      final ExerciseTemplate jCurl = atgDays[0]
          .phases
          .expand((p) => p.exercises)
          .firstWhere((e) => e.liftId == 'jefferson_curl');
      expect(jCurl.bodyweightPercentage, equals(25));

      // Day 2: Hip Range & Posterior Chain (includes forearm rotation & wrist extension)
      expect(atgDays[1].title, contains('Hip Range & Posterior Chain'));
      final ExerciseTemplate splitSquat = atgDays[1]
          .phases
          .expand((p) => p.exercises)
          .firstWhere((e) => e.liftId == 'atg_split_squat');
      expect(splitSquat.bodyweightPercentage, equals(25));

      final List<String> day2LiftIds = atgDays[1]
          .phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day2LiftIds, contains('forearm_pronation_supination'));
      expect(day2LiftIds, contains('dumbbell_wrist_extension'));

      // Day 3: Active ROKP & Ankle Transformation
      expect(atgDays[2].isActiveRecovery, isTrue);
      expect(atgDays[2].title, contains('Ankle Transformation'));

      // Day 4: Deep Squat & Vertical Press/Pull (includes wrist flexion)
      expect(atgDays[3].title, contains('Deep Squat'));
      final List<String> day4LiftIds = atgDays[3]
          .phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day4LiftIds, contains('dumbbell_wrist_flexion'));

      // Day 5: Posterior Armor & Trunk Integrity (includes floor wrist prep)
      expect(atgDays[4].title, contains('Posterior Armor'));
      final List<String> day5LiftIds = atgDays[4]
          .phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day5LiftIds, contains('quadruped_wrist_loading'));

      // Day 6 & 7: Active recovery / athletic bounce
      expect(atgDays[5].isActiveRecovery, isTrue);
      expect(atgDays[6].isActiveRecovery, isTrue);
    });

    test('Dynamic % BW calculation scales with logged bodyweight from BodyCompProvider', () {
      final ExerciseTemplate stepUp = ExerciseTemplate(
        name: 'Poliquin Step-Up',
        liftId: 'poliquin_step_up',
        setScheme: '5x20',
        bodyweightPercentage: 66,
      );

      final ExerciseTemplate splitSquat = ExerciseTemplate(
        name: 'ATG Split Squat',
        liftId: 'atg_split_squat',
        setScheme: '5x5',
        bodyweightPercentage: 25,
      );

      final ExerciseTemplate tibRaise = ExerciseTemplate(
        name: 'Tibialis Anterior Raises',
        liftId: 'tibialis_raise',
        setScheme: '3x20',
        bodyweightPercentage: 12.5,
      );

      // At 80 kg athlete bodyweight
      // 66% of 80 = 52.8 -> rounded to nearest 0.5 kg = 53.0 kg
      expect(
        stepUp.calculateTargetWeight(
          week: 1,
          currentMaxes: const <String, double>{},
          athleteBodyweightKg: 80,
        ),
        equals(53.0),
      );

      // 25% of 80 = 20.0 kg
      expect(
        splitSquat.calculateTargetWeight(
          week: 1,
          currentMaxes: const <String, double>{},
          athleteBodyweightKg: 80,
        ),
        equals(20.0),
      );

      // 12.5% of 80 = 10.0 kg
      expect(
        tibRaise.calculateTargetWeight(
          week: 1,
          currentMaxes: const <String, double>{},
          athleteBodyweightKg: 80,
        ),
        equals(10.0),
      );

      // At 72.5 kg athlete bodyweight
      // 25% of 72.5 = 18.125 -> rounded to 18.0 kg
      expect(
        splitSquat.calculateTargetWeight(
          week: 1,
          currentMaxes: const <String, double>{},
          athleteBodyweightKg: 72.5,
        ),
        equals(18.0),
      );

      // Fallback default (85 kg) when unlogged (omitted bodyweight)
      // 25% of 85.0 = 21.25 -> rounded to 21.5 kg
      expect(
        splitSquat.calculateTargetWeight(
          week: 1,
          currentMaxes: const <String, double>{},
        ),
        equals(21.5),
      );
    });

    test('ProgramProvider switches to ATG Standards track and adjusts day clamp to 7', () {
      programProvider.setTrainingTrack(TrainingTrack.atgStandards);
      expect(programProvider.isAtgTrack, isTrue);
      expect(programProvider.isRetestWeek, isFalse);
      expect(programProvider.days.length, equals(7));

      programProvider.selectDay(7);
      expect(programProvider.currentDay, equals(7));

      // Verify currentDayTemplate returns ATG day
      final DayTemplate today = programProvider.currentDayTemplate;
      expect(today.title, isNotEmpty);
    });

    test('WorkoutSession correctly infers atgStandards track from notes, tags, or exercises', () {
      final WorkoutSession sessionWithTag = WorkoutSession(
        id: '1',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        logs: const <ExerciseLog>[],
        jointStrainTags: const <String>['atg', 'knee_ability'],
      );
      expect(sessionWithTag.inferredTrack, equals(TrainingTrack.atgStandards));

      final WorkoutSession sessionWithExercise = WorkoutSession(
        id: '2',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        logs: <ExerciseLog>[
          ExerciseLog(
            exerciseName: 'ATG Split Squat',
            liftId: 'atg_split_squat',
            sets: <CompletedSet>[],
          ),
          ExerciseLog(
            exerciseName: 'Poliquin Step-Up (45° Slant)',
            liftId: 'poliquin_step_up',
            sets: <CompletedSet>[],
          ),
        ],
      );
      expect(sessionWithExercise.inferredTrack, equals(TrainingTrack.atgStandards));
    });

    test('ActivityExpenditureService calculates ATG workout expenditure with MET 4.8', () {
      final WorkoutSession atgSession = WorkoutSession(
        id: 'test_atg',
        sessionTitle: 'ATG Standards Session',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        durationSeconds: 3600, // 60 mins
        track: TrainingTrack.atgStandards.name,
        logs: <ExerciseLog>[
          ExerciseLog(
            exerciseName: 'Poliquin Step-Up',
            liftId: 'poliquin_step_up',
            sets: <CompletedSet>[
              CompletedSet(setIndex: 0, weight: 50, reps: 20),
            ],
          ),
        ],
      );

      final double met = ActivityExpenditureService.calculateSessionMet(atgSession);
      expect(met, closeTo(4.8, 0.1));
      expect(
        ActivityExpenditureService.formatSessionActivityName(atgSession),
        contains('ATG Standards'),
      );
    });

    test('RecoveryEngineService returns dedicated ATG active recovery prescription', () {
      final GeneratedRecoveryRoutine routine = RecoveryEngineService.generateRoutine(
        ratioAnalyses: const <LiftRatioAnalysis>[],
        lastSession: null,
        trainingTrack: TrainingTrack.atgStandards,
      );

      expect(routine.phaseGroups, isNotEmpty);
      expect(
        routine.phaseGroups.any(
          (g) => g.title.contains('ROKP') || g.title.contains('Reverse Sled'),
        ),
        isTrue,
      );
    });

    testWidgets('DashboardScreen renders track selector dropdown and switches to ATG Standards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Populate body comp entry for dynamic weight scaling
      await bodyCompProvider.addEntry(
        BodyCompositionEntry.create(
          weightLb: 82.0 * 2.20462,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: <ChangeNotifierProvider<dynamic>>[
            ChangeNotifierProvider<ProgramProvider>.value(value: programProvider),
            ChangeNotifierProvider<LiftProvider>.value(value: liftProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
            ChangeNotifierProvider<GoalProvider>.value(value: goalProvider),
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

      // Ensure dropdown button is visible
      await tester.ensureVisible(find.text('TRAINING TRACK'));
      await tester.pumpAndSettle();

      // Open the track selection modal
      await tester.tap(find.text('TRAINING TRACK'));
      await tester.pumpAndSettle();

      // Verify ATG Standards tile exists in the dropdown modal
      expect(find.text('Select Training Track'), findsOneWidget);
      expect(find.text('ATG Standards'), findsOneWidget);
      expect(find.text('Joint Armor'), findsOneWidget);

      // Select ATG Standards track
      await tester.tap(find.text('ATG Standards'));
      await tester.pumpAndSettle();

      // Verify track switched
      expect(programProvider.isAtgTrack, isTrue);
      expect(find.text('ATG Standards'), findsWidgets);
      expect(find.text('JOINT ARMOR'), findsWidgets);
      expect(find.text("TODAY'S ATG STANDARDS SESSION"), findsOneWidget);
    });
  });
}
