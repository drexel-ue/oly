import 'package:flutter/foundation.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/services/storage_service.dart';

class ProgramProvider extends ChangeNotifier {
  ProgramProvider(this._storage) {
    _cycle = _storage.loadProgramCycle();
    _days = ProgramCycle.getBuiltInProgram();
    _sessions = _storage.loadWorkoutSessions();
    _activeDraft = _storage.loadActiveWorkoutDraft();
  }
  final StorageService _storage;

  late ProgramCycle _cycle;
  late List<DayTemplate> _days;
  late List<WorkoutSession> _sessions;
  ActiveWorkoutDraft? _activeDraft;

  ProgramCycle get cycle => _cycle;
  List<DayTemplate> get days => List.unmodifiable(_days);
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);
  ActiveWorkoutDraft? get activeDraft => _activeDraft;
  bool get hasActiveDraft => _activeDraft != null;

  int get currentWeek => _cycle.currentWeek;
  int get currentDay => _cycle.currentDay;
  int get currentCycle => _cycle.currentCycle;
  bool get isRetestWeek => _cycle.currentWeek == 5;

  double get totalVolumeKg => _sessions.fold(
    0.0,
    (double sum, WorkoutSession s) => sum + s.totalVolumeKg,
  );
  double get totalTonsMetric => totalVolumeKg / 1000.0;
  double get totalTonsUs => (totalVolumeKg * 2.20462) / 2000.0;
  int get totalCompletedSets =>
      _sessions.fold(0, (int sum, WorkoutSession s) => sum + s.totalSets);
  int get totalCompletedReps =>
      _sessions.fold(0, (int sum, WorkoutSession s) => sum + s.totalReps);

  String formatTotalTons({required bool isLbs}) {
    if (isLbs) {
      final double tons = totalTonsUs;
      if (tons < 1.0) {
        final double lbs = totalVolumeKg * 2.20462;
        return '${lbs.toStringAsFixed(0)} lbs';
      }
      return '${tons.toStringAsFixed(2)} Tons';
    } else {
      final double tons = totalTonsMetric;
      if (tons < 1.0) {
        return '${totalVolumeKg.toStringAsFixed(0)} kg';
      }
      return '${tons.toStringAsFixed(2)} Tonnes';
    }
  }

  DayTemplate get currentDayTemplate {
    return _days.firstWhere(
      (DayTemplate d) => d.dayNumber == _cycle.currentDay,
      orElse: () => _days.first,
    );
  }

  void selectDay(int dayNumber) {
    if (dayNumber >= 1 && dayNumber <= _days.length) {
      _cycle.currentDay = dayNumber;
      _storage.saveProgramCycle(_cycle);
      notifyListeners();
    }
  }

  void selectWeek(int weekNumber) {
    if (weekNumber >= 1 && weekNumber <= 5) {
      _cycle.currentWeek = weekNumber;
      _storage.saveProgramCycle(_cycle);
      notifyListeners();
    }
  }

  Future<void> advanceWeek() async {
    if (_cycle.currentWeek < 5) {
      _cycle.currentWeek++;
    } else {
      // Completed 1RM Retest Week -> Start Cycle N+1, Week 1
      _cycle.currentCycle++;
      _cycle.currentWeek = 1;
    }
    _cycle.currentDay = 1;
    await _storage.saveProgramCycle(_cycle);
    notifyListeners();
  }

  Future<void> startNewCycle() async {
    _cycle.currentCycle++;
    _cycle.currentWeek = 1;
    _cycle.currentDay = 1;
    await _storage.saveProgramCycle(_cycle);
    notifyListeners();
  }

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    _sessions.insert(0, session);
    if (!_cycle.completedSessionIds.contains(session.id)) {
      _cycle.completedSessionIds.add(session.id);
    }

    // Auto advance day & week after logging a live workout
    if (_cycle.currentDay < _days.length) {
      _cycle.currentDay++;
    } else {
      // Completed Day 5 -> Roll over to Week + 1, Day 1
      _cycle.currentDay = 1;
      if (_cycle.currentWeek < 5) {
        _cycle.currentWeek++;
      } else {
        // Completed Week 5 Retest -> Advance to Cycle + 1, Week 1
        _cycle.currentCycle++;
        _cycle.currentWeek = 1;
      }
    }

    await _storage.saveWorkoutSessions(_sessions);
    await _storage.saveProgramCycle(_cycle);
    await clearActiveDraft();
    notifyListeners();
  }

  Future<void> saveActiveDraft(ActiveWorkoutDraft draft) async {
    _activeDraft = draft;
    await _storage.saveActiveWorkoutDraft(draft);
    notifyListeners();
  }

  Future<void> clearActiveDraft() async {
    _activeDraft = null;
    await _storage.clearActiveWorkoutDraft();
    notifyListeners();
  }

  Future<void> reload() async {
    _cycle = _storage.loadProgramCycle();
    _sessions = _storage.loadWorkoutSessions();
    _activeDraft = _storage.loadActiveWorkoutDraft();
    notifyListeners();
  }
}
