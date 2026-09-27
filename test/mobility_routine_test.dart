import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/mobility/mobility_routine_screen.dart';
import 'package:oly/widgets/hold_stopwatch_card.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobility & Hypertrophy Routine Tests', () {
    late StorageService storage;
    late GoalProvider goalProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      goalProvider = GoalProvider(storage);
    });

    test('Mobility standards contain separate 90/90 and Butterfly movements', () {
      final List<MobilityExerciseModel> exercises =
          MobilityExerciseModel.defaultExercises();

      final MobilityExerciseModel hip9090 =
          exercises.firstWhere((e) => e.id == 'hip_90_90_switch');
      final MobilityExerciseModel butterfly =
          exercises.firstWhere((e) => e.id == 'seated_butterfly');

      expect(hip9090.name, contains('90/90 Hip Switches'));
      expect(hip9090.focusArea, equals(MobilityFocusArea.hipCapsule));

      expect(butterfly.name, contains('Butterfly'));
      expect(butterfly.focusArea, equals(MobilityFocusArea.hipCapsule));
      expect(butterfly.id, isNot(equals(hip9090.id)));

      // Verify Dane Miller Miracle Grow is present
      final MobilityExerciseModel miracleGrow =
          exercises.firstWhere((e) => e.id == 'miracle_grow');
      expect(miracleGrow.name, contains('Miracle Grow'));
      expect(miracleGrow.focusArea, equals(MobilityFocusArea.arms));

      // Verify ATG Split Squat is present
      final MobilityExerciseModel splitSquat =
          exercises.firstWhere((e) => e.id == 'atg_split_squat');
      expect(splitSquat.name, contains('ATG Split Squat'));
      expect(splitSquat.focusArea, equals(MobilityFocusArea.quadriceps));
    });

    test('Mobility GoalTrack has milestones for both 90/90 and Butterfly', () {
      final GoalTrack? mobilityGoal =
          goalProvider.getGoal('goal_mobility_hypertrophy');
      expect(mobilityGoal, isNotNull);

      final List<String> milestoneIds =
          mobilityGoal!.milestones.map((m) => m.id).toList();

      expect(milestoneIds, contains('hip_90_90_flow_180s'));
      expect(milestoneIds, contains('seated_butterfly_120s'));
      expect(milestoneIds, contains('atg_split_squat_50'));
      expect(milestoneIds, contains('jefferson_curl_50'));
      expect(milestoneIds, contains('seated_good_morning_50'));
      expect(milestoneIds, contains('couch_stretch_120s'));
      expect(milestoneIds, contains('miracle_grow_50'));
      expect(milestoneIds, contains('shoulder_ext_rot_10'));
      expect(milestoneIds, contains('elephant_walk_45'));
    });

    testWidgets('Renders MobilityRoutineScreen with tabs and standards list',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: <ChangeNotifierProvider<dynamic>>[
            ChangeNotifierProvider<GoalProvider>.value(value: goalProvider),
          ],
          child: const MaterialApp(
            home: MobilityRoutineScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header and title
      expect(find.text('Mobility & Hypertrophy'), findsWidgets);
      expect(find.text('Standards & Milestones'), findsOneWidget);
      expect(find.text('Weekly Curriculum'), findsOneWidget);

      // Verify Level card
      expect(find.textContaining('Level 1: Foundation'), findsOneWidget);

      // Verify milestone cards are rendered
      expect(find.text('ATG Split Squat 50% BW'), findsOneWidget);
      expect(find.text('90/90 Hip Transitions 3:00'), findsOneWidget);
      expect(find.text('Seated Butterfly 2:00'), findsOneWidget);

      // Switch to Weekly Curriculum tab
      await tester.tap(find.text('Weekly Curriculum'));
      await tester.pumpAndSettle();

      // Verify weekdays chips exist
      expect(find.textContaining('Mon'), findsWidgets);
      expect(find.text('EXERCISE PROTOCOLS'), findsOneWidget);
      expect(find.text('Start Live Workout Session'), findsOneWidget);
    });

    test('ProgramCycle.getMobilityProgram generates 7 cohesive daily sessions with separate 90/90 and Butterfly', () {
      final List<DayTemplate> mobilityDays = ProgramCycle.getMobilityProgram();
      expect(mobilityDays.length, equals(7));

      // Day 1: Lower Hypertrophy + ATG Knee/Ankle
      final DayTemplate day1 = mobilityDays[0];
      expect(day1.title, contains('Day 1: Lower Hypertrophy'));
      final List<String> day1Lifts = day1.phases.expand((p) => p.exercises).map((e) => e.liftId).toList();
      expect(day1Lifts, contains('slant_board_calf_stretch'));
      expect(day1Lifts, contains('tibialis_raise'));
      expect(day1Lifts, contains('atg_split_squat'));
      expect(day1Lifts, contains('back_squat'));

      // Day 3: Posterior Chain & Hip Capsule Flow (Separate 90/90 and Butterfly)
      final DayTemplate day3 = mobilityDays[2];
      final List<String> day3Lifts = day3.phases.expand((p) => p.exercises).map((e) => e.liftId).toList();
      expect(day3Lifts, contains('hip_90_90_switch'));
      expect(day3Lifts, contains('seated_butterfly'));
      expect(day3Lifts, contains('elephant_walk'));
      expect(day3Lifts, contains('jefferson_curl'));
      expect(day3Lifts, contains('seated_good_morning'));

      // Verify fixed weights
      final ExerciseTemplate butterfly = day3.phases
          .expand((p) => p.exercises)
          .firstWhere((e) => e.liftId == 'seated_butterfly');
      expect(butterfly.fixedWeightKg, equals(0));
    });

    test('ProgramProvider switches between Mobility and Olympic tracks seamlessly', () {
      final ProgramProvider program = ProgramProvider(storage);

      // Default is mobility
      expect(program.activeTrack, equals(TrainingTrack.mobility));
      expect(program.isMobilityTrack, isTrue);
      expect(program.days.length, equals(7));

      // Switch to Olympic
      program.setTrainingTrack(TrainingTrack.olympic);
      expect(program.activeTrack, equals(TrainingTrack.olympic));
      expect(program.isMobilityTrack, isFalse);
      expect(program.days.length, equals(6));

      // Switch back to Mobility
      program.setTrainingTrack(TrainingTrack.mobility);
      expect(program.activeTrack, equals(TrainingTrack.mobility));
      expect(program.isMobilityTrack, isTrue);
      expect(program.days.length, equals(7));
    });

    test('YouTube search URLs query strictly the movement name without extra tutorial strings', () {
      final List<MobilityExerciseModel> exercises =
          MobilityExerciseModel.defaultExercises();

      // Check exercises with generated YouTube search URLs
      final MobilityExerciseModel ergRow =
          exercises.firstWhere((e) => e.id == 'zone2_cardio_row');
      expect(ergRow.videoUrl, equals('https://www.youtube.com/results?search_query=${Uri.encodeComponent('Concept2 Ergometer Rowing')}'));

      final MobilityExerciseModel cindy =
          exercises.firstWhere((e) => e.id == 'cindy_wod');
      expect(cindy.videoUrl, equals('https://www.youtube.com/results?search_query=${Uri.encodeComponent('Crossfit Cindy')}'));

      final MobilityExerciseModel cableCurl =
          exercises.firstWhere((e) => e.id == 'bayesian_cable_curl');
      expect(cableCurl.videoUrl, equals('https://www.youtube.com/results?search_query=${Uri.encodeComponent('Bayesian Cable Curl')}'));

      // Ensure no exercise search query contains Catalyst Athletics or weightlifting tutorial
      for (final MobilityExerciseModel ex in exercises) {
        expect(ex.videoUrl.contains('Catalyst+Athletics'), isFalse,
            reason: 'Exercise ${ex.name} should not append Catalyst Athletics');
        expect(ex.videoUrl.contains('weightlifting+tutorial'), isFalse,
            reason: 'Exercise ${ex.name} should not append weightlifting tutorial');
        expect(ex.videoUrl.contains('exercise+tutorial'), isFalse,
            reason: 'Exercise ${ex.name} should not append exercise tutorial');
      }
    });

    test('Forearm work and pull-up iso holds are present in exercises, curriculum, and goals', () {
      final List<MobilityExerciseModel> exercises =
          MobilityExerciseModel.defaultExercises();

      final MobilityExerciseModel hammer =
          exercises.firstWhere((e) => e.id == 'hammer_curls');
      expect(hammer.name, contains('Hammer Curls'));
      expect(hammer.videoUrl, contains(Uri.encodeComponent('Dumbbell Hammer Curls')));

      final MobilityExerciseModel wristCurls =
          exercises.firstWhere((e) => e.id == 'dumbbell_wrist_curls');
      expect(wristCurls.name, contains('Wrist Curls'));
      expect(wristCurls.focusArea, equals(MobilityFocusArea.gripStrength));
      expect(wristCurls.videoUrl, contains(Uri.encodeComponent('Dumbbell Wrist Curls')));

      final MobilityExerciseModel pullupIso =
          exercises.firstWhere((e) => e.id == 'pullup_isometric_hold');
      expect(pullupIso.name, contains('Pull-Up Isometric Hold'));
      expect(pullupIso.description, contains("golfer's elbow"));
      expect(pullupIso.videoUrl, contains(Uri.encodeComponent('Pull Up Isometric Hold')));

      // Check Milestones in GoalTrack
      final GoalTrack? mobilityGoal =
          goalProvider.getGoal('goal_mobility_hypertrophy');
      expect(mobilityGoal, isNotNull);
      final List<String> milestoneIds =
          mobilityGoal!.milestones.map((m) => m.id).toList();
      expect(milestoneIds, contains('hammer_curls_35'));
      expect(milestoneIds, contains('wrist_curls_25'));
      expect(milestoneIds, contains('pullup_iso_hold_30s'));

      // Check Curriculum Day 2 and Day 5
      final List<DayTemplate> mobilityDays = ProgramCycle.getMobilityProgram();
      final DayTemplate day2 = mobilityDays[1];
      final List<String> day2Lifts = day2.phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day2Lifts, contains('hammer_curls'));
      expect(day2Lifts, contains('dumbbell_wrist_curls'));
      expect(day2Lifts, contains('pullup_isometric_hold'));

      final DayTemplate day5 = mobilityDays[4];
      final List<String> day5Lifts = day5.phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day5Lifts, contains('hammer_curls'));
      expect(day5Lifts, contains('dumbbell_wrist_curls'));
      expect(day5Lifts, contains('pullup_isometric_hold'));
    });

    test('WorkoutWeightHelper identifies timed holds and parses duration schemes', () {
      // Detection
      expect(WorkoutWeightHelper.isTimedExercise("Pull-Up Isometric Hold (Golfer's Elbow Iso)"), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Wall Couch Stretch'), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Slant Board Calf Stretch'), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Seated Butterfly & PNF Adductor Stretch'), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Deep Squat Pry with Kettlebell'), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Dead Hang'), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Custom Lift', '3 Sets of 30s Hold'), isTrue);
      expect(WorkoutWeightHelper.isTimedExercise('Bench Press', '3 Sets of 10 Reps'), isFalse);

      // Reps / Seconds extraction
      expect(WorkoutWeightHelper.extractRepsCount('3 Sets of 30s Hold'), equals(30));
      expect(WorkoutWeightHelper.extractRepsCount('2 Sets of 90s Hold'), equals(90));
      expect(WorkoutWeightHelper.extractRepsCount('2 Sets of 120s Hold'), equals(120));
      expect(WorkoutWeightHelper.extractRepsCount('3 Sets of 60s Hold'), equals(60));
      expect(WorkoutWeightHelper.extractRepsCount('3 Sets of 45s Hold'), equals(45));
      expect(WorkoutWeightHelper.extractRepsCount('4 Sets of 8 Reps'), equals(8));
    });

    testWidgets('HoldStopwatchCard renders and allows adjustment and completion', (tester) async {
      int completedIndex = -1;
      int completedElapsed = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldStopwatchCard(
              exerciseName: "Pull-Up Isometric Hold (Golfer's Elbow Iso)",
              targetSeconds: 30,
              activeSetIndex: 0,
              totalSets: 3,
              isAllCompleted: false,
              onCompleteHold: ({required setIndex, required elapsedSeconds}) {
                completedIndex = setIndex;
                completedElapsed = elapsedSeconds;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify timer labels and badges
      expect(find.text('HOLD STOPWATCH'), findsOneWidget);
      expect(find.text('SET 1 OF 3'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
      expect(find.text('Target: 30s hold'), findsOneWidget);
      expect(find.text('START HOLD'), findsOneWidget);

      // Tap +5s adjustment
      await tester.tap(find.text('+5s'));
      await tester.pumpAndSettle();
      expect(find.text('00:35'), findsOneWidget);
      expect(find.text('Target: 35s hold'), findsOneWidget);

      // Tap Complete button
      await tester.tap(find.text('COMPLETE (35s)'));
      await tester.pumpAndSettle();

      expect(completedIndex, equals(0));
      expect(completedElapsed, equals(35));
    });

    test('Hip Internal Rotation protocols are integrated across exercises, curriculum, goals, and timing helpers', () {
      final List<MobilityExerciseModel> exercises =
          MobilityExerciseModel.defaultExercises();

      final MobilityExerciseModel hipIR9090 =
          exercises.firstWhere((e) => e.id == 'hip_90_90_internal_rotation');
      expect(hipIR9090.name, contains('90/90 Rear-Leg Hip IR PAILs/RAILs'));
      expect(hipIR9090.focusArea, equals(MobilityFocusArea.hipCapsule));
      expect(hipIR9090.videoUrl, contains(Uri.encodeComponent('90 90 Hip Internal Rotation PAILs RAILs')));

      final MobilityExerciseModel bandedHipIR =
          exercises.firstWhere((e) => e.id == 'banded_hip_internal_rotation');
      expect(bandedHipIR.name, contains('Banded Hip Internal Rotation'));
      expect(bandedHipIR.focusArea, equals(MobilityFocusArea.hipCapsule));
      expect(bandedHipIR.videoUrl, contains(Uri.encodeComponent('Banded Hip Internal Rotation')));

      final MobilityExerciseModel seatedHipIR =
          exercises.firstWhere((e) => e.id == 'seated_hip_internal_rotation');
      expect(seatedHipIR.name, contains('Seated Hip IR with Block Squeeze'));
      expect(seatedHipIR.focusArea, equals(MobilityFocusArea.hipCapsule));
      expect(seatedHipIR.videoUrl, contains(Uri.encodeComponent('Seated Hip Internal Rotation Block Squeeze')));

      // Check Milestones in GoalTrack
      final GoalTrack? mobilityGoal =
          goalProvider.getGoal('goal_mobility_hypertrophy');
      expect(mobilityGoal, isNotNull);
      final List<String> milestoneIds =
          mobilityGoal!.milestones.map((m) => m.id).toList();
      expect(milestoneIds, contains('hip_internal_rotation_35'));

      // Check Program Days 1, 3, 4
      final List<DayTemplate> mobilityDays = ProgramCycle.getMobilityProgram();

      // Day 1
      final DayTemplate day1 = mobilityDays[0];
      final List<String> day1Lifts = day1.phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day1Lifts, contains('banded_hip_internal_rotation'));

      // Day 3
      final DayTemplate day3 = mobilityDays[2];
      final List<String> day3Lifts = day3.phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day3Lifts, contains('hip_90_90_internal_rotation'));

      // Day 4
      final DayTemplate day4 = mobilityDays[3];
      final List<String> day4Lifts = day4.phases
          .expand((p) => p.exercises)
          .map((e) => e.liftId)
          .toList();
      expect(day4Lifts, contains('banded_hip_internal_rotation'));

      // WorkoutWeightHelper timing detection
      expect(
        WorkoutWeightHelper.isTimedExercise(
          '90/90 Rear-Leg Hip IR PAILs/RAILs',
          '3 Sets of 60s Hold',
        ),
        isTrue,
      );
      expect(
        WorkoutWeightHelper.isTimedExercise(
          'Banded Hip Internal Rotation',
          '2 Sets of 12 Reps',
        ),
        isFalse,
      );
      expect(
        WorkoutWeightHelper.isTimedExercise(
          'Banded Hip Internal Rotation',
          '3 Sets of 12 Reps',
        ),
        isFalse,
      );
    });
  });
}
