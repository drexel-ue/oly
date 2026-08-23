import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lift_model.dart';
import '../models/program_model.dart';
import '../models/workout_session.dart';

class StorageService {
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

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- LIFTS STORAGE ---
  List<LiftModel> loadLifts() {
    final jsonStr = _prefs.getString(_keyLifts);
    if (jsonStr == null || jsonStr.isEmpty) {
      return LiftModel.defaultLifts();
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => LiftModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return LiftModel.defaultLifts();
    }
  }

  Future<void> saveLifts(List<LiftModel> lifts) async {
    final jsonStr = jsonEncode(lifts.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyLifts, jsonStr);
  }

  // --- PROGRAM CYCLE STORAGE ---
  ProgramCycle loadProgramCycle() {
    final jsonStr = _prefs.getString(_keyCycle);
    if (jsonStr == null || jsonStr.isEmpty) {
      return ProgramCycle();
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ProgramCycle.fromJson(map);
    } catch (_) {
      return ProgramCycle();
    }
  }

  Future<void> saveProgramCycle(ProgramCycle cycle) async {
    final jsonStr = jsonEncode(cycle.toJson());
    await _prefs.setString(_keyCycle, jsonStr);
  }

  // --- WORKOUT SESSIONS STORAGE ---
  List<WorkoutSession> loadWorkoutSessions() {
    final jsonStr = _prefs.getString(_keySessions);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWorkoutSessions(List<WorkoutSession> sessions) async {
    final jsonStr = jsonEncode(sessions.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySessions, jsonStr);
  }

  // --- ACTIVE WORKOUT DRAFT STORAGE ---
  ActiveWorkoutDraft? loadActiveWorkoutDraft() {
    final jsonStr = _prefs.getString(_keyActiveDraft);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ActiveWorkoutDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveWorkoutDraft(ActiveWorkoutDraft draft) async {
    final jsonStr = jsonEncode(draft.toJson());
    await _prefs.setString(_keyActiveDraft, jsonStr);
  }

  Future<void> clearActiveWorkoutDraft() async {
    await _prefs.remove(_keyActiveDraft);
  }

  // --- SETTINGS STORAGE ---
  bool loadIsLbs() => _prefs.getBool(_keyUnit) ?? false;
  Future<void> saveIsLbs(bool isLbs) async => await _prefs.setBool(_keyUnit, isLbs);

  double loadBarWeight() => _prefs.getDouble(_keyBarWeight) ?? 20.0;
  Future<void> saveBarWeight(double weight) async => await _prefs.setDouble(_keyBarWeight, weight);

  double loadCollarWeight() => _prefs.getDouble(_keyCollarWeight) ?? 2.5;
  Future<void> saveCollarWeight(double weight) async => await _prefs.setDouble(_keyCollarWeight, weight);

  // --- RECOVERY LOGS STORAGE ---
  List<Map<String, dynamic>> loadRawRecoveryLogs() {
    final jsonStr = _prefs.getString(_keyRecoveryLogs);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRawRecoveryLogs(List<Map<String, dynamic>> logs) async {
    final jsonStr = jsonEncode(logs);
    await _prefs.setString(_keyRecoveryLogs, jsonStr);
  }

  bool loadSoundAlerts() => _prefs.getBool(_keySoundAlerts) ?? true;
  Future<void> saveSoundAlerts(bool value) async => await _prefs.setBool(_keySoundAlerts, value);

  bool loadHapticsEnabled() => _prefs.getBool(_keyHapticsEnabled) ?? true;
  Future<void> saveHapticsEnabled(bool value) async => await _prefs.setBool(_keyHapticsEnabled, value);

  // --- EXPORT & IMPORT UTILITIES ---
  String exportFullAppDataJson() {
    final map = {
      'exportedAt': DateTime.now().toIso8601String(),
      'lifts': jsonDecode(_prefs.getString(_keyLifts) ?? '[]'),
      'cycle': jsonDecode(_prefs.getString(_keyCycle) ?? '{}'),
      'workoutSessions': jsonDecode(_prefs.getString(_keySessions) ?? '[]'),
      'recoveryLogs': jsonDecode(_prefs.getString(_keyRecoveryLogs) ?? '[]'),
      'settings': {
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
    final lifts = loadLifts();
    final buffer = StringBuffer();
    buffer.writeln('Lift Name,Category,1RM (KG),1RM (LBS),Target Ratio,Anchor Lift ID');
    for (var lift in lifts) {
      final lbs = (lift.currentMax * 2.20462).toStringAsFixed(1);
      buffer.writeln('${lift.name},${lift.category.name},${lift.currentMax.toStringAsFixed(1)},$lbs,${lift.targetRatio},${lift.anchorLiftId ?? ''}');
    }
    return buffer.toString();
  }

  Future<bool> importAppDataJson(String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (map.containsKey('lifts')) {
        await _prefs.setString(_keyLifts, jsonEncode(map['lifts']));
      }
      if (map.containsKey('cycle')) {
        await _prefs.setString(_keyCycle, jsonEncode(map['cycle']));
      }
      if (map.containsKey('workoutSessions')) {
        await _prefs.setString(_keySessions, jsonEncode(map['workoutSessions']));
      }
      if (map.containsKey('recoveryLogs')) {
        await _prefs.setString(_keyRecoveryLogs, jsonEncode(map['recoveryLogs']));
      }
      if (map.containsKey('settings')) {
        final s = map['settings'] as Map<String, dynamic>;
        if (s.containsKey('isLbs')) await saveIsLbs(s['isLbs'] as bool);
        if (s.containsKey('barWeight')) await saveBarWeight((s['barWeight'] as num).toDouble());
        if (s.containsKey('collarWeight')) await saveCollarWeight((s['collarWeight'] as num).toDouble());
        if (s.containsKey('soundAlerts')) await saveSoundAlerts(s['soundAlerts'] as bool);
        if (s.containsKey('hapticsEnabled')) await saveHapticsEnabled(s['hapticsEnabled'] as bool);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> importPrsCsv(String csvStr) async {
    try {
      final lines = csvStr
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) return false;

      final lifts = loadLifts();
      bool updated = false;

      final startIndex =
          lines.first.toLowerCase().contains('lift name') ? 1 : 0;

      for (int i = startIndex; i < lines.length; i++) {
        final parts = lines[i].split(',').map((p) => p.trim()).toList();
        if (parts.length < 3) continue;

        final liftName = parts[0];
        final maxKg = double.tryParse(parts[2]);

        if (maxKg != null && maxKg > 0) {
          final liftIndex = lifts.indexWhere(
            (l) => l.name.toLowerCase() == liftName.toLowerCase(),
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
}
