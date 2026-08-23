import '../models/lift_model.dart';
import '../models/mobility_exercise_model.dart';
import '../models/workout_session.dart';
import '../providers/lift_provider.dart';

class GeneratedRecoveryRoutine {
  final List<MobilityExerciseModel> exercises;
  final List<String> diagnosticReasons;
  final int totalEstimatedMinutes;

  GeneratedRecoveryRoutine({
    required this.exercises,
    required this.diagnosticReasons,
    required this.totalEstimatedMinutes,
  });
}

class RecoveryEngineService {
  static GeneratedRecoveryRoutine generateRoutine({
    required List<LiftRatioAnalysis> ratioAnalyses,
    required WorkoutSession? lastSession,
    List<MobilityExerciseModel>? customCatalog,
  }) {
    final catalog = customCatalog ?? MobilityExerciseModel.defaultExercises();
    final targetFocusAreas = <MobilityFocusArea>{};
    final diagnosticReasons = <String>[];

    // 1. Inspect Ratio Balance Chart Gaps
    final underdeveloped = ratioAnalyses.where((a) => a.status == 'Underdeveloped').toList();

    for (var analysis in underdeveloped) {
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

      for (var log in lastSession.logs) {
        final name = log.exerciseName.toLowerCase();
        if (name.contains('squat')) hadSquats = true;
        if (name.contains('snatch') || name.contains('jerk') || name.contains('press')) hadOverhead = true;
        if (name.contains('pull') || name.contains('deadlift') || name.contains('rdl')) hadPulls = true;
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
      targetFocusAreas.addAll([
        MobilityFocusArea.thoracicSpine,
        MobilityFocusArea.hipCapsule,
        MobilityFocusArea.ankleDorsiflexion,
      ]);
      diagnosticReasons.add(
        'Baseline Weightlifting Maintenance: Essential thoracic, hip, and ankle tune-up.',
      );
    }

    // 3. Select 3 Mobility Drills and 2 Lifting Accessories matching targetFocusAreas
    final selectedMobility = catalog
        .where((ex) =>
            ex.category == MobilityCategory.mobilityDrill &&
            targetFocusAreas.contains(ex.focusArea))
        .take(3)
        .toList();

    // Fallback if not enough matching mobility drills
    if (selectedMobility.length < 3) {
      final remaining = catalog
          .where((ex) =>
              ex.category == MobilityCategory.mobilityDrill &&
              !selectedMobility.contains(ex))
          .take(3 - selectedMobility.length);
      selectedMobility.addAll(remaining);
    }

    final selectedAccessories = catalog
        .where((ex) =>
            ex.category == MobilityCategory.liftingAccessory &&
            targetFocusAreas.contains(ex.focusArea))
        .take(2)
        .toList();

    // Fallback if not enough matching accessories
    if (selectedAccessories.length < 2) {
      final remaining = catalog
          .where((ex) =>
              ex.category == MobilityCategory.liftingAccessory &&
              !selectedAccessories.contains(ex))
          .take(2 - selectedAccessories.length);
      selectedAccessories.addAll(remaining);
    }

    final finalExercises = [...selectedMobility, ...selectedAccessories];

    // Estimate total time (mobility duration + 3 sets * 45s per accessory set)
    int totalSecs = 0;
    for (var ex in finalExercises) {
      if (ex.category == MobilityCategory.mobilityDrill) {
        totalSecs += ex.durationSeconds;
      } else {
        totalSecs += (ex.defaultSets * 45);
      }
    }
    final estMinutes = (totalSecs / 60).ceil();

    return GeneratedRecoveryRoutine(
      exercises: finalExercises,
      diagnosticReasons: diagnosticReasons.toSet().toList(), // Remove duplicates
      totalEstimatedMinutes: estMinutes > 0 ? estMinutes : 12,
    );
  }
}
