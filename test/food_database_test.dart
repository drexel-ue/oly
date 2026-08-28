import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/services/food_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Food Database & Barcode Intelligence Tests', () {
    test('Scales FoodItem macros accurately for serving size multipliers', () {
      const item = FoodItem(
        id: 'staple_chicken',
        name: 'Chicken Breast',
        servingSize: '100g',
        servingWeightGrams: 100,
        calories: 165,
        protein: 31.0,
        carbs: 0.0,
        fat: 3.6,
        source: 'offline_staple',
      );

      final entry = item.toNutritionEntry(
        mealCategory: MealCategory.lunch,
        servingMultiplier: 2.0, // 200g
      );

      expect(entry.name, equals('Chicken Breast'));
      expect(entry.calories, equals(330));
      expect(entry.proteinGrams, closeTo(62.0, 0.1));
      expect(entry.carbsGrams, equals(0.0));
      expect(entry.fatGrams, closeTo(7.2, 0.1));
      expect(entry.portion, equals('2.0x (100g)'));
    });

    test('Parses Open Food Facts Barcode API responses accurately', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('737628064502')) {
          final body = {
            'status': 1,
            'product': {
              'code': '737628064502',
              'product_name': 'Pure Protein Bar Chocolate Peanut Butter',
              'brands': 'Pure Protein',
              'serving_size': '50g',
              'serving_quantity': 50,
              'nutriments': {
                'energy-kcal_serving': 200,
                'proteins_serving': 20.0,
                'carbohydrates_serving': 17.0,
                'fat_serving': 6.0,
                'fiber_serving': 2.0,
              },
            },
          };
          return http.Response(jsonEncode(body), 200);
        }
        return http.Response('{"status": 0}', 404);
      });

      final service = FoodDatabaseService(client: mockClient);
      final item = await service.lookupBarcode('737628064502');

      expect(item, isNotNull);
      expect(item!.name, equals('Pure Protein Bar Chocolate Peanut Butter'));
      expect(item.brand, equals('Pure Protein'));
      expect(item.calories, equals(200));
      expect(item.protein, equals(20.0));
      expect(item.carbs, equals(17.0));
      expect(item.fat, equals(6.0));
      expect(item.fiber, equals(2.0));
      expect(item.barcode, equals('737628064502'));
      expect(item.source, equals('open_food_facts'));
    });

    test('Computes athlete protein density and macro calorie percentages correctly', () {
      const highProteinFood = FoodItem(
        id: 'whey_isolate',
        name: 'Whey Protein Isolate',
        servingSize: '30g scoop',
        servingWeightGrams: 30,
        calories: 120,
        protein: 25.0,
        carbs: 1.0,
        fat: 1.0,
        source: 'offline_staple',
      );

      // Protein density: 25g / (120/100) = 20.83g P / 100 kcal
      expect(highProteinFood.proteinDensity, closeTo(20.83, 0.1));
      expect(highProteinFood.proteinDensityLabel, equals('20.8g P / 100 kcal'));
      expect(highProteinFood.isHighProtein, isTrue);
      expect(highProteinFood.proteinCaloriePct, greaterThan(80.0));
    });

    test('Loads and searches bundled staple foods dataset successfully', () async {
      final service = FoodDatabaseService();
      final staples = await service.getStapleFoods();

      expect(staples.length, greaterThanOrEqualTo(100));

      final chickenMatches = await service.searchStapleFoods('chicken');
      expect(chickenMatches.isNotEmpty, isTrue);
      expect(chickenMatches.any((f) => f.name.contains('Breast')), isTrue);

      final riceMatches = await service.searchStapleFoods('rice');
      expect(riceMatches.isNotEmpty, isTrue);

      final salmonMatches = await service.searchStapleFoods('salmon');
      expect(salmonMatches.isNotEmpty, isTrue);
    });
  });
}
