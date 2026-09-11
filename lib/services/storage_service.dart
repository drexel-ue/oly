import 'dart:convert';

import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/death_by_burpees_log.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';
import 'package:oly/models/fasting_grocery_item.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/models/fran_workout_log.dart';
import 'package:oly/models/grace_workout_log.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/jackie_workout_log.dart';
import 'package:oly/models/kettlebell_mile_log.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/models/nutrition_goal_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._prefs);
  static const String _keyLifts = 'oly_lifts_v1';
  static const String _keyCycle = 'oly_cycle_v1';
  static const String _keySessions = 'oly_sessions_v1';
  static const String _keyUnit = 'oly_unit_v1';
  static const String _keyBarWeight = 'oly_bar_weight_v1';
  static const String _keyCollarWeight = 'oly_collar_weight_v1';
  static const String _keyRecoveryLogs = 'oly_recovery_logs_v1';
  static const String _keySoundAlerts = 'oly_sound_alerts_v1';
  static const String _keyHapticsEnabled = 'oly_haptics_enabled_v1';
  static const String _keyActiveDraft = 'oly_active_draft_v1';
  static const String _keyAccessoryLogs = 'oly_accessory_logs_v1';
  static const String _keyKettlebellMileLogs = 'oly_kettlebell_mile_logs_v1';
  static const String _keyCindyWorkoutLogs = 'oly_cindy_workout_logs_v1';
  static const String _keyJackieWorkoutLogs = 'oly_jackie_workout_logs_v1';
  static const String _keyFranWorkoutLogs = 'oly_fran_workout_logs_v1';
  static const String _keyHelenWorkoutLogs = 'oly_helen_workout_logs_v1';
  static const String _keyGraceWorkoutLogs = 'oly_grace_workout_logs_v1';
  static const String _keyDtWorkoutLogs = 'oly_dt_workout_logs_v1';
  static const String _keyDeathByBurpeesLogs = 'oly_death_by_burpees_logs_v1';
  static const String _keyBodyCompEntries = 'oly_body_comp_entries_v1';
  static const String _keyNutritionLogs = 'oly_nutrition_logs_v1';
  static const String _keyNutritionGoal = 'oly_nutrition_goal_v1';
  static const String _keyMealTemplates = 'oly_meal_templates_v1';
  static const String _keyCachedProducts = 'oly_cached_products_v1';
  static const String _keyRecentScans = 'oly_recent_scans_v1';
  static const String _keyInjuries = 'oly_injuries_v1';
  static const String _keyBreathingLogs = 'oly_breathing_logs_v1';
  static const String _keyBreathingConfig = 'oly_breathing_config_v1';
  static const String _keyCindyEmomBeep = 'oly_cindy_emom_beep_v1';
  static const String _keyBenchmarkWodLogs = 'oly_benchmark_wod_logs_v1';
  static const String _keyActiveFastingSession = 'oly_active_fasting_session_v1';
  static const String _keyFastingHistory = 'oly_fasting_history_v1';
  static const String _keyAthleteCircadianConfig =
      'oly_athlete_circadian_config_v1';
  static const String _keyFastingPantryItems = 'oly_fasting_pantry_items_v1';
  static const String _keyFastingBiomarkers = 'oly_fasting_biomarkers_v1';

  final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- LIFTS STORAGE ---
  List<LiftModel> loadLifts() {
    final String? jsonStr = _prefs.getString(_keyLifts);
    if (jsonStr == null || jsonStr.isEmpty) {
      return LiftModel.defaultLifts();
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => LiftModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return LiftModel.defaultLifts();
    }
  }

  Future<void> saveLifts(List<LiftModel> lifts) async {
    final String jsonStr = jsonEncode(
      lifts.map((LiftModel e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyLifts, jsonStr);
  }

  // --- PROGRAM CYCLE STORAGE ---
  ProgramCycle loadProgramCycle() {
    final String? jsonStr = _prefs.getString(_keyCycle);
    if (jsonStr == null || jsonStr.isEmpty) {
      return ProgramCycle();
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return ProgramCycle.fromJson(map);
    } catch (_) {
      return ProgramCycle();
    }
  }

  Future<void> saveProgramCycle(ProgramCycle cycle) async {
    final String jsonStr = jsonEncode(cycle.toJson());
    await _prefs.setString(_keyCycle, jsonStr);
  }

  // --- WORKOUT SESSIONS STORAGE ---
  List<WorkoutSession> loadWorkoutSessions() {
    final String? jsonStr = _prefs.getString(_keySessions);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <WorkoutSession>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <WorkoutSession>[];
    }
  }

  Future<void> saveWorkoutSessions(List<WorkoutSession> sessions) async {
    final String jsonStr = jsonEncode(
      sessions.map((WorkoutSession e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keySessions, jsonStr);
  }

  // --- ACTIVE WORKOUT DRAFT STORAGE ---
  ActiveWorkoutDraft? loadActiveWorkoutDraft() {
    final String? jsonStr = _prefs.getString(_keyActiveDraft);
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return ActiveWorkoutDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveWorkoutDraft(ActiveWorkoutDraft draft) async {
    final String jsonStr = jsonEncode(draft.toJson());
    await _prefs.setString(_keyActiveDraft, jsonStr);
  }

  Future<void> clearActiveWorkoutDraft() async {
    await _prefs.remove(_keyActiveDraft);
  }

  // --- SETTINGS STORAGE ---
  bool loadIsLbs() => _prefs.getBool(_keyUnit) ?? false;
  Future<void> saveIsLbs(bool isLbs) async => _prefs.setBool(_keyUnit, isLbs);

  double loadBarWeight() => _prefs.getDouble(_keyBarWeight) ?? 20.0;
  Future<void> saveBarWeight(double weight) async =>
      _prefs.setDouble(_keyBarWeight, weight);

  double loadCollarWeight() => _prefs.getDouble(_keyCollarWeight) ?? 2.5;
  Future<void> saveCollarWeight(double weight) async =>
      _prefs.setDouble(_keyCollarWeight, weight);

  // --- RECOVERY LOGS STORAGE ---
  List<Map<String, dynamic>> loadRawRecoveryLogs() {
    final String? jsonStr = _prefs.getString(_keyRecoveryLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveRawRecoveryLogs(List<Map<String, dynamic>> logs) async {
    final String jsonStr = jsonEncode(logs);
    await _prefs.setString(_keyRecoveryLogs, jsonStr);
  }

  bool loadSoundAlerts() => _prefs.getBool(_keySoundAlerts) ?? true;
  Future<void> saveSoundAlerts(bool value) async =>
      _prefs.setBool(_keySoundAlerts, value);

  bool loadHapticsEnabled() => _prefs.getBool(_keyHapticsEnabled) ?? true;
  Future<void> saveHapticsEnabled(bool value) async =>
      _prefs.setBool(_keyHapticsEnabled, value);

  bool loadCindyEmomBeep() => _prefs.getBool(_keyCindyEmomBeep) ?? false;
  Future<void> saveCindyEmomBeep(bool value) async =>
      _prefs.setBool(_keyCindyEmomBeep, value);

  // --- ACCESSORY LOGS STORAGE ---
  List<AccessoryLog> loadAccessoryLogs() {
    final String? jsonStr = _prefs.getString(_keyAccessoryLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <AccessoryLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => AccessoryLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <AccessoryLog>[];
    }
  }

  Future<void> saveAccessoryLogs(List<AccessoryLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((AccessoryLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyAccessoryLogs, jsonStr);
  }

  Future<void> logAccessorySet({
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int sets,
    required int reps,
    String? source,
    String? notes,
  }) async {
    final List<AccessoryLog> currentLogs = loadAccessoryLogs();
    final AccessoryLog newEntry = AccessoryLog(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      weightKg: weightKg,
      sets: sets,
      reps: reps,
      date: DateTime.now(),
      source: source,
      notes: notes,
    );
    currentLogs.add(newEntry);
    await saveAccessoryLogs(currentLogs);
  }

  List<AccessoryLog> getAccessoryHistory(String exerciseId) {
    return loadAccessoryLogs()
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

  // --- KETTLEBELL MILE STORAGE ---
  List<KettlebellMileLog> loadKettlebellMileLogs() {
    final String? jsonStr = _prefs.getString(_keyKettlebellMileLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <KettlebellMileLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => KettlebellMileLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <KettlebellMileLog>[];
    }
  }

  Future<void> saveKettlebellMileLogs(List<KettlebellMileLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((KettlebellMileLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyKettlebellMileLogs, jsonStr);
  }

  Future<void> logKettlebellMileSet({
    required double weightKg,
    required double bodyweightPercentage,
    required double speedMph,
    required double inclinePct,
    required int durationSeconds,
    bool? completedUnder20Min,
    String? notes,
  }) async {
    final List<KettlebellMileLog> currentLogs = loadKettlebellMileLogs();
    final bool under20 = completedUnder20Min ?? (durationSeconds > 0 && durationSeconds < 1200);
    final KettlebellMileLog newEntry = KettlebellMileLog(
      id: 'kb_mile_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      weightKg: weightKg,
      bodyweightPercentage: bodyweightPercentage,
      speedMph: speedMph,
      inclinePct: inclinePct,
      durationSeconds: durationSeconds,
      completedUnder20Min: under20,
      notes: notes,
    );
    currentLogs.insert(0, newEntry);
    await saveKettlebellMileLogs(currentLogs);
  }

  List<KettlebellMileLog> getKettlebellMileHistory() {
    final List<KettlebellMileLog> list = loadKettlebellMileLogs();
    list.sort((KettlebellMileLog a, KettlebellMileLog b) => b.date.compareTo(a.date));
    return list;
  }

  KettlebellMileLog? getLatestKettlebellMileLog() {
    final List<KettlebellMileLog> history = getKettlebellMileHistory();
    return history.isNotEmpty ? history.first : null;
  }

  // --- CROSSFIT CINDY STORAGE ---
  List<CindyWorkoutLog> loadCindyWorkoutLogs() {
    final String? jsonStr = _prefs.getString(_keyCindyWorkoutLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <CindyWorkoutLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => CindyWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <CindyWorkoutLog>[];
    }
  }

  Future<void> saveCindyWorkoutLogs(List<CindyWorkoutLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((CindyWorkoutLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyCindyWorkoutLogs, jsonStr);
  }

  Future<CindyWorkoutLog> logCindyWorkout(CindyWorkoutLog entry) async {
    final List<CindyWorkoutLog> currentLogs = loadCindyWorkoutLogs();
    final CindyWorkoutLog? currentPr = getCindyPersonalRecord(tier: entry.scalingTier);
    final bool isNewPr = currentPr == null || entry.totalReps > currentPr.totalReps;

    final CindyWorkoutLog finalized = CindyWorkoutLog(
      id: entry.id,
      date: entry.date,
      durationSeconds: entry.durationSeconds,
      completedRounds: entry.completedRounds,
      partialPullups: entry.partialPullups,
      partialPushups: entry.partialPushups,
      partialSquats: entry.partialSquats,
      rounds: entry.rounds,
      partialPullupVariation: entry.partialPullupVariation,
      partialPushupVariation: entry.partialPushupVariation,
      partialSquatVariation: entry.partialSquatVariation,
      isPr: isNewPr,
      notes: entry.notes,
    );

    currentLogs.insert(0, finalized);
    await saveCindyWorkoutLogs(currentLogs);
    return finalized;
  }

  List<CindyWorkoutLog> getCindyWorkoutHistory({String? tier}) {
    final List<CindyWorkoutLog> list = loadCindyWorkoutLogs();
    list.sort((CindyWorkoutLog a, CindyWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((CindyWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  CindyWorkoutLog? getLatestCindyWorkoutLog({String? tier}) {
    final List<CindyWorkoutLog> history = getCindyWorkoutHistory(tier: tier);
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

  // --- CROSSFIT JACKIE STORAGE ---
  List<JackieWorkoutLog> loadJackieWorkoutLogs() {
    final String? jsonStr = _prefs.getString(_keyJackieWorkoutLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <JackieWorkoutLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => JackieWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <JackieWorkoutLog>[];
    }
  }

  Future<void> saveJackieWorkoutLogs(List<JackieWorkoutLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((JackieWorkoutLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyJackieWorkoutLogs, jsonStr);
  }

  Future<JackieWorkoutLog> logJackieWorkout(JackieWorkoutLog entry) async {
    final List<JackieWorkoutLog> currentLogs = loadJackieWorkoutLogs();
    final JackieWorkoutLog? currentPr = getJackiePersonalRecord(tier: entry.scalingTier);
    final bool isNewPr = currentPr == null || entry.totalTimeSeconds < currentPr.totalTimeSeconds;

    final JackieWorkoutLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveJackieWorkoutLogs(currentLogs);
    return finalized;
  }

  List<JackieWorkoutLog> getJackieWorkoutHistory({String? tier}) {
    final List<JackieWorkoutLog> list = loadJackieWorkoutLogs();
    list.sort((JackieWorkoutLog a, JackieWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((JackieWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  JackieWorkoutLog? getLatestJackieWorkoutLog({String? tier}) {
    final List<JackieWorkoutLog> history = getJackieWorkoutHistory(tier: tier);
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

  // --- CROSSFIT FRAN STORAGE ---
  List<FranWorkoutLog> loadFranWorkoutLogs() {
    final String? jsonStr = _prefs.getString(_keyFranWorkoutLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <FranWorkoutLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => FranWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <FranWorkoutLog>[];
    }
  }

  Future<void> saveFranWorkoutLogs(List<FranWorkoutLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((FranWorkoutLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyFranWorkoutLogs, jsonStr);
  }

  Future<FranWorkoutLog> logFranWorkout(FranWorkoutLog entry) async {
    final List<FranWorkoutLog> currentLogs = loadFranWorkoutLogs();
    final FranWorkoutLog? currentPr = getFranPersonalRecord(tier: entry.scalingTier);
    final bool isNewPr = currentPr == null || entry.totalTimeSeconds < currentPr.totalTimeSeconds;

    final FranWorkoutLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveFranWorkoutLogs(currentLogs);
    return finalized;
  }

  List<FranWorkoutLog> getFranWorkoutHistory({String? tier}) {
    final List<FranWorkoutLog> list = loadFranWorkoutLogs();
    list.sort((FranWorkoutLog a, FranWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((FranWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  FranWorkoutLog? getLatestFranWorkoutLog({String? tier}) {
    final List<FranWorkoutLog> history = getFranWorkoutHistory(tier: tier);
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

  // --- CROSSFIT HELEN STORAGE ---
  List<HelenWorkoutLog> loadHelenWorkoutLogs() {
    final String? jsonStr = _prefs.getString(_keyHelenWorkoutLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <HelenWorkoutLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => HelenWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <HelenWorkoutLog>[];
    }
  }

  Future<void> saveHelenWorkoutLogs(List<HelenWorkoutLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((HelenWorkoutLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyHelenWorkoutLogs, jsonStr);
  }

  Future<HelenWorkoutLog> logHelenWorkout(HelenWorkoutLog entry) async {
    final List<HelenWorkoutLog> currentLogs = loadHelenWorkoutLogs();
    final HelenWorkoutLog? currentPr = getHelenPersonalRecord(tier: entry.scalingTier);
    final bool isNewPr = currentPr == null || entry.totalTimeSeconds < currentPr.totalTimeSeconds;

    final HelenWorkoutLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveHelenWorkoutLogs(currentLogs);
    return finalized;
  }

  List<HelenWorkoutLog> getHelenWorkoutHistory({String? tier}) {
    final List<HelenWorkoutLog> list = loadHelenWorkoutLogs();
    list.sort((HelenWorkoutLog a, HelenWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((HelenWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  HelenWorkoutLog? getLatestHelenWorkoutLog({String? tier}) {
    final List<HelenWorkoutLog> history = getHelenWorkoutHistory(tier: tier);
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

  // --- CROSSFIT GRACE STORAGE ---
  List<GraceWorkoutLog> loadGraceWorkoutLogs() {
    final String? jsonStr = _prefs.getString(_keyGraceWorkoutLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <GraceWorkoutLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => GraceWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <GraceWorkoutLog>[];
    }
  }

  Future<void> saveGraceWorkoutLogs(List<GraceWorkoutLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((GraceWorkoutLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyGraceWorkoutLogs, jsonStr);
  }

  Future<GraceWorkoutLog> logGraceWorkout(GraceWorkoutLog entry) async {
    final List<GraceWorkoutLog> currentLogs = loadGraceWorkoutLogs();
    final GraceWorkoutLog? currentPr = getGracePersonalRecord(tier: entry.scalingTier);
    final bool isNewPr = currentPr == null || entry.totalTimeSeconds < currentPr.totalTimeSeconds;

    final GraceWorkoutLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveGraceWorkoutLogs(currentLogs);
    return finalized;
  }

  List<GraceWorkoutLog> getGraceWorkoutHistory({String? tier}) {
    final List<GraceWorkoutLog> list = loadGraceWorkoutLogs();
    list.sort((GraceWorkoutLog a, GraceWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((GraceWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  GraceWorkoutLog? getLatestGraceWorkoutLog({String? tier}) {
    final List<GraceWorkoutLog> history = getGraceWorkoutHistory(tier: tier);
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

  // --- CROSSFIT HERO WOD DT STORAGE ---
  List<DtWorkoutLog> loadDtWorkoutLogs() {
    final String? jsonStr = _prefs.getString(_keyDtWorkoutLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <DtWorkoutLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => DtWorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <DtWorkoutLog>[];
    }
  }

  Future<void> saveDtWorkoutLogs(List<DtWorkoutLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((DtWorkoutLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyDtWorkoutLogs, jsonStr);
  }

  Future<DtWorkoutLog> logDtWorkout(DtWorkoutLog entry) async {
    final List<DtWorkoutLog> currentLogs = loadDtWorkoutLogs();
    final DtWorkoutLog? currentPr = getDtPersonalRecord(tier: entry.scalingTier);
    final bool isNewPr = currentPr == null || entry.totalTimeSeconds < currentPr.totalTimeSeconds;

    final DtWorkoutLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveDtWorkoutLogs(currentLogs);
    return finalized;
  }

  List<DtWorkoutLog> getDtWorkoutHistory({String? tier}) {
    final List<DtWorkoutLog> list = loadDtWorkoutLogs();
    list.sort((DtWorkoutLog a, DtWorkoutLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((DtWorkoutLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  DtWorkoutLog? getLatestDtWorkoutLog({String? tier}) {
    final List<DtWorkoutLog> history = getDtWorkoutHistory(tier: tier);
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

  // --- CROSSFIT BENCHMARK DEATH BY BURPEES STORAGE ---
  List<DeathByBurpeesLog> loadDeathByBurpeesLogs() {
    final String? jsonStr = _prefs.getString(_keyDeathByBurpeesLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <DeathByBurpeesLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => DeathByBurpeesLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <DeathByBurpeesLog>[];
    }
  }

  Future<void> saveDeathByBurpeesLogs(List<DeathByBurpeesLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((DeathByBurpeesLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyDeathByBurpeesLogs, jsonStr);
  }

  Future<DeathByBurpeesLog> logDeathByBurpees(DeathByBurpeesLog entry) async {
    final List<DeathByBurpeesLog> currentLogs = loadDeathByBurpeesLogs();
    final DeathByBurpeesLog? currentPr = getDeathByBurpeesPersonalRecord(tier: entry.scalingTier);
    // In Death by Burpees, more total reps / minutes is better!
    final bool isNewPr = currentPr == null || entry.totalReps > currentPr.totalReps;

    final DeathByBurpeesLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveDeathByBurpeesLogs(currentLogs);
    return finalized;
  }

  List<DeathByBurpeesLog> getDeathByBurpeesHistory({String? tier}) {
    final List<DeathByBurpeesLog> list = loadDeathByBurpeesLogs();
    list.sort((DeathByBurpeesLog a, DeathByBurpeesLog b) => b.date.compareTo(a.date));
    if (tier != null) {
      return list.where((DeathByBurpeesLog e) => e.scalingTier == tier).toList();
    }
    return list;
  }

  DeathByBurpeesLog? getLatestDeathByBurpeesLog({String? tier}) {
    final List<DeathByBurpeesLog> history = getDeathByBurpeesHistory(tier: tier);
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

  // --- BENCHMARK & HERO WOD STORAGE ---
  List<BenchmarkWodLog> loadBenchmarkWodLogs() {
    final String? jsonStr = _prefs.getString(_keyBenchmarkWodLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <BenchmarkWodLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => BenchmarkWodLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <BenchmarkWodLog>[];
    }
  }

  Future<void> saveBenchmarkWodLogs(List<BenchmarkWodLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((BenchmarkWodLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyBenchmarkWodLogs, jsonStr);
  }

  Future<BenchmarkWodLog> logBenchmarkWod(BenchmarkWodLog entry) async {
    final List<BenchmarkWodLog> currentLogs = loadBenchmarkWodLogs();
    final BenchmarkWodLog? currentPr = getBenchmarkWodPersonalRecord(entry.wodId, isRx: entry.isRx);

    // Check if new attempt beats previous PR (or is the first attempt)
    final bool isNewPr = currentPr == null || entry.isBetterScoreThan(currentPr);

    final BenchmarkWodLog finalized = entry.copyWith(isPr: isNewPr);
    currentLogs.insert(0, finalized);
    await saveBenchmarkWodLogs(currentLogs);
    return finalized;
  }

  Future<void> deleteBenchmarkWodLog(String id) async {
    final List<BenchmarkWodLog> currentLogs = loadBenchmarkWodLogs();
    currentLogs.removeWhere((BenchmarkWodLog log) => log.id == id);
    _recalculateBenchmarkPrs(currentLogs);
    await saveBenchmarkWodLogs(currentLogs);
  }

  void _recalculateBenchmarkPrs(List<BenchmarkWodLog> logs) {
    final List<BenchmarkWodLog> chronological = List<BenchmarkWodLog>.from(logs)
      ..sort((BenchmarkWodLog a, BenchmarkWodLog b) => a.date.compareTo(b.date));
    final Map<String, BenchmarkWodLog> bestPerWodTier = <String, BenchmarkWodLog>{};
    for (int i = 0; i < chronological.length; i++) {
      final BenchmarkWodLog item = chronological[i];
      final String key = '${item.wodId.toLowerCase()}_${item.isRx}';
      final BenchmarkWodLog? prevBest = bestPerWodTier[key];
      if (prevBest == null || item.isBetterScoreThan(prevBest)) {
        bestPerWodTier[key] = item;
      }
    }
    for (int i = 0; i < logs.length; i++) {
      final BenchmarkWodLog log = logs[i];
      final String key = '${log.wodId.toLowerCase()}_${log.isRx}';
      final bool isBest = bestPerWodTier[key]?.id == log.id;
      if (log.isPr != isBest) {
        logs[i] = log.copyWith(isPr: isBest);
      }
    }
  }

  List<BenchmarkWodLog> getBenchmarkWodHistory(String wodId, {bool? isRx}) {
    final List<BenchmarkWodLog> list = loadBenchmarkWodLogs()
        .where((BenchmarkWodLog e) => e.wodId.toLowerCase() == wodId.toLowerCase())
        .toList();
    list.sort((BenchmarkWodLog a, BenchmarkWodLog b) => b.date.compareTo(a.date));
    if (isRx != null) {
      return list.where((BenchmarkWodLog e) => e.isRx == isRx).toList();
    }
    return list;
  }

  BenchmarkWodLog? getBenchmarkWodPersonalRecord(String wodId, {bool? isRx}) {
    final List<BenchmarkWodLog> history = getBenchmarkWodHistory(wodId, isRx: isRx);
    if (history.isEmpty) {
      return null;
    }
    return history.reduce(
      (BenchmarkWodLog a, BenchmarkWodLog b) => a.isBetterScoreThan(b) ? a : b,
    );
  }

  Map<String, BenchmarkWodLog> getAllBenchmarkPersonalRecords() {
    final List<BenchmarkWodLog> all = loadBenchmarkWodLogs();
    final Map<String, BenchmarkWodLog> prs = <String, BenchmarkWodLog>{};
    for (final BenchmarkWodLog log in all) {
      final String key = log.wodId.toLowerCase();
      final BenchmarkWodLog? existing = prs[key];
      if (existing == null || log.isBetterScoreThan(existing)) {
        prs[key] = log;
      }
    }
    return prs;
  }

  Set<String> getCompletedWodIds() {
    final List<BenchmarkWodLog> all = loadBenchmarkWodLogs();
    return all.map((BenchmarkWodLog e) => e.wodId.toLowerCase()).toSet();
  }

  // --- EXPORT & IMPORT UTILITIES ---
  String exportFullAppDataJson() {
    final Map<String, dynamic> map = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'lifts': jsonDecode(_prefs.getString(_keyLifts) ?? '[]'),
      'cycle': jsonDecode(_prefs.getString(_keyCycle) ?? '{}'),
      'workoutSessions': jsonDecode(_prefs.getString(_keySessions) ?? '[]'),
      'recoveryLogs': jsonDecode(_prefs.getString(_keyRecoveryLogs) ?? '[]'),
      'accessoryLogs': jsonDecode(_prefs.getString(_keyAccessoryLogs) ?? '[]'),
      'kettlebellMileLogs': jsonDecode(_prefs.getString(_keyKettlebellMileLogs) ?? '[]'),
      'cindyWorkoutLogs': jsonDecode(_prefs.getString(_keyCindyWorkoutLogs) ?? '[]'),
      'jackieWorkoutLogs': jsonDecode(_prefs.getString(_keyJackieWorkoutLogs) ?? '[]'),
      'franWorkoutLogs': jsonDecode(_prefs.getString(_keyFranWorkoutLogs) ?? '[]'),
      'helenWorkoutLogs': jsonDecode(_prefs.getString(_keyHelenWorkoutLogs) ?? '[]'),
      'graceWorkoutLogs': jsonDecode(_prefs.getString(_keyGraceWorkoutLogs) ?? '[]'),
      'dtWorkoutLogs': jsonDecode(_prefs.getString(_keyDtWorkoutLogs) ?? '[]'),
      'deathByBurpeesLogs': jsonDecode(_prefs.getString(_keyDeathByBurpeesLogs) ?? '[]'),
      'breathingLogs': jsonDecode(_prefs.getString(_keyBreathingLogs) ?? '[]'),
      'breathingConfig': jsonDecode(_prefs.getString(_keyBreathingConfig) ?? '{}'),
      'settings': <String, Object>{
        'isLbs': loadIsLbs(),
        'barWeight': loadBarWeight(),
        'collarWeight': loadCollarWeight(),
        'soundAlerts': loadSoundAlerts(),
        'hapticsEnabled': loadHapticsEnabled(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  String exportPrsCsv() {
    final List<LiftModel> lifts = loadLifts();
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'Lift Name,Category,1RM (KG),1RM (LBS),Target Ratio,Anchor Lift ID',
    );
    for (final LiftModel lift in lifts) {
      final String lbs = (lift.currentMax * 2.20462).toStringAsFixed(1);
      buffer.writeln(
        '${lift.name},${lift.category.name},${lift.currentMax.toStringAsFixed(1)},$lbs,${lift.targetRatio},${lift.anchorLiftId ?? ''}',
      );
    }
    return buffer.toString();
  }

  Future<bool> importAppDataJson(String jsonStr) async {
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      if (map.containsKey('lifts')) {
        await _prefs.setString(_keyLifts, jsonEncode(map['lifts']));
      }
      if (map.containsKey('cycle')) {
        await _prefs.setString(_keyCycle, jsonEncode(map['cycle']));
      }
      if (map.containsKey('workoutSessions')) {
        await _prefs.setString(
          _keySessions,
          jsonEncode(map['workoutSessions']),
        );
      }
      if (map.containsKey('recoveryLogs')) {
        await _prefs.setString(
          _keyRecoveryLogs,
          jsonEncode(map['recoveryLogs']),
        );
      }
      if (map.containsKey('accessoryLogs')) {
        await _prefs.setString(
          _keyAccessoryLogs,
          jsonEncode(map['accessoryLogs']),
        );
      }
      if (map.containsKey('cindyWorkoutLogs')) {
        await _prefs.setString(
          _keyCindyWorkoutLogs,
          jsonEncode(map['cindyWorkoutLogs']),
        );
      }
      if (map.containsKey('jackieWorkoutLogs')) {
        await _prefs.setString(
          _keyJackieWorkoutLogs,
          jsonEncode(map['jackieWorkoutLogs']),
        );
      }
      if (map.containsKey('franWorkoutLogs')) {
        await _prefs.setString(
          _keyFranWorkoutLogs,
          jsonEncode(map['franWorkoutLogs']),
        );
      }
      if (map.containsKey('helenWorkoutLogs')) {
        await _prefs.setString(
          _keyHelenWorkoutLogs,
          jsonEncode(map['helenWorkoutLogs']),
        );
      }
      if (map.containsKey('graceWorkoutLogs')) {
        await _prefs.setString(
          _keyGraceWorkoutLogs,
          jsonEncode(map['graceWorkoutLogs']),
        );
      }
      if (map.containsKey('dtWorkoutLogs')) {
        await _prefs.setString(
          _keyDtWorkoutLogs,
          jsonEncode(map['dtWorkoutLogs']),
        );
      }
      if (map.containsKey('deathByBurpeesLogs')) {
        await _prefs.setString(
          _keyDeathByBurpeesLogs,
          jsonEncode(map['deathByBurpeesLogs']),
        );
      }
      if (map.containsKey('breathingLogs')) {
        await _prefs.setString(
          _keyBreathingLogs,
          jsonEncode(map['breathingLogs']),
        );
      }
      if (map.containsKey('breathingConfig')) {
        await _prefs.setString(
          _keyBreathingConfig,
          jsonEncode(map['breathingConfig']),
        );
      }
      if (map.containsKey('settings')) {
        final Map<String, dynamic> s = map['settings'] as Map<String, dynamic>;
        if (s.containsKey('isLbs')) {
          await saveIsLbs(s['isLbs'] as bool);
        }
        if (s.containsKey('barWeight')) {
          await saveBarWeight((s['barWeight'] as num).toDouble());
        }
        if (s.containsKey('collarWeight')) {
          await saveCollarWeight((s['collarWeight'] as num).toDouble());
        }
        if (s.containsKey('soundAlerts')) {
          await saveSoundAlerts(s['soundAlerts'] as bool);
        }
        if (s.containsKey('hapticsEnabled')) {
          await saveHapticsEnabled(s['hapticsEnabled'] as bool);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> importPrsCsv(String csvStr) async {
    try {
      final List<String> lines = csvStr
          .split(RegExp(r'\r?\n'))
          .where((String l) => l.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        return false;
      }

      final List<LiftModel> lifts = loadLifts();
      bool updated = false;

      final int startIndex = lines.first.toLowerCase().contains('lift name')
          ? 1
          : 0;

      for (int i = startIndex; i < lines.length; i++) {
        final List<String> parts = lines[i]
            .split(',')
            .map((String p) => p.trim())
            .toList();
        if (parts.length < 3) {
          continue;
        }

        final String liftName = parts[0];
        final double? maxKg = double.tryParse(parts[2]);

        if (maxKg != null && maxKg > 0) {
          final int liftIndex = lifts.indexWhere(
            (LiftModel l) => l.name.toLowerCase() == liftName.toLowerCase(),
          );
          if (liftIndex != -1) {
            lifts[liftIndex].currentMax = maxKg;
            updated = true;
          }
        }
      }

      if (updated) {
        await saveLifts(lifts);
      }
      return updated;
    } catch (_) {
      return false;
    }
  }

  // --- BODY COMPOSITION STORAGE ---
  List<BodyCompositionEntry> loadBodyCompEntries() {
    final String? jsonStr = _prefs.getString(_keyBodyCompEntries);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <BodyCompositionEntry>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final List<BodyCompositionEntry> entries = list
          .map((e) => BodyCompositionEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort(
        (BodyCompositionEntry a, BodyCompositionEntry b) =>
            b.timestamp.compareTo(a.timestamp),
      );
      return entries;
    } catch (_) {
      return <BodyCompositionEntry>[];
    }
  }

  Future<void> saveBodyCompEntries(List<BodyCompositionEntry> entries) async {
    final String jsonStr = jsonEncode(
      entries.map((BodyCompositionEntry e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyBodyCompEntries, jsonStr);
  }

  // --- DAILY NUTRITION LOGS STORAGE ---
  Map<String, DailyNutritionLog> loadDailyNutritionLogs() {
    final String? jsonStr = _prefs.getString(_keyNutritionLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <String, DailyNutritionLog>{};
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map(
        (String k, v) =>
            MapEntry(k, DailyNutritionLog.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return <String, DailyNutritionLog>{};
    }
  }

  Future<void> saveDailyNutritionLogs(
    Map<String, DailyNutritionLog> logs,
  ) async {
    final Map<String, Map<String, dynamic>> map = logs.map(
      (String k, DailyNutritionLog v) => MapEntry(k, v.toJson()),
    );
    final String jsonStr = jsonEncode(map);
    await _prefs.setString(_keyNutritionLogs, jsonStr);
  }

  // --- NUTRITION GOAL STORAGE ---
  NutritionGoalModel loadNutritionGoal() {
    final String? jsonStr = _prefs.getString(_keyNutritionGoal);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const NutritionGoalModel();
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return NutritionGoalModel.fromJson(map);
    } catch (_) {
      return const NutritionGoalModel();
    }
  }

  Future<void> saveNutritionGoal(NutritionGoalModel goal) async {
    final String jsonStr = jsonEncode(goal.toJson());
    await _prefs.setString(_keyNutritionGoal, jsonStr);
  }

  // --- MEAL TEMPLATES / FAVORITES STORAGE ---
  List<NutritionEntry> loadMealTemplates() {
    final String? jsonStr = _prefs.getString(_keyMealTemplates);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <NutritionEntry>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => NutritionEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <NutritionEntry>[];
    }
  }

  Future<void> saveMealTemplates(List<NutritionEntry> templates) async {
    final String jsonStr = jsonEncode(
      templates.map((NutritionEntry e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyMealTemplates, jsonStr);
  }

  // --- PRODUCT CACHING STORAGE ---
  Map<String, Map<String, dynamic>> loadCachedProductsJson() {
    final String? jsonStr = _prefs.getString(_keyCachedProducts);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map(
        (String k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return <String, Map<String, dynamic>>{};
    }
  }

  Future<void> saveCachedProductJson(
    String barcode,
    Map<String, dynamic> jsonMap,
  ) async {
    final Map<String, Map<String, dynamic>> current = loadCachedProductsJson();
    current[barcode] = jsonMap;
    await _prefs.setString(_keyCachedProducts, jsonEncode(current));
  }

  Future<void> removeCachedProduct(String barcode) async {
    final Map<String, Map<String, dynamic>> current = loadCachedProductsJson();
    if (current.containsKey(barcode)) {
      current.remove(barcode);
      await _prefs.setString(_keyCachedProducts, jsonEncode(current));
    }
  }

  // --- RECENT SCANNED BARCODES STORAGE ---
  List<String> loadRecentScannedBarcodes() {
    final List<String>? list = _prefs.getStringList(_keyRecentScans);
    return list ?? <String>[];
  }

  Future<void> addRecentScannedBarcode(String barcode) async {
    final List<String> list = loadRecentScannedBarcodes();
    list.removeWhere((String b) => b == barcode);
    list.insert(0, barcode);
    if (list.length > 20) {
      list.removeRange(20, list.length);
    }
    await _prefs.setStringList(_keyRecentScans, list);
  }

  Future<void> clearRecentScans() async {
    await _prefs.remove(_keyRecentScans);
  }

  // --- INJURY TRACKING STORAGE ---
  List<InjuryRecord> loadInjuries() {
    final String? jsonStr = _prefs.getString(_keyInjuries);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <InjuryRecord>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) => InjuryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <InjuryRecord>[];
    }
  }

  Future<void> saveInjuries(List<InjuryRecord> injuries) async {
    final String jsonStr = jsonEncode(
      injuries.map((InjuryRecord e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyInjuries, jsonStr);
  }

  // --- BREATHING / WIM HOF STORAGE ---
  List<BreathingSessionLog> loadBreathingLogs() {
    final String? jsonStr = _prefs.getString(_keyBreathingLogs);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <BreathingSessionLog>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final List<BreathingSessionLog> logs = list
          .map((dynamic e) =>
              BreathingSessionLog.fromJson(e as Map<String, dynamic>))
          .toList();
      logs.sort((BreathingSessionLog a, BreathingSessionLog b) =>
          b.date.compareTo(a.date));
      return logs;
    } catch (_) {
      return <BreathingSessionLog>[];
    }
  }

  Future<void> saveBreathingLogs(List<BreathingSessionLog> logs) async {
    final String jsonStr = jsonEncode(
      logs.map((BreathingSessionLog e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyBreathingLogs, jsonStr);
  }

  WimHofConfig loadBreathingConfig() {
    final String? jsonStr = _prefs.getString(_keyBreathingConfig);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const WimHofConfig();
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return WimHofConfig.fromJson(map);
    } catch (_) {
      return const WimHofConfig();
    }
  }

  Future<void> saveBreathingConfig(WimHofConfig config) async {
    final String jsonStr = jsonEncode(config.toJson());
    await _prefs.setString(_keyBreathingConfig, jsonStr);
  }

  // --- GUIDED FASTING STORAGE ---
  FastingSession? loadActiveFastingSession() {
    final String? jsonStr = _prefs.getString(_keyActiveFastingSession);
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return FastingSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveFastingSession(FastingSession? session) async {
    if (session == null) {
      await _prefs.remove(_keyActiveFastingSession);
    } else {
      final String jsonStr = jsonEncode(session.toJson());
      await _prefs.setString(_keyActiveFastingSession, jsonStr);
    }
  }

  List<FastingSession> loadFastingHistory() {
    final String? jsonStr = _prefs.getString(_keyFastingHistory);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <FastingSession>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final List<FastingSession> history = list
          .map((dynamic e) => FastingSession.fromJson(e as Map<String, dynamic>))
          .toList();
      history.sort((FastingSession a, FastingSession b) =>
          b.startTime.compareTo(a.startTime));
      return history;
    } catch (_) {
      return <FastingSession>[];
    }
  }

  Future<void> saveFastingHistory(List<FastingSession> history) async {
    final String jsonStr = jsonEncode(
      history.map((FastingSession s) => s.toJson()).toList(),
    );
    await _prefs.setString(_keyFastingHistory, jsonStr);
  }

  AthleteCircadianConfig loadAthleteCircadianConfig() {
    final String? jsonStr = _prefs.getString(_keyAthleteCircadianConfig);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const AthleteCircadianConfig();
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return AthleteCircadianConfig.fromJson(map);
    } catch (_) {
      return const AthleteCircadianConfig();
    }
  }

  Future<void> saveAthleteCircadianConfig(AthleteCircadianConfig config) async {
    final String jsonStr = jsonEncode(config.toJson());
    await _prefs.setString(_keyAthleteCircadianConfig, jsonStr);
  }

  List<FastingGroceryItem> loadFastingPantryItems() {
    final String? jsonStr = _prefs.getString(_keyFastingPantryItems);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <FastingGroceryItem>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) =>
              FastingGroceryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <FastingGroceryItem>[];
    }
  }

  Future<void> saveFastingPantryItems(List<FastingGroceryItem> items) async {
    final String jsonStr = jsonEncode(
      items.map((FastingGroceryItem i) => i.toJson()).toList(),
    );
    await _prefs.setString(_keyFastingPantryItems, jsonStr);
  }

  List<FastingBiomarkerEntry> loadFastingBiomarkers() {
    final String? jsonStr = _prefs.getString(_keyFastingBiomarkers);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <FastingBiomarkerEntry>[];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((dynamic e) =>
              FastingBiomarkerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <FastingBiomarkerEntry>[];
    }
  }

  Future<void> saveFastingBiomarkers(List<FastingBiomarkerEntry> entries) async {
    final String jsonStr = jsonEncode(
      entries.map((FastingBiomarkerEntry e) => e.toJson()).toList(),
    );
    await _prefs.setString(_keyFastingBiomarkers, jsonStr);
  }
}
