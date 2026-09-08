import 'package:uuid/uuid.dart';

/// Represents the specific exercise variation and metrics for a single round of Cindy.
class CindyRoundDetail {
  CindyRoundDetail({
    required this.roundNumber,
    this.pullupVariation = 'standard',
    this.pullupAddedWeightKg,
    this.pullupBandAssistance,
    this.pushupVariation = 'standard',
    this.pushupAddedWeightKg,
    this.squatVariation = 'standard',
    this.squatAddedWeightKg,
    this.splitTimeSeconds = 0,
    this.roundDurationSeconds = 0,
    String? roundTier,
  }) : roundTier = roundTier ?? _calculateRoundTier(
          pullupVariation: pullupVariation,
          pullupAddedWeightKg: pullupAddedWeightKg,
          pullupBandAssistance: pullupBandAssistance,
          pushupVariation: pushupVariation,
          pushupAddedWeightKg: pushupAddedWeightKg,
          squatVariation: squatVariation,
          squatAddedWeightKg: squatAddedWeightKg,
        );

  factory CindyRoundDetail.fromJson(Map<String, dynamic> json) {
    return CindyRoundDetail(
      roundNumber: json['roundNumber'] as int? ?? 1,
      pullupVariation: json['pullupVariation'] as String? ?? 'standard',
      pullupAddedWeightKg: (json['pullupAddedWeightKg'] as num?)?.toDouble(),
      pullupBandAssistance: json['pullupBandAssistance'] as String?,
      pushupVariation: json['pushupVariation'] as String? ?? 'standard',
      pushupAddedWeightKg: (json['pushupAddedWeightKg'] as num?)?.toDouble(),
      squatVariation: json['squatVariation'] as String? ?? 'standard',
      squatAddedWeightKg: (json['squatAddedWeightKg'] as num?)?.toDouble(),
      splitTimeSeconds: json['splitTimeSeconds'] as int? ?? 0,
      roundDurationSeconds: json['roundDurationSeconds'] as int? ?? 0,
      roundTier: json['roundTier'] as String?,
    );
  }

  final int roundNumber;
  final String pullupVariation; // 'standard', 'chin_up', 'band_assisted', 'ring_rows', 'jumping', 'weighted'
  final double? pullupAddedWeightKg;
  final String? pullupBandAssistance; // 'light', 'medium', 'heavy'
  final String pushupVariation; // 'standard', 'knee', 'incline', 'pike', 'weighted', 'hspu'
  final double? pushupAddedWeightKg;
  final String squatVariation; // 'standard', 'goblet', 'weighted_vest', 'box_squat'
  final double? squatAddedWeightKg;
  final int splitTimeSeconds; // Total elapsed time when round completed
  final int roundDurationSeconds; // Time taken for this round
  final String roundTier; // 'Rx', 'Scaled', 'Weighted'

  static String _calculateRoundTier({
    required String pullupVariation,
    required String pushupVariation,
    required String squatVariation,
    double? pullupAddedWeightKg,
    String? pullupBandAssistance,
    double? pushupAddedWeightKg,
    double? squatAddedWeightKg,
  }) {
    final bool isScaled = pullupVariation == 'band_assisted' ||
        pullupVariation == 'ring_rows' ||
        pullupVariation == 'jumping' ||
        pullupBandAssistance != null ||
        pushupVariation == 'knee' ||
        pushupVariation == 'incline' ||
        squatVariation == 'box_squat';

    if (isScaled) {
      return 'Scaled';
    }

    final bool isWeighted = pullupVariation == 'weighted' ||
        (pullupAddedWeightKg != null && pullupAddedWeightKg > 0) ||
        pushupVariation == 'weighted' ||
        (pushupAddedWeightKg != null && pushupAddedWeightKg > 0) ||
        pushupVariation == 'pike' ||
        pushupVariation == 'hspu' ||
        squatVariation == 'goblet' ||
        squatVariation == 'weighted_vest' ||
        (squatAddedWeightKg != null && squatAddedWeightKg > 0);

    if (isWeighted) {
      return 'Weighted';
    }

    return 'Rx';
  }

  String get pullupDisplayName {
    switch (pullupVariation) {
      case 'chin_up':
        return 'Chin-ups (Rx)';
      case 'band_assisted':
        final String band = pullupBandAssistance != null ? ' (${pullupBandAssistance!.toUpperCase()})' : '';
        return 'Banded Pull-ups$band';
      case 'ring_rows':
        return 'Ring Rows';
      case 'jumping':
        return 'Jumping Pull-ups';
      case 'weighted':
        final String wt = pullupAddedWeightKg != null ? ' (+${pullupAddedWeightKg!.toStringAsFixed(1)}kg)' : '';
        return 'Weighted Pull-ups$wt';
      case 'standard':
      default:
        return 'Strict Pull-ups (Rx)';
    }
  }

  String get pushupDisplayName {
    switch (pushupVariation) {
      case 'knee':
        return 'Knee Push-ups';
      case 'incline':
        return 'Incline Push-ups';
      case 'pike':
        return 'Pike Push-ups';
      case 'hspu':
        return 'Handstand Push-ups';
      case 'weighted':
        final String wt = pushupAddedWeightKg != null ? ' (+${pushupAddedWeightKg!.toStringAsFixed(1)}kg)' : '';
        return 'Weighted Push-ups$wt';
      case 'standard':
      default:
        return 'Strict Push-ups (Rx)';
    }
  }

  String get squatDisplayName {
    switch (squatVariation) {
      case 'box_squat':
        return 'Box Squats';
      case 'goblet':
        final String wt = squatAddedWeightKg != null ? ' (${squatAddedWeightKg!.toStringAsFixed(1)}kg)' : '';
        return 'Goblet Squats$wt';
      case 'weighted_vest':
        final String wt = squatAddedWeightKg != null ? ' (+${squatAddedWeightKg!.toStringAsFixed(1)}kg)' : '';
        return 'Weight Vest Squats$wt';
      case 'standard':
      default:
        return 'Air Squats (Rx)';
    }
  }

  String get formattedSplit {
    final int m = splitTimeSeconds ~/ 60;
    final int s = splitTimeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roundNumber': roundNumber,
      'pullupVariation': pullupVariation,
      'pullupAddedWeightKg': pullupAddedWeightKg,
      'pullupBandAssistance': pullupBandAssistance,
      'pushupVariation': pushupVariation,
      'pushupAddedWeightKg': pushupAddedWeightKg,
      'squatVariation': squatVariation,
      'squatAddedWeightKg': squatAddedWeightKg,
      'splitTimeSeconds': splitTimeSeconds,
      'roundDurationSeconds': roundDurationSeconds,
      'roundTier': roundTier,
    };
  }

  CindyRoundDetail copyWith({
    int? roundNumber,
    String? pullupVariation,
    double? pullupAddedWeightKg,
    String? pullupBandAssistance,
    String? pushupVariation,
    double? pushupAddedWeightKg,
    String? squatVariation,
    double? squatAddedWeightKg,
    int? splitTimeSeconds,
    int? roundDurationSeconds,
    String? roundTier,
  }) {
    return CindyRoundDetail(
      roundNumber: roundNumber ?? this.roundNumber,
      pullupVariation: pullupVariation ?? this.pullupVariation,
      pullupAddedWeightKg: pullupAddedWeightKg ?? this.pullupAddedWeightKg,
      pullupBandAssistance: pullupBandAssistance ?? this.pullupBandAssistance,
      pushupVariation: pushupVariation ?? this.pushupVariation,
      pushupAddedWeightKg: pushupAddedWeightKg ?? this.pushupAddedWeightKg,
      squatVariation: squatVariation ?? this.squatVariation,
      squatAddedWeightKg: squatAddedWeightKg ?? this.squatAddedWeightKg,
      splitTimeSeconds: splitTimeSeconds ?? this.splitTimeSeconds,
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      roundTier: roundTier ?? this.roundTier,
    );
  }
}

/// Represents an entire completed or logged CrossFit Cindy session (AMRAP 20 Minutes).
class CindyWorkoutLog {
  CindyWorkoutLog({
    required this.completedRounds,
    String? id,
    DateTime? date,
    this.durationSeconds = 1200, // 20:00 standard
    this.partialPullups = 0,
    this.partialPushups = 0,
    this.partialSquats = 0,
    List<CindyRoundDetail>? rounds,
    this.partialPullupVariation = 'standard',
    this.partialPushupVariation = 'standard',
    this.partialSquatVariation = 'standard',
    this.isPr = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        rounds = rounds ?? <CindyRoundDetail>[];

  factory CindyWorkoutLog.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawRounds = json['rounds'] as List<dynamic>?;
    final List<CindyRoundDetail> roundList = rawRounds != null
        ? rawRounds
            .map((dynamic e) => CindyRoundDetail.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CindyRoundDetail>[];

    return CindyWorkoutLog(
      id: json['id'] as String? ?? const Uuid().v4(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      durationSeconds: json['durationSeconds'] as int? ?? 1200,
      completedRounds: json['completedRounds'] as int? ?? 0,
      partialPullups: json['partialPullups'] as int? ?? 0,
      partialPushups: json['partialPushups'] as int? ?? 0,
      partialSquats: json['partialSquats'] as int? ?? 0,
      rounds: roundList,
      partialPullupVariation: json['partialPullupVariation'] as String? ?? 'standard',
      partialPushupVariation: json['partialPushupVariation'] as String? ?? 'standard',
      partialSquatVariation: json['partialSquatVariation'] as String? ?? 'standard',
      isPr: json['isPr'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int durationSeconds; // standard 1200 (20m)
  final int completedRounds;
  final int partialPullups; // 0..5
  final int partialPushups; // 0..10
  final int partialSquats; // 0..15
  final List<CindyRoundDetail> rounds;
  final String partialPullupVariation;
  final String partialPushupVariation;
  final String partialSquatVariation;
  final bool isPr;
  final String? notes;

  /// Total reps completed: (completedRounds * 30) + partialPullups + partialPushups + partialSquats
  int get totalReps {
    return (completedRounds * 30) +
        partialPullups.clamp(0, 5) +
        partialPushups.clamp(0, 10) +
        partialSquats.clamp(0, 15);
  }

  /// Partial reps beyond completed rounds
  int get partialReps {
    return partialPullups.clamp(0, 5) +
        partialPushups.clamp(0, 10) +
        partialSquats.clamp(0, 15);
  }

  /// Overall session scaling tier:
  /// - If any completed round or partial movement used scaling -> 'Scaled'
  /// - Else if any round used weighted load -> 'Weighted'
  /// - Else -> 'Rx'
  String get scalingTier {
    if (rounds.isEmpty) {
      final bool hasScaled = partialPullupVariation == 'band_assisted' ||
          partialPullupVariation == 'ring_rows' ||
          partialPullupVariation == 'jumping' ||
          partialPushupVariation == 'knee' ||
          partialPushupVariation == 'incline' ||
          partialSquatVariation == 'box_squat';
      if (hasScaled) {
        return 'Scaled';
      }
      final bool hasWeighted = partialPullupVariation == 'weighted' ||
          partialPushupVariation == 'weighted' ||
          partialPushupVariation == 'pike' ||
          partialPushupVariation == 'hspu' ||
          partialSquatVariation == 'goblet' ||
          partialSquatVariation == 'weighted_vest';
      if (hasWeighted) {
        return 'Weighted';
      }
      return 'Rx';
    }

    final bool hasScaledRound = rounds.any((CindyRoundDetail r) => r.roundTier == 'Scaled');
    if (hasScaledRound) {
      return 'Scaled';
    }

    final bool hasWeightedRound = rounds.any((CindyRoundDetail r) => r.roundTier == 'Weighted');
    if (hasWeightedRound) {
      return 'Weighted';
    }

    return 'Rx';
  }

  int get rxRoundCount => rounds.where((CindyRoundDetail r) => r.roundTier == 'Rx').length;
  int get scaledRoundCount => rounds.where((CindyRoundDetail r) => r.roundTier == 'Scaled').length;
  int get weightedRoundCount => rounds.where((CindyRoundDetail r) => r.roundTier == 'Weighted').length;

  /// High-level summary of progressions used across rounds
  String get progressionSummary {
    if (rounds.isEmpty) {
      return scalingTier;
    }
    if (rxRoundCount == rounds.length) {
      return 'All $completedRounds Rounds Strict Rx';
    }
    if (scaledRoundCount == rounds.length) {
      return 'All $completedRounds Rounds Scaled';
    }
    if (weightedRoundCount == rounds.length) {
      return 'All $completedRounds Rounds Weighted';
    }

    // Mixed progression summary (e.g. 5 Rx, 12 Scaled)
    final List<String> parts = <String>[];
    if (rxRoundCount > 0) {
      parts.add('$rxRoundCount Rx');
    }
    if (weightedRoundCount > 0) {
      parts.add('$weightedRoundCount Weighted');
    }
    if (scaledRoundCount > 0) {
      parts.add('$scaledRoundCount Scaled');
    }
    return parts.join(', ');
  }

  /// Formatted score string (e.g. "21 Rds + 7 Reps (637 reps)")
  String get scoreDisplay {
    final String partialStr = partialReps > 0 ? ' + $partialReps Reps' : '';
    return '$completedRounds Rds$partialStr ($totalReps reps)';
  }

  String get formattedDuration {
    final int m = durationSeconds ~/ 60;
    final int s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'completedRounds': completedRounds,
      'partialPullups': partialPullups,
      'partialPushups': partialPushups,
      'partialSquats': partialSquats,
      'rounds': rounds.map((CindyRoundDetail r) => r.toJson()).toList(),
      'partialPullupVariation': partialPullupVariation,
      'partialPushupVariation': partialPushupVariation,
      'partialSquatVariation': partialSquatVariation,
      'isPr': isPr,
      'notes': notes,
    };
  }
}
