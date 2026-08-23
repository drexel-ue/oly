class RecoverySessionLog {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final List<String> completedExerciseIds;
  final int readinessRating; // 1 (Stiff) to 5 (Feeling Great / Ready)
  final List<String> diagnosticReasons;

  RecoverySessionLog({
    required this.id,
    required this.date,
    required this.durationMinutes,
    required this.completedExerciseIds,
    required this.readinessRating,
    required this.diagnosticReasons,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completedExerciseIds': completedExerciseIds,
      'readinessRating': readinessRating,
      'diagnosticReasons': diagnosticReasons,
    };
  }

  factory RecoverySessionLog.fromJson(Map<String, dynamic> json) {
    return RecoverySessionLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 10,
      completedExerciseIds:
          (json['completedExerciseIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      readinessRating: json['readinessRating'] as int? ?? 3,
      diagnosticReasons:
          (json['diagnosticReasons'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}
