class KettlebellMileLog {
  KettlebellMileLog({
    required this.id,
    required this.date,
    required this.weightKg,
    required this.bodyweightPercentage,
    required this.speedMph,
    required this.inclinePct,
    required this.durationSeconds,
    this.completedUnder20Min = false,
    this.notes,
  });

  factory KettlebellMileLog.fromJson(Map<String, dynamic> json) {
    final int duration = json['durationSeconds'] as int? ?? 0;
    return KettlebellMileLog(
      id: json['id'] as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      weightKg: (json['weightKg'] as num).toDouble(),
      bodyweightPercentage: (json['bodyweightPercentage'] as num?)?.toDouble() ?? 10.0,
      speedMph: (json['speedMph'] as num?)?.toDouble() ?? 3.5,
      inclinePct: (json['inclinePct'] as num?)?.toDouble() ?? 1.0,
      durationSeconds: duration,
      completedUnder20Min: json['completedUnder20Min'] as bool? ?? (duration > 0 && duration < 1200),
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final double weightKg;
  final double bodyweightPercentage; // e.g. 10.0 (10%), 15.0 (15%), up to 30.0%
  final double speedMph; // Speed e.g. 3.5 mph
  final double inclinePct; // Incline grade % e.g. 2.0%
  final int durationSeconds; // Total time to complete 1 mile
  final bool completedUnder20Min; // Unlocks next weight milestone
  final String? notes;

  String get formattedDuration {
    final int minutes = durationSeconds ~/ 60;
    final int seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'bodyweightPercentage': bodyweightPercentage,
      'speedMph': speedMph,
      'inclinePct': inclinePct,
      'durationSeconds': durationSeconds,
      'completedUnder20Min': completedUnder20Min,
      'notes': notes,
    };
  }
}
