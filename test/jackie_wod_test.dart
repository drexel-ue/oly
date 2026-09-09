import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/jackie_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/jackie_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Jackie Model & Progression Tests', () {
    test('JackieWorkoutLog serializes and deserializes with tier calculation', () {
      final JackieWorkoutLog rxLog = JackieWorkoutLog(
        totalTimeSeconds: 542, // 9:02
        rowTimeSeconds: 225, // 3:45
        thrusterTimeSeconds: 215, // 3:35
        pullupTimeSeconds: 102, // 1:42
        barbellWeightKg: 20.4,
        pullupVariation: 'kipping',
      );

      expect(rxLog.scalingTier, equals('Rx'));
      expect(rxLog.formattedTotalTime, equals('09:02'));
      expect(rxLog.formattedRowTime, equals('03:45'));
      expect(rxLog.pullupDisplayName, contains('Kipping'));
      expect(rxLog.scoreDisplay, equals('09:02 (Rx)'));

      // Test JSON roundtrip
      final Map<String, dynamic> json = rxLog.toJson();
      final JackieWorkoutLog restored = JackieWorkoutLog.fromJson(json);
      expect(restored.totalTimeSeconds, equals(542));
      expect(restored.rowTimeSeconds, equals(225));
      expect(restored.scalingTier, equals('Rx'));
      expect(restored.pullupVariation, equals('kipping'));
    });

    test('Jackie scaling tiers detect Scaled vs Weighted vs Rx', () {
      final JackieWorkoutLog scaledBanded = JackieWorkoutLog(
        totalTimeSeconds: 650,
        pullupVariation: 'band_assisted',
        pullupBandAssistance: 'medium',
      );
      expect(scaledBanded.scalingTier, equals('Scaled'));

      final JackieWorkoutLog scaledLightBar = JackieWorkoutLog(
        totalTimeSeconds: 600,
        barbellWeightKg: 15.0, // 33 lb
      );
      expect(scaledLightBar.scalingTier, equals('Scaled'));

      final JackieWorkoutLog weightedBar = JackieWorkoutLog(
        totalTimeSeconds: 720,
        barbellWeightKg: 29.5, // 65 lb
      );
      expect(weightedBar.scalingTier, equals('Weighted'));

      final JackieWorkoutLog rxStandard = JackieWorkoutLog(
        totalTimeSeconds: 510,
        barbellWeightKg: 20.4,
        pullupVariation: 'standard',
      );
      expect(rxStandard.scalingTier, equals('Rx'));
    });
  });

  group('Jackie StorageService & RecoveryProvider Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs Jackie workout and calculates PR correctly (lower time is better)', () async {
      // First session: 10:00 (600s) -> should be PR
      final JackieWorkoutLog firstLog = JackieWorkoutLog(
        totalTimeSeconds: 600,
        barbellWeightKg: 20.4,
        scalingTier: 'Rx',
      );
      final JackieWorkoutLog result1 = await recovery.logJackieWorkout(firstLog);
      expect(result1.isPr, isTrue);

      expect(recovery.jackieWorkoutLogs.length, equals(1));
      expect(recovery.getJackiePersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(600));

      // Slower session: 10:30 (630s) -> NOT a PR
      final JackieWorkoutLog slowerLog = JackieWorkoutLog(
        totalTimeSeconds: 630,
        barbellWeightKg: 20.4,
        scalingTier: 'Rx',
      );
      final JackieWorkoutLog result2 = await recovery.logJackieWorkout(slowerLog);
      expect(result2.isPr, isFalse);
      expect(recovery.getJackiePersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(600));

      // Faster session: 8:45 (525s) -> NEW PR
      final JackieWorkoutLog fasterLog = JackieWorkoutLog(
        totalTimeSeconds: 525,
        barbellWeightKg: 20.4,
        scalingTier: 'Rx',
      );
      final JackieWorkoutLog result3 = await recovery.logJackieWorkout(fasterLog);
      expect(result3.isPr, isTrue);
      expect(recovery.getJackiePersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(525));
    });
  });

  group('JackieWodCard Widget Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;
    late SettingsProvider settings;
    late BodyCompProvider bodyComp;
    late NutritionProvider nutrition;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
      settings = SettingsProvider(storage);
      bodyComp = BodyCompProvider(storage);
      nutrition = NutritionProvider(storage);
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<RecoveryProvider>.value(value: recovery),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
          ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        ),
      );
    }

    testWidgets('Renders JackieWodCard header, stopwatch, stations, and setup explainer button',
        (WidgetTester tester) async {
      final MobilityExerciseModel jackieExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'jackie_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          JackieWodCard(
            exercise: jackieExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CrossFit: Jackie'), findsOneWidget);
      expect(find.text('FOR TIME'), findsOneWidget);
      expect(find.text('START CLOCK'), findsOneWidget);
      expect(find.text('Setup & Strategy Guide'), findsOneWidget);
      expect(find.text('Station 1: 1,000m Row'), findsOneWidget);
      expect(find.text('Station 2: 50 Thrusters (45 lb)'), findsOneWidget);
      expect(find.text('Station 3: 30 Pull-ups'), findsOneWidget);
    });

    testWidgets('Can start stopwatch and progress through Row station to Thrusters',
        (WidgetTester tester) async {
      final MobilityExerciseModel jackieExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'jackie_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          JackieWodCard(
            exercise: jackieExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start clock
      await tester.tap(find.text('START CLOCK'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('PAUSE'), findsOneWidget);

      // Complete Row station
      final Finder completeRowFinder = find.widgetWithText(ElevatedButton, 'ROW COMPLETE (00:02) -> GO TO THRUSTERS');
      expect(completeRowFinder, findsOneWidget);
      await tester.tap(completeRowFinder);
      await tester.pumpAndSettle();

      // Now Station 2 is active
      expect(find.text('Reps: 0 / 50'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);

      // Tap +10 reps
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      expect(find.text('Reps: 10 / 50'), findsOneWidget);
    });

    testWidgets('Toggles between Live Mode and Manual Entry mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel jackieExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'jackie_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          JackieWodCard(
            exercise: jackieExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle to manual entry
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL LOG ENTRY'), findsOneWidget);
      expect(find.text('LOG MANUAL JACKIE SCORE'), findsOneWidget);

      // Toggle back to live timer
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(find.text('START CLOCK'), findsOneWidget);
    });
  });
}
