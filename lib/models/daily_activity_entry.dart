import 'package:uuid/uuid.dart';

class DailyActivityEntry {
  const DailyActivityEntry({
    required this.id,
    required this.timestamp,
    required this.date,
    required this.activityType,
    required this.name,
    required this.durationMinutes,
    required this.metValue,
    required this.caloriesBurned,
    this.stepsCount,
    this.distanceMiles,
    this.source = 'manual',
    this.sessionId,
    this.notes,
    this.metadata,
  });

  factory DailyActivityEntry.create({
    required String activityType,
    required String name,
    required double durationMinutes,
    required double metValue,
    required int caloriesBurned,
    String? id,
    DateTime? timestamp,
    String? date,
    int? stepsCount,
    double? distanceMiles,
    String source = 'manual',
    String? sessionId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    final DateTime now = timestamp ?? DateTime.now();
    final String d =
        date ??
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return DailyActivityEntry(
      id: id ?? const Uuid().v4(),
      timestamp: now,
      date: d,
      activityType: activityType,
      name: name,
      durationMinutes: durationMinutes,
      stepsCount: stepsCount,
      distanceMiles: distanceMiles,
      metValue: metValue,
      caloriesBurned: caloriesBurned,
      source: source,
      sessionId: sessionId,
      notes: notes,
      metadata: metadata,
    );
  }

  factory DailyActivityEntry.fromJson(Map<String, dynamic> json) {
    return DailyActivityEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      date: json['date'] as String,
      activityType: json['activityType'] as String? ?? 'custom',
      name: json['name'] as String? ?? 'Activity',
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble() ?? 0.0,
      stepsCount: json['stepsCount'] as int?,
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble(),
      metValue: (json['metValue'] as num?)?.toDouble() ?? 3.5,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'manual',
      sessionId: json['sessionId'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final DateTime timestamp;
  final String date; // YYYY-MM-DD
  final String activityType; // 'walking_steps', 'cardio_machine', 'mobility_flow', 'rucking', 'workout_wod', 'custom'
  final String name;
  final double durationMinutes;
  final int? stepsCount;
  final double? distanceMiles;
  final double metValue;
  final int caloriesBurned;
  final String source; // 'manual', 'wod_auto_sync', 'apple_health'
  final String? sessionId; // Link to WorkoutSession if auto-synced
  final String? notes;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'date': date,
      'activityType': activityType,
      'name': name,
      'durationMinutes': durationMinutes,
      'stepsCount': stepsCount,
      'distanceMiles': distanceMiles,
      'metValue': metValue,
      'caloriesBurned': caloriesBurned,
      'source': source,
      'sessionId': sessionId,
      'notes': notes,
      'metadata': metadata,
    };
  }
}
