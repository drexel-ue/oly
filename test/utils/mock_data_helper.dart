import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/pr_entry.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/services/storage_service.dart';

class MockDataHelper {
  static List<LiftModel> getMockLifts() {
    final now = DateTime.now();

    return [
      LiftModel(
        id: 'snatch',
        name: 'Snatch',
        category: LiftCategory.snatch,
        currentMax: 95.0,
        history: [
          PREntry(
            id: 'pr_sn_1',
            weight: 95.0,
            reps: 1,
            date: now.subtract(const Duration(days: 4)),
            notes: 'Smooth lockout, solid catch',
          ),
          PREntry(
            id: 'pr_sn_2',
            weight: 92.5,
            reps: 1,
            date: now.subtract(const Duration(days: 18)),
            notes: 'Good turnover speed',
          ),
          PREntry(
            id: 'pr_sn_3',
            weight: 90.0,
            reps: 1,
            date: now.subtract(const Duration(days: 35)),
            notes: 'Solid baseline',
          ),
        ],
      ),
      LiftModel(
        id: 'clean_and_jerk',
        name: 'Clean & Jerk',
        category: LiftCategory.cleanAndJerk,
        currentMax: 120.0,
        history: [
          PREntry(
            id: 'pr_cj_1',
            weight: 120.0,
            reps: 1,
            date: now.subtract(const Duration(days: 5)),
            notes: 'Fast recovery out of the hole, strong split jerk',
          ),
          PREntry(
            id: 'pr_cj_2',
            weight: 117.5,
            reps: 1,
            date: now.subtract(const Duration(days: 20)),
          ),
          PREntry(
            id: 'pr_cj_3',
            weight: 115.0,
            reps: 1,
            date: now.subtract(const Duration(days: 40)),
          ),
        ],
      ),
      LiftModel(
        id: 'power_snatch',
        name: 'Power Snatch',
        category: LiftCategory.snatch,
        anchorLiftId: 'snatch',
        targetRatio: 0.82,
        currentMax: 78.0,
      ),
      LiftModel(
        id: 'hang_snatch',
        name: 'Hang Snatch',
        category: LiftCategory.snatch,
        anchorLiftId: 'snatch',
        targetRatio: 0.88,
        currentMax: 84.0,
      ),
      LiftModel(
        id: 'muscle_snatch',
        name: 'Muscle Snatch',
        category: LiftCategory.snatch,
        anchorLiftId: 'snatch',
        targetRatio: 0.60,
        currentMax: 60.0,
      ),
      LiftModel(
        id: 'power_clean',
        name: 'Power Clean',
        category: LiftCategory.cleanAndJerk,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.85,
        currentMax: 102.0,
      ),
      LiftModel(
        id: 'hang_clean',
        name: 'Hang Clean',
        category: LiftCategory.cleanAndJerk,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.88,
        currentMax: 106.0,
      ),
      LiftModel(
        id: 'block_clean',
        name: 'Block Clean',
        category: LiftCategory.cleanAndJerk,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.90,
        currentMax: 108.0,
      ),
      LiftModel(
        id: 'back_squat',
        name: 'Back Squat',
        category: LiftCategory.squat,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 1.35,
        currentMax: 160.0,
        history: [
          PREntry(
            id: 'pr_bs_1',
            weight: 160.0,
            reps: 1,
            date: now.subtract(const Duration(days: 7)),
            notes: 'High bar depth below parallel',
          ),
          PREntry(
            id: 'pr_bs_2',
            weight: 155.0,
            reps: 3,
            date: now.subtract(const Duration(days: 25)),
          ),
        ],
      ),
      LiftModel(
        id: 'front_squat',
        name: 'Front Squat',
        category: LiftCategory.squat,
        anchorLiftId: 'back_squat',
        targetRatio: 0.85,
        currentMax: 136.0,
      ),
      LiftModel(
        id: 'snatch_pull',
        name: 'Snatch Pull',
        category: LiftCategory.pull,
        anchorLiftId: 'snatch',
        targetRatio: 1.05,
        currentMax: 105.0,
      ),
      LiftModel(
        id: 'snatch_deadlift',
        name: 'Snatch Deadlift',
        category: LiftCategory.pull,
        anchorLiftId: 'snatch',
        targetRatio: 1.15,
        currentMax: 115.0,
      ),
      LiftModel(
        id: 'military_press',
        name: 'Military Press',
        category: LiftCategory.overhead,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.55,
        currentMax: 66.0,
      ),
      LiftModel(
        id: 'push_press',
        name: 'Push Press',
        category: LiftCategory.overhead,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.75,
        currentMax: 90.0,
      ),
      LiftModel(
        id: 'rdl',
        name: 'Romanian Deadlift (RDL)',
        category: LiftCategory.pull,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.80,
        currentMax: 96.0,
      ),
    ];
  }

  static ProgramCycle getMockProgramCycle() {
    return ProgramCycle(
      currentCycle: 1,
      currentWeek: 2, // Heavy loading week (70%)
      currentDay: 1, // Day 1: Snatch & Clean Strength
      completedSessionIds: [
        'sess_w1_d1',
        'sess_w1_d2',
        'sess_w1_d3',
        'sess_w1_d4',
        'sess_w1_d5',
      ],
    );
  }

  static List<WorkoutSession> getMockWorkoutSessions() {
    final now = DateTime.now();

    return [
      WorkoutSession(
        id: 'sess_w1_d1',
        date: now.subtract(const Duration(days: 6)),
        dayNumber: 1,
        weekNumber: 1,
        cycleNumber: 1,
        durationSeconds: 3240, // 54m
        sessionRpe: 8,
        jointStrainTags: ['Wrists', 'Knees'],
        notes: 'Great opening week session. Snatch felt crisp, clean was smooth.',
        logs: [
          ExerciseLog(
            exerciseName: 'Power Snatch + Overhead Squat',
            liftId: 'snatch',
            sets: [
              CompletedSet(setIndex: 1, weight: 61.5, reps: 2, isCompleted: true),
              CompletedSet(setIndex: 2, weight: 61.5, reps: 2, isCompleted: true),
              CompletedSet(setIndex: 3, weight: 61.5, reps: 2, isCompleted: true),
              CompletedSet(setIndex: 4, weight: 61.5, reps: 2, isCompleted: true),
            ],
          ),
          ExerciseLog(
            exerciseName: 'Hang Clean',
            liftId: 'clean_and_jerk',
            sets: [
              CompletedSet(setIndex: 1, weight: 78.0, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 2, weight: 78.0, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 3, weight: 78.0, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 4, weight: 78.0, reps: 3, isCompleted: true),
            ],
          ),
          ExerciseLog(
            exerciseName: 'Back Squat',
            liftId: 'back_squat',
            sets: [
              CompletedSet(setIndex: 1, weight: 104.0, reps: 6, isCompleted: true),
              CompletedSet(setIndex: 2, weight: 104.0, reps: 6, isCompleted: true),
              CompletedSet(setIndex: 3, weight: 104.0, reps: 6, isCompleted: true),
              CompletedSet(setIndex: 4, weight: 104.0, reps: 6, isCompleted: true),
            ],
          ),
        ],
      ),
      WorkoutSession(
        id: 'sess_w1_d3',
        date: now.subtract(const Duration(days: 4)),
        dayNumber: 3,
        weekNumber: 1,
        cycleNumber: 1,
        durationSeconds: 3480, // 58m
        sessionRpe: 9,
        jointStrainTags: ['Shoulders'],
        notes: 'Explosive block cleans. Push press was fast.',
        logs: [
          ExerciseLog(
            exerciseName: 'Muscle Snatch',
            liftId: 'snatch',
            sets: [
              CompletedSet(setIndex: 1, weight: 47.5, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 2, weight: 47.5, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 3, weight: 47.5, reps: 3, isCompleted: true),
            ],
          ),
          ExerciseLog(
            exerciseName: 'Block Clean',
            liftId: 'clean_and_jerk',
            sets: [
              CompletedSet(setIndex: 1, weight: 84.0, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 2, weight: 84.0, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 3, weight: 84.0, reps: 3, isCompleted: true),
              CompletedSet(setIndex: 4, weight: 84.0, reps: 3, isCompleted: true),
            ],
          ),
        ],
      ),
      WorkoutSession(
        id: 'sess_w1_d5',
        date: now.subtract(const Duration(days: 2)),
        dayNumber: 5,
        weekNumber: 1,
        cycleNumber: 1,
        durationSeconds: 2940, // 49m
        sessionRpe: 7,
        jointStrainTags: ['Hips'],
        notes: 'Front squats felt strong and stable. Ready for Week 2.',
        logs: [
          ExerciseLog(
            exerciseName: 'Front Squat',
            liftId: 'clean_and_jerk',
            sets: [
              CompletedSet(setIndex: 1, weight: 90.0, reps: 5, isCompleted: true),
              CompletedSet(setIndex: 2, weight: 90.0, reps: 5, isCompleted: true),
              CompletedSet(setIndex: 3, weight: 90.0, reps: 5, isCompleted: true),
              CompletedSet(setIndex: 4, weight: 90.0, reps: 5, isCompleted: true),
            ],
          ),
        ],
      ),
    ];
  }

  static List<Map<String, dynamic>> getMockRecoveryLogs() {
    final now = DateTime.now();

    return [
      {
        'id': 'rec_log_1',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'durationSeconds': 900,
        'focusAreas': ['Wrists', 'Knees', 'Thoracic Spine'],
        'completedExerciseNames': [
          'Thoracic Spine Foam Roller Openers',
          'Deep Squat Ankle Mobilization',
          'Wrist Extension & Flexion Flow',
        ],
      },
    ];
  }

  static List<AccessoryLog> getMockAccessoryLogs() {
    final now = DateTime.now();

    return [
      AccessoryLog(
        id: 'acc_1',
        exerciseId: 'bicep_curls',
        exerciseName: 'Bicep Curls / Hammer Curls',
        weightKg: 10.0,
        sets: 3,
        reps: 12,
        date: now.subtract(const Duration(days: 21)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_2',
        exerciseId: 'bicep_curls',
        exerciseName: 'Bicep Curls / Hammer Curls',
        weightKg: 12.5,
        sets: 3,
        reps: 12,
        date: now.subtract(const Duration(days: 10)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_3',
        exerciseId: 'bicep_curls',
        exerciseName: 'Bicep Curls / Hammer Curls',
        weightKg: 15.0,
        sets: 3,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_4',
        exerciseId: 'tricep_extensions',
        exerciseName: 'Overhead Tricep Extensions',
        weightKg: 12.5,
        sets: 3,
        reps: 15,
        date: now.subtract(const Duration(days: 14)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_5',
        exerciseId: 'tricep_extensions',
        exerciseName: 'Overhead Tricep Extensions',
        weightKg: 15.0,
        sets: 3,
        reps: 15,
        date: now.subtract(const Duration(days: 3)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_6',
        exerciseId: 'lateral_delt_flyes',
        exerciseName: 'Lateral & Rear Delt Flyes',
        weightKg: 7.5,
        sets: 3,
        reps: 15,
        date: now.subtract(const Duration(days: 12)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_7',
        exerciseId: 'lateral_delt_flyes',
        exerciseName: 'Lateral & Rear Delt Flyes',
        weightKg: 10.0,
        sets: 3,
        reps: 15,
        date: now.subtract(const Duration(days: 4)),
        source: 'routine',
      ),
      AccessoryLog(
        id: 'acc_8',
        exerciseId: 'sots_press',
        exerciseName: 'Sots Press & Snatch Balance Prep',
        weightKg: 20.0,
        sets: 3,
        reps: 5,
        date: now.subtract(const Duration(days: 16)),
        source: 'warmup',
      ),
      AccessoryLog(
        id: 'acc_9',
        exerciseId: 'sots_press',
        exerciseName: 'Sots Press & Snatch Balance Prep',
        weightKg: 25.0,
        sets: 3,
        reps: 5,
        date: now.subtract(const Duration(days: 5)),
        source: 'warmup',
      ),
    ];
  }

  /// Seeds SharedPreferences with comprehensive mock data
  static Future<StorageService> setupMockStorage() async {
    final liftsJson = jsonEncode(getMockLifts().map((e) => e.toJson()).toList());
    final cycleJson = jsonEncode(getMockProgramCycle().toJson());
    final sessionsJson = jsonEncode(getMockWorkoutSessions().map((e) => e.toJson()).toList());
    final recoveryJson = jsonEncode(getMockRecoveryLogs());
    final accessoryJson = jsonEncode(getMockAccessoryLogs().map((e) => e.toJson()).toList());

    SharedPreferences.setMockInitialValues({
      'oly_lifts_v1': liftsJson,
      'oly_cycle_v1': cycleJson,
      'oly_sessions_v1': sessionsJson,
      'oly_recovery_logs_v1': recoveryJson,
      'oly_accessory_logs_v1': accessoryJson,
      'oly_unit_v1': false, // KG
      'oly_bar_weight_v1': 20.0,
      'oly_collar_weight_v1': 2.5,
      'oly_sound_alerts_v1': true,
      'oly_haptics_enabled_v1': true,
    });

    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }
}
