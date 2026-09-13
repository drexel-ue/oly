enum GoalType {
  olympicLifting,
  gripAndHang,
  c25kRunning,
  custom,
}

enum SessionBlockType {
  lifting,
  hang,
  c25k,
  mobility,
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
