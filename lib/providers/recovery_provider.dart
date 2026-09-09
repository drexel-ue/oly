import 'package:flutter/foundation.dart';
import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/death_by_burpees_log.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/fran_workout_log.dart';
import 'package:oly/models/grace_workout_log.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/jackie_workout_log.dart';
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
  List<CindyWorkoutLog> _cindyWorkoutLogs = <CindyWorkoutLog>[];
  List<JackieWorkoutLog> _jackieWorkoutLogs = <JackieWorkoutLog>[];
  List<FranWorkoutLog> _franWorkoutLogs = <FranWorkoutLog>[];
  List<HelenWorkoutLog> _helenWorkoutLogs = <HelenWorkoutLog>[];
  List<GraceWorkoutLog> _graceWorkoutLogs = <GraceWorkoutLog>[];
  List<DtWorkoutLog> _dtWorkoutLogs = <DtWorkoutLog>[];
  List<DeathByBurpeesLog> _deathByBurpeesLogs = <DeathByBurpeesLog>[];

  void _loadLogs() {
    final List<Map<String, dynamic>> raw = _storage.loadRawRecoveryLogs();
    _recoveryLogs = raw
        .map((Map<String, dynamic> map) => RecoverySessionLog.fromJson(map))
        .toList();
    _accessoryLogs = _storage.loadAccessoryLogs();
    _kettlebellMileLogs = _storage.loadKettlebellMileLogs();
    _cindyWorkoutLogs = _storage.loadCindyWorkoutLogs();
    _jackieWorkoutLogs = _storage.loadJackieWorkoutLogs();
    _franWorkoutLogs = _storage.loadFranWorkoutLogs();
    _helenWorkoutLogs = _storage.loadHelenWorkoutLogs();
    _graceWorkoutLogs = _storage.loadGraceWorkoutLogs();
    _dtWorkoutLogs = _storage.loadDtWorkoutLogs();
    _deathByBurpeesLogs = _storage.loadDeathByBurpeesLogs();
  }

  List<RecoverySessionLog> get recoveryLogs => List.unmodifiable(_recoveryLogs);
  List<AccessoryLog> get accessoryLogs => List.unmodifiable(_accessoryLogs);
  List<KettlebellMileLog> get kettlebellMileLogs =>
      List.unmodifiable(_kettlebellMileLogs);
  List<CindyWorkoutLog> get cindyWorkoutLogs =>
      List.unmodifiable(_cindyWorkoutLogs);
  List<JackieWorkoutLog> get jackieWorkoutLogs =>
      List.unmodifiable(_jackieWorkoutLogs);
  List<FranWorkoutLog> get franWorkoutLogs =>
      List.unmodifiable(_franWorkoutLogs);
  List<HelenWorkoutLog> get helenWorkoutLogs =>
      List.unmodifiable(_helenWorkoutLogs);
  List<GraceWorkoutLog> get graceWorkoutLogs =>
      List.unmodifiable(_graceWorkoutLogs);
  List<DtWorkoutLog> get dtWorkoutLogs =>
      List.unmodifiable(_dtWorkoutLogs);
  List<DeathByBurpeesLog> get deathByBurpeesLogs =>
      List.unmodifiable(_deathByBurpeesLogs);

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

  // --- CROSSFIT CINDY METHODS ---
  List<CindyWorkoutLog> getCindyWorkoutHistory({String? tier}) {
    final List<CindyWorkoutLog> list = List<CindyWorkoutLog>.from(_cindyWorkoutLogs)
      ..sort((CindyWorkoutLog a, CindyWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((CindyWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  CindyWorkoutLog? get latestCindyWorkoutLog {
    final List<CindyWorkoutLog> history = getCindyWorkoutHistory();
    return history.isNotEmpty ? history.first : null;
  }

  CindyWorkoutLog? getCindyPersonalRecord({String? tier}) {
    final List<CindyWorkoutLog> history = getCindyWorkoutHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (CindyWorkoutLog a, CindyWorkoutLog b) => a.totalReps >= b.totalReps ? a : b,
    );
  }

  Future<CindyWorkoutLog> logCindyWorkout(CindyWorkoutLog log) async {
    final CindyWorkoutLog finalized = await _storage.logCindyWorkout(log);
    _cindyWorkoutLogs = _storage.loadCindyWorkoutLogs();
    notifyListeners();
    return finalized;
  }

  // --- CROSSFIT JACKIE METHODS ---
  List<JackieWorkoutLog> getJackieWorkoutHistory({String? tier}) {
    final List<JackieWorkoutLog> list = List<JackieWorkoutLog>.from(_jackieWorkoutLogs)
      ..sort((JackieWorkoutLog a, JackieWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((JackieWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  JackieWorkoutLog? get latestJackieWorkoutLog {
    final List<JackieWorkoutLog> history = getJackieWorkoutHistory();
    return history.isNotEmpty ? history.first : null;
  }

  JackieWorkoutLog? getJackiePersonalRecord({String? tier}) {
    final List<JackieWorkoutLog> history = getJackieWorkoutHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (JackieWorkoutLog a, JackieWorkoutLog b) => a.totalTimeSeconds <= b.totalTimeSeconds ? a : b,
    );
  }

  Future<JackieWorkoutLog> logJackieWorkout(JackieWorkoutLog log) async {
    final JackieWorkoutLog finalized = await _storage.logJackieWorkout(log);
    _jackieWorkoutLogs = _storage.loadJackieWorkoutLogs();
    notifyListeners();
    return finalized;
  }

  // --- CROSSFIT FRAN METHODS ---
  List<FranWorkoutLog> getFranWorkoutHistory({String? tier}) {
    final List<FranWorkoutLog> list = List<FranWorkoutLog>.from(_franWorkoutLogs)
      ..sort((FranWorkoutLog a, FranWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((FranWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  FranWorkoutLog? get latestFranWorkoutLog {
    final List<FranWorkoutLog> history = getFranWorkoutHistory();
    return history.isNotEmpty ? history.first : null;
  }

  FranWorkoutLog? getFranPersonalRecord({String? tier}) {
    final List<FranWorkoutLog> history = getFranWorkoutHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (FranWorkoutLog a, FranWorkoutLog b) => a.totalTimeSeconds <= b.totalTimeSeconds ? a : b,
    );
  }

  Future<FranWorkoutLog> logFranWorkout(FranWorkoutLog log) async {
    final FranWorkoutLog finalized = await _storage.logFranWorkout(log);
    _franWorkoutLogs = _storage.loadFranWorkoutLogs();
    notifyListeners();
    return finalized;
  }

  // --- CROSSFIT HELEN METHODS ---
  List<HelenWorkoutLog> getHelenWorkoutHistory({String? tier}) {
    final List<HelenWorkoutLog> list = List<HelenWorkoutLog>.from(_helenWorkoutLogs)
      ..sort((HelenWorkoutLog a, HelenWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((HelenWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  HelenWorkoutLog? get latestHelenWorkoutLog {
    final List<HelenWorkoutLog> history = getHelenWorkoutHistory();
    return history.isNotEmpty ? history.first : null;
  }

  HelenWorkoutLog? getHelenPersonalRecord({String? tier}) {
    final List<HelenWorkoutLog> history = getHelenWorkoutHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (HelenWorkoutLog a, HelenWorkoutLog b) => a.totalTimeSeconds <= b.totalTimeSeconds ? a : b,
    );
  }

  Future<HelenWorkoutLog> logHelenWorkout(HelenWorkoutLog log) async {
    final HelenWorkoutLog finalized = await _storage.logHelenWorkout(log);
    _helenWorkoutLogs = _storage.loadHelenWorkoutLogs();
    notifyListeners();
    return finalized;
  }

  // --- CROSSFIT GRACE METHODS ---
  List<GraceWorkoutLog> getGraceWorkoutHistory({String? tier}) {
    final List<GraceWorkoutLog> list = List<GraceWorkoutLog>.from(_graceWorkoutLogs)
      ..sort((GraceWorkoutLog a, GraceWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((GraceWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  GraceWorkoutLog? get latestGraceWorkoutLog {
    final List<GraceWorkoutLog> history = getGraceWorkoutHistory();
    return history.isNotEmpty ? history.first : null;
  }

  GraceWorkoutLog? getGracePersonalRecord({String? tier}) {
    final List<GraceWorkoutLog> history = getGraceWorkoutHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (GraceWorkoutLog a, GraceWorkoutLog b) => a.totalTimeSeconds <= b.totalTimeSeconds ? a : b,
    );
  }

  Future<GraceWorkoutLog> logGraceWorkout(GraceWorkoutLog log) async {
    final GraceWorkoutLog finalized = await _storage.logGraceWorkout(log);
    _graceWorkoutLogs = _storage.loadGraceWorkoutLogs();
    notifyListeners();
    return finalized;
  }

  // --- CROSSFIT HERO WOD DT METHODS ---
  List<DtWorkoutLog> getDtWorkoutHistory({String? tier}) {
    final List<DtWorkoutLog> list = List<DtWorkoutLog>.from(_dtWorkoutLogs)
      ..sort((DtWorkoutLog a, DtWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((DtWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  DtWorkoutLog? get latestDtWorkoutLog {
    final List<DtWorkoutLog> history = getDtWorkoutHistory();
    return history.isNotEmpty ? history.first : null;
  }

  DtWorkoutLog? getDtPersonalRecord({String? tier}) {
    final List<DtWorkoutLog> history = getDtWorkoutHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (DtWorkoutLog a, DtWorkoutLog b) => a.totalTimeSeconds <= b.totalTimeSeconds ? a : b,
    );
  }

  Future<DtWorkoutLog> logDtWorkout(DtWorkoutLog log) async {
    final DtWorkoutLog finalized = await _storage.logDtWorkout(log);
    _dtWorkoutLogs = _storage.loadDtWorkoutLogs();
    notifyListeners();
    return finalized;
  }

  // --- CROSSFIT BENCHMARK DEATH BY BURPEES METHODS ---
  List<DeathByBurpeesLog> getDeathByBurpeesHistory({String? tier}) {
    final List<DeathByBurpeesLog> list = List<DeathByBurpeesLog>.from(_deathByBurpeesLogs)
      ..sort((DeathByBurpeesLog a, DeathByBurpeesLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((DeathByBurpeesLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  DeathByBurpeesLog? get latestDeathByBurpeesLog {
    final List<DeathByBurpeesLog> history = getDeathByBurpeesHistory();
    return history.isNotEmpty ? history.first : null;
  }

  DeathByBurpeesLog? getDeathByBurpeesPersonalRecord({String? tier}) {
    final List<DeathByBurpeesLog> history = getDeathByBurpeesHistory(tier: tier);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (DeathByBurpeesLog a, DeathByBurpeesLog b) => a.totalReps >= b.totalReps ? a : b,
    );
  }

  Future<DeathByBurpeesLog> logDeathByBurpees(DeathByBurpeesLog log) async {
    final DeathByBurpeesLog finalized = await _storage.logDeathByBurpees(log);
    _deathByBurpeesLogs = _storage.loadDeathByBurpeesLogs();
    notifyListeners();
    return finalized;
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

