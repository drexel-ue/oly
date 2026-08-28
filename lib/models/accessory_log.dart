class AccessoryLog {
  AccessoryLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.sets,
    required this.reps,
    required this.date,
    this.source,
    this.notes,
  });

  factory AccessoryLog.fromJson(Map<String, dynamic> json) {
    return AccessoryLog(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      source: json['source'] as String?,
      notes: json['notes'] as String?,
    );
  }
  final String id;
  final String exerciseId;
  final String exerciseName;
  final double weightKg;
  final int sets;
  final int reps;
  final DateTime date;
  final String? source; // 'recovery', 'workout', 'warmup'
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'weightKg': weightKg,
      'sets': sets,
      'reps': reps,
      'date': date.toIso8601String(),
      'source': source,
      'notes': notes,
    };
  }
}
