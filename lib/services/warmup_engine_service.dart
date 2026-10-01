import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';

class WarmupPhaseGroup {
  new({
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

class GeneratedWarmupRoutine {
  new({
    required this.workoutTitle,
    required this.phaseGroups,
    required this.exercises,
    required this.diagnosticReasons,
    required this.totalEstimatedMinutes,
  });
  final String workoutTitle;
  final List<WarmupPhaseGroup> phaseGroups;
  final List<MobilityExerciseModel> exercises;
  final List<String> diagnosticReasons;
  final int totalEstimatedMinutes;
}

class WarmupEngineService {
  static GeneratedWarmupRoutine generateWarmup({
    required DayTemplate? dayTemplate,
    List<MobilityExerciseModel>? customCatalog,
  }) {
    final List<MobilityExerciseModel> catalog =
        customCatalog ?? MobilityExerciseModel.defaultExercises();
    final List<String> diagnosticReasons = <String>[];
    final String title = dayTemplate?.title ?? 'Olympic Weightlifting Session';

    // 1. Inspect Scheduled Exercises for Today
    final bool isActiveRecovery = dayTemplate?.isActiveRecovery == true;
    bool hasSnatch = false;
    bool hasCleanJerk = false;
    bool hasSquat = false;
    bool hasBenchPress = false;
    bool hasPullRow = false;

    if (dayTemplate != null) {
      for (final PhaseTemplate phase in dayTemplate.phases) {
        for (final ExerciseTemplate ex in phase.exercises) {
          final String name = ex.name.toLowerCase();
          if (name.contains('snatch')) {
            hasSnatch = true;
          }
          if (name.contains('clean') || name.contains('jerk')) {
            hasCleanJerk = true;
          }
          if (name.contains('squat') ||
              name.contains('leg extension') ||
              name.contains('lunge') ||
              name.contains('split squat')) {
            hasSquat = true;
          }
          if (name.contains('bench') ||
              name.contains('press') ||
              name.contains('push')) {
            hasBenchPress = true;
          }
          if (name.contains('row') ||
              name.contains('pulldown') ||
              name.contains('pull-up') ||
              name.contains('pull')) {
            hasPullRow = true;
          }
        }
      }
    }

    // Default if no specific lifts found and NOT active recovery
    if (!isActiveRecovery &&
        !hasSnatch &&
        !hasCleanJerk &&
        !hasSquat &&
        !hasBenchPress &&
        !hasPullRow) {
      hasSnatch = true;
      hasCleanJerk = true;
    }

    // --- PHASE 1: CARDIO OPENER ---
    final List<MobilityExerciseModel> phase1Exercises = catalog
        .where((ex) => ex.id == 'zone2_cardio_row')
        .toList();

    // --- PHASE 2: FOAM ROLLING ---
    final List<MobilityExerciseModel> phase2Exercises = catalog
        .where(
          (ex) =>
              ex.category == MobilityCategory.foamRolling,
        )
        .toList();

    // --- PHASE 3: JOINT MOBILIZATION & DROMS ---
    final List<MobilityExerciseModel> phase3Exercises = catalog
        .where(
          (ex) =>
              ex.id == 'hip_90_90_switches' ||
              ex.id == 'banded_ankle_distraction',
        )
        .toList();

    // --- PHASE 4: MOVEMENT PREP / BARBELL SPECIFIC ---
    final List<MobilityExerciseModel> phase4Exercises =
        <MobilityExerciseModel>[];
    String phase4Title = 'Phase 4: Barbell Warm-Up';
    String phase4Subtitle = "Tailored for today's primary lifts";

    if (isActiveRecovery) {
      phase4Title = 'Phase 4: Restorative Joint & Mobility Flossing';
      phase4Subtitle = 'Deep tissue flossing and down-regulation';
      final List<MobilityExerciseModel> recoveryPrep = catalog
          .where((ex) =>
              ex.id == 'couch_stretch' ||
              ex.id == 'elephant_walk' ||
              ex.id == 'doorway_pec_stretch' ||
              ex.id == 'deep_squat_pry')
          .take(3)
          .toList();
      phase4Exercises.addAll(recoveryPrep);
      diagnosticReasons.add(
        'Active Recovery Prep: Gentle joint flossing and mobility without barbell load.',
      );
    } else {
      if (hasSnatch) {
        final List<MobilityExerciseModel> snatchPrep = catalog
            .where(
              (ex) =>
                  ex.focusArea == MobilityFocusArea.barbellSnatch,
            )
            .toList();
        phase4Exercises.addAll(snatchPrep);
        diagnosticReasons.add(
          'Snatch Specific Prep: Burgener complex & Sotts Press for overhead stability.',
        );
      }

      if (hasCleanJerk) {
        final List<MobilityExerciseModel> cjPrep = catalog
            .where(
              (ex) =>
                  ex.focusArea == MobilityFocusArea.barbellCleanJerk,
            )
            .toList();
        phase4Exercises.addAll(cjPrep);
        diagnosticReasons.add(
          'Clean & Jerk Prep: Front rack delivery & Jerk dip-and-drive verticality.',
        );
      }

      if (hasSquat && !hasSnatch && !hasCleanJerk) {
        final List<MobilityExerciseModel> squatPrep = catalog
            .where(
              (ex) =>
                  ex.focusArea == MobilityFocusArea.barbellSquat,
            )
            .toList();
        phase4Exercises.addAll(squatPrep);
        diagnosticReasons.add(
          'Squat Specific Prep: Paused empty bar squats to prime hip adductors.',
        );
      }

      if (hasBenchPress &&
          !hasSnatch &&
          !hasCleanJerk &&
          phase4Exercises.isEmpty) {
        phase4Title = 'Phase 4: Upper Push & Shoulder Prep';
        phase4Subtitle = 'Anterior chest opening & rotator cuff stability';
        final List<MobilityExerciseModel> pressPrep = catalog
            .where((ex) =>
                ex.id == 'doorway_pec_stretch' ||
                ex.focusArea == MobilityFocusArea.shoulderOverhead)
            .take(2)
            .toList();
        phase4Exercises.addAll(pressPrep);
        diagnosticReasons.add(
          'Upper Body Push Prep: Anterior pec opening & rotator cuff activation.',
        );
      }

      if (hasPullRow &&
          !hasSnatch &&
          !hasCleanJerk &&
          phase4Exercises.isEmpty) {
        phase4Title = 'Phase 4: Upper Back & Lat Mobility';
        phase4Subtitle = 'Thoracic extension & lat activation';
        final List<MobilityExerciseModel> pullPrep = catalog
            .where((ex) =>
                ex.id == 'thoracic_foam_roll' ||
                ex.focusArea == MobilityFocusArea.thoracicSpine)
            .take(2)
            .toList();
        phase4Exercises.addAll(pullPrep);
        diagnosticReasons.add(
          'Upper Body Pull Prep: Thoracic extension & lat activation.',
        );
      }
    }

    final List<WarmupPhaseGroup> phaseGroups = <WarmupPhaseGroup>[
      WarmupPhaseGroup(
        phaseNumber: 1,
        title: 'Phase 1: Cardio Opener',
        subtitle: '3-5 Mins Aerobic Heart Rate Pulse',
        exercises: phase1Exercises,
      ),
      WarmupPhaseGroup(
        phaseNumber: 2,
        title: 'Phase 2: Foam Rolling',
        subtitle: 'Thoracic Spine, Lats & Quads Release',
        exercises: phase2Exercises,
      ),
      WarmupPhaseGroup(
        phaseNumber: 3,
        title: 'Phase 3: Joint Mobilization',
        subtitle: 'Hips & Ankle Distraction Flow',
        exercises: phase3Exercises,
      ),
      WarmupPhaseGroup(
        phaseNumber: 4,
        title: phase4Title,
        subtitle: phase4Subtitle,
        exercises: phase4Exercises,
      ),
    ];

    final List<MobilityExerciseModel> allExercises = phaseGroups
        .expand((g) => g.exercises)
        .toList();

    return GeneratedWarmupRoutine(
      workoutTitle: title,
      phaseGroups: phaseGroups,
      exercises: allExercises,
      diagnosticReasons: diagnosticReasons,
      totalEstimatedMinutes: 12,
    );
  }
}
