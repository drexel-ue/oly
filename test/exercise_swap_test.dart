import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late LiftProvider liftProvider;
  late SettingsProvider settingsProvider;
  late List<LiftModel> defaultLifts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    liftProvider = LiftProvider(storage);
    settingsProvider = SettingsProvider(storage);
    defaultLifts = LiftModel.defaultLifts();
  });

  group('ExerciseSwapHelper Segmentation Tests', () {
    test('Segments Snatch exercise into snatch variations and others', () {
      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      final result = ExerciseSwapHelper.segmentLifts(
        exercise: exercise,
        allLifts: defaultLifts,
      );

      expect(result.suggested.isNotEmpty, isTrue);
      expect(result.others.isNotEmpty, isTrue);

      final suggestedIds = result.suggested.map((l) => l.id).toSet();
      expect(suggestedIds, containsAll(['snatch', 'power_snatch', 'hang_snatch', 'muscle_snatch']));
      expect(suggestedIds.contains('clean_and_jerk'), isFalse);
      expect(suggestedIds.contains('back_squat'), isFalse);
    });

    test('Segments Clean exercise into clean variations and others', () {
      final exercise = ExerciseTemplate(
        name: 'Hang Clean',
        liftId: 'clean_and_jerk',
        setScheme: '4 Sets of 3 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      final result = ExerciseSwapHelper.segmentLifts(
        exercise: exercise,
        allLifts: defaultLifts,
      );

      final suggestedIds = result.suggested.map((l) => l.id).toSet();
      expect(suggestedIds, containsAll(['clean_and_jerk', 'power_clean', 'hang_clean', 'block_clean']));
      expect(suggestedIds.contains('snatch'), isFalse);
    });

    test('Segments Squat exercise into squat variations and others', () {
      final exercise = ExerciseTemplate(
        name: 'Back Squat',
        liftId: 'back_squat',
        setScheme: '4 Sets of 6-8 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      final result = ExerciseSwapHelper.segmentLifts(
        exercise: exercise,
        allLifts: defaultLifts,
      );

      final suggestedIds = result.suggested.map((l) => l.id).toSet();
      expect(suggestedIds, containsAll(['back_squat', 'front_squat']));
      expect(suggestedIds.contains('snatch'), isFalse);
      expect(suggestedIds.contains('clean_and_jerk'), isFalse);
    });

    test('Segments Pull / Deadlift exercise into pull variations and others', () {
      final exercise = ExerciseTemplate(
        name: 'Snatch Pull',
        liftId: 'snatch',
        setScheme: '3 Sets of 2 Reps',
        fixedPercentage: 90.0,
      );

      final result = ExerciseSwapHelper.segmentLifts(
        exercise: exercise,
        allLifts: defaultLifts,
      );

      final suggestedIds = result.suggested.map((l) => l.id).toSet();
      expect(suggestedIds, containsAll(['snatch_pull', 'snatch_deadlift', 'rdl']));
      expect(suggestedIds.contains('back_squat'), isFalse);
    });

    test('Segments Overhead / Press exercise into overhead variations and others', () {
      final exercise = ExerciseTemplate(
        name: 'Military Press',
        liftId: 'military_press',
        setScheme: '3 Sets of 8 Reps',
        weeklyWeightIncrementKg: 2.5,
      );

      final result = ExerciseSwapHelper.segmentLifts(
        exercise: exercise,
        allLifts: defaultLifts,
      );

      final suggestedIds = result.suggested.map((l) => l.id).toSet();
      expect(suggestedIds, containsAll(['military_press', 'push_press']));
      expect(suggestedIds.contains('snatch'), isFalse);
    });
  });

  group('ExerciseSwapHelper Weight Calculation Tests', () {
    test('Preserves week percentage periodization on swap', () {
      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      final hangSnatch = defaultLifts.firstWhere((l) => l.id == 'hang_snatch'); // max 70kg
      final maxes = {'hang_snatch': 70.0};

      // Week 2 = 70% -> 70 * 0.70 = 49.0 kg
      final weightWeek2 = ExerciseSwapHelper.calculateSwappedWeight(
        newLift: hangSnatch,
        exerciseTemplate: exercise,
        currentWeek: 2,
        currentMaxes: maxes,
      );
      expect(weightWeek2, closeTo(49.0, 0.01));

      // Week 3 = 75% -> 70 * 0.75 = 52.5 kg
      final weightWeek3 = ExerciseSwapHelper.calculateSwappedWeight(
        newLift: hangSnatch,
        exerciseTemplate: exercise,
        currentWeek: 3,
        currentMaxes: maxes,
      );
      expect(weightWeek3, closeTo(52.5, 0.01));
    });

    test('Preserves fixed percentage on swap', () {
      final exercise = ExerciseTemplate(
        name: 'Snatch Pull',
        liftId: 'snatch',
        setScheme: '3 Sets of 2 Reps',
        fixedPercentage: 90.0,
      );

      final snatchDeadlift = defaultLifts.firstWhere((l) => l.id == 'snatch_deadlift'); // max 95kg
      final weight = ExerciseSwapHelper.calculateSwappedWeight(
        newLift: snatchDeadlift,
        exerciseTemplate: exercise,
        currentWeek: 1,
        currentMaxes: {'snatch_deadlift': 95.0},
      );
      expect(weight, closeTo(85.5, 0.01)); // 95 * 0.90
    });

    test('Preserves linear weekly weight increment on swap', () {
      final exercise = ExerciseTemplate(
        name: 'Push Press',
        liftId: 'clean_and_jerk',
        setScheme: '3 Sets of 5 Reps',
        weeklyWeightIncrementKg: 2.5,
      );

      final militaryPress = defaultLifts.firstWhere((l) => l.id == 'military_press'); // max 55kg
      // Week 1: 55 * 0.60 = 33.0 kg
      final weightWeek1 = ExerciseSwapHelper.calculateSwappedWeight(
        newLift: militaryPress,
        exerciseTemplate: exercise,
        currentWeek: 1,
        currentMaxes: {'military_press': 55.0},
      );
      expect(weightWeek1, closeTo(33.0, 0.01));

      // Week 3: (55 * 0.60) + (2 * 2.5) = 38.0 kg
      final weightWeek3 = ExerciseSwapHelper.calculateSwappedWeight(
        newLift: militaryPress,
        exerciseTemplate: exercise,
        currentWeek: 3,
        currentMaxes: {'military_press': 55.0},
      );
      expect(weightWeek3, closeTo(38.0, 0.01));
    });
  });

  group('ExerciseSwapModal Widget Tests', () {
    testWidgets('Renders Suggested Swaps and Other Movements sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      LiftModel? selectedLift;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: liftProvider),
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseSwapModal(
                exercise: exercise,
                currentWeek: 1,
                onSwapSelected: (lift) {
                  selectedLift = lift;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section headers
      expect(find.text('SUGGESTED SWAPS'), findsOneWidget);
      expect(find.text('OTHER MOVEMENTS'), findsOneWidget);

      // Check that a suggested snatch variation appears
      expect(find.text('Hang Snatch'), findsWidgets);

      // Tap on Hang Snatch
      await tester.tap(find.text('Hang Snatch').first);
      await tester.pumpAndSettle();

      expect(selectedLift, isNotNull);
      expect(selectedLift!.id, equals('hang_snatch'));
    });

    testWidgets('Search filters movements dynamically', (tester) async {
      final exercise = ExerciseTemplate(
        name: 'Hang Clean',
        liftId: 'clean_and_jerk',
        setScheme: '4 Sets of 3 Reps',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: liftProvider),
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseSwapModal(
                exercise: exercise,
                currentWeek: 1,
                onSwapSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query "Front"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Front');
      await tester.pumpAndSettle();

      // Front Squat should be visible
      expect(find.text('Front Squat'), findsWidgets);
      // Snatch should not be in the list
      expect(find.text('Power Snatch'), findsNothing);
    });

    testWidgets('Shows Reset button when exercise is currently swapped', (tester) async {
      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
      );

      bool resetTapped = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: liftProvider),
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseSwapModal(
                exercise: exercise,
                currentSwappedName: 'Hang Snatch',
                currentWeek: 1,
                onSwapSelected: (_) {},
                onResetToOriginal: () {
                  resetTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Swap: Hang Snatch'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(resetTapped, isTrue);
    });
  });
}
