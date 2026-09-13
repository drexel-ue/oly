import 'package:uuid/uuid.dart';

enum C25kStepType {
  warmupWalk,
  jog,
  walk,
  cooldownWalk;

  String get displayName {
    switch (this) {
      case C25kStepType.warmupWalk:
        return 'Warm-Up Walk';
      case C25kStepType.jog:
        return 'Jog / Run';
      case C25kStepType.walk:
        return 'Recovery Walk';
      case C25kStepType.cooldownWalk:
        return 'Cool-Down Walk';
    }
  }

  bool get isRunning => this == C25kStepType.jog;
}

class C25kIntervalStep {
  const new({
    required this.type,
    required this.durationSeconds,
    this.label,
  });

  factory fromJson(Map<String, dynamic> json) {
    final String typeStr = json['type'] as String? ?? 'walk';
    final C25kStepType type = C25kStepType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => C25kStepType.walk,
    );
    return C25kIntervalStep(
      type: type,
      durationSeconds: json['durationSeconds'] as int? ?? 60,
      label: json['label'] as String?,
    );
  }

  final C25kStepType type;
  final int durationSeconds;
  final String? label;

  String get formattedDuration {
    final int mins = durationSeconds ~/ 60;
    final int secs = durationSeconds % 60;
    if (mins > 0 && secs > 0) return '${mins}m ${secs}s';
    if (mins > 0) return '$mins min';
    return '$secs sec';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'durationSeconds': durationSeconds,
      'label': label,
    };
  }
}

class C25kWorkout {
  const new({
    required this.week,
    required this.day,
    required this.title,
    required this.description,
    required this.steps,
  });

  final int week;
  final int day;
  final String title;
  final String description;
  final List<C25kIntervalStep> steps;

  int get totalDurationSeconds =>
      steps.fold(0, (sum, s) => sum + s.durationSeconds);

  int get totalJogSeconds => steps
      .where((s) => s.type == C25kStepType.jog)
      .fold(0, (sum, s) => sum + s.durationSeconds);

  int get totalWalkSeconds => steps
      .where((s) => s.type != C25kStepType.jog)
      .fold(0, (sum, s) => sum + s.durationSeconds);

  int get jogIntervalCount =>
      steps.where((s) => s.type == C25kStepType.jog).length;

  String get formattedTotalDuration {
    final int minutes = totalDurationSeconds ~/ 60;
    final int seconds = totalDurationSeconds % 60;
    if (seconds == 0) return '$minutes mins';
    return '$minutes min $seconds sec';
  }

  double estimateDistanceKm({double jogSpeedKmh = 9.0, double walkSpeedKmh = 5.0}) {
    final double jogHours = totalJogSeconds / 3600.0;
    final double walkHours = totalWalkSeconds / 3600.0;
    return (jogHours * jogSpeedKmh) + (walkHours * walkSpeedKmh);
  }
}

class C25kSessionLog {
  new({
    required this.id,
    required this.date,
    required this.week,
    required this.day,
    required this.completedJogSeconds,
    required this.completedWalkSeconds,
    required this.estimatedDistanceKm,
    required this.netCaloriesBurned,
    this.isCompleted = true,
    this.notes,
  });

  factory create({
    required int week,
    required int day,
    required int completedJogSeconds,
    required int completedWalkSeconds,
    required double estimatedDistanceKm,
    required double netCaloriesBurned,
    bool isCompleted = true,
    String? notes,
  }) {
    return C25kSessionLog(
      id: const Uuid().v4(),
      date: DateTime.now(),
      week: week,
      day: day,
      completedJogSeconds: completedJogSeconds,
      completedWalkSeconds: completedWalkSeconds,
      estimatedDistanceKm: estimatedDistanceKm,
      netCaloriesBurned: netCaloriesBurned,
      isCompleted: isCompleted,
      notes: notes,
    );
  }

  factory fromJson(Map<String, dynamic> json) {
    return C25kSessionLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      week: json['week'] as int? ?? 1,
      day: json['day'] as int? ?? 1,
      completedJogSeconds: json['completedJogSeconds'] as int? ?? 0,
      completedWalkSeconds: json['completedWalkSeconds'] as int? ?? 0,
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble() ?? 0.0,
      netCaloriesBurned: (json['netCaloriesBurned'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int week;
  final int day;
  final int completedJogSeconds;
  final int completedWalkSeconds;
  final double estimatedDistanceKm;
  final double netCaloriesBurned;
  final bool isCompleted;
  final String? notes;

  int get totalDurationSeconds => completedJogSeconds + completedWalkSeconds;

  String get formattedDuration {
    final int minutes = totalDurationSeconds ~/ 60;
    final int seconds = totalDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'week': week,
      'day': day,
      'completedJogSeconds': completedJogSeconds,
      'completedWalkSeconds': completedWalkSeconds,
      'estimatedDistanceKm': estimatedDistanceKm,
      'netCaloriesBurned': netCaloriesBurned,
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }
}

class C25kCurriculum {
  static List<C25kWorkout> getAllWorkouts() {
    final List<C25kWorkout> list = <C25kWorkout>[];

    // WEEK 1: 5m walk, 8x (60s jog / 90s walk), 5m walk
    for (int day = 1; day <= 3; day++) {
      final List<C25kIntervalStep> steps = <C25kIntervalStep>[
        const C25kIntervalStep(
          type: C25kStepType.warmupWalk,
          durationSeconds: 300,
          label: '5 Min Warm-Up Walk',
        ),
      ];
      for (int i = 1; i <= 8; i++) {
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.jog,
            durationSeconds: 60,
            label: 'Jog (Interval $i/8)',
          ),
        );
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.walk,
            durationSeconds: 90,
            label: 'Recovery Walk ($i/8)',
          ),
        );
      }
      steps.add(
        const C25kIntervalStep(
          type: C25kStepType.cooldownWalk,
          durationSeconds: 300,
          label: '5 Min Cool-Down Walk',
        ),
      );
      list.add(
        C25kWorkout(
          week: 1,
          day: day,
          title: 'Week 1 Day $day',
          description: '5m Walk • 8x (60s Jog / 90s Walk) • 5m Walk',
          steps: steps,
        ),
      );
    }

    // WEEK 2: 5m walk, 6x (90s jog / 2m walk), 5m walk
    for (int day = 1; day <= 3; day++) {
      final List<C25kIntervalStep> steps = <C25kIntervalStep>[
        const C25kIntervalStep(
          type: C25kStepType.warmupWalk,
          durationSeconds: 300,
          label: '5 Min Warm-Up Walk',
        ),
      ];
      for (int i = 1; i <= 6; i++) {
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.jog,
            durationSeconds: 90,
            label: 'Jog (Interval $i/6)',
          ),
        );
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.walk,
            durationSeconds: 120,
            label: 'Recovery Walk ($i/6)',
          ),
        );
      }
      steps.add(
        const C25kIntervalStep(
          type: C25kStepType.cooldownWalk,
          durationSeconds: 300,
          label: '5 Min Cool-Down Walk',
        ),
      );
      list.add(
        C25kWorkout(
          week: 2,
          day: day,
          title: 'Week 2 Day $day',
          description: '5m Walk • 6x (90s Jog / 2m Walk) • 5m Walk',
          steps: steps,
        ),
      );
    }

    // WEEK 3: 5m walk, 2x (90s jog / 90s walk / 3m jog / 3m walk), 5m walk
    for (int day = 1; day <= 3; day++) {
      final List<C25kIntervalStep> steps = <C25kIntervalStep>[
        const C25kIntervalStep(
          type: C25kStepType.warmupWalk,
          durationSeconds: 300,
          label: '5 Min Warm-Up Walk',
        ),
      ];
      for (int i = 1; i <= 2; i++) {
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.jog,
            durationSeconds: 90,
            label: 'Jog 90s (Set $i)',
          ),
        );
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.walk,
            durationSeconds: 90,
            label: 'Walk 90s (Set $i)',
          ),
        );
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.jog,
            durationSeconds: 180,
            label: 'Jog 3 Mins (Set $i)',
          ),
        );
        steps.add(
          C25kIntervalStep(
            type: C25kStepType.walk,
            durationSeconds: 180,
            label: 'Walk 3 Mins (Set $i)',
          ),
        );
      }
      steps.add(
        const C25kIntervalStep(
          type: C25kStepType.cooldownWalk,
          durationSeconds: 300,
          label: '5 Min Cool-Down Walk',
        ),
      );
      list.add(
        C25kWorkout(
          week: 3,
          day: day,
          title: 'Week 3 Day $day',
          description: '5m Walk • 2x (90s Jog/90s Walk/3m Jog/3m Walk) • 5m Walk',
          steps: steps,
        ),
      );
    }

    // WEEK 4: 5m walk, 3m jog / 90s walk / 5m jog / 2.5m walk / 3m jog / 90s walk / 5m jog, 5m walk
    for (int day = 1; day <= 3; day++) {
      final List<C25kIntervalStep> steps = <C25kIntervalStep>[
        const C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
        const C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 180, label: 'Jog 3 Mins'),
        const C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 90, label: 'Walk 90s'),
        const C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins'),
        const C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 150, label: 'Walk 2.5 Mins'),
        const C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 180, label: 'Jog 3 Mins'),
        const C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 90, label: 'Walk 90s'),
        const C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins'),
        const C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
      ];
      list.add(
        C25kWorkout(
          week: 4,
          day: day,
          title: 'Week 4 Day $day',
          description: '5m Walk • 3m Jog / 90s Walk / 5m Jog / 2.5m Walk / 3m Jog / 90s Walk / 5m Jog • 5m Walk',
          steps: steps,
        ),
      );
    }

    // WEEK 5:
    // Day 1: 5m walk, 3x (5m jog / 3m walk), 5m walk
    list.add(
      const C25kWorkout(
        week: 5,
        day: 1,
        title: 'Week 5 Day 1',
        description: '5m Walk • 3x (5m Jog / 3m Walk) • 5m Walk',
        steps: <C25kIntervalStep>[
          C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins (1/3)'),
          C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 180, label: 'Walk 3 Mins (1/3)'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins (2/3)'),
          C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 180, label: 'Walk 3 Mins (2/3)'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins (3/3)'),
          C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
        ],
      ),
    );

    // Day 2: 5m walk, 2x (8m jog / 5m walk), 5m walk
    list.add(
      const C25kWorkout(
        week: 5,
        day: 2,
        title: 'Week 5 Day 2',
        description: '5m Walk • 2x (8m Jog / 5m Walk) • 5m Walk',
        steps: <C25kIntervalStep>[
          C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 480, label: 'Jog 8 Mins (1/2)'),
          C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 300, label: 'Walk 5 Mins'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 480, label: 'Jog 8 Mins (2/2)'),
          C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
        ],
      ),
    );

    // Day 3: 5m walk, 20m continuous jog, 5m walk (Milestone!)
    list.add(
      const C25kWorkout(
        week: 5,
        day: 3,
        title: 'Week 5 Day 3 (Milestone)',
        description: '5m Walk • 20 Mins Continuous Jog • 5m Walk',
        steps: <C25kIntervalStep>[
          C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 1200, label: 'Continuous Jog (20 Mins)'),
          C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
        ],
      ),
    );

    // WEEK 6:
    // Day 1: 5m walk, 5m jog / 3m walk / 8m jog / 3m walk / 5m jog, 5m walk
    list.add(
      const C25kWorkout(
        week: 6,
        day: 1,
        title: 'Week 6 Day 1',
        description: '5m Walk • 5m Jog / 3m Walk / 8m Jog / 3m Walk / 5m Jog • 5m Walk',
        steps: <C25kIntervalStep>[
          C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins'),
          C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 180, label: 'Walk 3 Mins'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 480, label: 'Jog 8 Mins'),
          C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 180, label: 'Walk 3 Mins'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 300, label: 'Jog 5 Mins'),
          C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
        ],
      ),
    );

    // Day 2: 5m walk, 2x (10m jog / 3m walk), 5m walk
    list.add(
      const C25kWorkout(
        week: 6,
        day: 2,
        title: 'Week 6 Day 2',
        description: '5m Walk • 2x (10m Jog / 3m Walk) • 5m Walk',
        steps: <C25kIntervalStep>[
          C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 600, label: 'Jog 10 Mins (1/2)'),
          C25kIntervalStep(type: C25kStepType.walk, durationSeconds: 180, label: 'Walk 3 Mins'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 600, label: 'Jog 10 Mins (2/2)'),
          C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
        ],
      ),
    );

    // Day 3: 5m walk, 22m continuous jog, 5m walk
    list.add(
      const C25kWorkout(
        week: 6,
        day: 3,
        title: 'Week 6 Day 3',
        description: '5m Walk • 22 Mins Continuous Jog • 5m Walk',
        steps: <C25kIntervalStep>[
          C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
          C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 1320, label: 'Continuous Jog (22 Mins)'),
          C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
        ],
      ),
    );

    // WEEK 7: 5m walk, 25m continuous jog, 5m walk (Days 1, 2, 3)
    for (int day = 1; day <= 3; day++) {
      list.add(
        C25kWorkout(
          week: 7,
          day: day,
          title: 'Week 7 Day $day',
          description: '5m Walk • 25 Mins Continuous Jog • 5m Walk',
          steps: const <C25kIntervalStep>[
            C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
            C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 1500, label: 'Continuous Jog (25 Mins)'),
            C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
          ],
        ),
      );
    }

    // WEEK 8: 5m walk, 28m continuous jog, 5m walk (Days 1, 2, 3)
    for (int day = 1; day <= 3; day++) {
      list.add(
        C25kWorkout(
          week: 8,
          day: day,
          title: 'Week 8 Day $day',
          description: '5m Walk • 28 Mins Continuous Jog • 5m Walk',
          steps: const <C25kIntervalStep>[
            C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
            C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 1680, label: 'Continuous Jog (28 Mins)'),
            C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
          ],
        ),
      );
    }

    // WEEK 9: 5m walk, 30m continuous jog (5K Milestone!), 5m walk (Days 1, 2, 3)
    for (int day = 1; day <= 3; day++) {
      list.add(
        C25kWorkout(
          week: 9,
          day: day,
          title: 'Week 9 Day $day (5K Graduation)',
          description: '5m Walk • 30 Mins Continuous Jog (5K!) • 5m Walk',
          steps: const <C25kIntervalStep>[
            C25kIntervalStep(type: C25kStepType.warmupWalk, durationSeconds: 300, label: '5 Min Warm-Up Walk'),
            C25kIntervalStep(type: C25kStepType.jog, durationSeconds: 1800, label: 'Continuous Jog 30 Mins (5K)'),
            C25kIntervalStep(type: C25kStepType.cooldownWalk, durationSeconds: 300, label: '5 Min Cool-Down Walk'),
          ],
        ),
      );
    }

    return list;
  }

  static C25kWorkout getWorkout(int week, int day) {
    final List<C25kWorkout> all = getAllWorkouts();
    return all.firstWhere(
      (w) => w.week == week && w.day == day,
      orElse: () => all.first,
    );
  }
}
