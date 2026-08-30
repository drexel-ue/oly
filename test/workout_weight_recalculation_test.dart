import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/workout_set_edit_dialog.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late LiftProvider liftProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    liftProvider = LiftProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  group('WorkoutWeightHelper 1RM Calculation Tests', () {
    test(
      'Calculates implied 1RM correctly from week percentage (e.g. 70%)',
      () {
        final ExerciseTemplate exercise = ExerciseTemplate(
          name: 'Power Snatch + Overhead Squat',
          liftId: 'snatch',
          setScheme: '4 Sets of 2 Reps',
          weekPercentages: <int, double>{1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
        );

        // In Week 2 (70%), if lifter moves 70.0 kg, implied 1RM is 70 / 0.70 = 100.0 kg
        final double implied1RMWeek2 =
            WorkoutWeightHelper.calculateImplied1RMPeriodization(
              workingWeightKg: 70.0,
              exerciseTemplate: exercise,
              currentWeek: 2,
            );
        expect(implied1RMWeek2, closeTo(100.0, 0.01));

        // In Week 3 (75%), if lifter moves 60.0 kg, implied 1RM is 60 / 0.75 = 80.0 kg
        final double implied1RMWeek3 =
            WorkoutWeightHelper.calculateImplied1RMPeriodization(
              workingWeightKg: 60.0,
              exerciseTemplate: exercise,
              currentWeek: 3,
            );
        expect(implied1RMWeek3, closeTo(80.0, 0.01));
      },
    );

    test(
      'Calculates implied 1RM correctly from fixed percentage (e.g. 90%)',
      () {
        final ExerciseTemplate exercise = ExerciseTemplate(
          name: 'Snatch Pull',
          liftId: 'snatch',
          setScheme: '3 Sets of 2 Reps',
          fixedPercentage: 90.0,
        );

        // If lifter pulls 90.0 kg at 90% fixed, implied 1RM is 90 / 0.90 = 100.0 kg
        final double implied1RM =
            WorkoutWeightHelper.calculateImplied1RMPeriodization(
              workingWeightKg: 90.0,
              exerciseTemplate: exercise,
              currentWeek: 1,
            );
        expect(implied1RM, closeTo(100.0, 0.01));
      },
    );

    test('Calculates implied 1RM correctly with weekly linear increments', () {
      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Push Press',
        liftId: 'clean_and_jerk',
        setScheme: '3 Sets of 5 Reps',
        weeklyWeightIncrementKg: 2.5,
      );

      // In Week 1: 60kg working weight -> 60 / 0.60 = 100.0 kg
      final double implied1RMWeek1 =
          WorkoutWeightHelper.calculateImplied1RMPeriodization(
            workingWeightKg: 60.0,
            exerciseTemplate: exercise,
            currentWeek: 1,
          );
      expect(implied1RMWeek1, closeTo(100.0, 0.01));

      // In Week 3: Increment total is (3 - 1) * 2.5 = 5.0 kg.
      // If working weight is 65.0 kg -> (65 - 5) / 0.60 = 100.0 kg
      final double implied1RMWeek3 =
          WorkoutWeightHelper.calculateImplied1RMPeriodization(
            workingWeightKg: 65.0,
            exerciseTemplate: exercise,
            currentWeek: 3,
          );
      expect(implied1RMWeek3, closeTo(100.0, 0.01));
    });

    test('Calculates Epley 1RM correctly for multi-rep sets', () {
      // 100kg for 3 reps: 100 * (1 + 3/30) = 110.0 kg
      final double epley3Reps = WorkoutWeightHelper.calculateImplied1RMEpley(
        workingWeightKg: 100.0,
        reps: 3,
      );
      expect(epley3Reps, closeTo(110.0, 0.01));

      // 100kg for 1 rep: 100.0 kg
      final double epley1Rep = WorkoutWeightHelper.calculateImplied1RMEpley(
        workingWeightKg: 100.0,
        reps: 1,
      );
      expect(epley1Rep, closeTo(100.0, 0.01));
    });

    test('Extracts rep counts from various set scheme formats', () {
      expect(
        WorkoutWeightHelper.extractRepsCount('4 Sets of 2 Reps'),
        equals(2),
      );
      expect(
        WorkoutWeightHelper.extractRepsCount('3 Sets of 5 Reps'),
        equals(5),
      );
      expect(
        WorkoutWeightHelper.extractRepsCount('4 Sets of 1 Rep'),
        equals(1),
      );
      expect(
        WorkoutWeightHelper.extractRepsCount('3 Sets of 12 Reps'),
        equals(12),
      );
    });
  });

  group('WorkoutWeightDialog Widget Tests', () {
    testWidgets(
      'Renders working weight input, steppers, and calculates live 1RM preview',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final ExerciseTemplate exercise = ExerciseTemplate(
          name: 'Power Snatch + Overhead Squat',
          liftId: 'snatch',
          setScheme: '4 Sets of 2 Reps',
          weekPercentages: <int, double>{1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
        );

        double? updatedWeight;
        bool? updated1RMFlag;
        double? updated1RMValue;

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider.value(value: liftProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: WorkoutWeightDialog(
                  exercise: exercise,
                  displayName: 'Power Snatch + Overhead Squat',
                  initialWeightKg: 56.0, // 70% of baseline 80kg snatch
                  currentWeek: 2,
                  onWeightUpdated:
                      ({
                        required double newWeightKg,
                        int? newReps,
                        required bool update1RM,
                        double? new1RMKg,
                      }) {
                        updatedWeight = newWeightKg;
                        updated1RMFlag = update1RM;
                        updated1RMValue = new1RMKg;
                      },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check title and baseline
        expect(find.text('Update Working Weight & Reps'), findsOneWidget);
        expect(find.text('Catalog Lift: Snatch'), findsOneWidget);

        // Check steppers exist
        expect(find.text('+5.0'), findsOneWidget);

        // Tap +5.0 stepper twice -> 56 + 10 = 66.0 kg
        await tester.tap(find.text('+5.0'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('+5.0'));
        await tester.pumpAndSettle();

        // Tap "Update & Recalc 1RM" button
        await tester.tap(find.text('Update & Recalc 1RM'));
        await tester.pumpAndSettle();

        expect(updatedWeight, closeTo(66.0, 0.1));
        expect(updated1RMFlag, isTrue);
        // 66.0 / 0.70 = ~94.28 kg
        expect(updated1RMValue, closeTo(94.28, 0.5));
      },
    );

    testWidgets(
      'Updates weight & reps without recalculating catalog 1RM when Weight & Reps Only is tapped',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final ExerciseTemplate exercise = ExerciseTemplate(
          name: 'Back Squat',
          liftId: 'back_squat',
          setScheme: '4 Sets of 6-8 Reps',
          weekPercentages: <int, double>{1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
        );

        double? updatedWeight;
        int? updatedReps;
        bool? updated1RMFlag;

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider.value(value: liftProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: WorkoutWeightDialog(
                  exercise: exercise,
                  displayName: 'Back Squat',
                  initialWeightKg: 100.0,
                  initialReps: 6,
                  currentWeek: 2,
                  onWeightUpdated:
                      ({
                        required double newWeightKg,
                        int? newReps,
                        required bool update1RM,
                        double? new1RMKg,
                      }) {
                        updatedWeight = newWeightKg;
                        updatedReps = newReps;
                        updated1RMFlag = update1RM;
                      },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select 8 Reps preset
        expect(find.text('8 Reps'), findsOneWidget);
        await tester.tap(find.text('8 Reps'));
        await tester.pumpAndSettle();

        // Tap "Weight & Reps Only"
        await tester.tap(find.text('Weight & Reps Only'));
        await tester.pumpAndSettle();

        expect(updatedWeight, closeTo(100.0, 0.01));
        expect(updatedReps, equals(8));
        expect(updated1RMFlag, isFalse);
      },
    );

    testWidgets(
      'Live Epley 1RM recalculation updates dynamically when reps change',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final ExerciseTemplate exercise = ExerciseTemplate(
          name: 'Clean and Jerk',
          liftId: 'clean_and_jerk',
          setScheme: '3 Sets of 3 Reps',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider.value(value: liftProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: WorkoutWeightDialog(
                  exercise: exercise,
                  displayName: 'Clean and Jerk',
                  initialWeightKg: 100.0,
                  initialReps: 1,
                  currentWeek: 1,
                  onWeightUpdated:
                      ({
                        required double newWeightKg,
                        int? newReps,
                        required bool update1RM,
                        double? new1RMKg,
                      }) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to Epley formula
        expect(find.textContaining('Formula:'), findsOneWidget);
        await tester.tap(find.textContaining('Formula:'));
        await tester.pumpAndSettle();

        expect(find.text('Formula: Epley (1 Reps)'), findsOneWidget);

        // At 100kg and 1 rep, implied 1RM is 100kg
        expect(find.text('100 kg'), findsWidgets);

        // Tap 5 Reps preset -> 100 * (1 + 5/30) = 116.66kg -> rounded to 116.5 kg
        await tester.tap(find.text('5 Reps'));
        await tester.pumpAndSettle();

        expect(find.text('Formula: Epley (5 Reps)'), findsOneWidget);
        expect(find.text('116.5 kg'), findsWidgets);
      },
    );
  });

  group('WorkoutSetEditDialog Widget Tests', () {
    testWidgets(
      'Renders set weight, reps, steppers, and saves updated individual set parameters',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final CompletedSet originalSet = CompletedSet(
          setIndex: 2,
          weight: 80.0,
          reps: 3,
          isCompleted: false,
        );

        double? savedWeight;
        int? savedReps;
        bool? savedCompletion;
        bool? savedApplyToSubsequent;

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: WorkoutSetEditDialog(
                  exerciseName: 'Snatch',
                  currentSet: originalSet,
                  totalSets: 4,
                  onSaveSet: ({
                    required double newWeightKg,
                    required int newReps,
                    required bool isCompleted,
                    bool applyToSubsequentSets = false,
                  }) {
                    savedWeight = newWeightKg;
                    savedReps = newReps;
                    savedCompletion = isCompleted;
                    savedApplyToSubsequent = applyToSubsequentSets;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check header and displays
        expect(find.text('Edit Set 2'), findsOneWidget);
        expect(find.text('Snatch'), findsOneWidget);

        // Weight steppers: tap +5.0 -> 85.0 kg
        expect(find.text('+5.0'), findsOneWidget);
        await tester.tap(find.text('+5.0'));
        await tester.pumpAndSettle();

        // Rep presets: tap 5 Reps
        expect(find.text('5 Reps'), findsOneWidget);
        await tester.tap(find.text('5 Reps'));
        await tester.pumpAndSettle();

        // Toggle Mark Set as Completed
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Toggle apply to remaining sets
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Save Set'));
        await tester.pumpAndSettle();

        expect(savedWeight, closeTo(85.0, 0.01));
        expect(savedReps, equals(5));
        expect(savedCompletion, isTrue);
        expect(savedApplyToSubsequent, isTrue);
      },
    );
  });
}

