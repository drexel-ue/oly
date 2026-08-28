import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Feature Enhancements Tests', () {
    test(
      'WorkoutSession serializes sessionRpe and jointStrainTags correctly',
      () {
        final WorkoutSession session = WorkoutSession(
          id: 's_1',
          date: DateTime.now(),
          dayNumber: 1,
          weekNumber: 1,
          cycleNumber: 1,
          sessionRpe: 8,
          jointStrainTags: <String>['Shoulders', 'Hips'],
          logs: <ExerciseLog>[
            ExerciseLog(
              exerciseName: 'Snatch',
              liftId: 'snatch',
              sets: <CompletedSet>[
                CompletedSet(setIndex: 1, weight: 80.0, reps: 3),
              ],
            ),
          ],
        );

        final Map<String, dynamic> json = session.toJson();
        final WorkoutSession restored = WorkoutSession.fromJson(json);

        expect(restored.sessionRpe, equals(8));
        expect(restored.jointStrainTags, contains('Shoulders'));
        expect(restored.jointStrainTags, contains('Hips'));
      },
    );

    test('RecoveryEngineService adapts focus areas based on jointStrainTags from last session', () {
      final WorkoutSession lastSession = WorkoutSession(
        id: 's_1',
        date: DateTime.now(),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        sessionRpe: 9,
        jointStrainTags: <String>['Shoulders'],
        logs: <ExerciseLog>[
          ExerciseLog(
            exerciseName: 'Snatch',
            liftId: 'snatch',
            sets: <CompletedSet>[],
          ),
        ],
      );

      final GeneratedRecoveryRoutine routine =
          RecoveryEngineService.generateRoutine(
            ratioAnalyses: <LiftRatioAnalysis>[],
            lastSession: lastSession,
          );

      expect(
        routine.diagnosticReasons.any(
          (String r) => r.contains('Shoulder strain reported'),
        ),
        isTrue,
      );
    });

    test(
      'StorageService exports JSON and CSV correctly and imports backup',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final StorageService storage = await StorageService.init();
        final SettingsProvider settings = SettingsProvider(storage);

        // Export CSV test
        final String csv = settings.exportPrsCsv();
        expect(csv.contains('Lift Name,Category,1RM (KG)'), isTrue);
        expect(csv.contains('Snatch'), isTrue);

        // Export JSON test
        final String jsonBackup = settings.exportFullDataJson();
        expect(jsonBackup.contains('"lifts"'), isTrue);
        expect(jsonBackup.contains('"settings"'), isTrue);

        // Import JSON test
        final bool importResult = await settings.importDataJson(jsonBackup);
        expect(importResult, isTrue);
      },
    );

    test('ActiveWorkoutDraft serializes and calculates progress correctly', () {
      final ActiveWorkoutDraft draft = ActiveWorkoutDraft(
        dayNumber: 1,
        weekNumber: 3,
        cycleNumber: 1,
        dayTitle: 'Day 1: Snatch & Clean Strength',
        startTime: DateTime.now().subtract(const Duration(minutes: 25)),
        exerciseSets: <String, List<CompletedSet>>{
          'Snatch': <CompletedSet>[
            CompletedSet(setIndex: 1, weight: 80.0, reps: 3, isCompleted: true),
            CompletedSet(setIndex: 2, weight: 80.0, reps: 3, isCompleted: true),
            CompletedSet(
              setIndex: 3,
              weight: 80.0,
              reps: 3,
              isCompleted: false,
            ),
            CompletedSet(
              setIndex: 4,
              weight: 80.0,
              reps: 3,
              isCompleted: false,
            ),
          ],
          'Back Squat': <CompletedSet>[
            CompletedSet(
              setIndex: 1,
              weight: 130.0,
              reps: 5,
              isCompleted: false,
            ),
            CompletedSet(
              setIndex: 2,
              weight: 130.0,
              reps: 5,
              isCompleted: false,
            ),
          ],
        },
        exerciseWeights: <String, double>{'Snatch': 80.0, 'Back Squat': 130.0},
        swappedExerciseNames: <String, String>{'Military Press': 'Push Press'},
        notes: 'Felt snappy on snatches',
        selectedRpe: 8,
        selectedJointStrains: <String>['Wrists'],
      );

      expect(draft.totalSetsCount, equals(6));
      expect(draft.totalCompletedSets, equals(2));
      expect(draft.completionPercentage, closeTo(2 / 6, 0.001));

      final Map<String, dynamic> json = draft.toJson();
      final ActiveWorkoutDraft restored = ActiveWorkoutDraft.fromJson(json);

      expect(restored.dayNumber, equals(1));
      expect(restored.weekNumber, equals(3));
      expect(restored.dayTitle, equals('Day 1: Snatch & Clean Strength'));
      expect(restored.totalCompletedSets, equals(2));
      expect(restored.exerciseSets['Snatch']?[0].isCompleted, isTrue);
      expect(restored.exerciseWeights['Snatch'], equals(80.0));
      expect(
        restored.swappedExerciseNames['Military Press'],
        equals('Push Press'),
      );
      expect(restored.notes, equals('Felt snappy on snatches'));
      expect(restored.selectedJointStrains, contains('Wrists'));
    });

    test('StorageService persists and clears active workout draft', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.init();

      expect(storage.loadActiveWorkoutDraft(), isNull);

      final ActiveWorkoutDraft draft = ActiveWorkoutDraft(
        dayNumber: 2,
        weekNumber: 1,
        cycleNumber: 1,
        dayTitle: 'Day 2: Technique Prep',
        startTime: DateTime.now(),
        exerciseSets: <String, List<CompletedSet>>{},
        exerciseWeights: <String, double>{},
      );

      await storage.saveActiveWorkoutDraft(draft);
      final ActiveWorkoutDraft? loaded = storage.loadActiveWorkoutDraft();
      expect(loaded, isNotNull);
      expect(loaded?.dayTitle, equals('Day 2: Technique Prep'));

      await storage.clearActiveWorkoutDraft();
      expect(storage.loadActiveWorkoutDraft(), isNull);
    });
  });
}
