import 'package:uuid/uuid.dart';

/// Represents an entire completed or logged CrossFit Helen session (3 Rounds For Time: 400m Run, 21 KB Swings, 12 Pull-ups).
class HelenWorkoutLog {
  HelenWorkoutLog({
    required this.totalTimeSeconds,
    String? id,
    DateTime? date,
    this.round1TimeSeconds, // split after round 1
    this.round2TimeSeconds, // split after round 2
    this.round3TimeSeconds, // split after round 3
    this.kettlebellWeightKg = 24.0, // 53 lb standard Rx Men (or 16.0 kg / 35 lb Rx Women)
    this.isRxWomen = false,
    this.swingType = 'american', // 'american' (overhead Rx) or 'russian' (eye-level scaled)
    this.pullupVariation = 'kipping',
    this.pullupBandAssistance,
    this.runDistanceMeters = 400,
    String? scalingTier,
    this.isPr = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        scalingTier = scalingTier ??
            _calculateScalingTier(
              kettlebellWeightKg: kettlebellWeightKg,
              isRxWomen: isRxWomen,
              swingType: swingType,
              pullupVariation: pullupVariation,
              pullupBandAssistance: pullupBandAssistance,
              runDistanceMeters: runDistanceMeters,
            );

  factory HelenWorkoutLog.fromJson(Map<String, dynamic> json) {
    return HelenWorkoutLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      round1TimeSeconds: json['round1TimeSeconds'] as int?,
      round2TimeSeconds: json['round2TimeSeconds'] as int?,
      round3TimeSeconds: json['round3TimeSeconds'] as int?,
      kettlebellWeightKg: (json['kettlebellWeightKg'] as num?)?.toDouble() ?? 24.0,
      isRxWomen: json['isRxWomen'] as bool? ?? false,
      swingType: json['swingType'] as String? ?? 'american',
      pullupVariation: json['pullupVariation'] as String? ?? 'kipping',
      pullupBandAssistance: json['pullupBandAssistance'] as String?,
      runDistanceMeters: json['runDistanceMeters'] as int? ?? 400,
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
  final double kettlebellWeightKg;
  final bool isRxWomen;
  final String swingType; // 'american', 'russian'
  final String pullupVariation;
  final String? pullupBandAssistance;
  final int runDistanceMeters;
  final String scalingTier; // 'Rx', 'Scaled', 'Weighted'
  final bool isPr;
  final String? notes;

  static String _calculateScalingTier({
    required double kettlebellWeightKg,
    required bool isRxWomen,
    required String swingType,
    required String pullupVariation,
    required int runDistanceMeters,
    String? pullupBandAssistance,
  }) {
    final double rxMinWeight = isRxWomen ? 15.5 : 23.5; // 35 lb (16 kg) or 53 lb (24 kg)
    final bool isScaled = swingType == 'russian' ||
        pullupVariation == 'band_assisted' ||
        pullupVariation == 'ring_rows' ||
        pullupVariation == 'jumping' ||
        pullupBandAssistance != null ||
        kettlebellWeightKg < rxMinWeight ||
        runDistanceMeters < 400;

    if (isScaled) {
      return 'Scaled';
    }

    final double rxMaxWeight = isRxWomen ? 17.0 : 25.0;
    final bool isWeighted = kettlebellWeightKg > rxMaxWeight || pullupVariation == 'weighted';
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

  String get swingDisplayName {
    final String typeStr = swingType == 'russian' ? 'Russian (Eye-level)' : 'American (Overhead)';
    return '$typeStr (${kettlebellWeightKg.toStringAsFixed(1)} kg)';
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
      'kettlebellWeightKg': kettlebellWeightKg,
      'isRxWomen': isRxWomen,
      'swingType': swingType,
      'pullupVariation': pullupVariation,
      'pullupBandAssistance': pullupBandAssistance,
      'runDistanceMeters': runDistanceMeters,
      'scalingTier': scalingTier,
      'isPr': isPr,
      'notes': notes,
    };
  }

  HelenWorkoutLog copyWith({
    String? id,
    DateTime? date,
    int? totalTimeSeconds,
    int? round1TimeSeconds,
    int? round2TimeSeconds,
    int? round3TimeSeconds,
    double? kettlebellWeightKg,
    bool? isRxWomen,
    String? swingType,
    String? pullupVariation,
    String? pullupBandAssistance,
    int? runDistanceMeters,
    String? scalingTier,
    bool? isPr,
    String? notes,
  }) {
    return HelenWorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      round1TimeSeconds: round1TimeSeconds ?? this.round1TimeSeconds,
      round2TimeSeconds: round2TimeSeconds ?? this.round2TimeSeconds,
      round3TimeSeconds: round3TimeSeconds ?? this.round3TimeSeconds,
      kettlebellWeightKg: kettlebellWeightKg ?? this.kettlebellWeightKg,
      isRxWomen: isRxWomen ?? this.isRxWomen,
      swingType: swingType ?? this.swingType,
      pullupVariation: pullupVariation ?? this.pullupVariation,
      pullupBandAssistance: pullupBandAssistance ?? this.pullupBandAssistance,
      runDistanceMeters: runDistanceMeters ?? this.runDistanceMeters,
      scalingTier: scalingTier ?? this.scalingTier,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }
}
