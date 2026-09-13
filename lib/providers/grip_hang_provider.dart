import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/storage_service.dart';

class GripHangProvider extends ChangeNotifier {
  new(this._storageService, {NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService() {
    _loadFromStorage();
  }

  final StorageService _storageService;
  final NotificationService _notificationService;

  List<DynamometerEntry> _dynamometerEntries = <DynamometerEntry>[];
  List<HangSessionLog> _hangLogs = <HangSessionLog>[];

  // Active Hang Timer State
  Timer? _hangTimer;
  bool _isHangTimerRunning = false;
  int _currentHangSeconds = 0;
  HangMode _currentHangMode = HangMode.twoHand;
  HangStyle _currentHangStyle = HangStyle.activeScapular;

  // Getters
  List<DynamometerEntry> get dynamometerEntries =>
      List<DynamometerEntry>.unmodifiable(_dynamometerEntries);

  List<HangSessionLog> get hangLogs =>
      List<HangSessionLog>.unmodifiable(_hangLogs);

  bool get isHangTimerRunning => _isHangTimerRunning;
  int get currentHangSeconds => _currentHangSeconds;
  HangMode get currentHangMode => _currentHangMode;
  HangStyle get currentHangStyle => _currentHangStyle;

  DynamometerEntry? get latestDynamometerEntry =>
      _dynamometerEntries.isNotEmpty ? _dynamometerEntries.first : null;

  void _loadFromStorage() {
    _dynamometerEntries = _storageService.loadDynamometerEntries();
    // Sort descending by date
    _dynamometerEntries.sort((a, b) => b.date.compareTo(a.date));

    _hangLogs = _storageService.loadHangSessionLogs();
    _hangLogs.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // --- DYNAMOMETER & CNS READINESS MATH ---

  /// Rolling 14-day baseline max grip force in kg
  double get rollingBaselineMaxForceKg {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 14));
    final List<DynamometerEntry> recent = _dynamometerEntries
        .where((e) => e.date.isAfter(cutoff))
        .toList();

    if (recent.isEmpty) {
      return latestDynamometerEntry?.maxForceKg ?? 50;
    }

    final double sum = recent.fold(0, (acc, e) => acc + e.maxForceKg);
    return sum / recent.length;
  }

  /// CNS Readiness Score (0 to 100%)
  int get cnsReadinessPercent {
    if (latestDynamometerEntry == null) return 95;
    final double baseline = rollingBaselineMaxForceKg;
    if (baseline <= 0) return 95;
    final double ratio = latestDynamometerEntry!.maxForceKg / baseline;
    return (ratio * 100).round().clamp(50, 100);
  }

  String get cnsStatusText {
    final int score = cnsReadinessPercent;
    if (score >= 95) return 'Fresh & High CNS Output';
    if (score >= 88) return 'Moderate Neuromuscular Load';
    return 'Elevated CNS Fatigue (Heavy Pulling Warning)';
  }

  Future<void> addDynamometerEntry({
    required double leftHandKg,
    required double rightHandKg,
    String? notes,
  }) async {
    final DynamometerEntry entry = DynamometerEntry.create(
      leftHandKg: leftHandKg,
      rightHandKg: rightHandKg,
      notes: notes,
    );

    _dynamometerEntries.insert(0, entry);
    await _storageService.saveDynamometerEntries(_dynamometerEntries);
    notifyListeners();
  }

  Future<void> deleteDynamometerEntry(String id) async {
    _dynamometerEntries.removeWhere((e) => e.id == id);
    await _storageService.saveDynamometerEntries(_dynamometerEntries);
    notifyListeners();
  }

  // --- HANG PRs & LOGS ---

  int get bestTwoHandSeconds {
    final List<HangSessionLog> filtered =
        _hangLogs.where((l) => l.mode == HangMode.twoHand).toList();
    if (filtered.isEmpty) return 0;
    return filtered
        .map((l) => l.durationSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  int get bestLeftHandSeconds {
    final List<HangSessionLog> filtered =
        _hangLogs.where((l) => l.mode == HangMode.singleHandLeft).toList();
    if (filtered.isEmpty) return 0;
    return filtered
        .map((l) => l.durationSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  int get bestRightHandSeconds {
    final List<HangSessionLog> filtered =
        _hangLogs.where((l) => l.mode == HangMode.singleHandRight).toList();
    if (filtered.isEmpty) return 0;
    return filtered
        .map((l) => l.durationSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  double get twoHandGoalProgressRatio =>
      (bestTwoHandSeconds / 300.0).clamp(0.0, 1.0);

  double get leftHandGoalProgressRatio =>
      (bestLeftHandSeconds / 120.0).clamp(0.0, 1.0);

  double get rightHandGoalProgressRatio =>
      (bestRightHandSeconds / 120.0).clamp(0.0, 1.0);

  bool isPersonalRecord(HangMode mode, int durationSeconds) {
    switch (mode) {
      case HangMode.twoHand:
        return durationSeconds > bestTwoHandSeconds;
      case HangMode.singleHandLeft:
        return durationSeconds > bestLeftHandSeconds;
      case HangMode.singleHandRight:
        return durationSeconds > bestRightHandSeconds;
    }
  }

  Future<HangSessionLog> recordHangSession({
    required HangMode mode,
    required HangStyle style,
    required int durationSeconds,
    String? notes,
  }) async {
    final bool isPr = isPersonalRecord(mode, durationSeconds);
    final HangSessionLog log = HangSessionLog.create(
      mode: mode,
      style: style,
      durationSeconds: durationSeconds,
      targetSeconds: mode.standardGoalSeconds,
      isPersonalRecord: isPr,
      notes: notes,
    );

    _hangLogs.insert(0, log);
    await _storageService.saveHangSessionLogs(_hangLogs);
    notifyListeners();
    return log;
  }

  // --- LIVE HANG TIMER LOGIC ---

  void Function(int seconds)? _onHangTick;

  void startHangTimer({
    HangMode mode = HangMode.twoHand,
    HangStyle style = HangStyle.activeScapular,
    void Function(int seconds)? onTick,
  }) {
    _currentHangMode = mode;
    _currentHangStyle = style;
    _currentHangSeconds = 0;
    _isHangTimerRunning = true;
    _onHangTick = onTick;
    _hangTimer?.cancel();

    _hangTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentHangSeconds++;
      _checkHangMilestones(_currentHangSeconds, _currentHangMode);
      _onHangTick?.call(_currentHangSeconds);
      notifyListeners();
    });
    notifyListeners();
  }

  void _checkHangMilestones(int seconds, HangMode mode) {
    // Audio/haptic milestones at 30s, 60s, 90s, 120s, 180s, 240s, 300s
    const Set<int> milestones = <int>{30, 60, 90, 120, 180, 240, 300};
    if (milestones.contains(seconds)) {
      HapticFeedback.heavyImpact();
      _notificationService.playTimerBeepSound();
    }
  }

  int stopHangTimer() {
    _hangTimer?.cancel();
    _hangTimer = null;
    _onHangTick = null;
    _isHangTimerRunning = false;
    final int finalSecs = _currentHangSeconds;
    notifyListeners();
    return finalSecs;
  }

  void resetHangTimer() {
    _hangTimer?.cancel();
    _hangTimer = null;
    _onHangTick = null;
    _isHangTimerRunning = false;
    _currentHangSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _hangTimer?.cancel();
    _hangTimer = null;
    _onHangTick = null;
    super.dispose();
  }
}
