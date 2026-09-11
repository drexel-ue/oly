import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/recovery_engine_service.dart';

enum SessionType { workout, mobility, breathwork }

/// Manages global active session state, including active exercise, set details,
/// and the real-time rest timer that persists across all app navigation tabs.
class ActiveSessionProvider extends ChangeNotifier {
  ActiveSessionProvider({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  bool _isActive = false;
  bool _isMinimized = false;
  bool _isPreviewMode = false;
  SessionType _sessionType = SessionType.workout;
  String _sessionTitle = '';
  String _currentExercise = '';
  String _currentSetInfo = '';
  int? _dayNumber;
  int? _weekNumber;

  // Mobility session state
  GeneratedRecoveryRoutine? _activeMobilityRoutine;
  int _mobilityExerciseIndex = 0;
  Set<String> _completedMobilityIds = <String>{};

  // Rest Timer State
  Timer? _timer;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 120;
  bool _isRestTimerRunning = false;
  DateTime? _restTargetEndTime;

  // Getters
  bool get isActive => _isActive;
  bool get isMinimized => _isMinimized;
  bool get isPreviewMode => _isPreviewMode;
  SessionType get sessionType => _sessionType;
  String get sessionTitle => _sessionTitle;
  String get currentExercise => _currentExercise;
  String get currentSetInfo => _currentSetInfo;
  int? get dayNumber => _dayNumber;
  int? get weekNumber => _weekNumber;

  GeneratedRecoveryRoutine? get activeMobilityRoutine => _activeMobilityRoutine;
  int get mobilityExerciseIndex => _mobilityExerciseIndex;
  Set<String> get completedMobilityIds =>
      Set<String>.unmodifiable(_completedMobilityIds);

  int get restSecondsRemaining => _restSecondsRemaining;
  int get restTotalSeconds => _restTotalSeconds;
  bool get isRestTimerRunning => _isRestTimerRunning;
  DateTime? get restTargetEndTime => _restTargetEndTime;

  double get timerProgress {
    if (_restTotalSeconds <= 0) {
      return 0.0;
    }
    return (_restSecondsRemaining / _restTotalSeconds).clamp(0.0, 1.0);
  }

  String get formattedRestTime {
    final int mins = _restSecondsRemaining ~/ 60;
    final int secs = _restSecondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Start or attach to an active session
  void startSession({
    required String sessionTitle,
    SessionType sessionType = SessionType.workout,
    bool isPreviewMode = false,
    String currentExercise = '',
    String currentSetInfo = '',
    int? dayNumber,
    int? weekNumber,
    bool isMinimized = false,
    GeneratedRecoveryRoutine? mobilityRoutine,
    int mobilityExerciseIndex = 0,
    Set<String>? completedMobilityIds,
  }) {
    _isActive = true;
    _isMinimized = isMinimized;
    _isPreviewMode = isPreviewMode;
    _sessionType = sessionType;
    _sessionTitle = sessionTitle;
    _currentExercise = currentExercise;
    _currentSetInfo = currentSetInfo;
    _dayNumber = dayNumber;
    _weekNumber = weekNumber;

    if (mobilityRoutine != null) {
      _activeMobilityRoutine = mobilityRoutine;
      _mobilityExerciseIndex = mobilityExerciseIndex;
      _completedMobilityIds = completedMobilityIds != null
          ? Set<String>.from(completedMobilityIds)
          : <String>{};
    }
    notifyListeners();
  }

  /// Update the active exercise and set descriptor
  void updateExercise({
    required String currentExercise,
    required String currentSetInfo,
  }) {
    _currentExercise = currentExercise;
    _currentSetInfo = currentSetInfo;
    notifyListeners();
  }

  /// Update mobility routine progression
  void updateMobilityProgress({
    required int exerciseIndex,
    required String exerciseName,
    required Set<String> completedIds,
    int totalExercises = 0,
  }) {
    _mobilityExerciseIndex = exerciseIndex;
    _currentExercise = exerciseName;
    _completedMobilityIds = Set<String>.from(completedIds);
    if (totalExercises > 0) {
      _currentSetInfo = 'Ex ${exerciseIndex + 1} of $totalExercises';
    }
    notifyListeners();
  }

  /// Set preview mode state explicitly
  void setPreviewMode(bool isPreview) {
    _isPreviewMode = isPreview;
    notifyListeners();
  }

  /// Minimize the session into the floating mini-dock
  void minimizeSession() {
    _isMinimized = true;
    notifyListeners();
  }

  /// Maximize the session from the mini-dock
  void maximizeSession() {
    _isMinimized = false;
    notifyListeners();
  }

  /// Terminate the active session and clean up timers
  void endSession() {
    _timer?.cancel();
    _timer = null;
    _notificationService.cancelTimerNotification();
    _isActive = false;
    _isMinimized = false;
    _isPreviewMode = false;
    _sessionType = SessionType.workout;
    _sessionTitle = '';
    _currentExercise = '';
    _currentSetInfo = '';
    _dayNumber = null;
    _weekNumber = null;
    _activeMobilityRoutine = null;
    _mobilityExerciseIndex = 0;
    _completedMobilityIds.clear();
    _isRestTimerRunning = false;
    _restSecondsRemaining = 0;
    _restTargetEndTime = null;
    notifyListeners();
  }

  /// Start a rest timer with the given duration in seconds
  void startRestTimer({
    required int seconds,
    String notificationTitle = '⏰ Rest Over!',
    String notificationBody = 'Time for your next set. Get back to the barbell!',
  }) {
    _timer?.cancel();
    _restTotalSeconds = seconds;
    _restSecondsRemaining = seconds;
    _isRestTimerRunning = true;
    _restTargetEndTime = DateTime.now().add(Duration(seconds: seconds));

    _notificationService.scheduleTimerNotification(
      secondsRemaining: seconds,
      title: notificationTitle,
      body: notificationBody,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_restTargetEndTime == null) {
        return;
      }
      final int remaining =
          _restTargetEndTime!.difference(DateTime.now()).inSeconds;

      if (remaining > 0) {
        _restSecondsRemaining = remaining;
        notifyListeners();
      } else {
        t.cancel();
        _restSecondsRemaining = 0;
        _isRestTimerRunning = false;
        _restTargetEndTime = null;
        _notificationService.cancelTimerNotification();
        _notificationService.triggerIntenseVibration();
        _notificationService.playTimerBeepSound();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Pause the currently running rest timer
  void pauseRestTimer() {
    if (!_isRestTimerRunning) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _notificationService.cancelTimerNotification();
    _isRestTimerRunning = false;
    _restTargetEndTime = null;
    notifyListeners();
  }

  /// Resume a paused rest timer
  void resumeRestTimer({
    String notificationTitle = '⏰ Rest Over!',
    String notificationBody = 'Time for your next set. Get back to the barbell!',
  }) {
    if (_isRestTimerRunning || _restSecondsRemaining <= 0) {
      return;
    }
    startRestTimer(
      seconds: _restSecondsRemaining,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
    );
  }

  /// Reset the rest timer to its initial duration
  void resetRestTimer() {
    _timer?.cancel();
    _timer = null;
    _notificationService.cancelTimerNotification();
    _isRestTimerRunning = false;
    _restSecondsRemaining = _restTotalSeconds;
    _restTargetEndTime = null;
    notifyListeners();
  }

  /// Increment or decrement time on the rest timer
  void adjustRestTimer(int deltaSeconds) {
    final int newRemaining = _restSecondsRemaining + deltaSeconds;
    _restSecondsRemaining = newRemaining < 0 ? 0 : newRemaining;
    if (_restSecondsRemaining > _restTotalSeconds) {
      _restTotalSeconds = _restSecondsRemaining;
    }

    if (_isRestTimerRunning) {
      startRestTimer(seconds: _restSecondsRemaining);
    } else {
      notifyListeners();
    }
  }

  /// Handle app lifecycle changes (sync time if app was in background)
  void syncFromBackground() {
    if (_isRestTimerRunning && _restTargetEndTime != null) {
      final int diff = _restTargetEndTime!.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        _restSecondsRemaining = diff;
      } else {
        _timer?.cancel();
        _timer = null;
        _restSecondsRemaining = 0;
        _isRestTimerRunning = false;
        _restTargetEndTime = null;
        _notificationService.triggerIntenseVibration();
        _notificationService.playTimerBeepSound();
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
