import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/breathing_analytics_tab.dart';
import 'package:oly/views/breathing/wim_hof_session_screen.dart';
import 'package:oly/views/breathing/wim_hof_setup_sheet.dart';
import 'package:oly/views/breathing/wim_hof_summary_screen.dart';
import 'package:provider/provider.dart';

import 'utils/mock_data_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late BreathingProvider breathingProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    breathingProvider = BreathingProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: breathingProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Wim Hof Models & Provider Unit Tests', () {
    test('BreathingSessionLog calculates max, avg, and total hold times accurately', () {
      final BreathingSessionLog session = BreathingSessionLog(
        id: 'test_sess_1',
        date: DateTime.now(),
        totalRounds: 3,
        rounds: <BreathingRoundLog>[
          BreathingRoundLog(
            roundNumber: 1,
            breathsCount: 30,
            retentionSeconds: 60,
            recoverySeconds: 15,
          ),
          BreathingRoundLog(
            roundNumber: 2,
            breathsCount: 30,
            retentionSeconds: 90,
            recoverySeconds: 15,
          ),
          BreathingRoundLog(
            roundNumber: 3,
            breathsCount: 30,
            retentionSeconds: 120,
            recoverySeconds: 15,
          ),
        ],
      );

      expect(session.maxHoldSeconds, 120);
      expect(session.avgHoldSeconds, 90);
      expect(session.totalHoldSeconds, 270);
      expect(session.formattedMaxHold, '02:00');
      expect(session.formattedAvgHold, '01:30');
      expect(session.formattedTotalHold, '04:30');
    });

    test('BreathingSessionLog JSON encode and decode preserves all fields', () {
      final BreathingSessionLog original = BreathingSessionLog(
        id: 'json_test_sess',
        date: DateTime(2026, 8, 29, 21, 0, 0),
        totalRounds: 2,
        readinessRating: 5,
        notes: 'Great flow!',
        rounds: <BreathingRoundLog>[
          BreathingRoundLog(
            roundNumber: 1,
            breathsCount: 30,
            retentionSeconds: 85,
            recoverySeconds: 15,
          ),
          BreathingRoundLog(
            roundNumber: 2,
            breathsCount: 30,
            retentionSeconds: 115,
            recoverySeconds: 15,
          ),
        ],
      );

      final Map<String, dynamic> jsonMap = original.toJson();
      final BreathingSessionLog decoded = BreathingSessionLog.fromJson(jsonMap);

      expect(decoded.id, original.id);
      expect(decoded.totalRounds, 2);
      expect(decoded.readinessRating, 5);
      expect(decoded.notes, 'Great flow!');
      expect(decoded.rounds.length, 2);
      expect(decoded.rounds.first.retentionSeconds, 85);
      expect(decoded.rounds.last.retentionSeconds, 115);
      expect(decoded.maxHoldSeconds, 115);
    });

    test('WimHofConfig cycle pacing calculations are correct', () {
      const WimHofConfig relaxed = WimHofConfig(pace: BreathingPace.relaxed);
      expect(relaxed.cycleDurationSeconds, 4.5);
      expect(relaxed.inhaleDurationSeconds, 2.7);
      expect(relaxed.exhaleDurationSeconds, 1.8);

      const WimHofConfig normal = WimHofConfig(pace: BreathingPace.normal);
      expect(normal.cycleDurationSeconds, 3.5);

      const WimHofConfig fast = WimHofConfig(pace: BreathingPace.fast);
      expect(fast.cycleDurationSeconds, 2.5);
    });

    test('BreathingProvider aggregations and PR detection work as expected', () async {
      expect(breathingProvider.totalSessionsCompleted, 2);
      expect(breathingProvider.totalRoundsCompleted, 7);
      expect(breathingProvider.allTimeMaxHoldSeconds, 165); // 2m 45s
      expect(breathingProvider.formattedAllTimeMaxHold, '02:45');

      expect(breathingProvider.isNewPR(160), isFalse);
      expect(breathingProvider.isNewPR(180), isTrue);

      final Map<int, double> roundAverages = breathingProvider.roundAveragesMap;
      expect(roundAverages.containsKey(1), isTrue);
      expect(roundAverages[1], (75 + 90) / 2.0); // 82.5s
      expect(roundAverages[2], (105 + 120) / 2.0); // 112.5s

      // Save a new session
      final BreathingSessionLog newSession = BreathingSessionLog(
        id: 'new_pr_sess',
        date: DateTime.now(),
        totalRounds: 1,
        rounds: <BreathingRoundLog>[
          BreathingRoundLog(
            roundNumber: 1,
            breathsCount: 30,
            retentionSeconds: 200, // New PR: 3m 20s
            recoverySeconds: 15,
          ),
        ],
      );

      await breathingProvider.saveSession(newSession);
      expect(breathingProvider.totalSessionsCompleted, 3);
      expect(breathingProvider.allTimeMaxHoldSeconds, 200);
      expect(breathingProvider.formattedAllTimeMaxHold, '03:20');
    });
  });

  group('Wim Hof Setup Sheet Widget Tests', () {
    testWidgets('Renders setup sheet with round stepper, breath count, and pace selectors', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const WimHofSetupSheet(),
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Wim Hof Breathwork'), findsOneWidget);
      expect(find.text('Guided Hyperventilation & Retention Flow'), findsOneWidget);
      expect(find.text('NUMBER OF ROUNDS'), findsOneWidget);
      expect(find.text('BREATHS PER ROUND'), findsOneWidget);
      expect(find.text('BREATHING PACE'), findsOneWidget);
      expect(find.text('START GUIDED BREATHWORK'), findsOneWidget);

      // Verify quick round selection chips (1, 3, 4, 5)
      expect(find.text('1 Round'), findsOneWidget);
      expect(find.text('3 Rounds'), findsOneWidget);
      expect(find.text('4 Rounds'), findsOneWidget);
      expect(find.text('5 Rounds'), findsOneWidget);

      // Tap 4 Rounds
      await tester.tap(find.text('4 Rounds'));
      await tester.pumpAndSettle();

      // Verify PR badge rendered from mock data
      expect(find.textContaining('All-Time Retention PR: 02:45'), findsOneWidget);
    });
  });

  group('Wim Hof Live Session Screen Widget Tests', () {
    testWidgets('Renders prep stage and advances to hyperventilation stage', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const WimHofConfig config = WimHofConfig(
        defaultRounds: 2,
        breathsPerRound: 20,
        soundEnabled: false,
        hapticsEnabled: false,
      );

      await tester.pumpWidget(
        buildTestWidget(const WimHofSessionScreen(config: config)),
      );
      await tester.pump();

      // Verify Prep stage
      expect(find.text('ROUND 1 OF 2'), findsOneWidget);
      expect(find.text('Get Ready'), findsOneWidget);
      expect(find.text('Round 1'), findsOneWidget);

      // Advance prep timer by 4 seconds to transition into hyperventilation
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      expect(find.text('Deep Rhythmic Breathing'), findsOneWidget);
      expect(find.text('BREATH 1 OF 20'), findsOneWidget);
      expect(find.text('FULLY IN...'), findsOneWidget);

      // Verify skip button
      expect(find.text('I\'M FULL • START RETENTION HOLD'), findsOneWidget);

      // Tap skip to transition to Retention hold immediately
      await tester.tap(find.text('I\'M FULL • START RETENTION HOLD'));
      await tester.pump();

      expect(find.text('Breath Retention (Exhale Hold)'), findsOneWidget);
      expect(find.text('RETENTION TIME'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('TAP TO INHALE (RECOVERY BREATH)'), findsOneWidget);

      // Advance retention stopwatch by 30 seconds
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('00:30'), findsOneWidget);

      // Tap to inhale and transition to recovery breath
      await tester.tap(find.text('TAP TO INHALE (RECOVERY BREATH)'));
      await tester.pump();

      expect(find.text('RECOVERY BREATH'), findsOneWidget);
      expect(find.text('Inhale fully to chest and hold for 15 seconds.'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('Wim Hof Summary Screen Widget Tests', () {
    testWidgets('Renders summary screen with round bars, stats, and star rating', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<BreathingRoundLog> testRounds = <BreathingRoundLog>[
        BreathingRoundLog(
          roundNumber: 1,
          breathsCount: 30,
          retentionSeconds: 80,
          recoverySeconds: 15,
        ),
        BreathingRoundLog(
          roundNumber: 2,
          breathsCount: 30,
          retentionSeconds: 125,
          recoverySeconds: 15,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          WimHofSummaryScreen(
            rounds: testRounds,
            config: const WimHofConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Breathwork Complete'), findsOneWidget);
      expect(find.text('2 Rounds Completed'), findsOneWidget);
      expect(find.text('LONGEST HOLD'), findsOneWidget);
      expect(find.text('02:05'), findsNWidgets(2)); // KPI card and Round 2 bar
      expect(find.text('TOTAL HOLD'), findsOneWidget);
      expect(find.text('03:25'), findsOneWidget); // 205s

      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('01:20'), findsOneWidget);
      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('BEST HOLD'), findsOneWidget);

      expect(find.text('LOG BREATHWORK SESSION'), findsOneWidget);

      // Tap Log Breathwork Session
      await tester.tap(find.text('LOG BREATHWORK SESSION'));
      await tester.pumpAndSettle();

      expect(breathingProvider.totalSessionsCompleted, 3);
    });
  });

  group('Breathing Analytics Tab Widget Tests', () {
    testWidgets('Renders KPI overview cards, retention trend chart, and session history', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(const BreathingAnalyticsTab()),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALL-TIME BREATHWORK TOTALS'), findsOneWidget);
      expect(find.text('Total Time in Retention / Breath Hold'), findsOneWidget);
      expect(find.text('RETENTION DURATION PROGRESSION'), findsOneWidget);
      expect(find.text('AVERAGE HOLD DURATION BY ROUND'), findsOneWidget);
      expect(find.text('BREATHWORK SESSION HISTORY'), findsOneWidget);

      // Verify mock data session cards rendered
      expect(find.text('4 Rounds'), findsOneWidget);
      expect(find.text('3 Rounds'), findsOneWidget);
      expect(find.text('“PR breath hold! Incredible focus.”'), findsOneWidget);
    });
  });
}
