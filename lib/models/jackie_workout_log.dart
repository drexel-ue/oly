import 'package:uuid/uuid.dart';

/// Represents an entire completed or logged CrossFit Jackie session (For Time: 1000m Row, 50 Thrusters, 30 Pull-ups).
class JackieWorkoutLog {
  JackieWorkoutLog({
    required this.totalTimeSeconds,
    String? id,
    DateTime? date,
    this.rowTimeSeconds,
    this.thrusterTimeSeconds,
    this.pullupTimeSeconds,
    this.barbellWeightKg = 20.4, // 45 lb standard Rx
    this.pullupVariation = 'standard',
    this.pullupBandAssistance,
    this.rowDistanceMeters = 1000,
    this.thrusterReps = 50,
    this.pullupReps = 30,
    String? scalingTier,
    this.isPr = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        scalingTier = scalingTier ??
            _calculateScalingTier(
              barbellWeightKg: barbellWeightKg,
              pullupVariation: pullupVariation,
              pullupBandAssistance: pullupBandAssistance,
              rowDistanceMeters: rowDistanceMeters,
              thrusterReps: thrusterReps,
              pullupReps: pullupReps,
            );

  factory JackieWorkoutLog.fromJson(Map<String, dynamic> json) {
    return JackieWorkoutLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      rowTimeSeconds: json['rowTimeSeconds'] as int?,
      thrusterTimeSeconds: json['thrusterTimeSeconds'] as int?,
      pullupTimeSeconds: json['pullupTimeSeconds'] as int?,
      barbellWeightKg: (json['barbellWeightKg'] as num?)?.toDouble() ?? 20.4,
      pullupVariation: json['pullupVariation'] as String? ?? 'standard',
      pullupBandAssistance: json['pullupBandAssistance'] as String?,
      rowDistanceMeters: json['rowDistanceMeters'] as int? ?? 1000,
      thrusterReps: json['thrusterReps'] as int? ?? 50,
      pullupReps: json['pullupReps'] as int? ?? 30,
      scalingTier: json['scalingTier'] as String?,
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int totalTimeSeconds;
  final int? rowTimeSeconds; // time when row completed
  final int? thrusterTimeSeconds; // time taken or split
  final int? pullupTimeSeconds; // time taken or split
  final double barbellWeightKg;
  final String pullupVariation;
  final String? pullupBandAssistance;
  final int rowDistanceMeters;
  final int thrusterReps;
  final int pullupReps;
  final String scalingTier; // 'Rx', 'Scaled', 'Weighted'
  final bool isPr;
  final String? notes;

  static String _calculateScalingTier({
    required double barbellWeightKg,
    required String pullupVariation,
    required int rowDistanceMeters,
    required int thrusterReps,
    required int pullupReps,
    String? pullupBandAssistance,
  }) {
    final bool isScaled = pullupVariation == 'band_assisted' ||
        pullupVariation == 'ring_rows' ||
        pullupVariation == 'jumping' ||
        pullupBandAssistance != null ||
        barbellWeightKg < 20.0 || // lighter than 45 lb (allowing minor rounding 20.0-20.4)
        rowDistanceMeters < 1000 ||
        thrusterReps < 50 ||
        pullupReps < 30;

    if (isScaled) {
      return 'Scaled';
    }

    final bool isWeighted = barbellWeightKg > 21.0 || pullupVariation == 'weighted';
    if (isWeighted) {
      return 'Weighted';
    }

    return 'Rx';
  }

  String get pullupDisplayName {
    switch (pullupVariation) {
      case 'chin_up':
        return 'Chin-ups (Rx)';
      case 'kipping':
        return 'Kipping Pull-ups (Rx)';
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
      case 'chest_to_bar':
        return 'Chest-to-Bar Pull-ups';
      case 'standard':
      default:
        return 'Strict Pull-ups (Rx)';
    }
  }

  String get formattedTotalTime {
    final int m = totalTimeSeconds ~/ 60;
    final int s = totalTimeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedRowTime {
    if (rowTimeSeconds == null) {
      return null;
    }
    final int m = rowTimeSeconds! ~/ 60;
    final int s = rowTimeSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedThrusterTime {
    if (thrusterTimeSeconds == null) {
      return null;
    }
    final int m = thrusterTimeSeconds! ~/ 60;
    final int s = thrusterTimeSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get formattedPullupTime {
    if (pullupTimeSeconds == null) {
      return null;
    }
    final int m = pullupTimeSeconds! ~/ 60;
    final int s = pullupTimeSeconds! % 60;
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
      'rowTimeSeconds': rowTimeSeconds,
      'thrusterTimeSeconds': thrusterTimeSeconds,
      'pullupTimeSeconds': pullupTimeSeconds,
      'barbellWeightKg': barbellWeightKg,
      'pullupVariation': pullupVariation,
      'pullupBandAssistance': pullupBandAssistance,
      'rowDistanceMeters': rowDistanceMeters,
      'thrusterReps': thrusterReps,
      'pullupReps': pullupReps,
      'scalingTier': scalingTier,
      'isPr': isPr,
      'notes': notes,
    };
  }

  JackieWorkoutLog copyWith({
    String? id,
    DateTime? date,
    int? totalTimeSeconds,
    int? rowTimeSeconds,
    int? thrusterTimeSeconds,
    int? pullupTimeSeconds,
    double? barbellWeightKg,
    String? pullupVariation,
    String? pullupBandAssistance,
    int? rowDistanceMeters,
    int? thrusterReps,
    int? pullupReps,
    String? scalingTier,
    bool? isPr,
    String? notes,
  }) {
    return JackieWorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      rowTimeSeconds: rowTimeSeconds ?? this.rowTimeSeconds,
      thrusterTimeSeconds: thrusterTimeSeconds ?? this.thrusterTimeSeconds,
      pullupTimeSeconds: pullupTimeSeconds ?? this.pullupTimeSeconds,
      barbellWeightKg: barbellWeightKg ?? this.barbellWeightKg,
      pullupVariation: pullupVariation ?? this.pullupVariation,
      pullupBandAssistance: pullupBandAssistance ?? this.pullupBandAssistance,
      rowDistanceMeters: rowDistanceMeters ?? this.rowDistanceMeters,
      thrusterReps: thrusterReps ?? this.thrusterReps,
      pullupReps: pullupReps ?? this.pullupReps,
      scalingTier: scalingTier ?? this.scalingTier,
      isPr: isPr ?? this.isPr,
      notes: notes ?? this.notes,
    );
  }
}
