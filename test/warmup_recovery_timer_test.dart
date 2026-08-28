import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/video_player_card.dart';
import 'package:provider/provider.dart';

import 'utils/mock_data_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late RecoveryProvider recoveryProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    recoveryProvider = RecoveryProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('Warmup & Recovery Flow Timer & Weight Tests', () {
    testWidgets(
      'Cardio Opener renders Cardio Interval Timer with live session controls',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final MobilityExerciseModel cardioEx = MobilityExerciseModel(
          id: 'zone2_cardio_row',
          name: 'Ergometer Row / Bike (Cardio Opener)',
          focusArea: MobilityFocusArea.cardio,
          category: MobilityCategory.cardioConditioning,
          description: 'Increases core body temperature.',
          cues: <String>['Row or bike at an easy pace.'],
          durationSeconds: 180,
          videoUrl: 'https://youtube.com',
        );

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerCard(exercise: cardioEx, onCompleted: () {}),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Cardio Interval Timer is rendered
        expect(find.text('Cardio Interval Timer'), findsOneWidget);
        expect(find.text('03:00'), findsOneWidget);
        expect(find.text('START TIMER'), findsOneWidget);

        // Verify micro-adjustment steppers
        expect(find.text('-10s'), findsOneWidget);
        expect(find.text('+10s'), findsOneWidget);

        // Verify duration presets (e.g. 1m, 2m, 3m, 5m)
        expect(find.text('1m'), findsOneWidget);
        expect(find.text('2m'), findsOneWidget);
        expect(find.text('3m'), findsOneWidget);
        expect(find.text('5m'), findsOneWidget);

        // Tap 5m preset
        await tester.tap(find.text('5m'));
        await tester.pump();
        expect(find.text('05:00'), findsOneWidget);

        // Tap Start Timer
        await tester.tap(find.text('START TIMER'));
        await tester.pump();
        expect(find.text('PAUSE TIMER'), findsOneWidget);
      },
    );

    testWidgets('Mobility & Foam Roll drills render unified drill timers', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel foamEx = MobilityExerciseModel(
        id: 'thoracic_foam_roll',
        name: 'Thoracic Extension Foam Roll',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.foamRolling,
        description: 'Upper back foam rolling.',
        cues: <String>['Support your head with hands.'],
        durationSeconds: 90,
        videoUrl: 'https://youtube.com',
      );

      await tester.pumpWidget(
        buildTestWidget(VideoPlayerCard(exercise: foamEx, onCompleted: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Foam Roll Timer'), findsOneWidget);
      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets(
      'Accessory exercises render workout-matched sets, weight steppers, and rest toggle',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final MobilityExerciseModel accessoryEx = MobilityExerciseModel(
          id: 'custom_hammer_curls',
          name: 'Hammer Curls Test',
          focusArea: MobilityFocusArea.arms,
          category: MobilityCategory.hypertrophyCore,
          description: 'Upper body pulling hypertrophy.',
          cues: <String>['Keep elbows tucked.', 'Squeeze biceps.'],
          defaultSets: 3,
          defaultReps: 12,
          videoUrl: 'https://youtube.com',
        );

        bool completed = false;

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerCard(
              exercise: accessoryEx,
              onCompleted: () {
                completed = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Target sets & weight header
        expect(find.text('TARGET SETS & WEIGHT'), findsOneWidget);
        expect(find.text('3 Sets × 12 Reps'), findsOneWidget);

        // Verify weight adjustment steppers
        expect(find.text('Weight:'), findsOneWidget);
        expect(find.text('+2.5'), findsOneWidget);
        expect(find.text('+5.0'), findsOneWidget);

        // Verify interactive set pills matching workout sessions
        expect(find.text('Set 1: 10.0KG'), findsOneWidget);
        expect(find.text('Set 2: 10.0KG'), findsOneWidget);
        expect(find.text('Set 3: 10.0KG'), findsOneWidget);

        // Adjust weight with +2.5 stepper
        await tester.tap(find.text('+2.5'));
        await tester.pump();
        expect(find.text('Set 1: 12.5KG'), findsOneWidget);

        // Toggle rest timer button
        expect(find.text('Rest'), findsOneWidget);
        await tester.tap(find.text('Rest'));
        await tester.pumpAndSettle();
        expect(find.text('Accessory Rest Timer'), findsOneWidget);

        // Tap all sets to mark completed
        await tester.tap(find.text('Set 1: 12.5KG'));
        await tester.pump();
        await tester.tap(find.text('Set 2: 12.5KG'));
        await tester.pump();
        await tester.tap(find.text('Set 3: 12.5KG'));
        await tester.pump();

        expect(completed, isTrue);
      },
    );
  });
}
