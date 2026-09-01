import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/flutter_timezone'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getLocalTimezone') {
          return 'America/New_York';
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async {
        return true;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async {
        return 1;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async {
        return 1;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/flutter_timezone'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      null,
    );
  });

  group('NotificationService Audio & Notification Tests', () {
    test('NotificationService singleton returns identical instance', () {
      final NotificationService instance1 = NotificationService();
      final NotificationService instance2 = NotificationService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('NotificationService initializes audio session and notifications cleanly', () async {
      final NotificationService service = NotificationService();
      await service.init();
      // Should not throw on repeated init calls
      await service.init();
    });

    test('playTimerBeepSound executes without throwing', () async {
      final NotificationService service = NotificationService();
      await service.init();
      await service.playTimerBeepSound();
    });

    test('scheduleTimerNotification schedules or cancels safely', () async {
      final NotificationService service = NotificationService();
      await service.scheduleTimerNotification(
        secondsRemaining: 60,
        title: 'Rest Over',
        body: 'Time to start next set',
      );
      await service.cancelTimerNotification();
    });

    test('scheduleTimerNotification skips when secondsRemaining <= 0', () async {
      final NotificationService service = NotificationService();
      await service.scheduleTimerNotification(
        secondsRemaining: 0,
        title: 'Zero timer',
        body: 'Should skip',
      );
    });

    test('triggerIntenseVibration executes safely', () async {
      final NotificationService service = NotificationService();
      await service.triggerIntenseVibration();
    });
  });
}
