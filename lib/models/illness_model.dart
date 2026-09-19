import 'package:uuid/uuid.dart';

enum IllnessSeverity {
  mildAboveNeck,
  systemicFever,
  respiratoryDeep,
  gastrointestinal,
}

extension IllnessSeverityExtension on IllnessSeverity {
  String get displayName {
    switch (this) {
      case IllnessSeverity.mildAboveNeck:
        return 'Above the Neck (Head Cold)';
      case IllnessSeverity.systemicFever:
        return 'Systemic Viral / Fever';
      case IllnessSeverity.respiratoryDeep:
        return 'Deep Chest / Respiratory';
      case IllnessSeverity.gastrointestinal:
        return 'Stomach Bug / GI Distress';
    }
  }

  String get shortLabel {
    switch (this) {
      case IllnessSeverity.mildAboveNeck:
        return 'Head Cold';
      case IllnessSeverity.systemicFever:
        return 'Systemic / Fever';
      case IllnessSeverity.respiratoryDeep:
        return 'Deep Respiratory';
      case IllnessSeverity.gastrointestinal:
        return 'GI / Stomach';
    }
  }

  String get clinicalGuidance {
    switch (this) {
      case IllnessSeverity.mildAboveNeck:
        return 'Neck Rule: Symptoms confined above neck. Light mobility and moderate tempo work permitted at -30% load. Avoid maximal ballistic efforts.';
      case IllnessSeverity.systemicFever:
        return 'Complete training cessation required. Exertion during fever imposes severe myocardial and renal stress. Prioritize hydration and rest.';
      case IllnessSeverity.respiratoryDeep:
        return 'Deep pulmonary strain impairs oxygen exchange and airway compliance. Training contraindicated. Rest and hydrate.';
      case IllnessSeverity.gastrointestinal:
        return 'Acute fluid and electrolyte loss. Strength training severely contraindicated due to hypovolemia and rhabdomyolysis risks.';
    }
  }
}

enum IllnessSymptom {
  runnyNose,
  nasalCongestion,
  soreThroat,
  sneezing,
  sinusPressure,
  headache,
  feverOrChills,
  muscleAches,
  deepChestCough,
  shortnessOfBreath,
  nauseaOrVomiting,
  gastrointestinalUpset,
  fatigueAndMalaise,
}

extension IllnessSymptomExtension on IllnessSymptom {
  String get displayName {
    switch (this) {
      case IllnessSymptom.runnyNose:
        return 'Runny Nose';
      case IllnessSymptom.nasalCongestion:
        return 'Nasal Congestion';
      case IllnessSymptom.soreThroat:
        return 'Sore Throat';
      case IllnessSymptom.sneezing:
        return 'Sneezing';
      case IllnessSymptom.sinusPressure:
        return 'Sinus Pressure';
      case IllnessSymptom.headache:
        return 'Headache';
      case IllnessSymptom.feverOrChills:
        return 'Fever / Chills';
      case IllnessSymptom.muscleAches:
        return 'Muscle / Body Aches';
      case IllnessSymptom.deepChestCough:
        return 'Deep Chest Cough';
      case IllnessSymptom.shortnessOfBreath:
        return 'Shortness of Breath';
      case IllnessSymptom.nauseaOrVomiting:
        return 'Nausea / Vomiting';
      case IllnessSymptom.gastrointestinalUpset:
        return 'Stomach / GI Upset';
      case IllnessSymptom.fatigueAndMalaise:
        return 'Extreme Fatigue / Malaise';
    }
  }

  bool get isBelowNeckOrSystemic {
    switch (this) {
      case IllnessSymptom.feverOrChills:
      case IllnessSymptom.muscleAches:
      case IllnessSymptom.deepChestCough:
      case IllnessSymptom.shortnessOfBreath:
      case IllnessSymptom.nauseaOrVomiting:
      case IllnessSymptom.gastrointestinalUpset:
        return true;
      default:
        return false;
    }
  }
}

enum ReEntryStage {
  stage0Acute,
  stage1LightRecovery,
  stage2ModerateVolume,
  stage3FullResumption,
}

extension ReEntryStageExtension on ReEntryStage {
  String get displayName {
    switch (this) {
      case ReEntryStage.stage0Acute:
        return 'Acute Illness Phase';
      case ReEntryStage.stage1LightRecovery:
        return 'Re-Entry Stage 1: Active Restoration';
      case ReEntryStage.stage2ModerateVolume:
        return 'Re-Entry Stage 2: Load Re-Introduction';
      case ReEntryStage.stage3FullResumption:
        return 'Re-Entry Stage 3: Full Training Cleared';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReEntryStage.stage0Acute:
        return 'Acute';
      case ReEntryStage.stage1LightRecovery:
        return 'Stage 1 (50%)';
      case ReEntryStage.stage2ModerateVolume:
        return 'Stage 2 (70%)';
      case ReEntryStage.stage3FullResumption:
        return 'Cleared (100%)';
    }
  }

  double get loadCapPercentage {
    switch (this) {
      case ReEntryStage.stage0Acute:
        return 0;
      case ReEntryStage.stage1LightRecovery:
        return 0.50;
      case ReEntryStage.stage2ModerateVolume:
        return 0.70;
      case ReEntryStage.stage3FullResumption:
        return 1;
    }
  }

  String get prescription {
    switch (this) {
      case ReEntryStage.stage0Acute:
        return 'Rest and sleep. No high-intensity exertion.';
      case ReEntryStage.stage1LightRecovery:
        return 'Cap loads at 50%. Focus on 20-30 min Zone 1 walking, restorative mobility, and light barbell technique drills.';
      case ReEntryStage.stage2ModerateVolume:
        return 'Cap loads at 70%. Moderate volume, RPE cap 7. Avoid maximal lifts to failure.';
      case ReEntryStage.stage3FullResumption:
        return 'Full physiological clearance. Resume scheduled cycle programming.';
    }
  }
}

class IllnessRecord {
  const new({
    required this.id,
    required this.onsetDate,
    required this.severity,
    this.resolvedDate,
    this.symptoms = const <IllnessSymptom>[],
    this.hasFever = false,
    this.temperatureCelsius,
    this.notes,
    this.reEntryStage = ReEntryStage.stage0Acute,
    this.reEntryStageStartedAt,
    this.isTrainingFrozen = true,
  });

  factory createNew({
    required IllnessSeverity severity,
    List<IllnessSymptom> symptoms = const <IllnessSymptom>[],
    bool hasFever = false,
    double? temperatureCelsius,
    String? notes,
    bool isTrainingFrozen = true,
  }) {
    return IllnessRecord(
      id: const Uuid().v4(),
      onsetDate: DateTime.now(),
      severity: severity,
      symptoms: symptoms,
      hasFever: hasFever,
      temperatureCelsius: temperatureCelsius,
      notes: notes,
      reEntryStageStartedAt: DateTime.now(),
      isTrainingFrozen: isTrainingFrozen,
    );
  }

  factory fromJson(Map<String, dynamic> json) {
    return IllnessRecord(
      id: json['id'] as String,
      onsetDate: DateTime.parse(json['onsetDate'] as String),
      resolvedDate: json['resolvedDate'] != null
          ? DateTime.parse(json['resolvedDate'] as String)
          : null,
      severity: IllnessSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => IllnessSeverity.mildAboveNeck,
      ),
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map(
                (e) => IllnessSymptom.values.firstWhere(
                  (s) => s.name == e,
                  orElse: () => IllnessSymptom.fatigueAndMalaise,
                ),
              )
              .toList() ??
          <IllnessSymptom>[],
      hasFever: json['hasFever'] as bool? ?? false,
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      reEntryStage: ReEntryStage.values.firstWhere(
        (e) => e.name == json['reEntryStage'],
        orElse: () => ReEntryStage.stage0Acute,
      ),
      reEntryStageStartedAt: json['reEntryStageStartedAt'] != null
          ? DateTime.parse(json['reEntryStageStartedAt'] as String)
          : null,
      isTrainingFrozen: json['isTrainingFrozen'] as bool? ?? true,
    );
  }

  final String id;
  final DateTime onsetDate;
  final DateTime? resolvedDate;
  final IllnessSeverity severity;
  final List<IllnessSymptom> symptoms;
  final bool hasFever;
  final double? temperatureCelsius;
  final String? notes;
  final ReEntryStage reEntryStage;
  final DateTime? reEntryStageStartedAt;
  final bool isTrainingFrozen;

  bool get isActive =>
      resolvedDate == null && reEntryStage == ReEntryStage.stage0Acute;

  bool get isConvalescing =>
      reEntryStage == ReEntryStage.stage1LightRecovery ||
      reEntryStage == ReEntryStage.stage2ModerateVolume;

  bool get isFullyResolved =>
      reEntryStage == ReEntryStage.stage3FullResumption ||
      (resolvedDate != null && !isConvalescing);

  int get readinessDeduction {
    if (isActive) {
      switch (severity) {
        case IllnessSeverity.systemicFever:
          return 70;
        case IllnessSeverity.respiratoryDeep:
          return 55;
        case IllnessSeverity.gastrointestinal:
          return 60;
        case IllnessSeverity.mildAboveNeck:
          return 25;
      }
    } else if (isConvalescing) {
      switch (reEntryStage) {
        case ReEntryStage.stage1LightRecovery:
          return 30;
        case ReEntryStage.stage2ModerateVolume:
          return 15;
        default:
          return 0;
      }
    }
    return 0;
  }

  double get suggestedLoadScale {
    if (isActive) {
      if (severity == IllnessSeverity.mildAboveNeck) {
        return 0.70;
      }
      return 0;
    }
    return reEntryStage.loadCapPercentage;
  }

  bool get isBallisticContraindicated =>
      isActive &&
      (hasFever ||
          severity == IllnessSeverity.systemicFever ||
          severity == IllnessSeverity.respiratoryDeep);

  bool get isFastingContraindicated =>
      isActive &&
      (hasFever ||
          severity == IllnessSeverity.systemicFever ||
          severity == IllnessSeverity.gastrointestinal);

  bool get isWimHofContraindicated =>
      isActive &&
      (hasFever ||
          severity == IllnessSeverity.systemicFever ||
          severity == IllnessSeverity.respiratoryDeep);

  int get hydrationBonusMl {
    if (!isActive) return 250;
    if (hasFever || severity == IllnessSeverity.gastrointestinal) {
      return 1000;
    }
    if (severity == IllnessSeverity.respiratoryDeep ||
        severity == IllnessSeverity.systemicFever) {
      return 750;
    }
    if (severity == IllnessSeverity.mildAboveNeck) {
      return 500;
    }
    return 250;
  }

  IllnessRecord copyWith({
    String? id,
    DateTime? onsetDate,
    DateTime? resolvedDate,
    IllnessSeverity? severity,
    List<IllnessSymptom>? symptoms,
    bool? hasFever,
    double? temperatureCelsius,
    String? notes,
    ReEntryStage? reEntryStage,
    DateTime? reEntryStageStartedAt,
    bool? isTrainingFrozen,
  }) {
    return IllnessRecord(
      id: id ?? this.id,
      onsetDate: onsetDate ?? this.onsetDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      severity: severity ?? this.severity,
      symptoms: symptoms ?? this.symptoms,
      hasFever: hasFever ?? this.hasFever,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      notes: notes ?? this.notes,
      reEntryStage: reEntryStage ?? this.reEntryStage,
      reEntryStageStartedAt:
          reEntryStageStartedAt ?? this.reEntryStageStartedAt,
      isTrainingFrozen: isTrainingFrozen ?? this.isTrainingFrozen,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'onsetDate': onsetDate.toIso8601String(),
      'resolvedDate': resolvedDate?.toIso8601String(),
      'severity': severity.name,
      'symptoms': symptoms.map((s) => s.name).toList(),
      'hasFever': hasFever,
      'temperatureCelsius': temperatureCelsius,
      'notes': notes,
      'reEntryStage': reEntryStage.name,
      'reEntryStageStartedAt': reEntryStageStartedAt?.toIso8601String(),
      'isTrainingFrozen': isTrainingFrozen,
    };
  }
}
