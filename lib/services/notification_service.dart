import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    // Detect actual native device timezone with safe fallback
    try {
      tz.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('Timezone lookup fallback: $e');
      }
    } catch (e) {
      debugPrint('Timezone init error: $e');
    }

    // Configure AVAudioSession category once at app startup
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const <AVAudioSessionOptions>{
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (e) {
      debugPrint('AudioContext init error: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Play high-volume double-beep audio alert safely
  Future<void> playTimerBeepSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/timer_beep.wav'));
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  /// Schedule a native local notification for when the rest timer expires in [secondsRemaining]
  Future<void> scheduleTimerNotification({
    required int secondsRemaining,
    required String title,
    required String body,
  }) async {
    await init();
    await cancelTimerNotification();

    if (secondsRemaining <= 0) {
      return;
    }

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: secondsRemaining));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'oly_rest_timer',
            'Rest Timer Alerts',
            channelDescription: 'Alarm alerts when rest timer reaches 0s',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'default',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        888,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Cancel any pending scheduled timer notification
  Future<void> cancelTimerNotification() async {
    try {
      await _notifications.cancel(888);
    } catch (_) {}
  }

  /// Trigger prominent haptic feedback loop on iOS & Android
  Future<void> triggerIntenseVibration() async {
    try {
      for (int i = 0; i < 4; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
}
