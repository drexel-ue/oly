import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/views/breathing/breathing_analytics_tab.dart';
import 'package:oly/views/breathing/wim_hof_session_screen.dart';
import 'package:oly/views/breathing/wim_hof_setup_sheet.dart';
import 'package:oly/views/breathing/wim_hof_summary_screen.dart';
import 'package:oly/views/dashboard_screen.dart';
import 'package:oly/views/diagnostics/crash_report_screen.dart';
import 'package:oly/views/injury_tracker_screen.dart';
import 'package:oly/views/lifts_screen.dart';
import 'package:oly/views/max_test_screen.dart';
import 'package:oly/views/nutrition/edit_food_entry_sheet.dart';
import 'package:oly/views/nutrition/food_search_sheet.dart';
import 'package:oly/views/nutrition/live_barcode_scanner_sheet.dart';
import 'package:oly/views/nutrition/metabolic_science_explainer_screen.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'package:oly/views/nutrition/renpho_scanner_sheet.dart';
import 'package:oly/views/plate_calculator_screen.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';
import 'package:oly/widgets/injury_export_bottom_sheet.dart';
import 'package:oly/widgets/mobility_exercise_swap_modal.dart';
import 'package:oly/widgets/nutrition/smart_portion_drawer.dart';
import 'package:oly/widgets/post_session_body_checkin_dialog.dart';
import 'package:oly/widgets/standard_ratios_sheet.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'package:provider/provider.dart';

import 'utils/mock_data_helper.dart';

Future<void> _loadFont(String family, String assetPath) async {
  final File file = File(assetPath);
  if (!file.existsSync()) {
    return;
  }
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader(family);
  loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _loadAllFontVariants() async {
  final Map<String, String> fonts = <String, String>{
    'Outfit': 'assets/fonts/Outfit-Regular.ttf',
    'Outfit_regular': 'assets/fonts/Outfit-Regular.ttf',
    'Outfit_400': 'assets/fonts/Outfit-Regular.ttf',
    'Outfit_500': 'assets/fonts/Outfit-Regular.ttf',
    'Outfit_600': 'assets/fonts/Outfit-SemiBold.ttf',
    'Outfit_semibold': 'assets/fonts/Outfit-SemiBold.ttf',
    'Outfit_700': 'assets/fonts/Outfit-Bold.ttf',
    'Outfit_bold': 'assets/fonts/Outfit-Bold.ttf',
    'Outfit_800': 'assets/fonts/Outfit-Bold.ttf',
    'Outfit_900': 'assets/fonts/Outfit-Bold.ttf',

    'Inter': 'assets/fonts/Inter-Regular.ttf',
    'Inter_regular': 'assets/fonts/Inter-Regular.ttf',
    'Inter_400': 'assets/fonts/Inter-Regular.ttf',
    'Inter_500': 'assets/fonts/Inter-Medium.ttf',
    'Inter_medium': 'assets/fonts/Inter-Medium.ttf',
    'Inter_600': 'assets/fonts/Inter-SemiBold.ttf',
    'Inter_semibold': 'assets/fonts/Inter-SemiBold.ttf',
    'Inter_700': 'assets/fonts/Inter-Bold.ttf',
    'Inter_bold': 'assets/fonts/Inter-Bold.ttf',
    'Inter_800': 'assets/fonts/Inter-Bold.ttf',
    'Inter_900': 'assets/fonts/Inter-Bold.ttf',
    'Inter_italic': 'assets/fonts/Inter-Italic.ttf',
    'Inter-Italic': 'assets/fonts/Inter-Italic.ttf',
    'Inter_400italic': 'assets/fonts/Inter-Italic.ttf',
    'Inter_500italic': 'assets/fonts/Inter-Italic.ttf',
    'Inter_600italic': 'assets/fonts/Inter-Italic.ttf',
    'Inter_700italic': 'assets/fonts/Inter-Italic.ttf',

    'FiraCode': 'assets/fonts/FiraCode-Regular.ttf',
    'FiraCode_regular': 'assets/fonts/FiraCode-Regular.ttf',
    'FiraCode_400': 'assets/fonts/FiraCode-Regular.ttf',
    'FiraCode_600': 'assets/fonts/FiraCode-SemiBold.ttf',
    'FiraCode_semibold': 'assets/fonts/FiraCode-SemiBold.ttf',
    'FiraCode_700': 'assets/fonts/FiraCode-Bold.ttf',
    'FiraCode_bold': 'assets/fonts/FiraCode-Bold.ttf',

    'MaterialIcons': 'assets/fonts/MaterialIcons-Regular.otf',
    'MaterialIcons-Regular': 'assets/fonts/MaterialIcons-Regular.otf',
    'packages/flutter_test/MaterialIcons': 'assets/fonts/MaterialIcons-Regular.otf',
  };

  for (final MapEntry<String, String> entry in fonts.entries) {
    await _loadFont(entry.key, entry.value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late SettingsProvider settingsProvider;
  late LiftProvider liftProvider;
  late ProgramProvider programProvider;
  late RecoveryProvider recoveryProvider;
  late BodyCompProvider bodyCompProvider;
  late NutritionProvider nutritionProvider;
  late InjuryProvider injuryProvider;
  late BreathingProvider breathingProvider;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadAllFontVariants();
    await loadAppFonts();

    // Pre-warm GoogleFonts
    GoogleFonts.outfit();
    GoogleFonts.outfit(fontWeight: FontWeight.bold);
    GoogleFonts.outfit(fontWeight: FontWeight.w600);
    GoogleFonts.inter();
    GoogleFonts.inter(fontWeight: FontWeight.bold);
    GoogleFonts.inter(fontWeight: FontWeight.w600);
    GoogleFonts.inter(fontWeight: FontWeight.w500);
    GoogleFonts.firaCode();
    await GoogleFonts.pendingFonts();
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    settingsProvider = SettingsProvider(storage);
    liftProvider = LiftProvider(storage);
    programProvider = ProgramProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    bodyCompProvider = BodyCompProvider(storage);
    nutritionProvider = NutritionProvider(storage);
    injuryProvider = InjuryProvider(storage);
    breathingProvider = BreathingProvider(storage);
  });

  GlobalKey boundaryKey = GlobalKey();

  Widget buildTestScreen(Widget child) {
    boundaryKey = GlobalKey();
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: liftProvider),
        ChangeNotifierProvider.value(value: programProvider),
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: bodyCompProvider),
        ChangeNotifierProvider.value(value: nutritionProvider),
        ChangeNotifierProvider.value(value: injuryProvider),
        ChangeNotifierProvider.value(value: breathingProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: RepaintBoundary(key: boundaryKey, child: child),
        ),
      ),
    );
  }

  Future<void> captureScreen(WidgetTester tester, String filename) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      final RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          final File file = File('screenshots/$filename.png');
          file.parent.createSync(recursive: true);
          await file.writeAsBytes(byteData.buffer.asUint8List());
          // ignore: avoid_print
          print(
            '📸 Generated screenshot: screenshots/$filename.png (${byteData.lengthInBytes} bytes)',
          );
        }
      }
    });
  }

  group('Mock Data & Screen Rendering Verification Suite', () {
    testWidgets('01 Renders Dashboard Screen with mock data', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const DashboardScreen()));
      await captureScreen(tester, '01_dashboard_screen');

      // Scrolling screenshot
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '01_dashboard_screen_scrolled');
      }

      expect(find.text('OLY'), findsWidgets);
      expect(find.text('Week 2 of 4: Base Loading'), findsOneWidget);
    });

    testWidgets(
      '02 Renders Lifts Matrix Screen with expanded percentage matrix',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestScreen(const LiftsScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        if (find.text('Snatch').evaluate().isNotEmpty) {
          await tester.tap(find.text('Snatch').first);
          await tester.pump(const Duration(milliseconds: 200));
        }

        await captureScreen(tester, '02_lifts_matrix_screen');
        expect(find.text('Snatch'), findsWidgets);
      },
    );

    testWidgets('03 Renders Lift Ratios Screen with balance statuses', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const LiftsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      if (find.text('Ratio Balance').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ratio Balance'));
        await tester.pump(const Duration(milliseconds: 200));
      }

      await captureScreen(tester, '03_lift_ratios_screen');
      expect(
        find.text('Olympic Ratio Standards Reference Chart'),
        findsOneWidget,
      );
    });

    testWidgets('04 Renders Standard Ratios Sheet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const StandardRatiosSheet()));
      await captureScreen(tester, '04_standard_ratios_sheet');
      expect(find.text('Olympic Ratio Standards'), findsOneWidget);
    });

    testWidgets('05 Renders Plate Calculator Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const PlateCalculatorScreen()));
      await captureScreen(tester, '05_plate_calculator_screen');
      expect(find.text('BAR & COLLAR SPECIFICATIONS'), findsOneWidget);
    });

    testWidgets('06 Renders Max Test Calculator Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const MaxTestScreen()));
      await captureScreen(tester, '06_max_test_screen');
      expect(find.text('WEEK 5: MAX TEST PROTOCOL'), findsOneWidget);
    });

    testWidgets('07 Renders Analytics Screen with volume progression', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const AnalyticsScreen()));
      await captureScreen(tester, '07_analytics_screen');

      // Scrolling screenshot
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '07_analytics_screen_scrolled');
      }

      expect(find.text('TOTAL WEIGHT MOVED'), findsOneWidget);
    });

    testWidgets(
      '07b Renders Accessory Progressions Screen with movement delta chips',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestScreen(const AnalyticsScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        if (find.text('Accessories').evaluate().isNotEmpty) {
          await tester.tap(find.text('Accessories'));
          await tester.pump(const Duration(milliseconds: 200));
        }

        await captureScreen(tester, '07b_accessory_progressions_screen');
        expect(find.text('ACCESSORY WEIGHT PROGRESSIONS'), findsOneWidget);
      },
    );

    testWidgets('08 Renders Warmup Session Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final DayTemplate day1 = ProgramCycle.getBuiltInProgram().first;
      await tester.pumpWidget(
        buildTestScreen(WarmupSessionScreen(dayTemplate: day1)),
      );
      await captureScreen(tester, '08_warmup_session_screen');
      expect(find.text('Guided Olympic Warm-Up'), findsOneWidget);
    });

    testWidgets('09 Renders Workout Session Screen with periodized sets', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final DayTemplate day1 = ProgramCycle.getBuiltInProgram().first;
      await tester.pumpWidget(
        buildTestScreen(
          WorkoutSessionScreen(
            dayTemplate: day1,
            previewWeek: 2,
            isPreviewMode: true,
          ),
        ),
      );
      await captureScreen(tester, '09_workout_session_screen');

      // Scrolling screenshot
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '09_workout_session_screen_scrolled');
      }

      expect(find.textContaining('PREVIEW MODE'), findsOneWidget);
    });

    testWidgets('10 Renders Workout Swap Modal with Suggested Swaps', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final DayTemplate day1 = ProgramCycle.getBuiltInProgram().first;
      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: <int, double>{1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      await tester.pumpWidget(
        buildTestScreen(
          Stack(
            children: <Widget>[
              WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2),
              Container(color: Colors.black.withValues(alpha: 0.65)),
              Align(
                alignment: Alignment.bottomCenter,
                child: ExerciseSwapModal(
                  exercise: exercise,
                  currentWeek: 2,
                  onSwapSelected: (_) {},
                ),
              ),
            ],
          ),
        ),
      );
      await captureScreen(tester, '10_workout_swap_modal');
      expect(find.text('Swap Movement Variation'), findsOneWidget);
    });

    testWidgets('11 Renders Workout Weight Dialog with 1RM estimate', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ExerciseTemplate exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: <int, double>{1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      await tester.pumpWidget(
        buildTestScreen(
          WorkoutWeightDialog(
            exercise: exercise,
            displayName: 'Power Snatch + Overhead Squat',
            initialWeightKg: 70.0,
            currentWeek: 2,
            onWeightUpdated: ({
              required double newWeightKg,
              required bool update1RM,
              int? newReps,
              double? new1RMKg,
            }) {},
          ),
        ),
      );
      await captureScreen(tester, '11_workout_weight_dialog');
      expect(find.text('Update Working Weight & Reps'), findsOneWidget);
    });

    testWidgets('12 Renders Active Recovery Session Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final GeneratedRecoveryRoutine routine =
          RecoveryEngineService.generateRoutine(
            ratioAnalyses: liftProvider.getRatioAnalysis(),
            lastSession: programProvider.sessions.isNotEmpty
                ? programProvider.sessions.first
                : null,
          );

      await tester.pumpWidget(
        buildTestScreen(RecoverySessionScreen(routine: routine)),
      );
      await captureScreen(tester, '12_recovery_session_screen');

      // Scrolling screenshot
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '12_recovery_session_screen_scrolled');
      }

      expect(find.text('Active Recovery Routine'), findsOneWidget);
    });

    testWidgets(
      '13 Renders Mobility Exercise Swap Modal with Suggested Alternatives',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final MobilityExerciseModel mobilityEx = MobilityExerciseModel(
          id: 'db_bicep_curls',
          name: 'Dumbbell Bicep Curls',
          focusArea: MobilityFocusArea.arms,
          category: MobilityCategory.hypertrophyCore,
          description: 'Builds elbow flexor strength and bicep tendon resilience for heavy clean catches.',
          cues: <String>['Keep elbows tucked.', 'Squeeze biceps.'],
          defaultSets: 3,
          defaultReps: 12,
          videoUrl: 'https://youtube.com',
        );

        await tester.pumpWidget(
          buildTestScreen(
            MobilityExerciseSwapModal(
              exercise: mobilityEx,
              onSwapSelected: (_) {},
            ),
          ),
        );
        await captureScreen(tester, '13_mobility_swap_modal');
        expect(find.text('Swap Movement'), findsOneWidget);
      },
    );

    testWidgets('14 Renders Nutrition & Energy Balance Dashboard Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(const NutritionDashboardScreen()),
      );
      await captureScreen(tester, '14_nutrition_dashboard_screen');

      // Scrolling screenshot
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -700));
        await captureScreen(tester, '14_nutrition_dashboard_screen_scrolled');
      }

      expect(find.text('ENERGY IN'), findsOneWidget);
      expect(find.text('ENERGY OUT'), findsOneWidget);
      expect(find.text('Breakfast'), findsWidgets);
    });

    testWidgets(
      '15 Renders Metabolic Science Explainer Screen with interactive tabs',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestScreen(const MetabolicScienceExplainerScreen()),
        );
        await captureScreen(tester, '15_metabolic_science_explainer_screen');

        // Scrolling screenshot
        final Finder scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -700));
          await captureScreen(
            tester,
            '15_metabolic_science_explainer_screen_scrolled',
          );
        }

        expect(find.text('Metabolic Science & Calculations'), findsOneWidget);
        expect(find.text('Energy & TDEE'), findsOneWidget);
      },
    );

    testWidgets('16 Renders Food Search & Recent Pantry Items Sheet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const FoodSearchSheet()));
      await captureScreen(tester, '16_food_search_sheet');
      expect(find.text('Search Foods & Menus'), findsOneWidget);
    });

    testWidgets(
      '17 Renders Athlete Smart Portion Drawer with Protein Density metric',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const FoodItem testFood = FoodItem(
          id: 'whey_isolate_vanilla',
          name: '100% Whey Protein Isolate (Vanilla)',
          brand: 'Optimum Nutrition',
          servingSize: '1 scoop (31g)',
          servingWeightGrams: 31,
          calories: 120,
          protein: 25.0,
          carbs: 1.0,
          fat: 1.0,
          barcode: '748927028669',
          source: 'open_food_facts',
        );

        await tester.pumpWidget(
          buildTestScreen(
            const SmartPortionDrawer(
              initialFoodItem: testFood,
              defaultCategory: MealCategory.snack,
            ),
          ),
        );
        await captureScreen(tester, '17_smart_portion_drawer');
        expect(find.text('OPTIMUM NUTRITION'), findsOneWidget);
        expect(
          find.text('100% Whey Protein Isolate (Vanilla)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '17b Renders Edit Food Entry Modal Sheet with Category Switcher & Macro Controls',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final NutritionEntry entry = NutritionEntry.create(
          name: 'Grilled Wild Salmon & Quinoa',
          calories: 580,
          proteinGrams: 46,
          carbsGrams: 42,
          fatGrams: 24,
          category: MealCategory.lunch,
          portion: '220g salmon + 1 cup cooked quinoa',
        );

        await tester.pumpWidget(
          buildTestScreen(
            EditFoodEntrySheet(entry: entry),
          ),
        );
        await captureScreen(tester, '17b_edit_food_entry_sheet');
        expect(find.text('Edit Logged Food'), findsOneWidget);
        expect(find.text('MEAL SECTION'), findsOneWidget);
        expect(find.text('Grilled Wild Salmon & Quinoa'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
      },
    );

    testWidgets('18 Renders Live Continuous Barcode Scanner Sheet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const LiveBarcodeScannerSheet()));
      await captureScreen(tester, '18_live_barcode_scanner_sheet');
      expect(find.text('Live Scanner'), findsOneWidget);
      expect(find.text('Align Barcode Here'), findsOneWidget);
      expect(find.text('Enter Barcode Manually'), findsOneWidget);
    });

    testWidgets(
      '19 Renders Renpho Scale OCR Scanner & Body Composition Donut Chart',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestScreen(const RenphoScannerSheet()));
        await captureScreen(tester, '19_renpho_scanner_sheet');
        expect(find.text('BODY COMPOSITION BREAKDOWN'), findsOneWidget);
      },
    );

    testWidgets('20 Renders System Diagnostics & Crash Report Screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AppLogService.instance.info('BOOT', 'Oly Application Core initialized');
      AppLogService.instance.debug(
        'FOOD_DB',
        '107 whole staple foods loaded into memory',
      );
      AppLogService.instance.info(
        'OCR',
        'Renpho biometric scale data parsed (LBM: 208.6 lb)',
      );
      AppLogService.instance.warning(
        'NETWORK',
        'Offline mode: Open Food Facts local cache active',
      );
      AppLogService.instance.error(
        'SYNC',
        'Simulated handled non-fatal socket timeout',
      );

      await tester.pumpWidget(buildTestScreen(const CrashReportScreen()));
      await captureScreen(tester, '20_crash_report_screen');
      expect(find.text('Diagnostics & Crash Logs'), findsOneWidget);
      expect(find.text('Total Logs'), findsOneWidget);
    });

    testWidgets('21 Renders Body Map & Injury Tracker Screen with Active Strains', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed mock injuries
      await injuryProvider.addInjury(
        InjuryRecord(
          id: 'mock_knee',
          name: "Patellar Jumper's Knee",
          region: InjuryRegion.leftKnee,
          onsetDate: DateTime.now().subtract(const Duration(days: 4)),
          painScale: 5,
          notes: 'Sharp catch pain in bottom position',
        ),
      );
      await injuryProvider.addInjury(
        InjuryRecord(
          id: 'mock_shoulder',
          name: 'Rotator Cuff Impingement',
          region: InjuryRegion.rightShoulder,
          onsetDate: DateTime.now().subtract(const Duration(days: 45)),
          painScale: 3,
          notes: 'Persistent overhead lockout stiffness',
        ),
      );

      await tester.pumpWidget(buildTestScreen(const InjuryTrackerScreen()));
      await captureScreen(tester, '21_injury_tracker_screen');
      expect(find.text('Body Map & Injuries'), findsOneWidget);
      expect(find.text('ANATOMICAL HEATMAP (TAP TO LOG / INSPECT)'), findsOneWidget);
    });

    testWidgets('22 Renders Post-Session Body Check-In Modal', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          PostSessionBodyCheckinDialog(
            initialJointStrains: const <String>['Knees', 'Shoulders'],
            onComplete: (Map<InjuryRegion, int> pain, List<String> tags) {},
          ),
        ),
      );
      await captureScreen(tester, '22_post_session_body_checkin');
      expect(find.text('Post-Session Strain Check-In'), findsOneWidget);
      expect(find.text('Save & Finish'), findsOneWidget);
    });

    testWidgets('23 Renders Injury Export Bottom Sheet (PDF & JSON)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          InjuryExportBottomSheet(
            injuries: injuryProvider.allInjuries,
          ),
        ),
      );
      await captureScreen(tester, '23_injury_export_sheet');
      expect(find.text('Export Injury History'), findsOneWidget);
      expect(find.text('Clinical & Athletic PDF Report'), findsOneWidget);
      expect(find.text('Structured JSON Data Export'), findsOneWidget);
    });

    testWidgets('24 Renders Wim Hof Setup Sheet with Round Steppers & PR Badge', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const WimHofSetupSheet()));
      await captureScreen(tester, '24_wim_hof_setup_sheet');
      expect(find.text('Wim Hof Breathwork'), findsOneWidget);
      expect(find.text('NUMBER OF ROUNDS'), findsOneWidget);
    });

    testWidgets('25 Renders Guided Wim Hof Live Breathing Session with Pulsing Orb', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const WimHofConfig config = WimHofConfig(
        defaultRounds: 3,
        breathsPerRound: 30,
        soundEnabled: false,
        hapticsEnabled: false,
      );

      await tester.pumpWidget(buildTestScreen(const WimHofSessionScreen(config: config)));
      // Advance prep timer into hyperventilation stage
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      await captureScreen(tester, '25_wim_hof_session_screen');
      expect(find.text('BREATH 1 OF 30'), findsOneWidget);
      expect(find.text('FULLY IN...'), findsOneWidget);
    });

    testWidgets('26 Renders Breath Retention Stopwatch and PR Milestone', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const WimHofConfig config = WimHofConfig(
        defaultRounds: 3,
        breathsPerRound: 30,
        soundEnabled: false,
        hapticsEnabled: false,
      );

      await tester.pumpWidget(buildTestScreen(const WimHofSessionScreen(config: config)));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      // Trigger retention hold
      await tester.tap(find.text("I'M FULL • START RETENTION HOLD"));
      await tester.pump();
      // Advance stopwatch to 1m 45s (105s)
      await tester.pump(const Duration(seconds: 105));

      await captureScreen(tester, '26_wim_hof_retention_screen');
      expect(find.text('RETENTION TIME'), findsOneWidget);
      expect(find.text('01:45'), findsOneWidget);
    });

    testWidgets('27 Renders Post-Breathwork Completion Summary & Round Bars', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<BreathingRoundLog> rounds = <BreathingRoundLog>[
        BreathingRoundLog(roundNumber: 1, breathsCount: 30, retentionSeconds: 85),
        BreathingRoundLog(roundNumber: 2, breathsCount: 30, retentionSeconds: 120),
        BreathingRoundLog(roundNumber: 3, breathsCount: 30, retentionSeconds: 155),
        BreathingRoundLog(roundNumber: 4, breathsCount: 30, retentionSeconds: 185), // PR hold
      ];

      await tester.pumpWidget(
        buildTestScreen(
          WimHofSummaryScreen(
            rounds: rounds,
            config: const WimHofConfig(defaultRounds: 4),
          ),
        ),
      );
      await captureScreen(tester, '27_wim_hof_summary_screen');
      expect(find.text('Breathwork Complete'), findsOneWidget);
      expect(find.text('NEW RETENTION PR!'), findsOneWidget);
    });

    testWidgets('28 Renders Breathwork Retention Analytics Tab with Progression Line Chart', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const BreathingAnalyticsTab()));
      await captureScreen(tester, '28_breathwork_analytics_tab');
      expect(find.text('ALL-TIME BREATHWORK TOTALS'), findsOneWidget);
      expect(find.text('RETENTION DURATION PROGRESSION'), findsOneWidget);
      expect(find.text('AVERAGE HOLD DURATION BY ROUND'), findsOneWidget);
    });
  });
}
