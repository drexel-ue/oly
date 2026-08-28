import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';

class ExerciseAdaptationRecommendation {
  ExerciseAdaptationRecommendation({
    required this.originalExerciseName,
    required this.isContraindicated,
    this.replacementName,
    this.replacementLiftId,
    this.weightMultiplier = 1.0,
    this.suggestedWeightKg,
    this.rationale = '',
    this.triggeringInjuryName,
    this.triggeringInjuryRegion,
    this.triggeringInjuryStage,
  });

  final String originalExerciseName;
  final bool isContraindicated;
  final String? replacementName;
  final String? replacementLiftId;
  final double weightMultiplier;
  final double? suggestedWeightKg;
  final String rationale;
  final String? triggeringInjuryName;
  final InjuryRegion? triggeringInjuryRegion;
  final InjuryStage? triggeringInjuryStage;
}

class SessionAdaptationPlan {
  SessionAdaptationPlan({
    required this.dayTemplate,
    required this.adaptations,
    required this.activeInjuries,
    required this.rehabWarmupSuggestions,
  });

  final DayTemplate dayTemplate;
  final Map<String, ExerciseAdaptationRecommendation> adaptations;
  final List<InjuryRecord> activeInjuries;
  final List<MobilityExerciseModel> rehabWarmupSuggestions;

  bool get hasAdaptations => adaptations.values.any(
        (ExerciseAdaptationRecommendation a) => a.isContraindicated,
      );

  int get adaptedCount => adaptations.values
      .where((ExerciseAdaptationRecommendation a) => a.isContraindicated)
      .length;
}

class InjuryAdaptationService {
  /// Evaluates an ExerciseTemplate against active injury records.
  static ExerciseAdaptationRecommendation evaluateExercise({
    required ExerciseTemplate exercise,
    required List<InjuryRecord> activeInjuries,
    required int currentWeek,
    required Map<String, double> currentMaxes,
  }) {
    final double standardTarget = exercise.calculateTargetWeight(
      week: currentWeek,
      currentMaxes: currentMaxes,
    );

    final List<InjuryRecord> validInjuries =
        activeInjuries.where((InjuryRecord i) => i.isActive).toList();

    if (validInjuries.isEmpty) {
      return ExerciseAdaptationRecommendation(
        originalExerciseName: exercise.name,
        isContraindicated: false,
        suggestedWeightKg: standardTarget,
      );
    }

    final String exNameLower = exercise.name.toLowerCase();

    for (final InjuryRecord injury in validInjuries) {
      // 1. Direct substitution match from catalog
      for (final InjurySubstitution sub in injury.safeSubstitutions) {
        if (exNameLower.contains(sub.targetExercise.toLowerCase()) ||
            exercise.name.toLowerCase() == sub.targetExercise.toLowerCase()) {
          final double base1RM = currentMaxes[sub.replacementLiftId] ??
              currentMaxes[exercise.liftId] ??
              100.0;
          final double adaptedKg = base1RM * 0.70 * sub.weightMultiplier;

          return ExerciseAdaptationRecommendation(
            originalExerciseName: exercise.name,
            isContraindicated: true,
            replacementName: sub.replacementName,
            replacementLiftId: sub.replacementLiftId,
            weightMultiplier: sub.weightMultiplier,
            suggestedWeightKg: adaptedKg,
            rationale: sub.rationale,
            triggeringInjuryName: injury.name,
            triggeringInjuryRegion: injury.region,
            triggeringInjuryStage: injury.stage,
          );
        }
      }

      // 2. Generic constraint rules
      for (final BiomechanicalConstraint constraint in injury.constraints) {
        // Knee flexion constraint
        if (constraint == BiomechanicalConstraint.avoidDeepKneeFlexion) {
          if (exNameLower.contains('snatch') && !exNameLower.contains('power')) {
            return ExerciseAdaptationRecommendation(
              originalExerciseName: exercise.name,
              isContraindicated: true,
              replacementName: 'Power Snatch from Blocks',
              replacementLiftId: 'power_snatch',
              weightMultiplier: 0.82,
              suggestedWeightKg: standardTarget * 0.82,
              rationale: 'Avoid deep knee flexion catch. Power variation from blocks protects patellofemoral joint.',
              triggeringInjuryName: injury.name,
              triggeringInjuryRegion: injury.region,
              triggeringInjuryStage: injury.stage,
            );
          }
          if (exNameLower.contains('squat') && !exNameLower.contains('box')) {
            return ExerciseAdaptationRecommendation(
              originalExerciseName: exercise.name,
              isContraindicated: true,
              replacementName: 'Box Squat (Vertical Shin)',
              replacementLiftId: 'back_squat',
              weightMultiplier: 0.80,
              suggestedWeightKg: standardTarget * 0.80,
              rationale: 'Box squat eliminates forward knee translation while maintaining squat loading.',
              triggeringInjuryName: injury.name,
              triggeringInjuryRegion: injury.region,
              triggeringInjuryStage: injury.stage,
            );
          }
        }

        // Overhead lockout constraint
        if (constraint == BiomechanicalConstraint.avoidOverheadLockout) {
          if (exNameLower.contains('snatch')) {
            return ExerciseAdaptationRecommendation(
              originalExerciseName: exercise.name,
              isContraindicated: true,
              replacementName: 'Snatch High Pull (Straps)',
              replacementLiftId: 'snatch',
              weightMultiplier: 0.90,
              suggestedWeightKg: standardTarget * 0.90,
              rationale: 'Snatch pulls preserve triple extension power without putting shoulder into overhead lockout.',
              triggeringInjuryName: injury.name,
              triggeringInjuryRegion: injury.region,
              triggeringInjuryStage: injury.stage,
            );
          }
          if (exNameLower.contains('press') || exNameLower.contains('jerk')) {
            return ExerciseAdaptationRecommendation(
              originalExerciseName: exercise.name,
              isContraindicated: true,
              replacementName: 'Landmine Press (Neutral Grip)',
              replacementLiftId: 'military_press',
              weightMultiplier: 0.75,
              suggestedWeightKg: standardTarget * 0.75,
              rationale: 'Scapular plane pressing relieves subacromial impingement and rotator cuff strain.',
              triggeringInjuryName: injury.name,
              triggeringInjuryRegion: injury.region,
              triggeringInjuryStage: injury.stage,
            );
          }
        }

        // Spinal shear / floor pull constraint
        if (constraint == BiomechanicalConstraint.avoidAxialSpinalShear ||
            constraint == BiomechanicalConstraint.avoidFloorPullShear) {
          if (exNameLower.contains('deadlift')) {
            return ExerciseAdaptationRecommendation(
              originalExerciseName: exercise.name,
              isContraindicated: true,
              replacementName: 'Block Pulls (Above Knee)',
              replacementLiftId: 'snatch',
              weightMultiplier: 0.85,
              suggestedWeightKg: standardTarget * 0.85,
              rationale: 'Pulling from blocks reduces lumbar spinal shear moment arm.',
              triggeringInjuryName: injury.name,
              triggeringInjuryRegion: injury.region,
              triggeringInjuryStage: injury.stage,
            );
          }
        }

        // Wrist extension constraint
        if (constraint == BiomechanicalConstraint.avoidWristExtension) {
          if (exNameLower.contains('clean') && !exNameLower.contains('pull')) {
            return ExerciseAdaptationRecommendation(
              originalExerciseName: exercise.name,
              isContraindicated: true,
              replacementName: 'Clean Pull with Straps',
              replacementLiftId: 'clean_and_jerk',
              weightMultiplier: 1.0,
              suggestedWeightKg: standardTarget,
              rationale: 'Pull with straps allows full pulling triple extension without wrist extension impact.',
              triggeringInjuryName: injury.name,
              triggeringInjuryRegion: injury.region,
              triggeringInjuryStage: injury.stage,
            );
          }
        }
      }
    }

    return ExerciseAdaptationRecommendation(
      originalExerciseName: exercise.name,
      isContraindicated: false,
      suggestedWeightKg: standardTarget,
    );
  }

  /// Builds a complete session adaptation plan for the given day template.
  static SessionAdaptationPlan generateSessionPlan({
    required DayTemplate dayTemplate,
    required List<InjuryRecord> activeInjuries,
    required int currentWeek,
    required Map<String, double> currentMaxes,
  }) {
    final Map<String, ExerciseAdaptationRecommendation> adaptations =
        <String, ExerciseAdaptationRecommendation>{};

    for (final PhaseTemplate phase in dayTemplate.phases) {
      for (final ExerciseTemplate ex in phase.exercises) {
        final ExerciseAdaptationRecommendation rec = evaluateExercise(
          exercise: ex,
          activeInjuries: activeInjuries,
          currentWeek: currentWeek,
          currentMaxes: currentMaxes,
        );
        adaptations[ex.name] = rec;
      }
    }

    // Collect targeted mobility drills based on active injury rehab focus areas
    final List<MobilityExerciseModel> allCatalogDrills =
        MobilityExerciseModel.defaultExercises();
    final List<MobilityExerciseModel> suggestedRehab = <MobilityExerciseModel>[];

    final Set<MobilityFocusArea> activeFocusAreas = <MobilityFocusArea>{};
    for (final InjuryRecord injury in activeInjuries.where((InjuryRecord i) => i.isActive)) {
      activeFocusAreas.addAll(injury.rehabFocusAreas);
    }

    for (final MobilityExerciseModel drill in allCatalogDrills) {
      if (activeFocusAreas.contains(drill.focusArea)) {
        if (!suggestedRehab.any((MobilityExerciseModel d) => d.id == drill.id)) {
          suggestedRehab.add(drill);
        }
      }
    }

    return SessionAdaptationPlan(
      dayTemplate: dayTemplate,
      adaptations: adaptations,
      activeInjuries: activeInjuries,
      rehabWarmupSuggestions: suggestedRehab,
    );
  }
}
