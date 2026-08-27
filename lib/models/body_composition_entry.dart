import 'package:uuid/uuid.dart';

class BodyCompositionEntry {
  final String id;
  final DateTime timestamp;
  final double weightLb;
  final double? bmi;
  final double? bodyFatPct;
  final double? bodyFatLb;
  final double? skeletalMuscleLb;
  final double? skeletalMusclePct;
  final double? fatFreeMassLb; // Lean Body Mass (LBM)
  final double? subcutaneousFatPct;
  final int? visceralFat;
  final double? bodyWaterLb;
  final double? bodyWaterPct;
  final double? muscleMassLb;
  final double? muscleMassPct;
  final double? boneMassLb;
  final double? boneMassPct;
  final double? proteinLb;
  final double? proteinPct;
  final int? bmrKcal;
  final int? metabolicAge;
  final String source; // 'renpho_ocr', 'manual'
  final String? notes;

  const BodyCompositionEntry({
    required this.id,
    required this.timestamp,
    required this.weightLb,
    this.bmi,
    this.bodyFatPct,
    this.bodyFatLb,
    this.skeletalMuscleLb,
    this.skeletalMusclePct,
    this.fatFreeMassLb,
    this.subcutaneousFatPct,
    this.visceralFat,
    this.bodyWaterLb,
    this.bodyWaterPct,
    this.muscleMassLb,
    this.muscleMassPct,
    this.boneMassLb,
    this.boneMassPct,
    this.proteinLb,
    this.proteinPct,
    this.bmrKcal,
    this.metabolicAge,
    this.source = 'renpho_ocr',
    this.notes,
  });

  factory BodyCompositionEntry.create({
    String? id,
    DateTime? timestamp,
    required double weightLb,
    double? bmi,
    double? bodyFatPct,
    double? bodyFatLb,
    double? skeletalMuscleLb,
    double? skeletalMusclePct,
    double? fatFreeMassLb,
    double? subcutaneousFatPct,
    int? visceralFat,
    double? bodyWaterLb,
    double? bodyWaterPct,
    double? muscleMassLb,
    double? muscleMassPct,
    double? boneMassLb,
    double? boneMassPct,
    double? proteinLb,
    double? proteinPct,
    int? bmrKcal,
    int? metabolicAge,
    String source = 'renpho_ocr',
    String? notes,
  }) {
    final calculatedFatLb = bodyFatLb ?? (bodyFatPct != null ? (weightLb * bodyFatPct / 100) : null);
    final calculatedFatFreeLb = fatFreeMassLb ?? (calculatedFatLb != null ? (weightLb - calculatedFatLb) : null);

    return BodyCompositionEntry(
      id: id ?? const Uuid().v4(),
      timestamp: timestamp ?? DateTime.now(),
      weightLb: weightLb,
      bmi: bmi ?? (weightLb > 0 ? (weightLb / (70 * 70) * 703) : null), // Estimate if unknown
      bodyFatPct: bodyFatPct ?? (calculatedFatLb != null ? (calculatedFatLb / weightLb * 100) : null),
      bodyFatLb: calculatedFatLb,
      skeletalMuscleLb: skeletalMuscleLb,
      skeletalMusclePct: skeletalMusclePct,
      fatFreeMassLb: calculatedFatFreeLb,
      subcutaneousFatPct: subcutaneousFatPct,
      visceralFat: visceralFat,
      bodyWaterLb: bodyWaterLb,
      bodyWaterPct: bodyWaterPct,
      muscleMassLb: muscleMassLb,
      muscleMassPct: muscleMassPct,
      boneMassLb: boneMassLb,
      boneMassPct: boneMassPct,
      proteinLb: proteinLb,
      proteinPct: proteinPct,
      bmrKcal: bmrKcal,
      metabolicAge: metabolicAge,
      source: source,
      notes: notes,
    );
  }

  /// Lean Body Mass in pounds
  double get leanBodyMassLb => fatFreeMassLb ?? (weightLb - (bodyFatLb ?? 0));

  /// Lean Body Mass in kilograms
  double get leanBodyMassKg => leanBodyMassLb / 2.20462;

  /// Weight in kilograms
  double get weightKg => weightLb / 2.20462;

  /// Total fat mass in pounds
  double get fatMassLb => bodyFatLb ?? (bodyFatPct != null ? (weightLb * bodyFatPct! / 100) : 0);

  /// Katch-McArdle formula for Basal Metabolic Rate using actual Lean Body Mass:
  /// BMR = 370 + (21.6 * LBM in kg)
  int get katchMcArdleBmr {
    final lbmKg = leanBodyMassKg;
    if (lbmKg <= 0) return bmrKcal ?? 2000;
    return (370 + (21.6 * lbmKg)).round();
  }

  /// Calculates target bodyweight to achieve a target body fat percentage
  /// while preserving 100% of current Lean Body Mass (LBM):
  /// Target Weight = LBM / (1 - Target BF %)
  double targetWeightForBodyFat(double targetBfPct) {
    final lbm = leanBodyMassLb;
    if (lbm <= 0 || targetBfPct <= 0 || targetBfPct >= 100) return weightLb;
    final targetBfDecimal = targetBfPct / 100.0;
    return lbm / (1.0 - targetBfDecimal);
  }

  /// Calculates pure fat to lose to reach a target body fat percentage
  double fatToLoseForTargetBf(double targetBfPct) {
    final targetWeight = targetWeightForBodyFat(targetBfPct);
    return (weightLb - targetWeight).clamp(0.0, weightLb);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'weightLb': weightLb,
      'bmi': bmi,
      'bodyFatPct': bodyFatPct,
      'bodyFatLb': bodyFatLb,
      'skeletalMuscleLb': skeletalMuscleLb,
      'skeletalMusclePct': skeletalMusclePct,
      'fatFreeMassLb': fatFreeMassLb,
      'subcutaneousFatPct': subcutaneousFatPct,
      'visceralFat': visceralFat,
      'bodyWaterLb': bodyWaterLb,
      'bodyWaterPct': bodyWaterPct,
      'muscleMassLb': muscleMassLb,
      'muscleMassPct': muscleMassPct,
      'boneMassLb': boneMassLb,
      'boneMassPct': boneMassPct,
      'proteinLb': proteinLb,
      'proteinPct': proteinPct,
      'bmrKcal': bmrKcal,
      'metabolicAge': metabolicAge,
      'source': source,
      'notes': notes,
    };
  }

  factory BodyCompositionEntry.fromJson(Map<String, dynamic> json) {
    return BodyCompositionEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      weightLb: (json['weightLb'] as num).toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bodyFatPct: (json['bodyFatPct'] as num?)?.toDouble(),
      bodyFatLb: (json['bodyFatLb'] as num?)?.toDouble(),
      skeletalMuscleLb: (json['skeletalMuscleLb'] as num?)?.toDouble(),
      skeletalMusclePct: (json['skeletalMusclePct'] as num?)?.toDouble(),
      fatFreeMassLb: (json['fatFreeMassLb'] as num?)?.toDouble(),
      subcutaneousFatPct: (json['subcutaneousFatPct'] as num?)?.toDouble(),
      visceralFat: json['visceralFat'] as int?,
      bodyWaterLb: (json['bodyWaterLb'] as num?)?.toDouble(),
      bodyWaterPct: (json['bodyWaterPct'] as num?)?.toDouble(),
      muscleMassLb: (json['muscleMassLb'] as num?)?.toDouble(),
      muscleMassPct: (json['muscleMassPct'] as num?)?.toDouble(),
      boneMassLb: (json['boneMassLb'] as num?)?.toDouble(),
      boneMassPct: (json['boneMassPct'] as num?)?.toDouble(),
      proteinLb: (json['proteinLb'] as num?)?.toDouble(),
      proteinPct: (json['proteinPct'] as num?)?.toDouble(),
      bmrKcal: json['bmrKcal'] as int?,
      metabolicAge: json['metabolicAge'] as int?,
      source: json['source'] as String? ?? 'renpho_ocr',
      notes: json['notes'] as String?,
    );
  }

  BodyCompositionEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? weightLb,
    double? bmi,
    double? bodyFatPct,
    double? bodyFatLb,
    double? skeletalMuscleLb,
    double? skeletalMusclePct,
    double? fatFreeMassLb,
    double? subcutaneousFatPct,
    int? visceralFat,
    double? bodyWaterLb,
    double? bodyWaterPct,
    double? muscleMassLb,
    double? muscleMassPct,
    double? boneMassLb,
    double? boneMassPct,
    double? proteinLb,
    double? proteinPct,
    int? bmrKcal,
    int? metabolicAge,
    String? source,
    String? notes,
  }) {
    return BodyCompositionEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weightLb: weightLb ?? this.weightLb,
      bmi: bmi ?? this.bmi,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      bodyFatLb: bodyFatLb ?? this.bodyFatLb,
      skeletalMuscleLb: skeletalMuscleLb ?? this.skeletalMuscleLb,
      skeletalMusclePct: skeletalMusclePct ?? this.skeletalMusclePct,
      fatFreeMassLb: fatFreeMassLb ?? this.fatFreeMassLb,
      subcutaneousFatPct: subcutaneousFatPct ?? this.subcutaneousFatPct,
      visceralFat: visceralFat ?? this.visceralFat,
      bodyWaterLb: bodyWaterLb ?? this.bodyWaterLb,
      bodyWaterPct: bodyWaterPct ?? this.bodyWaterPct,
      muscleMassLb: muscleMassLb ?? this.muscleMassLb,
      muscleMassPct: muscleMassPct ?? this.muscleMassPct,
      boneMassLb: boneMassLb ?? this.boneMassLb,
      boneMassPct: boneMassPct ?? this.boneMassPct,
      proteinLb: proteinLb ?? this.proteinLb,
      proteinPct: proteinPct ?? this.proteinPct,
      bmrKcal: bmrKcal ?? this.bmrKcal,
      metabolicAge: metabolicAge ?? this.metabolicAge,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }
}
