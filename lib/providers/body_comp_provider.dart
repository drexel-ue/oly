import 'package:flutter/foundation.dart';
import '../models/body_composition_entry.dart';
import '../services/storage_service.dart';

class BodyCompProvider extends ChangeNotifier {
  final StorageService _storage;
  List<BodyCompositionEntry> _entries = [];

  BodyCompProvider(this._storage) {
    _loadEntries();
  }

  List<BodyCompositionEntry> get entries => List.unmodifiable(_entries);

  BodyCompositionEntry? get latestEntry => _entries.isNotEmpty ? _entries.first : null;

  BodyCompositionEntry? get previousEntry => _entries.length > 1 ? _entries[1] : null;

  BodyCompositionEntry? get baselineEntry => _entries.isNotEmpty ? _entries.last : null;

  bool get hasEntries => _entries.isNotEmpty;

  void _loadEntries() {
    _entries = _storage.loadBodyCompEntries();
    if (_entries.isEmpty) {
      // Add initial seed based on user's Renpho scale baseline if empty
      _entries = [
        BodyCompositionEntry.create(
          timestamp: DateTime(2026, 7, 21, 19, 30, 37),
          weightLb: 264.8,
          bmi: 34.9,
          bodyFatPct: 21.2,
          bodyFatLb: 56.2,
          skeletalMuscleLb: 134.6,
          skeletalMusclePct: 50.8,
          fatFreeMassLb: 208.6,
          subcutaneousFatPct: 16.8,
          visceralFat: 17,
          bodyWaterLb: 150.6,
          bodyWaterPct: 56.9,
          muscleMassLb: 198.4,
          muscleMassPct: 74.9,
          boneMassLb: 10.4,
          boneMassPct: 3.9,
          proteinLb: 47.6,
          proteinPct: 18.0,
          bmrKcal: 2394,
          metabolicAge: 35,
          source: 'renpho_ocr',
          notes: 'Baseline Renpho Scale scan',
        ),
      ];
      _storage.saveBodyCompEntries(_entries);
    }
    notifyListeners();
  }

  Future<void> addEntry(BodyCompositionEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _storage.saveBodyCompEntries(_entries);
    notifyListeners();
  }

  Future<void> updateEntry(BodyCompositionEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveBodyCompEntries(_entries);
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveBodyCompEntries(_entries);
    notifyListeners();
  }

  /// Calculates weight delta vs previous scan (in lbs)
  double get weightDeltaVsPrevious {
    if (latestEntry == null || previousEntry == null) return 0.0;
    return latestEntry!.weightLb - previousEntry!.weightLb;
  }

  /// Calculates body fat % delta vs previous scan
  double get bodyFatPctDeltaVsPrevious {
    if (latestEntry?.bodyFatPct == null || previousEntry?.bodyFatPct == null) return 0.0;
    return latestEntry!.bodyFatPct! - previousEntry!.bodyFatPct!;
  }

  /// Calculates Lean Body Mass delta vs previous scan (in lbs)
  double get leanMassDeltaVsPrevious {
    if (latestEntry == null || previousEntry == null) return 0.0;
    return latestEntry!.leanBodyMassLb - previousEntry!.leanBodyMassLb;
  }

  /// Calculates Fat Mass delta vs previous scan (in lbs)
  double get fatMassDeltaVsPrevious {
    if (latestEntry == null || previousEntry == null) return 0.0;
    return latestEntry!.fatMassLb - previousEntry!.fatMassLb;
  }

  /// Calculates Skeletal Muscle delta vs previous scan (in lbs)
  double get skeletalMuscleDeltaVsPrevious {
    if (latestEntry?.skeletalMuscleLb == null || previousEntry?.skeletalMuscleLb == null) return 0.0;
    return latestEntry!.skeletalMuscleLb! - previousEntry!.skeletalMuscleLb!;
  }

  /// Rolling average weight for the last N days
  double getRollingAverageWeight([int days = 7]) {
    if (_entries.isEmpty) return 0.0;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final relevant = _entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    if (relevant.isEmpty) return latestEntry!.weightLb;
    return relevant.fold(0.0, (sum, e) => sum + e.weightLb) / relevant.length;
  }

  /// Filter entries within a timeframe
  List<BodyCompositionEntry> getEntriesForRange(Duration duration) {
    if (_entries.isEmpty) return [];
    final cutoff = DateTime.now().subtract(duration);
    final filtered = _entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // ascending for charts
    return filtered;
  }
}
