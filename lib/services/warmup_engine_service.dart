import '../models/mobility_exercise_model.dart';
import '../models/program_model.dart';

class WarmupPhaseGroup {
  final int phaseNumber;
  final String title;
  final String subtitle;
  final List<MobilityExerciseModel> exercises;

  WarmupPhaseGroup({
    required this.phaseNumber,
    required this.title,
    required this.subtitle,
    required this.exercises,
  });
}

class GeneratedWarmupRoutine {
  final String workoutTitle;
  final List<WarmupPhaseGroup> phaseGroups;
  final List<MobilityExerciseModel> exercises;
  final List<String> diagnosticReasons;
  final int totalEstimatedMinutes;

  GeneratedWarmupRoutine({
    required this.workoutTitle,
    required this.phaseGroups,
    required this.exercises,
    required this.diagnosticReasons,
    required this.totalEstimatedMinutes,
  });
}

class WarmupEngineService {
  static GeneratedWarmupRoutine generateWarmup({
    required DayTemplate? dayTemplate,
    List<MobilityExerciseModel>? customCatalog,
  }) {
    final catalog = customCatalog ?? MobilityExerciseModel.defaultExercises();
    final diagnosticReasons = <String>[];
    final title = dayTemplate?.title ?? 'Olympic Weightlifting Session';

    // 1. Inspect Scheduled Exercises for Today
    bool hasSnatch = false;
    bool hasCleanJerk = false;
    bool hasSquat = false;

    if (dayTemplate != null) {
      for (var phase in dayTemplate.phases) {
        for (var ex in phase.exercises) {
          final name = ex.name.toLowerCase();
          if (name.contains('snatch')) hasSnatch = true;
          if (name.contains('clean') || name.contains('jerk')) hasCleanJerk = true;
          if (name.contains('squat')) hasSquat = true;
        }
      }
    }

    // Default if no specific lifts found
    if (!hasSnatch && !hasCleanJerk && !hasSquat) {
      hasSnatch = true;
      hasCleanJerk = true;
    }

    // --- PHASE 1: CARDIO OPENER ---
    final phase1Exercises = catalog.where((ex) => ex.id == 'zone2_cardio_row').toList();

    // --- PHASE 2: FOAM ROLLING ---
    final phase2Exercises = catalog.where((ex) => ex.category == MobilityCategory.foamRolling).toList();

    // --- PHASE 3: JOINT MOBILIZATION & DROMS ---
    final phase3Exercises = catalog.where((ex) =>
        ex.id == 'wrist_elbow_droms' ||
        ex.id == 'banded_shoulder_dislocates' ||
        ex.id == 'hip_90_90_switches' ||
        ex.id == 'banded_ankle_distraction').toList();

    // --- PHASE 4: BARBELL PREP ---
    final phase4Exercises = <MobilityExerciseModel>[];

    if (hasSnatch) {
      final snatchPrep = catalog.where((ex) => ex.focusArea == MobilityFocusArea.barbellSnatch).toList();
      phase4Exercises.addAll(snatchPrep);
      diagnosticReasons.add('Snatch Specific Prep: Burgener complex & Sotts Press for overhead stability.');
    }

    if (hasCleanJerk) {
      final cjPrep = catalog.where((ex) => ex.focusArea == MobilityFocusArea.barbellCleanJerk).toList();
      phase4Exercises.addAll(cjPrep);
      diagnosticReasons.add('Clean & Jerk Prep: Front rack delivery & Jerk dip-and-drive verticality.');
    }

    if (hasSquat && !hasSnatch && !hasCleanJerk) {
      final squatPrep = catalog.where((ex) => ex.focusArea == MobilityFocusArea.barbellSquat).toList();
      phase4Exercises.addAll(squatPrep);
      diagnosticReasons.add('Squat Specific Prep: Paused empty bar squats to prime hip adductors.');
    }

    final phaseGroups = [
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
        subtitle: 'Wrists, Ankles, Hips & PVC Pass-Throughs',
        exercises: phase3Exercises,
      ),
      WarmupPhaseGroup(
        phaseNumber: 4,
        title: 'Phase 4: Barbell Warm-Up',
        subtitle: 'Tailored for today\'s primary lifts',
        exercises: phase4Exercises,
      ),
    ];

    final allExercises = phaseGroups.expand((g) => g.exercises).toList();

    return GeneratedWarmupRoutine(
      workoutTitle: title,
      phaseGroups: phaseGroups,
      exercises: allExercises,
      diagnosticReasons: diagnosticReasons,
      totalEstimatedMinutes: 12,
    );
  }
}
