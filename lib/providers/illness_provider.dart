import 'package:flutter/foundation.dart';
import 'package:oly/models/illness_model.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/storage_service.dart';

class IllnessProvider extends ChangeNotifier {
  new(this._storage) {
    _records = _storage.loadIllnessRecords();
  }

  final StorageService _storage;
  late List<IllnessRecord> _records;

  List<IllnessRecord> get allRecords => List.unmodifiable(_records);

  List<IllnessRecord> get activeRecords =>
      _records.where((r) => r.isActive).toList();

  bool get hasActiveIllness => activeRecords.isNotEmpty;

  IllnessRecord? get activeRecord =>
      hasActiveIllness ? activeRecords.first : null;

  List<IllnessRecord> get convalescingRecords =>
      _records.where((r) => r.isConvalescing).toList();

  bool get isConvalescing => !hasActiveIllness && convalescingRecords.isNotEmpty;

  IllnessRecord? get convalescingRecord =>
      isConvalescing ? convalescingRecords.first : null;

  /// Whether the athlete's current training cycle calendar should be frozen
  bool get isTrainingFrozen => activeRecord?.isTrainingFrozen ?? false;

  /// Holistic readiness penalty deducted from baseline readiness score
  int get effectiveReadinessDeduction {
    if (hasActiveIllness) {
      return activeRecord!.readinessDeduction;
    }
    if (isConvalescing) {
      return convalescingRecord!.readinessDeduction;
    }
    return 0;
  }

  /// Scale multiplier for barbell working loads (0.0 = full rest, 0.7 = -30%, 1.0 = normal)
  double get effectiveLoadScale {
    if (hasActiveIllness) {
      return activeRecord!.suggestedLoadScale;
    }
    if (isConvalescing) {
      return convalescingRecord!.suggestedLoadScale;
    }
    return 1;
  }

  bool get isBallisticContraindicated =>
      activeRecord?.isBallisticContraindicated ?? false;

  bool get isFastingContraindicated =>
      activeRecord?.isFastingContraindicated ?? false;

  bool get isWimHofContraindicated =>
      activeRecord?.isWimHofContraindicated ?? false;

  int get hydrationBonusMl {
    if (hasActiveIllness) {
      return activeRecord!.hydrationBonusMl;
    }
    return 0;
  }

  Future<void> logIllness({
    required IllnessSeverity severity,
    List<IllnessSymptom> symptoms = const <IllnessSymptom>[],
    bool hasFever = false,
    double? temperatureCelsius,
    String? notes,
    bool isTrainingFrozen = true,
  }) async {
    // If there is an existing active record, mark it superseded
    final DateTime now = DateTime.now();
    for (int i = 0; i < _records.length; i++) {
      if (_records[i].isActive) {
        _records[i] = _records[i].copyWith(
          resolvedDate: now,
          reEntryStage: ReEntryStage.stage3FullResumption,
        );
      }
    }

    final IllnessRecord newRecord = IllnessRecord.createNew(
      severity: severity,
      symptoms: symptoms,
      hasFever: hasFever,
      temperatureCelsius: temperatureCelsius,
      notes: notes,
      isTrainingFrozen: isTrainingFrozen,
    );

    _records.insert(0, newRecord);
    await _storage.saveIllnessRecords(_records);

    AppLogService.instance.info(
      'ILLNESS',
      'Logged illness: ${severity.displayName}, fever: $hasFever, freezeCycle: $isTrainingFrozen',
    );
    notifyListeners();
  }

  Future<void> updateIllness(IllnessRecord record) async {
    final int index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      await _storage.saveIllnessRecords(_records);
      notifyListeners();
    }
  }

  /// Transition active illness to Re-Entry Stage 1 (Active Restoration)
  Future<void> resolveIllness(String id) async {
    final int index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      final IllnessRecord existing = _records[index];
      final DateTime now = DateTime.now();
      _records[index] = existing.copyWith(
        resolvedDate: now,
        reEntryStage: ReEntryStage.stage1LightRecovery,
        reEntryStageStartedAt: now,
        isTrainingFrozen: false,
      );
      await _storage.saveIllnessRecords(_records);

      AppLogService.instance.info(
        'ILLNESS',
        'Illness $id transitioned to Re-Entry Stage 1 (Active Restoration)',
      );
      notifyListeners();
    }
  }

  /// Advance through the 3-day Return-to-Play re-entry ramp:
  /// Stage 1 (50%) -> Stage 2 (70%) -> Stage 3 (Cleared / 100%)
  Future<void> advanceReEntryStage(String id) async {
    final int index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      final IllnessRecord existing = _records[index];
      final DateTime now = DateTime.now();

      ReEntryStage nextStage;
      switch (existing.reEntryStage) {
        case ReEntryStage.stage0Acute:
          nextStage = ReEntryStage.stage1LightRecovery;
        case ReEntryStage.stage1LightRecovery:
          nextStage = ReEntryStage.stage2ModerateVolume;
        case ReEntryStage.stage2ModerateVolume:
        case ReEntryStage.stage3FullResumption:
          nextStage = ReEntryStage.stage3FullResumption;
      }

      _records[index] = existing.copyWith(
        reEntryStage: nextStage,
        reEntryStageStartedAt: now,
        isTrainingFrozen: false,
      );
      await _storage.saveIllnessRecords(_records);

      AppLogService.instance.info(
        'ILLNESS',
        'Illness $id advanced to ${nextStage.displayName}',
      );
      notifyListeners();
    }
  }

  Future<void> deleteIllness(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _storage.saveIllnessRecords(_records);
    AppLogService.instance.info('ILLNESS', 'Deleted illness record $id');
    notifyListeners();
  }
}
