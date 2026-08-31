import 'package:flutter/foundation.dart';
import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/kettlebell_mile_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/recovery_session_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class RecoveryProvider extends ChangeNotifier {
  RecoveryProvider(this._storage) {
    _loadLogs();
  }
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  List<RecoverySessionLog> _recoveryLogs = <RecoverySessionLog>[];
  List<AccessoryLog> _accessoryLogs = <AccessoryLog>[];
  List<KettlebellMileLog> _kettlebellMileLogs = <KettlebellMileLog>[];

  void _loadLogs() {
    final List<Map<String, dynamic>> raw = _storage.loadRawRecoveryLogs();
    _recoveryLogs = raw
        .map((Map<String, dynamic> map) => RecoverySessionLog.fromJson(map))
        .toList();
    _accessoryLogs = _storage.loadAccessoryLogs();
    _kettlebellMileLogs = _storage.loadKettlebellMileLogs();
  }

  List<RecoverySessionLog> get recoveryLogs => List.unmodifiable(_recoveryLogs);
  List<AccessoryLog> get accessoryLogs => List.unmodifiable(_accessoryLogs);
  List<KettlebellMileLog> get kettlebellMileLogs =>
      List.unmodifiable(_kettlebellMileLogs);

  int get totalMobilityMinutes {
    return _recoveryLogs.fold(
      0,
      (int sum, RecoverySessionLog log) => sum + log.durationMinutes,
    );
  }

  int get totalSessionsCompleted => _recoveryLogs.length;

  // --- KETTLEBELL MILE PROGRESSION METHODS ---
  List<KettlebellMileLog> getKettlebellMileHistory() {
    return List<KettlebellMileLog>.from(_kettlebellMileLogs)
      ..sort((KettlebellMileLog a, KettlebellMileLog b) => b.date.compareTo(a.date));
  }

  KettlebellMileLog? get latestKettlebellMileLog {
    final List<KettlebellMileLog> history = getKettlebellMileHistory();
    return history.isNotEmpty ? history.first : null;
  }

  /// Calculates the suggested target Kettlebell % of bodyweight (10% to 30%).
  /// When previous session is completed in under 20 minutes (< 1200s), progresses by 2.5% up to 30%.
  double getCurrentKettlebellTargetPercentage() {
    final KettlebellMileLog? latest = latestKettlebellMileLog;
    if (latest == null) {
      return 10.0; // Baseline start at 10% BW
    }

    if (latest.completedUnder20Min ||
        (latest.durationSeconds > 0 && latest.durationSeconds < 1200)) {
      // Completed in under 20 mins -> Progress +2.5% BW (up to 30%)
      final double nextPct = latest.bodyweightPercentage + 2.5;
      return nextPct.clamp(10.0, 30.0);
    }

    return latest.bodyweightPercentage.clamp(10.0, 30.0);
  }

  /// Calculates target Kettlebell weight in KG for a given athlete bodyweight
  double calculateSuggestedKettlebellWeightKg({required double athleteWeightKg}) {
    final double targetPct = getCurrentKettlebellTargetPercentage();
    final double weight = athleteWeightKg * (targetPct / 100.0);
    // Round to nearest 0.5kg or standard increment
    return double.parse(weight.toStringAsFixed(1));
  }

  Future<void> logKettlebellMile({
    required double weightKg,
    required double bodyweightPercentage,
    required double speedMph,
    required double inclinePct,
    required int durationSeconds,
    bool? completedUnder20Min,
    String? notes,
  }) async {
    await _storage.logKettlebellMileSet(
      weightKg: weightKg,
      bodyweightPercentage: bodyweightPercentage,
      speedMph: speedMph,
      inclinePct: inclinePct,
      durationSeconds: durationSeconds,
      completedUnder20Min: completedUnder20Min,
      notes: notes,
    );
    _kettlebellMileLogs = _storage.loadKettlebellMileLogs();
    notifyListeners();
  }

  // --- ACCESSORY PROGRESSION METHODS ---
  List<AccessoryLog> getAccessoryHistory(String exerciseId) {
    return _accessoryLogs
        .where(
          (AccessoryLog l) =>
              l.exerciseId == exerciseId ||
              l.exerciseName.toLowerCase() == exerciseId.toLowerCase(),
        )
        .toList()
      ..sort((AccessoryLog a, AccessoryLog b) => b.date.compareTo(a.date));
  }

  AccessoryLog? getLatestAccessoryLog(String exerciseId) {
    final List<AccessoryLog> history = getAccessoryHistory(exerciseId);
    return history.isNotEmpty ? history.first : null;
  }

  double getAccessoryPersonalBest(String exerciseId) {
    final List<AccessoryLog> history = getAccessoryHistory(exerciseId);
    if (history.isEmpty) {
      return 0.0;
    }
    return history
        .map((AccessoryLog e) => e.weightKg)
        .reduce((double a, double b) => a > b ? a : b);
  }

  Map<String, List<AccessoryLog>> get groupedAccessoryProgressions {
    final Map<String, List<AccessoryLog>> map = <String, List<AccessoryLog>>{};
    for (final AccessoryLog log in _accessoryLogs) {
      map.putIfAbsent(log.exerciseName, () => <AccessoryLog>[]).add(log);
    }
    for (final String key in map.keys) {
      map[key]!.sort(
        (AccessoryLog a, AccessoryLog b) => a.date.compareTo(b.date),
      ); // chronological order
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
    final RecoverySessionLog newLog = RecoverySessionLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      completedExerciseIds: completedExerciseIds,
      readinessRating: readinessRating,
      diagnosticReasons: diagnosticReasons,
    );

    _recoveryLogs.insert(0, newLog);
    final List<Map<String, dynamic>> rawList = _recoveryLogs
        .map((RecoverySessionLog log) => log.toJson())
        .toList();
    await _storage.saveRawRecoveryLogs(rawList);
    notifyListeners();
  }
}

