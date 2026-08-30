import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/widgets/video_player_card.dart';
import 'package:provider/provider.dart';

import 'utils/mock_data_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late RecoveryProvider recoveryProvider;
  late ProgramProvider programProvider;
  late LiftProvider liftProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    recoveryProvider = RecoveryProvider(storage);
    programProvider = ProgramProvider(storage);
    liftProvider = LiftProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: programProvider),
        ChangeNotifierProvider.value(value: liftProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Accessory Weight Progression Storage & Provider Tests', () {
    test('StorageService persists and retrieves accessory logs', () async {
      final List<AccessoryLog> history = storage.getAccessoryHistory(
        'bicep_curls',
      );
      expect(history.length, 3);
      expect(storage.getAccessoryPersonalBest('bicep_curls'), 15.0);

      await storage.logAccessorySet(
        exerciseId: 'bicep_curls',
        exerciseName: 'Bicep Curls / Hammer Curls',
        weightKg: 17.5,
        sets: 3,
        reps: 12,
        source: 'routine',
      );

      expect(storage.getAccessoryPersonalBest('bicep_curls'), 17.5);
      final AccessoryLog? latest = storage.getLatestAccessoryLog('bicep_curls');
      expect(latest?.weightKg, 17.5);
    });

    test(
      'RecoveryProvider calculates grouped progressions and personal bests',
      () async {
        final Map<String, List<AccessoryLog>> grouped =
            recoveryProvider.groupedAccessoryProgressions;
        expect(grouped.containsKey('Bicep Curls / Hammer Curls'), isTrue);
        expect(grouped['Bicep Curls / Hammer Curls']!.length, 3);

        final double pb = recoveryProvider.getAccessoryPersonalBest(
          'bicep_curls',
        );
        expect(pb, 15.0);
      },
    );
  });

  group('Accessory Progression Widget Tests', () {
    testWidgets(
      'VideoPlayerCard initializes with previous weight and displays PB & History',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final MobilityExerciseModel accessoryEx = MobilityExerciseModel(
          id: 'bicep_curls',
          name: 'Bicep Curls / Hammer Curls',
          focusArea: MobilityFocusArea.arms,
          category: MobilityCategory.hypertrophyCore,
          description: 'Upper body pulling hypertrophy.',
          cues: <String>['Keep elbows tucked.'],
          defaultSets: 3,
          defaultReps: 12,
          videoUrl: 'https://youtube.com',
        );

        await tester.pumpWidget(
          buildTestWidget(
            SingleChildScrollView(
              child: VideoPlayerCard(exercise: accessoryEx, onCompleted: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initialized with latest logged weight (15.0 KG)
        expect(find.text('15.0 KG'), findsAtLeast(1));

        // Verify Personal Best badge
        expect(find.text('PB: 15.0 KG'), findsOneWidget);

        // Verify History button
        expect(find.text('History'), findsOneWidget);

        // Tap History button to open breakdown sheet
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();

        // Verify modal sheet contents
        expect(find.text('Weight Progression History'), findsOneWidget);
        expect(find.text('PR'), findsOneWidget);
      },
    );

    testWidgets(
      'AnalyticsScreen renders Accessories tab with progress cards and deltas',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget(const AnalyticsScreen()));
        await tester.pumpAndSettle();

        // Verify Tab exists
        expect(find.text('Accessories'), findsOneWidget);

        // Switch to Accessories tab
        await tester.tap(find.text('Accessories'));
        await tester.pumpAndSettle();

        // Verify Overview Banner
        expect(find.text('ACCESSORY WEIGHT PROGRESSIONS'), findsOneWidget);
        expect(find.text('4 Movements Tracked'), findsOneWidget);

        // Verify Movement Progression Cards & Positive Delta Chips
        expect(find.text('Bicep Curls / Hammer Curls'), findsOneWidget);
        expect(find.text('+5.0 KG'), findsAtLeast(1));
        expect(find.text('Overhead Tricep Extensions'), findsOneWidget);
        expect(find.text('+2.5 KG'), findsAtLeast(1));
        expect(find.text('Sots Press & Snatch Balance Prep'), findsOneWidget);
      },
    );

    testWidgets(
      'VideoPlayerCard adjusts target reps and allows individual set editing via long press',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final MobilityExerciseModel accessoryEx = MobilityExerciseModel(
          id: 'lu_raises',
          name: 'Lu Raises (Lateral Full Range)',
          focusArea: MobilityFocusArea.shoulderOverhead,
          category: MobilityCategory.liftingAccessory,
          description: 'Shoulder mobility and hypertrophy.',
          cues: <String>['Controlled tempo.'],
          defaultSets: 3,
          defaultReps: 12,
          videoUrl: 'https://youtube.com',
        );

        bool completedTriggered = false;

        await tester.pumpWidget(
          buildTestWidget(
            SingleChildScrollView(
              child: VideoPlayerCard(
                exercise: accessoryEx,
                onCompleted: () {
                  completedTriggered = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Target reps header displays 12 Reps
        expect(find.text('3 Sets × 12 Reps'), findsOneWidget);
        expect(find.text('Target Reps:'), findsOneWidget);
        expect(find.text('12 reps'), findsOneWidget);

        // Tap '+1' on reps stepper -> becomes 13 reps
        expect(find.text('+1'), findsOneWidget);
        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();

        expect(find.text('3 Sets × 13 Reps'), findsOneWidget);
        expect(find.text('13 reps'), findsOneWidget);

        // Sets reflect 13 reps
        expect(find.text('Set 1: 10.0KG × 13'), findsOneWidget);

        // Long press on Set 1 to open WorkoutSetEditDialog
        await tester.longPress(find.text('Set 1: 10.0KG × 13'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Set 1'), findsOneWidget);

        // Tap 10 Reps preset in dialog
        expect(find.text('10 Reps'), findsOneWidget);
        await tester.tap(find.text('10 Reps'));
        await tester.pumpAndSettle();

        // Tap Save Set in dialog
        await tester.tap(find.text('Save Set'));
        await tester.pumpAndSettle();

        // Set 1 updated to 10 reps
        expect(find.text('Set 1: 10.0KG × 10'), findsOneWidget);

        // Tap all 3 sets to complete the exercise
        await tester.tap(find.text('Set 1: 10.0KG × 10'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Set 2: 10.0KG × 13'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Set 3: 10.0KG × 13'));
        await tester.pumpAndSettle();

        expect(completedTriggered, isTrue);

        // Verify logged in recovery provider
        final AccessoryLog? latest = recoveryProvider.getLatestAccessoryLog('lu_raises');
        expect(latest, isNotNull);
        expect(latest?.reps, 13);
      },
    );
  });
}
