import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/services/injury_adaptation_service.dart';

void main() {
  group('InjuryAdaptationService Tests', () {
    final Map<String, double> mockMaxes = <String, double>{
      'snatch': 100.0,
      'clean_and_jerk': 120.0,
      'back_squat': 150.0,
      'front_squat': 130.0,
      'military_press': 70.0,
      'power_snatch': 85.0,
    };

    test('Leaves exercise unchanged when no active injuries exist', () {
      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Snatch',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
      );

      final ExerciseAdaptationRecommendation result =
          InjuryAdaptationService.evaluateExercise(
        exercise: exercise,
        activeInjuries: <InjuryRecord>[],
        currentWeek: 1,
        currentMaxes: mockMaxes,
      );

      expect(result.isContraindicated, isFalse);
      expect(result.originalExerciseName, equals('Snatch'));
      expect(result.replacementName, isNull);
    });

    test('Recommends Power Snatch from Blocks when patellar tendinopathy is active', () {
      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Snatch',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
      );

      final InjuryRecord kneeInjury = InjuryRecord(
        id: 'patella_1',
        name: 'Patellar Tendinopathy',
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now().subtract(const Duration(days: 5)),
        painScale: 5,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ],
        safeSubstitutions: <InjurySubstitution>[
          InjurySubstitution(
            targetExercise: 'Snatch',
            replacementName: 'Power Snatch from Blocks',
            replacementLiftId: 'power_snatch',
            weightMultiplier: 0.82,
            rationale: 'High blocks eliminate deep knee catch shock.',
          ),
        ],
      );

      final ExerciseAdaptationRecommendation result =
          InjuryAdaptationService.evaluateExercise(
        exercise: exercise,
        activeInjuries: <InjuryRecord>[kneeInjury],
        currentWeek: 1,
        currentMaxes: mockMaxes,
      );

      expect(result.isContraindicated, isTrue);
      expect(result.replacementName, equals('Power Snatch from Blocks'));
      expect(result.replacementLiftId, equals('power_snatch'));
      expect(result.rationale, contains('High blocks eliminate deep knee catch shock'));
      expect(result.triggeringInjuryName, equals('Patellar Tendinopathy'));
      expect(result.triggeringInjuryStage, equals(InjuryStage.acute));
    });

    test('Recommends Landmine Press when shoulder impingement constraint is active', () {
      final ExerciseTemplate pressExercise = ExerciseTemplate(
        name: 'Military Press',
        liftId: 'military_press',
        setScheme: '3 Sets of 8 Reps',
      );

      final InjuryRecord shoulderInjury = InjuryRecord(
        id: 'shoulder_1',
        name: 'Shoulder Impingement',
        region: InjuryRegion.rightShoulder,
        onsetDate: DateTime.now().subtract(const Duration(days: 30)),
        painScale: 4,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidOverheadLockout,
        ],
      );

      final ExerciseAdaptationRecommendation result =
          InjuryAdaptationService.evaluateExercise(
        exercise: pressExercise,
        activeInjuries: <InjuryRecord>[shoulderInjury],
        currentWeek: 2,
        currentMaxes: mockMaxes,
      );

      expect(result.isContraindicated, isTrue);
      expect(result.replacementName, equals('Landmine Press (Neutral Grip)'));
      expect(result.triggeringInjuryStage, equals(InjuryStage.subacute));
    });

    test('Generates complete SessionAdaptationPlan with suggested rehab warmups', () {
      final DayTemplate day1 = ProgramCycle.getBuiltInProgram().first;

      final InjuryRecord kneeInjury = InjuryRecord(
        id: 'patella_1',
        name: "Patellar Jumper's Knee",
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now().subtract(const Duration(days: 50)),
        painScale: 6,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
        ],
        rehabFocusAreas: <MobilityFocusArea>[
          MobilityFocusArea.quadriceps,
          MobilityFocusArea.hipCapsule,
        ],
      );

      final SessionAdaptationPlan plan =
          InjuryAdaptationService.generateSessionPlan(
        dayTemplate: day1,
        activeInjuries: <InjuryRecord>[kneeInjury],
        currentWeek: 1,
        currentMaxes: mockMaxes,
      );

      expect(plan.hasAdaptations, isTrue);
      expect(plan.adaptedCount, greaterThanOrEqualTo(1));
      expect(plan.rehabWarmupSuggestions.isNotEmpty, isTrue);
      expect(
        plan.rehabWarmupSuggestions.any(
          (MobilityExerciseModel m) =>
              m.focusArea == MobilityFocusArea.quadriceps ||
              m.focusArea == MobilityFocusArea.hipCapsule,
        ),
        isTrue,
      );
    });
  });
}
