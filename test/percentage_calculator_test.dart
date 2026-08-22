import 'package:flutter_test/flutter_test.dart';
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

    test('Built-in program contains 4 days including Active Recovery Day 4', () {
      final days = ProgramCycle.getBuiltInProgram();
      expect(days.length, equals(4));

      final day4 = days[3];
      expect(day4.isActiveRecovery, isTrue);
      expect(day4.title, contains('In-Between Day'));
    });
  });
}
