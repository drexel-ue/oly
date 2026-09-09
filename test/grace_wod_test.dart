import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/grace_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/grace_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Grace Model & Progression Tests', () {
    test('GraceWorkoutLog serializes and deserializes with tier calculation', () {
      final GraceWorkoutLog rxLog = GraceWorkoutLog(
        totalTimeSeconds: 165, // 2:45
        splitAt10Seconds: 45, // 0:45
        splitAt20Seconds: 105, // 1:45
        barbellWeightKg: 61.2,
        repPacingScheme: 'quick_singles',
        cleanTechnique: 'power_clean',
        jerkTechnique: 'push_jerk',
      );

      expect(rxLog.scalingTier, equals('Rx'));
      expect(rxLog.formattedTotalTime, equals('02:45'));
      expect(rxLog.formattedSplitAt10, equals('00:45'));
      expect(rxLog.formattedSplitAt20, equals('01:45'));
      expect(rxLog.scoreDisplay, equals('02:45 (Rx)'));

      // Test JSON roundtrip
      final Map<String, dynamic> json = rxLog.toJson();
      final GraceWorkoutLog restored = GraceWorkoutLog.fromJson(json);
      expect(restored.totalTimeSeconds, equals(165));
      expect(restored.splitAt10Seconds, equals(45));
      expect(restored.splitAt20Seconds, equals(105));
      expect(restored.scalingTier, equals('Rx'));
      expect(restored.cleanTechnique, equals('power_clean'));
      expect(restored.jerkTechnique, equals('push_jerk'));
    });

    test('Grace scaling tiers detect Rx Women (95 lb / 43.1 kg), Scaled (light load), and Weighted', () {
      final GraceWorkoutLog rxWomen = GraceWorkoutLog(
        totalTimeSeconds: 190,
        barbellWeightKg: 43.1,
        isRxWomen: true,
      );
      expect(rxWomen.scalingTier, equals('Rx'));

      final GraceWorkoutLog scaledLight = GraceWorkoutLog(
        totalTimeSeconds: 220,
        barbellWeightKg: 52.2, // 115 lb for men
        isRxWomen: false,
      );
      expect(scaledLight.scalingTier, equals('Scaled'));

      final GraceWorkoutLog heavyBar = GraceWorkoutLog(
        totalTimeSeconds: 300,
        barbellWeightKg: 70.3, // 155 lb
      );
      expect(heavyBar.scalingTier, equals('Weighted'));
    });
  });

  group('Grace StorageService & RecoveryProvider Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs Grace workout and calculates PR correctly (lower time is better)', () async {
      // First session: 3:30 (210s) -> should be PR
      final GraceWorkoutLog firstLog = GraceWorkoutLog(
        totalTimeSeconds: 210,
        barbellWeightKg: 61.2,
        scalingTier: 'Rx',
      );
      final GraceWorkoutLog result1 = await recovery.logGraceWorkout(firstLog);
      expect(result1.isPr, isTrue);

      expect(recovery.graceWorkoutLogs.length, equals(1));
      expect(recovery.getGracePersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(210));

      // Slower session: 3:50 (230s) -> NOT a PR
      final GraceWorkoutLog slowerLog = GraceWorkoutLog(
        totalTimeSeconds: 230,
        barbellWeightKg: 61.2,
        scalingTier: 'Rx',
      );
      final GraceWorkoutLog result2 = await recovery.logGraceWorkout(slowerLog);
      expect(result2.isPr, isFalse);
      expect(recovery.getGracePersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(210));

      // Faster session: 2:20 (140s) -> NEW PR
      final GraceWorkoutLog fasterLog = GraceWorkoutLog(
        totalTimeSeconds: 140,
        barbellWeightKg: 61.2,
        scalingTier: 'Rx',
      );
      final GraceWorkoutLog result3 = await recovery.logGraceWorkout(fasterLog);
      expect(result3.isPr, isTrue);
      expect(recovery.getGracePersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(140));
    });
  });

  group('GraceWodCard Widget Tests', () {
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

    testWidgets('Renders GraceWodCard header, stopwatch, rep counter, and setup explainer button',
        (WidgetTester tester) async {
      final MobilityExerciseModel graceExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'grace_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          GraceWodCard(
            exercise: graceExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CrossFit: Grace'), findsOneWidget);
      expect(find.text('30 REPS'), findsOneWidget);
      expect(find.text('START CLOCK'), findsOneWidget);
      expect(find.text('Setup & Strategy Guide'), findsOneWidget);
      expect(find.text('CLEAN & JERKS COMPLETED'), findsOneWidget);
      expect(find.text('+1 QUICK SINGLE (1 / 30)'), findsOneWidget);
    });

    testWidgets('Starts stopwatch on rep tap and records reps towards 30',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel graceExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'grace_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          GraceWodCard(
            exercise: graceExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap +1 QUICK SINGLE
      await tester.tap(find.text('+1 QUICK SINGLE (1 / 30)'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap +5
      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();

      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('Toggles between Live Mode and Manual Entry mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel graceExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'grace_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          GraceWodCard(
            exercise: graceExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle to manual entry
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL GRACE LOG'), findsOneWidget);
      expect(find.text('LOG MANUAL GRACE SCORE'), findsOneWidget);

      // Toggle back to live timer
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(find.text('START CLOCK'), findsOneWidget);
    });
  });
}
