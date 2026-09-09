import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/widgets/dt_wod_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DT Model & Progression Tests', () {
    test('DtWorkoutLog serializes and deserializes with tier calculation', () {
      final DtWorkoutLog rxLog = DtWorkoutLog(
        totalTimeSeconds: 435, // 7:15
        round1TimeSeconds: 80, // 1:20
        round2TimeSeconds: 85, // 1:25
        round3TimeSeconds: 90, // 1:30
        round4TimeSeconds: 90, // 1:30
        round5TimeSeconds: 90, // 1:30
        barbellWeightKg: 70.3,
      );

      expect(rxLog.scalingTier, equals('Rx'));
      expect(rxLog.formattedTotalTime, equals('07:15'));
      expect(rxLog.formattedRound1Time, equals('01:20'));
      expect(rxLog.scoreDisplay, equals('07:15 (Rx)'));

      // Test JSON roundtrip
      final Map<String, dynamic> json = rxLog.toJson();
      final DtWorkoutLog restored = DtWorkoutLog.fromJson(json);
      expect(restored.totalTimeSeconds, equals(435));
      expect(restored.round1TimeSeconds, equals(80));
      expect(restored.scalingTier, equals('Rx'));
      expect(restored.barbellWeightKg, equals(70.3));
    });

    test('DT scaling tiers detect Rx Women (105 lb / 47.6 kg), Scaled (light load), and Weighted', () {
      final DtWorkoutLog rxWomen = DtWorkoutLog(
        totalTimeSeconds: 480,
        barbellWeightKg: 47.6,
        isRxWomen: true,
      );
      expect(rxWomen.scalingTier, equals('Rx'));

      final DtWorkoutLog scaledLight = DtWorkoutLog(
        totalTimeSeconds: 520,
        barbellWeightKg: 61.2, // 135 lb for men
        isRxWomen: false,
      );
      expect(scaledLight.scalingTier, equals('Scaled'));

      final DtWorkoutLog heavyBar = DtWorkoutLog(
        totalTimeSeconds: 650,
        barbellWeightKg: 83.9, // 185 lb
      );
      expect(heavyBar.scalingTier, equals('Weighted'));
    });
  });

  group('DT StorageService & RecoveryProvider Tests', () {
    late SharedPreferences prefs;
    late StorageService storage;
    late RecoveryProvider recovery;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      recovery = RecoveryProvider(storage);
    });

    test('Logs DT workout and calculates PR correctly (lower time is better)', () async {
      // First session: 8:00 (480s) -> should be PR
      final DtWorkoutLog firstLog = DtWorkoutLog(
        totalTimeSeconds: 480,
        barbellWeightKg: 70.3,
        scalingTier: 'Rx',
      );
      final DtWorkoutLog result1 = await recovery.logDtWorkout(firstLog);
      expect(result1.isPr, isTrue);

      expect(recovery.dtWorkoutLogs.length, equals(1));
      expect(recovery.getDtPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(480));

      // Slower session: 8:30 (510s) -> NOT a PR
      final DtWorkoutLog slowerLog = DtWorkoutLog(
        totalTimeSeconds: 510,
        barbellWeightKg: 70.3,
        scalingTier: 'Rx',
      );
      final DtWorkoutLog result2 = await recovery.logDtWorkout(slowerLog);
      expect(result2.isPr, isFalse);
      expect(recovery.getDtPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(480));

      // Faster session: 6:45 (405s) -> NEW PR
      final DtWorkoutLog fasterLog = DtWorkoutLog(
        totalTimeSeconds: 405,
        barbellWeightKg: 70.3,
        scalingTier: 'Rx',
      );
      final DtWorkoutLog result3 = await recovery.logDtWorkout(fasterLog);
      expect(result3.isPr, isTrue);
      expect(recovery.getDtPersonalRecord(tier: 'Rx')?.totalTimeSeconds, equals(405));
    });
  });

  group('DtWodCard Widget Tests', () {
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

    testWidgets('Renders DtWodCard header, stopwatch, 5 rounds, and setup explainer button',
        (WidgetTester tester) async {
      final MobilityExerciseModel dtExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'dt_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          DtWodCard(
            exercise: dtExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CrossFit Hero: DT'), findsOneWidget);
      expect(find.text('5 ROUNDS'), findsOneWidget);
      expect(find.text('START CLOCK'), findsOneWidget);
      expect(find.text('Setup & Strategy Guide'), findsOneWidget);
      expect(find.text('Round 1 of 5'), findsOneWidget);
      expect(find.text('Round 2 of 5'), findsOneWidget);
      expect(find.text('Round 3 of 5'), findsOneWidget);
      expect(find.text('Round 4 of 5'), findsOneWidget);
      expect(find.text('Round 5 of 5'), findsOneWidget);
    });

    testWidgets('Starts stopwatch and completes Round 1 into Round 2',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final MobilityExerciseModel dtExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'dt_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          DtWodCard(
            exercise: dtExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start clock
      await tester.tap(find.text('START CLOCK'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('PAUSE'), findsOneWidget);

      // Complete Round 1
      final Finder completeR1Finder = find.widgetWithText(
        ElevatedButton,
        'COMPLETE ROUND 1 (00:02) -> GO TO ROUND 2',
      );
      expect(completeR1Finder, findsOneWidget);
      await tester.tap(completeR1Finder);
      await tester.pumpAndSettle();

      // Now Round 2 is active
      expect(find.text('12 Deadlifts: 0 / 12'), findsOneWidget);
      expect(find.text('9 Hang Power Cleans: 0 / 9'), findsOneWidget);
      expect(find.text('6 Push Jerks: 0 / 6'), findsOneWidget);
    });

    testWidgets('Toggles between Live Mode and Manual Entry mode',
        (WidgetTester tester) async {
      final MobilityExerciseModel dtExercise =
          MobilityExerciseModel.defaultExercises().firstWhere(
        (MobilityExerciseModel e) => e.id == 'dt_wod',
      );

      await tester.pumpWidget(
        createTestApp(
          DtWodCard(
            exercise: dtExercise,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle to manual entry
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL DT LOG'), findsOneWidget);
      expect(find.text('LOG MANUAL DT SCORE'), findsOneWidget);

      // Toggle back to live timer
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(find.text('START CLOCK'), findsOneWidget);
    });
  });
}
