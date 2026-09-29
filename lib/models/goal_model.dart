enum GoalType {
  olympicLifting,
  gripAndHang,
  c25kRunning,
  mobilityAndHypertrophy,
  bodybuilding,
  custom,
}

enum SessionBlockType {
  lifting,
  hang,
  c25k,
  mobility,
  bodybuilding,
  custom,
}

class GoalMilestone {
  const new({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    this.description,
  });

  factory fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String,
      title: json['title'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      unit: json['unit'] as String,
      description: json['description'] as String?,
    );
  }

  final String id;
  final String title;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String? description;

  double get progressRatio {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  int get progressPercent => (progressRatio * 100).round();

  bool get isCompleted => currentValue >= targetValue;

  GoalMilestone copyWith({
    String? id,
    String? title,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? description,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'description': description,
    };
  }
}

class GoalScheduleConfig {
  const new({
    this.isEnabled = true,
    this.scheduledWeekdays = const <int>{
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday,
    },
    this.customSettings = const <String, dynamic>{},
  });

  factory fromJson(Map<String, dynamic> json) {
    final List<dynamic>? weekdaysRaw = json['scheduledWeekdays'] as List<dynamic>?;
    final Set<int> weekdays = weekdaysRaw != null
        ? weekdaysRaw.map((dynamic e) => e as int).toSet()
        : const <int>{DateTime.monday, DateTime.wednesday, DateTime.friday};

    return GoalScheduleConfig(
      isEnabled: json['isEnabled'] as bool? ?? true,
      scheduledWeekdays: weekdays,
      customSettings: json['customSettings'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
  }

  final bool isEnabled;
  final Set<int> scheduledWeekdays; // 1 = Monday, 7 = Sunday
  final Map<String, dynamic> customSettings;

  bool isScheduledForWeekday(int weekday) =>
      isEnabled && scheduledWeekdays.contains(weekday);

  GoalScheduleConfig copyWith({
    bool? isEnabled,
    Set<int>? scheduledWeekdays,
    Map<String, dynamic>? customSettings,
  }) {
    return GoalScheduleConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      scheduledWeekdays: scheduledWeekdays ?? this.scheduledWeekdays,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
      'scheduledWeekdays': scheduledWeekdays.toList(),
      'customSettings': customSettings,
    };
  }
}

class GoalTrack {
  const new({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconCode,
    this.scheduleConfig = const GoalScheduleConfig(),
    this.milestones = const <GoalMilestone>[],
  });

  factory fromJson(Map<String, dynamic> json) {
    final String typeStr = json['type'] as String? ?? 'custom';
    final GoalType type = GoalType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => GoalType.custom,
    );

    final List<dynamic>? rawMilestones = json['milestones'] as List<dynamic>?;
    final List<GoalMilestone> milestonesList = rawMilestones != null
        ? rawMilestones
            .map((dynamic m) => GoalMilestone.fromJson(m as Map<String, dynamic>))
            .toList()
        : const <GoalMilestone>[];

    return GoalTrack(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconCode: json['iconCode'] as int? ?? 0xe28d, // default fitness icon
      scheduleConfig: json['scheduleConfig'] != null
          ? GoalScheduleConfig.fromJson(
              json['scheduleConfig'] as Map<String, dynamic>)
          : const GoalScheduleConfig(),
      milestones: milestonesList,
    );
  }

  final String id;
  final GoalType type;
  final String title;
  final String subtitle;
  final int iconCode;
  final GoalScheduleConfig scheduleConfig;
  final List<GoalMilestone> milestones;

  bool get isEnabled => scheduleConfig.isEnabled;

  double get overallMilestoneProgress {
    if (milestones.isEmpty) return 0;
    final double total = milestones.fold(
      0,
      (sum, m) => sum + m.progressRatio,
    );
    return total / milestones.length;
  }

  GoalTrack copyWith({
    String? id,
    GoalType? type,
    String? title,
    String? subtitle,
    int? iconCode,
    GoalScheduleConfig? scheduleConfig,
    List<GoalMilestone>? milestones,
  }) {
    return GoalTrack(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconCode: iconCode ?? this.iconCode,
      scheduleConfig: scheduleConfig ?? this.scheduleConfig,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'iconCode': iconCode,
      'scheduleConfig': scheduleConfig.toJson(),
      'milestones': milestones.map((m) => m.toJson()).toList(),
    };
  }

  static List<GoalTrack> getDefaultGoals() {
    return <GoalTrack>[
      const GoalTrack(
        id: 'goal_oly_lifting',
        type: GoalType.olympicLifting,
        title: 'Olympic Weightlifting',
        subtitle: 'Wave Periodization (Snatch, C&J, Squats)',
        iconCode: 0xe28d, // Icons.fitness_center
        scheduleConfig: GoalScheduleConfig(
          scheduledWeekdays: <int>{
            DateTime.monday,
            DateTime.tuesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          },
        ),
        milestones: <GoalMilestone>[
          GoalMilestone(
            id: 'oly_total_200',
            title: 'Olympic Total 200 kg',
            targetValue: 200,
            currentValue: 155,
            unit: 'kg',
            description: 'Combined Snatch and Clean & Jerk total',
          ),
          GoalMilestone(
            id: 'snatch_90',
            title: 'Snatch 90 kg',
            targetValue: 90,
            currentValue: 70,
            unit: 'kg',
          ),
          GoalMilestone(
            id: 'cj_115',
            title: 'Clean & Jerk 115 kg',
            targetValue: 115,
            currentValue: 85,
            unit: 'kg',
          ),
        ],
      ),
      const GoalTrack(
        id: 'goal_grip_hang',
        type: GoalType.gripAndHang,
        title: 'Grip & Active Hang Mastery',
        subtitle: '5:00 Two-Hand & 2:00 Unilateral Hang Goals',
        iconCode: 0xf552, // Icons.pan_tool_outlined
        milestones: <GoalMilestone>[
          GoalMilestone(
            id: 'hang_dual_300s',
            title: '5:00 Two-Hand Hang',
            targetValue: 300,
            currentValue: 105,
            unit: 's',
            description: 'Continuous active hang on standard pull-up bar',
          ),
          GoalMilestone(
            id: 'hang_left_120s',
            title: '2:00 Left Single-Arm Hang',
            targetValue: 120,
            currentValue: 32,
            unit: 's',
            description: 'Unilateral left-hand active hang',
          ),
          GoalMilestone(
            id: 'hang_right_120s',
            title: '2:00 Right Single-Arm Hang',
            targetValue: 120,
            currentValue: 38,
            unit: 's',
            description: 'Unilateral right-hand active hang',
          ),
        ],
      ),
      const GoalTrack(
        id: 'goal_c25k',
        type: GoalType.c25kRunning,
        title: 'Couch to 5K (C25K)',
        subtitle: '9-Week Aerobic Base & 5K Continuous Run',
        iconCode: 0xe1f3, // Icons.directions_run
        scheduleConfig: GoalScheduleConfig(
          scheduledWeekdays: <int>{
            DateTime.tuesday,
            DateTime.thursday,
            DateTime.saturday,
          },
        ),
        milestones: <GoalMilestone>[
          GoalMilestone(
            id: 'c25k_continuous_5k',
            title: 'Continuous 5K (30:00 Run)',
            targetValue: 1800, // 30 minutes in seconds
            currentValue: 480, // e.g. 8 minutes achieved
            unit: 's',
            description: 'Run continuously without walking intervals',
          ),
          GoalMilestone(
            id: 'c25k_complete_curriculum',
            title: '27 Sessions Completed',
            targetValue: 27,
            currentValue: 3,
            unit: 'sessions',
            description: 'Complete all 9 weeks of the C25K protocol',
          ),
        ],
      ),
      const GoalTrack(
        id: 'goal_mobility_hypertrophy',
        type: GoalType.mobilityAndHypertrophy,
        title: 'Mobility & Hypertrophy',
        subtitle: 'ATG Joint Standards & Loaded Muscle Armor',
        iconCode: 0xe0a2, // Icons.accessibility_new / self improvement
        scheduleConfig: GoalScheduleConfig(
          scheduledWeekdays: <int>{
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          },
        ),
        milestones: <GoalMilestone>[
          GoalMilestone(
            id: 'atg_split_squat_50',
            title: 'ATG Split Squat 50% BW',
            targetValue: 50,
            currentValue: 0,
            unit: '% BW',
            description: 'Flat ground with 25% BW per hand for 5 reps',
          ),
          GoalMilestone(
            id: 'couch_stretch_120s',
            title: 'Couch Stretch 2:00',
            targetValue: 120,
            currentValue: 45,
            unit: 's',
            description: 'Shin flush to wall, butt to heel, upright torso',
          ),
          GoalMilestone(
            id: 'elephant_walk_45',
            title: 'Elephant Walk 45 Reps',
            targetValue: 45,
            currentValue: 30,
            unit: 'reps',
            description: 'Palms flat on floor, continuous alternating lockouts',
          ),
          GoalMilestone(
            id: 'jefferson_curl_50',
            title: 'Jefferson Curl 50% BW',
            targetValue: 50,
            currentValue: 0,
            unit: '% BW',
            description: 'Curled spine with barbell 4"+ below toes',
          ),
          GoalMilestone(
            id: 'seated_good_morning_50',
            title: 'Seated Good Morning 50% BW',
            targetValue: 50,
            currentValue: 0,
            unit: '% BW',
            description: 'Flat back, chest to bench with 50% BW barbell',
          ),
          GoalMilestone(
            id: 'hip_90_90_flow_180s',
            title: '90/90 Hip Transitions 3:00',
            targetValue: 180,
            currentValue: 60,
            unit: 's',
            description: 'Hands-free 90/90 internal and external hip switches',
          ),
          GoalMilestone(
            id: 'seated_butterfly_120s',
            title: 'Seated Butterfly 2:00',
            targetValue: 120,
            currentValue: 45,
            unit: 's',
            description: 'Active groin opening with knees flat to floor',
          ),
          GoalMilestone(
            id: 'hip_internal_rotation_35',
            title: 'Hip Internal Rotation 35°',
            targetValue: 35,
            currentValue: 15,
            unit: '°',
            description: '35° passive IR with 5-second active end-range lift-off hold',
          ),
          GoalMilestone(
            id: 'miracle_grow_50',
            title: 'Miracle Grow 50 lbs',
            targetValue: 50,
            currentValue: 20,
            unit: 'lbs',
            description: 'Dumbbell pullover into deep triceps extension',
          ),
          GoalMilestone(
            id: 'shoulder_ext_rot_10',
            title: 'Shoulder Ext. Rotation 10% BW',
            targetValue: 10,
            currentValue: 5,
            unit: '% BW',
            description: 'Seated DB external rotation with 3s eccentric',
          ),
          GoalMilestone(
            id: 'hammer_curls_35',
            title: 'Hammer Curls 35 lbs',
            targetValue: 35,
            currentValue: 15,
            unit: 'lbs',
            description: 'Neutral grip forearm & brachialis armor; protects medial epicondyle',
          ),
          GoalMilestone(
            id: 'wrist_curls_25',
            title: 'Wrist Curls 25 lbs',
            targetValue: 25,
            currentValue: 10,
            unit: 'lbs',
            description: "Forearm flexor & extensor resilience to resolve golfer's elbow",
          ),
          GoalMilestone(
            id: 'pullup_iso_hold_30s',
            title: 'Pull-Up Iso Hold 30s',
            targetValue: 30,
            currentValue: 10,
            unit: 's',
            description: '90° elbow isometric hold; remodels tendon collagen for medial epicondylitis',
          ),
        ],
      ),
      const GoalTrack(
        id: 'goal_bodybuilding',
        type: GoalType.bodybuilding,
        title: 'Bodybuilding (Upper / Lower + Armor)',
        subtitle: 'Trainer Winny System • 4-Day Hypertrophy & Tendon Armor',
        iconCode: 0xe28d, // Icons.fitness_center
        scheduleConfig: GoalScheduleConfig(
          scheduledWeekdays: <int>{
            DateTime.monday,
            DateTime.tuesday,
            DateTime.thursday,
            DateTime.friday,
          },
        ),
        milestones: <GoalMilestone>[
          GoalMilestone(
            id: 'bb_bench_press_100',
            title: 'Flat Bench Press 100 kg',
            targetValue: 100,
            currentValue: 70,
            unit: 'kg',
            description: 'Barbell horizontal press across full pectoral range',
          ),
          GoalMilestone(
            id: 'bb_incline_db_35',
            title: 'Incline DB Press 35 kg',
            targetValue: 35,
            currentValue: 24,
            unit: 'kg',
            description: '30-45° upper chest clavicular fibers',
          ),
          GoalMilestone(
            id: 'bb_front_squat_120',
            title: 'Barbell Front Squat 120 kg',
            targetValue: 120,
            currentValue: 85,
            unit: 'kg',
            description:
                'Upright torso quad isolation with clean or cross-arm rack',
          ),
          GoalMilestone(
            id: 'bb_romanian_deadlift_120',
            title: 'Romanian Deadlift 120 kg',
            targetValue: 120,
            currentValue: 80,
            unit: 'kg',
            description: 'Loaded hip hinge for stretch-mediated hamstring growth',
          ),
          GoalMilestone(
            id: 'bb_lat_pulldown_85',
            title: 'Lat Pulldown 85 kg',
            targetValue: 85,
            currentValue: 60,
            unit: 'kg',
            description: 'Wide grip vertical pull for lat flare and V-taper',
          ),
          GoalMilestone(
            id: 'bb_overhead_press_60',
            title: 'Overhead Press 60 kg',
            targetValue: 60,
            currentValue: 45,
            unit: 'kg',
            description: 'Strict vertical barbell press for shoulder mass',
          ),
          GoalMilestone(
            id: 'bb_barbell_curl_45',
            title: 'Barbell Bicep Curl 45 kg',
            targetValue: 45,
            currentValue: 30,
            unit: 'kg',
            description: 'Supinated bicep brachii isolation',
          ),
          GoalMilestone(
            id: 'bb_hammer_curl_20',
            title: 'DB Hammer Curls 20 kg',
            targetValue: 20,
            currentValue: 14,
            unit: 'kg',
            description: 'Neutral grip brachialis and forearm density',
          ),
          GoalMilestone(
            id: 'bb_tricep_pushdown_40',
            title: 'Cable Triceps Pushdown 40 kg',
            targetValue: 40,
            currentValue: 28,
            unit: 'kg',
            description: 'Lateral head tricep horseshoe isolation',
          ),
          GoalMilestone(
            id: 'bb_overhead_tricep_35',
            title: 'Overhead Tricep Ext 35 kg',
            targetValue: 35,
            currentValue: 22,
            unit: 'kg',
            description: 'Long head overhead tricep stretch',
          ),
          GoalMilestone(
            id: 'bb_lateral_raise_16',
            title: 'DB Lateral Raises 16 kg',
            targetValue: 16,
            currentValue: 10,
            unit: 'kg',
            description: 'Strict lateral deltoid isolation for 3D shoulders',
          ),
          GoalMilestone(
            id: 'bb_leg_extension_70',
            title: 'Leg Extension 70 kg',
            targetValue: 70,
            currentValue: 45,
            unit: 'kg',
            description: 'Terminal knee extension rectus femoris pump',
          ),
          GoalMilestone(
            id: 'bb_hamstring_curl_60',
            title: 'Hamstring Leg Curl 60 kg',
            targetValue: 60,
            currentValue: 40,
            unit: 'kg',
            description: 'Isolated knee flexion for hamstring bellies',
          ),
          GoalMilestone(
            id: 'bb_standing_calf_100',
            title: 'Standing Calf Raise 100 kg',
            targetValue: 100,
            currentValue: 65,
            unit: 'kg',
            description: 'Full ankle dorsiflexion gastrocnemius stretch',
          ),
          GoalMilestone(
            id: 'bb_cable_crunch_50',
            title: 'Kneeling Cable Crunch 50 kg',
            targetValue: 50,
            currentValue: 35,
            unit: 'kg',
            description: 'Loaded spinal flexion for thick rectus abdominis',
          ),
          GoalMilestone(
            id: 'bb_barbell_wrist_curls_25',
            title: 'Barbell Wrist Curls 25 kg',
            targetValue: 25,
            currentValue: 15,
            unit: 'kg',
            description: "Forearm flexor thickness & tendon armor for golfer's elbow",
          ),
          GoalMilestone(
            id: 'bb_banded_hip_rotations_20',
            title: 'Banded Hip Rotations 20 Reps',
            targetValue: 20,
            currentValue: 15,
            unit: 'reps',
            description: 'Internal rotation primer for hip capsule depth',
          ),
          GoalMilestone(
            id: 'bb_elephant_walks_45',
            title: 'Elephant Walks 45 Reps',
            targetValue: 45,
            currentValue: 30,
            unit: 'reps',
            description: 'Continuous alternating knee lockouts with palms on floor',
          ),
          GoalMilestone(
            id: 'bb_jefferson_curls_40',
            title: 'Jefferson Curl 40 kg',
            targetValue: 40,
            currentValue: 20,
            unit: 'kg',
            description: 'Loaded segmental spinal flexion below toes for disc resilience',
          ),
          GoalMilestone(
            id: 'bb_couch_stretch_90s',
            title: 'Couch Stretch 90s',
            targetValue: 90,
            currentValue: 45,
            unit: 's',
            description: 'Shin flush to wall, upright torso, full glute squeeze per side',
          ),
          GoalMilestone(
            id: 'bb_landmine_rotations_25',
            title: 'Landmine Rotation 25 kg',
            targetValue: 25,
            currentValue: 15,
            unit: 'kg',
            description: 'Controlled transverse rainbow arc with hip pivot per side',
          ),
          GoalMilestone(
            id: 'bb_pallof_press_25',
            title: 'Cable Pallof Press 25 kg',
            targetValue: 25,
            currentValue: 15,
            unit: 'kg',
            description: 'Strict 2s lockout hold against rotational pull per side',
          ),
          GoalMilestone(
            id: 'bb_ab_wheel_rollout_15',
            title: 'Ab Wheel Rollout 15 Reps',
            targetValue: 15,
            currentValue: 8,
            unit: 'reps',
            description: 'Full-range kneeling rollout with zero lumbar hyperextension',
          ),
          GoalMilestone(
            id: 'bb_bulgarian_split_squat_30',
            title: 'Bulgarian Split Squat 30 kg',
            targetValue: 30,
            currentValue: 18,
            unit: 'kg',
            description: 'Rear foot elevated dumbbells 8-10 strict reps per leg',
          ),
          GoalMilestone(
            id: 'bb_single_leg_rdl_24',
            title: 'Free Single-Leg RDL 24 kg',
            targetValue: 24,
            currentValue: 14,
            unit: 'kg',
            description: 'Suspended pendulum single-leg hinge with square pelvis per leg',
          ),
        ],
      ),
    ];
  }
}

class ComposedSessionBlock {
  const new({
    required this.id,
    required this.goalId,
    required this.type,
    required this.title,
    required this.subtitle,
    this.estimatedMinutes = 20,
    this.isCompleted = false,
    this.completedAt,
    this.data = const <String, dynamic>{},
  });

  factory fromJson(Map<String, dynamic> json) {
    final String typeStr = json['type'] as String? ?? 'custom';
    final SessionBlockType type = SessionBlockType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SessionBlockType.custom,
    );

    return ComposedSessionBlock(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      type: type,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 20,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  final String id;
  final String goalId;
  final SessionBlockType type;
  final String title;
  final String subtitle;
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final Map<String, dynamic> data;

  ComposedSessionBlock copyWith({
    String? id,
    String? goalId,
    SessionBlockType? type,
    String? title,
    String? subtitle,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    Map<String, dynamic>? data,
  }) {
    return ComposedSessionBlock(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'goalId': goalId,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'estimatedMinutes': estimatedMinutes,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'data': data,
    };
  }
}

class DailySessionPlan {
  const new({
    required this.date,
    required this.blocks,
  });

  factory fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawBlocks = json['blocks'] as List<dynamic>?;
    final List<ComposedSessionBlock> blockList = rawBlocks != null
        ? rawBlocks
            .map((dynamic b) =>
                ComposedSessionBlock.fromJson(b as Map<String, dynamic>))
            .toList()
        : const <ComposedSessionBlock>[];

    return DailySessionPlan(
      date: DateTime.parse(json['date'] as String),
      blocks: blockList,
    );
  }

  final DateTime date;
  final List<ComposedSessionBlock> blocks;

  bool get isFullyCompleted =>
      blocks.isNotEmpty && blocks.every((b) => b.isCompleted);

  int get completedBlockCount => blocks.where((b) => b.isCompleted).length;

  int get totalBlockCount => blocks.length;

  double get completionProgress =>
      totalBlockCount == 0 ? 0.0 : completedBlockCount / totalBlockCount;

  int get totalEstimatedMinutes =>
      blocks.fold(0, (sum, b) => sum + b.estimatedMinutes);

  DailySessionPlan copyWith({
    DateTime? date,
    List<ComposedSessionBlock>? blocks,
  }) {
    return DailySessionPlan(
      date: date ?? this.date,
      blocks: blocks ?? this.blocks,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }
}
