import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/add_movement_modal_sheet.dart';
import 'package:oly/widgets/empty_add_movement_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late LiftProvider liftProvider;
  late SettingsProvider settingsProvider;
  late ProgramProvider programProvider;
  late BodyCompProvider bodyCompProvider;
  late NutritionProvider nutritionProvider;
  late RecoveryProvider recoveryProvider;
  late InjuryProvider injuryProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    liftProvider = LiftProvider(storage);
    settingsProvider = SettingsProvider(storage);
    programProvider = ProgramProvider(storage);
    bodyCompProvider = BodyCompProvider(storage);
    nutritionProvider = NutritionProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    injuryProvider = InjuryProvider(storage);
  });

  Widget buildTestApp({required Widget child}) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<LiftProvider>.value(value: liftProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ProgramProvider>.value(value: programProvider),
        ChangeNotifierProvider<BodyCompProvider>.value(value: bodyCompProvider),
        ChangeNotifierProvider<NutritionProvider>.value(value: nutritionProvider),
        ChangeNotifierProvider<RecoveryProvider>.value(value: recoveryProvider),
        ChangeNotifierProvider<InjuryProvider?>.value(value: injuryProvider),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Free-Form Models & Draft Serialization Tests', () {
    test('DynamicWorkoutItem serializes and deserializes all types correctly', () {
      final DynamicWorkoutItem wodItem = DynamicWorkoutItem(
        id: 'wod_1',
        type: DynamicItemType.wod,
        name: 'FRAN',
        refId: 'fran',
        subtitle: '21-15-9 Thrusters & Pull-ups',
        setScheme: '21-15-9 For Time',
        isCompleted: true,
        completedResult: '03:14 (Rx)',
      );

      final Map<String, dynamic> json = wodItem.toJson();
      final DynamicWorkoutItem restored = DynamicWorkoutItem.fromJson(json);

      expect(restored.id, equals('wod_1'));
      expect(restored.type, equals(DynamicItemType.wod));
      expect(restored.name, equals('FRAN'));
      expect(restored.refId, equals('fran'));
      expect(restored.isCompleted, isTrue);
      expect(restored.completedResult, equals('03:14 (Rx)'));

      final DynamicWorkoutItem kbItem = DynamicWorkoutItem(
        id: 'kb_1',
        type: DynamicItemType.kettlebellMile,
        name: 'Kettlebell Mile Carry',
        refId: 'kettlebell_mile',
        subtitle: '1 Mile Farmer Carry',
        targetWeightKg: 32.0,
      );
      final DynamicWorkoutItem restoredKb =
          DynamicWorkoutItem.fromJson(kbItem.toJson());
      expect(restoredKb.type, equals(DynamicItemType.kettlebellMile));
      expect(restoredKb.targetWeightKg, equals(32.0));
      expect(restoredKb.isCompleted, isFalse);
    });

    test('ActiveWorkoutDraft with dynamicItems computes completionPercentage correctly', () {
      final ActiveWorkoutDraft draft = ActiveWorkoutDraft(
        dayNumber: 2,
        weekNumber: 1,
        cycleNumber: 1,
        dayTitle: 'Day 2: Conditioning & Accessories',
        startTime: DateTime.now(),
        exerciseSets: <String, List<CompletedSet>>{},
        exerciseWeights: <String, double>{},
        dynamicItems: <DynamicWorkoutItem>[
          DynamicWorkoutItem(
            id: '1',
            type: DynamicItemType.wod,
            name: 'Cindy',
            isCompleted: true,
          ),
          DynamicWorkoutItem(
            id: '2',
            type: DynamicItemType.kettlebellMile,
            name: 'Kettlebell Mile',
            isCompleted: false,
          ),
        ],
      );

      expect(draft.totalSetsCount, equals(0));
      expect(draft.totalDynamicCount, equals(2));
      expect(draft.totalCompletedDynamic, equals(1));
      expect(draft.completionPercentage, closeTo(0.5, 0.001));

      // Test JSON roundtrip
      final Map<String, dynamic> json = draft.toJson();
      final ActiveWorkoutDraft restored = ActiveWorkoutDraft.fromJson(json);

      expect(restored.dynamicItems.length, equals(2));
      expect(restored.dynamicItems.first.name, equals('Cindy'));
      expect(restored.dynamicItems.first.isCompleted, isTrue);
      expect(restored.totalCompletedDynamic, equals(1));
      expect(restored.completionPercentage, closeTo(0.5, 0.001));
    });

    test('DayTemplate program templates configure Days 2, 4, 6 as isFreeform: true', () {
      final List<DayTemplate> program = ProgramCycle.getBuiltInProgram(week: 1);

      final DayTemplate day1 = program[0];
      final DayTemplate day2 = program[1];
      final DayTemplate day3 = program[2];
      final DayTemplate day4 = program[3];
      final DayTemplate day5 = program[4];
      final DayTemplate day6 = program[5];

      expect(day1.isFreeform, isFalse);
      expect(day1.phases.isNotEmpty, isTrue);

      expect(day2.isFreeform, isTrue);
      expect(day2.isActiveRecovery, isFalse);
      expect(day2.phases, isEmpty);
      expect(day2.title, contains('Day 2'));

      expect(day3.isFreeform, isFalse);
      expect(day4.isFreeform, isTrue);
      expect(day5.isFreeform, isFalse);
      expect(day6.isFreeform, isTrue);

      // Verify recommended active recovery phases exist
      final List<PhaseTemplate> recPhases =
          DayTemplate.recommendedActiveRecoveryPhases;
      expect(recPhases.length, equals(3));
      expect(recPhases[0].name, contains('Kettlebell Mile'));
      expect(recPhases[0].exercises.any((e) => e.name.contains('Mile')), isTrue);
      expect(recPhases[1].name, contains('Core Stability'));
      expect(recPhases[2].name, contains('Hypertrophy'));
    });
  });

  group('EmptyAddMovementCard Widget Tests', () {
    testWidgets('Renders empty canvas hero card when isSessionEmpty is true', (
      WidgetTester tester,
    ) async {
      bool addTapped = false;
      bool loadRecTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyAddMovementCard(
              isSessionEmpty: true,
              onAddPressed: () => addTapped = true,
              onLoadRecommendedPressed: () => loadRecTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('FREE-FORM CONDITIONING DAY'), findsOneWidget);
      expect(find.text('Design Your Own Session'), findsOneWidget);
      expect(find.textContaining('LOAD RECOMMENDED ACTIVE RECOVERY'), findsOneWidget);
      expect(find.text('START BY ADDING A MOVEMENT'), findsOneWidget);

      await tester.tap(find.textContaining('LOAD RECOMMENDED ACTIVE RECOVERY'));
      await tester.pump();
      expect(loadRecTapped, isTrue);

      await tester.tap(find.text('START BY ADDING A MOVEMENT'));
      await tester.pump();
      expect(addTapped, isTrue);
    });

    testWidgets('Collapses to simple dashed add button when isSessionEmpty is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyAddMovementCard(
              isSessionEmpty: false,
              onAddPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('FREE-FORM CONDITIONING DAY'), findsNothing);
      expect(find.textContaining('LOAD RECOMMENDED ACTIVE RECOVERY'), findsNothing);
      expect(find.text('ADD ANOTHER MOVEMENT OR WOD'), findsOneWidget);
    });
  });

  group('AddMovementModalSheet Widget Tests', () {
    testWidgets('Filters by categories and adds selected benchmark WOD', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      DynamicWorkoutItem? addedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddMovementModalSheet(
              onAddMovement: (DynamicWorkoutItem item) => addedItem = item,
            ),
          ),
        ),
      );

      expect(find.text('ADD TO WORKOUT'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('WODs'), findsOneWidget);
      expect(find.text('Carries & Cardio'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Tap WODs category chip
      await tester.tap(find.text('WODs'));
      await tester.pumpAndSettle();

      expect(find.text('Shuffle Random CrossFit WOD'), findsOneWidget);
      expect(find.text('Fran'), findsOneWidget);
      expect(find.text('Cindy'), findsOneWidget);

      // Select Fran
      await tester.tap(find.text('Fran'));
      await tester.pumpAndSettle();

      expect(addedItem, isNotNull);
      expect(addedItem!.name, equals('Fran'));
      expect(addedItem!.type, equals(DynamicItemType.wod));
      expect(addedItem!.refId, equals('fran'));
    });

    testWidgets('Adds custom movement with custom sets and reps', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      DynamicWorkoutItem? addedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddMovementModalSheet(
              onAddMovement: (DynamicWorkoutItem item) => addedItem = item,
            ),
          ),
        ),
      );

      // Tap Custom category chip
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('CREATE CUSTOM MOVEMENT'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextField, 'Movement Name'),
        'Ring Dips',
      );

      // Tap Add to Session button
      await tester.tap(find.text('ADD CUSTOM MOVEMENT TO SESSION'));
      await tester.pumpAndSettle();

      expect(addedItem, isNotNull);
      expect(addedItem!.name, equals('Ring Dips'));
      expect(addedItem!.type, equals(DynamicItemType.custom));
      expect(addedItem!.setScheme, contains('Sets'));
    });
  });

  group('WorkoutSessionScreen Free-Form Integration Tests', () {
    testWidgets('Renders blank free-form canvas and loads recommended template', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final DayTemplate freeformDay = DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Conditioning & Accessories',
        subtitle: 'Free-Form Canvas',
        phases: <PhaseTemplate>[],
        isFreeform: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: WorkoutSessionScreen(
            dayTemplate: freeformDay,
            isPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and empty canvas
      expect(find.text('Day 2: Conditioning & Accessories'), findsOneWidget);
      expect(find.text('FREE-FORM CONDITIONING DAY'), findsOneWidget);
      expect(find.textContaining('LOAD RECOMMENDED ACTIVE RECOVERY'), findsOneWidget);
      expect(find.text('START BY ADDING A MOVEMENT'), findsOneWidget);

      // Tap Load Recommended Active Recovery
      await tester.tap(find.textContaining('LOAD RECOMMENDED ACTIVE RECOVERY'));
      await tester.pumpAndSettle();

      // Verify recommended movements appeared
      expect(find.text('Kettlebell Mile Carry'), findsOneWidget);
      expect(find.text('Cable Crunches'), findsOneWidget);

      // Rest timer must be active at bottom
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Restores active draft with dynamic items and checkboxes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final DayTemplate freeformDay = DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Conditioning & Accessories',
        subtitle: 'Free-Form Canvas',
        phases: <PhaseTemplate>[],
        isFreeform: true,
      );

      final ActiveWorkoutDraft initialDraft = ActiveWorkoutDraft(
        dayNumber: 2,
        weekNumber: 1,
        cycleNumber: 1,
        dayTitle: 'Day 2: Conditioning & Accessories',
        startTime: DateTime.now(),
        exerciseSets: <String, List<CompletedSet>>{},
        exerciseWeights: <String, double>{},
        dynamicItems: <DynamicWorkoutItem>[
          DynamicWorkoutItem(
            id: 'wod_1',
            type: DynamicItemType.wod,
            name: 'DT',
            refId: 'dt',
            subtitle: '5 Rounds: 12 DL, 9 HPC, 6 PJ',
            isCompleted: false,
          ),
          DynamicWorkoutItem(
            id: 'kb_1',
            type: DynamicItemType.kettlebellMile,
            name: 'Kettlebell Mile Carry',
            refId: 'kettlebell_mile',
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: WorkoutSessionScreen(
            dayTemplate: freeformDay,
            initialDraft: initialDraft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify restored dynamic items
      expect(find.text('DT'), findsOneWidget);
      expect(find.text('LAUNCH LIVE WOD'), findsOneWidget);
      expect(find.text('Kettlebell Mile Carry'), findsOneWidget);

      // Mark DT done manually
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Completed:'), findsOneWidget);

      // Mark Kettlebell Mile complete
      await tester.tap(find.text('Tap to Mark 1 Mile Complete'));
      await tester.pumpAndSettle();

      expect(find.text('1 Mile Carry Completed!'), findsOneWidget);
    });

    testWidgets('EmptyAddMovementCard renders preview mode texts when isPreviewMode is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: EmptyAddMovementCard(
              isSessionEmpty: true,
              isPreviewMode: true,
              onAddPressed: () {},
              onLoadRecommendedPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FREE-FORM CONDITIONING DAY'), findsOneWidget);
      expect(find.text('Preview & Plan Your Session'), findsOneWidget);
      expect(find.text('LOAD RECOMMENDED ACTIVE RECOVERY (PREVIEW)'), findsOneWidget);
      expect(find.text('START BY ADDING A MOVEMENT'), findsOneWidget);
    });

    testWidgets('WorkoutSessionScreen in preview mode displays PREVIEW mode pill, banner, and preview card actions', (WidgetTester tester) async {
      final DayTemplate freeformDay = DayTemplate(
        dayNumber: 2,
        title: 'Day 2: Conditioning & Accessories',
        subtitle: 'Free-Form Canvas',
        isFreeform: true,
        phases: <PhaseTemplate>[],
      );

      final ActiveWorkoutDraft initialDraft = ActiveWorkoutDraft(
        dayNumber: 2,
        weekNumber: 1,
        cycleNumber: 1,
        dayTitle: 'Day 2: Conditioning & Accessories',
        startTime: DateTime.now(),
        exerciseSets: <String, List<CompletedSet>>{},
        exerciseWeights: <String, double>{},
        isPreviewMode: true,
        dynamicItems: <DynamicWorkoutItem>[
          DynamicWorkoutItem(
            id: 'wod_fran',
            type: DynamicItemType.wod,
            name: 'FRAN',
            refId: 'fran',
            subtitle: '21-15-9 Thrusters & Pull-ups',
            isCompleted: false,
          ),
          DynamicWorkoutItem(
            id: 'kb_mile',
            type: DynamicItemType.kettlebellMile,
            name: 'Kettlebell Mile Carry',
            refId: 'kettlebell_mile',
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: WorkoutSessionScreen(
            dayTemplate: freeformDay,
            initialDraft: initialDraft,
            isPreviewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Preview Pill in AppBar
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(find.textContaining('PREVIEW MODE — Free-Form Canvas'), findsOneWidget);
      expect(find.text('GO LIVE'), findsOneWidget);

      // Verify WOD Card has PREVIEW WOD & STANDARDS button instead of LAUNCH LIVE WOD
      expect(find.text('PREVIEW WOD & STANDARDS'), findsOneWidget);
      expect(find.text('LAUNCH LIVE WOD'), findsNothing);

      // Verify Kettlebell Mile card has PREVIEW PROTOCOL & STANDARDS button
      expect(find.text('PREVIEW PROTOCOL & STANDARDS'), findsOneWidget);
      expect(find.text('Tap to Mark 1 Mile Complete'), findsNothing);

      // Tap PREVIEW pill in AppBar to toggle to LIVE mode
      await tester.tap(find.text('PREVIEW'));
      await tester.pumpAndSettle();

      // Verify it toggled to LIVE mode
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('LAUNCH LIVE WOD'), findsOneWidget);
      expect(find.text('Tap to Mark 1 Mile Complete'), findsOneWidget);
    });

    testWidgets('AddMovementModalSheet allows previewing WOD setup explainer with ADD TO WORKOUT action', (WidgetTester tester) async {
      DynamicWorkoutItem? addedItem;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) => ElevatedButton(
                onPressed: () => AddMovementModalSheet.show(
                  ctx,
                  onAddMovement: (DynamicWorkoutItem item) => addedItem = item,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify PREVIEW buttons exist on WOD items
      expect(find.text('PREVIEW'), findsWidgets);

      // Tap PREVIEW on the first item (Cindy)
      await tester.tap(find.text('PREVIEW').first);
      await tester.pumpAndSettle();

      // Explainer sheet is shown with ADD TO WORKOUT button
      expect(find.text('ADD CINDY TO WORKOUT'), findsOneWidget);

      // Tap ADD CINDY TO WORKOUT
      await tester.tap(find.text('ADD CINDY TO WORKOUT'));
      await tester.pumpAndSettle();

      // Verify item was selected and returned
      expect(addedItem, isNotNull);
      expect(addedItem!.name, equals('Cindy'));
      expect(addedItem!.type, equals(DynamicItemType.wod));
    });
  });
}
