enum TrainingTrack {
  olympic,
  mobility,
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
  final String? notes;

  // Calculate suggested working weight for a specific week given current 1RMs map
  double calculateTargetWeight({
    required int week,
    required Map<String, double> currentMaxes,
  }) {
    if (fixedWeightKg != null) {
      return fixedWeightKg!;
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
  }) : completedSessionIds = completedSessionIds ?? <String>[];

  factory fromJson(Map<String, dynamic> json) {
    return ProgramCycle(
      currentCycle: json['currentCycle'] as int? ?? 1,
      currentWeek: json['currentWeek'] as int? ?? 1,
      currentDay: json['currentDay'] as int? ?? 1,
      activeTrack: json['activeTrack'] == 'olympic'
          ? TrainingTrack.olympic
          : TrainingTrack.mobility,
      completedSessionIds:
          (json['completedSessionIds'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
    );
  }
  int currentCycle;
  int currentWeek; // 1..4 = training weeks, 5 = 1RM Retest Week
  int currentDay; // 1..4 (Olympic) or 1..7 (Mobility)
  TrainingTrack activeTrack;
  List<String> completedSessionIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentCycle': currentCycle,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'activeTrack': activeTrack.name,
      'completedSessionIds': completedSessionIds,
    };
  }

  static List<DayTemplate> getMobilityProgram() {
    return <DayTemplate>[
      // Day 1 (Mon): Lower Hypertrophy + ATG Knee/Ankle
      DayTemplate(
        dayNumber: 1,
        title: 'Day 1: Lower Hypertrophy + ATG Knee/Ankle',
        subtitle: 'Slant Board, Tibialis Raises, Pause Squats, ATG Split Squats, Couch Stretch',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Ankle & Knee Bulletproofing',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Slant Board Calf Stretch',
                liftId: 'slant_board_calf_stretch',
                setScheme: '3 Sets of 60 Reps',
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
                setScheme: '2 Sets of 90 Reps',
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
        subtitle: 'Miracle Grow Pullovers, Incline Trap-3 Raises, Seated DB External Rotation',
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
        ],
      ),

      // Day 3 (Wed): Restorative Posterior Chain & Hip Capsule Flow
      DayTemplate(
        dayNumber: 3,
        title: 'Day 3: Posterior Chain & Hip Capsule Flow',
        subtitle: 'Elephant Walk, Jefferson Curls, Seated Good Mornings, 90/90 Switches, Butterfly',
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
                name: 'Seated Butterfly & PNF Adductor Stretch',
                liftId: 'seated_butterfly',
                setScheme: '3 Sets of 60 Reps',
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
        subtitle: 'Curtsy Lunges, Heel-Elevated Squats, Wall Couch Stretch',
        phases: <PhaseTemplate>[
          PhaseTemplate(
            name: 'Phase 1 - Unilateral Hip Stability',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Curtsy Lunges (Dane Miller)',
                liftId: 'curtsy_lunge',
                setScheme: '3 Sets of 10 Reps',
                fixedWeightKg: 10,
                notes: 'Cross trailing leg behind; strengthens glute medius and hip stabilizers.',
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
                setScheme: '2 Sets of 120 Reps',
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
        subtitle: 'Overhead / Z-Press, Powell Raises, Dumbbell Pullovers',
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
                setScheme: '3 Sets of 45 Reps',
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
