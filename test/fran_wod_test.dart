import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/fran_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/fran_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fran Model & Progression Tests', () {
    test('FranWorkoutLog serializes and deserializes with tier calculation', () {
      final FranWorkoutLog rxLog = FranWorkoutLog(
        totalTimeSeconds: 215, // 3:35
        round1TimeSeconds: 105, // 1:45
        round2TimeSeconds: 70, // 1:10
        round3TimeSeconds: 40, // 0:40
        barbellWeightKg: 43.1,
        pullupVariation: 'kipping',
      );

      expect(rxLog.scalingTier, equals('Rx'));
      expect(rxLog.formattedTotalTime, equals('03:35'));
      expect(rxLog.formattedRound1Time, equals('01:45'));
      expect(rxLog.pullupDisplayName, contains('Kipping'));
      expect(rxLog.scoreDisplay, equals('03:35 (Rx)'));

      // Test JSON roundtrip
      final Map<String, dynamic> json = rxLog.toJson();
      final FranWorkoutLog restored = FranWorkoutLog.fromJson(json);
      expect(restored.totalTimeSeconds, equals(215));
      expect(restored.round1TimeSeconds, equals(105));
      expect(restored.scalingTier, equals('Rx'));
      expect(restored.pullupVariation, equals('kipping'));
    });

    test('Fran scaling tiers detect Rx Women (65 lb), Scaled (banded/light), Weighted, and Rx Men', () {
      final FranWorkoutLog rxWomen = FranWorkoutLog(
        totalTimeSeconds: 240,
        barbellWeightKg: 29.5,
        isRxWomen: true,
        pullupVariation: 'butterfly',
      );
      expect(rxWomen.scalingTier, equals('Rx'));

      final FranWorkoutLog scaledBanded = FranWorkoutLog(
        totalTimeSeconds: 320,
        pullupVariation: 'band_assisted',
        pullupBandAssistance: 'medium',
      );
      expect(scaledBanded.scalingTier, equals('Scaled'));

      final FranWorkoutLog scaledLightBar = FranWorkoutLog(
        totalTimeSeconds: 300,
        barbellWeightKg: 34.0, // 75 lb for men
        isRxWomen: false,
      );
      expect(scaledLightBar.scalingTier, equals('Scaled'));

      final FranWorkoutLog heavyBar = FranWorkoutLog(
        totalTimeSeconds: 420,
        barbellWeightKg: 52.2, // 115 lb
      );
      expect(heavyBar.scalingTier, equals('Weighted'));
    });
  });

  group('Fran StorageService & RecoveryProvider Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs Fran workout and calculates PR correctly (lower time is better)', () async {
      // First session: 5:00 (300s) -> should be PR
      final FranWorkoutLog firstLog = FranWorkoutLog(
        totalTimeSeconds: 300,
        barbellWeightKg: 43.1,
        scalingTier: 'Rx',
      );
      final FranWorkoutLog result1 = await recovery.logFranWorkout(firstLog);
      expect(result1.isPr, isTrue);

      expect(recovery.franWorkoutLogs.length, equals(1));
      expect(recovery.getFranPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(300));

      // Slower session: 5:20 (320s) -> NOT a PR
      final FranWorkoutLog slowerLog = FranWorkoutLog(
        totalTimeSeconds: 320,
        barbellWeightKg: 43.1,
        scalingTier: 'Rx',
      );
      final FranWorkoutLog result2 = await recovery.logFranWorkout(slowerLog);
      expect(result2.isPr, isFalse);
      expect(recovery.getFranPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(300));

      // Faster session: 3:50 (230s) -> NEW PR
      final FranWorkoutLog fasterLog = FranWorkoutLog(
        totalTimeSeconds: 230,
        barbellWeightKg: 43.1,
        scalingTier: 'Rx',
      );
      final FranWorkoutLog result3 = await recovery.logFranWorkout(fasterLog);
      expect(result3.isPr, isTrue);
      expect(recovery.getFranPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(230));
    });
  });

  group('FranWodCard Widget Tests', () {
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

    testWidgets('Renders FranWodCard header, stopwatch, rounds, and setup explainer button',
        (WidgetTester tester) async {
      final MobilityExerciseModel franExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'fran_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          FranWodCard(
            exercise: franExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CrossFit: Fran'), findsOneWidget);
      expect(find.text('21-15-9'), findsOneWidget);
      expect(find.text('START CLOCK'), findsOneWidget);
      expect(find.text('Setup & Strategy Guide'), findsOneWidget);
      expect(find.text('Round of 21 Reps'), findsOneWidget);
      expect(find.text('Round of 15 Reps'), findsOneWidget);
      expect(find.text('Round of 9 Reps'), findsOneWidget);
    });

    testWidgets('Can start stopwatch and progress through Round of 21 to Round of 15',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel franExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'fran_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          FranWodCard(
            exercise: franExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start clock
      await tester.tap(find.text('START CLOCK'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('PAUSE'), findsOneWidget);

      // Complete 21s
      final Finder complete21Finder = find.widgetWithText(ElevatedButton, 'COMPLETE 21s (00:02) -> GO TO 15s');
      expect(complete21Finder, findsOneWidget);
      await tester.tap(complete21Finder);
      await tester.pumpAndSettle();

      // Now Round of 15 is active
      expect(find.text('Thrusters: 0 / 15'), findsOneWidget);
      expect(find.text('Pull-ups: 0 / 15'), findsOneWidget);
    });

    testWidgets('Toggles between Live Mode and Manual Entry mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel franExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'fran_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          FranWodCard(
            exercise: franExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle to manual entry
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL FRAN LOG'), findsOneWidget);
      expect(find.text('LOG MANUAL FRAN SCORE'), findsOneWidget);

      // Toggle back to live timer
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(find.text('START CLOCK'), findsOneWidget);
    });
  });
}
