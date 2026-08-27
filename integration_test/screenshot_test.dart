import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/views/dashboard_screen.dart';
import 'package:oly/views/lifts_screen.dart';
import 'package:oly/views/max_test_screen.dart';
import 'package:oly/views/plate_calculator_screen.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';
import 'package:oly/widgets/standard_ratios_sheet.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import '../test/utils/mock_data_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture high-res screenshots of all Oly screens with mock data', (tester) async {
    final storage = await MockDataHelper.setupMockStorage();
    final settingsProvider = SettingsProvider(storage);
    final liftProvider = LiftProvider(storage);
    final programProvider = ProgramProvider(storage);
    final recoveryProvider = RecoveryProvider(storage);

    Widget buildAppWrapper(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: liftProvider),
          ChangeNotifierProvider.value(value: programProvider),
          ChangeNotifierProvider.value(value: recoveryProvider),
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
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot(name);
    }

    // 01 DASHBOARD SCREEN
    await tester.pumpWidget(buildAppWrapper(const DashboardScreen()));
    await takeAppScreenshot('01_dashboard_screen');

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

    // 07 ANALYTICS SCREEN
    await tester.pumpWidget(buildAppWrapper(const AnalyticsScreen()));
    await takeAppScreenshot('07_analytics_screen');

    // 08 WARMUP SESSION SCREEN
    final day1 = ProgramCycle.getBuiltInProgram().first;
    await tester.pumpWidget(buildAppWrapper(WarmupSessionScreen(dayTemplate: day1)));
    await takeAppScreenshot('08_warmup_session_screen');

    // 09 WORKOUT SESSION SCREEN
    await tester.pumpWidget(buildAppWrapper(WorkoutSessionScreen(dayTemplate: day1, previewWeek: 2)));
    await takeAppScreenshot('09_workout_session_screen');

    // 10 WORKOUT SWAP MODAL
    final exercise = ExerciseTemplate(
      name: 'Power Snatch + Overhead Squat',
      liftId: 'snatch',
      setScheme: '4 Sets of 2 Reps',
      weekPercentages: {1: 65.0, 2: 70.0, 3: 75.0, 4: 70.0},
    );
    await tester.pumpWidget(
      buildAppWrapper(
        ExerciseSwapModal(
          exercise: exercise,
          currentWeek: 2,
          onSwapSelected: (_) {},
        ),
      ),
    );
    await takeAppScreenshot('10_workout_swap_modal');

    // 11 WORKOUT WEIGHT & 1RM RECALC DIALOG
    await tester.pumpWidget(
      buildAppWrapper(
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
    await takeAppScreenshot('11_workout_weight_dialog');

    // 12 ACTIVE RECOVERY SESSION SCREEN
    final routine = RecoveryEngineService.generateRoutine(
      ratioAnalyses: liftProvider.getRatioAnalysis(),
      lastSession: programProvider.sessions.isNotEmpty ? programProvider.sessions.first : null,
    );
    await tester.pumpWidget(buildAppWrapper(RecoverySessionScreen(routine: routine)));
    await takeAppScreenshot('12_recovery_session_screen');
  });
}
