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

    test('Built-in program contains 6 days (Day 1 -> Free-Form -> Day 2 -> Free-Form -> Day 3 -> Free-Form)', () {
      final List<DayTemplate> days = ProgramCycle.getBuiltInProgram();
      expect(days.length, equals(6));

      expect(days[0].isFreeform, isFalse); // Day 1 Lift
      expect(days[1].isFreeform, isTrue); // Free-Form Conditioning (Day 2)
      expect(days[2].isFreeform, isFalse); // Day 2 Lift (Day 3)
      expect(days[3].isFreeform, isTrue); // Free-Form Conditioning (Day 4)
      expect(days[4].isFreeform, isFalse); // Day 3 Lift (Day 5)
      expect(days[5].isFreeform, isTrue); // Free-Form Conditioning (Day 6)
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

    test('Week 1 (Week A) alternates 2 Snatch days to 1 Clean & Jerk day', () {
      final List<DayTemplate> week1Days =
          ProgramCycle.getBuiltInProgram(week: 1);
      expect(week1Days.length, equals(6));

      // Day 1: Snatch + Squat (2 exercises)
      final List<ExerciseTemplate> day1Exercises =
          week1Days[0].phases.expand((PhaseTemplate p) => p.exercises).toList();
      expect(day1Exercises.length, equals(2));
      expect(day1Exercises[0].liftId, equals('snatch'));
      expect(day1Exercises[1].liftId, equals('back_squat'));

      // Day 3 (Lifting Day 2): Clean & Jerk + Front Squat (2 exercises)
      final List<ExerciseTemplate> day3Exercises =
          week1Days[2].phases.expand((PhaseTemplate p) => p.exercises).toList();
      expect(day3Exercises.length, equals(2));
      expect(day3Exercises[0].liftId, equals('clean_and_jerk'));
      expect(day3Exercises[1].anchorLiftId, equals('clean_and_jerk'));

      // Day 5 (Lifting Day 3): Snatch + Snatch Pull (2 exercises)
      final List<ExerciseTemplate> day5Exercises =
          week1Days[4].phases.expand((PhaseTemplate p) => p.exercises).toList();
      expect(day5Exercises.length, equals(2));
      expect(day5Exercises[0].liftId, equals('snatch'));
      expect(day5Exercises[1].liftId, equals('snatch'));
    });

    test('Week 2 (Week B) alternates 1 Snatch day to 2 Clean & Jerk days', () {
      final List<DayTemplate> week2Days =
          ProgramCycle.getBuiltInProgram(week: 2);
      expect(week2Days.length, equals(6));

      // Day 1: Clean & Jerk + Front Squat (2 exercises)
      final List<ExerciseTemplate> day1Exercises =
          week2Days[0].phases.expand((PhaseTemplate p) => p.exercises).toList();
      expect(day1Exercises.length, equals(2));
      expect(day1Exercises[0].liftId, equals('clean_and_jerk'));
      expect(day1Exercises[1].anchorLiftId, equals('clean_and_jerk'));

      // Day 3 (Lifting Day 2): Snatch + Back Squat (2 exercises)
      final List<ExerciseTemplate> day3Exercises =
          week2Days[2].phases.expand((PhaseTemplate p) => p.exercises).toList();
      expect(day3Exercises.length, equals(2));
      expect(day3Exercises[0].liftId, equals('snatch'));
      expect(day3Exercises[1].liftId, equals('back_squat'));

      // Day 5 (Lifting Day 3): Clean & Jerk (Hang Clean) + Clean Pull (2 exercises)
      final List<ExerciseTemplate> day5Exercises =
          week2Days[4].phases.expand((PhaseTemplate p) => p.exercises).toList();
      expect(day5Exercises.length, equals(2));
      expect(day5Exercises[0].liftId, equals('clean_and_jerk'));
      expect(day5Exercises[1].liftId, equals('clean_and_jerk'));
    });

    test('Week 5 generates dedicated 1RM Retest protocols for Snatch, C&J, and Squat', () {
      final List<DayTemplate> week5Days =
          ProgramCycle.getBuiltInProgram(week: 5);
      expect(week5Days.length, equals(6));

      // Day 1: Snatch 1RM Retest
      expect(week5Days[0].title, contains('Snatch 1RM Retest'));
      expect(week5Days[0].phases[0].exercises[0].liftId, equals('snatch'));
      expect(
        week5Days[0].phases[0].exercises[0].fixedPercentage,
        equals(100.0),
      );

      // Day 3: Clean & Jerk 1RM Retest
      expect(week5Days[2].title, contains('Clean & Jerk 1RM Retest'));
      expect(
        week5Days[2].phases[0].exercises[0].liftId,
        equals('clean_and_jerk'),
      );
      expect(
        week5Days[2].phases[0].exercises[0].fixedPercentage,
        equals(100.0),
      );

      // Day 5: Back Squat 1RM Retest
      expect(week5Days[4].title, contains('Back Squat 1RM Retest'));
      expect(week5Days[4].phases[0].exercises[0].liftId, equals('back_squat'));
      expect(
        week5Days[4].phases[0].exercises[0].fixedPercentage,
        equals(100.0),
      );
    });
  });
}
