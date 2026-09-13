import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamometer Model & Symmetry Math Tests', () {
    test('Calculates max force, asymmetry percent, and dominant hand correctly', () {
      final DynamometerEntry entry = DynamometerEntry.create(
        leftHandKg: 45,
        rightHandKg: 50,
      );

      expect(entry.maxForceKg, equals(50));
      expect(entry.dominantHand, equals('Right'));
      // Asymmetry: |50 - 45| / 50 * 100 = 10%
      expect(entry.asymmetryPercent, closeTo(10, 0.01));
      expect(entry.isBalanced, isTrue);
    });

    test('Flags significant asymmetry when difference exceeds 10%', () {
      final DynamometerEntry asymmetricEntry = DynamometerEntry.create(
        leftHandKg: 35,
        rightHandKg: 50,
      );

      // |50 - 35| / 50 * 100 = 30%
      expect(asymmetricEntry.asymmetryPercent, closeTo(30, 0.01));
      expect(asymmetricEntry.isBalanced, isFalse);
    });
  });

  group('GripHangProvider State & CNS Baseline Tests', () {
    late StorageService storage;
    late GripHangProvider gripHangProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      gripHangProvider = GripHangProvider(storage);
    });

    test('Initializes with empty entries and default CNS score', () {
      expect(gripHangProvider.dynamometerEntries, isEmpty);
      expect(gripHangProvider.hangLogs, isEmpty);
      expect(gripHangProvider.latestDynamometerEntry, isNull);
      expect(gripHangProvider.cnsReadinessPercent, equals(95));
      expect(gripHangProvider.bestTwoHandSeconds, equals(0));
      expect(gripHangProvider.bestLeftHandSeconds, equals(0));
      expect(gripHangProvider.bestRightHandSeconds, equals(0));
    });

    test('Adds dynamometer entry and updates baseline & CNS readiness score', () async {
      await gripHangProvider.addDynamometerEntry(
        leftHandKg: 48,
        rightHandKg: 52,
        notes: 'Morning test',
      );

      expect(gripHangProvider.dynamometerEntries.length, equals(1));
      expect(gripHangProvider.latestDynamometerEntry!.maxForceKg, equals(52));
      expect(gripHangProvider.rollingBaselineMaxForceKg, equals(52));
      expect(gripHangProvider.cnsReadinessPercent, equals(100));
      expect(gripHangProvider.cnsStatusText, equals('Fresh & High CNS Output'));

      // Check persistence
      final GripHangProvider reloaded = GripHangProvider(storage);
      expect(reloaded.dynamometerEntries.length, equals(1));
      expect(reloaded.latestDynamometerEntry!.maxForceKg, equals(52));
    });

    test('Detects CNS fatigue when latest grip force drops compared to rolling baseline', () async {
      // Simulate historical high entries within 14 days
      final DateTime now = DateTime.now();
      final List<DynamometerEntry> history = <DynamometerEntry>[
        DynamometerEntry(
          id: 'entry_1',
          date: now.subtract(const Duration(days: 3)),
          leftHandKg: 58,
          rightHandKg: 60,
        ),
        DynamometerEntry(
          id: 'entry_2',
          date: now.subtract(const Duration(days: 1)),
          leftHandKg: 59,
          rightHandKg: 60,
        ),
      ];
      await storage.saveDynamometerEntries(history);

      final GripHangProvider providerWithHistory = GripHangProvider(storage);
      expect(providerWithHistory.rollingBaselineMaxForceKg, equals(60));

      // Add a low score today showing fatigue (e.g. 48kg vs 60kg baseline = 80%)
      await providerWithHistory.addDynamometerEntry(
        leftHandKg: 46,
        rightHandKg: 48,
        notes: 'Post heavy pulls',
      );

      expect(providerWithHistory.cnsReadinessPercent, lessThan(90));
      expect(providerWithHistory.cnsStatusText, anyOf(contains('Neuromuscular'), contains('CNS Fatigue')));
    });

    test('Records hang session, detects PR, and calculates goal ratios', () async {
      // First hang: 60s twoHand
      final HangSessionLog log1 = await gripHangProvider.recordHangSession(
        mode: HangMode.twoHand,
        style: HangStyle.activeScapular,
        durationSeconds: 60,
      );

      expect(log1.isPersonalRecord, isTrue);
      expect(gripHangProvider.bestTwoHandSeconds, equals(60));
      // Goal is 300s: 60 / 300 = 0.20
      expect(gripHangProvider.twoHandGoalProgressRatio, closeTo(0.20, 0.01));

      // Second hang: 90s twoHand (new PR)
      final HangSessionLog log2 = await gripHangProvider.recordHangSession(
        mode: HangMode.twoHand,
        style: HangStyle.activeScapular,
        durationSeconds: 90,
      );

      expect(log2.isPersonalRecord, isTrue);
      expect(gripHangProvider.bestTwoHandSeconds, equals(90));
      expect(gripHangProvider.twoHandGoalProgressRatio, closeTo(0.30, 0.01));

      // Third hang: 70s twoHand (NOT a PR)
      final HangSessionLog log3 = await gripHangProvider.recordHangSession(
        mode: HangMode.twoHand,
        style: HangStyle.passiveDecompression,
        durationSeconds: 70,
      );

      expect(log3.isPersonalRecord, isFalse);
      expect(gripHangProvider.bestTwoHandSeconds, equals(90));

      // Test Single-Hand Left (Goal 120s)
      final HangSessionLog leftLog = await gripHangProvider.recordHangSession(
        mode: HangMode.singleHandLeft,
        style: HangStyle.activeScapular,
        durationSeconds: 30,
      );
      expect(leftLog.isPersonalRecord, isTrue);
      expect(gripHangProvider.bestLeftHandSeconds, equals(30));
      // 30 / 120 = 0.25
      expect(gripHangProvider.leftHandGoalProgressRatio, closeTo(0.25, 0.01));
    });

    test('Controls live hang stopwatch timer lifecycle', () {
      gripHangProvider.startHangTimer(
        mode: HangMode.singleHandRight,
      );

      expect(gripHangProvider.isHangTimerRunning, isTrue);
      expect(gripHangProvider.currentHangMode, equals(HangMode.singleHandRight));

      final int stoppedSeconds = gripHangProvider.stopHangTimer();
      expect(gripHangProvider.isHangTimerRunning, isFalse);
      expect(stoppedSeconds, equals(0));

      gripHangProvider.resetHangTimer();
      expect(gripHangProvider.currentHangSeconds, equals(0));
    });
  });
}
