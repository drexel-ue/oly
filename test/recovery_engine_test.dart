import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/recovery_session_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';

void main() {
  group('RecoveryEngineService Tests', () {
    test('Generates thoracic & shoulder drills when overhead ratio is Underdeveloped', () {
      final snatch = LiftModel(
        id: 'snatch',
        name: 'Snatch',
        category: LiftCategory.snatch,
        currentMax: 100.0,
      );
      final overheadPress = LiftModel(
        id: 'military_press',
        name: 'Military Press',
        category: LiftCategory.overhead,
        anchorLiftId: 'snatch',
        targetRatio: 0.55,
        currentMax: 40.0, // 40% vs 55% target -> Underdeveloped
      );

      final analysis = [
        LiftRatioAnalysis(
          lift: overheadPress,
          anchorLift: snatch,
          actualRatio: 0.40,
          targetRatio: 0.55,
          ratioPercentage: (0.40 / 0.55) * 100,
          status: 'Underdeveloped',
        ),
      ];

      final routine = RecoveryEngineService.generateRoutine(
        ratioAnalyses: analysis,
        lastSession: null,
      );

      expect(routine.exercises.length, equals(5));
      expect(routine.diagnosticReasons.any((r) => r.contains('Military Press')), isTrue);
      expect(
        routine.exercises.any((e) =>
            e.focusArea == MobilityFocusArea.thoracicSpine ||
            e.focusArea == MobilityFocusArea.shoulderOverhead),
        isTrue,
      );
    });

    test('Generates hip & ankle drills when heavy squats were logged in last session', () {
      final lastSession = WorkoutSession(
        id: 'session_1',
        date: DateTime.now(),
        cycleNumber: 1,
        weekNumber: 1,
        dayNumber: 1,
        logs: [
          ExerciseLog(
            liftId: 'back_squat',
            exerciseName: 'Back Squat',
            sets: [
              CompletedSet(setIndex: 1, reps: 5, weight: 100.0),
              CompletedSet(setIndex: 2, reps: 5, weight: 100.0),
            ],
          ),
        ],
      );

      final routine = RecoveryEngineService.generateRoutine(
        ratioAnalyses: [],
        lastSession: lastSession,
      );

      expect(routine.exercises.length, equals(5));
      expect(routine.diagnosticReasons.any((r) => r.contains('Squat volume')), isTrue);
      expect(
        routine.exercises.any((e) =>
            e.focusArea == MobilityFocusArea.hipCapsule ||
            e.focusArea == MobilityFocusArea.ankleDorsiflexion),
        isTrue,
      );
    });

    test('MobilityExerciseModel and RecoverySessionLog json serialization', () {
      final ex = MobilityExerciseModel(
        id: 'test_ex',
        name: 'Test Drill',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.mobilityDrill,
        description: 'Test description',
        cues: ['Cue 1', 'Cue 2'],
        videoUrl: 'https://youtube.com/watch?v=123',
      );

      final json = ex.toJson();
      final restored = MobilityExerciseModel.fromJson(json);

      expect(restored.id, equals('test_ex'));
      expect(restored.focusArea, equals(MobilityFocusArea.thoracicSpine));
      expect(restored.cues.length, equals(2));

      final log = RecoverySessionLog(
        id: 'log_1',
        date: DateTime.now(),
        durationMinutes: 12,
        completedExerciseIds: ['test_ex'],
        readinessRating: 5,
        diagnosticReasons: ['Tested rationale'],
      );

      final logJson = log.toJson();
      final restoredLog = RecoverySessionLog.fromJson(logJson);

      expect(restoredLog.id, equals('log_1'));
      expect(restoredLog.readinessRating, equals(5));
      expect(restoredLog.completedExerciseIds, contains('test_ex'));
    });

    test('SettingsProvider formatTextUnits converts metric references in prose when in LBS mode', () async {
      SharedPreferences.setMockInitialValues({'oly_unit_v1': true}); // LBS mode enabled
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final settings = SettingsProvider(storage);

      expect(settings.isLbs, isTrue);

      const cue1 = 'Use 1.25kg - 2.5kg micro plates or light dumbbells.';
      const cue2 = 'Stand on box with light kettlebell or empty bar (8-16kg).';

      final converted1 = settings.formatTextUnits(cue1);
      final converted2 = settings.formatTextUnits(cue2);

      expect(converted1, equals('Use 3 lbs - 5.5 lbs micro plates or light dumbbells.'));
      expect(converted2, equals('Stand on box with light kettlebell or empty bar (17.5-35.5 lbs).'));
    });
  });
}
