class PREntry {
  PREntry({
    required this.id,
    required this.weight,
    required this.reps,
    required this.date,
    this.rpe,
    this.notes,
  });

  factory PREntry.fromJson(Map<String, dynamic> json) {
    return PREntry(
      id: json['id'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      rpe: json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
      notes: json['notes'] as String?,
    );
  }
  final String id;
  final double weight; // stored in standard base unit (KG)
  final int reps;
  final DateTime date;
  final double? rpe;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'weight': weight,
      'reps': reps,
      'date': date.toIso8601String(),
      'rpe': rpe,
      'notes': notes,
    };
  }
}
