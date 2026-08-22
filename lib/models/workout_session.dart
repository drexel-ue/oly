class CompletedSet {
  final int setIndex;
  final double weight; // KG
  final int reps;
  final double? rpe;
  final bool isCompleted;
  final DateTime? completedAt;

  CompletedSet({
    required this.setIndex,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isCompleted = true,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'setIndex': setIndex,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory CompletedSet.fromJson(Map<String, dynamic> json) {
    return CompletedSet(
      setIndex: json['setIndex'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      rpe: json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
      isCompleted: json['isCompleted'] as bool? ?? true,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class ExerciseLog {
  final String exerciseName;
  final String liftId;
  final List<CompletedSet> sets;

  ExerciseLog({
    required this.exerciseName,
    required this.liftId,
    required this.sets,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'liftId': liftId,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseName: json['exerciseName'] as String,
      liftId: json['liftId'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => CompletedSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final int dayNumber;
  final int weekNumber;
  final int cycleNumber;
  final int durationSeconds;
  final String? notes;
  final List<ExerciseLog> logs;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.dayNumber,
    required this.weekNumber,
    required this.cycleNumber,
    this.durationSeconds = 0,
    this.notes,
    required this.logs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'cycleNumber': cycleNumber,
      'durationSeconds': durationSeconds,
      'notes': notes,
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      dayNumber: json['dayNumber'] as int,
      weekNumber: json['weekNumber'] as int,
      cycleNumber: json['cycleNumber'] as int,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      notes: json['notes'] as String?,
      logs: (json['logs'] as List<dynamic>)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
