import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/c25k_model.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('C25kCurriculum Curriculum Integrity Tests', () {
    test('Curriculum contains 9 weeks with 3 workouts each (27 total)', () {
      final List<C25kWorkout> workouts = C25kCurriculum.getAllWorkouts();
      expect(workouts.length, equals(27));

      for (int week = 1; week <= 9; week++) {
        for (int day = 1; day <= 3; day++) {
          final C25kWorkout workout = C25kCurriculum.getWorkout(week, day);
          expect(workout.week, equals(week));
          expect(workout.day, equals(day));
          expect(workout.steps, isNotEmpty);
          expect(workout.totalDurationSeconds, greaterThan(0));
          expect(workout.estimateDistanceKm(), greaterThan(0.0));
        }
      }
    });

    test('Week 1 Day 1 structure matches classic C25K protocol', () {
      final C25kWorkout w1d1 = C25kCurriculum.getWorkout(1, 1);
      // Warmup walk (300s) + 8 cycles of (60s jog + 90s walk = 150s * 8 = 1200s) + cooldown walk (300s) = 1800s (30 mins)
      expect(w1d1.totalDurationSeconds, equals(1800));
      expect(w1d1.steps.first.type, equals(C25kStepType.warmupWalk));
      expect(w1d1.steps.last.type, equals(C25kStepType.cooldownWalk));
      expect(w1d1.totalJogSeconds, equals(480)); // 8 * 60s
      expect(w1d1.totalWalkSeconds, equals(1320)); // 300 + 8 * 90 + 300
    });
  });

  group('C25kProvider State & Interval Engine Tests', () {
    late StorageService storage;
    late C25kProvider c25kProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      c25kProvider = C25kProvider(storage);
    });

    test('Initializes with Week 1 Day 1 and empty session logs', () {
      expect(c25kProvider.currentWeek, equals(1));
      expect(c25kProvider.currentDay, equals(1));
      expect(c25kProvider.sessionLogs, isEmpty);
      expect(c25kProvider.isRunActive, isFalse);
      expect(c25kProvider.isPaused, isFalse);
    });

    test('Sets and advances curriculum progress', () async {
      await c25kProvider.setProgress(2, 2);
      expect(c25kProvider.currentWeek, equals(2));
      expect(c25kProvider.currentDay, equals(2));

      await c25kProvider.advanceProgress();
      expect(c25kProvider.currentWeek, equals(2));
      expect(c25kProvider.currentDay, equals(3));

      // Advancing past day 3 moves to next week day 1
      await c25kProvider.advanceProgress();
      expect(c25kProvider.currentWeek, equals(3));
      expect(c25kProvider.currentDay, equals(1));

      // Check persistence with fresh instance
      final C25kProvider reloaded = C25kProvider(storage);
      expect(reloaded.currentWeek, equals(3));
      expect(reloaded.currentDay, equals(1));
    });

    test('Starts run session and handles pause/resume and skip step', () {
      c25kProvider.startRunSession(week: 1, day: 1);

      expect(c25kProvider.isRunActive, isTrue);
      expect(c25kProvider.isPaused, isFalse);
      expect(c25kProvider.currentStepIndex, equals(0));
      expect(c25kProvider.currentStep?.type, equals(C25kStepType.warmupWalk));

      c25kProvider.pauseRunSession();
      expect(c25kProvider.isPaused, isTrue);

      c25kProvider.resumeRunSession();
      expect(c25kProvider.isPaused, isFalse);

      // Skip warmup walk (step 0) -> step 1 should be first jog
      c25kProvider.skipToNextStep();
      expect(c25kProvider.currentStepIndex, equals(1));
      expect(c25kProvider.currentStep?.type, equals(C25kStepType.jog));
    });

    test('Finishing run session computes Algorithm B net calories and saves log', () async {
      c25kProvider.startRunSession(week: 1, day: 1);

      // Finish session with custom weight
      final C25kSessionLog log = await c25kProvider.finishRunSession(
        bodyWeightKg: 80,
      );

      expect(c25kProvider.isRunActive, isFalse);
      expect(c25kProvider.sessionLogs.length, equals(1));
      expect(log.week, equals(1));
      expect(log.day, equals(1));
      expect(log.isCompleted, isTrue);

      // Check that progress advanced to Day 2
      expect(c25kProvider.currentWeek, equals(1));
      expect(c25kProvider.currentDay, equals(2));
      expect(c25kProvider.totalCompletedSessions, equals(1));
    });

    test('Can cancel an active run session', () {
      c25kProvider.startRunSession(week: 1, day: 1);
      expect(c25kProvider.isRunActive, isTrue);

      c25kProvider.cancelRunSession();
      expect(c25kProvider.isRunActive, isFalse);
      expect(c25kProvider.activeWorkout, isNull);
    });
  });
}
