import 'package:oly/models/mobility_exercise_model.dart';

enum InjuryRegion {
  neck,
  leftShoulder,
  rightShoulder,
  chestPecs,
  thoracicSpine,
  lumbarSpine,
  coreAbs,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHipGlute,
  rightHipGlute,
  leftQuad,
  rightQuad,
  leftHamstring,
  rightHamstring,
  leftKnee,
  rightKnee,
  leftCalfAnkle,
  rightCalfAnkle,
}

extension InjuryRegionExtension on InjuryRegion {
  String get displayName {
    switch (this) {
      case InjuryRegion.neck:
        return 'Neck / Cervical';
      case InjuryRegion.leftShoulder:
        return 'Left Shoulder';
      case InjuryRegion.rightShoulder:
        return 'Right Shoulder';
      case InjuryRegion.chestPecs:
        return 'Chest / Pecs';
      case InjuryRegion.thoracicSpine:
        return 'Upper / Mid Back';
      case InjuryRegion.lumbarSpine:
        return 'Lower Back (Lumbar)';
      case InjuryRegion.coreAbs:
        return 'Core / Abdominals';
      case InjuryRegion.leftElbow:
        return 'Left Elbow';
      case InjuryRegion.rightElbow:
        return 'Right Elbow';
      case InjuryRegion.leftWrist:
        return 'Left Wrist';
      case InjuryRegion.rightWrist:
        return 'Right Wrist';
      case InjuryRegion.leftHipGlute:
        return 'Left Hip & Glute';
      case InjuryRegion.rightHipGlute:
        return 'Right Hip & Glute';
      case InjuryRegion.leftQuad:
        return 'Left Quadriceps';
      case InjuryRegion.rightQuad:
        return 'Right Quadriceps';
      case InjuryRegion.leftHamstring:
        return 'Left Hamstring';
      case InjuryRegion.rightHamstring:
        return 'Right Hamstring';
      case InjuryRegion.leftKnee:
        return 'Left Knee';
      case InjuryRegion.rightKnee:
        return 'Right Knee';
      case InjuryRegion.leftCalfAnkle:
        return 'Left Calf & Ankle';
      case InjuryRegion.rightCalfAnkle:
        return 'Right Calf & Ankle';
    }
  }

  bool get isPosteriorDefault {
    switch (this) {
      case InjuryRegion.thoracicSpine:
      case InjuryRegion.lumbarSpine:
      case InjuryRegion.leftHamstring:
      case InjuryRegion.rightHamstring:
        return true;
      default:
        return false;
    }
  }
}

enum InjurySeverity {
  mild,     // Pain 1 - 3
  moderate, // Pain 4 - 6
  severe,   // Pain 7 - 10
}

extension InjurySeverityExtension on InjurySeverity {
  String get displayName {
    switch (this) {
      case InjurySeverity.mild:
        return 'Mild (1-3)';
      case InjurySeverity.moderate:
        return 'Moderate (4-6)';
      case InjurySeverity.severe:
        return 'Severe (7-10)';
    }
  }

  static InjurySeverity fromPain(int pain) {
    if (pain <= 3) {
      return InjurySeverity.mild;
    }
    if (pain <= 6) {
      return InjurySeverity.moderate;
    }
    return InjurySeverity.severe;
  }
}

enum InjuryStage {
  acute,    // < 14 days
  subacute, // 14 - 42 days (2 - 6 weeks)
  chronic,  // > 42 days (6+ weeks)
}

extension InjuryStageExtension on InjuryStage {
  String get label {
    switch (this) {
      case InjuryStage.acute:
        return 'ACUTE';
      case InjuryStage.subacute:
        return 'SUBACUTE';
      case InjuryStage.chronic:
        return 'CHRONIC';
    }
  }

  String get description {
    switch (this) {
      case InjuryStage.acute:
        return 'Recent onset (< 2 weeks) - Active protection and inflammation control.';
      case InjuryStage.subacute:
        return 'Healing phase (2-6 weeks) - Progressive remodeling and controlled tempo loading.';
      case InjuryStage.chronic:
        return 'Persistent (6+ weeks) - Movement pattern modification and capacity building.';
    }
  }
}

enum BiomechanicalConstraint {
  avoidDeepKneeFlexion,
  avoidOverheadLockout,
  avoidAxialSpinalShear,
  avoidFloorPullShear,
  avoidWristExtension,
  avoidBallisticCatchImpact,
  avoidHeavyEccentricStretch,
  avoidAggressiveHipHinge,
}

extension BiomechanicalConstraintExtension on BiomechanicalConstraint {
  String get displayName {
    switch (this) {
      case BiomechanicalConstraint.avoidDeepKneeFlexion:
        return 'Limit Deep Knee Flexion';
      case BiomechanicalConstraint.avoidOverheadLockout:
        return 'Limit Overhead Lockout';
      case BiomechanicalConstraint.avoidAxialSpinalShear:
        return 'Limit Spinal Axial Compression';
      case BiomechanicalConstraint.avoidFloorPullShear:
        return 'Limit Floor Pulls';
      case BiomechanicalConstraint.avoidWristExtension:
        return 'Limit Wrist Extension Rack';
      case BiomechanicalConstraint.avoidBallisticCatchImpact:
        return 'Avoid Ballistic Catch Shock';
      case BiomechanicalConstraint.avoidHeavyEccentricStretch:
        return 'Limit Deep Eccentric Stretch';
      case BiomechanicalConstraint.avoidAggressiveHipHinge:
        return 'Limit Forward Hip Hinge';
    }
  }
}

class InjurySubstitution {
  InjurySubstitution({
    required this.targetExercise,
    required this.replacementName,
    required this.replacementLiftId,
    required this.weightMultiplier,
    required this.rationale,
  });

  factory InjurySubstitution.fromJson(Map<String, dynamic> json) {
    return InjurySubstitution(
      targetExercise: json['targetExercise'] as String? ?? '',
      replacementName: json['replacementName'] as String? ?? '',
      replacementLiftId: json['replacementLiftId'] as String? ?? '',
      weightMultiplier: (json['weightMultiplier'] as num?)?.toDouble() ?? 1.0,
      rationale: json['rationale'] as String? ?? '',
    );
  }

  final String targetExercise;
  final String replacementName;
  final String replacementLiftId;
  final double weightMultiplier;
  final String rationale;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'targetExercise': targetExercise,
      'replacementName': replacementName,
      'replacementLiftId': replacementLiftId,
      'weightMultiplier': weightMultiplier,
      'rationale': rationale,
    };
  }
}

class CatalogInjury {
  CatalogInjury({
    required this.id,
    required this.osiicsCode,
    required this.name,
    required this.region,
    required this.supportedRegions,
    required this.description,
    required this.acuteDurationDays,
    required this.chronicThresholdDays,
    required this.aggravatingVectors,
    required this.contraindicatedLifts,
    required this.safeSubstitutions,
    required this.rehabFocusAreas,
    required this.rehabCues,
  });

  factory CatalogInjury.fromJson(Map<String, dynamic> json) {
    return CatalogInjury(
      id: json['id'] as String,
      osiicsCode: json['osiicsCode'] as String? ?? '',
      name: json['name'] as String,
      region: InjuryRegion.values.firstWhere(
        (InjuryRegion r) => r.name == json['region'],
        orElse: () => InjuryRegion.leftKnee,
      ),
      supportedRegions: (json['supportedRegions'] as List<dynamic>?)
              ?.map(
                (dynamic e) => InjuryRegion.values.firstWhere(
                  (InjuryRegion r) => r.name == e,
                  orElse: () => InjuryRegion.leftKnee,
                ),
              )
              .toList() ??
          <InjuryRegion>[],
      description: json['description'] as String? ?? '',
      acuteDurationDays: json['acuteDurationDays'] as int? ?? 14,
      chronicThresholdDays: json['chronicThresholdDays'] as int? ?? 42,
      aggravatingVectors: (json['aggravatingVectors'] as List<dynamic>?)
              ?.map(
                (dynamic e) => BiomechanicalConstraint.values.firstWhere(
                  (BiomechanicalConstraint c) => c.name == e,
                  orElse: () => BiomechanicalConstraint.avoidDeepKneeFlexion,
                ),
              )
              .toList() ??
          <BiomechanicalConstraint>[],
      contraindicatedLifts: (json['contraindicatedLifts'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
      safeSubstitutions: (json['safeSubstitutions'] as List<dynamic>?)
              ?.map((dynamic e) => InjurySubstitution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <InjurySubstitution>[],
      rehabFocusAreas: (json['rehabFocusAreas'] as List<dynamic>?)
              ?.map(
                (dynamic e) => MobilityFocusArea.values.firstWhere(
                  (MobilityFocusArea f) => f.name == e,
                  orElse: () => MobilityFocusArea.hipCapsule,
                ),
              )
              .toList() ??
          <MobilityFocusArea>[],
      rehabCues: (json['rehabCues'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
    );
  }

  final String id;
  final String osiicsCode;
  final String name;
  final InjuryRegion region;
  final List<InjuryRegion> supportedRegions;
  final String description;
  final int acuteDurationDays;
  final int chronicThresholdDays;
  final List<BiomechanicalConstraint> aggravatingVectors;
  final List<String> contraindicatedLifts;
  final List<InjurySubstitution> safeSubstitutions;
  final List<MobilityFocusArea> rehabFocusAreas;
  final List<String> rehabCues;
}

class InjuryHistoryEntry {
  InjuryHistoryEntry({
    required this.date,
    required this.painScale,
    this.notes = '',
    this.sessionRpe,
  });

  factory InjuryHistoryEntry.fromJson(Map<String, dynamic> json) {
    return InjuryHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      painScale: json['painScale'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
      sessionRpe: json['sessionRpe'] as int?,
    );
  }

  final DateTime date;
  final int painScale;
  final String notes;
  final int? sessionRpe;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'painScale': painScale,
      'notes': notes,
      'sessionRpe': sessionRpe,
    };
  }
}

class InjuryRecord {
  InjuryRecord({
    required this.id,
    required this.name,
    required this.region,
    required this.onsetDate,
    required this.painScale,
    this.osiicsCode = '',
    this.constraints = const <BiomechanicalConstraint>[],
    this.notes = '',
    this.isActive = true,
    this.resolvedAt,
    List<InjuryHistoryEntry>? history,
    this.safeSubstitutions = const <InjurySubstitution>[],
    this.rehabFocusAreas = const <MobilityFocusArea>[],
    this.rehabCues = const <String>[],
  }) : history = history ?? <InjuryHistoryEntry>[];

  factory InjuryRecord.fromJson(Map<String, dynamic> json) {
    return InjuryRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      osiicsCode: json['osiicsCode'] as String? ?? '',
      region: InjuryRegion.values.firstWhere(
        (InjuryRegion r) => r.name == json['region'],
        orElse: () => InjuryRegion.leftKnee,
      ),
      onsetDate: DateTime.parse(json['onsetDate'] as String),
      painScale: json['painScale'] as int? ?? 3,
      constraints: (json['constraints'] as List<dynamic>?)
              ?.map(
                (dynamic e) => BiomechanicalConstraint.values.firstWhere(
                  (BiomechanicalConstraint c) => c.name == e,
                  orElse: () => BiomechanicalConstraint.avoidDeepKneeFlexion,
                ),
              )
              .toList() ??
          <BiomechanicalConstraint>[],
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      history: (json['history'] as List<dynamic>?)
              ?.map((dynamic e) => InjuryHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <InjuryHistoryEntry>[],
      safeSubstitutions: (json['safeSubstitutions'] as List<dynamic>?)
              ?.map((dynamic e) => InjurySubstitution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <InjurySubstitution>[],
      rehabFocusAreas: (json['rehabFocusAreas'] as List<dynamic>?)
              ?.map(
                (dynamic e) => MobilityFocusArea.values.firstWhere(
                  (MobilityFocusArea f) => f.name == e,
                  orElse: () => MobilityFocusArea.hipCapsule,
                ),
              )
              .toList() ??
          <MobilityFocusArea>[],
      rehabCues: (json['rehabCues'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
    );
  }

  final String id;
  final String name;
  final String osiicsCode;
  final InjuryRegion region;
  final DateTime onsetDate;
  int painScale; // 1 to 10
  final List<BiomechanicalConstraint> constraints;
  String notes;
  bool isActive;
  DateTime? resolvedAt;
  final List<InjuryHistoryEntry> history;
  final List<InjurySubstitution> safeSubstitutions;
  final List<MobilityFocusArea> rehabFocusAreas;
  final List<String> rehabCues;

  InjurySeverity get severity => InjurySeverityExtension.fromPain(painScale);

  int get durationInDays {
    final DateTime endDate = resolvedAt ?? DateTime.now();
    return endDate.difference(onsetDate).inDays.clamp(0, 9999);
  }

  InjuryStage get stage {
    if (durationInDays < 14) {
      return InjuryStage.acute;
    }
    if (durationInDays <= 42) {
      return InjuryStage.subacute;
    }
    return InjuryStage.chronic;
  }

  String get formattedDuration {
    final int days = durationInDays;
    if (days == 0) {
      return 'Today';
    }
    if (days == 1) {
      return '1 day';
    }
    if (days < 14) {
      return '$days days';
    }
    final int weeks = (days / 7).floor();
    if (weeks < 8) {
      return '$weeks weeks ($days d)';
    }
    final int months = (days / 30).floor();
    return '$months+ months ($days d)';
  }

  InjuryRecord copyWith({
    String? id,
    String? name,
    String? osiicsCode,
    InjuryRegion? region,
    DateTime? onsetDate,
    int? painScale,
    List<BiomechanicalConstraint>? constraints,
    String? notes,
    bool? isActive,
    DateTime? resolvedAt,
    List<InjuryHistoryEntry>? history,
    List<InjurySubstitution>? safeSubstitutions,
    List<MobilityFocusArea>? rehabFocusAreas,
    List<String>? rehabCues,
  }) {
    return InjuryRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      osiicsCode: osiicsCode ?? this.osiicsCode,
      region: region ?? this.region,
      onsetDate: onsetDate ?? this.onsetDate,
      painScale: painScale ?? this.painScale,
      constraints: constraints ?? List<BiomechanicalConstraint>.from(this.constraints),
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      history: history ?? List<InjuryHistoryEntry>.from(this.history),
      safeSubstitutions: safeSubstitutions ?? List<InjurySubstitution>.from(this.safeSubstitutions),
      rehabFocusAreas: rehabFocusAreas ?? List<MobilityFocusArea>.from(this.rehabFocusAreas),
      rehabCues: rehabCues ?? List<String>.from(this.rehabCues),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'osiicsCode': osiicsCode,
      'region': region.name,
      'onsetDate': onsetDate.toIso8601String(),
      'painScale': painScale,
      'constraints': constraints.map((BiomechanicalConstraint c) => c.name).toList(),
      'notes': notes,
      'isActive': isActive,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'history': history.map((InjuryHistoryEntry h) => h.toJson()).toList(),
      'safeSubstitutions': safeSubstitutions.map((InjurySubstitution s) => s.toJson()).toList(),
      'rehabFocusAreas': rehabFocusAreas.map((MobilityFocusArea f) => f.name).toList(),
      'rehabCues': rehabCues,
    };
  }
}

class InjuryCheckinDiff {
  InjuryCheckinDiff({
    required this.region,
    required this.initialPain,
    required this.postPain,
    this.notes = '',
  });

  final InjuryRegion region;
  final int initialPain;
  final int postPain;
  final String notes;

  int get deltaPain => postPain - initialPain;
  bool get hasWorsened => deltaPain > 0;
  bool get hasImproved => deltaPain < 0;
  bool get isUnchanged => deltaPain == 0;
}
