import 'package:flutter/foundation.dart';
import '../models/program_model.dart';
import '../models/workout_session.dart';
import '../services/storage_service.dart';

class ProgramProvider extends ChangeNotifier {
  final StorageService _storage;

  late ProgramCycle _cycle;
  late List<DayTemplate> _days;
  late List<WorkoutSession> _sessions;

  ProgramProvider(this._storage) {
    _cycle = _storage.loadProgramCycle();
    _days = ProgramCycle.getBuiltInProgram();
    _sessions = _storage.loadWorkoutSessions();
  }

  ProgramCycle get cycle => _cycle;
  List<DayTemplate> get days => List.unmodifiable(_days);
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  int get currentWeek => _cycle.currentWeek;
  int get currentDay => _cycle.currentDay;
  int get currentCycle => _cycle.currentCycle;
  bool get isRetestWeek => _cycle.currentWeek == 5;

  double get totalVolumeKg => _sessions.fold(0.0, (sum, s) => sum + s.totalVolumeKg);
  double get totalTonsMetric => totalVolumeKg / 1000.0;
  double get totalTonsUs => (totalVolumeKg * 2.20462) / 2000.0;
  int get totalCompletedSets => _sessions.fold(0, (sum, s) => sum + s.totalSets);
  int get totalCompletedReps => _sessions.fold(0, (sum, s) => sum + s.totalReps);

  String formatTotalTons({required bool isLbs}) {
    if (isLbs) {
      final tons = totalTonsUs;
      if (tons < 1.0) {
        final lbs = totalVolumeKg * 2.20462;
        return '${lbs.toStringAsFixed(0)} lbs';
      }
      return '${tons.toStringAsFixed(2)} Tons';
    } else {
      final tons = totalTonsMetric;
      if (tons < 1.0) {
        return '${totalVolumeKg.toStringAsFixed(0)} kg';
      }
      return '${tons.toStringAsFixed(2)} Tonnes';
    }
  }

  DayTemplate get currentDayTemplate {
    return _days.firstWhere(
      (d) => d.dayNumber == _cycle.currentDay,
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
    notifyListeners();
  }
}
