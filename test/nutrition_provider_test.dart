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

    test('Deletes and restores food entry correctly (Undo)', () async {
      final NutritionEntry item = NutritionEntry.create(
        name: 'Snack Bar',
        calories: 200,
        category: MealCategory.snack,
      );
      await nutritionProvider.addFoodEntry(item);
      expect(nutritionProvider.currentDayLog.entries.length, equals(1));

      await nutritionProvider.deleteFoodEntry(item.id);
      expect(nutritionProvider.currentDayLog.entries.length, equals(0));

      await nutritionProvider.restoreFoodEntry(item);
      expect(nutritionProvider.currentDayLog.entries.length, equals(1));
      expect(nutritionProvider.currentDayLog.entries.first.name, equals('Snack Bar'));
    });

    test('Updates food entry details (name, calories, macros, portion)', () async {
      final NutritionEntry item = NutritionEntry.create(
        name: 'Greek Yogurt',
        calories: 120,
        proteinGrams: 15,
        carbsGrams: 8,
        fatGrams: 0,
        category: MealCategory.breakfast,
      );
      await nutritionProvider.addFoodEntry(item);

      final NutritionEntry updated = item.copyWith(
        name: 'Greek Yogurt with Blueberries',
        calories: 180,
        proteinGrams: 18,
        carbsGrams: 20,
        fatGrams: 2,
        portion: '1 cup yogurt + 0.5 cup berries',
      );
      await nutritionProvider.updateFoodEntry(updated);

      final DailyNutritionLog log = nutritionProvider.currentDayLog;
      expect(log.entries.length, equals(1));
      expect(log.entries.first.name, equals('Greek Yogurt with Blueberries'));
      expect(log.entries.first.calories, equals(180));
      expect(log.entries.first.proteinGrams, equals(18.0));
      expect(log.entries.first.carbsGrams, equals(20.0));
      expect(log.entries.first.fatGrams, equals(2.0));
      expect(log.entries.first.portion, equals('1 cup yogurt + 0.5 cup berries'));
      expect(log.totalCalories, equals(180));
      expect(log.totalProtein, equals(18.0));
    });

    test('Moves food entry across meal sections / categories', () async {
      final NutritionEntry item = NutritionEntry.create(
        name: 'Grilled Steak & Sweet Potato',
        calories: 650,
        proteinGrams: 50,
        carbsGrams: 45,
        fatGrams: 22,
        category: MealCategory.lunch,
      );
      await nutritionProvider.addFoodEntry(item);

      expect(
        nutritionProvider.currentDayLog.getEntriesForCategory(MealCategory.lunch).length,
        equals(1),
      );
      expect(
        nutritionProvider.currentDayLog.getEntriesForCategory(MealCategory.dinner).length,
        equals(0),
      );

      // Move from Lunch to Dinner via updateFoodEntry
      final NutritionEntry moved = item.copyWith(category: MealCategory.dinner);
      await nutritionProvider.updateFoodEntry(moved);

      expect(
        nutritionProvider.currentDayLog.getEntriesForCategory(MealCategory.lunch).length,
        equals(0),
      );
      expect(
        nutritionProvider.currentDayLog.getEntriesForCategory(MealCategory.dinner).length,
        equals(1),
      );
      expect(
        nutritionProvider.currentDayLog.getCaloriesForCategory(MealCategory.dinner),
        equals(650),
      );

      // Move from Dinner to Post-Workout via moveFoodEntry
      await nutritionProvider.moveFoodEntry(item.id, MealCategory.postWorkout);
      expect(
        nutritionProvider.currentDayLog.getEntriesForCategory(MealCategory.dinner).length,
        equals(0),
      );
      expect(
        nutritionProvider.currentDayLog.getEntriesForCategory(MealCategory.postWorkout).length,
        equals(1),
      );
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
