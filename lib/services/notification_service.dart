import 'dart:async';

import 'package:audio_session/audio_session.dart' as session_pkg;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/deep_link_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'oly_hydration_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_log_water',
              '💧 Quick Log',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_open_fuel',
              'Open Fuel',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'oly_coffee_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_log_coffee',
              '☕ Log Coffee (240 mL)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_open_fasting',
              'Open Fasting',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'oly_gtg_pullup_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_log_gtg_reps',
              '💪 Log Reps',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_open_gtg',
              'Open GtG Hub',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'oly_gtg_hang_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_log_gtg_hang',
              '🧗 Log Hang',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_start_gtg_hang',
              '⏱️ Start Hang',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'oly_gtg_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_log_gtg_reps',
              '💪 Log Reps',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_log_gtg_hang',
              '🧗 Log Hang',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_start_gtg_hang',
              '⏱️ Start Hang',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'oly_rest_timer_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_add_rest_30s',
              '⏱️ +30s Rest',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_workout_ready',
              '⚡ Ready to Lift',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'oly_breathwork_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'action_start_breathwork',
              '🌬️ Start Breathwork',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'action_open_recover',
              'Open Recover',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          AppLogService.instance.info(
            'NOTIFICATION',
            'Notification tapped: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
          );
          debugPrint(
            'Notification tapped: id=${response.id}, actionId=${response.actionId}, payload=${response.payload}',
          );
          if (response.payload != null && response.payload!.isNotEmpty) {
            DeepLinkCoordinator.instance.handlePayload(
              response.payload!,
              actionId: response.actionId,
            );
          }
        },
      );

      // Check if app was launched directly from tapping a notification (Cold Start)
      final NotificationAppLaunchDetails? launchDetails =
          await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final NotificationResponse? response =
            launchDetails.notificationResponse;
        if (response != null &&
            response.payload != null &&
            response.payload!.isNotEmpty) {
          AppLogService.instance.info(
            'NOTIFICATION',
            'App launched from notification cold start: ${response.payload} (action: ${response.actionId})',
          );
          debugPrint(
            'App launched from notification cold start: ${response.payload}',
          );
          DeepLinkCoordinator.instance.handlePayload(
            response.payload!,
            actionId: response.actionId,
          );
        }
      }

      // Request explicit permissions on iOS to ensure banner, sound, and badge are allowed
      try {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        debugPrint('Error requesting iOS notification permissions: $e');
      }

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
    OlySoundTone? tone,
  }) async {
    await init();
    await cancelTimerNotification();

    if (secondsRemaining <= 0) {
      return;
    }

    OlySoundTone resolvedTone = tone ?? OlySoundTone.platformChime;
    if (tone == null) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? savedId = prefs.getString('oly_sound_tone_v1');
        resolvedTone = OlySoundTone.fromId(savedId);
      } catch (_) {}
    }

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: secondsRemaining));

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'oly_rest_timer',
            'Rest Timer Alerts',
            channelDescription: 'Alarm alerts when rest timer reaches 0s',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(resolvedTone.id),
            actions: const <AndroidNotificationAction>[
              AndroidNotificationAction(
                'action_add_rest_30s',
                '⏱️ +30s Rest',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'action_workout_ready',
                '⚡ Ready to Lift',
                showsUserInterface: true,
              ),
            ],
          );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: resolvedTone.iosSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_rest_timer_category',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        888,
        title,
        body,
        scheduledDate,
        details,
        payload: 'oly://workout/active?restComplete=true',
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
  static const List<int> _gtgNotificationIds = <int>[
    801, 802, 803, 804, 805, 806, 807, 808, 809, 810, 811, 812
  ];

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
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_log_water',
          '💧 Quick Log',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_open_fuel',
          'Open Fuel',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      sound: 'oly_iron_gong.caf',
      categoryIdentifier: 'oly_hydration_category',
      interruptionLevel: InterruptionLevel.timeSensitive,
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
          payload: 'oly://fuel/water?amount=$portionMl&slot=$id',
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
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_log_coffee',
          '☕ Log Coffee (240 mL)',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_open_fasting',
          'Open Fasting',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      sound: 'oly_iron_gong.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'oly_coffee_category',
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
          payload: 'oly://fuel/fasting?slot=$id',
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

  // --- GREASE THE GROOVE (GTG) INTERVAL REMINDERS ---

  /// Schedule periodic Grease the Groove reminders across waking hours
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
    await init();
    await cancelGtgReminders();

    final List<Map<String, dynamic>> slots = <Map<String, dynamic>>[];
    int currentTotalMinutes = startHour * 60 + startMinute;
    final int endTotalMinutes = endHour * 60 + endMinute;
    int idIndex = 0;

    while (currentTotalMinutes <= endTotalMinutes &&
        idIndex < _gtgNotificationIds.length) {
      final int hour = currentTotalMinutes ~/ 60;
      final int minute = currentTotalMinutes % 60;
      final int notifId = _gtgNotificationIds[idIndex];

      final bool isHangFocus = idIndex.isEven;
      final String title = isHangFocus
          ? '🧗 GtG: Active Scapular Hang ($targetHangSeconds s)'
          : '💪 GtG: Submax Pull-Ups ($targetPullUpReps reps)';
      final String body = isHangFocus
          ? 'Depress scapulae down with a slight elbow bend for tendon armor. Accumulate volume without fatigue.'
          : 'Knock out $targetPullUpReps crisp, strict pull-ups. Stop well shy of failure to build neural power.';

      final String payload = isHangFocus
          ? 'oly://gtg/hang?target=$targetHangSeconds'
          : 'oly://gtg/pullups?reps=$targetPullUpReps';

      slots.add(<String, dynamic>{
        'id': notifId,
        'hour': hour,
        'minute': minute,
        'title': title,
        'body': body,
        'payload': payload,
        'isHangFocus': isHangFocus,
      });

      idIndex++;
      currentTotalMinutes += intervalMinutes;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (final Map<String, dynamic> slot in slots) {
      try {
        final int id = slot['id'] as int;
        final int hour = slot['hour'] as int;
        final int minute = slot['minute'] as int;
        final String title = slot['title'] as String;
        final String body = slot['body'] as String;
        final String payload = slot['payload'] as String;
        final bool isHang = slot['isHangFocus'] as bool? ?? false;

        final NotificationDetails details = NotificationDetails(
          android: AndroidNotificationDetails(
            'oly_gtg_channel',
            'Grease the Groove Reminders',
            channelDescription:
                'Paced submaximal active hang and pull-up interval prompts',
            sound: const RawResourceAndroidNotificationSound('oly_chrono_pulse'),
            importance: Importance.high,
            priority: Priority.high,
            actions: isHang
                ? const <AndroidNotificationAction>[
                    AndroidNotificationAction(
                      'action_log_gtg_hang',
                      '🧗 Log Hang',
                      showsUserInterface: true,
                    ),
                    AndroidNotificationAction(
                      'action_start_gtg_hang',
                      '⏱️ Start Hang',
                      showsUserInterface: true,
                    ),
                  ]
                : const <AndroidNotificationAction>[
                    AndroidNotificationAction(
                      'action_log_gtg_reps',
                      '💪 Log Reps',
                      showsUserInterface: true,
                    ),
                    AndroidNotificationAction(
                      'action_open_gtg',
                      'Open GtG Hub',
                      showsUserInterface: true,
                    ),
                  ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: false,
            sound: 'oly_chrono_pulse.caf',
            interruptionLevel: InterruptionLevel.timeSensitive,
            categoryIdentifier: isHang
                ? 'oly_gtg_hang_category'
                : 'oly_gtg_pullup_category',
          ),
        );

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
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error scheduling GtG alert: $e');
        }
      }
    }
  }

  Future<void> cancelGtgReminders() async {
    for (final int id in _gtgNotificationIds) {
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

  // --- IMMEDIATE 5-SECOND TEST NOTIFICATIONS ---

  /// Test Circadian Hydration Notification (739 mL)
  Future<void> scheduleTestHydrationNotification() async {
    await init();
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'oly_hydration_channel',
        'Hydration Reminders',
        channelDescription: 'Paced hydration reminders to hit daily water goal',
        sound: RawResourceAndroidNotificationSound('oly_iron_gong'),
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_log_water',
            '💧 Quick Log',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_open_fuel',
            'Open Fuel',
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'oly_iron_gong.caf',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_hydration_category',
      );

      await _notifications.zonedSchedule(
        999,
        '💧 Test Hydration Alert (739 mL)',
        'Lock screen test! Long-press this banner for Quick Actions or tap to open Fuel.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'oly://fuel/water?amount=739&slot=test_water',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling test hydration notification: $e');
    }
  }

  /// Legacy alias for scheduleTestHydrationNotification
  Future<void> scheduleTestLockScreenNotification() =>
      scheduleTestHydrationNotification();

  /// Test Rest Timer Over Notification (with +30s Rest & Ready to Lift)
  Future<void> scheduleTestRestTimerNotification() async {
    await init();
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      OlySoundTone tone = OlySoundTone.platformChime;
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? savedId = prefs.getString('oly_sound_tone_v1');
        tone = OlySoundTone.fromId(savedId);
      } catch (_) {}

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'oly_rest_timer',
        'Rest Timer Alerts',
        channelDescription: 'Alarm alerts when rest timer reaches 0s',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(tone.id),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_add_rest_30s',
            '⏱️ +30s Rest',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_workout_ready',
            '⚡ Ready to Lift',
            showsUserInterface: true,
          ),
        ],
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: tone.iosSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_rest_timer_category',
      );

      await _notifications.zonedSchedule(
        998,
        '⏰ Rest Over: Platform Ready!',
        'Rest interval complete. Long-press to add +30s rest or tap to resume workout.',
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'oly://workout/active?restComplete=true',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling test rest timer notification: $e');
    }
  }

  /// Test Fasting Coffee Primer Notification (with Quick Log & Open Fasting)
  Future<void> scheduleTestCoffeeNotification() async {
    await init();
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'oly_coffee_channel',
        'Fasting Coffee Alerts',
        channelDescription: 'Strategic coffee timing to assist fasting & athletic sleep',
        sound: RawResourceAndroidNotificationSound('oly_iron_gong'),
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_log_coffee',
            '☕ Log Coffee (240 mL)',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_open_fasting',
            'Open Fasting',
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'oly_iron_gong.caf',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_coffee_category',
      );

      await _notifications.zonedSchedule(
        997,
        '☕ Fasting Coffee Primer (240 mL)',
        'Pre-workout caffeine mobilization window. Long-press to quick-log 240 mL coffee.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'oly://fuel/fasting?slot=test_coffee',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling test coffee notification: $e');
    }
  }

  /// Test GtG Submax Pull-Ups Notification (with Quick Log Reps & Open GtG)
  Future<void> scheduleTestGtgPullUpNotification() async {
    await init();
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'oly_gtg_channel',
        'Grease the Groove Reminders',
        channelDescription: 'Paced submaximal active hang and pull-up interval prompts',
        sound: RawResourceAndroidNotificationSound('oly_chrono_pulse'),
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_log_gtg_reps',
            '💪 Log Reps',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_open_gtg',
            'Open GtG Hub',
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'oly_chrono_pulse.caf',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_gtg_pullup_category',
      );

      await _notifications.zonedSchedule(
        996,
        '💪 GtG: Submax Pull-Ups (5 Reps)',
        'Neural drive prompt. Long-press to quick-log 5 pull-ups or tap to open GtG Hub.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'oly://gtg/pullups?reps=5',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling test GtG pull-up notification: $e');
    }
  }

  /// Test GtG Active Scapular Hang Notification (with Quick Log Hang & Start Hang)
  Future<void> scheduleTestGtgHangNotification() async {
    await init();
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'oly_gtg_channel',
        'Grease the Groove Reminders',
        channelDescription: 'Paced submaximal active hang and pull-up interval prompts',
        sound: RawResourceAndroidNotificationSound('oly_chrono_pulse'),
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_log_gtg_hang',
            '🧗 Log Hang',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_start_gtg_hang',
            '⏱️ Start Hang',
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'oly_chrono_pulse.caf',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_gtg_hang_category',
      );

      await _notifications.zonedSchedule(
        995,
        '🧗 GtG: Active Scapular Hang (45s)',
        'Scapular retraction interval. Long-press to quick-log 45s or start hang timer.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'oly://gtg/hang?target=45',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling test GtG hang notification: $e');
    }
  }

  /// Test Wim Hof Breathwork Notification (with Start Breathwork & Open Recover)
  Future<void> scheduleTestBreathworkNotification() async {
    await init();
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'oly_breathwork_channel',
        'Breathwork Reminders',
        channelDescription: 'Guided Wim Hof and parasympathetic breath resets',
        sound: RawResourceAndroidNotificationSound('oly_platform_chime'),
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_start_breathwork',
            '🌬️ Start Breathwork',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_open_recover',
            'Open Recover',
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'oly_platform_chime.caf',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'oly_breathwork_category',
      );

      await _notifications.zonedSchedule(
        994,
        '🌬️ Wim Hof Breathwork Reset',
        'Parasympathetic recovery flow. Long-press to start guided breathwork session.',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'oly://recover/breathwork',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling test breathwork notification: $e');
    }
  }
}
