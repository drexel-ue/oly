import 'package:flutter/foundation.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/pr_entry.dart';
import 'package:oly/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class LiftRatioAnalysis {
  // 'Balanced', 'Underdeveloped', 'Dominant'

  LiftRatioAnalysis({
    required this.lift,
    required this.anchorLift,
    required this.actualRatio,
    required this.targetRatio,
    required this.ratioPercentage,
    required this.status,
  });
  final LiftModel lift;
  final LiftModel anchorLift;
  final double actualRatio;
  final double targetRatio;
  final double ratioPercentage; // actual / target * 100
  final String status;
}

class LiftSuggestion {
  LiftSuggestion({required this.suggestedMaxKg, required this.reason});
  final double suggestedMaxKg;
  final String reason;
}

class LiftProvider extends ChangeNotifier {
  LiftProvider(this._storage) {
    _lifts = _storage.loadLifts();
  }
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  List<LiftModel> _lifts = <LiftModel>[];

  List<LiftModel> get lifts => List.unmodifiable(_lifts);

  Map<String, double> get currentMaxes {
    final Map<String, double> map = <String, double>{};
    for (final LiftModel lift in _lifts) {
      map[lift.id] = lift.currentMax;
    }
    return map;
  }

  LiftModel? getLift(String id) {
    try {
      return _lifts.firstWhere((LiftModel l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  double getOlympicTotal() {
    final double snatch = getLift('snatch')?.currentMax ?? 0.0;
    final double cj = getLift('clean_and_jerk')?.currentMax ?? 0.0;
    return snatch + cj;
  }

  Future<void> updateMax(
    String liftId,
    double newMaxKg, {
    String? notes,
    int reps = 1,
    double? rpe,
  }) async {
    final int liftIndex = _lifts.indexWhere((LiftModel l) => l.id == liftId);
    if (liftIndex == -1) {
      return;
    }

    final LiftModel lift = _lifts[liftIndex];
    lift.currentMax = newMaxKg;

    final PREntry prEntry = PREntry(
      id: _uuid.v4(),
      weight: newMaxKg,
      reps: reps,
      date: DateTime.now(),
      rpe: rpe,
      notes: notes ?? 'Updated PR',
    );

    lift.history.insert(0, prEntry);
    await _storage.saveLifts(_lifts);
    notifyListeners();
  }

  Map<int, double> getPercentageMatrix(String liftId) {
    final LiftModel? lift = getLift(liftId);
    final double maxKg = lift?.currentMax ?? 100.0;

    final List<int> percentages = <int>[
      50,
      55,
      60,
      65,
      70,
      75,
      80,
      85,
      90,
      95,
      100,
      105,
    ];
    final Map<int, double> map = <int, double>{};
    for (final int pct in percentages) {
      map[pct] = maxKg * (pct / 100.0);
    }
    return map;
  }

  List<LiftRatioAnalysis> getRatioAnalysis() {
    final List<LiftRatioAnalysis> results = <LiftRatioAnalysis>[];

    for (final LiftModel lift in _lifts) {
      if (lift.anchorLiftId == null || lift.anchorLiftId!.isEmpty) {
        continue;
      }

      final LiftModel? anchorLift = getLift(lift.anchorLiftId!);
      if (anchorLift == null || anchorLift.currentMax <= 0) {
        continue;
      }

      final double actualRatio = lift.currentMax / anchorLift.currentMax;
      final double targetRatio = lift.targetRatio;
      final double ratioPct = (actualRatio / targetRatio) * 100.0;

      String status = 'Balanced';
      if (ratioPct < 93.0) {
        status = 'Underdeveloped';
      } else if (ratioPct > 107.0) {
        status = 'Dominant';
      }

      results.add(
        LiftRatioAnalysis(
          lift: lift,
          anchorLift: anchorLift,
          actualRatio: actualRatio,
          targetRatio: targetRatio,
          ratioPercentage: ratioPct,
          status: status,
        ),
      );
    }

    return results;
  }

  LiftSuggestion? getSuggestion(String liftId) {
    final LiftModel? lift = getLift(liftId);
    if (lift == null) {
      return null;
    }

    // 1. Direct anchor check (e.g., Hang Snatch -> 88% of Snatch)
    if (lift.anchorLiftId != null && lift.anchorLiftId!.isNotEmpty) {
      final LiftModel? anchor = getLift(lift.anchorLiftId!);
      if (anchor != null && anchor.currentMax > 0) {
        final double calculatedKg = anchor.currentMax * lift.targetRatio;
        final String pctStr = (lift.targetRatio * 100).toStringAsFixed(0);
        return LiftSuggestion(
          suggestedMaxKg: calculatedKg,
          reason: '$pctStr% of ${anchor.name}',
        );
      }
    }

    // 2. Reverse anchor check (e.g., Snatch estimated from Hang Snatch)
    final List<LiftModel> dependents = _lifts
        .where((LiftModel l) => l.anchorLiftId == liftId && l.currentMax > 0)
        .toList();
    if (dependents.isNotEmpty) {
      final LiftModel primaryDep = dependents.first;
      final double calculatedKg =
          primaryDep.currentMax / primaryDep.targetRatio;
      final String pctStr = (primaryDep.targetRatio * 100).toStringAsFixed(0);
      return LiftSuggestion(
        suggestedMaxKg: calculatedKg,
        reason: 'Estimated from ${primaryDep.name} ($pctStr% ratio)',
      );
    }

    return null;
  }

  Future<void> reload() async {
    _lifts = _storage.loadLifts();
    notifyListeners();
  }
}
