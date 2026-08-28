import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/services/warmup_engine_service.dart';

void main() {
  group('WarmupEngineService Tests', () {
    test(
      'Generates Snatch barbell prep when today includes Snatch exercises',
      () {
        final DayTemplate snatchDay = DayTemplate(
          dayNumber: 1,
          title: 'Day 1: Snatch Focus & Heavy Back Squat',
          subtitle: 'Snatch & Squats',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Primary Snatch',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Snatch',
                  liftId: 'snatch',
                  setScheme: '3 Sets of 5 Reps',
                ),
              ],
            ),
          ],
        );

        final GeneratedWarmupRoutine warmup =
            WarmupEngineService.generateWarmup(dayTemplate: snatchDay);

        expect(warmup.phaseGroups.length, equals(4));
        expect(
          warmup.diagnosticReasons.any((String r) => r.contains('Snatch')),
          isTrue,
        );
        expect(
          warmup.exercises.any(
            (MobilityExerciseModel e) =>
                e.focusArea == MobilityFocusArea.barbellSnatch,
          ),
          isTrue,
        );
      },
    );

    test('Generates Clean & Jerk barbell prep when today includes Clean & Jerk exercises', () {
      final DayTemplate cjDay = DayTemplate(
        dayNumber: 3,
        title: 'Day 3: Clean & Jerk Focus',
        subtitle: 'Clean & Jerk',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Primary C&J',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Clean & Jerk',
                liftId: 'clean_and_jerk',
                setScheme: '3 Sets of 5 Reps',
              ),
            ],
          ),
        ],
      );

      final GeneratedWarmupRoutine warmup = WarmupEngineService.generateWarmup(
        dayTemplate: cjDay,
      );

      expect(warmup.phaseGroups.length, equals(4));
      expect(
        warmup.diagnosticReasons.any((String r) => r.contains('Clean & Jerk')),
        isTrue,
      );
      expect(
        warmup.exercises.any(
          (MobilityExerciseModel e) =>
              e.focusArea == MobilityFocusArea.barbellCleanJerk,
        ),
        isTrue,
      );
    });
  });
}
