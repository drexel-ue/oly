import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/services/tdee_calculator_service.dart';

enum GoalType {
  cutting,
  leanBulking,
  recomposition,
  maintenance;

  String get displayName {
    switch (this) {
      case GoalType.cutting:
        return 'Fat Loss (Cut)';
      case GoalType.leanBulking:
        return 'Hypertrophy (Bulk)';
      case GoalType.recomposition:
        return 'Recomposition (Recomp)';
      case GoalType.maintenance:
        return 'Performance Maintenance';
    }
  }

  String get description {
    switch (this) {
      case GoalType.cutting:
        return 'Preserve maximum lean mass while losing fat in a controlled caloric deficit.';
      case GoalType.leanBulking:
        return 'Maximize power, strength, and muscle growth with a clean caloric surplus.';
      case GoalType.recomposition:
        return 'Simultaneously build strength & muscle while reducing body fat near maintenance.';
      case GoalType.maintenance:
        return 'Sustain current bodyweight and fuel peak Olympic weightlifting performance.';
    }
  }
}

class NutritionGoalModel {
  // Custom water goal override if user sets one

  const NutritionGoalModel({
    this.goalType = GoalType.recomposition,
    this.targetBodyFatPct = 15.0,
    this.targetWeightLb,
    this.proteinGramsPerLbLbm = 1.05,
    this.dailyCalorieAdjustment = 0,
    this.carbCyclingEnabled = true,
    this.trainingDayBonusCalories = 250,
    this.trainingDayCarbBonusGrams = 45.0,
    this.baseTdeeEstimate = 2800,
    this.customDailyWaterGoalOz,
  });

  factory NutritionGoalModel.fromJson(Map<String, dynamic> json) {
    return NutritionGoalModel(
      goalType: GoalType.values.firstWhere(
        (GoalType g) => g.name == (json['goalType'] as String?),
        orElse: () => GoalType.recomposition,
      ),
      targetBodyFatPct: (json['targetBodyFatPct'] as num?)?.toDouble() ?? 15.0,
      targetWeightLb: (json['targetWeightLb'] as num?)?.toDouble(),
      proteinGramsPerLbLbm:
          (json['proteinGramsPerLbLbm'] as num?)?.toDouble() ?? 1.05,
      dailyCalorieAdjustment: json['dailyCalorieAdjustment'] as int? ?? 0,
      carbCyclingEnabled: json['carbCyclingEnabled'] as bool? ?? true,
      trainingDayBonusCalories: json['trainingDayBonusCalories'] as int? ?? 250,
      trainingDayCarbBonusGrams:
          (json['trainingDayCarbBonusGrams'] as num?)?.toDouble() ?? 45.0,
      baseTdeeEstimate: json['baseTdeeEstimate'] as int? ?? 2800,
      customDailyWaterGoalOz: (json['customDailyWaterGoalOz'] as num?)
          ?.toDouble(),
    );
  }
  final GoalType goalType;
  final double targetBodyFatPct; // e.g. 15.0%
  final double? targetWeightLb;
  final double proteinGramsPerLbLbm; // e.g. 1.0 - 1.2 g/lb Lean Body Mass
  final int dailyCalorieAdjustment; // e.g. -400 for cut, +250 for bulk
  final bool carbCyclingEnabled;
  final int
  trainingDayBonusCalories; // e.g. +200 kcal on Snatch/Clean & Jerk days
  final double
  trainingDayCarbBonusGrams; // e.g. +40g Carbs on heavy lifting days
  final int baseTdeeEstimate;
  final double? customDailyWaterGoalOz;

  /// Calculates dynamic daily water goal based on body composition and training status
  double getRecommendedWaterGoalOz({
    BodyCompositionEntry? latestBodyComp,
    bool isTrainingDay = false,
  }) {
    if (customDailyWaterGoalOz != null && customDailyWaterGoalOz! > 0) {
      return customDailyWaterGoalOz! + (isTrainingDay ? 24.0 : 0.0);
    }
    return TdeeCalculatorService.calculateRecommendedWaterOz(
      latestBodyComp: latestBodyComp,
      isTrainingDay: isTrainingDay,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'goalType': goalType.name,
      'targetBodyFatPct': targetBodyFatPct,
      'targetWeightLb': targetWeightLb,
      'proteinGramsPerLbLbm': proteinGramsPerLbLbm,
      'dailyCalorieAdjustment': dailyCalorieAdjustment,
      'carbCyclingEnabled': carbCyclingEnabled,
      'trainingDayBonusCalories': trainingDayBonusCalories,
      'trainingDayCarbBonusGrams': trainingDayCarbBonusGrams,
      'baseTdeeEstimate': baseTdeeEstimate,
      'customDailyWaterGoalOz': customDailyWaterGoalOz,
    };
  }

  NutritionGoalModel copyWith({
    GoalType? goalType,
    double? targetBodyFatPct,
    double? targetWeightLb,
    double? proteinGramsPerLbLbm,
    int? dailyCalorieAdjustment,
    bool? carbCyclingEnabled,
    int? trainingDayBonusCalories,
    double? trainingDayCarbBonusGrams,
    int? baseTdeeEstimate,
    double? customDailyWaterGoalOz,
  }) {
    return NutritionGoalModel(
      goalType: goalType ?? this.goalType,
      targetBodyFatPct: targetBodyFatPct ?? this.targetBodyFatPct,
      targetWeightLb: targetWeightLb ?? this.targetWeightLb,
      proteinGramsPerLbLbm: proteinGramsPerLbLbm ?? this.proteinGramsPerLbLbm,
      dailyCalorieAdjustment:
          dailyCalorieAdjustment ?? this.dailyCalorieAdjustment,
      carbCyclingEnabled: carbCyclingEnabled ?? this.carbCyclingEnabled,
      trainingDayBonusCalories:
          trainingDayBonusCalories ?? this.trainingDayBonusCalories,
      trainingDayCarbBonusGrams:
          trainingDayCarbBonusGrams ?? this.trainingDayCarbBonusGrams,
      baseTdeeEstimate: baseTdeeEstimate ?? this.baseTdeeEstimate,
      customDailyWaterGoalOz:
          customDailyWaterGoalOz ?? this.customDailyWaterGoalOz,
    );
  }
}
