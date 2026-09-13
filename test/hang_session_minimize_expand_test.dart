import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActiveSessionProvider activeSession;
  late GripHangProvider gripHang;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final StorageService storageService = StorageService(prefs);
    final NotificationService notificationService = NotificationService();

    activeSession = ActiveSessionProvider(
      notificationService: notificationService,
    );

    gripHang = GripHangProvider(
      storageService,
      notificationService: notificationService,
    );
  });

  tearDown(() {
    gripHang.stopHangTimer();
    activeSession.endSession();
  });

  group('Active Hang & Session Lifecycle Integrity', () {
    test('Embedded hang updates progress without overwriting SessionType.workout', () {
      // 1. Simulate active workout session initialized
      activeSession.startSession(
        sessionTitle: 'Week 1 Day 1',
        currentExercise: 'Snatch',
        dayNumber: 1,
        weekNumber: 1,
      );

      expect(activeSession.sessionType, SessionType.workout);
      expect(activeSession.dayNumber, 1);
      expect(activeSession.sessionTitle, 'Week 1 Day 1');

      // 2. Simulate starting hang from inside the daily workout
      activeSession.registerEndSessionCallback(gripHang.resetHangTimer);
      activeSession.updateHangProgress(
        modeLabel: HangMode.twoHand.displayName,
        durationSeconds: 15,
        targetSeconds: 300,
      );

      // Session type and workout identity must remain intact
      expect(activeSession.sessionType, SessionType.workout);
      expect(activeSession.dayNumber, 1);
      expect(activeSession.sessionTitle, 'Week 1 Day 1');
      expect(activeSession.currentSetInfo, contains('00:15 / 05:00'));
    });

    test('GripHangProvider clean timer lifecycle and callback execution', () {
      int tickCount = 0;
      gripHang.startHangTimer(
        mode: HangMode.singleHandRight,
        style: HangStyle.passiveDecompression,
        onTick: (secs) {
          tickCount = secs;
        },
      );

      expect(tickCount, 0);
      expect(gripHang.isHangTimerRunning, isTrue);

      final int duration = gripHang.stopHangTimer();
      expect(gripHang.isHangTimerRunning, isFalse);
      expect(duration, 0);

      gripHang.resetHangTimer();
      expect(gripHang.currentHangSeconds, 0);
      expect(gripHang.isHangTimerRunning, isFalse);
    });

    test('ActiveSessionProvider endSession cleans up registered subsystem timers', () {
      bool cleanupInvoked = false;
      activeSession.registerEndSessionCallback(() {
        cleanupInvoked = true;
      });

      gripHang.startHangTimer();
      expect(gripHang.isHangTimerRunning, isTrue);

      activeSession.registerEndSessionCallback(gripHang.resetHangTimer);

      activeSession.endSession();

      expect(cleanupInvoked, isTrue);
      expect(gripHang.isHangTimerRunning, isFalse);
      expect(activeSession.isActive, isFalse);
      expect(activeSession.isRestTimerRunning, isFalse);
    });
  });
}
