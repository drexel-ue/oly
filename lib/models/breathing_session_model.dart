class BreathingRoundLog {
  BreathingRoundLog({
    required this.roundNumber,
    required this.breathsCount,
    required this.retentionSeconds,
    this.recoverySeconds = 15,
  });

  factory BreathingRoundLog.fromJson(Map<String, dynamic> json) {
    return BreathingRoundLog(
      roundNumber: json['roundNumber'] as int? ?? 1,
      breathsCount: json['breathsCount'] as int? ?? 30,
      retentionSeconds: json['retentionSeconds'] as int? ?? 0,
      recoverySeconds: json['recoverySeconds'] as int? ?? 15,
    );
  }

  final int roundNumber;
  final int breathsCount;
  final int retentionSeconds;
  final int recoverySeconds;

  String get formattedRetentionTime {
    final int minutes = retentionSeconds ~/ 60;
    final int seconds = retentionSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roundNumber': roundNumber,
      'breathsCount': breathsCount,
      'retentionSeconds': retentionSeconds,
      'recoverySeconds': recoverySeconds,
    };
  }
}

class BreathingSessionLog {
  BreathingSessionLog({
    required this.id,
    required this.date,
    required this.totalRounds,
    required this.rounds,
    this.readinessRating = 4,
    this.notes,
    int? maxHoldSeconds,
    int? avgHoldSeconds,
    int? totalHoldSeconds,
    int? totalDurationSeconds,
  })  : maxHoldSeconds = maxHoldSeconds ??
            (rounds.isEmpty
                ? 0
                : rounds
                    .map((BreathingRoundLog r) => r.retentionSeconds)
                    .reduce((int a, int b) => a > b ? a : b)),
        avgHoldSeconds = avgHoldSeconds ??
            (rounds.isEmpty
                ? 0
                : (rounds.fold(
                            0,
                            (int sum, BreathingRoundLog r) =>
                                sum + r.retentionSeconds,
                          ) /
                        rounds.length)
                    .round()),
        totalHoldSeconds = totalHoldSeconds ??
            (rounds.isEmpty
                ? 0
                : rounds.fold(
                    0,
                    (int sum, BreathingRoundLog r) => sum + r.retentionSeconds,
                  )),
        totalDurationSeconds = totalDurationSeconds ??
            (rounds.isEmpty
                ? 0
                : rounds.fold(
                    0,
                    (int sum, BreathingRoundLog r) =>
                        sum +
                        (r.breathsCount * 3) +
                        r.retentionSeconds +
                        r.recoverySeconds,
                  ));

  factory BreathingSessionLog.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawRounds = json['rounds'] as List<dynamic>?;
    final List<BreathingRoundLog> parsedRounds = rawRounds != null
        ? rawRounds
            .map((dynamic e) =>
                BreathingRoundLog.fromJson(e as Map<String, dynamic>))
            .toList()
        : <BreathingRoundLog>[];

    return BreathingSessionLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalRounds: json['totalRounds'] as int? ?? parsedRounds.length,
      rounds: parsedRounds,
      maxHoldSeconds: json['maxHoldSeconds'] as int?,
      avgHoldSeconds: json['avgHoldSeconds'] as int?,
      totalHoldSeconds: json['totalHoldSeconds'] as int?,
      totalDurationSeconds: json['totalDurationSeconds'] as int?,
      readinessRating: json['readinessRating'] as int? ?? 4,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final int totalRounds;
  final List<BreathingRoundLog> rounds;
  final int maxHoldSeconds;
  final int avgHoldSeconds;
  final int totalHoldSeconds;
  final int totalDurationSeconds;
  final int readinessRating;
  final String? notes;

  String get formattedMaxHold {
    final int minutes = maxHoldSeconds ~/ 60;
    final int seconds = maxHoldSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedAvgHold {
    final int minutes = avgHoldSeconds ~/ 60;
    final int seconds = avgHoldSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedTotalHold {
    final int minutes = totalHoldSeconds ~/ 60;
    final int seconds = totalHoldSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'totalRounds': totalRounds,
      'rounds': rounds.map((BreathingRoundLog r) => r.toJson()).toList(),
      'maxHoldSeconds': maxHoldSeconds,
      'avgHoldSeconds': avgHoldSeconds,
      'totalHoldSeconds': totalHoldSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'readinessRating': readinessRating,
      'notes': notes,
    };
  }
}

enum BreathingPace { relaxed, normal, fast }

class WimHofConfig {
  const WimHofConfig({
    this.defaultRounds = 3,
    this.breathsPerRound = 30,
    this.pace = BreathingPace.normal,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  factory WimHofConfig.fromJson(Map<String, dynamic> json) {
    BreathingPace parsedPace = BreathingPace.normal;
    final String? paceStr = json['pace'] as String?;
    if (paceStr != null) {
      for (final BreathingPace p in BreathingPace.values) {
        if (p.name == paceStr) {
          parsedPace = p;
          break;
        }
      }
    }

    return WimHofConfig(
      defaultRounds: json['defaultRounds'] as int? ?? 3,
      breathsPerRound: json['breathsPerRound'] as int? ?? 30,
      pace: parsedPace,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }

  final int defaultRounds;
  final int breathsPerRound;
  final BreathingPace pace;
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// Total seconds per breathing cycle (inhale + exhale)
  double get cycleDurationSeconds {
    switch (pace) {
      case BreathingPace.relaxed:
        return 4.5;
      case BreathingPace.normal:
        return 3.5;
      case BreathingPace.fast:
        return 2.5;
    }
  }

  double get inhaleDurationSeconds {
    switch (pace) {
      case BreathingPace.relaxed:
        return 2.7;
      case BreathingPace.normal:
        return 2.0;
      case BreathingPace.fast:
        return 1.5;
    }
  }

  double get exhaleDurationSeconds {
    switch (pace) {
      case BreathingPace.relaxed:
        return 1.8;
      case BreathingPace.normal:
        return 1.5;
      case BreathingPace.fast:
        return 1.0;
    }
  }

  WimHofConfig copyWith({
    int? defaultRounds,
    int? breathsPerRound,
    BreathingPace? pace,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return WimHofConfig(
      defaultRounds: defaultRounds ?? this.defaultRounds,
      breathsPerRound: breathsPerRound ?? this.breathsPerRound,
      pace: pace ?? this.pace,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'defaultRounds': defaultRounds,
      'breathsPerRound': breathsPerRound,
      'pace': pace.name,
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
    };
  }
}
