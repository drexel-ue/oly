import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/program_model.dart';

void main() {
  group('Percentage Matrix & Periodization Tests', () {
    test(
      'ExerciseTemplate calculates correct week 1..4 percentages based on 1RM',
      () {
        final ExerciseTemplate exercise = ExerciseTemplate(
          name: 'Power Snatch',
          liftId: 'snatch',
          setScheme: '4 Sets of 2 Reps',
          weekPercentages: <int, double>{1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
        );

        final Map<String, double> maxes = <String, double>{'snatch': 100.0};

        expect(
          exercise.calculateTargetWeight(week: 1, currentMaxes: maxes),
          equals(65.0),
        );
        expect(
          exercise.calculateTargetWeight(week: 2, currentMaxes: maxes),
          equals(70.0),
        );
        expect(
          exercise.calculateTargetWeight(week: 3, currentMaxes: maxes),
          equals(75.0),
        );
        expect(
          exercise.calculateTargetWeight(week: 4, currentMaxes: maxes),
          equals(70.0),
        );
      },
    );

    test('ExerciseTemplate handles anchor lift overrides (e.g. Front Squat % of Clean & Jerk)', () {
      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Front Squat',
        liftId: 'front_squat',
        anchorLiftId: 'clean_and_jerk',
        setScheme: '4 Sets of 3-5 Reps',
        fixedPercentage: 75.0,
      );

      final Map<String, double> maxes = <String, double>{
        'snatch': 80.0,
        'clean_and_jerk': 100.0,
        'back_squat': 135.0,
      };

      // 75% of 100kg C&J = 75kg
      expect(
        exercise.calculateTargetWeight(week: 1, currentMaxes: maxes),
        equals(75.0),
      );
    });

    test('Built-in program contains 6 days (Day 1 -> Recovery -> Day 2 -> Recovery -> Day 3 -> Recovery)', () {
      final List<DayTemplate> days = ProgramCycle.getBuiltInProgram();
      expect(days.length, equals(6));

      expect(days[0].isActiveRecovery, isFalse); // Day 1 Lift
      expect(days[1].isActiveRecovery, isTrue); // Recovery Day 1 (Day 2)
      expect(days[2].isActiveRecovery, isFalse); // Day 2 Lift (Day 3)
      expect(days[3].isActiveRecovery, isTrue); // Recovery Day 2 (Day 4)
      expect(days[4].isActiveRecovery, isFalse); // Day 3 Lift (Day 5)
      expect(days[5].isActiveRecovery, isTrue); // Recovery Day 3 (Day 6)
    });

    test('ExerciseTemplate correctly calculates weights for previewed peak weeks (e.g. Week 3)', () {
      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Block Clean',
        liftId: 'clean_and_jerk',
        setScheme: '4 Sets of 2-3 Reps',
        weekPercentages: <int, double>{1: 70.0, 2: 75.0, 3: 80.0, 4: 75.0},
      );

      final Map<String, double> maxes = <String, double>{
        'clean_and_jerk': 100.0,
      };
      // Previewing Week 3 -> 80% of 100kg = 80kg
      expect(
        exercise.calculateTargetWeight(week: 3, currentMaxes: maxes),
        equals(80.0),
      );
    });

    test('LiftModel calculates correct 1RM suggestion for variation lift (Hang Snatch from Snatch)', () {
      final List<LiftModel> lifts = LiftModel.defaultLifts();
      final LiftModel snatch = lifts.firstWhere(
        (LiftModel l) => l.id == 'snatch',
      );
      final LiftModel hangSnatch = lifts.firstWhere(
        (LiftModel l) => l.id == 'hang_snatch',
      );

      snatch.currentMax = 100.0;
      // Hang Snatch target ratio is 0.88 (88%)
      final double expectedSuggested =
          snatch.currentMax * hangSnatch.targetRatio;
      expect(expectedSuggested, equals(88.0));
    });
  });
}
