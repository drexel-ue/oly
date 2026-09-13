import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oly/models/c25k_model.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/storage_service.dart';

class C25kProvider extends ChangeNotifier {
  new(this._storageService, {NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService() {
    _loadFromStorage();
  }

  final StorageService _storageService;
  final NotificationService _notificationService;

  List<C25kSessionLog> _sessionLogs = <C25kSessionLog>[];
  int _currentWeek = 1;
  int _currentDay = 1;

  // Active Run Timer Engine
  Timer? _ticker;
  bool _isRunActive = false;
  bool _isPaused = false;
  C25kWorkout? _activeWorkout;
  int _currentStepIndex = 0;
  int _currentStepRemainingSeconds = 0;
  int _totalElapsedSeconds = 0;
  int _accumulatedJogSeconds = 0;
  int _accumulatedWalkSeconds = 0;

  // Getters
  List<C25kSessionLog> get sessionLogs =>
      List<C25kSessionLog>.unmodifiable(_sessionLogs);

  int get currentWeek => _currentWeek;
  int get currentDay => _currentDay;

  bool get isRunActive => _isRunActive;
  bool get isPaused => _isPaused;
  C25kWorkout? get activeWorkout => _activeWorkout;
  int get currentStepIndex => _currentStepIndex;
  int get currentStepRemainingSeconds => _currentStepRemainingSeconds;
  int get totalElapsedSeconds => _totalElapsedSeconds;
  int get accumulatedJogSeconds => _accumulatedJogSeconds;
  int get accumulatedWalkSeconds => _accumulatedWalkSeconds;

  C25kWorkout get todayWorkout =>
      C25kCurriculum.getWorkout(_currentWeek, _currentDay);

  C25kIntervalStep? get currentStep {
    if (_activeWorkout == null ||
        _currentStepIndex >= _activeWorkout!.steps.length) {
      return null;
    }
    return _activeWorkout!.steps[_currentStepIndex];
  }

  double get currentStepProgress {
    if (currentStep == null || currentStep!.durationSeconds <= 0) return 0;
    return 1.0 -
        (_currentStepRemainingSeconds / currentStep!.durationSeconds)
            .clamp(0.0, 1.0);
  }

  double get overallWorkoutProgress {
    if (_activeWorkout == null || _activeWorkout!.totalDurationSeconds <= 0) {
      return 0;
    }
    return (_totalElapsedSeconds / _activeWorkout!.totalDurationSeconds)
        .clamp(0.0, 1.0);
  }

  int get totalCompletedSessions =>
      _sessionLogs.where((l) => l.isCompleted).length;

  void _loadFromStorage() {
    _sessionLogs = _storageService.loadC25kSessionLogs();
    _sessionLogs.sort((a, b) => b.date.compareTo(a.date));

    final Map<String, int> progress = _storageService.loadC25kProgress();
    _currentWeek = progress['week'] ?? 1;
    _currentDay = progress['day'] ?? 1;
    notifyListeners();
  }

  Future<void> setProgress(int week, int day) async {
    _currentWeek = week.clamp(1, 9);
    _currentDay = day.clamp(1, 3);
    await _storageService.saveC25kProgress(_currentWeek, _currentDay);
    notifyListeners();
  }

  Future<void> advanceProgress() async {
    if (_currentDay < 3) {
      _currentDay++;
    } else if (_currentWeek < 9) {
      _currentWeek++;
      _currentDay = 1;
    }
    await _storageService.saveC25kProgress(_currentWeek, _currentDay);
    notifyListeners();
  }

  // --- RUN INTERVAL ENGINE ---

  void startRunSession({int? week, int? day}) {
    final int targetWeek = week ?? _currentWeek;
    final int targetDay = day ?? _currentDay;

    _activeWorkout = C25kCurriculum.getWorkout(targetWeek, targetDay);
    _currentStepIndex = 0;
    _totalElapsedSeconds = 0;
    _accumulatedJogSeconds = 0;
    _accumulatedWalkSeconds = 0;
    _isRunActive = true;
    _isPaused = false;

    if (_activeWorkout!.steps.isNotEmpty) {
      _currentStepRemainingSeconds =
          _activeWorkout!.steps.first.durationSeconds;
    }

    _ticker?.cancel();
    HapticFeedback.mediumImpact();
    _notificationService.playTimerBeepSound(); // Initial alert

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _tick();
      }
    });
    notifyListeners();
  }

  void pauseRunSession() {
    _isPaused = true;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void resumeRunSession() {
    _isPaused = false;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void skipToNextStep() {
    if (_activeWorkout == null) return;
    HapticFeedback.heavyImpact();
    _transitionToNextStep();
  }

  void _tick() {
    _totalElapsedSeconds++;
    final C25kIntervalStep? step = currentStep;
    if (step != null) {
      if (step.type == C25kStepType.jog) {
        _accumulatedJogSeconds++;
      } else {
        _accumulatedWalkSeconds++;
      }
    }

    if (_currentStepRemainingSeconds > 1) {
      _currentStepRemainingSeconds--;
      // 3-second countdown audio haptic warning
      if (_currentStepRemainingSeconds <= 3) {
        HapticFeedback.lightImpact();
      }
    } else {
      _transitionToNextStep();
    }
    notifyListeners();
  }

  void _transitionToNextStep() {
    if (_activeWorkout == null) return;
    _currentStepIndex++;

    if (_currentStepIndex < _activeWorkout!.steps.length) {
      _currentStepRemainingSeconds =
          _activeWorkout!.steps[_currentStepIndex].durationSeconds;
      HapticFeedback.heavyImpact();
      _notificationService.playTimerBeepSound();
    } else {
      // Workout Completed!
      finishRunSession();
    }
    notifyListeners();
  }

  Future<C25kSessionLog> finishRunSession({
    bool isCompleted = true,
    double bodyWeightKg = 75.0,
  }) async {
    _ticker?.cancel();
    _ticker = null;
    _isRunActive = false;
    _isPaused = false;

    final C25kWorkout workout = _activeWorkout ?? todayWorkout;
    final double estimatedDistance = workout.estimateDistanceKm();

    // Compendium of Physical Activities Algorithm B Net Calories:
    // Net MET = Gross MET - 1.0 (Resting MET)
    // Jogging net MET = 8.0 - 1.0 = 7.0
    // Walking net MET = 3.5 - 1.0 = 2.5
    final double jogHours = _accumulatedJogSeconds / 3600.0;
    final double walkHours = _accumulatedWalkSeconds / 3600.0;
    final double netCalories =
        ((7.0 * bodyWeightKg * jogHours) + (2.5 * bodyWeightKg * walkHours))
            .clamp(0.0, 2000.0);

    final C25kSessionLog log = C25kSessionLog.create(
      week: workout.week,
      day: workout.day,
      completedJogSeconds: _accumulatedJogSeconds,
      completedWalkSeconds: _accumulatedWalkSeconds,
      estimatedDistanceKm: estimatedDistance,
      netCaloriesBurned: netCalories,
      isCompleted: isCompleted,
    );

    _sessionLogs.insert(0, log);
    await _storageService.saveC25kSessionLogs(_sessionLogs);

    if (isCompleted &&
        workout.week == _currentWeek &&
        workout.day == _currentDay) {
      await advanceProgress();
    }

    unawaited(HapticFeedback.vibrate());
    unawaited(_notificationService.playTimerBeepSound());
    notifyListeners();
    return log;
  }

  void cancelRunSession() {
    _ticker?.cancel();
    _ticker = null;
    _isRunActive = false;
    _isPaused = false;
    _activeWorkout = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}
