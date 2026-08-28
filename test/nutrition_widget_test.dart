import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/nutrition/body_comp_analytics_screen.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'package:oly/widgets/nutrition/body_donut_chart.dart';
import 'package:oly/widgets/nutrition/macro_ring_card.dart';
import 'package:oly/widgets/nutrition/renpho_stat_pill.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late BodyCompProvider bodyCompProvider;
  late NutritionProvider nutritionProvider;
  late LiftProvider liftProvider;
  late ProgramProvider programProvider;
  late RecoveryProvider recoveryProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    bodyCompProvider = BodyCompProvider(storage);
    nutritionProvider = NutritionProvider(storage);
    liftProvider = LiftProvider(storage);
    programProvider = ProgramProvider(storage);
    recoveryProvider = RecoveryProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  Widget buildTestableWidget(Widget child) {
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
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Nutrition & BodyComp Widget Tests', () {
    testWidgets('MacroRingCard renders remaining calories and macro bars', (tester) async {
      final log = DailyNutritionLog.create(
        date: '2026-07-21',
        targetCalories: 2600,
        targetProteinGrams: 220,
        targetCarbsGrams: 280,
        targetFatGrams: 75,
        entries: [
          NutritionEntry.create(
            name: 'Breakfast Burrito',
            calories: 600,
            proteinGrams: 40,
            carbsGrams: 50,
            fatGrams: 20,
            category: MealCategory.breakfast,
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: MacroRingCard(log: log),
        ),
      ));

      expect(find.text('DAILY TARGET'), findsOneWidget);
      expect(find.text('2000'), findsOneWidget); // 2600 - 600 = 2000 remaining
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fats'), findsOneWidget);
    });

    testWidgets('BodyDonutChart renders Renpho metrics breakdown', (tester) async {
      final entry = BodyCompositionEntry.create(
        weightLb: 264.8,
        bodyFatLb: 56.2,
        bodyFatPct: 21.2,
        bodyWaterLb: 150.6,
        bodyWaterPct: 56.9,
        proteinLb: 47.6,
        proteinPct: 18.0,
        boneMassLb: 10.4,
        boneMassPct: 3.9,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: BodyDonutChart(entry: entry),
        ),
      ));

      expect(find.text('BODY COMPOSITION BREAKDOWN'), findsOneWidget);
      expect(find.text('264.8'), findsOneWidget);
      expect(find.text('Body Water'), findsOneWidget);
      expect(find.text('Protein / Muscle'), findsOneWidget);
      expect(find.text('Body Fat'), findsOneWidget);
      expect(find.text('Bone Mass'), findsOneWidget);
    });

    testWidgets('RenphoStatPill renders metric and deltas', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: RenphoStatPill(
            icon: Icons.scale,
            label: 'Fat-Free Mass',
            value: '208.6',
            unit: 'lb',
            status: 'Average',
            delta: 0.4,
          ),
        ),
      ));

      expect(find.text('Fat-Free Mass'), findsOneWidget);
      expect(find.text('208.6'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('+0.4'), findsOneWidget);
    });

    testWidgets('NutritionDashboardScreen renders full dashboard', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const NutritionDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nutrition & Energy'), findsOneWidget);
      expect(find.text('DAILY ENERGY BALANCE'), findsOneWidget);
      expect(find.text('RENPHO SCALE BIOMETRICS'), findsOneWidget);
      expect(find.text('Daily Hydration'), findsOneWidget);
      expect(find.text('+24oz'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Log Food'), findsOneWidget);

      // Switch to Macro Targets
      await tester.tap(find.text('Macro Targets'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY TARGET'), findsOneWidget);

      // Scroll and tap +24oz water button
      await tester.ensureVisible(find.text('+24oz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+24oz'));
      await tester.pumpAndSettle();
      expect(find.textContaining('24 oz'), findsOneWidget);
    });

    testWidgets('BodyCompAnalyticsScreen renders goal calculator and history', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BodyCompAnalyticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Body Composition Intelligence'), findsOneWidget);
      expect(find.text('LEAN MASS PRESERVATION GOAL'), findsOneWidget);
      expect(find.text('BODY COMPOSITION TREND'), findsOneWidget);
      expect(find.text('LATEST RENPHO BIOMETRICS'), findsOneWidget);
    });
  });
}
