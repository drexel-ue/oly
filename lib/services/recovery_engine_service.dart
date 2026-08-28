import 'package:oly/models/lift_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';

class RecoveryPhaseGroup {
  RecoveryPhaseGroup({
    required this.phaseNumber,
    required this.title,
    required this.subtitle,
    required this.exercises,
  });
  final int phaseNumber;
  final String title;
  final String subtitle;
  final List<MobilityExerciseModel> exercises;
}

class GeneratedRecoveryRoutine {
  GeneratedRecoveryRoutine({
    required this.phaseGroups,
    required this.exercises,
    required this.diagnosticReasons,
    required this.totalEstimatedMinutes,
  });
  final List<RecoveryPhaseGroup> phaseGroups;
  final List<MobilityExerciseModel> exercises;
  final List<String> diagnosticReasons;
  final int totalEstimatedMinutes;
}

class RecoveryEngineService {
  static GeneratedRecoveryRoutine generateRoutine({
    required List<LiftRatioAnalysis> ratioAnalyses,
    required WorkoutSession? lastSession,
    List<MobilityExerciseModel>? customCatalog,
  }) {
    final List<MobilityExerciseModel> catalog =
        customCatalog ?? MobilityExerciseModel.defaultExercises();
    final Set<MobilityFocusArea> targetFocusAreas = <MobilityFocusArea>{};
    final List<String> diagnosticReasons = <String>[];

    // 1. Inspect Ratio Balance Chart Gaps
    final List<LiftRatioAnalysis> underdeveloped = ratioAnalyses
        .where((LiftRatioAnalysis a) => a.status == 'Underdeveloped')
        .toList();

    for (final LiftRatioAnalysis analysis in underdeveloped) {
      switch (analysis.lift.category) {
        case LiftCategory.overhead:
          targetFocusAreas.add(MobilityFocusArea.thoracicSpine);
          targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
          diagnosticReasons.add(
            'Ratio Gap: ${analysis.lift.name} ratio (${analysis.actualRatio.toStringAsFixed(2)}) is underdeveloped vs target (${analysis.targetRatio.toStringAsFixed(2)}).',
          );
          break;

        case LiftCategory.squat:
          targetFocusAreas.add(MobilityFocusArea.hipCapsule);
          targetFocusAreas.add(MobilityFocusArea.ankleDorsiflexion);
          targetFocusAreas.add(MobilityFocusArea.quadriceps);
          diagnosticReasons.add(
            'Ratio Gap: ${analysis.lift.name} is underdeveloped. Targeting deep receiving squat mechanics.',
          );
          break;

        case LiftCategory.pull:
          targetFocusAreas.add(MobilityFocusArea.posteriorChain);
          diagnosticReasons.add(
            'Ratio Gap: Pulling power in ${analysis.lift.name} needs posterior chain balance.',
          );
          break;

        case LiftCategory.snatch:
        case LiftCategory.cleanAndJerk:
          targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
          targetFocusAreas.add(MobilityFocusArea.thoracicSpine);
          diagnosticReasons.add(
            'Ratio Gap: ${analysis.lift.name} performance targeted with overhead position drills.',
          );
          break;

        default:
          break;
      }
    }

    // 2. Inspect Previous Day's Workout Fatigue
    if (lastSession != null && lastSession.logs.isNotEmpty) {
      bool hadSquats = false;
      bool hadOverhead = false;
      bool hadPulls = false;

      for (final ExerciseLog log in lastSession.logs) {
        final String name = log.exerciseName.toLowerCase();
        if (name.contains('squat')) {
          hadSquats = true;
        }
        if (name.contains('snatch') ||
            name.contains('jerk') ||
            name.contains('press')) {
          hadOverhead = true;
        }
        if (name.contains('pull') ||
            name.contains('deadlift') ||
            name.contains('rdl')) {
          hadPulls = true;
        }
      }

      if (lastSession.jointStrainTags != null &&
          lastSession.jointStrainTags!.isNotEmpty) {
        for (final String tag in lastSession.jointStrainTags!) {
          switch (tag) {
            case 'Shoulders':
              targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
              targetFocusAreas.add(MobilityFocusArea.thoracicSpine);
              diagnosticReasons.add(
                'Athlete Feedback: Shoulder strain reported in last check-in.',
              );
              break;
            case 'Hips':
            case 'Knees':
              targetFocusAreas.add(MobilityFocusArea.hipCapsule);
              targetFocusAreas.add(MobilityFocusArea.ankleDorsiflexion);
              targetFocusAreas.add(MobilityFocusArea.quadriceps);
              diagnosticReasons.add(
                'Athlete Feedback: Lower body joint strain reported in last check-in.',
              );
              break;
            case 'Lower Back':
              targetFocusAreas.add(MobilityFocusArea.posteriorChain);
              diagnosticReasons.add(
                'Athlete Feedback: Posterior chain strain reported in last check-in.',
              );
              break;
            case 'Wrists':
              targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
              diagnosticReasons.add(
                'Athlete Feedback: Wrist & front rack tension targeted.',
              );
              break;
          }
        }
      }

      if (hadSquats) {
        targetFocusAreas.add(MobilityFocusArea.hipCapsule);
        targetFocusAreas.add(MobilityFocusArea.ankleDorsiflexion);
        targetFocusAreas.add(MobilityFocusArea.quadriceps);
        diagnosticReasons.add(
          'Previous Session Load: Squat volume logged in Day ${lastSession.dayNumber} session.',
        );
      }

      if (hadOverhead) {
        targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
        targetFocusAreas.add(MobilityFocusArea.thoracicSpine);
        diagnosticReasons.add(
          'Previous Session Load: Overhead dynamic strain from previous workout.',
        );
      }

      if (hadPulls) {
        targetFocusAreas.add(MobilityFocusArea.posteriorChain);
        diagnosticReasons.add(
          'Previous Session Load: Heavy pulling volume logged in recent session.',
        );
      }
    }

    // Baseline fallback if no gaps or session logs found
    if (targetFocusAreas.isEmpty) {
      targetFocusAreas.addAll(<MobilityFocusArea>[
        MobilityFocusArea.thoracicSpine,
        MobilityFocusArea.hipCapsule,
        MobilityFocusArea.ankleDorsiflexion,
      ]);
      diagnosticReasons.add(
        'Baseline Weightlifting Maintenance: Essential thoracic, hip, and ankle tune-up.',
      );
    }

    // --- BUILD THE 5 PHASES ---

    // Phase 1: Zone 2 Cardio
    final List<MobilityExerciseModel> phase1Exercises = catalog
        .where(
          (MobilityExerciseModel ex) =>
              ex.focusArea == MobilityFocusArea.cardio,
        )
        .toList();

    // Phase 2: Dynamic Mobility & Weak-Point Accessories
    final List<MobilityExerciseModel> selectedMobility = catalog
        .where(
          (MobilityExerciseModel ex) =>
              ex.category == MobilityCategory.mobilityDrill &&
              targetFocusAreas.contains(ex.focusArea),
        )
        .take(3)
        .toList();

    if (selectedMobility.length < 3) {
      final Iterable<MobilityExerciseModel> remaining = catalog
          .where(
            (MobilityExerciseModel ex) =>
                ex.category == MobilityCategory.mobilityDrill &&
                !selectedMobility.contains(ex),
          )
          .take(3 - selectedMobility.length);
      selectedMobility.addAll(remaining);
    }

    final List<MobilityExerciseModel> selectedAccessories = catalog
        .where(
          (MobilityExerciseModel ex) =>
              ex.category == MobilityCategory.liftingAccessory &&
              targetFocusAreas.contains(ex.focusArea),
        )
        .take(2)
        .toList();

    if (selectedAccessories.length < 2) {
      final Iterable<MobilityExerciseModel> remaining = catalog
          .where(
            (MobilityExerciseModel ex) =>
                ex.category == MobilityCategory.liftingAccessory &&
                !selectedAccessories.contains(ex),
          )
          .take(2 - selectedAccessories.length);
      selectedAccessories.addAll(remaining);
    }

    final List<MobilityExerciseModel> phase2Exercises = <MobilityExerciseModel>[
      ...selectedMobility,
      ...selectedAccessories,
    ];

    // Phase 3: Arms & Upper Hypertrophy
    final List<MobilityExerciseModel> phase3Exercises = catalog
        .where(
          (MobilityExerciseModel ex) => ex.focusArea == MobilityFocusArea.arms,
        )
        .toList();

    // Phase 4: Abs & Core Stability
    final List<MobilityExerciseModel> phase4Exercises = catalog
        .where(
          (MobilityExerciseModel ex) =>
              ex.focusArea == MobilityFocusArea.absCore,
        )
        .toList();

    // Phase 5: Grip Strength
    final List<MobilityExerciseModel> phase5Exercises = catalog
        .where(
          (MobilityExerciseModel ex) =>
              ex.focusArea == MobilityFocusArea.gripStrength,
        )
        .toList();

    final List<RecoveryPhaseGroup> phaseGroups = <RecoveryPhaseGroup>[
      RecoveryPhaseGroup(
        phaseNumber: 1,
        title: 'Phase 1: Zone 2 Cardio',
        subtitle: '15 Mins Aerobic Flush Pace',
        exercises: phase1Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 2,
        title: 'Phase 2: Mobility & Joint Health',
        subtitle: 'Tailored for balance gaps & fatigue',
        exercises: phase2Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 3,
        title: 'Phase 3: Arms & Upper Body',
        subtitle: 'Bicep & tricep tendon resilience',
        exercises: phase3Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 4,
        title: 'Phase 4: Abs & Core Stability',
        subtitle: 'Anti-extension & hollow body bracing',
        exercises: phase4Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 5,
        title: 'Phase 5: Grip Strength',
        subtitle: 'Crush grip & spine decompression',
        exercises: phase5Exercises,
      ),
    ];

    final List<MobilityExerciseModel> allExercises = phaseGroups
        .expand((RecoveryPhaseGroup g) => g.exercises)
        .toList();

    return GeneratedRecoveryRoutine(
      phaseGroups: phaseGroups,
      exercises: allExercises,
      diagnosticReasons: diagnosticReasons.toSet().toList(),
      totalEstimatedMinutes:
          35, // 15m cardio + 10m mobility + 10m arms/abs/grip
    );
  }
}
