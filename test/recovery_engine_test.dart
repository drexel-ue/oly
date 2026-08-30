import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/recovery_session_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RecoveryEngineService Tests', () {
    test('Generates thoracic & shoulder drills when overhead ratio is Underdeveloped', () {
      final LiftModel snatch = LiftModel(
        id: 'snatch',
        name: 'Snatch',
        category: LiftCategory.snatch,
        currentMax: 100.0,
      );
      final LiftModel overheadPress = LiftModel(
        id: 'military_press',
        name: 'Military Press',
        category: LiftCategory.overhead,
        anchorLiftId: 'snatch',
        targetRatio: 0.55,
        currentMax: 40.0, // 40% vs 55% target -> Underdeveloped
      );

      final List<LiftRatioAnalysis> analysis = <LiftRatioAnalysis>[
        LiftRatioAnalysis(
          lift: overheadPress,
          anchorLift: snatch,
          actualRatio: 0.40,
          targetRatio: 0.55,
          ratioPercentage: (0.40 / 0.55) * 100,
          status: 'Underdeveloped',
        ),
      ];

      final GeneratedRecoveryRoutine routine =
          RecoveryEngineService.generateRoutine(
            ratioAnalyses: analysis,
            lastSession: null,
          );

      expect(routine.phaseGroups.length, equals(4));
      expect(routine.exercises.length, equals(10));
      expect(
        routine.diagnosticReasons.any(
          (String r) => r.contains('Military Press'),
        ),
        isTrue,
      );
      expect(
        routine.exercises.any(
          (MobilityExerciseModel e) =>
              e.focusArea == MobilityFocusArea.thoracicSpine ||
              e.focusArea == MobilityFocusArea.shoulderOverhead,
        ),
        isTrue,
      );
      expect(
        routine.exercises.any(
          (MobilityExerciseModel e) => e.id == 'kettlebell_mile',
        ),
        isTrue,
      );
    });

    test('Generates hip & ankle drills when heavy squats were logged in last session', () {
      final WorkoutSession lastSession = WorkoutSession(
        id: 'session_1',
        date: DateTime.now(),
        cycleNumber: 1,
        weekNumber: 1,
        dayNumber: 1,
        logs: <ExerciseLog>[
          ExerciseLog(
            liftId: 'back_squat',
            exerciseName: 'Back Squat',
            sets: <CompletedSet>[
              CompletedSet(setIndex: 1, reps: 5, weight: 100.0),
              CompletedSet(setIndex: 2, reps: 5, weight: 100.0),
            ],
          ),
        ],
      );

      final GeneratedRecoveryRoutine routine =
          RecoveryEngineService.generateRoutine(
            ratioAnalyses: <LiftRatioAnalysis>[],
            lastSession: lastSession,
          );

      expect(routine.phaseGroups.length, equals(4));
      expect(routine.exercises.length, equals(10));
      expect(
        routine.diagnosticReasons.any((String r) => r.contains('Squat volume')),
        isTrue,
      );
      expect(
        routine.exercises.any(
          (MobilityExerciseModel e) =>
              e.focusArea == MobilityFocusArea.hipCapsule ||
              e.focusArea == MobilityFocusArea.ankleDorsiflexion,
        ),
        isTrue,
      );
      expect(
        routine.exercises.any(
          (MobilityExerciseModel e) => e.id == 'kettlebell_mile',
        ),
        isTrue,
      );
    });

    test('MobilityExerciseModel and RecoverySessionLog json serialization', () {
      final MobilityExerciseModel ex = MobilityExerciseModel(
        id: 'test_ex',
        name: 'Test Drill',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.mobilityDrill,
        description: 'Test description',
        cues: <String>['Cue 1', 'Cue 2'],
        videoUrl: 'https://youtube.com/watch?v=123',
      );

      final Map<String, dynamic> json = ex.toJson();
      final MobilityExerciseModel restored = MobilityExerciseModel.fromJson(
        json,
      );

      expect(restored.id, equals('test_ex'));
      expect(restored.focusArea, equals(MobilityFocusArea.thoracicSpine));
      expect(restored.cues.length, equals(2));

      final RecoverySessionLog log = RecoverySessionLog(
        id: 'log_1',
        date: DateTime.now(),
        durationMinutes: 12,
        completedExerciseIds: <String>['test_ex'],
        readinessRating: 5,
        diagnosticReasons: <String>['Tested rationale'],
      );

      final Map<String, dynamic> logJson = log.toJson();
      final RecoverySessionLog restoredLog = RecoverySessionLog.fromJson(
        logJson,
      );

      expect(restoredLog.id, equals('log_1'));
      expect(restoredLog.readinessRating, equals(5));
      expect(restoredLog.completedExerciseIds, contains('test_ex'));
    });

    test('SettingsProvider formatTextUnits converts metric references in prose when in LBS mode', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'oly_unit_v1': true,
      }); // LBS mode enabled
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final SettingsProvider settings = SettingsProvider(storage);

      expect(settings.isLbs, isTrue);

      const String cue1 = 'Use 1.25kg - 2.5kg micro plates or light dumbbells.';
      const String cue2 =
          'Stand on box with light kettlebell or empty bar (8-16kg).';

      final String converted1 = settings.formatTextUnits(cue1);
      final String converted2 = settings.formatTextUnits(cue2);

      expect(
        converted1,
        equals('Use 3 lbs - 5.5 lbs micro plates or light dumbbells.'),
      );
      expect(
        converted2,
        equals(
          'Stand on box with light kettlebell or empty bar (17.5-35.5 lbs).',
        ),
      );
    });
  });
}
