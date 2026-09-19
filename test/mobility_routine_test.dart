import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/mobility/mobility_routine_screen.dart';
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
  });
}

