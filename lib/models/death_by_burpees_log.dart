import 'package:uuid/uuid.dart';

/// Represents an entire completed or logged CrossFit "Death By Burpees" EMOM session.
/// (Minute 1 = 1 burpee, Minute 2 = 2 burpees, ..., until failure to complete within the minute).
class DeathByBurpeesLog {
  DeathByBurpeesLog({
    required this.completedMinutes,
    this.partialReps = 0,
    int? totalReps,
    int? totalDurationSeconds,
    String? id,
    DateTime? date,
    this.burpeeVariation = 'standard', // 'standard' (chest-to-floor Rx), 'no_pushup', 'box_elevated'
    String? scalingTier,
    this.isPr = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        totalReps = totalReps ?? _calculateTotalReps(completedMinutes, partialReps),
        totalDurationSeconds = totalDurationSeconds ?? (completedMinutes * 60),
        scalingTier = scalingTier ?? (burpeeVariation == 'standard' ? 'Rx' : 'Scaled');

  factory DeathByBurpeesLog.fromJson(Map<String, dynamic> json) {
    final int minutes = json['completedMinutes'] as int? ?? 0;
    final int partial = json['partialReps'] as int? ?? 0;
    return DeathByBurpeesLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      completedMinutes: minutes,
      partialReps: partial,
      totalReps: json['totalReps'] as int? ?? _calculateTotalReps(minutes, partial),
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? (minutes * 60),
      burpeeVariation: json['burpeeVariation'] as String? ?? 'standard',
      scalingTier: json['scalingTier'] as String? ?? 'Rx',
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int completedMinutes;
  final int partialReps;
  final int totalReps;
  final int totalDurationSeconds;
  final String burpeeVariation;
  final String scalingTier; // 'Rx', 'Scaled'
  final bool isPr;
  final String? notes;

  static int _calculateTotalReps(int minutes, int partial) {
    // Sum of 1 + 2 + ... + N = N * (N + 1) / 2
    final int fullReps = minutes > 0 ? (minutes * (minutes + 1)) ~/ 2 : 0;
    return fullReps + partial;
  }

  String get variationDisplayName {
    switch (burpeeVariation) {
      case 'no_pushup':
        return 'No-Pushup Burpees (Scaled)';
      case 'box_elevated':
        return 'Elevated Hands (Scaled)';
      case 'standard':
      default:
        return 'Chest-to-Floor (Rx)';
    }
  }

  String get scoreDisplay {
    if (partialReps > 0) {
      return '$completedMinutes Mins + $partialReps Reps ($totalReps Burpees, $scalingTier)';
    }
    return '$completedMinutes Minutes ($totalReps Burpees, $scalingTier)';
  }

  String get formattedDuration {
    final int m = totalDurationSeconds ~/ 60;
    final int s = totalDurationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'completedMinutes': completedMinutes,
      'partialReps': partialReps,
      'totalReps': totalReps,
      'totalDurationSeconds': totalDurationSeconds,
      'burpeeVariation': burpeeVariation,
      'scalingTier': scalingTier,
      'isPr': isPr,
      'notes': notes,
    };
  }

  DeathByBurpeesLog copyWith({
    String? id,
    DateTime? date,
    int? completedMinutes,
    int? partialReps,
    int? totalReps,
    int? totalDurationSeconds,
    String? burpeeVariation,
    String? scalingTier,
    bool? isPr,
    String? notes,
  }) {
    return DeathByBurpeesLog(
      id: id ?? this.id,
      date: date ?? this.date,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      partialReps: partialReps ?? this.partialReps,
      totalReps: totalReps ?? this.totalReps,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      burpeeVariation: burpeeVariation ?? this.burpeeVariation,
      scalingTier: scalingTier ?? this.scalingTier,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }
}
