import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
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

  RecoveryProvider(this._storage) {
    _loadLogs();
  }

  void _loadLogs() {
    final raw = _storage.loadRawRecoveryLogs();
    _recoveryLogs = raw.map((map) => RecoverySessionLog.fromJson(map)).toList();
  }

  List<RecoverySessionLog> get recoveryLogs => List.unmodifiable(_recoveryLogs);

  int get totalMobilityMinutes {
    return _recoveryLogs.fold(0, (sum, log) => sum + log.durationMinutes);
  }

  int get totalSessionsCompleted => _recoveryLogs.length;

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
