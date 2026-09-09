import 'package:uuid/uuid.dart';

/// Represents an entire completed or logged CrossFit Fran session (For Time: 21-15-9 Thrusters & Pull-ups).
class FranWorkoutLog {
  FranWorkoutLog({
    required this.totalTimeSeconds,
    String? id,
    DateTime? date,
    this.round1TimeSeconds, // split at completion of 21/21
    this.round2TimeSeconds, // split at completion of 15/15
    this.round3TimeSeconds, // split at completion of 9/9
    this.barbellWeightKg = 43.1, // 95 lb standard Rx Men (or 29.5 kg / 65 lb Rx Women)
    this.isRxWomen = false,
    this.pullupVariation = 'kipping',
    this.pullupBandAssistance,
    String? scalingTier,
    this.isPr = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        scalingTier = scalingTier ??
            _calculateScalingTier(
              barbellWeightKg: barbellWeightKg,
              isRxWomen: isRxWomen,
              pullupVariation: pullupVariation,
              pullupBandAssistance: pullupBandAssistance,
            );

  factory FranWorkoutLog.fromJson(Map<String, dynamic> json) {
    return FranWorkoutLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      round1TimeSeconds: json['round1TimeSeconds'] as int?,
      round2TimeSeconds: json['round2TimeSeconds'] as int?,
      round3TimeSeconds: json['round3TimeSeconds'] as int?,
      barbellWeightKg: (json['barbellWeightKg'] as num?)?.toDouble() ?? 43.1,
      isRxWomen: json['isRxWomen'] as bool? ?? false,
      pullupVariation: json['pullupVariation'] as String? ?? 'kipping',
      pullupBandAssistance: json['pullupBandAssistance'] as String?,
      scalingTier: json['scalingTier'] as String?,
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int totalTimeSeconds;
  final int? round1TimeSeconds; // split after 21s
  final int? round2TimeSeconds; // split after 15s
  final int? round3TimeSeconds; // split after 9s
  final double barbellWeightKg;
  final bool isRxWomen;
  final String pullupVariation;
  final String? pullupBandAssistance;
  final String scalingTier; // 'Rx', 'Scaled', 'Weighted'
  final bool isPr;
  final String? notes;

  static String _calculateScalingTier({
    required double barbellWeightKg,
    required bool isRxWomen,
    required String pullupVariation,
    String? pullupBandAssistance,
  }) {
    final double rxMinWeight = isRxWomen ? 29.0 : 42.0; // 65 lb (29.5 kg) or 95 lb (43.1 kg) with tolerance
    final bool isScaled = pullupVariation == 'band_assisted' ||
        pullupVariation == 'ring_rows' ||
        pullupVariation == 'jumping' ||
        pullupBandAssistance != null ||
        barbellWeightKg < rxMinWeight;

    if (isScaled) {
      return 'Scaled';
    }

    final double rxMaxWeight = isRxWomen ? 31.0 : 45.0;
    final bool isWeighted = barbellWeightKg > rxMaxWeight || pullupVariation == 'weighted';
    if (isWeighted) {
      return 'Weighted';
    }

    return 'Rx';
  }

  String get pullupDisplayName {
    switch (pullupVariation) {
      case 'chin_up':
        return 'Chin-ups (Rx)';
      case 'butterfly':
        return 'Butterfly Pull-ups (Rx)';
      case 'band_assisted':
        final String band = pullupBandAssistance != null ? ' (${pullupBandAssistance!.toUpperCase()})' : '';
        return 'Banded Pull-ups$band';
      case 'ring_rows':
        return 'Ring Rows';
      case 'jumping':
        return 'Jumping Pull-ups';
      case 'weighted':
        return 'Weighted Pull-ups';
      case 'standard':
        return 'Strict Pull-ups (Rx)';
      case 'kipping':
      default:
        return 'Kipping Pull-ups (Rx)';
    }
  }

  String get formattedTotalTime {
    final int m = totalTimeSeconds ~/ 60;
    final int s = totalTimeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedRound1Time {
    if (round1TimeSeconds == null) {
      return null;
    }
    final int m = round1TimeSeconds! ~/ 60;
    final int s = round1TimeSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedRound2Time {
    if (round2TimeSeconds == null) {
      return null;
    }
    final int m = round2TimeSeconds! ~/ 60;
    final int s = round2TimeSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedRound3Time {
    if (round3TimeSeconds == null) {
      return null;
    }
    final int m = round3TimeSeconds! ~/ 60;
    final int s = round3TimeSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get scoreDisplay {
    return '$formattedTotalTime ($scalingTier)';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'totalTimeSeconds': totalTimeSeconds,
      'round1TimeSeconds': round1TimeSeconds,
      'round2TimeSeconds': round2TimeSeconds,
      'round3TimeSeconds': round3TimeSeconds,
      'barbellWeightKg': barbellWeightKg,
      'isRxWomen': isRxWomen,
      'pullupVariation': pullupVariation,
      'pullupBandAssistance': pullupBandAssistance,
      'scalingTier': scalingTier,
      'isPr': isPr,
      'notes': notes,
    };
  }

  FranWorkoutLog copyWith({
    String? id,
    DateTime? date,
    int? totalTimeSeconds,
    int? round1TimeSeconds,
    int? round2TimeSeconds,
    int? round3TimeSeconds,
    double? barbellWeightKg,
    bool? isRxWomen,
    String? pullupVariation,
    String? pullupBandAssistance,
    String? scalingTier,
    bool? isPr,
    String? notes,
  }) {
    return FranWorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      round1TimeSeconds: round1TimeSeconds ?? this.round1TimeSeconds,
      round2TimeSeconds: round2TimeSeconds ?? this.round2TimeSeconds,
      round3TimeSeconds: round3TimeSeconds ?? this.round3TimeSeconds,
      barbellWeightKg: barbellWeightKg ?? this.barbellWeightKg,
      isRxWomen: isRxWomen ?? this.isRxWomen,
      pullupVariation: pullupVariation ?? this.pullupVariation,
      pullupBandAssistance: pullupBandAssistance ?? this.pullupBandAssistance,
      scalingTier: scalingTier ?? this.scalingTier,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }
}
