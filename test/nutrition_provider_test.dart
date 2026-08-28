import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nutrition & BodyComp Provider Tests', () {
    late StorageService storage;
    late NutritionProvider nutritionProvider;
    late BodyCompProvider bodyCompProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      bodyCompProvider = BodyCompProvider(storage);
      nutritionProvider = NutritionProvider(storage);
    });

    test('Initializes with baseline Renpho scan', () {
      expect(bodyCompProvider.hasEntries, isTrue);
      expect(bodyCompProvider.latestEntry!.weightLb, closeTo(264.8, 0.01));
      expect(
        bodyCompProvider.latestEntry!.leanBodyMassLb,
        closeTo(208.6, 0.01),
      );
    });

    test(
      'Logs food entry and calculates correct macro and calorie sums',
      () async {
        await nutritionProvider.addFoodEntry(
          NutritionEntry.create(
            name: 'Chicken and Rice',
            calories: 550,
            proteinGrams: 45,
            carbsGrams: 60,
            fatGrams: 10,
            category: MealCategory.lunch,
          ),
        );

        await nutritionProvider.addFoodEntry(
          NutritionEntry.create(
            name: 'Whey Protein Shake',
            calories: 140,
            proteinGrams: 25,
            carbsGrams: 3,
            fatGrams: 2,
            category: MealCategory.postWorkout,
          ),
        );

        final DailyNutritionLog log = nutritionProvider.currentDayLog;
        expect(log.entries.length, equals(2));
        expect(log.totalCalories, equals(690));
        expect(log.totalProtein, equals(70.0));
        expect(log.totalCarbs, equals(63.0));
        expect(log.totalFat, equals(12.0));
      },
    );

    test('Quick adds calories and water', () async {
      await nutritionProvider.quickAddCalories(calories: 300, protein: 20);
      await nutritionProvider.addWater(16);

      final DailyNutritionLog log = nutritionProvider.currentDayLog;
      expect(log.totalCalories, equals(300));
      expect(log.waterOz, equals(16.0));
    });

    test('Deletes food entry correctly', () async {
      final NutritionEntry item = NutritionEntry.create(
        name: 'Snack Bar',
        calories: 200,
        category: MealCategory.snack,
      );
      await nutritionProvider.addFoodEntry(item);
      expect(nutritionProvider.currentDayLog.entries.length, equals(1));

      await nutritionProvider.deleteFoodEntry(item.id);
      expect(nutritionProvider.currentDayLog.entries.length, equals(0));
    });

    test('Adds new Renpho scan and calculates scan deltas', () async {
      final BodyCompositionEntry newScan = BodyCompositionEntry.create(
        timestamp: DateTime(2026, 8, 1),
        weightLb: 262.5,
        bodyFatPct: 20.4,
        bodyFatLb: 53.55,
        skeletalMuscleLb: 135.0,
        fatFreeMassLb: 208.95,
      );

      await bodyCompProvider.addEntry(newScan);

      expect(bodyCompProvider.latestEntry!.weightLb, equals(262.5));
      expect(
        bodyCompProvider.weightDeltaVsPrevious,
        closeTo(-2.3, 0.01),
      ); // -2.3 lb
      expect(
        bodyCompProvider.bodyFatPctDeltaVsPrevious,
        closeTo(-0.8, 0.01),
      ); // -0.8%
      expect(
        bodyCompProvider.leanMassDeltaVsPrevious,
        greaterThan(0),
      ); // Lean mass preserved/increased!
    });
  });
}
