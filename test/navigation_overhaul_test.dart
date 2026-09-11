import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/main.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/active_session_mini_dock.dart';
import 'package:oly/widgets/athlete_summary_overview_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/flutter_timezone'),
      (MethodCall methodCall) async {
        return 'America/New_York';
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
  });

  group('ActiveSessionProvider Unit Tests', () {
    test('Initial state is inactive and timer stopped', () {
      final ActiveSessionProvider provider = ActiveSessionProvider();
      expect(provider.isActive, isFalse);
      expect(provider.isMinimized, isFalse);
      expect(provider.isRestTimerRunning, isFalse);
      expect(provider.restSecondsRemaining, 0);
    });

    test('startSession sets metadata and notifies listeners', () {
      final ActiveSessionProvider provider = ActiveSessionProvider();
      provider.startSession(
        sessionTitle: 'Week 3, Day 1: Heavy Snatch',
        currentExercise: 'Snatch',
        currentSetInfo: 'Set 2 of 5 • 80kg',
        dayNumber: 1,
        weekNumber: 3,
      );

      expect(provider.isActive, isTrue);
      expect(provider.sessionTitle, 'Week 3, Day 1: Heavy Snatch');
      expect(provider.currentExercise, 'Snatch');
      expect(provider.currentSetInfo, 'Set 2 of 5 • 80kg');
      expect(provider.dayNumber, 1);
      expect(provider.weekNumber, 3);
    });

    test('minimize and maximize toggle isMinimized', () {
      final ActiveSessionProvider provider = ActiveSessionProvider();
      provider.startSession(sessionTitle: 'Test Session');
      expect(provider.isMinimized, isFalse);

      provider.minimizeSession();
      expect(provider.isMinimized, isTrue);

      provider.maximizeSession();
      expect(provider.isMinimized, isFalse);
    });

    test('startRestTimer sets time and running state', () {
      final ActiveSessionProvider provider = ActiveSessionProvider();
      provider.startRestTimer(seconds: 90);

      expect(provider.isRestTimerRunning, isTrue);
      expect(provider.restSecondsRemaining, 90);
      expect(provider.restTotalSeconds, 90);
      expect(provider.timerProgress, 1.0);
      expect(provider.formattedRestTime, '01:30');

      provider.pauseRestTimer();
      expect(provider.isRestTimerRunning, isFalse);
      expect(provider.restSecondsRemaining, 90);

      provider.adjustRestTimer(15);
      expect(provider.restSecondsRemaining, 105);

      provider.resetRestTimer();
      expect(provider.restSecondsRemaining, provider.restTotalSeconds);
      expect(provider.isRestTimerRunning, isFalse);

      provider.endSession();
      expect(provider.isActive, isFalse);
      expect(provider.restSecondsRemaining, 0);
    });

    test('preview mode state tracking', () {
      final ActiveSessionProvider provider = ActiveSessionProvider();
      expect(provider.isPreviewMode, isFalse);

      provider.startSession(
        sessionTitle: 'Snatch Technique',
        isPreviewMode: true,
      );
      expect(provider.isPreviewMode, isTrue);

      provider.setPreviewMode(false);
      expect(provider.isPreviewMode, isFalse);

      provider.setPreviewMode(true);
      expect(provider.isPreviewMode, isTrue);
    });

    test('mobility flow session tracking and progress update', () {
      final ActiveSessionProvider provider = ActiveSessionProvider();
      final GeneratedRecoveryRoutine routine = GeneratedRecoveryRoutine(
        phaseGroups: <RecoveryPhaseGroup>[],
        exercises: MobilityExerciseModel.defaultExercises().take(3).toList(),
        diagnosticReasons: <String>['Tightness in hip flexors'],
        totalEstimatedMinutes: 12,
      );

      provider.startSession(
        sessionType: SessionType.mobility,
        sessionTitle: 'Daily Recovery Protocol',
        currentExercise: routine.exercises.first.name,
        currentSetInfo: 'Step 1 of ${routine.exercises.length}',
        mobilityRoutine: routine,
      );

      expect(provider.isActive, isTrue);
      expect(provider.sessionType, SessionType.mobility);
      expect(provider.activeMobilityRoutine, routine);
      expect(provider.mobilityExerciseIndex, 0);
      expect(provider.completedMobilityIds, isEmpty);

      provider.updateMobilityProgress(
        exerciseIndex: 1,
        exerciseName: routine.exercises[1].name,
        completedIds: <String>{routine.exercises.first.id},
        totalExercises: routine.exercises.length,
      );

      expect(provider.mobilityExerciseIndex, 1);
      expect(
        provider.completedMobilityIds.contains(routine.exercises.first.id),
        isTrue,
      );
    });
  });

  group('MainNavigationContainer 4-Domain Architecture Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
    });

    Widget createTestApp({ActiveSessionProvider? sessionProvider}) {
      return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(storage),
          ),
          ChangeNotifierProvider<LiftProvider>(
            create: (_) => LiftProvider(storage),
          ),
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => ProgramProvider(storage),
          ),
          ChangeNotifierProvider<RecoveryProvider>(
            create: (_) => RecoveryProvider(storage),
          ),
          ChangeNotifierProvider<BodyCompProvider>(
            create: (_) => BodyCompProvider(storage),
          ),
          ChangeNotifierProvider<NutritionProvider>(
            create: (_) => NutritionProvider(storage),
          ),
          ChangeNotifierProvider<InjuryProvider>(
            create: (_) => InjuryProvider(storage),
          ),
          ChangeNotifierProvider<BreathingProvider>(
            create: (_) => BreathingProvider(storage),
          ),
          ChangeNotifierProvider<ActiveSessionProvider>(
            create: (_) => sessionProvider ?? ActiveSessionProvider(),
          ),
        ],
        child: const MaterialApp(
          home: MainNavigationContainer(),
        ),
      );
    }

    testWidgets('Renders exactly 4 domain tabs: TRAIN, RECOVER, FUEL, INSIGHTS', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(BottomNavigationBar, 'TRAIN'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'RECOVER'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'FUEL'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'INSIGHTS'), findsOneWidget);

      // Verify old 6-tab destinations are no longer persistent bottom tabs
      expect(find.text('Home'), findsNothing);
      expect(find.text('Lifts'), findsNothing);
      expect(find.text('Loader'), findsNothing);
      expect(find.text('Max Test'), findsNothing);
    });

    testWidgets('Switches tabs cleanly between domains', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap RECOVER tab via icon
      await tester.tap(find.byIcon(Icons.self_improvement_outlined));
      await tester.pumpAndSettle();
      expect(find.text('DAILY READINESS'), findsOneWidget);
      expect(find.text('WIM HOF BREATHWORK'), findsOneWidget);

      // Tap FUEL tab via icon
      await tester.tap(find.byIcon(Icons.restaurant_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Nutrition & Energy'), findsOneWidget);

      // Tap INSIGHTS tab via icon
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Analytics & Session Logs'), findsOneWidget);

      // Tap back to TRAIN tab via icon
      await tester.tap(find.byIcon(Icons.fitness_center_outlined));
      await tester.pumpAndSettle();
      expect(find.text('OLY'), findsOneWidget);
    });

    testWidgets('ActiveSessionMiniDock renders when session is active and updates', (
      WidgetTester tester,
    ) async {
      final ActiveSessionProvider sessionProvider = ActiveSessionProvider();

      await tester.pumpWidget(createTestApp(sessionProvider: sessionProvider));
      await tester.pumpAndSettle();

      // Initially no dock visible
      expect(find.byType(ActiveSessionMiniDock), findsOneWidget);
      expect(find.text('Snatch'), findsNothing);

      // Start an active session with rest timer
      sessionProvider.startSession(
        sessionTitle: 'Snatch & Squat',
        currentExercise: 'Snatch',
        currentSetInfo: 'Set 3 of 5 • 85kg',
      );
      sessionProvider.startRestTimer(seconds: 75);

      await tester.pumpAndSettle();

      // Mini-dock now shows the exercise, set info, and rest countdown
      expect(find.text('Snatch'), findsOneWidget);
      expect(find.text('Set 3 of 5 • 85kg'), findsOneWidget);
      expect(find.text('RESTING • 01:15'), findsOneWidget);

      // Pause button interaction
      await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
      await tester.pumpAndSettle();
      expect(sessionProvider.isRestTimerRunning, isFalse);

      // Terminate session
      sessionProvider.endSession();
      await tester.pumpAndSettle();

      expect(find.text('Snatch'), findsNothing);
    });

    testWidgets('AthleteSummaryOverviewCard renders daily briefing details', (
      WidgetTester tester,
    ) async {
      final DayTemplate day = ProgramCycle.getBuiltInProgram().first;

      await tester.pumpWidget(
        MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(storage),
            ),
            ChangeNotifierProvider<LiftProvider>(
              create: (_) => LiftProvider(storage),
            ),
            ChangeNotifierProvider<ProgramProvider>(
              create: (_) => ProgramProvider(storage),
            ),
            ChangeNotifierProvider<RecoveryProvider>(
              create: (_) => RecoveryProvider(storage),
            ),
            ChangeNotifierProvider<BodyCompProvider>(
              create: (_) => BodyCompProvider(storage),
            ),
            ChangeNotifierProvider<NutritionProvider>(
              create: (_) => NutritionProvider(storage),
            ),
            ChangeNotifierProvider<InjuryProvider>(
              create: (_) => InjuryProvider(storage),
            ),
            ChangeNotifierProvider<BreathingProvider>(
              create: (_) => BreathingProvider(storage),
            ),
            ChangeNotifierProvider<ActiveSessionProvider>(
              create: (_) => ActiveSessionProvider(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AthleteSummaryOverviewCard(dayTemplate: day),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('READINESS'), findsOneWidget);
      expect(find.text('START WORKOUT'), findsOneWidget);
      expect(find.text('Warm-Up'), findsOneWidget);
      expect(find.text('FUEL'), findsOneWidget);
      expect(find.text('BREATH'), findsOneWidget);
    });

    testWidgets('ActiveSessionMiniDock renders PREVIEW badge in preview mode', (
      WidgetTester tester,
    ) async {
      final ActiveSessionProvider sessionProvider = ActiveSessionProvider();

      await tester.pumpWidget(createTestApp(sessionProvider: sessionProvider));
      await tester.pumpAndSettle();

      sessionProvider.startSession(
        sessionTitle: 'Snatch Complex',
        currentExercise: 'Snatch Balance',
        isPreviewMode: true,
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ActiveSessionMiniDock),
          matching: find.text('PREVIEW'),
        ),
        findsOneWidget,
      );
      expect(find.text('Snatch Balance'), findsOneWidget);
    });

    testWidgets(
      'ActiveSessionMiniDock renders RECOVERY badge and expands into RecoverySessionScreen for mobility flow',
      (WidgetTester tester) async {
        final ActiveSessionProvider sessionProvider = ActiveSessionProvider();
        final GeneratedRecoveryRoutine routine = GeneratedRecoveryRoutine(
          phaseGroups: <RecoveryPhaseGroup>[],
          exercises: MobilityExerciseModel.defaultExercises().take(2).toList(),
          diagnosticReasons: <String>['Ankle dorsiflexion deficit'],
          totalEstimatedMinutes: 8,
        );

        await tester.pumpWidget(createTestApp(sessionProvider: sessionProvider));
        await tester.pumpAndSettle();

        sessionProvider.startSession(
          sessionType: SessionType.mobility,
          sessionTitle: 'Ankle Mobility Protocol',
          currentExercise: routine.exercises.first.name,
          currentSetInfo: 'Step 1 of ${routine.exercises.length}',
          mobilityRoutine: routine,
        );

        await tester.pumpAndSettle();

        // Mini-dock displays RECOVERY badge and exercise name
        expect(find.text('RECOVERY'), findsOneWidget);
        expect(find.text(routine.exercises.first.name), findsOneWidget);

        // Tap to expand into RecoverySessionScreen
        await tester.tap(find.byType(ActiveSessionMiniDock));
        await tester.pumpAndSettle();

        expect(find.byType(RecoverySessionScreen), findsOneWidget);
        expect(find.text('Active Recovery Routine'), findsOneWidget);

        // Tap minimize button in RecoverySessionScreen
        await tester.tap(find.byTooltip('Minimize to Dock'));
        await tester.pumpAndSettle();

        // Back to dashboard with dock visible
        expect(find.byType(RecoverySessionScreen), findsNothing);
        expect(find.byType(ActiveSessionMiniDock), findsOneWidget);
      },
    );

    testWidgets(
      'ActiveSessionMiniDock dismiss button closes preview mode dock immediately',
      (WidgetTester tester) async {
        final ActiveSessionProvider sessionProvider = ActiveSessionProvider();

        await tester.pumpWidget(createTestApp(sessionProvider: sessionProvider));
        await tester.pumpAndSettle();

        sessionProvider.startSession(
          sessionTitle: 'Snatch Technique',
          currentExercise: 'Snatch High Pull',
          isPreviewMode: true,
        );

        await tester.pumpAndSettle();
        expect(find.byType(ActiveSessionMiniDock), findsOneWidget);
        expect(find.text('Snatch High Pull'), findsOneWidget);

        // Tap the dismiss button on the mini dock
        await tester.tap(find.byTooltip('Dismiss Preview'));
        await tester.pumpAndSettle();

        expect(sessionProvider.isActive, isFalse);
        expect(find.text('Snatch High Pull'), findsNothing);
      },
    );

    testWidgets(
      'WorkoutSessionScreen preview mode AppBar close button dismisses active session',
      (WidgetTester tester) async {
        final DayTemplate day = ProgramCycle.getBuiltInProgram().first;
        final ActiveSessionProvider sessionProvider = ActiveSessionProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<SettingsProvider>(
                create: (_) => SettingsProvider(storage),
              ),
              ChangeNotifierProvider<LiftProvider>(
                create: (_) => LiftProvider(storage),
              ),
              ChangeNotifierProvider<ProgramProvider>(
                create: (_) => ProgramProvider(storage),
              ),
              ChangeNotifierProvider<RecoveryProvider>(
                create: (_) => RecoveryProvider(storage),
              ),
              ChangeNotifierProvider<BodyCompProvider>(
                create: (_) => BodyCompProvider(storage),
              ),
              ChangeNotifierProvider<NutritionProvider>(
                create: (_) => NutritionProvider(storage),
              ),
              ChangeNotifierProvider<InjuryProvider>(
                create: (_) => InjuryProvider(storage),
              ),
              ChangeNotifierProvider<BreathingProvider>(
                create: (_) => BreathingProvider(storage),
              ),
              ChangeNotifierProvider<ActiveSessionProvider>(
                create: (_) => sessionProvider,
              ),
            ],
            child: MaterialApp(
              home: WorkoutSessionScreen(
                dayTemplate: day,
                isPreviewMode: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Close Preview button and Minimize button in AppBar exist
        expect(find.byTooltip('Close Preview'), findsOneWidget);
        expect(find.byTooltip('Minimize to Dock'), findsOneWidget);

        // Tap Close Preview button in AppBar
        await tester.tap(find.byTooltip('Close Preview'));
        await tester.pumpAndSettle();

        expect(sessionProvider.isActive, isFalse);
      },
    );

    testWidgets(
      'WorkoutSessionScreen Exit Preview button scrolls into view and dismisses active session',
      (WidgetTester tester) async {
        final DayTemplate day = ProgramCycle.getBuiltInProgram().first;
        final ActiveSessionProvider sessionProvider = ActiveSessionProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<SettingsProvider>(
                create: (_) => SettingsProvider(storage),
              ),
              ChangeNotifierProvider<LiftProvider>(
                create: (_) => LiftProvider(storage),
              ),
              ChangeNotifierProvider<ProgramProvider>(
                create: (_) => ProgramProvider(storage),
              ),
              ChangeNotifierProvider<RecoveryProvider>(
                create: (_) => RecoveryProvider(storage),
              ),
              ChangeNotifierProvider<BodyCompProvider>(
                create: (_) => BodyCompProvider(storage),
              ),
              ChangeNotifierProvider<NutritionProvider>(
                create: (_) => NutritionProvider(storage),
              ),
              ChangeNotifierProvider<InjuryProvider>(
                create: (_) => InjuryProvider(storage),
              ),
              ChangeNotifierProvider<BreathingProvider>(
                create: (_) => BreathingProvider(storage),
              ),
              ChangeNotifierProvider<ActiveSessionProvider>(
                create: (_) => sessionProvider,
              ),
            ],
            child: MaterialApp(
              home: WorkoutSessionScreen(
                dayTemplate: day,
                isPreviewMode: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder exitBtn = find.text('Exit Preview');
        await tester.ensureVisible(exitBtn);
        await tester.pumpAndSettle();

        await tester.tap(exitBtn);
        await tester.pumpAndSettle();

        expect(sessionProvider.isActive, isFalse);
      },
    );
  });
}
