import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/program_model.dart';

void main() {
  group('Percentage Matrix & Periodization Tests', () {
    test('ExerciseTemplate calculates correct week 1..4 percentages based on 1RM', () {
      final exercise = ExerciseTemplate(
        name: 'Power Snatch',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      final maxes = {'snatch': 100.0};

      expect(exercise.calculateTargetWeight(week: 1, currentMaxes: maxes), equals(65.0));
      expect(exercise.calculateTargetWeight(week: 2, currentMaxes: maxes), equals(70.0));
      expect(exercise.calculateTargetWeight(week: 3, currentMaxes: maxes), equals(75.0));
      expect(exercise.calculateTargetWeight(week: 4, currentMaxes: maxes), equals(70.0));
    });

    test('ExerciseTemplate handles anchor lift overrides (e.g. Front Squat % of Clean & Jerk)', () {
      final exercise = ExerciseTemplate(
        name: 'Front Squat',
        liftId: 'front_squat',
        anchorLiftId: 'clean_and_jerk',
        setScheme: '4 Sets of 3-5 Reps',
        fixedPercentage: 75.0,
      );

      final maxes = {
        'snatch': 80.0,
        'clean_and_jerk': 100.0,
        'back_squat': 135.0,
      };

      // 75% of 100kg C&J = 75kg
      expect(exercise.calculateTargetWeight(week: 1, currentMaxes: maxes), equals(75.0));
    });

    test('Built-in program contains 5 days (Day 1 -> Recovery -> Day 2 -> Recovery -> Day 3)', () {
      final days = ProgramCycle.getBuiltInProgram();
      expect(days.length, equals(5));

      expect(days[0].isActiveRecovery, isFalse);
      expect(days[1].isActiveRecovery, isTrue); // Recovery Day 2
      expect(days[2].isActiveRecovery, isFalse);
      expect(days[3].isActiveRecovery, isTrue); // Recovery Day 4
      expect(days[4].isActiveRecovery, isFalse);
    });

    test('ExerciseTemplate correctly calculates weights for previewed peak weeks (e.g. Week 3)', () {
      final exercise = ExerciseTemplate(
        name: 'Block Clean',
        liftId: 'clean_and_jerk',
        setScheme: '4 Sets of 2-3 Reps',
        weekPercentages: {1: 70.0, 2: 75.0, 3: 80.0, 4: 75.0},
      );

      final maxes = {'clean_and_jerk': 100.0};
      // Previewing Week 3 -> 80% of 100kg = 80kg
      expect(exercise.calculateTargetWeight(week: 3, currentMaxes: maxes), equals(80.0));
    });

    test('LiftModel calculates correct 1RM suggestion for variation lift (Hang Snatch from Snatch)', () {
      final lifts = LiftModel.defaultLifts();
      final snatch = lifts.firstWhere((l) => l.id == 'snatch');
      final hangSnatch = lifts.firstWhere((l) => l.id == 'hang_snatch');

      snatch.currentMax = 100.0;
      // Hang Snatch target ratio is 0.88 (88%)
      final expectedSuggested = snatch.currentMax * hangSnatch.targetRatio;
      expect(expectedSuggested, equals(88.0));
    });
  });
}
