import 'dart:async';

import 'package:audio_session/audio_session.dart' as session_pkg;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Distinctive notification and alert sound profiles engineered for OLY
enum OlySoundTone {
  platformChime(
    'oly_platform_chime',
    'sounds/oly_platform_chime.wav',
    'oly_platform_chime.caf',
    'Platform Chime',
    'Barbell metallic attack + ascending fifth (587Hz -> 880Hz)',
  ),
  chronoPulse(
    'oly_chrono_pulse',
    'sounds/oly_chrono_pulse.wav',
    'oly_chrono_pulse.caf',
    'Arena Pulse',
    'High-octane dual pulse (784Hz -> 1046Hz) for WODs and intervals',
  ),
  ironGong(
    'oly_iron_gong',
    'sounds/oly_iron_gong.wav',
    'oly_iron_gong.caf',
    'Iron Gong',
    'Deep competition bumper steel resonance (330Hz) with warm decay',
  ),
  legacyBeep(
    'timer_beep',
    'sounds/timer_beep.wav',
    'default',
    'Classic Beep',
    'Original electronic rest timer tone',
  );

  new(
    this.id,
    this.assetPath,
    this.iosSound,
    this.label,
    this.description,
  );

  final String id;
  final String assetPath;
  final String iosSound;
  final String label;
  final String description;

  static OlySoundTone fromId(String? id) {
    return OlySoundTone.values.firstWhere(
      (e) => e.id == id,
      orElse: () => OlySoundTone.platformChime,
    );
  }
}

class NotificationService {
  factory() => _instance;
  new _internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  ap.AudioPlayer? _audioPlayer;
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
            usage: session_pkg.AndroidAudioUsage.alarm,
          ),
          androidAudioFocusGainType:
              session_pkg.AndroidAudioFocusGainType.gainTransient,
          androidWillPauseWhenDucked: true,
        ),
      );

    } catch (e) {
      debugPrint('AudioSession init error: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
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
  /// Play signature Olympic Platform Chime (Rest timer 0s, platform approach)
  Future<void> playPlatformChime() => playSound(OlySoundTone.platformChime);

  /// Play Chrono Arena Pulse (WOD intervals, C25K pace shifts, and countdowns)
  Future<void> playChronoPulse() => playSound(OlySoundTone.chronoPulse);

  /// Play Iron Plate Gong (Breath retention, hydration, and fasting milestones)
  Future<void> playIronGong() => playSound(OlySoundTone.ironGong);

  /// Play audio alert safely while pausing external audio and resuming it.
  Future<void> playTimerBeepSound({OlySoundTone tone = OlySoundTone.platformChime}) async {
    await playSound(tone);
  }

  /// Play any [OlySoundTone] safely with audio session ducking
  Future<void> playSound(OlySoundTone tone) async {
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

      if (_audioPlayer == null) {
        _audioPlayer = ap.AudioPlayer();
        await _audioPlayer!.setAudioContext(
          ap.AudioContext(
            iOS: ap.AudioContextIOS(
              options: const <ap.AVAudioSessionOptions>{
                ap.AVAudioSessionOptions.duckOthers,
              },
            ),
            android: const ap.AudioContextAndroid(
              usageType: ap.AndroidUsageType.alarm,
              contentType: ap.AndroidContentType.sonification,
              audioFocus: ap.AndroidAudioFocus.gainTransient,
            ),
          ),
        );
      }
      await _audioPlayer!.stop();

      // Set up completion handler to deactivate audio session with notifyOthersOnDeactivation
      final Completer<void> completer = Completer<void>();
      _playerCompleteSubscription = _audioPlayer!.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Safety timeout in case onPlayerComplete is delayed or dropped (all files < 1.8s)
      _sessionDeactivationTimer = Timer(const Duration(milliseconds: 2200), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      unawaited(
        completer.future.then((_) async {
          await _deactivateAudioSession();
        }),
      );

      await _audioPlayer!.play(ap.AssetSource(tone.assetPath));
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

  // --- FASTING & HYDRATION REMINDERS ---

  static const List<int> _hydrationNotificationIds = <int>[701, 702, 703, 704, 705, 706];
  static const List<int> _coffeeNotificationIds = <int>[751, 752, 753];

  /// Schedule paced water notifications across waking hours to reach the daily target
  Future<void> scheduleFastingHydrationReminders({
    required int dailyTargetMl,
    int wakeHour = 4,
    int wakeMinute = 45,
    bool isTrainingDay = false,
    bool isDeepKetosis = false,
  }) async {
    await init();
    await cancelHydrationReminders();

    final int portionMl = (dailyTargetMl / 6).round();
    final List<Map<String, dynamic>> scheduleTimes = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 701,
        'hour': 5,
        'minute': 0,
        'title': '💧 Morning Hydration Primer ($portionMl mL)',
        'body': isTrainingDay
            ? 'Drink $portionMl mL water + salt to restore plasma volume before your 6 AM platform lift.'
            : 'Drink $portionMl mL water + a pinch of salt to kickstart circadian hydration.',
      },
      <String, dynamic>{
        'id': 702,
        'hour': 7,
        'minute': 30,
        'title': '💧 Post-Lift Rehydration ($portionMl mL)',
        'body': isTrainingDay
            ? 'Refill with $portionMl mL water. Training day surcharge to rehydrate muscle tissue after lifting.'
            : 'Drink $portionMl mL water to maintain intracellular hydration.',
      },
      <String, dynamic>{
        'id': 703,
        'hour': 10,
        'minute': 0,
        'title': '💧 Mid-Morning Hydration Check ($portionMl mL)',
        'body':
            'Pacing towards your $dailyTargetMl mL goal. Drink $portionMl mL cool or sparkling water.',
      },
      <String, dynamic>{
        'id': 704,
        'hour': 12,
        'minute': 30,
        'title': '💧 Midday Cellular Hydration ($portionMl mL)',
        'body': isDeepKetosis
            ? 'Deep ketosis natriuresis active. Drink $portionMl mL water + minerals to sustain energy.'
            : 'Keep electrolytes and fluid balanced during your fast. $portionMl mL target.',
      },
      <String, dynamic>{
        'id': 705,
        'hour': 15,
        'minute': 30,
        'title': '💧 Afternoon Metabolic Hydration ($portionMl mL)',
        'body':
            'Afternoon slump? Salted water boosts alertness and blunts appetite.',
      },
      <String, dynamic>{
        'id': 706,
        'hour': 18,
        'minute': 0,
        'title': '💧 Final Evening Hydration ($portionMl mL)',
        'body':
            'Last water target before night. Finish hydration by 6:30 PM for uninterrupted sleep.',
      },
    ];

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'oly_hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Paced hydration reminders to hit daily water goal',
      sound: RawResourceAndroidNotificationSound('oly_iron_gong'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      sound: 'oly_iron_gong.caf',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (final Map<String, dynamic> item in scheduleTimes) {
      try {
        final int id = item['id'] as int;
        final int hour = item['hour'] as int;
        final int minute = item['minute'] as int;
        final String title = item['title'] as String;
        final String body = item['body'] as String;

        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('Error scheduling hydration alert: $e');
      }
    }
  }

  Future<void> cancelHydrationReminders() async {
    for (final int id in _hydrationNotificationIds) {
      try {
        await _notifications.cancel(id);
      } catch (_) {}
    }
  }

  /// Schedule strategic fasting coffee & caffeine reminders
  Future<void> scheduleFastingCoffeeReminders() async {
    await init();
    await cancelCoffeeReminders();

    final List<Map<String, dynamic>> coffeeReminders = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 751,
        'hour': 5,
        'minute': 15,
        'title': '☕ 5:15 AM Pre-Workout Platform Primer',
        'body': 'Black coffee + 600mg salt spikes free fatty acid mobilization 45m before your 6:00 AM lift.',
      },
      <String, dynamic>{
        'id': 752,
        'hour': 9,
        'minute': 30,
        'title': '☕ 9:30 AM Fasting Bridge (Ghrelin Shield)',
        'body': 'Mid-morning hunger wave? Black coffee or green tea stimulates peptide YY to blunt appetite.',
      },
      <String, dynamic>{
        'id': 753,
        'hour': 12,
        'minute': 0,
        'title': '🛑 12:00 PM Caffeine Curfew',
        'body': 'Last call for coffee! Shutting down caffeine now clears adenosine for your 8:45 PM bedtime and deep HRV.',
      },
    ];

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'oly_coffee_channel',
      'Fasting Coffee Alerts',
      channelDescription: 'Strategic coffee timing to assist fasting & athletic sleep',
      sound: RawResourceAndroidNotificationSound('oly_iron_gong'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      sound: 'oly_iron_gong.caf',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (final Map<String, dynamic> item in coffeeReminders) {
      try {
        final int id = item['id'] as int;
        final int hour = item['hour'] as int;
        final int minute = item['minute'] as int;
        final String title = item['title'] as String;
        final String body = item['body'] as String;

        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('Error scheduling coffee alert: $e');
      }
    }
  }

  Future<void> cancelCoffeeReminders() async {
    for (final int id in _coffeeNotificationIds) {
      try {
        await _notifications.cancel(id);
      } catch (_) {}
    }
  }

  /// Trigger prominent haptic feedback loop on iOS & Android
  Future<void> triggerIntenseVibration() async {
    try {
      for (int i = 0; i < 4; i++) {
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
}
