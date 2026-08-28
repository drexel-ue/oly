import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/services/activity_expenditure_service.dart';

void main() {
  group('Activity Expenditure & Metabolic Science Tests', () {
    test('Calculates Algorithm A (Standard Clinical Formula) correctly', () {
      // 45 min brisk walk (3.8 MET) for a 120.1 kg (264.8 lb) individual
      // Calories = 45 * (3.8 * 3.5 * 120.1 / 200) = 359.6 -> 360 kcal
      final cal = ActivityExpenditureService.calculateStandardCalories(
        met: 3.8,
        weightKg: 120.1,
        durationMinutes: 45.0,
      );

      expect(cal, equals(359));
    });

    test('Calculates Algorithm B (Katch-McArdle LBM Scaled Formula) correctly', () {
      // 45 min brisk walk (3.8 MET) for an athlete with 208.6 lb LBM (94.62 kg)
      // BMR = 370 + 21.6 * 94.62 = 2413.8 -> REE/min = 2413.8 / 1440 = 1.676 kcal/min
      // Calories = 3.8 * 1.676 * 45 = 286.7 -> 287 kcal
      final cal = ActivityExpenditureService.calculateAdjustedCalories(
        met: 3.8,
        leanBodyMassLb: 208.6,
        durationMinutes: 45.0,
      );

      expect(cal, equals(287));
    });

    test('Demonstrates that Algorithm B prevents 25% overestimation of caloric burn', () {
      final calA = ActivityExpenditureService.calculateStandardCalories(
        met: 3.8,
        weightKg: 120.1,
        durationMinutes: 45.0,
      );
      final calB = ActivityExpenditureService.calculateAdjustedCalories(
        met: 3.8,
        leanBodyMassLb: 208.6,
        durationMinutes: 45.0,
      );

      expect(calA, greaterThan(calB));
      final pctDifference = ((calA - calB) / calB) * 100.0;
      expect(pctDifference, closeTo(25.4, 1.0));
    });

    test('Calculates ACSM Steps and Distance accurately', () {
      final (cal, miles) = ActivityExpenditureService.calculateStepsExpenditure(
        steps: 8600,
        weightLb: 264.8,
        leanBodyMassLb: 208.6,
      );

      expect(miles, equals(4.0));
      expect(cal, greaterThan(400));
      expect(cal, lessThan(500));
    });

    test('Maps lift categories to distinct Compendium MET intensities', () {
      expect(ActivityExpenditureService.getMetForLift('snatch', 'Power Snatch'), equals(6.5));
      expect(ActivityExpenditureService.getMetForLift('clean_jerk', 'Clean & Jerk'), equals(6.5));
      expect(ActivityExpenditureService.getMetForLift('back_squat', 'Pause Back Squat'), equals(6.0));
      expect(ActivityExpenditureService.getMetForLift('clean_pull', 'Clean Pull'), equals(6.0));
      expect(ActivityExpenditureService.getMetForLift('push_press', 'Push Press'), equals(5.0));
      expect(ActivityExpenditureService.getMetForLift('accessories', 'Bulgarian Split Squat'), equals(4.5));
    });

    test('Calculates Workout of the Day (WOD) energy expenditure from session logs', () {
      final bodyComp = BodyCompositionEntry.create(
        weightLb: 264.8,
        bodyFatPct: 21.2,
        fatFreeMassLb: 208.6,
        bmrKcal: 2394,
      );

      final session = WorkoutSession(
        id: 'session_test_1',
        date: DateTime(2026, 8, 27),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        durationSeconds: 2700, // 45 min
        logs: [
          ExerciseLog(
            exerciseName: 'Snatch',
            liftId: 'snatch',
            sets: [
              CompletedSet(setIndex: 0, weight: 80.0, reps: 2),
              CompletedSet(setIndex: 1, weight: 85.0, reps: 2),
              CompletedSet(setIndex: 2, weight: 90.0, reps: 2),
            ],
          ),
          ExerciseLog(
            exerciseName: 'Back Squat',
            liftId: 'back_squat',
            sets: [
              CompletedSet(setIndex: 0, weight: 140.0, reps: 5),
              CompletedSet(setIndex: 1, weight: 150.0, reps: 5),
              CompletedSet(setIndex: 2, weight: 160.0, reps: 5),
            ],
          ),
        ],
      );

      final (totalCal, totalDur, totalTonnage, breakdown) = ActivityExpenditureService.calculateSessionExpenditure(
        session: session,
        bodyComp: bodyComp,
      );

      expect(totalCal, greaterThan(150));
      expect(totalTonnage, greaterThan(2000.0)); // >2,000 kg tonnage
      expect(breakdown.containsKey('Snatch'), isTrue);
      expect(breakdown.containsKey('Back Squat'), isTrue);

      final wodEntry = ActivityExpenditureService.createWodActivityEntry(
        session: session,
        bodyComp: bodyComp,
      );

      expect(wodEntry.activityType, equals('workout_wod'));
      expect(wodEntry.sessionId, equals('session_test_1'));
      expect(wodEntry.caloriesBurned, equals(totalCal));
    });
  });
}
