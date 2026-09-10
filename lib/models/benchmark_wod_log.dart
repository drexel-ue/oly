import 'package:uuid/uuid.dart';

/// Represents a logged completion of any CrossFit Benchmark or Hero WOD.
class BenchmarkWodLog {
  const BenchmarkWodLog({
    required this.id,
    required this.wodId,
    required this.wodName,
    required this.format,
    required this.date,
    required this.durationSeconds,
    required this.scoreDisplay,
    this.category = 'Hero Benchmark',
    this.completedRounds = 0,
    this.completedReps = 0,
    this.isRx = true,
    this.scalingModifications,
    this.rpe,
    this.averageHeartRate,
    this.caloriesBurned,
    this.isPr = false,
    this.notes,
  });

  /// Factory constructor for quickly logging a new attempt with an auto-generated UUID.
  factory BenchmarkWodLog.create({
    required String wodId,
    required String wodName,
    required String format,
    required DateTime date,
    required int durationSeconds,
    required String scoreDisplay,
    String category = 'Hero Benchmark',
    int completedRounds = 0,
    int completedReps = 0,
    bool isRx = true,
    String? scalingModifications,
    int? rpe,
    int? averageHeartRate,
    int? caloriesBurned,
    bool isPr = false,
    String? notes,
  }) {
    return BenchmarkWodLog(
      id: const Uuid().v4(),
      wodId: wodId,
      wodName: wodName,
      format: format,
      category: category,
      date: date,
      durationSeconds: durationSeconds,
      completedRounds: completedRounds,
      completedReps: completedReps,
      scoreDisplay: scoreDisplay,
      isRx: isRx,
      scalingModifications: scalingModifications,
      rpe: rpe,
      averageHeartRate: averageHeartRate,
      caloriesBurned: caloriesBurned,
      isPr: isPr,
      notes: notes,
    );
  }

  factory BenchmarkWodLog.fromJson(Map<String, dynamic> json) {
    return BenchmarkWodLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      wodId: json['wodId'] as String? ?? '',
      wodName: json['wodName'] as String? ?? 'Unnamed WOD',
      format: json['format'] as String? ?? 'forTime',
      category: json['category'] as String? ?? 'Hero Benchmark',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      completedRounds: (json['completedRounds'] as num?)?.toInt() ?? 0,
      completedReps: (json['completedReps'] as num?)?.toInt() ?? 0,
      scoreDisplay: json['scoreDisplay'] as String? ?? '--',
      isRx: json['isRx'] as bool? ?? true,
      scalingModifications: json['scalingModifications'] as String?,
      rpe: (json['rpe'] as num?)?.toInt(),
      averageHeartRate: (json['averageHeartRate'] as num?)?.toInt(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String wodId;
  final String wodName;
  final String format; // 'forTime', 'amrap', 'emom', 'chipper', 'rft', etc.
  final String category;
  final DateTime date;
  final int durationSeconds; // For 'forTime': time taken. For 'amrap': duration of the workout.
  final int completedRounds; // For 'amrap': completed rounds
  final int completedReps; // For 'amrap': additional reps; or total reps
  final String scoreDisplay; // e.g. "38:15" or "22 Rds + 7 Reps"
  final bool isRx; // Rx Prescribed vs Scaled
  final String? scalingModifications; // e.g. "No vest, banded pull-ups"
  final int? rpe; // Perceived exertion 1 to 10
  final int? averageHeartRate;
  final int? caloriesBurned;
  final bool isPr; // Indicates if this attempt is an all-time personal best
  final String? notes;

  BenchmarkWodLog copyWith({
    String? id,
    String? wodId,
    String? wodName,
    String? format,
    String? category,
    DateTime? date,
    int? durationSeconds,
    int? completedRounds,
    int? completedReps,
    String? scoreDisplay,
    bool? isRx,
    String? scalingModifications,
    int? rpe,
    int? averageHeartRate,
    int? caloriesBurned,
    bool? isPr,
    String? notes,
  }) {
    return BenchmarkWodLog(
      id: id ?? this.id,
      wodId: wodId ?? this.wodId,
      wodName: wodName ?? this.wodName,
      format: format ?? this.format,
      category: category ?? this.category,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedRounds: completedRounds ?? this.completedRounds,
      completedReps: completedReps ?? this.completedReps,
      scoreDisplay: scoreDisplay ?? this.scoreDisplay,
      isRx: isRx ?? this.isRx,
      scalingModifications: scalingModifications ?? this.scalingModifications,
      rpe: rpe ?? this.rpe,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }

  /// Determines whether [other] is beaten by this log.
  /// For 'forTime': lower duration is better.
  /// For 'amrap': more rounds, then more reps is better.
  /// For 'emom' or intervals: higher duration or reps is better.
  bool isBetterScoreThan(BenchmarkWodLog other) {
    final String cleanFormat = format.toLowerCase();
    if (cleanFormat.contains('time') || cleanFormat.contains('chipper')) {
      if (durationSeconds <= 0) {
        return false;
      }
      if (other.durationSeconds <= 0) {
        return true;
      }
      return durationSeconds < other.durationSeconds;
    } else if (cleanFormat.contains('amrap')) {
      if (completedRounds != other.completedRounds) {
        return completedRounds > other.completedRounds;
      }
      return completedReps > other.completedReps;
    } else {
      // Default to higher reps or longer duration survived
      if (completedReps > 0 && other.completedReps > 0) {
        return completedReps > other.completedReps;
      }
      return durationSeconds > other.durationSeconds;
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'wodId': wodId,
      'wodName': wodName,
      'format': format,
      'category': category,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'completedRounds': completedRounds,
      'completedReps': completedReps,
      'scoreDisplay': scoreDisplay,
      'isRx': isRx,
      'scalingModifications': scalingModifications,
      'rpe': rpe,
      'averageHeartRate': averageHeartRate,
      'caloriesBurned': caloriesBurned,
      'isPr': isPr,
      'notes': notes,
    };
  }
}
