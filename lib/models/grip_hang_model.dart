import 'package:uuid/uuid.dart';

enum HangMode {
  twoHand,
  singleHandLeft,
  singleHandRight;

  String get displayName {
    switch (this) {
      case HangMode.twoHand:
        return 'Two-Hand Dual Hang';
      case HangMode.singleHandLeft:
        return 'Left Single-Arm Hang';
      case HangMode.singleHandRight:
        return 'Right Single-Arm Hang';
    }
  }

  int get standardGoalSeconds {
    switch (this) {
      case HangMode.twoHand:
        return 300; // 5 minutes
      case HangMode.singleHandLeft:
      case HangMode.singleHandRight:
        return 120; // 2 minutes
    }
  }
}

enum HangStyle {
  activeScapular,
  passiveDecompression;

  String get displayName {
    switch (this) {
      case HangStyle.activeScapular:
        return 'Active Scapular Engagement';
      case HangStyle.passiveDecompression:
        return 'Passive Joint Decompression';
    }
  }
}

class DynamometerEntry {
  new({
    required this.id,
    required this.date,
    required this.leftHandKg,
    required this.rightHandKg,
    this.notes,
  });

  factory create({
    required double leftHandKg,
    required double rightHandKg,
    String? notes,
  }) {
    return DynamometerEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      leftHandKg: leftHandKg,
      rightHandKg: rightHandKg,
      notes: notes,
    );
  }

  factory fromJson(Map<String, dynamic> json) {
    return DynamometerEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      leftHandKg: (json['leftHandKg'] as num).toDouble(),
      rightHandKg: (json['rightHandKg'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final double leftHandKg;
  final double rightHandKg;
  final String? notes;

  double get maxForceKg =>
      leftHandKg > rightHandKg ? leftHandKg : rightHandKg;

  double get minForceKg =>
      leftHandKg < rightHandKg ? leftHandKg : rightHandKg;

  double get avgForceKg => (leftHandKg + rightHandKg) / 2;

  double get asymmetryPercent {
    if (maxForceKg <= 0) return 0;
    return ((maxForceKg - minForceKg) / maxForceKg) * 100;
  }

  String get dominantHand =>
      rightHandKg >= leftHandKg ? 'Right' : 'Left';

  bool get isBalanced => asymmetryPercent <= 10;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'leftHandKg': leftHandKg,
      'rightHandKg': rightHandKg,
      'notes': notes,
    };
  }
}

class HangSessionLog {
  new({
    required this.id,
    required this.date,
    required this.mode,
    required this.style,
    required this.durationSeconds,
    required this.targetSeconds,
    this.isPersonalRecord = false,
    this.notes,
  });

  factory create({
    required HangMode mode,
    required HangStyle style,
    required int durationSeconds,
    required int targetSeconds,
    bool isPersonalRecord = false,
    String? notes,
  }) {
    return HangSessionLog(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mode: mode,
      style: style,
      durationSeconds: durationSeconds,
      targetSeconds: targetSeconds,
      isPersonalRecord: isPersonalRecord,
      notes: notes,
    );
  }

  factory fromJson(Map<String, dynamic> json) {
    final String modeStr = json['mode'] as String? ?? 'twoHand';
    final HangMode mode = HangMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => HangMode.twoHand,
    );

    final String styleStr = json['style'] as String? ?? 'activeScapular';
    final HangStyle style = HangStyle.values.firstWhere(
      (e) => e.name == styleStr,
      orElse: () => HangStyle.activeScapular,
    );

    return HangSessionLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mode: mode,
      style: style,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      targetSeconds: json['targetSeconds'] as int? ?? mode.standardGoalSeconds,
      isPersonalRecord: json['isPersonalRecord'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final HangMode mode;
  final HangStyle style;
  final int durationSeconds;
  final int targetSeconds;
  final bool isPersonalRecord;
  final String? notes;

  double get progressRatio {
    if (targetSeconds <= 0) return 0;
    return (durationSeconds / targetSeconds).clamp(0, 1);
  }

  String get formattedDuration {
    final int minutes = durationSeconds ~/ 60;
    final int seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'mode': mode.name,
      'style': style.name,
      'durationSeconds': durationSeconds,
      'targetSeconds': targetSeconds,
      'isPersonalRecord': isPersonalRecord,
      'notes': notes,
    };
  }
}

class HangProtocol {
  const new({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.description,
    required this.targetAccumulatedSeconds,
    this.recommendedSets = 3,
    this.restBetweenSetsSeconds = 60,
  });

  final String id;
  final String title;
  final String subtitle;
  final HangMode mode;
  final String description;
  final int targetAccumulatedSeconds;
  final int recommendedSets;
  final int restBetweenSetsSeconds;

  static List<HangProtocol> getProtocols() {
    return const <HangProtocol>[
      HangProtocol(
        id: 'proto_max_test',
        title: 'Max Effort PR Test',
        subtitle: 'Continuous hold to failure with milestone alerts',
        mode: HangMode.twoHand,
        description:
            'Engage active scapulae, brace core, and hold continuously. Visual and audio alerts fire at 30s, 60s, 90s, 2m, 3m, 4m, and the 5m gold standard.',
        targetAccumulatedSeconds: 300,
        recommendedSets: 1,
        restBetweenSetsSeconds: 180,
      ),
      HangProtocol(
        id: 'proto_density_accumulation',
        title: 'Density Accumulation Ladder',
        subtitle: 'Accumulate target hang volume in fewest sets possible',
        mode: HangMode.twoHand,
        description:
            'Target: 3:00 (180s) total hang time. Complete as many sub-maximal sets as needed with 60s rest between sets. Progression: decrease sets to reach 3:00 unbroken.',
        targetAccumulatedSeconds: 180,
      ),
      HangProtocol(
        id: 'proto_unilateral_progression',
        title: 'Unilateral 2-Minute Foundation',
        subtitle: 'Single-arm alternating holds & lock-off stability',
        mode: HangMode.singleHandLeft,
        description:
            'Alternate between Left and Right single-arm hangs. 4 rounds of 15s Left / 15s Right / 30s Rest. Targets shoulder stability and unilateral grip endurance.',
        targetAccumulatedSeconds: 120,
        recommendedSets: 4,
        restBetweenSetsSeconds: 45,
      ),
    ];
  }
}
