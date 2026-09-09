import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/helen_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Helen Model & Progression Tests', () {
    test('HelenWorkoutLog serializes and deserializes with tier calculation', () {
      final HelenWorkoutLog rxLog = HelenWorkoutLog(
        totalTimeSeconds: 575, // 9:35
        round1TimeSeconds: 180, // 3:00
        round2TimeSeconds: 195, // 3:15
        round3TimeSeconds: 200, // 3:20
        kettlebellWeightKg: 24.0,
        swingType: 'american',
        pullupVariation: 'kipping',
      );

      expect(rxLog.scalingTier, equals('Rx'));
      expect(rxLog.formattedTotalTime, equals('09:35'));
      expect(rxLog.formattedRound1Time, equals('03:00'));
      expect(rxLog.pullupDisplayName, contains('Kipping'));
      expect(rxLog.swingDisplayName, contains('American'));
      expect(rxLog.scoreDisplay, equals('09:35 (Rx)'));

      // Test JSON roundtrip
      final Map<String, dynamic> json = rxLog.toJson();
      final HelenWorkoutLog restored = HelenWorkoutLog.fromJson(json);
      expect(restored.totalTimeSeconds, equals(575));
      expect(restored.round1TimeSeconds, equals(180));
      expect(restored.scalingTier, equals('Rx'));
      expect(restored.swingType, equals('american'));
      expect(restored.pullupVariation, equals('kipping'));
    });

    test('Helen scaling tiers detect Rx Women (35 lb / 16 kg), Scaled (russian swing / banded / light KB / short run), and Weighted', () {
      final HelenWorkoutLog rxWomen = HelenWorkoutLog(
        totalTimeSeconds: 610,
        kettlebellWeightKg: 16.0,
        isRxWomen: true,
        swingType: 'american',
        pullupVariation: 'butterfly',
      );
      expect(rxWomen.scalingTier, equals('Rx'));

      final HelenWorkoutLog scaledRussian = HelenWorkoutLog(
        totalTimeSeconds: 650,
        kettlebellWeightKg: 24.0,
        swingType: 'russian',
      );
      expect(scaledRussian.scalingTier, equals('Scaled'));

      final HelenWorkoutLog scaledBanded = HelenWorkoutLog(
        totalTimeSeconds: 700,
        pullupVariation: 'band_assisted',
        pullupBandAssistance: 'green',
      );
      expect(scaledBanded.scalingTier, equals('Scaled'));

      final HelenWorkoutLog scaledLightKb = HelenWorkoutLog(
        totalTimeSeconds: 680,
        kettlebellWeightKg: 12.0, // 26 lb
        isRxWomen: false,
      );
      expect(scaledLightKb.scalingTier, equals('Scaled'));

      final HelenWorkoutLog scaledShortRun = HelenWorkoutLog(
        totalTimeSeconds: 520,
        runDistanceMeters: 200,
      );
      expect(scaledShortRun.scalingTier, equals('Scaled'));

      final HelenWorkoutLog heavyKb = HelenWorkoutLog(
        totalTimeSeconds: 800,
        kettlebellWeightKg: 32.0, // 70 lb
      );
      expect(heavyKb.scalingTier, equals('Weighted'));
    });
  });

  group('Helen StorageService & RecoveryProvider Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs Helen workout and calculates PR correctly (lower time is better)', () async {
      // First session: 10:00 (600s) -> should be PR
      final HelenWorkoutLog firstLog = HelenWorkoutLog(
        totalTimeSeconds: 600,
        kettlebellWeightKg: 24.0,
        scalingTier: 'Rx',
      );
      final HelenWorkoutLog result1 = await recovery.logHelenWorkout(firstLog);
      expect(result1.isPr, isTrue);

      expect(recovery.helenWorkoutLogs.length, equals(1));
      expect(recovery.getHelenPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(600));

      // Slower session: 10:30 (630s) -> NOT a PR
      final HelenWorkoutLog slowerLog = HelenWorkoutLog(
        totalTimeSeconds: 630,
        kettlebellWeightKg: 24.0,
        scalingTier: 'Rx',
      );
      final HelenWorkoutLog result2 = await recovery.logHelenWorkout(slowerLog);
      expect(result2.isPr, isFalse);
      expect(recovery.getHelenPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(600));

      // Faster session: 8:45 (525s) -> NEW PR
      final HelenWorkoutLog fasterLog = HelenWorkoutLog(
        totalTimeSeconds: 525,
        kettlebellWeightKg: 24.0,
        scalingTier: 'Rx',
      );
      final HelenWorkoutLog result3 = await recovery.logHelenWorkout(fasterLog);
      expect(result3.isPr, isTrue);
      expect(recovery.getHelenPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(525));
    });
  });

  group('HelenWodCard Widget Tests', () {
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

    testWidgets('Renders HelenWodCard header, stopwatch, rounds, and setup explainer button',
        (WidgetTester tester) async {
      final MobilityExerciseModel helenExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'helen_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          HelenWodCard(
            exercise: helenExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CrossFit: Helen'), findsOneWidget);
      expect(find.text('3 ROUNDS'), findsOneWidget);
      expect(find.text('START CLOCK'), findsOneWidget);
      expect(find.text('Setup & Strategy Guide'), findsOneWidget);
      expect(find.text('Round 1 of 3'), findsOneWidget);
      expect(find.text('Round 2 of 3'), findsOneWidget);
      expect(find.text('Round 3 of 3'), findsOneWidget);
    });

    testWidgets('Can start stopwatch, toggle run, and progress through Round 1 to Round 2',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel helenExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'helen_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          HelenWodCard(
            exercise: helenExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start clock
      await tester.tap(find.text('START CLOCK'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('PAUSE'), findsOneWidget);

      // Toggle 400m run
      await tester.tap(find.text('400m Run'));
      await tester.pumpAndSettle();

      // Complete Round 1
      final Finder completeR1Finder = find.widgetWithText(
        ElevatedButton,
        'COMPLETE ROUND 1 (00:02) -> GO TO ROUND 2',
      );
      expect(completeR1Finder, findsOneWidget);
      await tester.tap(completeR1Finder);
      await tester.pumpAndSettle();

      // Now Round 2 is active
      expect(find.text('21 Kettlebell Swings: 0 / 21'), findsOneWidget);
      expect(find.text('12 Pull-ups: 0 / 12'), findsOneWidget);
    });

    testWidgets('Toggles between Live Mode and Manual Entry mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel helenExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'helen_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          HelenWodCard(
            exercise: helenExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle to manual entry
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL HELEN LOG'), findsOneWidget);
      expect(find.text('LOG MANUAL HELEN SCORE'), findsOneWidget);

      // Toggle back to live timer
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(find.text('START CLOCK'), findsOneWidget);
    });
  });
}
