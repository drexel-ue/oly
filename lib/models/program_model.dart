class ExerciseTemplate {
  ExerciseTemplate({
    required this.name,
    required this.liftId,
    required this.setScheme,
    this.weekPercentages,
    this.anchorLiftId,
    this.fixedPercentage,
    this.weeklyWeightIncrementKg,
    this.notes,
  });

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      name: json['name'] as String,
      liftId: json['liftId'] as String,
      setScheme: json['setScheme'] as String,
      weekPercentages: (json['weekPercentages'] as Map<String, dynamic>?)?.map(
        (String k, dynamic v) => MapEntry<int, double>(int.parse(k), (v as num).toDouble()),
      ),
      anchorLiftId: json['anchorLiftId'] as String?,
      fixedPercentage: (json['fixedPercentage'] as num?)?.toDouble(),
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
  weeklyWeightIncrementKg; // Weekly progressive load (e.g. 2.5kg / ~5-10lbs)
  final String? notes;

  // Calculate suggested working weight for a specific week given current 1RMs map
  double calculateTargetWeight({
    required int week,
    required Map<String, double> currentMaxes,
  }) {
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
        (int k, double v) => MapEntry<String, double>(k.toString(), v),
      ),
      'anchorLiftId': anchorLiftId,
      'fixedPercentage': fixedPercentage,
      'weeklyWeightIncrementKg': weeklyWeightIncrementKg,
      'notes': notes,
    };
  }
}

class PhaseTemplate {
  PhaseTemplate({required this.name, required this.exercises});

  factory PhaseTemplate.fromJson(Map<String, dynamic> json) {
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
      'exercises': exercises.map((ExerciseTemplate e) => e.toJson()).toList(),
    };
  }
}

class DayTemplate {
  DayTemplate({
    required this.dayNumber,
    required this.title,
    required this.subtitle,
    required this.phases,
    this.isActiveRecovery = false,
  });

  factory DayTemplate.fromJson(Map<String, dynamic> json) {
    return DayTemplate(
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      phases: (json['phases'] as List<dynamic>)
          .map((dynamic e) => PhaseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActiveRecovery: json['isActiveRecovery'] as bool? ?? false,
    );
  }
  final int dayNumber;
  final String title;
  final String subtitle;
  final List<PhaseTemplate> phases;
  final bool isActiveRecovery;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dayNumber': dayNumber,
      'title': title,
      'subtitle': subtitle,
      'phases': phases.map((PhaseTemplate e) => e.toJson()).toList(),
      'isActiveRecovery': isActiveRecovery,
    };
  }
}

class ProgramCycle {
  ProgramCycle({
    this.currentCycle = 1,
    this.currentWeek = 1,
    this.currentDay = 1,
    List<String>? completedSessionIds,
  }) : completedSessionIds = completedSessionIds ?? <String>[];

  factory ProgramCycle.fromJson(Map<String, dynamic> json) {
    return ProgramCycle(
      currentCycle: json['currentCycle'] as int? ?? 1,
      currentWeek: json['currentWeek'] as int? ?? 1,
      currentDay: json['currentDay'] as int? ?? 1,
      completedSessionIds:
          (json['completedSessionIds'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
    );
  }
  int currentCycle;
  int currentWeek; // 1..4 = training weeks, 5 = 1RM Retest Week
  int currentDay; // 1..4
  List<String> completedSessionIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentCycle': currentCycle,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'completedSessionIds': completedSessionIds,
    };
  }

  static List<DayTemplate> getBuiltInProgram({int week = 1}) {
    // Helper active recovery template reused for Day 2, Day 4, and Day 6
    DayTemplate createActiveRecoveryDay(int dayNum) {
      return DayTemplate(
        dayNumber: dayNum,
        title: 'Active Recovery Day',
        subtitle:
            'Kettlebell Mile (10%->30% BW), Cable Crunches (3x8), Dragon Flags (3x5), GHD Extensions (3x12), Hypertrophy (Arms & Leg Extensions)',
        isActiveRecovery: true,
        phases: <PhaseTemplate>[
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
                name: 'Dumbbell Bicep Curls',
                liftId: 'db_bicep_curls',
                setScheme: '3 Sets of 10 Reps',
                weeklyWeightIncrementKg: 2.5,
                notes: 'Strict form; track weight.',
              ),
              ExerciseTemplate(
                name: 'Overhead Dumbbell Tricep Extension',
                liftId: 'overhead_tricep_ext',
                setScheme: '3 Sets of 10 Reps',
                weeklyWeightIncrementKg: 2.5,
                notes: 'Full elbow extension; track weight.',
              ),
              ExerciseTemplate(
                name: 'Seated Machine Leg Extensions',
                liftId: 'seated_leg_extensions',
                setScheme: '3 Sets of 12 Reps',
                weeklyWeightIncrementKg: 2.5,
                notes:
                    'Knee extension machine for quad & patellar tendon resilience; track weight.',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Mobility & Joint Health Flow',
            exercises: <ExerciseTemplate>[
              ExerciseTemplate(
                name: 'Thoracic Spine + Ankle & Hip Mobility Flow',
                liftId: 'mobility',
                setScheme: '10-15 Minutes Flow Routine',
                notes: 'Thoracic extensions, ankle dorsiflexion, hip openers',
              ),
            ],
          ),
        ],
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
                  fixedPercentage: 100.0,
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
                  fixedPercentage: 70.0,
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
                  fixedPercentage: 100.0,
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
                  fixedPercentage: 70.0,
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
                  fixedPercentage: 100.0,
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
                  fixedPercentage: 75.0,
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
                  fixedPercentage: 90.0,
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
                  fixedPercentage: 75.0,
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
                  fixedPercentage: 95.0,
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
