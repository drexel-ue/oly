class ExerciseTemplate {
  final String name;
  final String liftId; // e.g. 'snatch', 'power_snatch', 'back_squat'
  final String setScheme; // e.g. '4 Sets of 2 Reps'
  final Map<int, double>? weekPercentages; // Week number (1..4) -> % of 1RM (e.g. {1: 65, 2: 70, 3: 75, 4: 70})
  final String? anchorLiftId; // Override reference 1RM (e.g. 'clean_and_jerk' for Front Squat)
  final double? fixedPercentage; // Fixed percentage for all weeks (e.g. 90% for Snatch Pull)
  final double? weeklyWeightIncrementKg; // Weekly progressive load (e.g. 2.5kg / ~5-10lbs)
  final String? notes;

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

  // Calculate suggested working weight for a specific week given current 1RMs map
  double calculateTargetWeight({
    required int week,
    required Map<String, double> currentMaxes,
  }) {
    final refLiftId = anchorLiftId ?? liftId;
    final base1RM = currentMaxes[refLiftId] ?? 100.0;

    if (weekPercentages != null && weekPercentages!.containsKey(week)) {
      final pct = weekPercentages![week]!;
      return (base1RM * (pct / 100.0));
    }

    if (fixedPercentage != null) {
      return (base1RM * (fixedPercentage! / 100.0));
    }

    if (weeklyWeightIncrementKg != null) {
      // Base calculation on 60% baseline + weekly increment
      final baseWeight = base1RM * 0.60;
      return baseWeight + ((week - 1) * weeklyWeightIncrementKg!);
    }

    return base1RM * 0.70; // Fallback default
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'liftId': liftId,
      'setScheme': setScheme,
      'weekPercentages': weekPercentages?.map((k, v) => MapEntry(k.toString(), v)),
      'anchorLiftId': anchorLiftId,
      'fixedPercentage': fixedPercentage,
      'weeklyWeightIncrementKg': weeklyWeightIncrementKg,
      'notes': notes,
    };
  }

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) {
    return ExerciseTemplate(
      name: json['name'] as String,
      liftId: json['liftId'] as String,
      setScheme: json['setScheme'] as String,
      weekPercentages: (json['weekPercentages'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      ),
      anchorLiftId: json['anchorLiftId'] as String?,
      fixedPercentage: (json['fixedPercentage'] as num?)?.toDouble(),
      weeklyWeightIncrementKg: (json['weeklyWeightIncrementKg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

class PhaseTemplate {
  final String name;
  final List<ExerciseTemplate> exercises;

  PhaseTemplate({
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory PhaseTemplate.fromJson(Map<String, dynamic> json) {
    return PhaseTemplate(
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DayTemplate {
  final int dayNumber;
  final String title;
  final String subtitle;
  final List<PhaseTemplate> phases;
  final bool isActiveRecovery;

  DayTemplate({
    required this.dayNumber,
    required this.title,
    required this.subtitle,
    required this.phases,
    this.isActiveRecovery = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'subtitle': subtitle,
      'phases': phases.map((e) => e.toJson()).toList(),
      'isActiveRecovery': isActiveRecovery,
    };
  }

  factory DayTemplate.fromJson(Map<String, dynamic> json) {
    return DayTemplate(
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      phases: (json['phases'] as List<dynamic>)
          .map((e) => PhaseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActiveRecovery: json['isActiveRecovery'] as bool? ?? false,
    );
  }
}

class ProgramCycle {
  int currentCycle;
  int currentWeek; // 1..4 = training weeks, 5 = 1RM Retest Week
  int currentDay; // 1..4
  List<String> completedSessionIds;

  ProgramCycle({
    this.currentCycle = 1,
    this.currentWeek = 1,
    this.currentDay = 1,
    List<String>? completedSessionIds,
  }) : completedSessionIds = completedSessionIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'currentCycle': currentCycle,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'completedSessionIds': completedSessionIds,
    };
  }

  factory ProgramCycle.fromJson(Map<String, dynamic> json) {
    return ProgramCycle(
      currentCycle: json['currentCycle'] as int? ?? 1,
      currentWeek: json['currentWeek'] as int? ?? 1,
      currentDay: json['currentDay'] as int? ?? 1,
      completedSessionIds: (json['completedSessionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static List<DayTemplate> getBuiltInProgram() {
    // Helper active recovery template reused for Day 2 and Day 4
    DayTemplate createActiveRecoveryDay(int dayNum) {
      return DayTemplate(
        dayNumber: dayNum,
        title: 'Active Recovery Day',
        subtitle: 'Cardio, Mobility Flow, Arms, Abs & Grip Strength',
        isActiveRecovery: true,
        phases: [
          PhaseTemplate(
            name: 'Cardio & Zone 2 Conditioning',
            exercises: [
              ExerciseTemplate(
                name: 'Ergometer Row / Bike / Intervals',
                liftId: 'cardio',
                setScheme: '15-20 Minutes @ Zone 2 Steady Pace',
                notes: 'Low intensity recovery cardio',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Mobility & Joint Health Flow',
            exercises: [
              ExerciseTemplate(
                name: 'Thoracic Spine + Ankle & Wrist Mobility',
                liftId: 'mobility',
                setScheme: '10-15 Minutes Flow Routine',
                notes: 'Thoracic extensions, ankle dorsiflexion, hip openers',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Arms & Upper Hypertrophy',
            exercises: [
              ExerciseTemplate(
                name: 'Dumbbell Bicep Curls',
                liftId: 'biceps',
                setScheme: '3 Sets of 12 Reps',
              ),
              ExerciseTemplate(
                name: 'Overhead Dumbbell Tricep Extension',
                liftId: 'triceps',
                setScheme: '3 Sets of 12 Reps',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Abs & Core Stability',
            exercises: [
              ExerciseTemplate(
                name: 'Hanging Leg Raises',
                liftId: 'abs',
                setScheme: '3 Sets of 12 Reps',
              ),
              ExerciseTemplate(
                name: 'Ab Wheel Rollout / Plank Hold',
                liftId: 'abs',
                setScheme: '3 Sets of 10 Reps / 60s Hold',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Grip Strength',
            exercises: [
              ExerciseTemplate(
                name: 'Farmer\'s Carries / Dead Hangs',
                liftId: 'grip',
                setScheme: '3 Sets of 45-60s Carries or Hangs',
              ),
              ExerciseTemplate(
                name: 'Plate Pinch Hold',
                liftId: 'grip',
                setScheme: '3 Sets of 30s Hold per Side',
              ),
            ],
          ),
        ],
      );
    }

    return [
      // STEP 1: DAY 1 (LIFT)
      DayTemplate(
        dayNumber: 1,
        title: 'Day 1: Snatch & Clean Strength',
        subtitle: 'Power Snatch + OHS, Hang Clean, Back Squat, Snatch Pull, Military Press',
        phases: [
          PhaseTemplate(
            name: 'Phase 1 - Power and Technique Development',
            exercises: [
              ExerciseTemplate(
                name: 'Power Snatch + Overhead Squat',
                liftId: 'snatch',
                setScheme: '4 Sets of 2 Reps (1 Power Snatch + 1 OHS)',
                weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
              ),
              ExerciseTemplate(
                name: 'Hang Clean',
                liftId: 'clean_and_jerk',
                setScheme: '4 Sets of 3 Reps',
                weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Strength Building',
            exercises: [
              ExerciseTemplate(
                name: 'Back Squat',
                liftId: 'back_squat',
                setScheme: '4 Sets of 6-8 Reps',
                weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Explosive Power and Pulling Strength',
            exercises: [
              ExerciseTemplate(
                name: 'Snatch Pull',
                liftId: 'snatch',
                setScheme: '3 Sets of 2 Reps',
                fixedPercentage: 90.0,
                notes: '@ 90% for all weeks',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Upper Body Development',
            exercises: [
              ExerciseTemplate(
                name: 'Military Press',
                liftId: 'military_press',
                setScheme: '3 Sets of 8 Reps',
                weeklyWeightIncrementKg: 2.5,
                notes: 'Progress 5-10lbs every week',
              ),
            ],
          ),
        ],
      ),

      // STEP 2: ACTIVE RECOVERY DAY
      createActiveRecoveryDay(2),

      // STEP 3: DAY 2 (LIFT)
      DayTemplate(
        dayNumber: 3,
        title: 'Day 2: Muscle Snatch & Block Clean',
        subtitle: 'Muscle Snatch, Block Clean, Snatch Deadlift, Push Press, Pull Ups',
        phases: [
          PhaseTemplate(
            name: 'Phase 1 - Technique and Muscle Activation',
            exercises: [
              ExerciseTemplate(
                name: 'Muscle Snatch',
                liftId: 'snatch',
                setScheme: '3 Sets of 3 Reps',
                fixedPercentage: 50.0,
                notes: '@ 50% of Snatch Max for all weeks',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Power and Explosiveness',
            exercises: [
              ExerciseTemplate(
                name: 'Block Clean',
                liftId: 'clean_and_jerk',
                setScheme: '4 Sets of 2-3 Reps',
                weekPercentages: {1: 70.0, 2: 75.0, 3: 80.0, 4: 75.0},
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Strength and Pulling Power',
            exercises: [
              ExerciseTemplate(
                name: 'Snatch Deadlift',
                liftId: 'snatch',
                setScheme: '4 Sets of 5 Reps',
                weeklyWeightIncrementKg: 2.5,
                notes: 'Challenging load, progress 5-10lbs weekly',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 4 - Upper Body Development',
            exercises: [
              ExerciseTemplate(
                name: 'Push Press',
                liftId: 'clean_and_jerk',
                setScheme: '3 Sets of 5 Reps',
                fixedPercentage: 60.0,
                weeklyWeightIncrementKg: 2.5,
                notes: '@ 60%, progress 5-10lbs every week',
              ),
              ExerciseTemplate(
                name: 'Pull Up',
                liftId: 'pull_up',
                setScheme: '3 Sets of 8 Reps',
                weeklyWeightIncrementKg: 2.5,
                notes: 'Challenging load, progress 5-10lbs weekly',
              ),
            ],
          ),
        ],
      ),

      // STEP 4: ACTIVE RECOVERY DAY
      createActiveRecoveryDay(4),

      // STEP 5: DAY 3 (LIFT)
      DayTemplate(
        dayNumber: 5,
        title: 'Day 3: Clean & Jerk Heavy & Front Squats',
        subtitle: 'Hang Snatch, Clean & Jerk, Front Squat, RDL, Lunges',
        phases: [
          PhaseTemplate(
            name: 'Phase 1 - Power and Technique Development',
            exercises: [
              ExerciseTemplate(
                name: 'Hang Snatch',
                liftId: 'snatch',
                setScheme: '4 Sets of 1 Rep',
                weekPercentages: {1: 70.0, 2: 75.0, 3: 80.0, 4: 75.0},
              ),
              ExerciseTemplate(
                name: 'Clean and Jerk',
                liftId: 'clean_and_jerk',
                setScheme: '4 Sets of 2 Reps',
                weekPercentages: {1: 70.0, 2: 75.0, 3: 80.0, 4: 75.0},
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 2 - Strength Building and Hypertrophy',
            exercises: [
              ExerciseTemplate(
                name: 'Front Squat',
                liftId: 'clean_and_jerk',
                anchorLiftId: 'clean_and_jerk',
                setScheme: '4 Sets of 3-5 Reps',
                fixedPercentage: 75.0,
                notes: '@ 75% of Clean and Jerk Max',
              ),
            ],
          ),
          PhaseTemplate(
            name: 'Phase 3 - Muscle Endurance and Stability',
            exercises: [
              ExerciseTemplate(
                name: 'Romanian Deadlift (RDL)',
                liftId: 'clean_and_jerk',
                anchorLiftId: 'clean_and_jerk',
                setScheme: '3 Sets of 6-8 Reps',
                fixedPercentage: 70.0,
                notes: '@ 70% of Clean and Jerk Max',
              ),
              ExerciseTemplate(
                name: 'Lunges',
                liftId: 'lunges',
                setScheme: '3 Sets of 8 Reps per Leg',
                weeklyWeightIncrementKg: 2.5,
                notes: 'Challenging load, progress 5-10lbs weekly',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
