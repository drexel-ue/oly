import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/exercise_database_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/widgets/mobility_exercise_swap_modal.dart';
import 'package:oly/widgets/video_player_card.dart';
import 'package:provider/provider.dart';

import 'utils/mock_data_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late LiftProvider liftProvider;
  late ProgramProvider programProvider;
  late RecoveryProvider recoveryProvider;
  late SettingsProvider settingsProvider;
  late BodyCompProvider bodyCompProvider;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    liftProvider = LiftProvider(storage);
    programProvider = ProgramProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    settingsProvider = SettingsProvider(storage);
    bodyCompProvider = BodyCompProvider(storage);
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: liftProvider),
        ChangeNotifierProvider.value(value: programProvider),
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: bodyCompProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Mobility & Warmup Exercise Swap Tests', () {
    test('MobilitySwapHelper segments exercises into suggested focus/category matches', () {
      final MobilityExerciseModel current = MobilityExerciseModel(
        id: 'bicep_curls',
        name: 'Bicep Curls / Hammer Curls',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Biceps hypertrophy',
        cues: <String>['Tuck elbows'],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: 'https://youtube.com',
      );

      final List<MobilityExerciseModel> allExercises =
          MobilityExerciseModel.defaultExercises();
      final ({
        List<MobilityExerciseModel> others,
        List<MobilityExerciseModel> suggested,
      })
      seg = MobilitySwapHelper.segmentExercises(
        current: current,
        allExercises: allExercises,
      );

      expect(
        seg.suggested.any(
          (MobilityExerciseModel e) => e.name.contains('Tricep'),
        ),
        isTrue,
      );
      expect(
        seg.suggested.any((MobilityExerciseModel e) => e.id == 'bicep_curls'),
        isFalse,
      );
      expect(
        seg.others.any((MobilityExerciseModel e) => e.id == 'bicep_curls'),
        isFalse,
      );
    });

    testWidgets(
      'MobilityExerciseSwapModal displays suggested alternatives and performs swap callback',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final MobilityExerciseModel current = MobilityExerciseModel(
          id: 'bicep_curls',
          name: 'Bicep Curls / Hammer Curls',
          focusArea: MobilityFocusArea.arms,
          category: MobilityCategory.hypertrophyCore,
          description: 'Biceps hypertrophy',
          cues: <String>['Tuck elbows'],
          defaultSets: 3,
          defaultReps: 12,
          videoUrl: 'https://youtube.com',
        );

        MobilityExerciseModel? selectedReplacement;

        await tester.pumpWidget(
          buildTestApp(
            MobilityExerciseSwapModal(
              exercise: current,
              onSwapSelected: (MobilityExerciseModel replacement) {
                selectedReplacement = replacement;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Swap Movement'), findsOneWidget);
        expect(find.text('CURRENT MOVEMENT'), findsOneWidget);
        expect(find.text('Bicep Curls / Hammer Curls'), findsOneWidget);

        expect(find.text('SUGGESTED ALTERNATIVES'), findsOneWidget);
        expect(find.text('Overhead DB Tricep Extension'), findsOneWidget);

        await tester.tap(find.text('Overhead DB Tricep Extension'));
        await tester.pumpAndSettle();

        expect(selectedReplacement, isNotNull);
        expect(selectedReplacement!.id, 'overhead_tricep_ext');
      },
    );

    testWidgets('VideoPlayerCard renders Swap button and triggers swap modal', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel current = MobilityExerciseModel(
        id: 'thoracic_foam_roll',
        name: 'Thoracic Extension Foam Roll',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.foamRolling,
        description: 'Mid-back extension',
        cues: <String>['Support head'],
        durationSeconds: 90,
        videoUrl: 'https://youtube.com',
      );

      await tester.pumpWidget(
        buildTestApp(
          SingleChildScrollView(
            child: VideoPlayerCard(
              exercise: current,
              onSwapExercise: (MobilityExerciseModel replacement) {},
              onCompleted: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swap'), findsOneWidget);

      await tester.tap(find.text('Swap'));
      await tester.pumpAndSettle();

      expect(find.text('Swap Movement'), findsOneWidget);
      expect(find.text('Thoracic Extension Foam Roll'), findsAtLeast(1));
    });

    testWidgets(
      'WarmupSessionScreen allows swapping exercises and displays SWAPPED status',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final DayTemplate day1 = ProgramCycle.getBuiltInProgram().first;
        await tester.pumpWidget(
          buildTestApp(WarmupSessionScreen(dayTemplate: day1)),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Open Swap modal on first warmup exercise
        expect(find.text('Swap'), findsOneWidget);
        await tester.tap(find.text('Swap'));
        await tester.pumpAndSettle();

        expect(find.text('Swap Movement'), findsOneWidget);
        expect(find.text('Quads & Lats Foam Roll'), findsOneWidget);

        await tester.tap(find.text('Quads & Lats Foam Roll'));
        await tester.pumpAndSettle();

        expect(find.text('Quads & Lats Foam Roll'), findsOneWidget);
        expect(find.text('SWAPPED'), findsOneWidget);
      },
    );

    testWidgets(
      'RecoverySessionScreen allows swapping exercises and resets back',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final GeneratedRecoveryRoutine routine =
            RecoveryEngineService.generateRoutine(
              ratioAnalyses: <LiftRatioAnalysis>[],
              lastSession: null,
            );

        await tester.pumpWidget(
          buildTestApp(
            RecoverySessionScreen(routine: routine, isPreviewMode: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Tap Swap on first exercise (Kettlebell Mile)
        expect(find.text('Swap'), findsOneWidget);
        await tester.tap(find.text('Swap'));
        await tester.pumpAndSettle();

        // Select Ergometer Row / Bike
        expect(find.text('Swap Movement'), findsOneWidget);
        expect(find.text('Ergometer Row / Bike (Cardio Opener)'), findsOneWidget);
        await tester.tap(find.text('Ergometer Row / Bike (Cardio Opener)'));
        await tester.pumpAndSettle();

        // Verify swapped status
        expect(find.text('Ergometer Row / Bike (Cardio Opener)'), findsOneWidget);
        expect(find.text('SWAPPED'), findsOneWidget);

        // Open swap modal again and reset
        await tester.tap(find.text('SWAPPED'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'Reset'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Reset'));
        await tester.pumpAndSettle();

        // Should be restored to original
        expect(find.text('SWAPPED'), findsNothing);
        expect(find.text('Swap'), findsOneWidget);
      },
    );

    testWidgets(
      'RecoverySessionScreen allows skipping exercises and advances to next exercise',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final GeneratedRecoveryRoutine routine =
            RecoveryEngineService.generateRoutine(
              ratioAnalyses: <LiftRatioAnalysis>[],
              lastSession: null,
            );

        await tester.pumpWidget(
          buildTestApp(
            RecoverySessionScreen(routine: routine, isPreviewMode: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Initial exercise is Kettlebell Mile
        expect(find.text('Kettlebell Mile (Loaded Carry)'), findsAtLeast(1));

        // Tap the bottom SKIP button
        expect(find.text('SKIP'), findsOneWidget);
        await tester.tap(find.text('SKIP'));
        await tester.pumpAndSettle();

        // Should advance to next exercise (Cable Crunches)
        expect(find.text('Cable Crunches'), findsAtLeast(1));
      },
    );

    test('MobilityExerciseModel.fromDatabaseModel converts database movement properly', () {
      final ExerciseDatabaseModel dbModel = ExerciseDatabaseModel(
        id: 'oly_bayesian_curl',
        name: 'Bayesian Curl',
        category: 'strength',
        bodyPart: 'upper arms',
        targetMuscle: 'biceps',
        equipment: 'cable',
        source: 'oly_curated',
        instructions: '1. Set low pulley.\n2. Step forward into stretch.',
        tips: 'Keep elbows behind torso.',
      );

      final MobilityExerciseModel model =
          MobilityExerciseModel.fromDatabaseModel(dbModel);

      expect(model.id, 'oly_bayesian_curl');
      expect(model.name, 'Bayesian Curl');
      expect(model.focusArea, MobilityFocusArea.arms);
      expect(model.category, MobilityCategory.hypertrophyCore);
      expect(model.cues.length, 3);
      expect(model.cues.first, '1. Set low pulley.');
      expect(model.cues.last, contains('Coach Tip: Keep elbows behind torso.'));
    });
  });
}
