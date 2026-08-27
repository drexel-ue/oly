import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/accessory_log.dart';
import '../models/mobility_exercise_model.dart';
import '../models/recovery_session_model.dart';
import '../models/workout_session.dart';
import '../services/recovery_engine_service.dart';
import '../services/storage_service.dart';
import 'lift_provider.dart';

class RecoveryProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<RecoverySessionLog> _recoveryLogs = [];
  List<AccessoryLog> _accessoryLogs = [];

  RecoveryProvider(this._storage) {
    _loadLogs();
  }

  void _loadLogs() {
    final raw = _storage.loadRawRecoveryLogs();
    _recoveryLogs = raw.map((map) => RecoverySessionLog.fromJson(map)).toList();
    _accessoryLogs = _storage.loadAccessoryLogs();
  }

  List<RecoverySessionLog> get recoveryLogs => List.unmodifiable(_recoveryLogs);
  List<AccessoryLog> get accessoryLogs => List.unmodifiable(_accessoryLogs);

  int get totalMobilityMinutes {
    return _recoveryLogs.fold(0, (sum, log) => sum + log.durationMinutes);
  }

  int get totalSessionsCompleted => _recoveryLogs.length;

  // --- ACCESSORY PROGRESSION METHODS ---
  List<AccessoryLog> getAccessoryHistory(String exerciseId) {
    return _accessoryLogs
        .where((l) => l.exerciseId == exerciseId || l.exerciseName.toLowerCase() == exerciseId.toLowerCase())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  AccessoryLog? getLatestAccessoryLog(String exerciseId) {
    final history = getAccessoryHistory(exerciseId);
    return history.isNotEmpty ? history.first : null;
  }

  double getAccessoryPersonalBest(String exerciseId) {
    final history = getAccessoryHistory(exerciseId);
    if (history.isEmpty) return 0.0;
    return history.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  }

  Map<String, List<AccessoryLog>> get groupedAccessoryProgressions {
    final Map<String, List<AccessoryLog>> map = {};
    for (var log in _accessoryLogs) {
      map.putIfAbsent(log.exerciseName, () => []).add(log);
    }
    for (var key in map.keys) {
      map[key]!.sort((a, b) => a.date.compareTo(b.date)); // chronological order
    }
    return map;
  }

  Future<void> logAccessoryWeight({
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int sets,
    required int reps,
    String? source,
    String? notes,
  }) async {
    await _storage.logAccessorySet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      weightKg: weightKg,
      sets: sets,
      reps: reps,
      source: source,
      notes: notes,
    );
    _accessoryLogs = _storage.loadAccessoryLogs();
    notifyListeners();
  }

  GeneratedRecoveryRoutine getRoutine({
    required List<LiftRatioAnalysis> ratioAnalyses,
    required WorkoutSession? lastSession,
    List<MobilityExerciseModel>? customCatalog,
  }) {
    return RecoveryEngineService.generateRoutine(
      ratioAnalyses: ratioAnalyses,
      lastSession: lastSession,
      customCatalog: customCatalog,
    );
  }

  Future<void> saveCompletedSession({
    required int durationMinutes,
    required List<String> completedExerciseIds,
    required int readinessRating,
    required List<String> diagnosticReasons,
  }) async {
    final newLog = RecoverySessionLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      completedExerciseIds: completedExerciseIds,
      readinessRating: readinessRating,
      diagnosticReasons: diagnosticReasons,
    );

    _recoveryLogs.insert(0, newLog);
    final rawList = _recoveryLogs.map((log) => log.toJson()).toList();
    await _storage.saveRawRecoveryLogs(rawList);
    notifyListeners();
  }
}
