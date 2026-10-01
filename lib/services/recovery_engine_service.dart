import 'package:oly/models/lift_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';

class RecoveryPhaseGroup {
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

class GeneratedRecoveryRoutine {
  new({
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
    TrainingTrack? trainingTrack,
    DayTemplate? dayTemplate,
    List<MobilityExerciseModel>? customCatalog,
  }) {
    final List<MobilityExerciseModel> catalog =
        customCatalog ?? MobilityExerciseModel.defaultExercises();

    // 1. If a specific DayTemplate with phases is supplied, adapt directly
    if (dayTemplate != null && dayTemplate.phases.isNotEmpty) {
      final List<RecoveryPhaseGroup> phaseGroups = <RecoveryPhaseGroup>[];
      int phaseNum = 1;

      for (final PhaseTemplate phase in dayTemplate.phases) {
        final List<MobilityExerciseModel> phaseExercises =
            <MobilityExerciseModel>[];

        for (final ExerciseTemplate ex in phase.exercises) {
          MobilityExerciseModel? match;
          final String cleanId =
              ex.liftId.toLowerCase().replaceFirst('bb_', '');
          final String exNameLower = ex.name.toLowerCase();

          for (final MobilityExerciseModel catEx in catalog) {
            final String catId = catEx.id.toLowerCase().replaceFirst('bb_', '');
            if (catId == cleanId ||
                catEx.id.toLowerCase() == ex.liftId.toLowerCase()) {
              match = catEx;
              break;
            }
          }
          if (match == null) {
            for (final MobilityExerciseModel catEx in catalog) {
              final String catNameLower = catEx.name.toLowerCase();
              if (catNameLower.contains(exNameLower) ||
                  exNameLower.contains(catNameLower)) {
                match = catEx;
                break;
              }
            }
          }

          if (match != null) {
            phaseExercises.add(match);
          } else {
            MobilityFocusArea focus = MobilityFocusArea.hipCapsule;
            if (exNameLower.contains('couch') ||
                exNameLower.contains('quad')) {
              focus = MobilityFocusArea.quadriceps;
            } else if (exNameLower.contains('pec') ||
                exNameLower.contains('chest') ||
                exNameLower.contains('doorway') ||
                exNameLower.contains('dislocate') ||
                exNameLower.contains('face pull')) {
              focus = MobilityFocusArea.thoracicSpine;
            } else if (exNameLower.contains('elephant') ||
                exNameLower.contains('jefferson') ||
                exNameLower.contains('hamstring') ||
                exNameLower.contains('spine')) {
              focus = MobilityFocusArea.posteriorChain;
            } else if (exNameLower.contains('walk') ||
                exNameLower.contains('cardio') ||
                exNameLower.contains('breath')) {
              focus = MobilityFocusArea.cardio;
            } else if (exNameLower.contains('wrist') ||
                exNameLower.contains('pull-up') ||
                exNameLower.contains('arm') ||
                exNameLower.contains('elbow')) {
              focus = MobilityFocusArea.arms;
            }

            final String videoUrl =
                'https://www.youtube.com/results?search_query=${Uri.encodeComponent(ex.name)}';

            phaseExercises.add(
              MobilityExerciseModel(
                id: ex.liftId,
                name: ex.name,
                focusArea: focus,
                category: MobilityCategory.mobilityDrill,
                description: ex.notes ?? '${ex.name} - ${ex.setScheme}',
                cues: ex.notes != null
                    ? <String>[
                        ex.notes!,
                        'Perform under strict control with deep diaphragmatic breathing.',
                      ]
                    : <String>[
                        'Perform with controlled cadence and deep breathing.',
                      ],
                durationSeconds: exNameLower.contains('walk')
                    ? 1500
                    : (exNameLower.contains('breath') ? 600 : 90),
                videoUrl: videoUrl,
              ),
            );
          }
        }

        phaseGroups.add(
          RecoveryPhaseGroup(
            phaseNumber: phaseNum++,
            title: phase.name,
            subtitle: dayTemplate.title,
            exercises: phaseExercises,
          ),
        );
      }

      final List<MobilityExerciseModel> allExercises =
          phaseGroups.expand((g) => g.exercises).toList();

      final List<String> reasons = <String>[
        '${dayTemplate.title}: Tailored active recovery and fascial flossing.',
        if (dayTemplate.subtitle.isNotEmpty) dayTemplate.subtitle,
      ];

      return GeneratedRecoveryRoutine(
        phaseGroups: phaseGroups,
        exercises: allExercises,
        diagnosticReasons: reasons,
        totalEstimatedMinutes: 30,
      );
    }

    // 2. Bodybuilding Track Fallback (if no specific dayTemplate provided)
    if (trainingTrack == TrainingTrack.bodybuilding) {
      final List<MobilityExerciseModel> p1 = catalog
          .where((e) => e.id == 'walking')
          .toList();
      final List<MobilityExerciseModel> p2 = catalog
          .where((e) => e.id == 'elephant_walk' || e.id == 'couch_stretch')
          .toList();
      final List<MobilityExerciseModel> p3 = catalog
          .where((e) =>
              e.id == 'jefferson_curl' ||
              e.id == 'dumbbell_wrist_curls' ||
              e.id == 'pullup_isometric_hold')
          .toList();
      final List<MobilityExerciseModel> p4 = catalog
          .where((e) => e.id == 'barbell_dead_hang' || e.id == 'breathwork')
          .toList();

      final List<RecoveryPhaseGroup> bbGroups = <RecoveryPhaseGroup>[
        RecoveryPhaseGroup(
          phaseNumber: 1,
          title: 'Phase 1: Low-Impact Aerobic Flush',
          subtitle: 'Restorative Walk / Incline Treadmill (Zone 1)',
          exercises: p1,
        ),
        RecoveryPhaseGroup(
          phaseNumber: 2,
          title: 'Phase 2: Soft-Tissue & Fascial Flossing',
          subtitle: 'Elephant Walks & Couch Stretch for Hip/Hamstring Length',
          exercises: p2,
        ),
        RecoveryPhaseGroup(
          phaseNumber: 3,
          title: 'Phase 3: Joint Armor & Tendon Remodeling',
          subtitle: 'Jefferson Curls, Forearm Armor & Pull-Up Isometric Hold',
          exercises: p3,
        ),
        RecoveryPhaseGroup(
          phaseNumber: 4,
          title: 'Phase 4: Passive Decompression & Down-Regulation',
          subtitle: 'Passive Bar Hangs & Wim Hof Breathwork Reset',
          exercises: p4,
        ),
      ];

      return GeneratedRecoveryRoutine(
        phaseGroups: bbGroups,
        exercises: bbGroups.expand((g) => g.exercises).toList(),
        diagnosticReasons: <String>[
          'Bodybuilding Hypertrophy Recovery: Soft-tissue flossing, tendon remodeling, and spinal decompression for Trainer Winny system.',
        ],
        totalEstimatedMinutes: 35,
      );
    }

    final Set<MobilityFocusArea> targetFocusAreas = <MobilityFocusArea>{};
    final List<String> diagnosticReasons = <String>[];

    // 3. Inspect Ratio Balance Chart Gaps (Olympic Lifting track default)
    final List<LiftRatioAnalysis> underdeveloped = ratioAnalyses
        .where((a) => a.status == 'Underdeveloped')
        .toList();

    for (final LiftRatioAnalysis analysis in underdeveloped) {
      switch (analysis.lift.category) {
        case LiftCategory.overhead:
          targetFocusAreas.add(MobilityFocusArea.thoracicSpine);
          targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
          diagnosticReasons.add(
            'Ratio Gap: ${analysis.lift.name} ratio (${analysis.actualRatio.toStringAsFixed(2)}) is underdeveloped vs target (${analysis.targetRatio.toStringAsFixed(2)}).',
          );

        case LiftCategory.squat:
          targetFocusAreas.add(MobilityFocusArea.hipCapsule);
          targetFocusAreas.add(MobilityFocusArea.ankleDorsiflexion);
          targetFocusAreas.add(MobilityFocusArea.quadriceps);
          diagnosticReasons.add(
            'Ratio Gap: ${analysis.lift.name} is underdeveloped. Targeting deep receiving squat mechanics.',
          );

        case LiftCategory.pull:
          targetFocusAreas.add(MobilityFocusArea.posteriorChain);
          diagnosticReasons.add(
            'Ratio Gap: Pulling power in ${analysis.lift.name} needs posterior chain balance.',
          );

        case LiftCategory.snatch:
        case LiftCategory.cleanAndJerk:
          targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
          targetFocusAreas.add(MobilityFocusArea.thoracicSpine);
          diagnosticReasons.add(
            'Ratio Gap: ${analysis.lift.name} performance targeted with overhead position drills.',
          );

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
            case 'Hips':
            case 'Knees':
              targetFocusAreas.add(MobilityFocusArea.hipCapsule);
              targetFocusAreas.add(MobilityFocusArea.ankleDorsiflexion);
              targetFocusAreas.add(MobilityFocusArea.quadriceps);
              diagnosticReasons.add(
                'Athlete Feedback: Lower body joint strain reported in last check-in.',
              );
            case 'Lower Back':
              targetFocusAreas.add(MobilityFocusArea.posteriorChain);
              diagnosticReasons.add(
                'Athlete Feedback: Posterior chain strain reported in last check-in.',
              );
            case 'Wrists':
              targetFocusAreas.add(MobilityFocusArea.shoulderOverhead);
              diagnosticReasons.add(
                'Athlete Feedback: Wrist & front rack tension targeted.',
              );
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

    // --- BUILD THE 4 PHASES ---

    // Phase 1: Kettlebell Mile Loaded Carry
    final List<MobilityExerciseModel> phase1Exercises = <MobilityExerciseModel>[
      ...catalog.where((ex) => ex.id == 'kettlebell_mile'),
    ];
    if (phase1Exercises.isEmpty) {
      phase1Exercises.addAll(
        catalog.where(
          (ex) => ex.focusArea == MobilityFocusArea.cardio,
        ),
      );
    }

    // Phase 2: Core & Posterior Chain Strength (Cable Crunches, Dragon Flags & GHD Back Extensions)
    final List<MobilityExerciseModel> coreOrdered = <MobilityExerciseModel>[
      ...catalog.where((ex) => ex.id == 'cable_crunches'),
      ...catalog.where((ex) => ex.id == 'dragon_flags'),
      ...catalog.where((ex) => ex.id == 'ghd_back_extensions'),
    ];
    if (coreOrdered.isEmpty) {
      coreOrdered.addAll(
        catalog.where((ex) => ex.focusArea == MobilityFocusArea.absCore),
      );
    }
    final List<MobilityExerciseModel> phase2Exercises = coreOrdered;

    // Phase 3: Hypertrophy & Tendon Resilience (Biceps, Triceps & Seated Leg Extensions)
    final List<MobilityExerciseModel> armsOrdered = <MobilityExerciseModel>[
      ...catalog.where((ex) => ex.id == 'db_bicep_curls'),
      ...catalog.where((ex) => ex.id == 'overhead_tricep_ext'),
      ...catalog.where((ex) => ex.id == 'seated_leg_extensions'),
    ];
    if (armsOrdered.isEmpty) {
      armsOrdered.addAll(
        catalog.where((ex) => ex.focusArea == MobilityFocusArea.arms),
      );
    }
    final List<MobilityExerciseModel> phase3Exercises = armsOrdered;

    // Phase 4: Dynamic Mobility & Weak-Point Accessories
    final List<MobilityExerciseModel> selectedMobility = catalog
        .where(
          (ex) =>
              ex.category == MobilityCategory.mobilityDrill &&
              targetFocusAreas.contains(ex.focusArea),
        )
        .take(3)
        .toList();

    if (selectedMobility.length < 3) {
      final Iterable<MobilityExerciseModel> remaining = catalog
          .where(
            (ex) =>
                ex.category == MobilityCategory.mobilityDrill &&
                !selectedMobility.contains(ex),
          )
          .take(3 - selectedMobility.length);
      selectedMobility.addAll(remaining);
    }

    final List<MobilityExerciseModel> selectedAccessories = catalog
        .where(
          (ex) =>
              ex.category == MobilityCategory.liftingAccessory &&
              targetFocusAreas.contains(ex.focusArea),
        )
        .take(2)
        .toList();

    if (selectedAccessories.length < 2) {
      final Iterable<MobilityExerciseModel> remaining = catalog
          .where(
            (ex) =>
                ex.category == MobilityCategory.liftingAccessory &&
                !selectedAccessories.contains(ex),
          )
          .take(2 - selectedAccessories.length);
      selectedAccessories.addAll(remaining);
    }

    final List<MobilityExerciseModel> phase4Exercises = <MobilityExerciseModel>[
      ...selectedMobility,
      ...selectedAccessories,
    ];

    final List<RecoveryPhaseGroup> phaseGroups = <RecoveryPhaseGroup>[
      RecoveryPhaseGroup(
        phaseNumber: 1,
        title: 'Phase 1: Kettlebell Mile Conditioning',
        subtitle: '1.0 Mile @ 10%->30% BW (<20m goal)',
        exercises: phase1Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 2,
        title: 'Phase 2: Core & Posterior Chain Strength',
        subtitle: 'Cable Crunches (3x8), Dragon Flags (3x5), GHD Extensions (3x12)',
        exercises: phase2Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 3,
        title: 'Phase 3: Hypertrophy & Tendon Resilience',
        subtitle: 'Biceps (3x10), Triceps (3x10), Leg Extensions (3x12)',
        exercises: phase3Exercises,
      ),
      RecoveryPhaseGroup(
        phaseNumber: 4,
        title: 'Phase 4: Mobility & Joint Health',
        subtitle: 'Tailored for balance gaps & fatigue',
        exercises: phase4Exercises,
      ),
    ];

    final List<MobilityExerciseModel> allExercises = phaseGroups
        .expand((g) => g.exercises)
        .toList();

    return GeneratedRecoveryRoutine(
      phaseGroups: phaseGroups,
      exercises: allExercises,
      diagnosticReasons: diagnosticReasons.toSet().toList(),
      totalEstimatedMinutes:
          40, // 20m KB mile + 10m core/arms + 10m mobility
    );
  }
}
