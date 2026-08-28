import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
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

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    liftProvider = LiftProvider(storage);
    programProvider = ProgramProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: liftProvider),
        ChangeNotifierProvider.value(value: programProvider),
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
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

      // Should include overhead tricep extensions (arms focus) and lateral delt flyes (hypertrophyCore) in suggested
      expect(
        seg.suggested.any(
          (MobilityExerciseModel e) => e.name.contains('Tricep'),
        ),
        isTrue,
      );
      // Should not contain itself
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

        // Verify Header & Current Movement Banner
        expect(find.text('Swap Movement'), findsOneWidget);
        expect(find.text('CURRENT MOVEMENT'), findsOneWidget);
        expect(find.text('Bicep Curls / Hammer Curls'), findsOneWidget);

        // Verify Suggested Alternatives section
        expect(find.text('SUGGESTED ALTERNATIVES'), findsOneWidget);
        expect(find.text('Overhead DB Tricep Extension'), findsOneWidget);

        // Tap on Overhead DB Tricep Extension
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

      // Verify Swap chip is visible
      expect(find.text('Swap'), findsOneWidget);

      // Tap Swap chip
      await tester.tap(find.text('Swap'));
      await tester.pumpAndSettle();

      // Modal should open
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

        // Open Swap modal on current cardio exercise
        expect(find.text('Swap'), findsOneWidget);
        await tester.tap(find.text('Swap'));
        await tester.pumpAndSettle();

        // Select Quads & Lats Foam Roll
        expect(find.text('Swap Movement'), findsOneWidget);
        await tester.tap(find.text('Quads & Lats Foam Roll'));
        await tester.pumpAndSettle();

        // Verify exercise is now updated to Quads & Lats Foam Roll and shows SWAPPED badge
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

        // Tap Swap on first exercise
        expect(find.text('Swap'), findsOneWidget);
        await tester.tap(find.text('Swap'));
        await tester.pumpAndSettle();

        // Select 90/90 Hip Mobility Switches
        expect(find.text('Swap Movement'), findsOneWidget);
        await tester.tap(find.text('90/90 Hip Mobility Switches'));
        await tester.pumpAndSettle();

        // Verify swapped status
        expect(find.text('90/90 Hip Mobility Switches'), findsOneWidget);
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
  });
}
