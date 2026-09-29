import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/gtg_model.dart';
import 'package:oly/providers/gtg_provider.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationService extends Fake implements NotificationService {
  bool scheduled = false;
  bool cancelled = false;
  int? lastIntervalMinutes;
  bool? lastMicroElbowBend;

  @override
  Future<void> scheduleGtgReminders({
    required int intervalMinutes,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int targetPullUpReps,
    required int targetHangSeconds,
    bool microElbowBend = true,
  }) async {
    scheduled = true;
    cancelled = false;
    lastIntervalMinutes = intervalMinutes;
    lastMicroElbowBend = microElbowBend;
  }

  @override
  Future<void> cancelGtgReminders() async {
    cancelled = true;
    scheduled = false;
  }

  @override
  Future<void> playChronoPulse() async {}

  @override
  Future<void> playTimerBeepSound({OlySoundTone tone = OlySoundTone.platformChime}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Grease the Groove Domain Models', () {
    test('GtgConfig calculates optimal submaximal reps at 40-50% of 1RM max', () {
      const GtgConfig config12 = GtgConfig(pullUpMax: 12);
      expect(config12.calculatedSubmaxReps, equals(5)); // 12 * 0.45 = 5.4 -> 5

      const GtgConfig config20 = GtgConfig(pullUpMax: 20);
      expect(config20.calculatedSubmaxReps, equals(9)); // 20 * 0.45 = 9

      const GtgConfig config3 = GtgConfig(pullUpMax: 3);
      expect(config3.calculatedSubmaxReps, equals(1)); // 3 * 0.45 = 1.35 -> 1
    });

    test('GtgConfig defaults emphasize active scapula and micro-bend elbow tendons', () {
      const GtgConfig config = GtgConfig();
      expect(config.microElbowBendDefault, isTrue);
      expect(config.activeScapulaDefault, isTrue);
      expect(config.targetHangSeconds, equals(30));
      expect(config.targetPullUpReps, equals(4));
      expect(config.dailyPullUpGoal, equals(35));
      expect(config.dailyHangSecondsGoal, equals(180));
      expect(config.intervalMinutes, equals(90));
      expect(config.remindersEnabled, isTrue);
    });

    test('GtgConfig JSON serialization and deserialization roundtrip', () {
      const GtgConfig original = GtgConfig(
        pullUpMax: 15,
        targetPullUpReps: 6,
        targetHangSeconds: 45,
        dailyPullUpGoal: 50,
        dailyHangSecondsGoal: 300,
        intervalMinutes: 60,
        startHour: 8,
        startMinute: 30,
        endHour: 19,
        endMinute: 15,
        remindersEnabled: false,
        microElbowBendDefault: false,
        activeScapulaDefault: false,
        prepDelaySeconds: 10,
      );

      final Map<String, dynamic> json = original.toJson();
      final GtgConfig restored = GtgConfig.fromJson(json);

      expect(restored.pullUpMax, equals(15));
      expect(restored.targetPullUpReps, equals(6));
      expect(restored.targetHangSeconds, equals(45));
      expect(restored.dailyPullUpGoal, equals(50));
      expect(restored.dailyHangSecondsGoal, equals(300));
      expect(restored.intervalMinutes, equals(60));
      expect(restored.startHour, equals(8));
      expect(restored.startMinute, equals(30));
      expect(restored.endHour, equals(19));
      expect(restored.endMinute, equals(15));
      expect(restored.remindersEnabled, isFalse);
      expect(restored.microElbowBendDefault, isFalse);
      expect(restored.activeScapulaDefault, isFalse);
      expect(restored.prepDelaySeconds, equals(10));
    });

    test('GtgSetLog properly flags micro-bend elbow engagement and scapular retraction', () {
      final GtgSetLog hangLog = GtgSetLog.create(
        type: GtgExerciseType.activeHang,
        durationSeconds: 30,
        notes: 'Great elbow tendon isometric contraction',
      );

      expect(hangLog.type, equals(GtgExerciseType.activeHang));
      expect(hangLog.durationSeconds, equals(30));
      expect(hangLog.microElbowBendEngaged, isTrue);
      expect(hangLog.scapulaRetracted, isTrue);
      expect(hangLog.notes, contains('tendon'));

      final Map<String, dynamic> json = hangLog.toJson();
      final GtgSetLog restored = GtgSetLog.fromJson(json);
      expect(restored.id, equals(hangLog.id));
      expect(restored.type, equals(GtgExerciseType.activeHang));
      expect(restored.durationSeconds, equals(30));
      expect(restored.microElbowBendEngaged, isTrue);
      expect(restored.scapulaRetracted, isTrue);
    });
  });

  group('GtgProvider State & Operations', () {
    late StorageService storage;
    late MockNotificationService mockNotifications;
    late GtgProvider gtg;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      mockNotifications = MockNotificationService();
      gtg = GtgProvider(storage, notificationService: mockNotifications);
    });

    test('Initializes with default config and empty logs', () {
      expect(gtg.logs, isEmpty);
      expect(gtg.todayLogs, isEmpty);
      expect(gtg.todayPullUpReps, equals(0));
      expect(gtg.todayHangSeconds, equals(0));
      expect(gtg.pullUpProgressRatio, equals(0.0));
      expect(gtg.hangProgressRatio, equals(0.0));
      expect(gtg.currentStreakDays, equals(0));
      expect(gtg.config.microElbowBendDefault, isTrue);
    });

    test('Logs submaximal pull-up sets and calculates daily volume', () async {
      await gtg.logPullUpSet(reps: 4);
      await gtg.logPullUpSet(reps: 4);

      expect(gtg.logs.length, equals(2));
      expect(gtg.todayLogs.length, equals(2));
      expect(gtg.todayPullUpReps, equals(8));
      expect(gtg.todaySetsCount, equals(2));
      // 8 / 35 goal = ~0.2285
      expect(gtg.pullUpProgressRatio, closeTo(0.228, 0.01));
    });

    test('Logs active scapular hang sets with micro-bend elbow cues', () async {
      await gtg.logActiveHangSet(seconds: 30);
      await gtg.logActiveHangSet(seconds: 40);

      expect(gtg.logs.length, equals(2));
      expect(gtg.todayHangSeconds, equals(70));
      // 70 / 180 goal = ~0.3888
      expect(gtg.hangProgressRatio, closeTo(0.388, 0.01));
      expect(gtg.logs.first.microElbowBendEngaged, isTrue);
      expect(gtg.logs.first.scapulaRetracted, isTrue);
    });

    test('Deletes a set properly and recalculates metrics', () async {
      final GtgSetLog set1 = await gtg.logPullUpSet(reps: 5);
      await gtg.logPullUpSet(reps: 4);

      expect(gtg.todayPullUpReps, equals(9));

      await gtg.deleteSet(set1.id);
      expect(gtg.logs.length, equals(1));
      expect(gtg.todayPullUpReps, equals(4));
    });

    test('Updates config and schedules or cancels interval notifications', () async {
      final GtgConfig newConfig = gtg.config.copyWith(
        intervalMinutes: 60,
        remindersEnabled: true,
      );

      await gtg.updateConfig(newConfig);
      expect(mockNotifications.scheduled, isTrue);
      expect(mockNotifications.lastIntervalMinutes, equals(60));
      expect(mockNotifications.lastMicroElbowBend, isTrue);

      await gtg.toggleReminders(false);
      expect(mockNotifications.cancelled, isTrue);
      expect(gtg.config.remindersEnabled, isFalse);
    });

    test('setPullUpMax recalculates submax target reps automatically', () async {
      await gtg.setPullUpMax(14);
      // 14 * 0.45 = 6.3 -> 6
      expect(gtg.config.pullUpMax, equals(14));
      expect(gtg.config.targetPullUpReps, equals(6));
    });

    test('Calculates streak properly when sets are recorded', () async {
      await gtg.logActiveHangSet(seconds: 30);
      expect(gtg.currentStreakDays, equals(1));
    });

    test('Active hang timer starts prep countdown, skips prep, and pauses/resets', () {
      gtg.setHangTarget(45);
      expect(gtg.hangTargetSeconds, equals(45));
      expect(gtg.hangSecondsRemaining, equals(45));
      expect(gtg.prepDelaySeconds, equals(5));

      gtg.startActiveHangTimer();
      expect(gtg.isHangPrepCountdown, isTrue);
      expect(gtg.hangPrepSecondsRemaining, equals(5));
      expect(gtg.isHangTimerActive, isTrue);
      expect(gtg.isHangTimerRunning, isFalse);

      gtg.skipHangPrep();
      expect(gtg.isHangPrepCountdown, isFalse);
      expect(gtg.isHangTimerRunning, isTrue);

      gtg.pauseActiveHangTimer();
      expect(gtg.isHangTimerRunning, isFalse);

      gtg.resetActiveHangTimer();
      expect(gtg.hangSecondsRemaining, equals(45));
    });

    test('Active hang timer starts immediately when prepSeconds is 0', () {
      gtg.startActiveHangTimer(prepSeconds: 0);
      expect(gtg.isHangPrepCountdown, isFalse);
      expect(gtg.isHangTimerRunning, isTrue);
      gtg.resetActiveHangTimer();
    });

    test('Configures and persists prepDelaySeconds in GtgConfig', () async {
      await gtg.setPrepDelaySeconds(10);
      expect(gtg.prepDelaySeconds, equals(10));
      expect(gtg.config.prepDelaySeconds, equals(10));

      final GtgProvider reloaded = GtgProvider(storage);
      expect(reloaded.prepDelaySeconds, equals(10));
    });
  });
}
