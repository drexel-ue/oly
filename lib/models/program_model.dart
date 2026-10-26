enum TrainingTrack {
  olympic,
  mobility,
  bodybuilding,
  atgStandards,
  emomEight,
}

class ExerciseTemplate {
  new({
    required this.name,
    required this.liftId,
    required this.setScheme,
    this.weekPercentages,
    this.anchorLiftId,
    this.fixedPercentage,
    this.fixedWeightKg,
    this.weeklyWeightIncrementKg,
    this.bodyweightPercentage,
    this.notes,
  });

  factory fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      name: json['name'] as String,
      liftId: json['liftId'] as String,
      setScheme: json['setScheme'] as String,
      weekPercentages: (json['weekPercentages'] as Map<String, dynamic>?)?.map(
        (k, dynamic v) => MapEntry<int, double>(int.parse(k), (v as num).toDouble()),
      ),
      anchorLiftId: json['anchorLiftId'] as String?,
      fixedPercentage: (json['fixedPercentage'] as num?)?.toDouble(),
      fixedWeightKg: (json['fixedWeightKg'] as num?)?.toDouble(),
      weeklyWeightIncrementKg: (json['weeklyWeightIncrementKg'] as num?)
          ?.toDouble(),
      bodyweightPercentage: (json['bodyweightPercentage'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
  final String name;
  final String liftId; // e.g. 'snatch', 'power_snatch', 'back_squat'
  final String setScheme; // e.g. '4 Sets of 2 Reps'
  final Map<int, double>? weekPercentages; // Week number (1..4) -> % of 1RM (e.g. {1: 65, 2: 70, 3: 75, 4: 70})
  final String? anchorLiftId; // Override reference 1RM (e.g. 'clean_and_jerk' for Front Squat)
  final double?
  fixedPercentage; // Fixed percentage for all weeks (e.g. 90% for Snatch Pull)
  final double?
  fixedWeightKg; // Explicit fixed weight (e.g. 0.0 for bodyweight, 20.0 for light bar)
  final double?
  weeklyWeightIncrementKg; // Weekly progressive load (e.g. 2.5kg / ~5-10lbs)
  final double?
  bodyweightPercentage; // % of athlete bodyweight (e.g. 50% for ATG Split Squat, 25% for Jefferson Curl)
  final String? notes;

  // Calculate suggested working weight for a specific week given current 1RMs map and athlete bodyweight in kg
  double calculateTargetWeight({
    required int week,
    required Map<String, double> currentMaxes,
    double? athleteBodyweightKg,
  }) {
    if (fixedWeightKg != null) {
      return fixedWeightKg!;
    }

    if (bodyweightPercentage != null) {
      // Dynamic bodyweight calculation from BodyCompProvider
      final double bw = (athleteBodyweightKg != null && athleteBodyweightKg > 0)
          ? athleteBodyweightKg
          : 85.0; // Fallback athlete bodyweight if unlogged
      final double calculated = bw * (bodyweightPercentage! / 100.0);
      return (calculated * 2).round() / 2.0; // Round to nearest 0.5 kg
    }

    final String refLiftId = anchorLiftId ?? liftId;
    final double base1RM = currentMaxes[refLiftId] ?? 100.0;

    if (weekPercentages != null && weekPercentages!.containsKey(week)) {
      final double pct = weekPercentages![week]!;
      return base1RM * (pct / 100.0);
    }

    if (fixedPercentage != null) {
      return base1RM * (fixedPercentage! / 100.0);
    }

    if (weeklyWeightIncrementKg != null) {
      // Base calculation on 60% baseline + weekly increment
      final double baseWeight = base1RM * 0.60;
      return baseWeight + ((week - 1) * weeklyWeightIncrementKg!);
    }

    return base1RM * 0.70; // Fallback default
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'liftId': liftId,
      'setScheme': setScheme,
      'weekPercentages': weekPercentages?.map(
        (k, v) => MapEntry<String, double>(k.toString(), v),
      ),
      'anchorLiftId': anchorLiftId,
      'fixedPercentage': fixedPercentage,
      'fixedWeightKg': fixedWeightKg,
      'weeklyWeightIncrementKg': weeklyWeightIncrementKg,
      'bodyweightPercentage': bodyweightPercentage,
      'notes': notes,
    };
  }
}

class PhaseTemplate {
  new({required this.name, required this.exercises});

  factory fromJson(Map<String, dynamic> json) {
    return PhaseTemplate(
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((dynamic e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final String name;
  final List<ExerciseTemplate> exercises;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class DayTemplate {
  new({
    required this.dayNumber,
    required this.title,
    required this.subtitle,
    required this.phases,
    this.isActiveRecovery = false,
    this.isFreeform = false,
  });

  factory fromJson(Map<String, dynamic> json) {
    return DayTemplate(
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      phases: (json['phases'] as List<dynamic>)
          .map((dynamic e) => PhaseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActiveRecovery: json['isActiveRecovery'] as bool? ?? false,
      isFreeform: json['isFreeform'] as bool? ?? false,
    );
  }
  final int dayNumber;
  final String title;
  final String subtitle;
  final List<PhaseTemplate> phases;
  final bool isActiveRecovery;
  final bool isFreeform;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dayNumber': dayNumber,
      'title': title,
      'subtitle': subtitle,
      'phases': phases.map((e) => e.toJson()).toList(),
      'isActiveRecovery': isActiveRecovery,
      'isFreeform': isFreeform,
    };
  }

  static List<PhaseTemplate> get recommendedActiveRecoveryPhases => <PhaseTemplate>[
        PhaseTemplate(
          name: 'Kettlebell Mile Conditioning',
          exercises: <ExerciseTemplate>[
            ExerciseTemplate(
              name: 'Kettlebell Mile (Loaded Carry)',
              liftId: 'kettlebell_mile',
              setScheme: '1.0 Mile @ 10% to 30% Bodyweight',
              notes:
                  'Record speed, incline %, and time. Progress weight when finished in under 20 mins.',
            ),
          ],
        ),
        PhaseTemplate(
          name: 'Core Stability & Anti-Extension',
          exercises: <ExerciseTemplate>[
            ExerciseTemplate(
              name: 'Cable Crunches',
              liftId: 'cable_crunches',
              setScheme: '3 Sets of 8 Reps',
              weeklyWeightIncrementKg: 2.5,
              notes: 'Kneeling rope cable stack; track weight.',
            ),
            ExerciseTemplate(
              name: 'Dragon Flags',
              liftId: 'dragon_flags',
              setScheme: '3 Sets of 5 Reps',
              notes: 'Full body tension, controlled eccentric descent.',
            ),
            ExerciseTemplate(
              name: 'GHD Machine Back Extensions',
              liftId: 'ghd_back_extensions',
              setScheme: '3 Sets of 12 Reps',
              weeklyWeightIncrementKg: 2.5,
              notes:
                  'Glute-Ham Developer hyperextensions; track added plate weight.',
            ),
          ],
        ),
        PhaseTemplate(
          name: 'Hypertrophy & Tendon Resilience',
          exercises: <ExerciseTemplate>[
            ExerciseTemplate(
              name: 'Incline Dumbbell Bicep Curls',
              liftId: 'incline_curls',
              setScheme: '3 Sets of 12 Reps',
              notes: 'Full biceps stretch; elbow flexor health.',
            ),
            ExerciseTemplate(
              name: 'Overhead Rope Tricep Extensions',
              liftId: 'rope_extensions',
              setScheme: '3 Sets of 15 Reps',
              notes: 'Long head tricep overhead lockouts.',
            ),
            ExerciseTemplate(
              name: 'Leg Extensions (VMO Isolation)',
              liftId: 'leg_extensions',
              setScheme: '3 Sets of 20 Reps',
              notes: 'High rep patellar tendon blood flow and knee health.',
            ),
          ],
        ),
      ];
}

class ProgramCycle {
  new({
    this.currentCycle = 1,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.activeTrack = TrainingTrack.mobility,
    List<String>? completedSessionIds,
    this.isEmomRestDay = false,
    this.emomRestDayDate,
  }) : completedSessionIds = completedSessionIds ?? <String>[];

  factory fromJson(Map<String, dynamic> json) {
    return ProgramCycle(
      currentCycle: json['currentCycle'] as int? ?? 1,
      currentWeek: json['currentWeek'] as int? ?? 1,
      currentDay: json['currentDay'] as int? ?? 1,
      activeTrack: json['activeTrack'] == 'olympic'
          ? TrainingTrack.olympic
          : (json['activeTrack'] == 'bodybuilding'
              ? TrainingTrack.bodybuilding
              : (json['activeTrack'] == 'atgStandards' || json['activeTrack'] == 'atg'
                  ? TrainingTrack.atgStandards
                  : (json['activeTrack'] == 'emomEight' || json['activeTrack'] == 'emom'
                      ? TrainingTrack.emomEight
                      : TrainingTrack.mobility))),
      completedSessionIds:
          (json['completedSessionIds'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
      isEmomRestDay: json['isEmomRestDay'] as bool? ?? false,
      emomRestDayDate: json['emomRestDayDate'] as String?,
    );
  }
  int currentCycle;
  int currentWeek; // 1..4 = training weeks, 5 = 1RM Retest Week
  int currentDay; // 1..4 (Olympic), 1..7 (Mobility/BB/ATG), 1..8 (EMOM 8)
  TrainingTrack activeTrack;
  List<String> completedSessionIds;
  bool isEmomRestDay;
  String? emomRestDayDate;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentCycle': currentCycle,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'activeTrack': activeTrack.name,
      'completedSessionIds': completedSessionIds,
      'isEmomRestDay': isEmomRestDay,
      'emomRestDayDate': emomRestDayDate,
    };
  }

  static List<DayTemplate> getMobilityProgram() {
    return <DayTemplate>[
      // Day 1 (Mon): Lower Hypertrophy + ATG Knee/Ankle
      DayTemplate(
        dayNumber: 1,
        title: 'Day 1: Lower Hypertrophy + ATG Knee/Ankle',
        subtitle: 'Slant Board, Tibialis Raises, Hip IR Squeeze, Pause Squats, ATG Split Squats, Couch Stretch',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Ankle & Knee Bulletproofing + Hip IR Primer',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Slant Board Calf Stretch',
                liftId: 'slant_board_calf_stretch',
                setScheme: '3 Sets of 60s Hold',
                fixedWeightKg: 0,
                notes: 'Drive knee forward over toes without heel lifting; expand dorsiflexion.',
              ),
              ExerciseTemplate(
                name: 'Tibialis Anterior Raises',
                liftId: 'tibialis_raise',
                setScheme: '3 Sets of 25 Reps',
                fixedWeightKg: 0,
                notes: 'Full dorsiflexion squeeze against wall or tib bar.',
              ),
              ExerciseTemplate(
                name: 'Banded Hip Internal Rotation',
                liftId: 'banded_hip_internal_rotation',
                setScheme: '2 Sets of 12 Reps',
                fixedWeightKg: 0,
                notes: 'Anchor band laterally to ankle; flare foot outward against resistance with 2s peak squeeze; primes deep squat capsule.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Deep Squat & VMO Hypertrophy',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Pause Back Squats (Dane Miller)',
                liftId: 'back_squat',
                setScheme: '4 Sets of 6 Reps',
                fixedPercentage: 65,
                anchorLiftId: 'back_squat',
                notes: '3-second isometric pause in deep hole. Sit between hips, tall chest.',
              ),
              ExerciseTemplate(
                name: 'ATG Split Squats (Ben Patrick)',
                liftId: 'atg_split_squat',
                setScheme: '4 Sets of 8 Reps',
                fixedWeightKg: 0,
                notes: 'Front hamstring covers calf completely; back leg straight with glute locked.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Hip Flexor Restoration',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '2 Sets of 90s Hold',
                fixedWeightKg: 0,
                notes: 'Shin flush to wall; squeeze glute to drive hip forward with tall spine.',
              ),
            ],
          ),
        ],
      ),

      // Day 2 (Tue): Upper Hypertrophy & Thoracic Mobility
      DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Upper Hypertrophy & Thoracic Mobility',
        subtitle: 'Miracle Grow, Trap-3 Raises, Seated External Rotation, Hammer Curls, Wrist Curls & Pull-Up Isos',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Overhead Lat & Triceps Hypertrophy',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Miracle Grow (Pullover into Tricep Ext)',
                liftId: 'miracle_grow',
                setScheme: '4 Sets of 12 Reps',
                fixedWeightKg: 20,
                notes: 'Full lat stretch behind head across bench; fire long head triceps to lockout.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Scapular Armor & Rotator Cuff',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Incline Trap-3 Raise',
                liftId: 'incline_trap_3_raise',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 5,
                notes: 'Prone on 45° bench, thumbs up at 45°; 2-second hold at peak.',
              ),
              ExerciseTemplate(
                name: 'Seated DB External Rotation',
                liftId: 'seated_db_external_rotation',
                setScheme: '3 Sets of 8 Reps',
                fixedWeightKg: 6,
                notes: 'Elbow on knee, 3s eccentric descent; strict infraspinatus isolation.',
              ),
            ],
          ),
          PhaseTemplate(
            name: "Phase 3 - Forearm Armor & Golfer's Elbow Rehab",
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Dumbbell Hammer Curls',
                liftId: 'hammer_curls',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 12,
                notes: 'Neutral grip targets brachialis & brachioradialis while offloading medial epicondyle.',
              ),
              ExerciseTemplate(
                name: 'Dumbbell Wrist Curls (Flexion & Extension)',
                liftId: 'dumbbell_wrist_curls',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 8,
                notes: 'Forearms rested on bench/knees; controlled flexor & extensor curls rebuild tendon integrity.',
              ),
              ExerciseTemplate(
                name: "Pull-Up Isometric Hold (Golfer's Elbow Iso)",
                liftId: 'pullup_isometric_hold',
                setScheme: '3 Sets of 30s Hold',
                fixedWeightKg: 0,
                notes: '90° elbow flexion or chin-over-bar hold; isometric loading stimulates analgesic tendon remodeling.',
              ),
            ],
          ),
        ],
      ),

      // Day 3 (Wed): Restorative Posterior Chain & Hip Capsule Flow
      DayTemplate(
        dayNumber: 3,
        title: 'Day 3: Posterior Chain & Hip Capsule Flow',
        subtitle: 'Elephant Walk, Jefferson Curls, Seated Good Mornings, 90/90 Switches, Rear-Leg IR Holds & Butterfly',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Spinal & Hamstring Decompression',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'ATG Elephant Walk',
                liftId: 'elephant_walk',
                setScheme: '2 Sets of 45 Reps',
                fixedWeightKg: 0,
                notes: 'Hands flat on floor or box; alternate knee extensions smoothly.',
              ),
              ExerciseTemplate(
                name: 'Jefferson Curls',
                liftId: 'jefferson_curl',
                setScheme: '4 Sets of 8 Reps',
                fixedWeightKg: 20,
                notes: 'Chin to chest, roll down bone-by-bone below toes with light load.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Loaded Adductor & Hip Hinge',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Seated Good Mornings',
                liftId: 'seated_good_morning',
                setScheme: '4 Sets of 10 Reps',
                fixedWeightKg: 20,
                notes: 'Wide straddle on bench, flat back, hinge abdomen down between knees.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Dedicated Capsule Separation Work',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: '90/90 Hip Switches & Rotations',
                liftId: 'hip_90_90_switch',
                setScheme: '4 Sets of 5 Reps',
                fixedWeightKg: 0,
                notes: 'Dedicated capsule work; open back knee first, 5s end-range hold per side.',
              ),
              ExerciseTemplate(
                name: '90/90 Rear-Leg Hip IR PAILs/RAILs',
                liftId: 'hip_90_90_internal_rotation',
                setScheme: '3 Sets of 60s Hold',
                fixedWeightKg: 0,
                notes: 'Torso rotated squarely toward rear knee; 60s passive stretch, 10s PAILs push, 5s active lift-off hold.',
              ),
              ExerciseTemplate(
                name: 'Seated Butterfly & PNF Adductor Stretch',
                liftId: 'seated_butterfly',
                setScheme: '3 Sets of 60s Hold',
                fixedWeightKg: 0,
                notes: 'Soles together, drive knees down, active 5s isometric groin contraction.',
              ),
            ],
          ),
        ],
      ),

      // Day 4 (Thu): Lower Body Depth Hypertrophy
      DayTemplate(
        dayNumber: 4,
        title: 'Day 4: Lower Body Depth Hypertrophy',
        subtitle: 'Curtsy Lunges, Seated Hip IR, Heel-Elevated Squats, Wall Couch Stretch',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Unilateral Hip Stability & Capsule Clearance',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Curtsy Lunges (Dane Miller)',
                liftId: 'curtsy_lunge',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 10,
                notes: 'Cross trailing leg behind; strengthens glute medius and hip stabilizers.',
              ),
              ExerciseTemplate(
                name: 'Banded Hip Internal Rotation',
                liftId: 'banded_hip_internal_rotation',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 0,
                notes: 'Anchor band laterally; flare ankle outward into deep IR against band tension; clears capsule before vertical squats.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Vertical Quad Hypertrophy',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Heel-Elevated Front / Goblet Squats',
                liftId: 'front_squat',
                setScheme: '4 Sets of 8 Reps',
                fixedPercentage: 55,
                anchorLiftId: 'clean_and_jerk',
                notes: 'Torso completely vertical, 2s bottom pause, constant quad tension.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Hip Extension Restorative Hold',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '2 Sets of 120s Hold',
                fixedWeightKg: 0,
                notes: 'Long restorative hold; squeeze glute to unlock anterior hip.',
              ),
            ],
          ),
        ],
      ),

      // Day 5 (Fri): Upper Hypertrophy & Scapular Armor
      DayTemplate(
        dayNumber: 5,
        title: 'Day 5: Upper Hypertrophy & Scapular Armor',
        subtitle: 'Overhead / Z-Press, Powell Raises, Dumbbell Pullovers, Hammer Curls & Pull-Up Isos',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Vertical Overhead Strength',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Overhead Press / Z-Press',
                liftId: 'strict_press',
                setScheme: '4 Sets of 8 Reps',
                fixedPercentage: 50,
                anchorLiftId: 'clean_and_jerk',
                notes: 'Press overhead from seated floor position; pure shoulder drive without leg bounce.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Rear Delt & Scapular Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Powell Raises',
                liftId: 'powell_raise',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 5,
                notes: 'Side-lying straight-arm raise to 90°; targets rear deltoid and mid-traps.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Thoracic Expansion & Lat Hypertrophy',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Dumbbell Pullovers',
                liftId: 'dumbbell_pullover',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 15,
                notes: 'Deep stretch across bench with ribcage expansion; keep lower back neutral.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Forearm Armor & Tendon Density',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Dumbbell Hammer Curls',
                liftId: 'hammer_curls',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 12,
                notes: 'Brachialis & forearm thickness; strict neutral grip.',
              ),
              ExerciseTemplate(
                name: 'Dumbbell Wrist Curls (Flexion & Extension)',
                liftId: 'dumbbell_wrist_curls',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 8,
                notes: 'Controlled wrist flexion and reverse extension curls.',
              ),
              ExerciseTemplate(
                name: "Pull-Up Isometric Hold (Golfer's Elbow Iso)",
                liftId: 'pullup_isometric_hold',
                setScheme: '3 Sets of 30s Hold',
                fixedWeightKg: 0,
                notes: 'Static 90° or top position hold for medial epicondyle tendon adaptation.',
              ),
            ],
          ),
        ],
      ),

      // Day 6 (Sat): Loaded Oly Mobility Flow
      DayTemplate(
        dayNumber: 6,
        title: 'Day 6: Loaded Oly Mobility Flow',
        subtitle: 'Close-Grip Snatch Balance, Loaded Cossack Squats, Deep Squat KB Pry',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Extreme Overhead Snatch Mobility',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Close-Grip Snatch Balance / OHS',
                liftId: 'close_grip_snatch',
                setScheme: '4 Sets of 5 Reps',
                fixedWeightKg: 20,
                notes: 'Clean or narrow grip; forces extreme thoracic extension and shoulder flexibility.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Multi-Planar Adductor Strength',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Loaded Cossack Squats',
                liftId: 'cossack_squat',
                setScheme: '3 Sets of 8 Reps',
                fixedWeightKg: 12,
                notes: 'Kettlebell held at chest; sink deep into lateral adductor stretch.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Bottom Position Isometric Stability',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Deep Squat Pry with Kettlebell',
                liftId: 'deep_squat_pry',
                setScheme: '3 Sets of 45s Hold',
                fixedWeightKg: 16,
                notes: 'Use elbows inside knees to pry hips open while maintaining upright posture.',
              ),
            ],
          ),
        ],
      ),

      // Day 7 (Sun): Active Restoration & Fasting
      DayTemplate(
        dayNumber: 7,
        title: 'Day 7: Active Restoration & Fasting',
        subtitle: 'Restorative Walking, Circadian Reset & Wim Hof Breathwork',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Restoration & Cellular Recovery',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Restorative Outdoor Walk',
                liftId: 'walking',
                setScheme: '1 Set of 30 Reps',
                fixedWeightKg: 0,
                notes: 'Gentle zone 1 aerobic recovery; nasal breathing.',
              ),
              ExerciseTemplate(
                name: 'Wim Hof Guided Breathwork',
                liftId: 'breathwork',
                setScheme: '3 Sets of 30 Reps',
                fixedWeightKg: 0,
                notes: 'Circadian and autonomic nervous system reset.',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<DayTemplate> getBodybuildingProgram() {
    return <DayTemplate>[
      // Day 1 (Mon): Upper A (Chest, Lats, Overhead Press, Arms & Forearm Armor)
      DayTemplate(
        dayNumber: 1,
        title: 'Day 1: Upper A (Heavy Horizontal, Shoulders, Forearms & Rotation)',
        subtitle:
            'Flat Bench Press, Lat Pulldown, Standing OHP, Barbell Curls, Cable Pushdowns, Wrist Curls, Landmine Rotations',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Chest & Lat Compound Synergy',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Barbell Flat Bench Press',
                liftId: 'bench_press',
                setScheme: '4 Sets of 8 Reps',
                fixedWeightKg: 80,
                notes:
                    'Plant feet, retract scapulae, lower with 2-3s control to lower sternum.',
              ),
              ExerciseTemplate(
                name: 'Wide-Grip Lat Pulldown',
                liftId: 'lat_pulldown',
                setScheme: '4 Sets of 10 Reps',
                fixedWeightKg: 65,
                notes:
                    'Depress scapula before pull; drive elbows straight to hip pockets for lat width.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Overhead Press & Direct Arms',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Standing Overhead Barbell Press',
                liftId: 'overhead_press',
                setScheme: '3 Sets of 8 Reps',
                fixedWeightKg: 50,
                notes:
                    'Strict vertical pressing path; brace glutes and core hard.',
              ),
              ExerciseTemplate(
                name: 'Standing Barbell Bicep Curl',
                liftId: 'barbell_curl',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 35,
                notes:
                    'Supinated grip loading both heads of biceps; strict form without swing.',
              ),
              ExerciseTemplate(
                name: 'Cable Triceps Pushdown',
                liftId: 'tricep_pushdown',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 30,
                notes:
                    'Pin elbows to ribs; full lateral head lockout contraction.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Forearm Armor & Rotational Power',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Barbell Wrist Curls (Flexion & Extension)',
                liftId: 'bb_barbell_wrist_curls',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 15,
                notes:
                    "Controlled wrist curls over bench; builds forearm flexor thickness and resolves golfer's elbow.",
              ),
              ExerciseTemplate(
                name: 'Landmine Rotations (Rainbows)',
                liftId: 'bb_landmine_rotations',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 15,
                notes:
                    'Pivot back hip and arc barbell across torso; explosive oblique rotation and rotary deceleration.',
              ),
            ],
          ),
        ],
      ),

      // Day 2 (Tue): Lower A - Front Squat Focus (Hip Primer, Front Squat, Hinge & Anti-Rotation)
      DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Lower A - Front Squat Focus (Primer, Front Squat, Hinge & Anti-Rotation)',
        subtitle:
            'Banded Hip Rotations, Front Squat, Romanian Deadlift, Leg Extension, Calf Raise, Pallof Press, Elephant Walks',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Hip Capsule Primer & Front Squat Quad Overload',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Banded Internal Hip Rotations',
                liftId: 'bb_banded_hip_rotations',
                setScheme: '2 Sets of 15 Reps',
                fixedWeightKg: 0,
                notes:
                    'Anchor band to rig at knee height; rotate femur internally to prime hip capsule.',
              ),
              ExerciseTemplate(
                name: 'Barbell Front Squat',
                liftId: 'front_squat',
                setScheme: '4 Sets of 8 Reps',
                fixedWeightKg: 85,
                notes:
                    'High elbows, upright torso, deep knee flexion, maximum quad isolation.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Posterior Hinge & Quad Isolation',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Romanian Deadlift (RDL)',
                liftId: 'romanian_deadlift',
                setScheme: '3 Sets of 8 Reps',
                fixedWeightKg: 90,
                notes:
                    'Push hips backward into deep hamstring stretch, soft knees, flat back.',
              ),
              ExerciseTemplate(
                name: 'Seated Leg Extension',
                liftId: 'leg_extensions',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 50,
                notes:
                    'Full rectus femoris lockout squeeze; pause for 1s at top.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Calves, Anti-Rotation & Dynamic Decompression',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Standing Calf Raise',
                liftId: 'calf_raises',
                setScheme: '4 Sets of 20 Reps',
                fixedWeightKg: 70,
                notes:
                    'Deep ankle dorsiflexion stretch, 2s pause at bottom and top squeeze.',
              ),
              ExerciseTemplate(
                name: 'Standing Cable Pallof Press',
                liftId: 'bb_pallof_press',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 15,
                notes:
                    'Perpendicular to cable; press straight out and hold 2s lockout to resist rotational shear.',
              ),
              ExerciseTemplate(
                name: 'Elephant Walks',
                liftId: 'bb_elephant_walks',
                setScheme: '2 Sets of 30 Reps',
                fixedWeightKg: 0,
                notes:
                    'Palms on floor or block; alternate knee lockouts to dynamically floss hamstrings and calves.',
              ),
            ],
          ),
        ],
      ),

      // Day 3 (Wed): Mid-Week Hypertrophy Restoration & Joint Armor
      DayTemplate(
        dayNumber: 3,
        title: 'Day 3: Mid-Week Hypertrophy Restoration & Joint Armor',
        subtitle:
            'Couch Stretch, Banded Hip Primer, Doorway Pec Opener, Forearm Armor & Restorative Walk',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Low-Stress Aerobic Flush & Circulation',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Restorative Walk / Incline Treadmill Flush',
                liftId: 'walking',
                setScheme: '1 Set of 25 Mins',
                fixedWeightKg: 0,
                notes:
                    'Low-intensity zone 1 walking to flush metabolites and deliver nutrient-rich blood flow to recovering muscle tissue.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Anterior Hip & Quad Length (Post-Squat)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Couch Stretch (Quad & Hip Flexor)',
                liftId: 'bb_couch_stretch',
                setScheme: '2 Sets of 90s Hold',
                fixedWeightKg: 0,
                notes:
                    'Shin flush to wall; restores hip extension and relieves patellar tendon strain from heavy squats and leg extensions.',
              ),
              ExerciseTemplate(
                name: 'Banded Internal Hip Rotations / 90/90 Flow',
                liftId: 'bb_banded_hip_rotations',
                setScheme: '2 Sets of 15 Reps per side',
                fixedWeightKg: 0,
                notes:
                    'Restores femoral head centering and internal rotation in hip capsule.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Chest, Scapular & Forearm Tendon Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Doorway Pec Stretch & Scapular Wall Slides',
                liftId: 'doorway_pec_stretch',
                setScheme: '3 Sets of 45s Stretch',
                fixedWeightKg: 0,
                notes:
                    'Relieves anterior shoulder capsule tightness and pec minor shortening after heavy benching.',
              ),
              ExerciseTemplate(
                name: 'Barbell Wrist Curls (Flexion & Extension)',
                liftId: 'bb_barbell_wrist_curls',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 15,
                notes:
                    "Resolves golfer's elbow / medial epicondylitis and strengthens forearm tendons after curls.",
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Autonomic Down-Regulation',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wim Hof Guided Breathwork',
                liftId: 'breathwork',
                setScheme: '3 Sets of 30 Breaths',
                fixedWeightKg: 0,
                notes:
                    'Down-regulates sympathetic fight-or-flight into parasympathetic anabolic recovery.',
              ),
            ],
          ),
        ],
      ),

      // Day 4 (Thu): Upper B (Incline Upper Chest, Mid-Back, 3D Delts & Arms)
      DayTemplate(
        dayNumber: 4,
        title: 'Day 4: Upper B (Incline Upper Chest, Mid-Back & Anti-Extension)',
        subtitle:
            'Incline DB Press, Chest-Supported Row, DB Lateral Raises, DB Hammer Curls, Overhead Triceps, Face Pulls, Ab Wheel',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Incline Chest & Horizontal Back',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Incline Dumbbell Bench Press',
                liftId: 'incline_dumbbell_press',
                setScheme: '4 Sets of 10 Reps',
                fixedWeightKg: 32,
                notes:
                    '30° to 45° bench angle targeting upper clavicular pectoralis.',
              ),
              ExerciseTemplate(
                name: 'Chest-Supported Row / Barbell Row',
                liftId: 'barbell_row',
                setScheme: '4 Sets of 10 Reps',
                fixedWeightKg: 60,
                notes:
                    'Horizontal pull targeting mid traps, rhomboids, and back thickness.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - 3D Delts & Long Head Arms',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Dumbbell Lateral Raises',
                liftId: 'lateral_raises',
                setScheme: '4 Sets of 15 Reps',
                fixedWeightKg: 12,
                notes:
                    'Lead with elbows, pinkies slightly elevated; 2s eccentric descent.',
              ),
              ExerciseTemplate(
                name: 'Neutral-Grip Dumbbell Hammer Curl',
                liftId: 'hammer_curls',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 16,
                notes:
                    'Neutral wrist orientation targeting brachialis and arm thickness.',
              ),
              ExerciseTemplate(
                name: 'Overhead Cable Triceps Extension',
                liftId: 'overhead_tricep_extension',
                setScheme: '3 Sets of 12 Reps',
                fixedWeightKg: 25,
                notes:
                    'Deep overhead stretch targeting long head of triceps; flare rope apart.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Rear Delts, Scapular Posture & Anti-Extension Core',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Cable Face Pulls / Reverse Pec Deck',
                liftId: 'face_pulls',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 25,
                notes:
                    'Pull toward eyes with external shoulder rotation; rear delt capping.',
              ),
              ExerciseTemplate(
                name: 'Ab Wheel Rollouts',
                liftId: 'bb_ab_wheel_rollout',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 0,
                notes:
                    'Kneel on pad, brace abs and tuck pelvis; roll forward slowly, resisting lumbar hyperextension.',
              ),
            ],
          ),
        ],
      ),

      // Day 5 (Fri): Lower B - Unilateral & Hinge Focus (Bulgarian Squat, Single-Leg RDL, Hip Thrust)
      DayTemplate(
        dayNumber: 5,
        title: 'Day 5: Lower B - Unilateral & Hinge Focus (Bulgarian Squat, Single-Leg RDL, Hip Thrust)',
        subtitle:
            'Bulgarian Split Squats, Free Single-Leg RDL, Barbell Hip Thrust, Seated Calf Raise, Jefferson Curls, Couch Stretch, Hanging Leg Raise',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Unilateral Knee Overload & Quad Stretch',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Bulgarian Split Squats (Rear-Foot Elevated)',
                liftId: 'bb_bulgarian_split_squat',
                setScheme: '3 Sets of 8 Reps per leg',
                fixedWeightKg: 18,
                notes:
                    'Rear foot on bench laces down; deep knee flexion, upright torso, full glute and quad stretch.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Posterior Chain & Peak Glute Overload',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Free Single-Leg Romanian Deadlift',
                liftId: 'bb_single_leg_rdl',
                setScheme: '3 Sets of 8 Reps per leg',
                fixedWeightKg: 16,
                notes:
                    'Rear leg suspended like a pendulum; hinge deep into working hamstring with square hips and level pelvis.',
              ),
              ExerciseTemplate(
                name: 'Barbell Hip Thrust',
                liftId: 'hip_thrust',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 110,
                notes:
                    'Tuck chin, drive through heels, 2s peak glute lockout squeeze.',
              ),
              ExerciseTemplate(
                name: 'Seated Machine Calf Raise',
                liftId: 'seated_calf_raise',
                setScheme: '4 Sets of 15 Reps',
                fixedWeightKg: 45,
                notes:
                    'Targets soleus muscle with 90° knee angle; slow 2s stretch.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Loaded Spinal Flexion, Hip Flexor Length & Core',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Jefferson Curls',
                liftId: 'bb_jefferson_curls',
                setScheme: '3 Sets of 8 Reps',
                fixedWeightKg: 20,
                notes:
                    'Stand on box; roll spine down vertebra by vertebra into deep hamstring stretch with barbell.',
              ),
              ExerciseTemplate(
                name: 'Couch Stretch (Quad & Hip Flexor)',
                liftId: 'bb_couch_stretch',
                setScheme: '2 Sets of 90s Hold',
                fixedWeightKg: 0,
                notes:
                    'Back shin flush to wall; squeeze glute to unlock anterior hip flexor and rectus femoris.',
              ),
              ExerciseTemplate(
                name: 'Hanging Knee / Leg Raise',
                liftId: 'hanging_leg_raise',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 0,
                notes:
                    'Posterior pelvic tilt to engage lower rectus abdominis.',
              ),
            ],
          ),
        ],
      ),

      // Day 6 (Sat): Hypertrophy Recovery, Tendon Armor & Fascial Flossing
      DayTemplate(
        dayNumber: 6,
        title: 'Day 6: Hypertrophy Recovery, Tendon Armor & Fascial Flossing',
        subtitle:
            'Elephant Walks, Jefferson Curls, Couch Stretch, Band Dislocates & Restorative Walk',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Low-Impact Aerobic Flush & Circulation',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Restorative Walk / Incline Treadmill Flush',
                liftId: 'walking',
                setScheme: '1 Set of 25 Mins',
                fixedWeightKg: 0,
                notes:
                    'Gentle zone 1 aerobic recovery, blood flow, and lymphatic drainage without joint impact.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Posterior Chain Decompression & Spine Flossing',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Elephant Walks (Hamstring & Fascial Flossing)',
                liftId: 'bb_elephant_walks',
                setScheme: '3 Sets of 30 Reps',
                fixedWeightKg: 0,
                notes:
                    'Dynamically flosses hamstrings, calves, and lumbar fascia after heavy squats and RDLs.',
              ),
              ExerciseTemplate(
                name: 'Jefferson Curls (Light Spinal Flexion)',
                liftId: 'bb_jefferson_curls',
                setScheme: '3 Sets of 8 Reps',
                fixedWeightKg: 15,
                notes:
                    'Light barbell articulation; rolls spine vertebra by vertebra to decompress intervertebral discs.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Shoulder Armor & Elbow Tendon Remodeling',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Cable Face Pulls / Band Pull-Aparts',
                liftId: 'face_pulls',
                setScheme: '3 Sets of 15 Reps',
                fixedWeightKg: 20,
                notes:
                    'Scapular retractors, rear deltoids, and rotator cuff reinforcement for pressing posture.',
              ),
              ExerciseTemplate(
                name: 'Pull-Up Isometric Hold (Elbow Tendon Armor)',
                liftId: 'pullup_isometric_hold',
                setScheme: '3 Sets of 25s Hold',
                fixedWeightKg: 0,
                notes:
                    'Static isometric hold at 90° elbow flexion; remodels tendon collagen and protects medial epicondyle.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Pelvic Settle & Hip Capsule Recovery',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Couch Stretch (Quad & Hip Flexor)',
                liftId: 'bb_couch_stretch',
                setScheme: '2 Sets of 90s Hold',
                fixedWeightKg: 0,
                notes:
                    'Restores anterior hip length after unilateral Bulgarian split squats and hip thrusts.',
              ),
              ExerciseTemplate(
                name: 'Deep Squat Pry with Hip Shift',
                liftId: 'deep_squat_pry',
                setScheme: '2 Sets of 45s Hold',
                fixedWeightKg: 12,
                notes:
                    'Use light kettlebell/elbows to open adductors and restore deep squat resting comfort.',
              ),
            ],
          ),
        ],
      ),

      // Day 7 (Sun): Full Systemic Reset, Decompression & Fasting
      DayTemplate(
        dayNumber: 7,
        title: 'Day 7: Full Systemic Reset, Decompression & Fasting',
        subtitle:
            'Passive Bar Hangs, Restorative Walk, 90/90 Hip Flow, Circadian Sun & Wim Hof Breathwork',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Restorative Circulation & Circadian Flow',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Restorative Outdoor Walk',
                liftId: 'walking',
                setScheme: '1 Set of 35 Mins',
                fixedWeightKg: 0,
                notes:
                    'Gentle zone 1 aerobic recovery, sunlight exposure, and lymphatic drainage.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Full-Body Passive Decompression',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Passive Bar Hang Decompression',
                liftId: 'barbell_dead_hang',
                setScheme: '3 Sets of 35s Hold',
                fixedWeightKg: 0,
                notes:
                    'Pure passive gravity traction to decompress lumbar spine, thoracic vertebrae, and shoulder joints.',
              ),
              ExerciseTemplate(
                name: 'Hip 90/90 Internal & External Rotation Flow',
                liftId: 'hip_90_90_switches',
                setScheme: '2 Sets of 60s per side',
                fixedWeightKg: 0,
                notes:
                    'Gentle, hands-free hip flow to restore full internal/external rotation.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Autonomic Down-Regulation & Fasting Reset',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wim Hof Guided Breathwork',
                liftId: 'breathwork',
                setScheme: '3 Sets of 30 Breaths',
                fixedWeightKg: 0,
                notes:
                    'Deep parasympathetic oxygenation and autonomic nervous system reset.',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<DayTemplate> getAtgStandardsProgram() {
    return <DayTemplate>[
      // Day 1 (Mon): Anterior Knee & VMO Armor
      DayTemplate(
        dayNumber: 1,
        title: 'Day 1: Anterior Knee & VMO Armor',
        subtitle:
            'Heavy Sled, Poliquin Step-Up, Jefferson Curl, Tibialis, Incline Press, Face Pull & Couch Stretch',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Knee Capillary Blood Flow & Foot Prep',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Reverse Sled / Deadmill (ROKP)',
                liftId: 'reverse_sled',
                setScheme: '3 Sets of 120m Heavy',
                fixedWeightKg: 0,
                notes:
                    'Heavy backward walking; pump maximum pain-free knee capillary blood flow.',
              ),
              ExerciseTemplate(
                name: 'Plantar Fascia Stretch',
                liftId: 'plantar_fascia_stretch',
                setScheme: '2 Sets of 120s Hold',
                fixedWeightKg: 0,
                notes:
                    'Toes extended against floor/wedge; deep plantar tissue lengthening.',
              ),
              ExerciseTemplate(
                name: 'Tibialis Stretch',
                liftId: 'tibialis_stretch',
                setScheme: '2 Sets of 120s Hold',
                fixedWeightKg: 0,
                notes: 'Sit on heels with ankles in full plantar flexion.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Main Knee Armor Density Block',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Poliquin Step-Up (45° Slant)',
                liftId: 'poliquin_step_up',
                setScheme: '5 Sets of 20 Reps @ 21X1',
                bodyweightPercentage: 66,
                notes:
                    'ATG Standard: 20 reps with 66% BW on back, 3-4" box, heel elevated >=45°.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Posterior Chain & Lower Leg Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Jefferson Curl',
                liftId: 'jefferson_curl',
                setScheme: '5 Sets of 10 Reps @ 3330',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 10 reps with 25% BW, segmented spine curl with wrists below toes.',
              ),
              ExerciseTemplate(
                name: 'Tibialis Anterior Raises',
                liftId: 'tibialis_raise',
                setScheme: '3 Sets of 20 Reps @ 11X2',
                bodyweightPercentage: 12.5,
                notes:
                    'ATG Standard: 12.5% BW dumbbell tib raise or strict wall reps; pause at top.',
              ),
              ExerciseTemplate(
                name: 'Hanging Leg Raise',
                liftId: 'hanging_leg_raise',
                setScheme: '3 Sets of 10 Reps @ 20X0',
                fixedWeightKg: 0,
                notes:
                    'ATG Standard: Toes to bar with controlled descent.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Upper Armor & Hip Opening',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: '45° Incline Dumbbell Press',
                liftId: 'incline_dumbbell_press',
                setScheme: '4 Sets of 10 Reps @ 22X0',
                bodyweightPercentage: 33,
                notes: 'ATG Standard: 33% BW per hand x 10 reps.',
              ),
              ExerciseTemplate(
                name: 'Cable Face Pull',
                liftId: 'face_pull',
                setScheme: '4 Sets of 10 Reps @ 2022',
                bodyweightPercentage: 33,
                notes:
                    'ATG Standard: 33% BW load x 10 reps, 2s peak scapular retraction.',
              ),
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '2 Sets of 90s per side',
                fixedWeightKg: 0,
                notes:
                    'Shin flush to wall, glute squeezed, upright vertical torso.',
              ),
            ],
          ),
        ],
      ),

      // Day 2 (Tue): Hip Range & Posterior Chain
      DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Hip Range & Posterior Chain',
        subtitle:
            'ATG Split Squat, Seated Good Morning, Single-Leg Calf, ATG Dips, Rotations, Forearm Armor & Pancake',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Foot, Sled & Hip Primer',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Standing Calf Stretch',
                liftId: 'calf_stretch',
                setScheme: '2 Sets of 120s per side',
                fixedWeightKg: 0,
                notes:
                    'Straight-leg upper gastrocnemius stretch against wall or slant board.',
              ),
              ExerciseTemplate(
                name: 'Sled Push / Pull',
                liftId: 'sled_push_pull',
                setScheme: '3 Sets of 20m Heavy',
                fixedWeightKg: 0,
                notes: 'Heavy push forward, pull backward.',
              ),
              ExerciseTemplate(
                name: 'Relaxed Lunge',
                liftId: 'relaxed_lunge',
                setScheme: '3 Sets of 60s per side',
                fixedWeightKg: 0,
                notes: 'Deep passive hip flexor sink.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Main Hip Density Block',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'ATG Split Squat',
                liftId: 'atg_split_squat',
                setScheme: '5 Sets of 5 Reps per side @ 33X0',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW per hand on flat ground (50% BW total); front hamstring covers calf completely.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Loaded Hip Hinge & Calf Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Seated Good Morning',
                liftId: 'seated_good_morning',
                setScheme: '5 Sets of 10 Reps @ 31X1',
                bodyweightPercentage: 50,
                notes:
                    'ATG Standard: 50% BW barbell on back; abs to bench with zero lower back rounding.',
              ),
              ExerciseTemplate(
                name: 'Single-Leg Calf Raise',
                liftId: 'single_leg_calf_raise',
                setScheme: '3 Sets of 10 Reps @ 11X2',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW DB in hand x 10 reps with 2s bottom stretch.',
              ),
              ExerciseTemplate(
                name: 'Garhammer Raise',
                liftId: 'garhammer_raise',
                setScheme: '3 Sets of 10 Reps @ 11X2',
                fixedWeightKg: 0,
                notes:
                    'ATG Standard: Level 2 knee curl starting from 90° flexion.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Upper Body Armor & Adductor Opening',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Full-Range ATG Dips',
                liftId: 'atg_dips',
                setScheme: '4 Sets of up to 12 Reps @ 22X0',
                fixedWeightKg: 0,
                notes:
                    'ATG Standard: 12 strict bodyweight reps with deep bicep-to-forearm compression.',
              ),
              ExerciseTemplate(
                name: 'Seated External Rotations',
                liftId: 'external_rotations',
                setScheme: '4 Sets of 12 Reps @ 32X0',
                bodyweightPercentage: 10,
                notes:
                    'ATG Standard: 10% BW dumbbell resting on elevated knee.',
              ),
              ExerciseTemplate(
                name: 'Forearm Pronation & Supination',
                liftId: 'forearm_pronation_supination',
                setScheme: '3 Sets of 15 Reps per side @ 2020',
                fixedWeightKg: 4,
                notes:
                    'Using ATG Wrist Bar, sledgehammer, or offset dumbbell; elbow at 90° on bench, slow controlled rotation.',
              ),
              ExerciseTemplate(
                name: 'Dumbbell Wrist Extension',
                liftId: 'dumbbell_wrist_extension',
                setScheme: '3 Sets of 15 Reps @ 3010',
                fixedWeightKg: 6,
                notes:
                    'Forearms flat across bench/thighs palms down; 3s eccentric lower; balances dip compression and protects lateral epicondyle.',
              ),
              ExerciseTemplate(
                name: 'Butterfly Stretch against Wall',
                liftId: 'butterfly_stretch',
                setScheme: '1 Set of 120s Hold',
                fixedWeightKg: 0,
                notes: 'Back flush to wall, knees pressed flat to floor.',
              ),
              ExerciseTemplate(
                name: 'Seated Pancake',
                liftId: 'seated_pancake',
                setScheme: '1 Set of 120s Hold',
                fixedWeightKg: 0,
                notes: 'Wide straddle forward fold chest to floor.',
              ),
            ],
          ),
        ],
      ),

      // Day 3 (Wed): Active ROKP & Ankle Transformation (Active Recovery)
      DayTemplate(
        dayNumber: 3,
        title: 'Day 3: Active ROKP & Ankle Transformation',
        subtitle:
            'Reverse Sled ROKP, 9-Min Calf Stretch, Seated Soleus Pauses, Tibialis & 90/90 Flow',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Capillary Flushing & Blood Flow',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Reverse Sled / Deadmill (ROKP)',
                liftId: 'reverse_sled',
                setScheme: '1 Set of 12 Mins Continuous',
                fixedWeightKg: 0,
                notes:
                    'Continuous backward walking; pump pain-free synovial fluid and capillary recovery.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Ankle Transformation Protocol',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Slant Board Calf Stretch',
                liftId: 'slant_board_calf_stretch',
                setScheme: '3 Sets of 90s per side',
                fixedWeightKg: 0,
                notes:
                    'Full 9 minutes total calf lengthening; drive knee over toes without heel lifting.',
              ),
              ExerciseTemplate(
                name: 'Seated Calf Machine (Soleus Raise)',
                liftId: 'seated_calf_raise',
                setScheme: '4 Sets of 4 Reps w/ 4s Pauses',
                bodyweightPercentage: 25,
                notes:
                    'Bent-knee soleus isolation; 4s isometric pause at bottom stretch.',
              ),
              ExerciseTemplate(
                name: 'Dumbbell Tibialis Raises',
                liftId: 'tibialis_raise',
                setScheme: '4 Sets of 15 Reps',
                bodyweightPercentage: 12.5,
                notes:
                    'Full dorsiflexion squeeze to strengthen the primary ankle decelerator.',
              ),
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '4 Sets of 30s per side',
                fixedWeightKg: 0,
                notes: 'Wall anchored quad and hip flexor reset.',
              ),
              ExerciseTemplate(
                name: 'Patrick Step-Up (Bodyweight)',
                liftId: 'patrick_step_up',
                setScheme: '4 Sets of 10 Reps',
                fixedWeightKg: 0,
                notes:
                    'Smooth, pain-free controlled ankle dorsiflexion tracking.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Hip Capsule Decompression',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: '90/90 Hip Switches & Pigeon Flow',
                liftId: 'hip_90_90_switch',
                setScheme: '1 Set of 180s per side',
                fixedWeightKg: 0,
                notes:
                    'Hands-free internal and external rotation hip capsule flow.',
              ),
            ],
          ),
        ],
      ),

      // Day 4 (Thu): Deep Squat & Vertical Press/Pull
      DayTemplate(
        dayNumber: 4,
        title: 'Day 4: Deep Squat & Vertical Press/Pull',
        subtitle:
            'Sled Drive, ATG Deep Squat, Nordic Curls, Cable Hip Flexors, Shoulder Press, Chin-Ups & Wrist Flexion',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Sled Drive & Hip Prep',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Plantar Fascia Stretch',
                liftId: 'plantar_fascia_stretch',
                setScheme: '2 Sets of 120s Hold',
                fixedWeightKg: 0,
                notes: 'Ankle and foot arch prep.',
              ),
              ExerciseTemplate(
                name: 'Sled Drive',
                liftId: 'sled_drive',
                setScheme: '3 Sets of 40m Heavy',
                fixedWeightKg: 0,
                notes:
                    'Forward sprint drive against heavy sled resistance.',
              ),
              ExerciseTemplate(
                name: 'Single-Leg Elevated Pike',
                liftId: 'elevated_pike',
                setScheme: '3 Sets of 60s per side',
                fixedWeightKg: 0,
                notes: 'Elevated single-leg hamstring stretch.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Full-Depth Squat Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'ATG Squat / VMO Squat',
                liftId: 'atg_squat',
                setScheme: '5 Sets of 20 Reps @ 22X1',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW x 20 reps; full ankle-to-hamstring coverage, upright torso.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Hamstring Armor & Hip Flexor Isolation',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Nordic Hamstring Curls',
                liftId: 'nordic_hamstring_curl',
                setScheme: '5 Sets of 10 Reps @ 41X0',
                fixedWeightKg: 0,
                notes:
                    'ATG Standard: 10 full-range reps or strict eccentric descent without hip flexion.',
              ),
              ExerciseTemplate(
                name: 'Low-Cable Pull-In',
                liftId: 'low_cable_pull_in',
                setScheme: '3 Sets of 20 Reps @ 10X0',
                bodyweightPercentage: 50,
                notes:
                    'ATG Standard: 50% BW x 20 reps; strengthen deep psoas hip flexors.',
              ),
              ExerciseTemplate(
                name: 'Tibialis Anterior Raises',
                liftId: 'tibialis_raise',
                setScheme: '3 Sets of 20 Reps @ 11X2',
                bodyweightPercentage: 12.5,
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Vertical Press & Pull Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'ATG DB Shoulder Press',
                liftId: 'atg_shoulder_press',
                setScheme: '4 Sets of 10 Reps @ 22X0',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW per hand x 10 reps (50% BW total).',
              ),
              ExerciseTemplate(
                name: 'ATG Full-Range Chin-Ups',
                liftId: 'atg_chin_up',
                setScheme: '4 Sets of up to 10 Reps @ 21X1',
                fixedWeightKg: 0,
                notes: 'ATG Standard: 10 dead-hang to chest-to-bar reps.',
              ),
              ExerciseTemplate(
                name: 'Dumbbell Wrist Flexion',
                liftId: 'dumbbell_wrist_flexion',
                setScheme: '3 Sets of 15 Reps @ 21X1',
                fixedWeightKg: 8,
                notes:
                    'Forearms flat across bench palms up; roll dumbbell to fingertips, curl into full wrist contraction to remodel medial epicondyle tendons.',
              ),
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '2 Sets of 90s per side',
                fixedWeightKg: 0,
              ),
            ],
          ),
        ],
      ),

      // Day 5 (Fri): Posterior Armor & Trunk Integrity
      DayTemplate(
        dayNumber: 5,
        title: 'Day 5: Posterior Armor & Trunk Integrity',
        subtitle:
            'ATG Romanian Deadlift, KOT/Sissy Squat, Floor Wrist Prep, L-Sit Hold, QL Extensions, Pullover & Trap 3',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Foot & Posterior Flush',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Standing Calf Stretch',
                liftId: 'calf_stretch',
                setScheme: '2 Sets of 120s per side',
                fixedWeightKg: 0,
              ),
              ExerciseTemplate(
                name: 'Sled Push / Pull',
                liftId: 'sled_push_pull',
                setScheme: '1 Set of 60m Heavy each way',
                fixedWeightKg: 0,
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Posterior Chain & Knee Extension Pairing',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'ATG Romanian Deadlift',
                liftId: 'atg_rdl',
                setScheme: '5 Sets of 10 Reps @ 11X1',
                bodyweightPercentage: 100,
                notes:
                    'ATG Standard: 100% BW x 10 reps; flat back with deep hamstring stretch below parallel.',
              ),
              ExerciseTemplate(
                name: 'KOT Squat / Sissy Squats',
                liftId: 'kot_squat',
                setScheme: '5 Sets of 20 Reps @ 31X0',
                fixedWeightKg: 0,
                notes:
                    'ATG Standard: Bodyweight x 20 reps, shins parallel to floor or knees to floor with pad.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Core & Lateral Trunk Armor',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Quadruped Floor Wrist Loading',
                liftId: 'quadruped_wrist_loading',
                setScheme: '2 Sets of 60s Flow',
                fixedWeightKg: 0,
                notes:
                    'Palms flat (fingers forward, backward) & backs of hands on floor; gentle bodyweight rock to prepare carpal tunnel & wrists for L-sit.',
              ),
              ExerciseTemplate(
                name: 'L-Sit Hold',
                liftId: 'l_sit_hold',
                setScheme: '3 Sets of 15s Hold',
                fixedWeightKg: 0,
                notes:
                    'ATG Standard: 15 seconds flat ground palms down hold.',
              ),
              ExerciseTemplate(
                name: 'QL Extensions',
                liftId: 'ql_extension',
                setScheme: '3 Sets of 10 Reps per side',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW x 10 reps on 45° back extension bench.',
              ),
              ExerciseTemplate(
                name: 'Single-Leg Calf Raise',
                liftId: 'single_leg_calf_raise',
                setScheme: '3 Sets of 10 Reps @ 11X2',
                bodyweightPercentage: 25,
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Scapular Armor & Cool-Down',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Cross-Bench Pullover',
                liftId: 'cross_bench_pullover',
                setScheme: '4 Sets of 10 Reps @ 22X0',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW x 10 reps; hips and elbows dropped below bench.',
              ),
              ExerciseTemplate(
                name: 'Trap-3 Raise',
                liftId: 'trap_3_raise',
                setScheme: '4 Sets of 10 Reps @ 30X3',
                bodyweightPercentage: 5,
                notes: '3-second peak isometric hold at 45° angle.',
              ),
              ExerciseTemplate(
                name: 'Seated Pancake',
                liftId: 'seated_pancake',
                setScheme: '1 Set of 120s Hold',
                fixedWeightKg: 0,
              ),
              ExerciseTemplate(
                name: 'Butterfly Stretch against Wall',
                liftId: 'butterfly_stretch',
                setScheme: '1 Set of 120s Hold',
                fixedWeightKg: 0,
              ),
            ],
          ),
        ],
      ),

      // Day 6 (Sat): Athletic Power & Elasticity (Active Recovery)
      DayTemplate(
        dayNumber: 6,
        title: 'Day 6: Athletic Power & Elasticity',
        subtitle:
            'Reverse Sled Flush, KOT Calf Raise, Tendon Pogo/Jump Landing Drills, Tibialis & Couch Stretch',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Sled Blood Flow',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Reverse Sled / Deadmill (ROKP)',
                liftId: 'reverse_sled',
                setScheme: '1 Set of 10 Mins Continuous',
                fixedWeightKg: 0,
                notes:
                    'Low-impact backward walking; joint decompression.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Athletic Qualities Protocol',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Athletic Tendon Drills / Pogo Bounces',
                liftId: 'athletic_qualities',
                setScheme: '3 Sets of 30s Drills',
                fixedWeightKg: 0,
                notes:
                    'Low-impact elastic tendon bouncing, pogo hops, or C25K running interval.',
              ),
              ExerciseTemplate(
                name: 'Single-Leg KOT Calf Raise',
                liftId: 'kot_calf_raise',
                setScheme: '3 Sets of 10 Reps',
                bodyweightPercentage: 25,
                notes:
                    'ATG Standard: 25% BW x 10 reps with knee bent over toes.',
              ),
              ExerciseTemplate(
                name: 'Dumbbell Tibialis Raises',
                liftId: 'tibialis_raise',
                setScheme: '3 Sets of 20 Reps',
                bodyweightPercentage: 12.5,
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Tissue Lengthening',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '2 Sets of 120s per side',
                fixedWeightKg: 0,
              ),
              ExerciseTemplate(
                name: '90/90 Hip Switches & Pigeon Flow',
                liftId: 'hip_90_90_switch',
                setScheme: '2 Sets of 120s per side',
                fixedWeightKg: 0,
              ),
            ],
          ),
        ],
      ),

      // Day 7 (Sun): Full System Recovery & Joint Restoration (Active Recovery)
      DayTemplate(
        dayNumber: 7,
        title: 'Day 7: Full System Recovery & Joint Restoration',
        subtitle:
            'Aerobic Walk/Sled Flush, Elephant Walk Hamstring Release, Wall Butterfly & Seated Pancake',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Decompression & Parasympathetic Reset',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Aerobic Walk / Light Sled',
                liftId: 'walking',
                setScheme: '1 Set of 15 Mins',
                fixedWeightKg: 0,
                notes:
                    'Gentle aerobic flush; nasal diaphragmatic breathing.',
              ),
              ExerciseTemplate(
                name: 'Elephant Walk',
                liftId: 'elephant_walk',
                setScheme: '2 Sets of 45 Reps',
                fixedWeightKg: 0,
                notes:
                    'Palms flat on floor, alternating knee extensions to decompress hamstrings.',
              ),
              ExerciseTemplate(
                name: 'Butterfly Stretch against Wall',
                liftId: 'butterfly_stretch',
                setScheme: '1 Set of 180s Hold',
                fixedWeightKg: 0,
              ),
              ExerciseTemplate(
                name: 'Seated Pancake',
                liftId: 'seated_pancake',
                setScheme: '1 Set of 180s Hold',
                fixedWeightKg: 0,
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<DayTemplate> getEmomEightProgram() {
    return <DayTemplate>[
      // Day 1: Vertical Pull (Pull-ups / Chin-ups)
      DayTemplate(
        dayNumber: 1,
        title: 'Day 1: Vertical Pull (Pull-ups / Chin-ups)',
        subtitle:
            'Scapular Depressions, Dead Hang Decompression & 10–30m EMOM Density',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Scapular Primer & Shoulder Prep',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Scapular Pull-ups & Dead Hang',
                liftId: 'scapular_pull_ups',
                setScheme: '2 Sets of 10 Reps + 30s Hang',
                fixedWeightKg: 0,
                notes:
                    'Active shoulder depression to fire lower traps and serratus before loading.',
              ),
              ExerciseTemplate(
                name: 'Band Pull-Aparts',
                liftId: 'band_pull_apart',
                setScheme: '2 Sets of 15 Reps',
                fixedWeightKg: 0,
                notes:
                    'Rear delt and rhomboid activation. Squeeze shoulder blades together.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Vertical Pull)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Pull-ups / Chin-ups (1–10 Method)',
                liftId: 'emom_pull_ups',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Submaximal quality volume every minute on the minute. Target 1-10 reps per round without training to failure early. '
                    'Progression: Weighted pull-ups or gymnastics ring pull-ups. '
                    'Regression: Foot-assisted on bench or resistance band looped on bar.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Decompression & Lat Reset',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Passive Bar Hang / Decompression',
                liftId: 'active_hang',
                setScheme: '2 Sets of 60s Hold',
                fixedWeightKg: 0,
                notes:
                    'Decompress spine, expand thoracic cavity, and stretch lats.',
              ),
            ],
          ),
        ],
      ),

      // Day 2: Downward Push (Parallel Bar Dips)
      DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Downward Push (Parallel Bar Dips)',
        subtitle:
            'Wrist Rotations, Scapular Dips & 10–30m EMOM Tricep/Chest Volume',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Wrist & Shoulder Capsule Prep',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wrist Extension/Flexion Rocks',
                liftId: 'wrist_mobility',
                setScheme: '2 Sets of 15 Rocks',
                fixedWeightKg: 0,
                notes: 'Palms flat on floor; rock gently forward over fingers.',
              ),
              ExerciseTemplate(
                name: 'Scapular Dip Shrugs',
                liftId: 'scapular_dips',
                setScheme: '2 Sets of 10 Reps',
                fixedWeightKg: 0,
                notes: 'Straight arms on dip bars; depress and elevate scapula.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Downward Push)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Parallel Bar Dips (1–10 Method)',
                liftId: 'emom_dips',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Clean depth with upper arms reaching parallel. Crisp lockouts without hyperextending elbows. '
                    'Progression: Weighted dips (+belt) or gymnastics ring dips. '
                    'Regression: Foot-assisted on bench or resistance band looped across bars.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Anterior Shoulder & Pec Release',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Doorway / Ring Chest Opener',
                liftId: 'ring_chest_stretch',
                setScheme: '2 Sets of 45s Hold',
                fixedWeightKg: 0,
                notes:
                    'Expand ribcage and release anterior delts and pectoralis major.',
              ),
            ],
          ),
        ],
      ),

      // Day 3: Knee Dominant / Squat (Squats)
      DayTemplate(
        dayNumber: 3,
        title: 'Day 3: Knee Dominant / Squat (Full Depth Squats)',
        subtitle:
            'Ankle Dorsiflexion, Hip IR & High-Density EMOM Squat Volume',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Ankle Dorsiflexion & Hip Capsule Primer',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Slant Board Calf Stretch',
                liftId: 'slant_board_calf_stretch',
                setScheme: '2 Sets of 45s Hold',
                fixedWeightKg: 0,
                notes: 'Drive knee forward over toes to open deep dorsiflexion.',
              ),
              ExerciseTemplate(
                name: 'Deep Squat Pry / Hip Opener',
                liftId: 'deep_squat_pry',
                setScheme: '2 Sets of 60s Pry',
                fixedWeightKg: 0,
                notes: 'Sit in deep bottom position, pry knees outward with elbows.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Knee-Dominant Squats)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Squats (1–10 Method)',
                liftId: 'emom_squats',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Full range of motion with hips descending below knees. High cardiovascular & leg pump density. '
                    'Progression: Dual kettlebell front rack squats or goblet squats. '
                    'Regression: Bodyweight air squats or box squats.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Quad & Hip Flexor Flush',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Wall Couch Stretch',
                liftId: 'couch_stretch',
                setScheme: '2 Sets of 45s per side',
                fixedWeightKg: 0,
                notes:
                    'Glute squeeze on trail leg to open tight hip flexors and rectus femoris.',
              ),
            ],
          ),
        ],
      ),

      // Day 4: Horizontal Pull (Inverted Rows)
      DayTemplate(
        dayNumber: 4,
        title: 'Day 4: Horizontal Pull (Inverted Rows)',
        subtitle:
            'Scapular Retraction, Rhomboid Armor & 10–30m EMOM Mid-Back Volume',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Scapular Retraction & Thoracic Extension',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Prone Y-T-W Scapular Raises',
                liftId: 'ytw_scapular_raises',
                setScheme: '2 Sets of 10 Reps each',
                fixedWeightKg: 0,
                notes:
                    'Activate lower traps, rhomboids, and mid-trapezius without shrugging.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Horizontal Pull)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Inverted Rows (1–10 Method)',
                liftId: 'emom_inverted_rows',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Barbell or gymnastic rings. Maintain a rigid plank from ankles to crown. '
                    'Progression: Feet elevated on box/bench or weighted vest. '
                    'Regression: Higher strap/bar angle (incline row) or bent knees.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Lat & Thoracic Decompression',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: "Child's Pose with Lateral Lat Reach",
                liftId: 'childs_pose_reach',
                setScheme: '2 Sets of 45s Hold per side',
                fixedWeightKg: 0,
                notes:
                    'Sink hips back onto heels, reach diagonally to expand lateral ribcage.',
              ),
            ],
          ),
        ],
      ),

      // Day 5: Horizontal Push (Push-ups)
      DayTemplate(
        dayNumber: 5,
        title: 'Day 5: Horizontal Push (Push-ups)',
        subtitle:
            'Wrist Extension, Serratus Activation & 10–30m EMOM Chest/Core Volume',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Serratus Anterior & Wrist Primer',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Scapular Push-ups (Push-up Plus)',
                liftId: 'scapular_push_ups',
                setScheme: '2 Sets of 12 Reps',
                fixedWeightKg: 0,
                notes:
                    'Protract scapula firmly at the top to prime the serratus anterior.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Horizontal Push)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Push-ups (1–10 Method)',
                liftId: 'emom_push_ups',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Elbows tracked at ~45 degrees, rigid glute/abdominal brace. Chest touches deck each rep. '
                    'Progression: Deficit push-ups (hands on blocks), ring push-ups, or weighted vest. '
                    'Regression: Hands-elevated incline push-ups or knee push-ups.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Pec & Bicep Tendon Release',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Prone Floor Pec & Bicep Stretch',
                liftId: 'floor_pec_stretch',
                setScheme: '2 Sets of 45s Hold per side',
                fixedWeightKg: 0,
                notes:
                    'Arm at 90 degrees; roll torso gently away from pinned shoulder.',
              ),
            ],
          ),
        ],
      ),

      // Day 6: Unilateral Leg (Walking / Reverse Lunges)
      DayTemplate(
        dayNumber: 6,
        title: 'Day 6: Unilateral Leg (Walking / Reverse Lunges)',
        subtitle:
            'Single-Leg Knee Stability, Pelvic Alignment & 10–30m EMOM Leg Density',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Ankle Dorsiflexion & Glute Medius Primer',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Patrick Step-Up / Controlled Tap',
                liftId: 'patrick_step_up',
                setScheme: '2 Sets of 10 Reps per side',
                fixedWeightKg: 0,
                notes:
                    'Pure knee over toe tracking to fire VMO and warm up patellar tendon.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Unilateral Leg)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Walking / Reverse Lunges (1–10 Method)',
                liftId: 'emom_lunges',
                setScheme: '10–30 Min EMOM (1–10 Reps/Round)',
                fixedWeightKg: 0,
                notes:
                    'Upright torso, vertical front shin, back knee gently touches floor. '
                    'Progression: Dual kettlebell/dumbbell farmer lunges or deficit reverse lunges. '
                    'Regression: Static split squats or hand-assisted lunges.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Hip Capsule & Glute Restoration',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: '90/90 Hip Switches & Pigeon Flow',
                liftId: 'hip_90_90_switch',
                setScheme: '2 Sets of 60s per side',
                fixedWeightKg: 0,
                notes:
                    'Decompress hip capsule and release external rotators after unilateral work.',
              ),
            ],
          ),
        ],
      ),

      // Day 7: Vertical Push (Pike Push-ups / Overhead Press)
      DayTemplate(
        dayNumber: 7,
        title: 'Day 7: Vertical Push (Pike Push-ups / Overhead Press)',
        subtitle:
            'Thoracic Mobility, Deltoid Power & 10–30m EMOM Overhead Density',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Overhead Thoracic & Scapular Elevation',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Downward Dog to Upward Dog Flow',
                liftId: 'downward_dog_flow',
                setScheme: '2 Sets of 8 Flows',
                fixedWeightKg: 0,
                notes:
                    'Drive head between shoulders in downward dog to open thoracic extension.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Vertical Push)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Pike Push-ups / Overhead Press (1–10 Method)',
                liftId: 'emom_pike_push_ups',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Inverted tripod head descent, hips stacked high over shoulders. '
                    'Progression: Feet-elevated box pike push-ups, wall handstand push-ups, or DB overhead press. '
                    'Regression: Hands-elevated incline pike push-ups or high-angle push-ups.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Overhead Lat & Thoracic Release',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Overhead Wall Lat & Tricep Stretch',
                liftId: 'wall_lat_stretch',
                setScheme: '2 Sets of 45s Hold',
                fixedWeightKg: 0,
                notes:
                    'Elbows on wall, hands behind neck, sink chest toward floor.',
              ),
            ],
          ),
        ],
      ),

      // Day 8: Hip Hinge / Posterior Chain (Romanian Deadlifts / Swings)
      DayTemplate(
        dayNumber: 8,
        title: 'Day 8: Hip Hinge / Posterior Chain (RDLs / Swings)',
        subtitle:
            'Hamstring Flexibility, Spinal Erector Armor & 10–30m EMOM Posterior Chain',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Hamstring Floss & Glute Primer',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Elephant Walks',
                liftId: 'elephant_walk',
                setScheme: '2 Sets of 20 Alternating Reps',
                fixedWeightKg: 0,
                notes:
                    'Alternate knee extensions with hands on floor to floss sciatic nerve and hamstrings.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Primary EMOM (Hip Hinge / Posterior Chain)',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Romanian Deadlifts / KB Hinges (1–10 Method)',
                liftId: 'emom_hinges',
                setScheme: '10–30 Min EMOM (1–10 Reps/Min)',
                fixedWeightKg: 0,
                notes:
                    'Hips back, soft knee flexion, rigid neutral spine. Glute drive on lockout. '
                    'Progression: Dual kettlebell / barbell Romanian deadlifts or explosive KB swings. '
                    'Regression: Bodyweight good mornings or resistance band hip hinges.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Lumbar & Hamstring Decompression',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Jefferson Curl (Light Bodyweight/Plate)',
                liftId: 'jefferson_curl',
                setScheme: '2 Sets of 5 Slow Reps',
                fixedWeightKg: 0,
                notes:
                    'Segmented vertebral spinal flexion to restore spinal length and decompress erectors.',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<DayTemplate> getBuiltInProgram({int week = 1}) {
    // Helper free-form conditioning day for Day 2, Day 4, and Day 6
    DayTemplate createActiveRecoveryDay(int dayNum) {
      return DayTemplate(
        dayNumber: dayNum,
        title: 'Day $dayNum: Conditioning & Accessories',
        subtitle:
            'Free-Form Canvas: Pick a WOD, Kettlebell Mile, or Accessories',
        isFreeform: true,
        phases: <PhaseTemplate>[],
      );
    }

    // --- WEEK 5: 1RM RETEST WEEK ---
    if (week == 5) {
      return <DayTemplate>[
        // Day 1: Snatch Retest + Squat Primer
        DayTemplate(
          dayNumber: 1,
          title: 'Day 1: Snatch 1RM Retest',
          subtitle: 'Snatch 1RM Retest Protocol, Back Squat Speed Primer',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Snatch 1RM Retest Protocol',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Snatch',
                  liftId: 'snatch',
                  setScheme:
                      '5 Sets: 1x3 @ 60%, 1x2 @ 75%, 1x1 @ 85%, 1x1 @ 95%, 1x1 @ New PR Target',
                  fixedPercentage: 100,
                  notes:
                      'Ramp progressively through warmups to establish new 1RM baseline.',
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Speed Squat Primer',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Back Squat',
                  liftId: 'back_squat',
                  setScheme: '3 Sets of 3 Reps',
                  fixedPercentage: 70,
                  notes: '@ 70% dynamic speed effort; keep legs fresh and explosive.',
                ),
              ],
            ),
          ],
        ),

        // Day 2: Recovery
        createActiveRecoveryDay(2),

        // Day 3: Clean & Jerk Retest + Front Squat Primer
        DayTemplate(
          dayNumber: 3,
          title: 'Day 2: Clean & Jerk 1RM Retest',
          subtitle:
              'Clean & Jerk 1RM Retest Protocol, Front Squat Speed Primer',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Clean & Jerk 1RM Retest Protocol',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Clean and Jerk',
                  liftId: 'clean_and_jerk',
                  setScheme:
                      '5 Sets: 1x3 @ 60%, 1x2 @ 75%, 1x1 @ 85%, 1x1 @ 95%, 1x1 @ New PR Target',
                  fixedPercentage: 100,
                  notes:
                      'Ramp progressively through warmups to establish new 1RM baseline.',
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Front Squat Speed Primer',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Front Squat',
                  liftId: 'clean_and_jerk',
                  anchorLiftId: 'clean_and_jerk',
                  setScheme: '3 Sets of 2 Reps',
                  fixedPercentage: 70,
                  notes: '@ 70% speed effort; maintain sharp upright posture.',
                ),
              ],
            ),
          ],
        ),

        // Day 4: Recovery
        createActiveRecoveryDay(4),

        // Day 5: Back Squat 1RM Retest / Classic Total
        DayTemplate(
          dayNumber: 5,
          title: 'Day 3: Back Squat 1RM Retest',
          subtitle: 'Back Squat 1RM Retest Protocol & Cycle Culmination',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Back Squat 1RM Retest Protocol',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Back Squat',
                  liftId: 'back_squat',
                  setScheme:
                      '5 Sets: 1x3 @ 60%, 1x2 @ 75%, 1x1 @ 85%, 1x1 @ 95%, 1x1 @ New PR Target',
                  fixedPercentage: 100,
                  notes:
                      'Test true squat baseline to anchor next cycle percentages.',
                ),
              ],
            ),
          ],
        ),

        // Day 6: Recovery
        createActiveRecoveryDay(6),
      ];
    }

    // --- WEEKS 1..4: 2:1 ALTERNATING PROGRAM ---
    // Odd weeks (1 & 3): Week A -> 2 Snatch days (Days 1 & 5), 1 Clean & Jerk day (Day 3)
    // Even weeks (2 & 4): Week B -> 1 Snatch day (Day 3), 2 Clean & Jerk days (Days 1 & 5)
    final bool isSnatchEmphasisWeek = (week % 2 != 0);

    if (isSnatchEmphasisWeek) {
      // WEEK A (2 Snatch : 1 Clean & Jerk)
      return <DayTemplate>[
        // Day 1: Snatch Primary + Back Squat
        DayTemplate(
          dayNumber: 1,
          title: 'Day 1: Snatch Focus & Squat',
          subtitle: 'Power Snatch + OHS, Back Squat',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Power & Technique Development',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Power Snatch + Overhead Squat',
                  liftId: 'snatch',
                  setScheme: '4 Sets of 2 Reps (1 Power Snatch + 1 OHS)',
                  weekPercentages: <int, double>{
                    1: 65.0,
                    2: 70.0,
                    3: 75.0,
                    4: 70.0,
                  },
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Squat Strength Foundation',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Back Squat',
                  liftId: 'back_squat',
                  setScheme: '4 Sets of 5 Reps',
                  weekPercentages: <int, double>{
                    1: 65.0,
                    2: 70.0,
                    3: 75.0,
                    4: 70.0,
                  },
                ),
              ],
            ),
          ],
        ),

        // Day 2: Active Recovery
        createActiveRecoveryDay(2),

        // Day 3: Clean & Jerk Primary + Front Squat
        DayTemplate(
          dayNumber: 3,
          title: 'Day 2: Clean & Jerk Focus & Squat',
          subtitle: 'Clean and Jerk, Front Squat',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Classic Lift Mastery',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Clean and Jerk',
                  liftId: 'clean_and_jerk',
                  setScheme: '4 Sets of 2 Reps',
                  weekPercentages: <int, double>{
                    1: 70.0,
                    2: 75.0,
                    3: 80.0,
                    4: 75.0,
                  },
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Anterior Squat Strength',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Front Squat',
                  liftId: 'clean_and_jerk',
                  anchorLiftId: 'clean_and_jerk',
                  setScheme: '4 Sets of 3 Reps',
                  fixedPercentage: 75,
                  notes: '@ 75% of Clean and Jerk Max',
                ),
              ],
            ),
          ],
        ),

        // Day 4: Active Recovery
        createActiveRecoveryDay(4),

        // Day 5: Hang Snatch + Snatch Pull
        DayTemplate(
          dayNumber: 5,
          title: 'Day 3: Hang Snatch & Pull Power',
          subtitle: 'Hang Snatch, Snatch Pull',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Explosive Second Pull & Turnover',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Hang Snatch',
                  liftId: 'snatch',
                  setScheme: '4 Sets of 2 Reps',
                  weekPercentages: <int, double>{
                    1: 70.0,
                    2: 75.0,
                    3: 80.0,
                    4: 75.0,
                  },
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Pulling Power & Mechanics',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Snatch Pull',
                  liftId: 'snatch',
                  setScheme: '3 Sets of 2 Reps',
                  fixedPercentage: 90,
                  notes: '@ 90% for all weeks',
                ),
              ],
            ),
          ],
        ),

        // Day 6: Active Recovery
        createActiveRecoveryDay(6),
      ];
    } else {
      // WEEK B (1 Snatch : 2 Clean & Jerk)
      return <DayTemplate>[
        // Day 1: Clean & Jerk Primary + Front Squat
        DayTemplate(
          dayNumber: 1,
          title: 'Day 1: Clean & Jerk Focus & Squat',
          subtitle: 'Clean and Jerk, Front Squat',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Classic Lift Mastery',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Clean and Jerk',
                  liftId: 'clean_and_jerk',
                  setScheme: '4 Sets of 2 Reps',
                  weekPercentages: <int, double>{
                    1: 70.0,
                    2: 75.0,
                    3: 80.0,
                    4: 75.0,
                  },
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Anterior Squat Strength',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Front Squat',
                  liftId: 'clean_and_jerk',
                  anchorLiftId: 'clean_and_jerk',
                  setScheme: '4 Sets of 3 Reps',
                  fixedPercentage: 75,
                  notes: '@ 75% of Clean and Jerk Max',
                ),
              ],
            ),
          ],
        ),

        // Day 2: Active Recovery
        createActiveRecoveryDay(2),

        // Day 3: Snatch Primary + Back Squat
        DayTemplate(
          dayNumber: 3,
          title: 'Day 2: Snatch Focus & Squat',
          subtitle: 'Power Snatch + OHS, Back Squat',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Power & Technique Development',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Power Snatch + Overhead Squat',
                  liftId: 'snatch',
                  setScheme: '4 Sets of 2 Reps (1 Power Snatch + 1 OHS)',
                  weekPercentages: <int, double>{
                    1: 65.0,
                    2: 70.0,
                    3: 75.0,
                    4: 70.0,
                  },
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Squat Strength Foundation',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Back Squat',
                  liftId: 'back_squat',
                  setScheme: '4 Sets of 5 Reps',
                  weekPercentages: <int, double>{
                    1: 65.0,
                    2: 70.0,
                    3: 75.0,
                    4: 70.0,
                  },
                ),
              ],
            ),
          ],
        ),

        // Day 4: Active Recovery
        createActiveRecoveryDay(4),

        // Day 5: Hang Clean + Clean Pull
        DayTemplate(
          dayNumber: 5,
          title: 'Day 3: Hang Clean & Pull Power',
          subtitle: 'Hang Clean, Clean Pull',
          phases: <PhaseTemplate>[
            PhaseTemplate(
              name: 'Phase 1 - Extension & Turnover Power',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Hang Clean',
                  liftId: 'clean_and_jerk',
                  setScheme: '4 Sets of 2 Reps',
                  weekPercentages: <int, double>{
                    1: 70.0,
                    2: 75.0,
                    3: 80.0,
                    4: 75.0,
                  },
                ),
              ],
            ),
            PhaseTemplate(
              name: 'Phase 2 - Pulling Power & Positions',
              exercises: <ExerciseTemplate>[
                ExerciseTemplate(
                  name: 'Clean Pull',
                  liftId: 'clean_and_jerk',
                  anchorLiftId: 'clean_and_jerk',
                  setScheme: '3 Sets of 2 Reps',
                  fixedPercentage: 95,
                  notes: '@ 95% of Clean and Jerk Max',
                ),
              ],
            ),
          ],
        ),

        // Day 6: Active Recovery
        createActiveRecoveryDay(6),
      ];
    }
  }
}
