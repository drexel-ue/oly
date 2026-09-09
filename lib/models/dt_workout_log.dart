import 'package:uuid/uuid.dart';

/// Represents an entire completed or logged CrossFit DT session (5 Rounds For Time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks).
class DtWorkoutLog {
  DtWorkoutLog({
    required this.totalTimeSeconds,
    String? id,
    DateTime? date,
    this.round1TimeSeconds,
    this.round2TimeSeconds,
    this.round3TimeSeconds,
    this.round4TimeSeconds,
    this.round5TimeSeconds,
    this.barbellWeightKg = 70.3, // 155 lb standard Rx Men (or 47.6 kg / 105 lb Rx Women)
    this.isRxWomen = false,
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

  factory DtWorkoutLog.fromJson(Map<String, dynamic> json) {
    return DtWorkoutLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      round1TimeSeconds: json['round1TimeSeconds'] as int?,
      round2TimeSeconds: json['round2TimeSeconds'] as int?,
      round3TimeSeconds: json['round3TimeSeconds'] as int?,
      round4TimeSeconds: json['round4TimeSeconds'] as int?,
      round5TimeSeconds: json['round5TimeSeconds'] as int?,
      barbellWeightKg: (json['barbellWeightKg'] as num?)?.toDouble() ?? 70.3,
      isRxWomen: json['isRxWomen'] as bool? ?? false,
      scalingTier: json['scalingTier'] as String?,
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int totalTimeSeconds;
  final int? round1TimeSeconds;
  final int? round2TimeSeconds;
  final int? round3TimeSeconds;
  final int? round4TimeSeconds;
  final int? round5TimeSeconds;
  final double barbellWeightKg;
  final bool isRxWomen;
  final String scalingTier; // 'Rx', 'Scaled', 'Weighted'
  final bool isPr;
  final String? notes;

  static String _calculateScalingTier({
    required double barbellWeightKg,
    required bool isRxWomen,
  }) {
    final double rxMinWeight = isRxWomen ? 46.0 : 69.0; // 105 lb (47.6 kg) or 155 lb (70.3 kg)
    if (barbellWeightKg < rxMinWeight) {
      return 'Scaled';
    }

    final double rxMaxWeight = isRxWomen ? 50.0 : 73.0;
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

  String? get formattedRound1Time => _formatOptional(round1TimeSeconds);
  String? get formattedRound2Time => _formatOptional(round2TimeSeconds);
  String? get formattedRound3Time => _formatOptional(round3TimeSeconds);
  String? get formattedRound4Time => _formatOptional(round4TimeSeconds);
  String? get formattedRound5Time => _formatOptional(round5TimeSeconds);

  static String? _formatOptional(int? seconds) {
    if (seconds == null) {
      return null;
    }
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
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
      'round1TimeSeconds': round1TimeSeconds,
      'round2TimeSeconds': round2TimeSeconds,
      'round3TimeSeconds': round3TimeSeconds,
      'round4TimeSeconds': round4TimeSeconds,
      'round5TimeSeconds': round5TimeSeconds,
      'barbellWeightKg': barbellWeightKg,
      'isRxWomen': isRxWomen,
      'scalingTier': scalingTier,
      'isPr': isPr,
      'notes': notes,
    };
  }

  DtWorkoutLog copyWith({
    String? id,
    DateTime? date,
    int? totalTimeSeconds,
    int? round1TimeSeconds,
    int? round2TimeSeconds,
    int? round3TimeSeconds,
    int? round4TimeSeconds,
    int? round5TimeSeconds,
    double? barbellWeightKg,
    bool? isRxWomen,
    String? scalingTier,
    bool? isPr,
    String? notes,
  }) {
    return DtWorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      round1TimeSeconds: round1TimeSeconds ?? this.round1TimeSeconds,
      round2TimeSeconds: round2TimeSeconds ?? this.round2TimeSeconds,
      round3TimeSeconds: round3TimeSeconds ?? this.round3TimeSeconds,
      round4TimeSeconds: round4TimeSeconds ?? this.round4TimeSeconds,
      round5TimeSeconds: round5TimeSeconds ?? this.round5TimeSeconds,
      barbellWeightKg: barbellWeightKg ?? this.barbellWeightKg,
      isRxWomen: isRxWomen ?? this.isRxWomen,
      scalingTier: scalingTier ?? this.scalingTier,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }
}
