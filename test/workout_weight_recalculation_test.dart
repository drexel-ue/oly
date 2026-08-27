import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late LiftProvider liftProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    liftProvider = LiftProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  group('WorkoutWeightHelper 1RM Calculation Tests', () {
    test('Calculates implied 1RM correctly from week percentage (e.g. 70%)', () {
      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      // In Week 2 (70%), if lifter moves 70.0 kg, implied 1RM is 70 / 0.70 = 100.0 kg
      final implied1RMWeek2 = WorkoutWeightHelper.calculateImplied1RMPeriodization(
        workingWeightKg: 70.0,
        exerciseTemplate: exercise,
        currentWeek: 2,
      );
      expect(implied1RMWeek2, closeTo(100.0, 0.01));

      // In Week 3 (75%), if lifter moves 60.0 kg, implied 1RM is 60 / 0.75 = 80.0 kg
      final implied1RMWeek3 = WorkoutWeightHelper.calculateImplied1RMPeriodization(
        workingWeightKg: 60.0,
        exerciseTemplate: exercise,
        currentWeek: 3,
      );
      expect(implied1RMWeek3, closeTo(80.0, 0.01));
    });

    test('Calculates implied 1RM correctly from fixed percentage (e.g. 90%)', () {
      final exercise = ExerciseTemplate(
        name: 'Snatch Pull',
        liftId: 'snatch',
        setScheme: '3 Sets of 2 Reps',
        fixedPercentage: 90.0,
      );

      // If lifter pulls 90.0 kg at 90% fixed, implied 1RM is 90 / 0.90 = 100.0 kg
      final implied1RM = WorkoutWeightHelper.calculateImplied1RMPeriodization(
        workingWeightKg: 90.0,
        exerciseTemplate: exercise,
        currentWeek: 1,
      );
      expect(implied1RM, closeTo(100.0, 0.01));
    });

    test('Calculates implied 1RM correctly with weekly linear increments', () {
      final exercise = ExerciseTemplate(
        name: 'Push Press',
        liftId: 'clean_and_jerk',
        setScheme: '3 Sets of 5 Reps',
        weeklyWeightIncrementKg: 2.5,
      );

      // In Week 1: 60kg working weight -> 60 / 0.60 = 100.0 kg
      final implied1RMWeek1 = WorkoutWeightHelper.calculateImplied1RMPeriodization(
        workingWeightKg: 60.0,
        exerciseTemplate: exercise,
        currentWeek: 1,
      );
      expect(implied1RMWeek1, closeTo(100.0, 0.01));

      // In Week 3: Increment total is (3 - 1) * 2.5 = 5.0 kg.
      // If working weight is 65.0 kg -> (65 - 5) / 0.60 = 100.0 kg
      final implied1RMWeek3 = WorkoutWeightHelper.calculateImplied1RMPeriodization(
        workingWeightKg: 65.0,
        exerciseTemplate: exercise,
        currentWeek: 3,
      );
      expect(implied1RMWeek3, closeTo(100.0, 0.01));
    });

    test('Calculates Epley 1RM correctly for multi-rep sets', () {
      // 100kg for 3 reps: 100 * (1 + 3/30) = 110.0 kg
      final epley3Reps = WorkoutWeightHelper.calculateImplied1RMEpley(
        workingWeightKg: 100.0,
        reps: 3,
      );
      expect(epley3Reps, closeTo(110.0, 0.01));

      // 100kg for 1 rep: 100.0 kg
      final epley1Rep = WorkoutWeightHelper.calculateImplied1RMEpley(
        workingWeightKg: 100.0,
        reps: 1,
      );
      expect(epley1Rep, closeTo(100.0, 0.01));
    });

    test('Extracts rep counts from various set scheme formats', () {
      expect(WorkoutWeightHelper.extractRepsCount('4 Sets of 2 Reps'), equals(2));
      expect(WorkoutWeightHelper.extractRepsCount('3 Sets of 5 Reps'), equals(5));
      expect(WorkoutWeightHelper.extractRepsCount('4 Sets of 1 Rep'), equals(1));
      expect(WorkoutWeightHelper.extractRepsCount('3 Sets of 12 Reps'), equals(12));
    });
  });

  group('WorkoutWeightDialog Widget Tests', () {
    testWidgets('Renders working weight input, steppers, and calculates live 1RM preview', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      double? updatedWeight;
      bool? updated1RMFlag;
      double? updated1RMValue;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
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
                onWeightUpdated: ({
                  required double newWeightKg,
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
      expect(find.text('Update Working Weight & 1RM'), findsOneWidget);
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
    });

    testWidgets('Updates weight only without recalculating catalog 1RM when Weight Only is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = ExerciseTemplate(
        name: 'Back Squat',
        liftId: 'back_squat',
        setScheme: '4 Sets of 6-8 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      double? updatedWeight;
      bool? updated1RMFlag;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: liftProvider),
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutWeightDialog(
                exercise: exercise,
                displayName: 'Back Squat',
                initialWeightKg: 100.0,
                currentWeek: 2,
                onWeightUpdated: ({
                  required double newWeightKg,
                  required bool update1RM,
                  double? new1RMKg,
                }) {
                  updatedWeight = newWeightKg;
                  updated1RMFlag = update1RM;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Weight Only"
      await tester.tap(find.text('Weight Only'));
      await tester.pumpAndSettle();

      expect(updatedWeight, closeTo(100.0, 0.01));
      expect(updated1RMFlag, isFalse);
    });
  });
}
