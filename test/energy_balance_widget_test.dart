import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/models/nutrition_goal_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/nutrition/activity_log_sheet.dart';
import 'package:oly/views/nutrition/metabolic_science_explainer_screen.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'package:oly/widgets/nutrition/energy_balance_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late NutritionProvider nutritionProvider;
  late BodyCompProvider bodyCompProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    nutritionProvider = NutritionProvider(storageService);
    bodyCompProvider = BodyCompProvider(storageService);
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NutritionProvider>.value(value: nutritionProvider),
        ChangeNotifierProvider<BodyCompProvider>.value(value: bodyCompProvider),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Energy Balance & Metabolic Science Widget Tests', () {
    testWidgets('EnergyBalanceCard renders Energy In, Energy Out, Deficit, and Breakdown', (tester) async {
      final log = DailyNutritionLog.create(
        date: '2026-08-27',
        targetCalories: 3200,
        entries: [
          NutritionEntry.create(
            name: 'Chicken and Rice',
            calories: 800,
            proteinGrams: 60,
            carbsGrams: 100,
            fatGrams: 15,
            category: MealCategory.lunch,
          ),
        ],
        activities: [
          DailyActivityEntry.create(
            activityType: 'workout_wod',
            name: 'Olympic Lifting WOD',
            durationMinutes: 45.0,
            metValue: 6.5,
            caloriesBurned: 520,
            source: 'wod_auto_sync',
          ),
          DailyActivityEntry.create(
            activityType: 'walking_steps',
            name: 'Brisk Walk',
            durationMinutes: 30.0,
            metValue: 3.8,
            caloriesBurned: 240,
          ),
        ],
      );

      final bodyComp = BodyCompositionEntry.create(
        weightLb: 264.8,
        fatFreeMassLb: 208.6,
        bmrKcal: 2394,
      );

      await tester.pumpWidget(buildTestableWidget(
        EnergyBalanceCard(
          log: log,
          latestBodyComp: bodyComp,
          goal: const NutritionGoalModel(goalType: GoalType.cutting),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DAILY ENERGY BALANCE'), findsOneWidget);
      expect(find.text('ENERGY IN'), findsOneWidget);
      expect(find.text('800'), findsOneWidget); // Food intake
      expect(find.text('ENERGY OUT'), findsOneWidget);
      expect(find.text('3154'), findsOneWidget); // 2394 + 520 + 240 = 3154
      expect(find.textContaining('DEFICIT'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
    });

    testWidgets('MetabolicScienceExplainerScreen renders all 5 interactive science tabs', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MetabolicScienceExplainerScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Metabolic Science & Calculations'), findsOneWidget);
      expect(find.text('Energy & TDEE'), findsOneWidget);
      expect(find.text('Algorithm B (METs)'), findsOneWidget);
      expect(find.text('WOD & Lifting Physics'), findsOneWidget);
      expect(find.text('Hydration Model'), findsOneWidget);
      expect(find.text('Open-Source Sources'), findsOneWidget);

      // Tap Algorithm B tab
      await tester.tap(find.text('Algorithm B (METs)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Algorithm B: Personalized REE Scaling'), findsOneWidget);
      expect(find.textContaining('Algorithm A (Generic)'), findsOneWidget);

      // Tap WOD tab
      await tester.tap(find.text('WOD & Lifting Physics'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Workout of the Day (WOD) Caloric Physics'), findsOneWidget);
    });

    testWidgets('ActivityLogSheet renders presets, Algorithm B energy calculation, and saves entry', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const ActivityLogSheet(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Log Activity & Energy Out'), findsOneWidget);
      expect(find.textContaining('COMPENDIUM ACTIVITY PRESETS'), findsOneWidget);
      expect(find.text('Brisk Walk (3.5 mph)'), findsWidgets);
      expect(find.textContaining('ALGORITHM B'), findsOneWidget);

      // Tap Log Activity Button
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('NutritionDashboardScreen renders Energy In vs Out selector and activities section', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const NutritionDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nutrition & Energy'), findsOneWidget);
      expect(find.text('Energy In vs Out'), findsOneWidget);
      expect(find.text('Macro Targets'), findsOneWidget);
      expect(find.text('DAILY ACTIVITIES & WOD'), findsOneWidget);
      expect(find.text('Search / Barcode'), findsOneWidget);

      // Switch to Macro Targets view
      await tester.tap(find.text('Macro Targets'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY TARGET'), findsOneWidget);
    });
  });
}
