import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';

void main() {
  group('Feature Enhancements Tests', () {
    test('WorkoutSession serializes sessionRpe and jointStrainTags correctly', () {
      final session = WorkoutSession(
        id: 's_1',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        sessionRpe: 8,
        jointStrainTags: ['Shoulders', 'Hips'],
        logs: [
          ExerciseLog(
            exerciseName: 'Snatch',
            liftId: 'snatch',
            sets: [
              CompletedSet(setIndex: 1, weight: 80.0, reps: 3),
            ],
          ),
        ],
      );

      final json = session.toJson();
      final restored = WorkoutSession.fromJson(json);

      expect(restored.sessionRpe, equals(8));
      expect(restored.jointStrainTags, contains('Shoulders'));
      expect(restored.jointStrainTags, contains('Hips'));
    });

    test('RecoveryEngineService adapts focus areas based on jointStrainTags from last session', () {
      final lastSession = WorkoutSession(
        id: 's_1',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        sessionRpe: 9,
        jointStrainTags: ['Shoulders'],
        logs: [
          ExerciseLog(exerciseName: 'Snatch', liftId: 'snatch', sets: []),
        ],
      );

      final routine = RecoveryEngineService.generateRoutine(
        ratioAnalyses: [],
        lastSession: lastSession,
      );

      expect(routine.diagnosticReasons.any((r) => r.contains('Shoulder strain reported')), isTrue);
    });

    test('StorageService exports JSON and CSV correctly and imports backup', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final settings = SettingsProvider(storage);

      // Export CSV test
      final csv = settings.exportPrsCsv();
      expect(csv.contains('Lift Name,Category,1RM (KG)'), isTrue);
      expect(csv.contains('Snatch'), isTrue);

      // Export JSON test
      final jsonBackup = settings.exportFullDataJson();
      expect(jsonBackup.contains('"lifts"'), isTrue);
      expect(jsonBackup.contains('"settings"'), isTrue);

      // Import JSON test
      final importResult = await settings.importDataJson(jsonBackup);
      expect(importResult, isTrue);
    });

    test('ActiveWorkoutDraft serializes and calculates progress correctly', () {
      final draft = ActiveWorkoutDraft(
        dayNumber: 1,
        weekNumber: 3,
        cycleNumber: 1,
        dayTitle: 'Day 1: Snatch & Clean Strength',
        startTime: DateTime.now().subtract(const Duration(minutes: 25)),
        exerciseSets: {
          'Snatch': [
            CompletedSet(setIndex: 1, weight: 80.0, reps: 3, isCompleted: true),
            CompletedSet(setIndex: 2, weight: 80.0, reps: 3, isCompleted: true),
            CompletedSet(setIndex: 3, weight: 80.0, reps: 3, isCompleted: false),
            CompletedSet(setIndex: 4, weight: 80.0, reps: 3, isCompleted: false),
          ],
          'Back Squat': [
            CompletedSet(setIndex: 1, weight: 130.0, reps: 5, isCompleted: false),
            CompletedSet(setIndex: 2, weight: 130.0, reps: 5, isCompleted: false),
          ],
        },
        exerciseWeights: {'Snatch': 80.0, 'Back Squat': 130.0},
        swappedExerciseNames: {'Military Press': 'Push Press'},
        notes: 'Felt snappy on snatches',
        selectedRpe: 8,
        selectedJointStrains: ['Wrists'],
      );

      expect(draft.totalSetsCount, equals(6));
      expect(draft.totalCompletedSets, equals(2));
      expect(draft.completionPercentage, closeTo(2 / 6, 0.001));

      final json = draft.toJson();
      final restored = ActiveWorkoutDraft.fromJson(json);

      expect(restored.dayNumber, equals(1));
      expect(restored.weekNumber, equals(3));
      expect(restored.dayTitle, equals('Day 1: Snatch & Clean Strength'));
      expect(restored.totalCompletedSets, equals(2));
      expect(restored.exerciseSets['Snatch']?[0].isCompleted, isTrue);
      expect(restored.exerciseWeights['Snatch'], equals(80.0));
      expect(restored.swappedExerciseNames['Military Press'], equals('Push Press'));
      expect(restored.notes, equals('Felt snappy on snatches'));
      expect(restored.selectedJointStrains, contains('Wrists'));
    });

    test('StorageService persists and clears active workout draft', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      expect(storage.loadActiveWorkoutDraft(), isNull);

      final draft = ActiveWorkoutDraft(
        dayNumber: 2,
        weekNumber: 1,
        cycleNumber: 1,
        dayTitle: 'Day 2: Technique Prep',
        startTime: DateTime.now(),
        exerciseSets: {},
        exerciseWeights: {},
      );

      await storage.saveActiveWorkoutDraft(draft);
      final loaded = storage.loadActiveWorkoutDraft();
      expect(loaded, isNotNull);
      expect(loaded?.dayTitle, equals('Day 2: Technique Prep'));

      await storage.clearActiveWorkoutDraft();
      expect(storage.loadActiveWorkoutDraft(), isNull);
    });
  });
}
