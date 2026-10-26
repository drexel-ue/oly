import 'package:flutter/foundation.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/services/storage_service.dart';

class ProgramProvider extends ChangeNotifier {
  new(this._storage) {
    _cycle = _storage.loadProgramCycle();
    if (_cycle.activeTrack == TrainingTrack.mobility ||
        _cycle.activeTrack == TrainingTrack.bodybuilding ||
        _cycle.activeTrack == TrainingTrack.atgStandards) {
      final int todayWeekday = DateTime.now().weekday;
      _cycle.currentDay = todayWeekday.clamp(1, 7);
    } else if (_cycle.activeTrack == TrainingTrack.emomEight) {
      final String todayStr = DateTime.now().toIso8601String().substring(0, 10);
      if (_cycle.isEmomRestDay &&
          _cycle.emomRestDayDate != null &&
          _cycle.emomRestDayDate != todayStr) {
        _cycle.isEmomRestDay = false;
        _cycle.emomRestDayDate = null;
      }
      _cycle.currentDay = _cycle.currentDay.clamp(1, 8);
    }
    _days = _cycle.activeTrack == TrainingTrack.bodybuilding
        ? ProgramCycle.getBodybuildingProgram()
        : (_cycle.activeTrack == TrainingTrack.mobility
            ? ProgramCycle.getMobilityProgram()
            : (_cycle.activeTrack == TrainingTrack.atgStandards
                ? ProgramCycle.getAtgStandardsProgram()
                : (_cycle.activeTrack == TrainingTrack.emomEight
                    ? ProgramCycle.getEmomEightProgram()
                    : ProgramCycle.getBuiltInProgram(
                        week: _cycle.currentWeek,
                      ))));
    _sessions = _storage.loadWorkoutSessions();
    _activeDraft = _storage.loadActiveWorkoutDraft();
  }
  final StorageService _storage;

  late ProgramCycle _cycle;
  late List<DayTemplate> _days;
  late List<WorkoutSession> _sessions;
  ActiveWorkoutDraft? _activeDraft;

  ProgramCycle get cycle => _cycle;
  TrainingTrack get activeTrack => _cycle.activeTrack;
  bool get isMobilityTrack => _cycle.activeTrack == TrainingTrack.mobility;
  bool get isBodybuildingTrack =>
      _cycle.activeTrack == TrainingTrack.bodybuilding;
  bool get isAtgTrack => _cycle.activeTrack == TrainingTrack.atgStandards;
  bool get isEmomTrack => _cycle.activeTrack == TrainingTrack.emomEight;
  bool get isEmomRestDay => _cycle.isEmomRestDay;

  List<DayTemplate> get days {
    if (isBodybuildingTrack) {
      return ProgramCycle.getBodybuildingProgram();
    } else if (isMobilityTrack) {
      return ProgramCycle.getMobilityProgram();
    } else if (isAtgTrack) {
      return ProgramCycle.getAtgStandardsProgram();
    } else if (isEmomTrack) {
      return ProgramCycle.getEmomEightProgram();
    } else {
      return ProgramCycle.getBuiltInProgram(week: _cycle.currentWeek);
    }
  }
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);
  ActiveWorkoutDraft? get activeDraft => _activeDraft;
  bool get hasActiveDraft => _activeDraft != null;

  int get currentWeek => _cycle.currentWeek;
  int get currentDay => _cycle.currentDay;
  int get currentCycle => _cycle.currentCycle;
  bool get isRetestWeek =>
      !isMobilityTrack &&
      !isBodybuildingTrack &&
      !isAtgTrack &&
      !isEmomTrack &&
      _cycle.currentWeek == 5;

  double get totalVolumeKg => _sessions.fold(
    0,
    (sum, s) => sum + s.totalVolumeKg,
  );
  double get totalTonsMetric => totalVolumeKg / 1000.0;
  double get totalTonsUs => (totalVolumeKg * 2.20462) / 2000.0;
  int get totalCompletedSets =>
      _sessions.fold(0, (sum, s) => sum + s.totalSets);
  int get totalCompletedReps =>
      _sessions.fold(0, (sum, s) => sum + s.totalReps);

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
    final List<DayTemplate> currentDays = days;
    return currentDays.firstWhere(
      (d) => d.dayNumber == _cycle.currentDay,
      orElse: () => currentDays.first,
    );
  }

  void setTrainingTrack(TrainingTrack track) {
    _cycle.activeTrack = track;
    if (track == TrainingTrack.mobility ||
        track == TrainingTrack.bodybuilding ||
        track == TrainingTrack.atgStandards) {
      final int todayWeekday = DateTime.now().weekday;
      _cycle.currentDay = todayWeekday.clamp(1, 7);
    } else if (track == TrainingTrack.emomEight) {
      _cycle.currentDay = _cycle.currentDay.clamp(1, 8);
    } else {
      _cycle.currentDay = 1;
    }
    _days = days;
    _storage.saveProgramCycle(_cycle);
    notifyListeners();
  }

  void toggleEmomRestDay({bool? forceState}) {
    final bool newState = forceState ?? !_cycle.isEmomRestDay;
    _cycle.isEmomRestDay = newState;
    if (newState) {
      _cycle.emomRestDayDate =
          DateTime.now().toIso8601String().substring(0, 10);
    } else {
      _cycle.emomRestDayDate = null;
    }
    _storage.saveProgramCycle(_cycle);
    notifyListeners();
  }

  void selectDay(int dayNumber) {
    final int maxDays = days.length;
    if (dayNumber >= 1 && dayNumber <= maxDays) {
      _cycle.currentDay = dayNumber;
      _storage.saveProgramCycle(_cycle);
      notifyListeners();
    }
  }

  void selectWeek(int weekNumber) {
    if (weekNumber >= 1 && weekNumber <= 5) {
      _cycle.currentWeek = weekNumber;
      _days = days;
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
    _days = days;
    await _storage.saveProgramCycle(_cycle);
    notifyListeners();
  }

  Future<void> startNewCycle() async {
    _cycle.currentCycle++;
    _cycle.currentWeek = 1;
    _cycle.currentDay = 1;
    _days = days;
    await _storage.saveProgramCycle(_cycle);
    notifyListeners();
  }

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    _sessions.insert(0, session);
    if (!_cycle.completedSessionIds.contains(session.id)) {
      _cycle.completedSessionIds.add(session.id);
    }

    // Auto advance day & week after logging a live workout
    if (isEmomTrack) {
      if (_cycle.currentDay < 8) {
        _cycle.currentDay++;
      } else {
        _cycle.currentDay = 1;
        _cycle.currentCycle++;
      }
      _cycle.isEmomRestDay = false;
      _cycle.emomRestDayDate = null;
    } else if (_cycle.currentDay < _days.length) {
      _cycle.currentDay++;
    } else {
      // Completed Day -> Roll over to Week + 1, Day 1
      _cycle.currentDay = 1;
      if (_cycle.currentWeek < 5) {
        _cycle.currentWeek++;
      } else {
        // Completed Week 5 Retest -> Advance to Cycle + 1, Week 1
        _cycle.currentCycle++;
        _cycle.currentWeek = 1;
      }
    }

    _days = days;
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
    _days = days;
    _sessions = _storage.loadWorkoutSessions();
    _activeDraft = _storage.loadActiveWorkoutDraft();
    notifyListeners();
  }
}
