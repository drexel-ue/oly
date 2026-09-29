import 'package:uuid/uuid.dart';

/// Type of Grease the Groove movement
enum GtgExerciseType {
  activeHang('active_hang', 'Active Scapular Hang (Micro-Bend)'),
  pullUp('pull_up', 'Submaximal Strict Pull-Up');

  new(this.id, this.displayName);
  final String id;
  final String displayName;

  static GtgExerciseType fromId(String? id) {
    return GtgExerciseType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => GtgExerciseType.activeHang,
    );
  }
}

/// Configuration settings for the Grease the Groove protocol
class GtgConfig {
  const new({
    this.pullUpMax = 10,
    this.targetPullUpReps = 4,
    this.targetHangSeconds = 30,
    this.dailyPullUpGoal = 35,
    this.dailyHangSecondsGoal = 180,
    this.intervalMinutes = 90,
    this.startHour = 9,
    this.startMinute = 0,
    this.endHour = 18,
    this.endMinute = 0,
    this.remindersEnabled = true,
    this.microElbowBendDefault = true,
    this.activeScapulaDefault = true,
  });

  factory fromJson(Map<String, dynamic> json) {
    return GtgConfig(
      pullUpMax: json['pullUpMax'] as int? ?? 10,
      targetPullUpReps: json['targetPullUpReps'] as int? ?? 4,
      targetHangSeconds: json['targetHangSeconds'] as int? ?? 30,
      dailyPullUpGoal: json['dailyPullUpGoal'] as int? ?? 35,
      dailyHangSecondsGoal: json['dailyHangSecondsGoal'] as int? ?? 180,
      intervalMinutes: json['intervalMinutes'] as int? ?? 90,
      startHour: json['startHour'] as int? ?? 9,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 18,
      endMinute: json['endMinute'] as int? ?? 0,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      microElbowBendDefault: json['microElbowBendDefault'] as bool? ?? true,
      activeScapulaDefault: json['activeScapulaDefault'] as bool? ?? true,
    );
  }

  final int pullUpMax;
  final int targetPullUpReps;
  final int targetHangSeconds;
  final int dailyPullUpGoal;
  final int dailyHangSecondsGoal;
  final int intervalMinutes;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool remindersEnabled;
  final bool microElbowBendDefault;
  final bool activeScapulaDefault;

  /// Optimal submaximal pull-up reps calculated as 40-50% of 1-set max
  int get calculatedSubmaxReps => (pullUpMax * 0.45).clamp(1, 30).round();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pullUpMax': pullUpMax,
        'targetPullUpReps': targetPullUpReps,
        'targetHangSeconds': targetHangSeconds,
        'dailyPullUpGoal': dailyPullUpGoal,
        'dailyHangSecondsGoal': dailyHangSecondsGoal,
        'intervalMinutes': intervalMinutes,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'remindersEnabled': remindersEnabled,
        'microElbowBendDefault': microElbowBendDefault,
        'activeScapulaDefault': activeScapulaDefault,
      };

  GtgConfig copyWith({
    int? pullUpMax,
    int? targetPullUpReps,
    int? targetHangSeconds,
    int? dailyPullUpGoal,
    int? dailyHangSecondsGoal,
    int? intervalMinutes,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? remindersEnabled,
    bool? microElbowBendDefault,
    bool? activeScapulaDefault,
  }) {
    return GtgConfig(
      pullUpMax: pullUpMax ?? this.pullUpMax,
      targetPullUpReps: targetPullUpReps ?? this.targetPullUpReps,
      targetHangSeconds: targetHangSeconds ?? this.targetHangSeconds,
      dailyPullUpGoal: dailyPullUpGoal ?? this.dailyPullUpGoal,
      dailyHangSecondsGoal: dailyHangSecondsGoal ?? this.dailyHangSecondsGoal,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      microElbowBendDefault:
          microElbowBendDefault ?? this.microElbowBendDefault,
      activeScapulaDefault:
          activeScapulaDefault ?? this.activeScapulaDefault,
    );
  }
}

/// An individual completed Grease the Groove set entry
class GtgSetLog {
  const new({
    required this.id,
    required this.timestamp,
    required this.type,
    this.reps = 0,
    this.durationSeconds = 0,
    this.microElbowBendEngaged = true,
    this.scapulaRetracted = true,
    this.notes,
  });

  factory create({
    required GtgExerciseType type,
    int reps = 0,
    int durationSeconds = 0,
    bool microElbowBendEngaged = true,
    bool scapulaRetracted = true,
    String? notes,
  }) {
    return GtgSetLog(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      type: type,
      reps: reps,
      durationSeconds: durationSeconds,
      microElbowBendEngaged: microElbowBendEngaged,
      scapulaRetracted: scapulaRetracted,
      notes: notes,
    );
  }

  factory fromJson(Map<String, dynamic> json) {
    return GtgSetLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: GtgExerciseType.fromId(json['type'] as String?),
      reps: json['reps'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      microElbowBendEngaged: json['microElbowBendEngaged'] as bool? ?? true,
      scapulaRetracted: json['scapulaRetracted'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime timestamp;
  final GtgExerciseType type;
  final int reps;
  final int durationSeconds;
  final bool microElbowBendEngaged;
  final bool scapulaRetracted;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.id,
        'reps': reps,
        'durationSeconds': durationSeconds,
        'microElbowBendEngaged': microElbowBendEngaged,
        'scapulaRetracted': scapulaRetracted,
        'notes': notes,
      };
}
