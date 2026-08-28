import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
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
import 'package:oly/views/dashboard_screen.dart';
import 'package:oly/views/diagnostics/crash_report_screen.dart';
import 'package:oly/views/lifts_screen.dart';
import 'package:oly/views/max_test_screen.dart';
import 'package:oly/views/nutrition/food_search_sheet.dart';
import 'package:oly/views/nutrition/live_barcode_scanner_sheet.dart';
import 'package:oly/views/nutrition/metabolic_science_explainer_screen.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:oly/views/nutrition/renpho_scanner_sheet.dart';
import 'package:oly/views/plate_calculator_screen.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';
import 'package:oly/widgets/mobility_exercise_swap_modal.dart';
import 'package:oly/widgets/nutrition/smart_portion_drawer.dart';
import 'package:oly/widgets/standard_ratios_sheet.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'utils/mock_data_helper.dart';

Future<void> _loadAllFontVariants() async {
  final fontMap = <String, List<String>>{
    'Outfit': [
      'assets/fonts/Outfit-Regular.ttf',
      'assets/fonts/Outfit-Bold.ttf',
      'assets/fonts/Outfit-SemiBold.ttf',
    ],
    'Outfit_regular': ['assets/fonts/Outfit-Regular.ttf'],
    'Outfit_bold': ['assets/fonts/Outfit-Bold.ttf'],
    'Outfit_semibold': ['assets/fonts/Outfit-SemiBold.ttf'],
    'Outfit_700': ['assets/fonts/Outfit-Bold.ttf'],
    'Outfit_600': ['assets/fonts/Outfit-SemiBold.ttf'],
    'Outfit_400': ['assets/fonts/Outfit-Regular.ttf'],

    'Inter': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Medium.ttf',
    ],
    'Inter_regular': ['assets/fonts/Inter-Regular.ttf'],
    'Inter_bold': ['assets/fonts/Inter-Bold.ttf'],
    'Inter_semibold': ['assets/fonts/Inter-SemiBold.ttf'],
    'Inter_medium': ['assets/fonts/Inter-Medium.ttf'],
    'Inter_700': ['assets/fonts/Inter-Bold.ttf'],
    'Inter_600': ['assets/fonts/Inter-SemiBold.ttf'],
    'Inter_500': ['assets/fonts/Inter-Medium.ttf'],
    'Inter_400': ['assets/fonts/Inter-Regular.ttf'],

    'FiraCode': [
      'assets/fonts/FiraCode-Regular.ttf',
      'assets/fonts/FiraCode-Bold.ttf',
      'assets/fonts/FiraCode-SemiBold.ttf',
    ],
    'FiraCode_regular': ['assets/fonts/FiraCode-Regular.ttf'],
    'FiraCode_bold': ['assets/fonts/FiraCode-Bold.ttf'],
    'FiraCode_semibold': ['assets/fonts/FiraCode-SemiBold.ttf'],
    'FiraCode_700': ['assets/fonts/FiraCode-Bold.ttf'],
    'FiraCode_600': ['assets/fonts/FiraCode-SemiBold.ttf'],
    'FiraCode_400': ['assets/fonts/FiraCode-Regular.ttf'],
    'Fira Code': [
      'assets/fonts/FiraCode-Regular.ttf',
      'assets/fonts/FiraCode-Bold.ttf',
      'assets/fonts/FiraCode-SemiBold.ttf',
    ],

    'Roboto': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Medium.ttf',
    ],
    '.AppleSystemUIFont': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Medium.ttf',
    ],
    '.SF Pro Text': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Medium.ttf',
    ],
    'Ahem': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ],
    'packages/flutter_test/Ahem': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ],
  };

  for (final entry in fontMap.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
    }
    await loader.load();
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

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadAllFontVariants();
    await loadAppFonts();
  });

  setUp(() async {
    storage = await MockDataHelper.setupMockStorage();
    settingsProvider = SettingsProvider(storage);
    liftProvider = LiftProvider(storage);
    programProvider = ProgramProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    bodyCompProvider = BodyCompProvider(storage);
    nutritionProvider = NutritionProvider(storage);
  });

  GlobalKey boundaryKey = GlobalKey();

  Widget buildTestScreen(Widget child) {
    boundaryKey = GlobalKey();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: liftProvider),
        ChangeNotifierProvider.value(value: programProvider),
        ChangeNotifierProvider.value(value: recoveryProvider),
        ChangeNotifierProvider.value(value: bodyCompProvider),
        ChangeNotifierProvider.value(value: nutritionProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: RepaintBoundary(
            key: boundaryKey,
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> captureScreen(WidgetTester tester, String filename) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('screenshots/$filename.png');
          file.parent.createSync(recursive: true);
          await file.writeAsBytes(byteData.buffer.asUint8List());
          // ignore: avoid_print
          print('📸 Generated screenshot: screenshots/$filename.png (${byteData.lengthInBytes} bytes)');
        }
      }
    });
  }

  group('Mock Data & Screen Rendering Verification Suite', () {
    testWidgets('01 Renders Dashboard Screen with mock data', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const DashboardScreen()));
      await captureScreen(tester, '01_dashboard_screen');

      // Scrolling screenshot
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '01_dashboard_screen_scrolled');
      }

      expect(find.text('OLY'), findsWidgets);
      expect(find.text('Week 2 of 4: Base Loading'), findsOneWidget);
    });

    testWidgets('02 Renders Lifts Matrix Screen with expanded percentage matrix', (tester) async {
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
    });

    testWidgets('03 Renders Lift Ratios Screen with balance statuses', (tester) async {
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
      expect(find.text('Olympic Ratio Standards Reference Chart'), findsOneWidget);
    });

    testWidgets('04 Renders Standard Ratios Sheet', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const StandardRatiosSheet()));
      await captureScreen(tester, '04_standard_ratios_sheet');
      expect(find.text('Olympic Ratio Standards'), findsOneWidget);
    });

    testWidgets('05 Renders Plate Calculator Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const PlateCalculatorScreen()));
      await captureScreen(tester, '05_plate_calculator_screen');
      expect(find.text('BAR & COLLAR SPECIFICATIONS'), findsOneWidget);
    });

    testWidgets('06 Renders Max Test Calculator Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const MaxTestScreen()));
      await captureScreen(tester, '06_max_test_screen');
      expect(find.text('WEEK 5: MAX TEST PROTOCOL'), findsOneWidget);
    });

    testWidgets('07 Renders Analytics Screen with volume progression', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const AnalyticsScreen()));
      await captureScreen(tester, '07_analytics_screen');

      // Scrolling screenshot
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '07_analytics_screen_scrolled');
      }

      expect(find.text('TOTAL WEIGHT MOVED'), findsOneWidget);
    });

    testWidgets('07b Renders Accessory Progressions Screen with movement delta chips', (tester) async {
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
    });

    testWidgets('08 Renders Warmup Session Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final day1 = ProgramCycle.getBuiltInProgram().first;
      await tester.pumpWidget(buildTestScreen(WarmupSessionScreen(dayTemplate: day1)));
      await captureScreen(tester, '08_warmup_session_screen');
      expect(find.text('Guided Olympic Warm-Up'), findsOneWidget);
    });

    testWidgets('09 Renders Workout Session Screen with periodized sets', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final day1 = ProgramCycle.getBuiltInProgram().first;
      await tester.pumpWidget(
        buildTestScreen(WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2, isPreviewMode: true)),
      );
      await captureScreen(tester, '09_workout_session_screen');

      // Scrolling screenshot
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '09_workout_session_screen_scrolled');
      }

      expect(find.textContaining('PREVIEW MODE'), findsOneWidget);
    });

    testWidgets('10 Renders Workout Swap Modal with Suggested Swaps', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final day1 = ProgramCycle.getBuiltInProgram().first;
      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
      );

      await tester.pumpWidget(
        buildTestScreen(
          Stack(
            children: [
              WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2),
              Container(color: Colors.black.withOpacity(0.65)),
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

    testWidgets('11 Renders Workout Weight Dialog with 1RM estimate', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exercise = ExerciseTemplate(
        name: 'Power Snatch + Overhead Squat',
        liftId: 'snatch',
        setScheme: '4 Sets of 2 Reps',
        weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
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
              double? new1RMKg,
            }) {},
          ),
        ),
      );
      await captureScreen(tester, '11_workout_weight_dialog');
      expect(find.text('Update Working Weight & 1RM'), findsOneWidget);
    });

    testWidgets('12 Renders Active Recovery Session Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routine = RecoveryEngineService.generateRoutine(
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
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600));
        await captureScreen(tester, '12_recovery_session_screen_scrolled');
      }

      expect(find.text('Active Recovery Routine'), findsOneWidget);
    });

    testWidgets('13 Renders Mobility Exercise Swap Modal with Suggested Alternatives', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mobilityEx = MobilityExerciseModel(
        id: 'db_bicep_curls',
        name: 'Dumbbell Bicep Curls',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Builds elbow flexor strength and bicep tendon resilience for heavy clean catches.',
        cues: ['Keep elbows tucked.', 'Squeeze biceps.'],
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
    });

    testWidgets('14 Renders Nutrition & Energy Balance Dashboard Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const NutritionDashboardScreen()));
      await captureScreen(tester, '14_nutrition_dashboard_screen');

      // Scrolling screenshot
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -700));
        await captureScreen(tester, '14_nutrition_dashboard_screen_scrolled');
      }

      expect(find.text('ENERGY IN'), findsOneWidget);
      expect(find.text('ENERGY OUT'), findsOneWidget);
      expect(find.text('Breakfast'), findsWidgets);
    });

    testWidgets('15 Renders Metabolic Science Explainer Screen with interactive tabs', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const MetabolicScienceExplainerScreen()));
      await captureScreen(tester, '15_metabolic_science_explainer_screen');

      // Scrolling screenshot
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -700));
        await captureScreen(tester, '15_metabolic_science_explainer_screen_scrolled');
      }

      expect(find.text('Metabolic Science & Calculations'), findsOneWidget);
      expect(find.text('Energy & TDEE'), findsOneWidget);
    });

    testWidgets('16 Renders Food Search & Recent Pantry Items Sheet', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const FoodSearchSheet()));
      await captureScreen(tester, '16_food_search_sheet');
      expect(find.text('Search Foods & Barcodes'), findsOneWidget);
    });

    testWidgets('17 Renders Athlete Smart Portion Drawer with Protein Density metric', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testFood = FoodItem(
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
        buildTestScreen(const SmartPortionDrawer(initialFoodItem: testFood, defaultCategory: MealCategory.snack)),
      );
      await captureScreen(tester, '17_smart_portion_drawer');
      expect(find.text('OPTIMUM NUTRITION'), findsOneWidget);
      expect(find.text('100% Whey Protein Isolate (Vanilla)'), findsOneWidget);
    });

    testWidgets('18 Renders Live Continuous Barcode Scanner Sheet', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const LiveBarcodeScannerSheet()));
      await captureScreen(tester, '18_live_barcode_scanner_sheet');
      expect(find.text('Live Scanner'), findsOneWidget);
      expect(find.text('Align Barcode Here'), findsOneWidget);
      expect(find.text('Enter Barcode Manually'), findsOneWidget);
    });

    testWidgets('19 Renders Renpho Scale OCR Scanner & Body Composition Donut Chart', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(const RenphoScannerSheet()));
      await captureScreen(tester, '19_renpho_scanner_sheet');
      expect(find.text('BODY COMPOSITION BREAKDOWN'), findsOneWidget);
    });

    testWidgets('20 Renders System Diagnostics & Crash Report Screen', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AppLogService.instance.info('BOOT', 'Oly Application Core initialized');
      AppLogService.instance.debug('FOOD_DB', '107 whole staple foods loaded into memory');
      AppLogService.instance.info('OCR', 'Renpho biometric scale data parsed (LBM: 208.6 lb)');
      AppLogService.instance.warning('NETWORK', 'Offline mode: Open Food Facts local cache active');
      AppLogService.instance.error('SYNC', 'Simulated handled non-fatal socket timeout');

      await tester.pumpWidget(buildTestScreen(const CrashReportScreen()));
      await captureScreen(tester, '20_crash_report_screen');
      expect(find.text('Diagnostics & Crash Logs'), findsOneWidget);
      expect(find.text('Total Logs'), findsOneWidget);
    });
  });
}
