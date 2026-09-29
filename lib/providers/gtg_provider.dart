import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oly/models/gtg_model.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/storage_service.dart';

class GtgProvider extends ChangeNotifier {
  new(
    this._storageService, {
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService() {
    _loadFromStorage();
  }

  final StorageService _storageService;
  final NotificationService _notificationService;

  late GtgConfig _config;
  List<GtgSetLog> _logs = <GtgSetLog>[];

  // Live Active Hang Timer State
  Timer? _liveHangTimer;
  Timer? _prepCountdownTimer;
  bool _isHangTimerRunning = false;
  bool _isHangPrepCountdown = false;
  int _hangPrepSecondsRemaining = 0;
  int _hangSecondsRemaining = 30;
  int _hangTargetSeconds = 30;

  // Getters
  GtgConfig get config => _config;
  List<GtgSetLog> get logs => List<GtgSetLog>.unmodifiable(_logs);
  bool get isHangTimerRunning => _isHangTimerRunning;
  bool get isHangPrepCountdown => _isHangPrepCountdown;
  bool get isHangTimerActive => _isHangTimerRunning || _isHangPrepCountdown;
  int get hangPrepSecondsRemaining => _hangPrepSecondsRemaining;
  int get hangSecondsRemaining => _hangSecondsRemaining;
  int get hangTargetSeconds => _hangTargetSeconds;
  int get prepDelaySeconds => _config.prepDelaySeconds;

  Future<void> setPrepDelaySeconds(int seconds) async {
    final GtgConfig updated = _config.copyWith(prepDelaySeconds: seconds);
    await updateConfig(updated);
  }

  void _loadFromStorage() {
    _config = _storageService.loadGtgConfig();
    _logs = _storageService.loadGtgLogs();
    _hangSecondsRemaining = _config.targetHangSeconds;
    _hangTargetSeconds = _config.targetHangSeconds;
    notifyListeners();
  }

  // --- TODAY'S METRICS ---

  List<GtgSetLog> get todayLogs {
    final DateTime now = DateTime.now();
    return _logs.where((log) {
      return log.timestamp.year == now.year &&
          log.timestamp.month == now.month &&
          log.timestamp.day == now.day;
    }).toList();
  }

  int get todayPullUpReps {
    return todayLogs
        .where((l) => l.type == GtgExerciseType.pullUp)
        .fold(0, (acc, l) => acc + l.reps);
  }

  int get todayHangSeconds {
    return todayLogs
        .where((l) => l.type == GtgExerciseType.activeHang)
        .fold(0, (acc, l) => acc + l.durationSeconds);
  }

  int get todaySetsCount => todayLogs.length;

  double get pullUpProgressRatio {
    if (_config.dailyPullUpGoal <= 0) return 0;
    return (todayPullUpReps / _config.dailyPullUpGoal).clamp(0, 1.0);
  }

  double get hangProgressRatio {
    if (_config.dailyHangSecondsGoal <= 0) return 0;
    return (todayHangSeconds / _config.dailyHangSecondsGoal).clamp(0, 1.0);
  }

  int get currentStreakDays {
    if (_logs.isEmpty) return 0;
    final Set<String> activeDates = _logs.map((l) {
      return '${l.timestamp.year}-${l.timestamp.month.toString().padLeft(2, '0')}-${l.timestamp.day.toString().padLeft(2, '0')}';
    }).toSet();

    final DateTime now = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    // If no sets logged today yet, check if yesterday had sets to keep streak alive
    final String todayKey =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    if (!activeDates.contains(todayKey)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final String key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (activeDates.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // --- LOGGING ACTIONS ---

  Future<GtgSetLog> logPullUpSet({
    int? reps,
    String? notes,
  }) async {
    final int finalReps = reps ?? _config.targetPullUpReps;
    final GtgSetLog newLog = GtgSetLog.create(
      type: GtgExerciseType.pullUp,
      reps: finalReps,
      notes: notes,
    );

    _logs.insert(0, newLog);
    await _storageService.saveGtgLogs(_logs);
    await HapticFeedback.mediumImpact();
    notifyListeners();
    return newLog;
  }

  Future<GtgSetLog> logActiveHangSet({
    int? seconds,
    bool microElbowBend = true,
    bool scapulaRetracted = true,
    String? notes,
  }) async {
    final int finalSeconds = seconds ?? _config.targetHangSeconds;
    final GtgSetLog newLog = GtgSetLog.create(
      type: GtgExerciseType.activeHang,
      durationSeconds: finalSeconds,
      microElbowBendEngaged: microElbowBend,
      scapulaRetracted: scapulaRetracted,
      notes: notes,
    );

    _logs.insert(0, newLog);
    await _storageService.saveGtgLogs(_logs);
    await HapticFeedback.mediumImpact();
    notifyListeners();
    return newLog;
  }

  Future<void> deleteSet(String id) async {
    _logs.removeWhere((l) => l.id == id);
    await _storageService.saveGtgLogs(_logs);
    notifyListeners();
  }

  // --- CONFIG & REMINDERS ---

  Future<void> updateConfig(GtgConfig newConfig) async {
    _config = newConfig;
    await _storageService.saveGtgConfig(_config);

    if (_config.remindersEnabled) {
      await _notificationService.scheduleGtgReminders(
        intervalMinutes: _config.intervalMinutes,
        startHour: _config.startHour,
        startMinute: _config.startMinute,
        endHour: _config.endHour,
        endMinute: _config.endMinute,
        targetPullUpReps: _config.targetPullUpReps,
        targetHangSeconds: _config.targetHangSeconds,
        microElbowBend: _config.microElbowBendDefault,
      );
    } else {
      await _notificationService.cancelGtgReminders();
    }

    notifyListeners();
  }

  Future<void> toggleReminders(bool enabled) async {
    final GtgConfig updated = _config.copyWith(remindersEnabled: enabled);
    await updateConfig(updated);
  }

  Future<void> setPullUpMax(int max) async {
    final int newSubmax = (max * 0.45).clamp(1, 30).round();
    final GtgConfig updated = _config.copyWith(
      pullUpMax: max,
      targetPullUpReps: newSubmax,
    );
    await updateConfig(updated);
  }

  // --- LIVE ACTIVE SCAPULAR HANG TIMER ---

  void startActiveHangTimer({int? seconds, int? prepSeconds}) {
    _prepCountdownTimer?.cancel();
    _prepCountdownTimer = null;
    _liveHangTimer?.cancel();
    _liveHangTimer = null;

    if (seconds != null) {
      _hangTargetSeconds = seconds;
      _hangSecondsRemaining = seconds;
    } else if (_hangSecondsRemaining <= 0) {
      _hangSecondsRemaining =
          _hangTargetSeconds > 0 ? _hangTargetSeconds : _config.targetHangSeconds;
    }

    final int delay = prepSeconds ?? _config.prepDelaySeconds;
    if (delay > 0) {
      _isHangPrepCountdown = true;
      _isHangTimerRunning = false;
      _hangPrepSecondsRemaining = delay;
      HapticFeedback.mediumImpact();
      notifyListeners();

      _prepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_hangPrepSecondsRemaining > 1) {
          _hangPrepSecondsRemaining--;
          HapticFeedback.selectionClick();
          notifyListeners();
        } else {
          timer.cancel();
          _prepCountdownTimer = null;
          _isHangPrepCountdown = false;
          _startActualHangCountdown();
        }
      });
    } else {
      _isHangPrepCountdown = false;
      _startActualHangCountdown();
    }
  }

  void skipHangPrep() {
    if (_isHangPrepCountdown) {
      _prepCountdownTimer?.cancel();
      _prepCountdownTimer = null;
      _isHangPrepCountdown = false;
      _startActualHangCountdown();
    }
  }

  void _startActualHangCountdown() {
    _isHangTimerRunning = true;
    HapticFeedback.heavyImpact();
    _notificationService.playChronoPulse();
    notifyListeners();

    _liveHangTimer?.cancel();
    _liveHangTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hangSecondsRemaining > 1) {
        _hangSecondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        _liveHangTimer = null;
        _hangSecondsRemaining = 0;
        _isHangTimerRunning = false;

        // Auto-log completed active scapular hang set
        logActiveHangSet(
          seconds: _hangTargetSeconds,
          microElbowBend: _config.microElbowBendDefault,
          scapulaRetracted: _config.activeScapulaDefault,
        );

        _notificationService.triggerIntenseVibration();
        _notificationService.playPlatformChime();
        notifyListeners();
      }
    });
  }

  void stopActiveHangTimer({bool logPartial = false}) {
    _prepCountdownTimer?.cancel();
    _prepCountdownTimer = null;
    _isHangPrepCountdown = false;

    _liveHangTimer?.cancel();
    _liveHangTimer = null;
    _isHangTimerRunning = false;

    final int completedSeconds = _hangTargetSeconds - _hangSecondsRemaining;
    if (logPartial && completedSeconds >= 5) {
      logActiveHangSet(
        seconds: completedSeconds,
        microElbowBend: _config.microElbowBendDefault,
        scapulaRetracted: _config.activeScapulaDefault,
      );
    }

    _hangSecondsRemaining = _hangTargetSeconds;
    notifyListeners();
  }

  void pauseActiveHangTimer() {
    _prepCountdownTimer?.cancel();
    _prepCountdownTimer = null;
    _isHangPrepCountdown = false;

    _liveHangTimer?.cancel();
    _liveHangTimer = null;
    _isHangTimerRunning = false;
    notifyListeners();
  }

  void setHangTarget(int seconds) {
    _hangTargetSeconds = seconds;
    _hangSecondsRemaining = seconds;
    notifyListeners();
  }

  void resetActiveHangTimer() {
    _prepCountdownTimer?.cancel();
    _prepCountdownTimer = null;
    _isHangPrepCountdown = false;

    _liveHangTimer?.cancel();
    _liveHangTimer = null;
    _isHangTimerRunning = false;
    _hangSecondsRemaining = _hangTargetSeconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _prepCountdownTimer?.cancel();
    _prepCountdownTimer = null;
    _liveHangTimer?.cancel();
    _liveHangTimer = null;
    super.dispose();
  }
}
