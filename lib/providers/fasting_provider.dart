import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';
import 'package:oly/models/fasting_grocery_item.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/models/nutrition_goal_model.dart';
import 'package:oly/services/fasting_engine_service.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class FastingProvider extends ChangeNotifier {
  new(this._storage, {NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService() {
    _loadState();
  }

  final StorageService _storage;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  FastingSession? _activeSession;
  List<FastingSession> _history = <FastingSession>[];
  AthleteCircadianConfig _circadianConfig = const AthleteCircadianConfig();
  List<FastingGroceryItem> _pantryItems = <FastingGroceryItem>[];
  List<FastingBiomarkerEntry> _biomarkers = <FastingBiomarkerEntry>[];
  Timer? _tickerTimer;

  // Cached fuel context for adaptive hydration calculations
  double? _cachedFuelWaterOz;
  bool _cachedIsTrainingDay = false;
  int? _cachedFuelWaterLoggedMl;

  // Getters
  FastingSession? get activeSession => _activeSession;
  bool get isFastingActive => _activeSession != null;
  double get elapsedHours => _activeSession?.elapsedHours ?? 0.0;
  List<FastingSession> get history => List.unmodifiable(_history);
  AthleteCircadianConfig get circadianConfig => _circadianConfig;
  List<FastingGroceryItem> get pantryItems => List.unmodifiable(_pantryItems);
  List<FastingBiomarkerEntry> get allBiomarkers =>
      List<FastingBiomarkerEntry>.unmodifiable(_biomarkers);
  double? get cachedFuelWaterOz => _cachedFuelWaterOz;
  bool get cachedIsTrainingDay => _cachedIsTrainingDay;
  int? get cachedFuelWaterLoggedMl => _cachedFuelWaterLoggedMl;

  /// Returns the research-backed fasting & biomarker hydration adjustment
  FastingHydrationAdjustment get currentHydrationAdjustment {
    if (!_circadianConfig.adjustForFastingBiomarkers) {
      return FastingHydrationAdjustment.zero;
    }
    return FastingEngineService.calculateFastingHydrationAdjustment(
      elapsedHours: elapsedHours,
      latestBiomarker: latestBiomarker,
    );
  }

  /// Calculates the effective daily water target in mL factoring in:
  /// 1. Fuel tab target (LBM + training day surcharge)
  /// 2. Fasting natriuresis & Keto-Mojo biomarker adjustment
  /// 3. Manual preference fallback
  int get effectiveDailyWaterTargetMl {
    double baseTargetOz;
    if (_circadianConfig.syncWithFuelWaterTarget &&
        _cachedFuelWaterOz != null &&
        _cachedFuelWaterOz! > 0) {
      baseTargetOz = _cachedFuelWaterOz!;
    } else {
      baseTargetOz = _circadianConfig.dailyWaterTargetMl / 29.5735;
    }

    int totalTargetMl = (baseTargetOz * 29.5735).round();

    if (_circadianConfig.adjustForFastingBiomarkers) {
      final FastingHydrationAdjustment adjustment = currentHydrationAdjustment;
      totalTargetMl += adjustment.bonusMl;
    }

    return totalTargetMl.clamp(1500, 6000);
  }

  /// Paced notification water portion in mL (divided into 6 daily reminders)
  int get scheduledPortionMl => (effectiveDailyWaterTargetMl / 6).round();

  /// Paced notification water portion in oz
  double get scheduledPortionOz => scheduledPortionMl / 29.5735296;

  /// 7-Day forward projection schedule based on current protocol
  List<FastingScheduleDay> get projectionSchedule {
    final FastingProtocol protocol =
        _activeSession?.protocol ?? FastingProtocol.intermittent16_8;
    return FastingEngineService.generateProjection(
      currentProtocol: protocol,
      config: _circadianConfig,
    );
  }

  /// Latest logged biomarker entry (for GKI & zone display)
  FastingBiomarkerEntry? get latestBiomarker {
    if (_biomarkers.isNotEmpty) {
      return _biomarkers.last;
    }
    if (_activeSession != null && _activeSession!.biomarkers.isNotEmpty) {
      return _activeSession!.biomarkers.last;
    }
    for (final FastingSession session in _history) {
      if (session.biomarkers.isNotEmpty) {
        return session.biomarkers.last;
      }
    }
    return null;
  }

  void _loadState() {
    _activeSession = _storage.loadActiveFastingSession();
    _history = _storage.loadFastingHistory();
    _circadianConfig = _storage.loadAthleteCircadianConfig();
    _pantryItems = List<FastingGroceryItem>.from(_storage.loadFastingPantryItems());
    _biomarkers = _storage.loadFastingBiomarkers();

    // Merge in any biomarkers stored inside activeSession or past history
    final Set<String> existingIds =
        _biomarkers.map((e) => e.id).toSet();
    if (_activeSession != null) {
      for (final FastingBiomarkerEntry b in _activeSession!.biomarkers) {
        if (!existingIds.contains(b.id)) {
          _biomarkers.add(b);
          existingIds.add(b.id);
        }
      }
    }
    for (final FastingSession session in _history) {
      for (final FastingBiomarkerEntry b in session.biomarkers) {
        if (!existingIds.contains(b.id)) {
          _biomarkers.add(b);
          existingIds.add(b.id);
        }
      }
    }
    _biomarkers.sort((a, b) =>
        a.timestamp.compareTo(b.timestamp));

    if (_pantryItems.isEmpty) {
      _pantryItems = List<FastingGroceryItem>.from(FastingEngineService.getSeedPantryItems());
      _storage.saveFastingPantryItems(_pantryItems);
    }

    // Initialize cached Fuel target from today's log or nutrition goal fallback
    final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, DailyNutritionLog> logs = _storage.loadDailyNutritionLogs();
    if (logs.containsKey(todayKey)) {
      _cachedFuelWaterOz = logs[todayKey]!.targetWaterOz;
      _cachedIsTrainingDay = logs[todayKey]!.isTrainingDay;
    } else {
      final NutritionGoalModel goal = _storage.loadNutritionGoal();
      final List<BodyCompositionEntry> comps = _storage.loadBodyCompEntries();
      final BodyCompositionEntry? latestComp =
          comps.isNotEmpty ? comps.first : null;
      _cachedFuelWaterOz = goal.getRecommendedWaterGoalOz(
        latestBodyComp: latestComp,
      );
      _cachedIsTrainingDay = false;
    }

    if (_activeSession != null) {
      _startTicker();
    }

    _syncNotificationSchedules();
    notifyListeners();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSession == null) {
        timer.cancel();
        return;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  /// Start a new fasting session
  Future<void> startFast({
    required FastingProtocol protocol,
    DateTime? customStartTime,
    int? customHours,
  }) async {
    final DateTime start = customStartTime ?? DateTime.now();
    final FastingSession session = FastingSession.create(
      id: _uuid.v4(),
      protocol: protocol,
      startTime: start,
      customDurationHours: customHours,
    );

    _activeSession = session;
    await _storage.saveActiveFastingSession(_activeSession);
    _startTicker();
    notifyListeners();
  }

  /// End the current fast, record subjective metrics, and move to history
  Future<void> endFast({
    int? energyRating,
    int? mentalClarityRating,
    int? hungerWaveRating,
    String? notes,
  }) async {
    if (_activeSession == null) {
      return;
    }

    _activeSession!.endTime = DateTime.now();
    _activeSession!.isCompleted = true;
    _activeSession!.energyRating = energyRating;
    _activeSession!.mentalClarityRating = mentalClarityRating;
    _activeSession!.hungerWaveRating = hungerWaveRating;
    _activeSession!.notes = notes;

    _history.insert(0, _activeSession!);
    await _storage.saveFastingHistory(_history);

    _activeSession = null;
    await _storage.saveActiveFastingSession(null);
    _stopTicker();
    notifyListeners();
  }

  /// Cancel an ongoing fast without recording as completed
  Future<void> cancelFast() async {
    _activeSession = null;
    await _storage.saveActiveFastingSession(null);
    _stopTicker();
    notifyListeners();
  }

  /// Log sodium / salt intake during an active fast
  Future<void> logSodium(int mg) async {
    if (_activeSession == null) {
      return;
    }
    _activeSession!.sodiumLoggedMg += mg;
    await _storage.saveActiveFastingSession(_activeSession);
    notifyListeners();
  }

  /// Log water intake during an active fast, with optional bridge to Fuel tab
  Future<void> logWater(int ml, {void Function(double oz)? onLogToFuel}) async {
    if (_activeSession != null) {
      _activeSession!.waterLoggedMl += ml;
      await _storage.saveActiveFastingSession(_activeSession);
    }
    if (onLogToFuel != null) {
      final double oz = ml / 29.5735296;
      onLogToFuel(oz);
    }
    notifyListeners();
  }

  /// Add a Keto-Mojo blood biomarker reading
  Future<void> addBiomarkerEntry({
    required double glucoseMgDl,
    required double ketoneMmolL,
    DateTime? timestamp,
    double? breathAcetonePpm,
    String? notes,
  }) async {
    final FastingBiomarkerEntry entry = FastingBiomarkerEntry.create(
      id: _uuid.v4(),
      glucoseMgDl: glucoseMgDl,
      ketoneMmolL: ketoneMmolL,
      timestamp: timestamp,
      breathAcetonePpm: breathAcetonePpm,
      notes: notes,
    );

    _biomarkers.add(entry);
    await _storage.saveFastingBiomarkers(_biomarkers);

    if (_activeSession != null) {
      _activeSession!.biomarkers.add(entry);
      await _storage.saveActiveFastingSession(_activeSession);
    } else if (_history.isNotEmpty) {
      _history.first.biomarkers.add(entry);
      await _storage.saveFastingHistory(_history);
    }
    _syncNotificationSchedules();
    notifyListeners();
  }

  /// Delete a biomarker reading
  Future<void> deleteBiomarkerEntry(String id) async {
    _biomarkers.removeWhere((e) => e.id == id);
    await _storage.saveFastingBiomarkers(_biomarkers);
    if (_activeSession != null) {
      _activeSession!.biomarkers.removeWhere((e) => e.id == id);
      await _storage.saveActiveFastingSession(_activeSession);
    }
    _syncNotificationSchedules();
    notifyListeners();
  }

  /// Toggle item in the Fasting Grocery / Pantry checklist
  Future<void> togglePantryItem(String itemId) async {
    final int index =
        _pantryItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final FastingGroceryItem current = _pantryItems[index];
      _pantryItems[index] = current.copyWith(isChecked: !current.isChecked);
      await _storage.saveFastingPantryItems(_pantryItems);
      notifyListeners();
    }
  }

  /// Add a custom grocery or pantry item
  Future<void> addCustomPantryItem({
    required String name,
    required FastingGroceryCategory category,
    String description = '',
  }) async {
    final FastingGroceryItem item = FastingGroceryItem(
      id: _uuid.v4(),
      name: name,
      category: category,
      description: description,
      isCustom: true,
    );
    _pantryItems.add(item);
    await _storage.saveFastingPantryItems(_pantryItems);
    notifyListeners();
  }

  /// Remove a custom grocery item
  Future<void> removeCustomPantryItem(String itemId) async {
    _pantryItems.removeWhere((i) => i.id == itemId);
    await _storage.saveFastingPantryItems(_pantryItems);
    notifyListeners();
  }

  /// Synchronizes dynamic target and water logged with active Fuel tab / nutrition state
  void syncFuelContext({
    required double fuelWaterOz,
    required bool isTrainingDay,
    int? loggedWaterMl,
  }) {
    bool changed = _cachedFuelWaterOz != fuelWaterOz ||
        _cachedIsTrainingDay != isTrainingDay;
    _cachedFuelWaterOz = fuelWaterOz;
    _cachedIsTrainingDay = isTrainingDay;

    if (loggedWaterMl != null) {
      if (_cachedFuelWaterLoggedMl != loggedWaterMl) {
        _cachedFuelWaterLoggedMl = loggedWaterMl;
        changed = true;
      }
      if (_activeSession != null &&
          _activeSession!.waterLoggedMl < loggedWaterMl) {
        _activeSession!.waterLoggedMl = loggedWaterMl;
        _storage.saveActiveFastingSession(_activeSession);
        changed = true;
      }
    }

    if (changed) {
      _syncNotificationSchedules();
      notifyListeners();
    }
  }

  /// Synchronizes water logged in the Fuel tab with the active fasting session
  Future<void> syncWaterFromFuel(int dailyWaterMl) async {
    _cachedFuelWaterLoggedMl = dailyWaterMl;
    if (_activeSession != null) {
      if (_activeSession!.waterLoggedMl < dailyWaterMl) {
        _activeSession!.waterLoggedMl = dailyWaterMl;
        await _storage.saveActiveFastingSession(_activeSession);
      }
    }
    notifyListeners();
  }

  /// Sets the exact water amount from the Fuel tab (e.g. Set Total action)
  Future<void> setWaterFromFuel(int dailyWaterMl) async {
    _cachedFuelWaterLoggedMl = dailyWaterMl;
    if (_activeSession != null) {
      _activeSession!.waterLoggedMl = dailyWaterMl;
      await _storage.saveActiveFastingSession(_activeSession);
    }
    notifyListeners();
  }

  /// Update athlete circadian preferences
  Future<void> updateCircadianConfig(AthleteCircadianConfig config) async {
    _circadianConfig = config;
    await _storage.saveAthleteCircadianConfig(_circadianConfig);
    _syncNotificationSchedules();
    notifyListeners();
  }

  /// Toggle water intake notifications
  Future<void> toggleWaterReminders(bool enabled) async {
    _circadianConfig =
        _circadianConfig.copyWith(waterRemindersEnabled: enabled);
    await _storage.saveAthleteCircadianConfig(_circadianConfig);
    _syncNotificationSchedules();
    notifyListeners();
  }

  /// Toggle fasting coffee notifications
  Future<void> toggleCoffeeReminders(bool enabled) async {
    _circadianConfig =
        _circadianConfig.copyWith(coffeeRemindersEnabled: enabled);
    await _storage.saveAthleteCircadianConfig(_circadianConfig);
    _syncNotificationSchedules();
    notifyListeners();
  }

  void _syncNotificationSchedules() {
    if (_circadianConfig.waterRemindersEnabled) {
      final FastingHydrationAdjustment adjustment = currentHydrationAdjustment;
      _notificationService.scheduleFastingHydrationReminders(
        dailyTargetMl: effectiveDailyWaterTargetMl,
        wakeHour: _circadianConfig.wakeHour,
        wakeMinute: _circadianConfig.wakeMinute,
        isTrainingDay: _cachedIsTrainingDay,
        isDeepKetosis: adjustment.isDeepKetosis,
      );
    } else {
      _notificationService.cancelHydrationReminders();
    }

    if (_circadianConfig.coffeeRemindersEnabled) {
      _notificationService.scheduleFastingCoffeeReminders();
    } else {
      _notificationService.cancelCoffeeReminders();
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}
