import 'dart:async';

import 'package:audio_session/audio_session.dart' as session_pkg;
import 'package:audioplayers/audioplayers.dart' as ap;
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
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  bool _initialized = false;
  StreamSubscription<void>? _playerCompleteSubscription;
  Timer? _sessionDeactivationTimer;

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

    // Configure AudioSession & AudioPlayer: pause other audio during playback and resume after
    try {
      final session_pkg.AudioSession session =
          await session_pkg.AudioSession.instance;
      await session.configure(
        const session_pkg.AudioSessionConfiguration(
          avAudioSessionCategory: session_pkg.AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              session_pkg.AVAudioSessionCategoryOptions.none,
          avAudioSessionMode: session_pkg.AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              session_pkg.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              session_pkg.AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
          androidAudioAttributes: session_pkg.AndroidAudioAttributes(
            contentType: session_pkg.AndroidAudioContentType.sonification,
            flags: session_pkg.AndroidAudioFlags.none,
            usage: session_pkg.AndroidAudioUsage.alarm,
          ),
          androidAudioFocusGainType:
              session_pkg.AndroidAudioFocusGainType.gainTransient,
          androidWillPauseWhenDucked: true,
        ),
      );

      await _audioPlayer.setAudioContext(
        ap.AudioContext(
          iOS: ap.AudioContextIOS(
            category: ap.AVAudioSessionCategory.playback,
            options: const <ap.AVAudioSessionOptions>{},
          ),
          android: const ap.AudioContextAndroid(
            usageType: ap.AndroidUsageType.alarm,
            contentType: ap.AndroidContentType.sonification,
            audioFocus: ap.AndroidAudioFocus.gainTransient,
          ),
        ),
      );
    } catch (e) {
      debugPrint('AudioSession init error: $e');
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

  /// Play high-volume double-beep audio alert safely while pausing external audio
  /// and automatically resuming it at full original volume once playback completes.
  Future<void> playTimerBeepSound() async {
    try {
      _sessionDeactivationTimer?.cancel();
      await _playerCompleteSubscription?.cancel();

      // Activate audio session to pause external audio apps (Spotify, Apple Music, podcasts)
      try {
        final session_pkg.AudioSession session =
            await session_pkg.AudioSession.instance;
        await session.setActive(true);
      } catch (e) {
        debugPrint('AudioSession activate error: $e');
      }

      await _audioPlayer.stop();

      // Set up completion handler to deactivate audio session with notifyOthersOnDeactivation
      final Completer<void> completer = Completer<void>();
      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Safety timeout in case onPlayerComplete is delayed or dropped (timer_beep.wav is 1.2s)
      _sessionDeactivationTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      completer.future.then((_) async {
        await _deactivateAudioSession();
      });

      await _audioPlayer.play(ap.AssetSource('sounds/timer_beep.wav'));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      await _deactivateAudioSession();
    }
  }

  Future<void> _deactivateAudioSession() async {
    _sessionDeactivationTimer?.cancel();
    _sessionDeactivationTimer = null;
    await _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = null;

    try {
      final session_pkg.AudioSession session =
          await session_pkg.AudioSession.instance;
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions:
            session_pkg.AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (e) {
      debugPrint('AudioSession deactivate error: $e');
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
