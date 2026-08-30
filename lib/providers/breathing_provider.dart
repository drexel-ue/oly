import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/services/storage_service.dart';

class BreathingProvider extends ChangeNotifier {
  BreathingProvider(this._storage) {
    _loadData();
  }

  final StorageService _storage;
  List<BreathingSessionLog> _sessions = <BreathingSessionLog>[];
  WimHofConfig _config = const WimHofConfig();

  void _loadData() {
    _sessions = _storage.loadBreathingLogs();
    _config = _storage.loadBreathingConfig();
  }

  List<BreathingSessionLog> get sessions => List.unmodifiable(_sessions);
  WimHofConfig get config => _config;

  int get totalSessionsCompleted => _sessions.length;

  int get totalRoundsCompleted {
    return _sessions.fold(
      0,
      (int sum, BreathingSessionLog s) => sum + s.rounds.length,
    );
  }

  int get allTimeMaxHoldSeconds {
    if (_sessions.isEmpty) {
      return 0;
    }
    int max = 0;
    for (final BreathingSessionLog session in _sessions) {
      if (session.maxHoldSeconds > max) {
        max = session.maxHoldSeconds;
      }
    }
    return max;
  }

  String get formattedAllTimeMaxHold {
    final int max = allTimeMaxHoldSeconds;
    final int minutes = max ~/ 60;
    final int seconds = max % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get allTimeTotalRetentionSeconds {
    return _sessions.fold(
      0,
      (int sum, BreathingSessionLog s) => sum + s.totalHoldSeconds,
    );
  }

  String get formattedAllTimeTotalRetention {
    final int total = allTimeTotalRetentionSeconds;
    final int hours = total ~/ 3600;
    final int minutes = (total % 3600) ~/ 60;
    final int seconds = total % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  int get averageHoldSecondsAcrossAllSessions {
    if (_sessions.isEmpty) {
      return 0;
    }
    int totalHolds = 0;
    int roundCount = 0;
    for (final BreathingSessionLog session in _sessions) {
      for (final BreathingRoundLog round in session.rounds) {
        totalHolds += round.retentionSeconds;
        roundCount++;
      }
    }
    return roundCount > 0 ? (totalHolds / roundCount).round() : 0;
  }

  String get formattedAverageHold {
    final int avg = averageHoldSecondsAcrossAllSessions;
    final int minutes = avg ~/ 60;
    final int seconds = avg % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool isNewPR(int holdSeconds) {
    if (holdSeconds <= 0) {
      return false;
    }
    return holdSeconds > allTimeMaxHoldSeconds;
  }

  /// Calculates the average hold duration for each round index (Round 1, Round 2, Round 3, etc.)
  Map<int, double> get roundAveragesMap {
    final Map<int, List<int>> roundHolds = <int, List<int>>{};
    for (final BreathingSessionLog session in _sessions) {
      for (final BreathingRoundLog round in session.rounds) {
        roundHolds
            .putIfAbsent(round.roundNumber, () => <int>[])
            .add(round.retentionSeconds);
      }
    }

    final Map<int, double> averages = <int, double>{};
    for (final MapEntry<int, List<int>> entry in roundHolds.entries) {
      final double avg =
          entry.value.reduce((int a, int b) => a + b) / entry.value.length;
      averages[entry.key] = avg;
    }
    return averages;
  }

  /// Chronological list of max hold FlSpots for LineChart
  List<FlSpot> get maxHoldTrendSpots {
    final List<BreathingSessionLog> chronological =
        List<BreathingSessionLog>.from(_sessions)
          ..sort((BreathingSessionLog a, BreathingSessionLog b) =>
              a.date.compareTo(b.date));

    return chronological.asMap().entries.map((
      MapEntry<int, BreathingSessionLog> entry,
    ) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.maxHoldSeconds.toDouble(),
      );
    }).toList();
  }

  /// Chronological list of average hold FlSpots for LineChart
  List<FlSpot> get avgHoldTrendSpots {
    final List<BreathingSessionLog> chronological =
        List<BreathingSessionLog>.from(_sessions)
          ..sort((BreathingSessionLog a, BreathingSessionLog b) =>
              a.date.compareTo(b.date));

    return chronological.asMap().entries.map((
      MapEntry<int, BreathingSessionLog> entry,
    ) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.avgHoldSeconds.toDouble(),
      );
    }).toList();
  }

  Future<void> saveSession(BreathingSessionLog session) async {
    _sessions.insert(0, session);
    await _storage.saveBreathingLogs(_sessions);
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((BreathingSessionLog s) => s.id == sessionId);
    await _storage.saveBreathingLogs(_sessions);
    notifyListeners();
  }

  Future<void> updateConfig(WimHofConfig config) async {
    _config = config;
    await _storage.saveBreathingConfig(config);
    notifyListeners();
  }
}
