import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/models/nutrition_goal_model.dart';
import 'package:oly/services/tdee_calculator_service.dart';

void main() {
  group('TDEE & Macro Calculator Tests', () {
    test('Calculates Katch-McArdle BMR correctly from Lean Mass', () {
      final bmr = TdeeCalculatorService.calculateKatchMcArdleBmr(208.6);
      expect(bmr, equals(2414));
    });

    test('Generates athletic macro targets on cutting goal', () {
      final entry = BodyCompositionEntry.create(
        weightLb: 264.8,
        fatFreeMassLb: 208.6,
        bmrKcal: 2394,
      );

      const goal = NutritionGoalModel(
        goalType: GoalType.cutting,
        proteinGramsPerLbLbm: 1.05,
        dailyCalorieAdjustment: -450,
        carbCyclingEnabled: true,
      );

      final restDayTargets = TdeeCalculatorService.calculateMacroTargets(
        latestBodyComp: entry,
        goal: goal,
        isTrainingDay: false,
      );

      final trainingDayTargets = TdeeCalculatorService.calculateMacroTargets(
        latestBodyComp: entry,
        goal: goal,
        isTrainingDay: true,
      );

      // Protein = 208.6 * 1.05 = 219g
      expect(restDayTargets.proteinGrams, closeTo(219.0, 1.0));
      expect(restDayTargets.calories, greaterThan(2500));

      // Training day has higher carbs and calories
      expect(trainingDayTargets.calories, greaterThan(restDayTargets.calories),
          reason: 'Rest: ${restDayTargets.calories} (P:${restDayTargets.proteinGrams}, C:${restDayTargets.carbsGrams}, F:${restDayTargets.fatGrams}) vs Train: ${trainingDayTargets.calories} (P:${trainingDayTargets.proteinGrams}, C:${trainingDayTargets.carbsGrams}, F:${trainingDayTargets.fatGrams})');
      expect(trainingDayTargets.carbsGrams, greaterThan(restDayTargets.carbsGrams));
    });

    test('Calculates adaptive TDEE from logged intake and body composition delta', () {
      final startComp = BodyCompositionEntry.create(
        timestamp: DateTime(2026, 7, 1),
        weightLb: 265.0,
        bodyFatLb: 56.0,
        fatFreeMassLb: 209.0,
      );

      final endComp = BodyCompositionEntry.create(
        timestamp: DateTime(2026, 7, 15), // 14 days later
        weightLb: 263.0,
        bodyFatLb: 54.0, // -2.0 lb fat
        fatFreeMassLb: 209.0, // 0 lb muscle lost
      );

      final logs = List.generate(
        14,
        (i) => DailyNutritionLog.create(
          date: '2026-07-${(i + 1).toString().padLeft(2, '0')}',
          entries: [
            NutritionEntry.create(
              name: 'Daily Total',
              calories: 2700,
              proteinGrams: 220,
              carbsGrams: 280,
              fatGrams: 75,
            ),
          ],
        ),
      );

      final adaptiveTdee = TdeeCalculatorService.calculateAdaptiveTdee(
        recentLogs: logs,
        startComp: startComp,
        endComp: endComp,
      );

      // Lost 2 lbs fat in 14 days = 7000 kcal deficit / 14 = 500 kcal/day deficit.
      // Average intake was 2700 kcal. True TDEE = 2700 - (-500) = 3200 kcal.
      expect(adaptiveTdee, equals(3200));
    });

    test('Calculates recommended water intake based on Lean Mass and Training Status', () {
      final entry = BodyCompositionEntry.create(
        weightLb: 264.8,
        fatFreeMassLb: 208.6,
        bodyFatLb: 56.2,
        bodyWaterPct: 56.9,
      );

      // Rest Day: (208.6 * 0.65) + (56.2 * 0.25) = 135.59 + 14.05 = 150 oz
      final restDayWater = TdeeCalculatorService.calculateRecommendedWaterOz(
        latestBodyComp: entry,
        isTrainingDay: false,
      );
      expect(restDayWater, equals(150.0));

      // Training Day: 150 + 24 oz sports surcharge = 174 oz
      final trainingDayWater = TdeeCalculatorService.calculateRecommendedWaterOz(
        latestBodyComp: entry,
        isTrainingDay: true,
      );
      expect(trainingDayWater, equals(174.0));
    });

    test('Applies hydration boost when Renpho Body Water is low (<55%)', () {
      final dehydratedEntry = BodyCompositionEntry.create(
        weightLb: 264.8,
        fatFreeMassLb: 208.6,
        bodyFatLb: 56.2,
        bodyWaterPct: 52.0, // Sub-optimal (<55%)
      );

      final boostedWater = TdeeCalculatorService.calculateRecommendedWaterOz(
        latestBodyComp: dehydratedEntry,
        isTrainingDay: false,
      );
      // 150 + 12 oz low-hydration boost = 162 oz
      expect(boostedWater, equals(162.0));
    });
  });
}
