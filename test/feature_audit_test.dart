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
  });
}
