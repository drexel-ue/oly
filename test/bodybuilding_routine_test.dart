import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/bodybuilding_model.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/bodybuilding/bodybuilding_routine_screen.dart';
import 'package:oly/views/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bodybuilding (19 Exercises - Trainer Winny) Track Tests', () {
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
      activeSessionProvider = ActiveSessionProvider();
    });

    test('19 Exercises model matches Trainer Winny layout across 9 bodyparts', () {
      final List<BodybuildingExercise> exercises =
          BodybuildingExercise.get19Exercises();

      // 19 core movements + 1 bonus glute + 8 mobility/armor bonus = 28 total
      expect(exercises.length, equals(28));

      final List<BodybuildingExercise> core19 =
          exercises.where((e) => !e.isBonus).toList();
      expect(core19.length, equals(19));

      // Verify 9 Bodyparts coverage
      // 1. Chest (3 exercises)
      final List<BodybuildingExercise> chest =
          exercises.where((e) => e.bodypart == BodypartCategory.chest).toList();
      expect(chest.length, equals(3));
      expect(chest.any((e) => e.name.contains('Bench Press')), isTrue);
      expect(chest.any((e) => e.name.contains('Incline Dumbbell')), isTrue);
      expect(chest.any((e) => e.name.contains('Fly')), isTrue);

      // 2. Back (3 exercises: lat pulldown, row, pullover)
      final List<BodybuildingExercise> back =
          exercises.where((e) => e.bodypart == BodypartCategory.back).toList();
      expect(back.length, equals(3));
      expect(back.any((e) => e.name.contains('Lat Pulldown')), isTrue);
      expect(back.any((e) => e.name.contains('Row')), isTrue);
      expect(back.any((e) => e.name.contains('Pullover')), isTrue);

      // 3. Shoulders (3 exercises: compound OHP, lateral raises, rear delts)
      final List<BodybuildingExercise> shoulders = exercises
          .where((e) => e.bodypart == BodypartCategory.shoulders)
          .toList();
      expect(shoulders.length, equals(3));
      expect(shoulders.any((e) => e.role == 'Compound Press'), isTrue);
      expect(shoulders.any((e) => e.role == 'Lateral Delts Isolation'), isTrue);
      expect(shoulders.any((e) => e.role == 'Rear Delts Isolation'), isTrue);

      // 4. Biceps (2 exercises: main curl, hammer brachialis)
      final List<BodybuildingExercise> biceps =
          exercises.where((e) => e.bodypart == BodypartCategory.biceps).toList();
      expect(biceps.length, equals(2));
      expect(biceps.any((e) => e.role == 'Main Bicep Curl'), isTrue);
      expect(biceps.any((e) => e.name.contains('Hammer Curl')), isTrue);

      // 5. Triceps (2 exercises: lateral pushdown, long head overhead)
      final List<BodybuildingExercise> triceps =
          exercises.where((e) => e.bodypart == BodypartCategory.triceps).toList();
      expect(triceps.length, equals(2));
      expect(triceps.any((e) => e.name.contains('Pushdown')), isTrue);
      expect(triceps.any((e) => e.name.contains('Overhead')), isTrue);

      // 6. Quads (2 exercises: squat compound, leg extension isolation)
      final List<BodybuildingExercise> quads =
          exercises.where((e) => e.bodypart == BodypartCategory.quads).toList();
      expect(quads.length, equals(2));
      expect(quads.any((e) => e.name.contains('Squat')), isTrue);
      expect(quads.any((e) => e.name.contains('Extension')), isTrue);

      // 7. Hamstrings (2 exercises: RDL compound, leg curl isolation)
      final List<BodybuildingExercise> hams = exercises
          .where((e) => e.bodypart == BodypartCategory.hamstrings)
          .toList();
      expect(hams.length, equals(2));
      expect(hams.any((e) => e.name.contains('Romanian Deadlift')), isTrue);
      expect(hams.any((e) => e.name.contains('Curl')), isTrue);

      // 8. Calves (1 exercise: calf raises)
      final List<BodybuildingExercise> calves =
          exercises.where((e) => e.bodypart == BodypartCategory.calves).toList();
      expect(calves.length, equals(1));
      expect(calves.any((e) => e.name.contains('Calf Raise')), isTrue);

      // 9. Abs (1 exercise: kneeling cable crunch)
      final List<BodybuildingExercise> abs =
          exercises.where((e) => e.bodypart == BodypartCategory.abs).toList();
      expect(abs.length, equals(1));
      expect(abs.any((e) => e.name.contains('Cable Crunch')), isTrue);

      // Bonus: Glutes
      final List<BodybuildingExercise> glutes =
          exercises.where((e) => e.bodypart == BodypartCategory.glutes).toList();
      expect(glutes.length, equals(1));
      expect(glutes.first.isBonus, isTrue);

      // Mobility & Armor (8 exercises)
      final List<BodybuildingExercise> armor = exercises
          .where((e) => e.bodypart == BodypartCategory.mobilityArmor)
          .toList();
      expect(armor.length, equals(8));
      expect(armor.any((e) => e.name.contains('Wrist Curls')), isTrue);
      expect(armor.any((e) => e.name.contains('Hip Rotations')), isTrue);
      expect(armor.any((e) => e.name.contains('Elephant Walks')), isTrue);
      expect(armor.any((e) => e.name.contains('Jefferson Curls')), isTrue);
      expect(armor.any((e) => e.name.contains('Couch Stretch')), isTrue);
      expect(armor.any((e) => e.name.contains('Landmine Rotations')), isTrue);
      expect(armor.any((e) => e.name.contains('Pallof Press')), isTrue);
      expect(armor.any((e) => e.name.contains('Ab Wheel Rollouts')), isTrue);
    });

    test('ProgramCycle getBodybuildingProgram delivers 7 days of weekly hypertrophy', () {
      final List<DayTemplate> days = ProgramCycle.getBodybuildingProgram();
      expect(days.length, equals(7));

      // Day 1: Upper A
      expect(days[0].dayNumber, equals(1));
      expect(days[0].title, contains('Upper A'));

      // Day 2: Lower A
      expect(days[1].dayNumber, equals(2));
      expect(days[1].title, contains('Lower A'));

      // Day 3: Mid-Week Restoration
      expect(days[2].dayNumber, equals(3));
      expect(days[2].title, contains('Restoration'));
      expect(days[2].isActiveRecovery, isTrue);

      // Day 4: Upper B
      expect(days[3].dayNumber, equals(4));
      expect(days[3].title, contains('Upper B'));

      // Day 5: Lower B
      expect(days[4].dayNumber, equals(5));
      expect(days[4].title, contains('Lower B'));

      // Day 6: Aerobic Endurance
      expect(days[5].dayNumber, equals(6));
      expect(days[5].title, contains('Aerobic Endurance'));
      expect(days[5].isActiveRecovery, isTrue);

      // Day 7: Active Restoration
      expect(days[6].dayNumber, equals(7));
      expect(days[6].isActiveRecovery, isTrue);
    });

    test('ProgramProvider switches to bodybuilding track and returns bodybuilding days', () {
      expect(programProvider.isBodybuildingTrack, isFalse);

      programProvider.setTrainingTrack(TrainingTrack.bodybuilding);
      expect(programProvider.isBodybuildingTrack, isTrue);
      expect(programProvider.activeTrack, equals(TrainingTrack.bodybuilding));
      expect(programProvider.days.length, equals(7));
      expect(programProvider.days.first.title, contains('Upper A'));

      // Test day selection
      programProvider.selectDay(2);
      expect(programProvider.currentDay, equals(2));
      expect(programProvider.currentDayTemplate.title, contains('Lower A'));
    });

    test('GoalTrack has goal_bodybuilding with 23 milestones', () {
      final GoalTrack? bbGoal = goalProvider.getGoal('goal_bodybuilding');
      expect(bbGoal, isNotNull);
      expect(bbGoal!.type, equals(GoalType.bodybuilding));
      expect(bbGoal.milestones.length, equals(23));

      final List<String> milestoneIds =
          bbGoal.milestones.map((m) => m.id).toList();
      expect(milestoneIds, contains('bb_bench_press_100'));
      expect(milestoneIds, contains('bb_incline_db_35'));
      expect(milestoneIds, contains('bb_barbell_squat_140'));
      expect(milestoneIds, contains('bb_romanian_deadlift_120'));
      expect(milestoneIds, contains('bb_lat_pulldown_85'));
      expect(milestoneIds, contains('bb_overhead_press_60'));
      expect(milestoneIds, contains('bb_barbell_curl_45'));
      expect(milestoneIds, contains('bb_hammer_curl_20'));
      expect(milestoneIds, contains('bb_tricep_pushdown_40'));
      expect(milestoneIds, contains('bb_overhead_tricep_35'));
      expect(milestoneIds, contains('bb_lateral_raise_16'));
      expect(milestoneIds, contains('bb_leg_extension_70'));
      expect(milestoneIds, contains('bb_hamstring_curl_60'));
      expect(milestoneIds, contains('bb_standing_calf_100'));
      expect(milestoneIds, contains('bb_cable_crunch_50'));
      expect(milestoneIds, contains('bb_barbell_wrist_curls_25'));
      expect(milestoneIds, contains('bb_banded_hip_rotations_20'));
      expect(milestoneIds, contains('bb_elephant_walks_45'));
      expect(milestoneIds, contains('bb_jefferson_curls_40'));
      expect(milestoneIds, contains('bb_couch_stretch_90s'));
      expect(milestoneIds, contains('bb_landmine_rotations_25'));
      expect(milestoneIds, contains('bb_pallof_press_25'));
      expect(milestoneIds, contains('bb_ab_wheel_rollout_15'));
    });

    test('GoalProvider updateBodybuildingMilestone updates progress', () async {
      final GoalTrack? bbGoalBefore = goalProvider.getGoal('goal_bodybuilding');
      expect(bbGoalBefore, isNotNull);

      await goalProvider.updateBodybuildingMilestone('bb_bench_press_100', 90);
      final GoalTrack? bbGoalAfter = goalProvider.getGoal('goal_bodybuilding');
      final GoalMilestone bench =
          bbGoalAfter!.milestones.firstWhere((m) => m.id == 'bb_bench_press_100');
      expect(bench.currentValue, equals(90));
      expect(bench.progressPercent, equals(90));
    });

    testWidgets('Renders BodybuildingRoutineScreen with 3 tabs and exercise cards',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: <ChangeNotifierProvider<dynamic>>[
            ChangeNotifierProvider<GoalProvider>.value(value: goalProvider),
            ChangeNotifierProvider<ProgramProvider>.value(value: programProvider),
          ],
          child: const MaterialApp(
            home: BodybuildingRoutineScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and tabs
      expect(find.text('Bodybuilding (19 Exercises)'), findsOneWidget);
      expect(find.text('19 Exercises Guide'), findsOneWidget);
      expect(find.text('Hypertrophy Standards'), findsOneWidget);
      expect(find.text('Weekly Curriculum'), findsOneWidget);

      // Hero Inspo Card
      expect(find.text('9 Bodyparts, 19 Exercises, Maximum Gains'), findsOneWidget);
      expect(find.text('Trainer Winny'), findsOneWidget);

      // First exercise card visible
      expect(find.text('Barbell Flat Bench Press'), findsOneWidget);

      // Switch to Standards tab
      await tester.tap(find.text('Hypertrophy Standards'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PHYSIQUE PROGRESSION TIER'), findsOneWidget);
      expect(find.textContaining('HYPERTROPHY BENCHMARKS'), findsOneWidget);
      expect(find.text('Flat Bench Press 100 kg'), findsOneWidget);

      // Switch to Curriculum tab
      await tester.tap(find.text('Weekly Curriculum'));
      await tester.pumpAndSettle();

      expect(find.text('Start Live Workout Session'), findsOneWidget);
      // Tap Monday pill to select Day 1
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();
      expect(find.text('DAY 1 OF 7'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders 3-way track switcher and switches to bodybuilding',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            ChangeNotifierProvider<ActiveSessionProvider>.value(value: activeSessionProvider),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure cycle card is visible
      await tester.ensureVisible(find.text('💪 Bodybuilding'));
      await tester.pumpAndSettle();

      // Verify the 3-way track switcher segments
      expect(find.text('🏋️ Olympic'), findsOneWidget);
      expect(find.text('🧘 Mobility'), findsOneWidget);
      expect(find.text('💪 Bodybuilding'), findsOneWidget);

      // Tap Bodybuilding track
      await tester.tap(find.text('💪 Bodybuilding'));
      await tester.pumpAndSettle();

      expect(programProvider.isBodybuildingTrack, isTrue);
      expect(find.text('ACTIVE FOCUS: BODYBUILDING (19 EXERCISES)'), findsOneWidget);
      expect(find.text('Trainer Winny: 9 Bodyparts, 19 Exercises'), findsOneWidget);
      expect(find.text('View 19 Exercises Guide & Inspo Video'), findsOneWidget);
    });
  });
}
