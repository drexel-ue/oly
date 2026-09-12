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
          (m) =>
              m.focusArea == MobilityFocusArea.quadriceps ||
              m.focusArea == MobilityFocusArea.hipCapsule,
        ),
        isTrue,
      );
    });

    test('Adapts Split Jerk to Power Jerk when bigToeMtp injury is active', () {
      final ExerciseTemplate jerkEx = ExerciseTemplate(
        name: 'Split Jerk',
        liftId: 'clean_and_jerk',
        setScheme: '3 Sets of 2 Reps',
      );

      final InjuryRecord turfToe = InjuryRecord(
        id: 'toe_1',
        name: 'Turf Toe Strain',
        region: InjuryRegion.leftCalfAnkle,
        subRegion: InjurySubRegion.bigToeMtp,
        onsetDate: DateTime.now().subtract(const Duration(days: 4)),
        painScale: 5,
      );

      final ExerciseAdaptationRecommendation result =
          InjuryAdaptationService.evaluateExercise(
        exercise: jerkEx,
        activeInjuries: <InjuryRecord>[turfToe],
        currentWeek: 1,
        currentMaxes: mockMaxes,
      );

      expect(result.isContraindicated, isTrue);
      expect(result.replacementName, equals('Clean and Power Jerk'));
      expect(result.triggeringInjurySubRegion, equals(InjurySubRegion.bigToeMtp));
      expect(result.rationale, contains('1st MTP'));
    });

    test('Adapts Back Squat to Narrow Stance Box Squat when adductorGroin is active', () {
      final ExerciseTemplate squatEx = ExerciseTemplate(
        name: 'Back Squat',
        liftId: 'back_squat',
        setScheme: '5 Sets of 3 Reps',
      );

      final InjuryRecord groinStrain = InjuryRecord(
        id: 'groin_1',
        name: 'Adductor Strain',
        region: InjuryRegion.leftHipGlute,
        subRegion: InjurySubRegion.adductorGroin,
        onsetDate: DateTime.now().subtract(const Duration(days: 8)),
        painScale: 6,
      );

      final ExerciseAdaptationRecommendation result =
          InjuryAdaptationService.evaluateExercise(
        exercise: squatEx,
        activeInjuries: <InjuryRecord>[groinStrain],
        currentWeek: 1,
        currentMaxes: mockMaxes,
      );

      expect(result.isContraindicated, isTrue);
      expect(result.replacementName, equals('Narrow Stance Box Squat'));
      expect(result.triggeringInjurySubRegion, equals(InjurySubRegion.adductorGroin));
    });

    test('Recommends lifting straps when thumbHookGrip is active', () {
      final ExerciseTemplate snatchEx = ExerciseTemplate(
        name: 'Snatch',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
      );

      final InjuryRecord thumbStrain = InjuryRecord(
        id: 'thumb_1',
        name: 'Hook Grip Thumb Pain',
        region: InjuryRegion.rightWrist,
        subRegion: InjurySubRegion.thumbHookGrip,
        onsetDate: DateTime.now().subtract(const Duration(days: 2)),
        painScale: 4,
      );

      final ExerciseAdaptationRecommendation result =
          InjuryAdaptationService.evaluateExercise(
        exercise: snatchEx,
        activeInjuries: <InjuryRecord>[thumbStrain],
        currentWeek: 1,
        currentMaxes: mockMaxes,
      );

      expect(result.isContraindicated, isTrue);
      expect(result.replacementName, contains('Lifting Straps'));
      expect(result.triggeringInjurySubRegion, equals(InjurySubRegion.thumbHookGrip));
    });
  });
}
