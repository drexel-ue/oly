import 'package:uuid/uuid.dart';

/// Represents an entire completed or logged CrossFit Grace session (30 Clean & Jerks For Time).
class GraceWorkoutLog {
  GraceWorkoutLog({
    required this.totalTimeSeconds,
    String? id,
    DateTime? date,
    this.splitAt10Seconds, // split after 10 reps
    this.splitAt20Seconds, // split after 20 reps
    this.barbellWeightKg = 61.2, // 135 lb standard Rx Men (or 43.1 kg / 95 lb Rx Women)
    this.isRxWomen = false,
    this.repPacingScheme = 'quick_singles', // 'quick_singles', 'touch_and_go', 'sets_of_5', 'unbroken'
    this.cleanTechnique = 'power_clean', // 'power_clean', 'squat_clean'
    this.jerkTechnique = 'push_jerk', // 'push_jerk', 'split_jerk', 'push_press'
    String? scalingTier,
    this.isPr = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        scalingTier = scalingTier ??
            _calculateScalingTier(
              barbellWeightKg: barbellWeightKg,
              isRxWomen: isRxWomen,
            );

  factory GraceWorkoutLog.fromJson(Map<String, dynamic> json) {
    return GraceWorkoutLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      splitAt10Seconds: json['splitAt10Seconds'] as int?,
      splitAt20Seconds: json['splitAt20Seconds'] as int?,
      barbellWeightKg: (json['barbellWeightKg'] as num?)?.toDouble() ?? 61.2,
      isRxWomen: json['isRxWomen'] as bool? ?? false,
      repPacingScheme: json['repPacingScheme'] as String? ?? 'quick_singles',
      cleanTechnique: json['cleanTechnique'] as String? ?? 'power_clean',
      jerkTechnique: json['jerkTechnique'] as String? ?? 'push_jerk',
      scalingTier: json['scalingTier'] as String?,
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int totalTimeSeconds;
  final int? splitAt10Seconds;
  final int? splitAt20Seconds;
  final double barbellWeightKg;
  final bool isRxWomen;
  final String repPacingScheme;
  final String cleanTechnique;
  final String jerkTechnique;
  final String scalingTier; // 'Rx', 'Scaled', 'Weighted'
  final bool isPr;
  final String? notes;

  static String _calculateScalingTier({
    required double barbellWeightKg,
    required bool isRxWomen,
  }) {
    final double rxMinWeight = isRxWomen ? 42.0 : 60.0; // 95 lb (43 kg) or 135 lb (61 kg)
    if (barbellWeightKg < rxMinWeight) {
      return 'Scaled';
    }

    final double rxMaxWeight = isRxWomen ? 45.0 : 63.5;
    if (barbellWeightKg > rxMaxWeight) {
      return 'Weighted';
    }

    return 'Rx';
  }

  String get formattedTotalTime {
    final int m = totalTimeSeconds ~/ 60;
    final int s = totalTimeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedSplitAt10 {
    if (splitAt10Seconds == null) {
      return null;
    }
    final int m = splitAt10Seconds! ~/ 60;
    final int s = splitAt10Seconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedSplitAt20 {
    if (splitAt20Seconds == null) {
      return null;
    }
    final int m = splitAt20Seconds! ~/ 60;
    final int s = splitAt20Seconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get scoreDisplay {
    return '$formattedTotalTime ($scalingTier)';
  }

  String get loadDisplayName {
    final String division = isRxWomen ? 'Rx Women' : 'Rx Men';
    return '${barbellWeightKg.toStringAsFixed(1)} kg ($division)';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'totalTimeSeconds': totalTimeSeconds,
      'splitAt10Seconds': splitAt10Seconds,
      'splitAt20Seconds': splitAt20Seconds,
      'barbellWeightKg': barbellWeightKg,
      'isRxWomen': isRxWomen,
      'repPacingScheme': repPacingScheme,
      'cleanTechnique': cleanTechnique,
      'jerkTechnique': jerkTechnique,
      'scalingTier': scalingTier,
      'isPr': isPr,
      'notes': notes,
    };
  }

  GraceWorkoutLog copyWith({
    String? id,
    DateTime? date,
    int? totalTimeSeconds,
    int? splitAt10Seconds,
    int? splitAt20Seconds,
    double? barbellWeightKg,
    bool? isRxWomen,
    String? repPacingScheme,
    String? cleanTechnique,
    String? jerkTechnique,
    String? scalingTier,
    bool? isPr,
    String? notes,
  }) {
    return GraceWorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      splitAt10Seconds: splitAt10Seconds ?? this.splitAt10Seconds,
      splitAt20Seconds: splitAt20Seconds ?? this.splitAt20Seconds,
      barbellWeightKg: barbellWeightKg ?? this.barbellWeightKg,
      isRxWomen: isRxWomen ?? this.isRxWomen,
      repPacingScheme: repPacingScheme ?? this.repPacingScheme,
      cleanTechnique: cleanTechnique ?? this.cleanTechnique,
      jerkTechnique: jerkTechnique ?? this.jerkTechnique,
      scalingTier: scalingTier ?? this.scalingTier,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }
}
