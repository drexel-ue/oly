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

  // --- SETTINGS STORAGE ---
  bool loadIsLbs() => _prefs.getBool(_keyUnit) ?? false;
  Future<void> saveIsLbs(bool isLbs) async => await _prefs.setBool(_keyUnit, isLbs);

  double loadBarWeight() => _prefs.getDouble(_keyBarWeight) ?? 20.0;
  Future<void> saveBarWeight(double weight) async => await _prefs.setDouble(_keyBarWeight, weight);

  double loadCollarWeight() => _prefs.getDouble(_keyCollarWeight) ?? 2.5;
  Future<void> saveCollarWeight(double weight) async => await _prefs.setDouble(_keyCollarWeight, weight);
}
