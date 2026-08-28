import 'dart:convert';

import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/injury_model.dart';
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
  static const String _keyBodyCompEntries = 'oly_body_comp_entries_v1';
  static const String _keyNutritionLogs = 'oly_nutrition_logs_v1';
  static const String _keyNutritionGoal = 'oly_nutrition_goal_v1';
  static const String _keyMealTemplates = 'oly_meal_templates_v1';
  static const String _keyCachedProducts = 'oly_cached_products_v1';
  static const String _keyRecentScans = 'oly_recent_scans_v1';
  static const String _keyInjuries = 'oly_injuries_v1';

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

  // --- EXPORT & IMPORT UTILITIES ---
  String exportFullAppDataJson() {
    final Map<String, dynamic> map = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'lifts': jsonDecode(_prefs.getString(_keyLifts) ?? '[]'),
      'cycle': jsonDecode(_prefs.getString(_keyCycle) ?? '{}'),
      'workoutSessions': jsonDecode(_prefs.getString(_keySessions) ?? '[]'),
      'recoveryLogs': jsonDecode(_prefs.getString(_keyRecoveryLogs) ?? '[]'),
      'accessoryLogs': jsonDecode(_prefs.getString(_keyAccessoryLogs) ?? '[]'),
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
}
