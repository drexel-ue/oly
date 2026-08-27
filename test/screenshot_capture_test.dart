import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/views/dashboard_screen.dart';
import 'package:oly/views/lifts_screen.dart';
import 'package:oly/views/max_test_screen.dart';
import 'package:oly/views/plate_calculator_screen.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';
import 'package:oly/widgets/mobility_exercise_swap_modal.dart';
import 'package:oly/widgets/standard_ratios_sheet.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'utils/mock_data_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late SettingsProvider settingsProvider;
  late LiftProvider liftProvider;
  late ProgramProvider programProvider;
  late RecoveryProvider recoveryProvider;
  late BodyCompProvider bodyCompProvider;
  late NutritionProvider nutritionProvider;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    settingsProvider = SettingsProvider(storage);
    liftProvider = LiftProvider(storage);
    programProvider = ProgramProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    bodyCompProvider = BodyCompProvider(storage);
    nutritionProvider = NutritionProvider(storage);
  });

  Widget buildTestScreen(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: liftProvider),
        ChangeNotifierProvider.value(value: programProvider),
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: bodyCompProvider),
        ChangeNotifierProvider.value(value: nutritionProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: child,
        ),
      ),
    );
  }

  group('Mock Data & Screen Rendering Verification Suite', () {
    testWidgets('01 Renders Dashboard Screen with mock data', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('OLY'), findsWidgets);
      expect(find.text('Week 2 of 4: Base Loading'), findsOneWidget);
    });

    testWidgets('02 Renders Lifts Matrix Screen with expanded percentage matrix', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const LiftsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      if (find.text('Snatch').evaluate().isNotEmpty) {
        await tester.tap(find.text('Snatch').first);
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Snatch'), findsWidgets);
    });

    testWidgets('03 Renders Lift Ratios Screen with balance statuses', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const LiftsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      if (find.text('Ratio Balance').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ratio Balance'));
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Ratio Balance'), findsOneWidget);
    });

    testWidgets('04 Renders Standard Ratios Sheet', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const StandardRatiosSheet()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Olympic Ratio Standards'), findsOneWidget);
    });

    testWidgets('05 Renders Plate Calculator Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const PlateCalculatorScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Barbell Plate Loader'), findsOneWidget);
    });

    testWidgets('06 Renders Max Test Calculator Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const MaxTestScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1RM Retest Assistant'), findsOneWidget);
    });

    testWidgets('07 Renders Analytics Screen with volume progression', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const AnalyticsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Analytics & Session Logs'), findsOneWidget);
    });

    testWidgets('07b Renders Accessory Progressions Screen with movement delta chips', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const AnalyticsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Accessories'));
      await tester.pumpAndSettle();

      expect(find.text('ACCESSORY WEIGHT PROGRESSIONS'), findsOneWidget);
      expect(find.text('Bicep Curls / Hammer Curls'), findsOneWidget);
    });

    testWidgets('08 Renders Warmup Session Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final day1 = ProgramCycle.getBuiltInProgram().first;
      await tester.pumpWidget(buildTestScreen(WarmupSessionScreen(dayTemplate: day1)));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Guided Olympic Warm-Up'), findsOneWidget);
    });

    testWidgets('09 Renders Workout Session Screen with periodized sets', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final day1 = ProgramCycle.getBuiltInProgram().first;
      await tester.pumpWidget(
        buildTestScreen(
          WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Day 1: Snatch & Clean Strength'), findsOneWidget);
    });

    testWidgets('10 Renders Workout Swap Modal with Suggested Swaps', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      await tester.pumpWidget(
        buildTestScreen(
          ExerciseSwapModal(
            exercise: exercise,
            currentWeek: 2,
            onSwapSelected: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Swap Movement Variation'), findsOneWidget);
      expect(find.text('SUGGESTED SWAPS'), findsOneWidget);
    });

    testWidgets('11 Renders Workout Weight Dialog with 1RM estimate', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      await tester.pumpWidget(
        buildTestScreen(
          WorkoutWeightDialog(
            exercise: exercise,
            displayName: 'Power Snatch + Overhead Squat',
            initialWeightKg: 70.0,
            currentWeek: 2,
            onWeightUpdated: ({
              required double newWeightKg,
              required bool update1RM,
              double? new1RMKg,
            }) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Update Working Weight & 1RM'), findsOneWidget);
      expect(find.text('RECALCULATED 1RM ESTIMATE'), findsOneWidget);
    });

    testWidgets('12 Renders Active Recovery Session Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routine = RecoveryEngineService.generateRoutine(
        ratioAnalyses: liftProvider.getRatioAnalysis(),
        lastSession: programProvider.sessions.isNotEmpty
            ? programProvider.sessions.first
            : null,
      );

      await tester.pumpWidget(
        buildTestScreen(RecoverySessionScreen(routine: routine)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Active Recovery Routine'), findsOneWidget);
    });

    testWidgets('13 Renders Mobility Exercise Swap Modal with Suggested Alternatives', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mobilityEx = MobilityExerciseModel(
        id: 'db_bicep_curls',
        name: 'Dumbbell Bicep Curls',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Builds elbow flexor strength and bicep tendon resilience for heavy clean catches.',
        cues: ['Keep elbows tucked.', 'Squeeze biceps.'],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: 'https://youtube.com',
      );

      await tester.pumpWidget(
        buildTestScreen(
          MobilityExerciseSwapModal(
            exercise: mobilityEx,
            onSwapSelected: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Swap Movement'), findsOneWidget);
      expect(find.text('CURRENT MOVEMENT'), findsOneWidget);
      expect(find.text('Dumbbell Bicep Curls'), findsOneWidget);
      expect(find.text('SUGGESTED ALTERNATIVES'), findsOneWidget);
    });
  });
}
