import '../models/body_composition_entry.dart';
import '../models/daily_nutrition_log.dart';
import '../models/nutrition_goal_model.dart';

class MacroTargets {
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const MacroTargets({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });
}

class TdeeCalculatorService {
  /// Baseline Katch-McArdle BMR calculation using Lean Body Mass:
  /// BMR = 370 + (21.6 * LBM in kg)
  static int calculateKatchMcArdleBmr(double leanBodyMassLb) {
    if (leanBodyMassLb <= 0) return 2000;
    final lbmKg = leanBodyMassLb / 2.20462;
    return (370 + (21.6 * lbmKg)).round();
  }

  /// Calculates baseline TDEE given BMR and an activity multiplier.
  /// Activity multiplier for Olympic lifting athletes:
  /// - 3-4 days/week training: ~1.50 - 1.55
  /// - 5 days/week training: ~1.65
  static int calculateBaselineTdee(int bmr, {double activityMultiplier = 1.55}) {
    return (bmr * activityMultiplier).round();
  }

  /// Calculates scientifically recommended daily water intake in fluid ounces (oz).
  ///
  /// Mathematical Formulation:
  /// 1. Body Composition & Lean Body Mass Model (ACSM / ISSN):
  ///    - Muscle/Lean tissue is ~75% water and metabolically active: 0.65 oz / lb LBM
  ///    - Fat/Adipose tissue is ~10% water: 0.25 oz / lb Fat Mass
  ///    - Baseline = (LBM_lb * 0.65) + (FatMass_lb * 0.25)
  /// 2. General Bodyweight Fallback:
  ///    - 0.55 oz / lb total bodyweight
  /// 3. Olympic Lifting & CNS Training Day Exertion Surcharge:
  ///    - Heavy lifting sessions require intra/post-workout rehydration and glycogen hydration:
  ///      +24.0 oz (~700 mL / standard shaker bottle)
  /// 4. Low Hydration Compensation:
  ///    - If Renpho scale reports Body Water % < 55%, add +12.0 oz recovery hydration.
  static double calculateRecommendedWaterOz({
    required BodyCompositionEntry? latestBodyComp,
    required bool isTrainingDay,
    double fallbackWeightLb = 200.0,
  }) {
    double baseWaterOz;
    if (latestBodyComp != null && latestBodyComp.weightLb > 0) {
      final lbm = latestBodyComp.leanBodyMassLb;
      final fat = latestBodyComp.fatMassLb;
      baseWaterOz = (lbm * 0.65) + (fat * 0.25);

      // Low hydration compensation from Renpho scale readings (<55% in athletic adults)
      if (latestBodyComp.bodyWaterPct != null && latestBodyComp.bodyWaterPct! < 55.0) {
        baseWaterOz += 12.0;
      }
    } else {
      baseWaterOz = fallbackWeightLb * 0.55;
    }

    if (isTrainingDay) {
      baseWaterOz += 24.0; // Sports hydration bonus for training session
    }

    return (baseWaterOz.roundToDouble()).clamp(64.0, 250.0);
  }

  /// Calculates dynamic expenditure from nutrition intake history and body composition changes
  static int calculateAdaptiveTdee({
    required List<DailyNutritionLog> recentLogs,
    required BodyCompositionEntry startComp,
    required BodyCompositionEntry endComp,
  }) {
    if (recentLogs.isEmpty) {
      return endComp.bmrKcal != null
          ? calculateBaselineTdee(endComp.bmrKcal!)
          : calculateBaselineTdee(calculateKatchMcArdleBmr(endComp.leanBodyMassLb));
    }

    final totalLoggedCalories = recentLogs.fold(0, (sum, log) => sum + log.totalCalories);
    final daysCount = recentLogs.length.clamp(1, 365);
    final avgDailyIntake = totalLoggedCalories / daysCount;

    final daysBetweenScans = endComp.timestamp.difference(startComp.timestamp).inDays;
    if (daysBetweenScans < 5) {
      // Too short to reliably deduce expenditure; fallback to baseline
      return calculateBaselineTdee(endComp.bmrKcal ?? calculateKatchMcArdleBmr(endComp.leanBodyMassLb));
    }

    final fatDeltaLb = endComp.fatMassLb - startComp.fatMassLb;
    final leanDeltaLb = endComp.leanBodyMassLb - startComp.leanBodyMassLb;

    // Fat tissue ~3500 kcal/lb, Muscle tissue ~800 kcal/lb
    final totalTissueEnergyDelta = (fatDeltaLb * 3500.0) + (leanDeltaLb * 800.0);
    final dailyTissueEnergyRate = totalTissueEnergyDelta / daysBetweenScans;

    final adaptiveTdee = (avgDailyIntake - dailyTissueEnergyRate).round();
    return adaptiveTdee.clamp(1500, 5000);
  }

  /// Generates tailored daily macronutrient and calorie targets
  static MacroTargets calculateMacroTargets({
    required BodyCompositionEntry? latestBodyComp,
    required NutritionGoalModel goal,
    required bool isTrainingDay,
  }) {
    final double lbmLb = latestBodyComp?.leanBodyMassLb ?? 180.0;
    final int bmr = latestBodyComp?.bmrKcal ?? calculateKatchMcArdleBmr(lbmLb);
    final int baseTdee = calculateBaselineTdee(bmr);

    int targetCalories = baseTdee;

    // Apply goal adjustments
    switch (goal.goalType) {
      case GoalType.cutting:
        targetCalories -= (goal.dailyCalorieAdjustment != 0 ? goal.dailyCalorieAdjustment.abs() : 450);
        break;
      case GoalType.leanBulking:
        targetCalories += (goal.dailyCalorieAdjustment != 0 ? goal.dailyCalorieAdjustment.abs() : 250);
        break;
      case GoalType.recomposition:
        targetCalories += goal.dailyCalorieAdjustment; // usually close to 0
        break;
      case GoalType.maintenance:
        targetCalories += goal.dailyCalorieAdjustment;
        break;
    }

    // Apply training day carb cycling bonus
    if (goal.carbCyclingEnabled && isTrainingDay) {
      targetCalories += goal.trainingDayBonusCalories;
    }

    // Protein: 1.0 - 1.2 g per lb of Fat-Free Mass
    final double targetProteinGrams = (lbmLb * goal.proteinGramsPerLbLbm).roundToDouble();
    final double proteinCalories = targetProteinGrams * 4.0;

    // Fat: ~22% (training day) or ~28% (rest day) of total calories
    final double fatPercentage = isTrainingDay ? 0.22 : 0.28;
    final double fatCalories = targetCalories * fatPercentage;
    final double targetFatGrams = (fatCalories / 9.0).roundToDouble();

    // Carbs: Remaining calories / 4
    final double remainingCalories = targetCalories - proteinCalories - (targetFatGrams * 9.0);
    final double targetCarbsGrams = (remainingCalories / 4.0).clamp(50.0, 800.0).roundToDouble();

    // Recalibrate final calorie sum
    final finalCalories = (targetProteinGrams * 4 + targetCarbsGrams * 4 + targetFatGrams * 9).round();

    return MacroTargets(
      calories: finalCalories,
      proteinGrams: targetProteinGrams,
      carbsGrams: targetCarbsGrams,
      fatGrams: targetFatGrams,
    );
  }
}
