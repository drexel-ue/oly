import 'package:flutter/foundation.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/injury_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class InjuryProvider extends ChangeNotifier {
  InjuryProvider(this._storage) {
    _injuries = _storage.loadInjuries();
    InjuryDatabaseService.instance.loadCatalog();
  }

  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  late List<InjuryRecord> _injuries;

  List<InjuryRecord> get allInjuries => List.unmodifiable(_injuries);
  List<InjuryRecord> get activeInjuries =>
      _injuries.where((InjuryRecord i) => i.isActive).toList();
  List<InjuryRecord> get chronicInjuries =>
      activeInjuries.where((InjuryRecord i) => i.stage == InjuryStage.chronic).toList();
  List<InjuryRecord> get subacuteInjuries =>
      activeInjuries.where((InjuryRecord i) => i.stage == InjuryStage.subacute).toList();
  List<InjuryRecord> get acuteInjuries =>
      activeInjuries.where((InjuryRecord i) => i.stage == InjuryStage.acute).toList();
  List<InjuryRecord> get resolvedInjuries =>
      _injuries.where((InjuryRecord i) => !i.isActive).toList();

  int get totalActiveCount => activeInjuries.length;

  double get averagePainScore {
    if (activeInjuries.isEmpty) {
      return 0.0;
    }
    final int sum = activeInjuries.fold(
      0,
      (int acc, InjuryRecord i) => acc + i.painScale,
    );
    return sum / activeInjuries.length;
  }

  InjuryRecord? getActiveInjuryForRegion(InjuryRegion region) {
    try {
      return activeInjuries.firstWhere((InjuryRecord i) => i.region == region);
    } catch (_) {
      return null;
    }
  }

  int getPainForRegion(InjuryRegion region) {
    final InjuryRecord? injury = getActiveInjuryForRegion(region);
    return injury?.painScale ?? 0;
  }

  Future<void> addInjury(InjuryRecord record) async {
    _injuries.removeWhere((InjuryRecord i) => i.id == record.id);
    // If there is already an active injury for this region, update or replace it
    _injuries.removeWhere(
      (InjuryRecord i) => i.region == record.region && i.isActive && i.id != record.id,
    );

    _injuries.insert(0, record);
    await _storage.saveInjuries(_injuries);
    AppLogService.instance.info(
      'INJURY',
      'Added injury: ${record.name} on ${record.region.displayName} (Pain: ${record.painScale}, ${record.stage.label})',
    );
    notifyListeners();
  }

  Future<void> updateInjury(InjuryRecord record) async {
    final int index = _injuries.indexWhere((InjuryRecord i) => i.id == record.id);
    if (index != -1) {
      _injuries[index] = record;
      await _storage.saveInjuries(_injuries);
      notifyListeners();
    } else {
      await addInjury(record);
    }
  }

  Future<void> resolveInjury(String id) async {
    final int index = _injuries.indexWhere((InjuryRecord i) => i.id == id);
    if (index != -1) {
      final InjuryRecord existing = _injuries[index];
      _injuries[index] = existing.copyWith(
        isActive: false,
        resolvedAt: DateTime.now(),
        painScale: 0,
      );
      await _storage.saveInjuries(_injuries);
      AppLogService.instance.info(
        'INJURY',
        'Resolved injury: ${existing.name} on ${existing.region.displayName}',
      );
      notifyListeners();
    }
  }

  Future<void> deleteInjury(String id) async {
    _injuries.removeWhere((InjuryRecord i) => i.id == id);
    await _storage.saveInjuries(_injuries);
    notifyListeners();
  }

  Future<void> logPainCheckin({
    required InjuryRegion region,
    required int painScale,
    String notes = '',
    int? sessionRpe,
  }) async {
    final InjuryRecord? existing = getActiveInjuryForRegion(region);

    if (existing != null) {
      final List<InjuryHistoryEntry> newHistory =
          List<InjuryHistoryEntry>.from(existing.history);
      newHistory.insert(
        0,
        InjuryHistoryEntry(
          date: DateTime.now(),
          painScale: painScale,
          notes: notes,
          sessionRpe: sessionRpe,
        ),
      );

      final InjuryRecord updated = existing.copyWith(
        painScale: painScale,
        isActive: painScale > 0,
        resolvedAt: painScale == 0 ? DateTime.now() : null,
        history: newHistory,
        notes: notes.isNotEmpty ? notes : existing.notes,
      );
      await updateInjury(updated);
    } else if (painScale > 0) {
      // Create new quick strain entry
      final InjuryRecord newRecord = InjuryRecord(
        id: _uuid.v4(),
        name: '${region.displayName} Strain',
        region: region,
        onsetDate: DateTime.now(),
        painScale: painScale,
        notes: notes,
        history: <InjuryHistoryEntry>[
          InjuryHistoryEntry(
            date: DateTime.now(),
            painScale: painScale,
            notes: notes,
            sessionRpe: sessionRpe,
          ),
        ],
      );
      await addInjury(newRecord);
    }
  }

  /// Processes post-workout session strain check-in map.
  Future<void> processPostSessionCheckin({
    required Map<InjuryRegion, int> postSessionPain,
    String sessionNotes = '',
    int? sessionRpe,
  }) async {
    for (final MapEntry<InjuryRegion, int> entry in postSessionPain.entries) {
      final InjuryRegion region = entry.key;
      final int pain = entry.value;
      await logPainCheckin(
        region: region,
        painScale: pain,
        notes: sessionNotes.isNotEmpty
            ? 'Post-session check-in: $sessionNotes'
            : 'Post-session check-in',
        sessionRpe: sessionRpe,
      );
    }
  }
}
