import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Food Database & Barcode Intelligence Tests', () {
    test('Scales FoodItem macros accurately for serving size multipliers', () {
      const FoodItem item = FoodItem(
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

      final NutritionEntry entry = item.toNutritionEntry(
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
      final MockClient mockClient = MockClient((http.Request request) async {
        if (request.url.path.contains('999999000001')) {
          final Map<String, Object> body = <String, Object>{
            'status': 1,
            'product': <String, Object>{
              'code': '999999000001',
              'product_name': 'Pure Protein Bar Chocolate Peanut Butter',
              'brands': 'Pure Protein',
              'serving_size': '50g',
              'serving_quantity': 50,
              'nutriments': <String, num>{
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

      final FoodDatabaseService service = FoodDatabaseService(
        client: mockClient,
      );
      final FoodItem? item = await service.lookupBarcode('999999000001');

      expect(item, isNotNull);
      expect(item!.name, equals('Pure Protein Bar Chocolate Peanut Butter'));
      expect(item.brand, equals('Pure Protein'));
      expect(item.calories, equals(200));
      expect(item.protein, equals(20.0));
      expect(item.carbs, equals(17.0));
      expect(item.fat, equals(6.0));
      expect(item.fiber, equals(2.0));
      expect(item.barcode, equals('999999000001'));
      expect(item.source, equals('open_food_facts'));
    });

    test('Computes athlete protein density and macro calorie percentages correctly', () {
      const FoodItem highProteinFood = FoodItem(
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

    test(
      'Loads and searches bundled staple foods dataset successfully',
      () async {
        final FoodDatabaseService service = FoodDatabaseService();
        final List<FoodItem> staples = await service.getStapleFoods();

        expect(staples.length, greaterThanOrEqualTo(100));

        final List<FoodItem> chickenMatches = await service.searchStapleFoods(
          'chicken',
        );
        expect(chickenMatches.isNotEmpty, isTrue);
        expect(
          chickenMatches.any((FoodItem f) => f.name.contains('Breast')),
          isTrue,
        );

        final List<FoodItem> riceMatches = await service.searchStapleFoods(
          'rice',
        );
        expect(riceMatches.isNotEmpty, isTrue);

        final List<FoodItem> salmonMatches = await service.searchStapleFoods(
          'salmon',
        );
        expect(salmonMatches.isNotEmpty, isTrue);
      },
    );

    test('Searches Wingstop and fast food restaurant catalog with piece units', () async {
      final FoodDatabaseService service = FoodDatabaseService();
      final List<FoodItem> restaurantFoods = await service.getRestaurantFoods();

      expect(restaurantFoods.isNotEmpty, isTrue);
      expect(restaurantFoods.any((FoodItem f) => f.brand == 'Wingstop'), isTrue);

      // Search for "wingstop"
      final List<FoodItem> wingstopMatches = await service.searchLocalFoods('wingstop');
      expect(wingstopMatches.length, greaterThanOrEqualTo(10));
      expect(wingstopMatches.any((FoodItem f) => f.name.contains('Lemon Pepper')), isTrue);
      expect(wingstopMatches.any((FoodItem f) => f.name.contains('Garlic Parmesan')), isTrue);
      expect(wingstopMatches.any((FoodItem f) => f.name.contains('Ranch')), isTrue);

      // Verify piece-based scaling for 10 wings
      final FoodItem lemonPepperWing = wingstopMatches.firstWhere(
        (FoodItem f) => f.name.contains('Lemon Pepper') && f.servingUnitName == 'wing',
      );
      final NutritionEntry tenWings = lemonPepperWing.toNutritionEntry(
        mealCategory: MealCategory.dinner,
        servingMultiplier: 10.0,
      );

      expect(tenWings.name, contains('Wingstop'));
      expect(tenWings.calories, equals(lemonPepperWing.calories * 10));
      expect(tenWings.proteinGrams, equals(lemonPepperWing.protein * 10));
      expect(tenWings.portion, equals('10 wings'));

      // Search for "chipotle"
      final List<FoodItem> chipotleMatches = await service.searchLocalFoods('chipotle');
      expect(chipotleMatches.isNotEmpty, isTrue);
      expect(chipotleMatches.any((FoodItem f) => f.name.contains('Chicken')), isTrue);
    });

    test('Parses USDA FoodData Central API search responses accurately', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        if (request.url.host.contains('nal.usda.gov')) {
          final Map<String, Object> body = <String, Object>{
            'foods': <Map<String, Object>>[
              <String, Object>{
                'fdcId': 123456,
                'description': 'WINGSTOP, CLASSIC WINGS, LEMON PEPPER',
                'brandOwner': 'Wingstop',
                'servingSize': 40.0,
                'servingSizeUnit': 'g',
                'householdServingFullText': '1 wing',
                'foodNutrients': <Map<String, Object>>[
                  <String, Object>{
                    'nutrientId': 1008,
                    'nutrientName': 'Energy',
                    'unitName': 'KCAL',
                    'value': 100.0,
                  },
                  <String, Object>{
                    'nutrientId': 1003,
                    'nutrientName': 'Protein',
                    'unitName': 'G',
                    'value': 8.0,
                  },
                  <String, Object>{
                    'nutrientId': 1005,
                    'nutrientName': 'Carbohydrate, by difference',
                    'unitName': 'G',
                    'value': 0.5,
                  },
                  <String, Object>{
                    'nutrientId': 1004,
                    'nutrientName': 'Total lipid (fat)',
                    'unitName': 'G',
                    'value': 7.5,
                  },
                ],
              },
            ],
          };
          return http.Response(jsonEncode(body), 200);
        }
        return http.Response('{"foods": []}', 200);
      });

      final FoodDatabaseService service = FoodDatabaseService(client: mockClient);
      final List<FoodItem> usdaFoods = await service.searchUsdaFoods('wingstop');

      expect(usdaFoods.isNotEmpty, isTrue);
      final FoodItem item = usdaFoods.first;
      expect(item.name, equals('WINGSTOP, CLASSIC WINGS, LEMON PEPPER'));
      expect(item.brand, equals('Wingstop'));
      expect(item.calories, equals(100));
      expect(item.protein, equals(8.0));
      expect(item.carbs, equals(0.5));
      expect(item.fat, equals(7.5));
      expect(item.source, equals('usda_fooddata'));
    });
  });
}
