import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/recovery_engine_service.dart';
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
import '../test/utils/mock_data_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture high-res and scrolling screenshots of all Oly screens with mock data', (tester) async {
    final storage = await MockDataHelper.setupMockStorage();
    final settingsProvider = SettingsProvider(storage);
    final liftProvider = LiftProvider(storage);
    final programProvider = ProgramProvider(storage);
    final recoveryProvider = RecoveryProvider(storage);
    final bodyCompProvider = BodyCompProvider(storage);
    final nutritionProvider = NutritionProvider(storage);

    Widget buildAppWrapper(Widget child) {
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
            body: child,
          ),
        ),
      );
    }

    Future<void> takeAppScreenshot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot(name);
    }

    Future<void> takeScrollingScreenshots(String baseName, {double dragDistance = 600.0}) async {
      await takeAppScreenshot(baseName);
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, Offset(0, -dragDistance));
        await tester.pump(const Duration(milliseconds: 300));
        await takeAppScreenshot('${baseName}_scrolled');
      }
    }

    // 01 DASHBOARD SCREEN (Top & Scrolled)
    await tester.pumpWidget(buildAppWrapper(const DashboardScreen()));
    await takeScrollingScreenshots('01_dashboard_screen', dragDistance: 500.0);

    // 02 LIFTS MATRIX SCREEN
    await tester.pumpWidget(buildAppWrapper(const LiftsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    if (find.text('Snatch').evaluate().isNotEmpty) {
      await tester.tap(find.text('Snatch').first);
      await tester.pump(const Duration(milliseconds: 300));
    }
    await takeAppScreenshot('02_lifts_matrix_screen');

    // 03 LIFTS RATIO BALANCE SCREEN
    await tester.pumpWidget(buildAppWrapper(const LiftsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    if (find.text('Ratio Balance').evaluate().isNotEmpty) {
      await tester.tap(find.text('Ratio Balance'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await takeAppScreenshot('03_lift_ratios_screen');

    // 04 STANDARD RATIOS SHEET
    await tester.pumpWidget(buildAppWrapper(const StandardRatiosSheet()));
    await takeAppScreenshot('04_standard_ratios_sheet');

    // 05 PLATE CALCULATOR SCREEN
    await tester.pumpWidget(buildAppWrapper(const PlateCalculatorScreen()));
    await takeAppScreenshot('05_plate_calculator_screen');

    // 06 MAX TEST SCREEN
    await tester.pumpWidget(buildAppWrapper(const MaxTestScreen()));
    await takeAppScreenshot('06_max_test_screen');

    // 07 ANALYTICS SCREEN (Workouts Tab)
    await tester.pumpWidget(buildAppWrapper(const AnalyticsScreen()));
    await takeScrollingScreenshots('07_analytics_screen', dragDistance: 500.0);

    // 07b ACCESSORY PROGRESSIONS TAB
    await tester.tap(find.text('Accessories'));
    await tester.pump(const Duration(milliseconds: 300));
    await takeAppScreenshot('07b_accessory_progressions_screen');

    // 08 WARMUP SESSION SCREEN
    final day1 = ProgramCycle.getBuiltInProgram().first;
    await tester.pumpWidget(buildAppWrapper(WarmupSessionScreen(dayTemplate: day1)));
    await tester.pump(const Duration(milliseconds: 300));
    await takeAppScreenshot('08_warmup_session_screen');

    // 09 WORKOUT SESSION SCREEN (Top & Scrolled)
    await tester.pumpWidget(buildAppWrapper(WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2)));
    await takeScrollingScreenshots('09_workout_session_screen', dragDistance: 600.0);

    // 10 WORKOUT SWAP MODAL
    final exercise = ExerciseTemplate(
      name: 'Power Snatch + Overhead Squat',
      liftId: 'snatch',
      setScheme: '4 Sets of 2 Reps',
      weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
    );
    await tester.pumpWidget(
      buildAppWrapper(
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
    await takeAppScreenshot('10_workout_swap_modal');

    // 11 WORKOUT WEIGHT & 1RM RECALC DIALOG
    await tester.pumpWidget(
      buildAppWrapper(
        Stack(
          children: [
            WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2),
            Container(color: Colors.black.withOpacity(0.65)),
            Align(
              alignment: Alignment.bottomCenter,
              child: WorkoutWeightDialog(
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
          ],
        ),
      ),
    );
    await takeAppScreenshot('11_workout_weight_dialog');

    // 12 ACTIVE RECOVERY SESSION SCREEN
    final routine = RecoveryEngineService.generateRoutine(
      ratioAnalyses: liftProvider.getRatioAnalysis(),
      lastSession: programProvider.sessions.isNotEmpty ? programProvider.sessions.first : null,
    );
    await tester.pumpWidget(buildAppWrapper(RecoverySessionScreen(routine: routine)));
    await tester.pump(const Duration(milliseconds: 300));
    await takeAppScreenshot('12_recovery_session_screen');

    // 13 MOBILITY & RECOVERY SWAP MODAL
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
      buildAppWrapper(
        Stack(
          children: [
            RecoverySessionScreen(routine: routine),
            Container(color: Colors.black.withOpacity(0.65)),
            Align(
              alignment: Alignment.bottomCenter,
              child: MobilityExerciseSwapModal(
                exercise: mobilityEx,
                onSwapSelected: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
    await takeAppScreenshot('13_mobility_swap_modal');

    // 14 NUTRITION & ENERGY BALANCE DASHBOARD (Top & Scrolled)
    await tester.pumpWidget(buildAppWrapper(const NutritionDashboardScreen()));
    await takeScrollingScreenshots('14_nutrition_dashboard_screen', dragDistance: 500.0);

    // 15 METABOLIC SCIENCE EXPLAINER SCREEN (Top & Scrolled)
    await tester.pumpWidget(buildAppWrapper(const MetabolicScienceExplainerScreen()));
    await takeScrollingScreenshots('15_metabolic_science_explainer_screen', dragDistance: 600.0);

    // 16 FOOD SEARCH & RECENT PANTRY ITEMS SHEET
    await tester.pumpWidget(buildAppWrapper(const FoodSearchSheet()));
    await takeAppScreenshot('16_food_search_sheet');

    // 17 SMART PORTION & ATHLETE MACRO DRAWER
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
      buildAppWrapper(
        const SmartPortionDrawer(initialFoodItem: testFood, defaultCategory: MealCategory.snack),
      ),
    );
    await takeAppScreenshot('17_smart_portion_drawer');

    // 18 LIVE CONTINUOUS BARCODE SCANNER
    await tester.pumpWidget(buildAppWrapper(const LiveBarcodeScannerSheet()));
    await tester.pump(const Duration(milliseconds: 200));
    await takeAppScreenshot('18_live_barcode_scanner_sheet');

    // 19 RENPHO SCALE OCR SCANNER & BODY DONUT CHART
    await tester.pumpWidget(buildAppWrapper(const RenphoScannerSheet()));
    await tester.pump(const Duration(milliseconds: 300));
    await takeAppScreenshot('19_renpho_scanner_sheet');

    // 20 SYSTEM DIAGNOSTICS & CRASH REPORT SCREEN
    await tester.pumpWidget(buildAppWrapper(const CrashReportScreen()));
    await tester.pump(const Duration(milliseconds: 200));
    await takeAppScreenshot('20_crash_report_screen');
  });
}
