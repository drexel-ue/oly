import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/lift_model.dart';
import '../models/pr_entry.dart';
import '../services/storage_service.dart';

class LiftRatioAnalysis {
  final LiftModel lift;
  final LiftModel anchorLift;
  final double actualRatio;
  final double targetRatio;
  final double ratioPercentage; // actual / target * 100
  final String status; // 'Balanced', 'Underdeveloped', 'Dominant'

  LiftRatioAnalysis({
    required this.lift,
    required this.anchorLift,
    required this.actualRatio,
    required this.targetRatio,
    required this.ratioPercentage,
    required this.status,
  });
}

class LiftProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<LiftModel> _lifts = [];

  LiftProvider(this._storage) {
    _lifts = _storage.loadLifts();
  }

  List<LiftModel> get lifts => List.unmodifiable(_lifts);

  Map<String, double> get currentMaxes {
    final map = <String, double>{};
    for (var lift in _lifts) {
      map[lift.id] = lift.currentMax;
    }
    return map;
  }

  LiftModel? getLift(String id) {
    try {
      return _lifts.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  double getOlympicTotal() {
    final snatch = getLift('snatch')?.currentMax ?? 0.0;
    final cj = getLift('clean_and_jerk')?.currentMax ?? 0.0;
    return snatch + cj;
  }

  Future<void> updateMax(String liftId, double newMaxKg, {String? notes, int reps = 1, double? rpe}) async {
    final liftIndex = _lifts.indexWhere((l) => l.id == liftId);
    if (liftIndex == -1) return;

    final lift = _lifts[liftIndex];
    lift.currentMax = newMaxKg;

    final prEntry = PREntry(
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
    final lift = getLift(liftId);
    final maxKg = lift?.currentMax ?? 100.0;

    final percentages = [50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105];
    final map = <int, double>{};
    for (var pct in percentages) {
      map[pct] = maxKg * (pct / 100.0);
    }
    return map;
  }

  List<LiftRatioAnalysis> getRatioAnalysis() {
    final results = <LiftRatioAnalysis>[];

    for (var lift in _lifts) {
      if (lift.anchorLiftId == null || lift.anchorLiftId!.isEmpty) continue;

      final anchorLift = getLift(lift.anchorLiftId!);
      if (anchorLift == null || anchorLift.currentMax <= 0) continue;

      final actualRatio = lift.currentMax / anchorLift.currentMax;
      final targetRatio = lift.targetRatio;
      final ratioPct = (actualRatio / targetRatio) * 100.0;

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
}
