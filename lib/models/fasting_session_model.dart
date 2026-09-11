import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';

/// Available fasting protocols with duration targets
enum FastingProtocol {
  intermittent16_8, // 16h fast / 8h window (Circadian baseline)
  intermittent18_6, // 18h fast / 6h window
  warrior20_4, // 20h fast / 4h window
  dinnerToDinner24, // 24h fast (Milestone 1)
  monkFast36, // 36h fast (Milestone 2: Sunday 6PM -> Tuesday 6AM)
  extended48, // 48h fast (Milestone 3: Deep Autophagy)
  apex72, // 72h fast (Milestone 4: Peak Stem Cell / Immune Reset)
  custom, // Custom duration
}

extension FastingProtocolExtension on FastingProtocol {
  String get displayName {
    switch (this) {
      case FastingProtocol.intermittent16_8:
        return '16:8 Circadian Fast';
      case FastingProtocol.intermittent18_6:
        return '18:6 Deep Fast';
      case FastingProtocol.warrior20_4:
        return '20:4 Warrior Fast';
      case FastingProtocol.dinnerToDinner24:
        return '24-Hour Reset';
      case FastingProtocol.monkFast36:
        return '36-Hour Monk Fast';
      case FastingProtocol.extended48:
        return '48-Hour Deep Autophagy';
      case FastingProtocol.apex72:
        return '72-Hour Apex Immune Reset';
      case FastingProtocol.custom:
        return 'Custom Protocol';
    }
  }

  int get targetHours {
    switch (this) {
      case FastingProtocol.intermittent16_8:
        return 16;
      case FastingProtocol.intermittent18_6:
        return 18;
      case FastingProtocol.warrior20_4:
        return 20;
      case FastingProtocol.dinnerToDinner24:
        return 24;
      case FastingProtocol.monkFast36:
        return 36;
      case FastingProtocol.extended48:
        return 48;
      case FastingProtocol.apex72:
        return 72;
      case FastingProtocol.custom:
        return 16;
    }
  }

  String get shortCode {
    switch (this) {
      case FastingProtocol.intermittent16_8:
        return '16:8';
      case FastingProtocol.intermittent18_6:
        return '18:6';
      case FastingProtocol.warrior20_4:
        return '20:4';
      case FastingProtocol.dinnerToDinner24:
        return '24H';
      case FastingProtocol.monkFast36:
        return '36H';
      case FastingProtocol.extended48:
        return '48H';
      case FastingProtocol.apex72:
        return '72H';
      case FastingProtocol.custom:
        return 'CUSTOM';
    }
  }

  String get subtitle {
    switch (this) {
      case FastingProtocol.intermittent16_8:
        return 'Ideal baseline for 6:00 AM lifters. 10:00 AM – 6:00 PM eating window.';
      case FastingProtocol.intermittent18_6:
        return 'Deepens daily ketogenesis and fat oxidation. 12:00 PM – 6:00 PM window.';
      case FastingProtocol.warrior20_4:
        return 'Aggressive daily autophagy. Single 4-hour evening feast.';
      case FastingProtocol.dinnerToDinner24:
        return 'Sunday 6 PM to Monday 6 PM. Complete overnight-to-overnight reset.';
      case FastingProtocol.monkFast36:
        return 'Sunday 6 PM to Tuesday 6 AM. Skips 1 day of eating; spans 2 nights.';
      case FastingProtocol.extended48:
        return '2 full days. Triggers 400% HGH surge and maximal autophagy.';
      case FastingProtocol.apex72:
        return 'The Valter Longo stem cell & hematopoietic immune reset.';
      case FastingProtocol.custom:
        return 'Set your own custom fasting duration and goal.';
    }
  }
}

/// Biological milestones achieved as hours elapse
enum FastingBiologicalStage {
  fed, // 0 - 4h
  postAbsorptive, // 4 - 12h
  ketosisOnset, // 12 - 18h
  autophagyActive, // 18 - 24h
  deepAutophagy, // 24 - 48h
  stemCellReset, // 48 - 72h+
}

extension FastingBiologicalStageExtension on FastingBiologicalStage {
  String get title {
    switch (this) {
      case FastingBiologicalStage.fed:
        return 'Fed / Digestion State';
      case FastingBiologicalStage.postAbsorptive:
        return 'Early Post-Absorptive';
      case FastingBiologicalStage.ketosisOnset:
        return 'Ketosis Onset & Fat Oxidation';
      case FastingBiologicalStage.autophagyActive:
        return 'Active Autophagy (AMPK Surge)';
      case FastingBiologicalStage.deepAutophagy:
        return 'Deep Autophagy & HGH Pulse';
      case FastingBiologicalStage.stemCellReset:
        return 'Stem Cell & Immune Regeneration';
    }
  }

  String get shortTitle {
    switch (this) {
      case FastingBiologicalStage.fed:
        return 'Fed State';
      case FastingBiologicalStage.postAbsorptive:
        return 'Post-Absorptive';
      case FastingBiologicalStage.ketosisOnset:
        return 'Ketosis Onset';
      case FastingBiologicalStage.autophagyActive:
        return 'Autophagy Active';
      case FastingBiologicalStage.deepAutophagy:
        return 'Deep Autophagy';
      case FastingBiologicalStage.stemCellReset:
        return 'Stem Cell Reset';
    }
  }

  String get timeRangeLabel {
    switch (this) {
      case FastingBiologicalStage.fed:
        return '0 – 4 Hours';
      case FastingBiologicalStage.postAbsorptive:
        return '4 – 12 Hours';
      case FastingBiologicalStage.ketosisOnset:
        return '12 – 18 Hours';
      case FastingBiologicalStage.autophagyActive:
        return '18 – 24 Hours';
      case FastingBiologicalStage.deepAutophagy:
        return '24 – 48 Hours';
      case FastingBiologicalStage.stemCellReset:
        return '48 – 72+ Hours';
    }
  }

  String get cellularSummary {
    switch (this) {
      case FastingBiologicalStage.fed:
        return 'Insulin is elevated; nutrients are transported into cells and partitioned into liver/muscle glycogen. mTOR is active; autophagy is suppressed.';
      case FastingBiologicalStage.postAbsorptive:
        return 'Blood glucose normalizes; insulin drops; glucagon rises. The liver begins breaking down glycogen reserves to maintain steady 70–90 mg/dL blood sugar.';
      case FastingBiologicalStage.ketosisOnset:
        return 'Hepatic glycogen depleted ~75%. Adipocytes mobilize free fatty acids; liver begins synthesizing beta-hydroxybutyrate (BHB) ketones for the brain and heart.';
      case FastingBiologicalStage.autophagyActive:
        return 'AMPK surges and turns off mTOR. Intracellular lysosomes begin digesting misfolded proteins, dysfunctional mitochondria (mitophagy), and cellular debris.';
      case FastingBiologicalStage.deepAutophagy:
        return 'Glycogen exhausted. Endogenous Human Growth Hormone (HGH) pulses up to 400% above baseline to preserve lean muscle tissue while ketones fuel the CNS.';
      case FastingBiologicalStage.stemCellReset:
        return 'Prolonged fasting causes apoptosis of senescent white blood cells. Hematopoietic stem cells shift from dormant to self-renewal mode, resetting the immune system.';
    }
  }

  Color get color {
    switch (this) {
      case FastingBiologicalStage.fed:
        return const Color(0xFF9E9E9E); // Silver Grey
      case FastingBiologicalStage.postAbsorptive:
        return const Color(0xFF42A5F5); // Blue
      case FastingBiologicalStage.ketosisOnset:
        return const Color(0xFF26C6DA); // Cyan
      case FastingBiologicalStage.autophagyActive:
        return const Color(0xFFAB47BC); // Neon Purple
      case FastingBiologicalStage.deepAutophagy:
        return const Color(0xFFFFB300); // Primary Amber / Gold
      case FastingBiologicalStage.stemCellReset:
        return const Color(0xFF00E676); // Emerald Green
    }
  }
}

/// An active or completed fasting session
class FastingSession {
  FastingSession({
    required this.id,
    required this.protocol,
    required this.targetDurationSeconds,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.sodiumLoggedMg = 0,
    this.waterLoggedMl = 0,
    List<FastingBiomarkerEntry>? biomarkers,
    this.energyRating,
    this.mentalClarityRating,
    this.hungerWaveRating,
    this.notes,
  }) : biomarkers = biomarkers ?? <FastingBiomarkerEntry>[];

  factory FastingSession.create({
    required String id,
    required FastingProtocol protocol,
    required DateTime startTime,
    int? customDurationHours,
  }) {
    final int hours =
        customDurationHours ?? protocol.targetHours;
    return FastingSession(
      id: id,
      protocol: protocol,
      targetDurationSeconds: hours * 3600,
      startTime: startTime,
    );
  }

  factory FastingSession.fromJson(Map<String, dynamic> json) {
    return FastingSession(
      id: json['id'] as String,
      protocol: FastingProtocol.values.firstWhere(
        (FastingProtocol p) => p.name == json['protocol'],
        orElse: () => FastingProtocol.intermittent16_8,
      ),
      targetDurationSeconds: json['targetDurationSeconds'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      sodiumLoggedMg: json['sodiumLoggedMg'] as int? ?? 0,
      waterLoggedMl: json['waterLoggedMl'] as int? ?? 0,
      biomarkers: json['biomarkers'] != null
          ? (json['biomarkers'] as List<dynamic>)
              .map((dynamic b) =>
                  FastingBiomarkerEntry.fromJson(b as Map<String, dynamic>))
              .toList()
          : <FastingBiomarkerEntry>[],
      energyRating: json['energyRating'] as int?,
      mentalClarityRating: json['mentalClarityRating'] as int?,
      hungerWaveRating: json['hungerWaveRating'] as int?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final FastingProtocol protocol;
  final int targetDurationSeconds;
  final DateTime startTime;
  DateTime? endTime;
  bool isCompleted;
  int sodiumLoggedMg;
  int waterLoggedMl;
  List<FastingBiomarkerEntry> biomarkers;
  int? energyRating; // 1-10
  int? mentalClarityRating; // 1-10
  int? hungerWaveRating; // 1-5
  String? notes;

  int get elapsedSeconds {
    final DateTime end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds.clamp(0, 86400 * 10);
  }

  double get elapsedHours => elapsedSeconds / 3600.0;

  int get remainingSeconds {
    final int rem = targetDurationSeconds - elapsedSeconds;
    return rem > 0 ? rem : 0;
  }

  double get progressRatio {
    if (targetDurationSeconds <= 0) {
      return 1.0;
    }
    return (elapsedSeconds / targetDurationSeconds).clamp(0.0, 1.0);
  }

  DateTime get targetEndTime =>
      startTime.add(Duration(seconds: targetDurationSeconds));

  FastingBiologicalStage get currentStage {
    final double hours = elapsedHours;
    if (hours < 4.0) {
      return FastingBiologicalStage.fed;
    }
    if (hours < 12.0) {
      return FastingBiologicalStage.postAbsorptive;
    }
    if (hours < 18.0) {
      return FastingBiologicalStage.ketosisOnset;
    }
    if (hours < 24.0) {
      return FastingBiologicalStage.autophagyActive;
    }
    if (hours < 48.0) {
      return FastingBiologicalStage.deepAutophagy;
    }
    return FastingBiologicalStage.stemCellReset;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'protocol': protocol.name,
      'targetDurationSeconds': targetDurationSeconds,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'isCompleted': isCompleted,
      'sodiumLoggedMg': sodiumLoggedMg,
      'waterLoggedMl': waterLoggedMl,
      'biomarkers': biomarkers
          .map((FastingBiomarkerEntry b) => b.toJson())
          .toList(),
      if (energyRating != null) 'energyRating': energyRating,
      if (mentalClarityRating != null)
        'mentalClarityRating': mentalClarityRating,
      if (hungerWaveRating != null) 'hungerWaveRating': hungerWaveRating,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Athlete circadian and schedule preferences for 6:00 AM lifting synchronization
class AthleteCircadianConfig {
  const AthleteCircadianConfig({
    this.wakeHour = 4,
    this.wakeMinute = 45,
    this.workoutHour = 6,
    this.workoutMinute = 0,
    this.bedHour = 20,
    this.bedMinute = 45,
    this.feedingCutoffHour = 18,
    this.feedingCutoffMinute = 0,
    this.waterRemindersEnabled = true,
    this.coffeeRemindersEnabled = true,
    this.dailyWaterTargetMl = 3000,
  });

  factory AthleteCircadianConfig.fromJson(Map<String, dynamic> json) {
    return AthleteCircadianConfig(
      wakeHour: json['wakeHour'] as int? ?? 4,
      wakeMinute: json['wakeMinute'] as int? ?? 45,
      workoutHour: json['workoutHour'] as int? ?? 6,
      workoutMinute: json['workoutMinute'] as int? ?? 0,
      bedHour: json['bedHour'] as int? ?? 20,
      bedMinute: json['bedMinute'] as int? ?? 45,
      feedingCutoffHour: json['feedingCutoffHour'] as int? ?? 18,
      feedingCutoffMinute: json['feedingCutoffMinute'] as int? ?? 0,
      waterRemindersEnabled:
          json['waterRemindersEnabled'] as bool? ?? true,
      coffeeRemindersEnabled:
          json['coffeeRemindersEnabled'] as bool? ?? true,
      dailyWaterTargetMl: json['dailyWaterTargetMl'] as int? ?? 3000,
    );
  }

  final int wakeHour;
  final int wakeMinute;
  final int workoutHour;
  final int workoutMinute;
  final int bedHour;
  final int bedMinute;
  final int feedingCutoffHour;
  final int feedingCutoffMinute;
  final bool waterRemindersEnabled;
  final bool coffeeRemindersEnabled;
  final int dailyWaterTargetMl;

  String get formattedWakeTime =>
      '${wakeHour.toString().padLeft(2, '0')}:${wakeMinute.toString().padLeft(2, '0')} AM';
  String get formattedWorkoutTime =>
      '${workoutHour.toString().padLeft(2, '0')}:${workoutMinute.toString().padLeft(2, '0')} AM';
  String get formattedBedTime => '8:45 PM';
  String get formattedFeedingCutoff => '6:00 PM';

  AthleteCircadianConfig copyWith({
    int? wakeHour,
    int? wakeMinute,
    int? workoutHour,
    int? workoutMinute,
    int? bedHour,
    int? bedMinute,
    int? feedingCutoffHour,
    int? feedingCutoffMinute,
    bool? waterRemindersEnabled,
    bool? coffeeRemindersEnabled,
    int? dailyWaterTargetMl,
  }) {
    return AthleteCircadianConfig(
      wakeHour: wakeHour ?? this.wakeHour,
      wakeMinute: wakeMinute ?? this.wakeMinute,
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
      bedHour: bedHour ?? this.bedHour,
      bedMinute: bedMinute ?? this.bedMinute,
      feedingCutoffHour: feedingCutoffHour ?? this.feedingCutoffHour,
      feedingCutoffMinute: feedingCutoffMinute ?? this.feedingCutoffMinute,
      waterRemindersEnabled:
          waterRemindersEnabled ?? this.waterRemindersEnabled,
      coffeeRemindersEnabled:
          coffeeRemindersEnabled ?? this.coffeeRemindersEnabled,
      dailyWaterTargetMl: dailyWaterTargetMl ?? this.dailyWaterTargetMl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'wakeHour': wakeHour,
      'wakeMinute': wakeMinute,
      'workoutHour': workoutHour,
      'workoutMinute': workoutMinute,
      'bedHour': bedHour,
      'bedMinute': bedMinute,
      'feedingCutoffHour': feedingCutoffHour,
      'feedingCutoffMinute': feedingCutoffMinute,
      'waterRemindersEnabled': waterRemindersEnabled,
      'coffeeRemindersEnabled': coffeeRemindersEnabled,
      'dailyWaterTargetMl': dailyWaterTargetMl,
    };
  }
}

/// A day in the 7-14 day forward fasting projection calendar
class FastingScheduleDay {
  const FastingScheduleDay({
    required this.date,
    required this.dayName,
    required this.protocol,
    required this.fastingStartHour,
    required this.fastingEndHour,
    required this.feedingWindowSummary,
    required this.workoutFocus,
    required this.isWorkoutDay,
    required this.notes,
  });

  final DateTime date;
  final String dayName;
  final FastingProtocol protocol;
  final String fastingStartHour;
  final String fastingEndHour;
  final String feedingWindowSummary;
  final String workoutFocus;
  final bool isWorkoutDay;
  final String notes;

  String get formattedDate => DateFormat('E, MMM d').format(date);
}
