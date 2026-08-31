import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/usda_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late UsdaDatabaseService usdaService;
  final String dbPath = '${Directory.current.path}/assets/data/usda_foods.db';

  setUp(() async {
    usdaService = UsdaDatabaseService(dbPath: dbPath);
    await usdaService.initDatabase();
    UsdaDatabaseService.setMockInstance(usdaService);
  });

  tearDown(() async {
    await usdaService.close();
    UsdaDatabaseService.setMockInstance(null);
  });

  group('USDA SQLite Database & FTS5 Intelligence Tests', () {
    test('Initializes SQLite database and returns valid database statistics', () async {
      final Map<String, dynamic> stats = await usdaService.getDatabaseStats();
      expect(stats['available'], isTrue);
      expect(stats['totalFoods'], isPositive);
      expect(stats['totalBrands'], isPositive);
    });

    test('Searches Wingstop items via FTS5 full text search', () async {
      final List<FoodItem> results = await usdaService.searchFoods('wingstop');
      expect(results.isNotEmpty, isTrue);

      final FoodItem first = results.firstWhere(
        (FoodItem f) => f.name.contains('Lemon Pepper'),
      );
      expect(first.brand, equals('Wingstop'));
      expect(first.servingUnitName, equals('wing'));
      expect(first.calories, isPositive);
      expect(first.protein, isPositive);
    });

    test("Searches McDonald's items with comprehensive menu variety", () async {
      final List<FoodItem> results = await usdaService.searchFoods('mcdonald');
      expect(results.length, greaterThanOrEqualTo(30));

      final bool hasBigMac = results.any((FoodItem f) => f.name.contains('Big Mac'));
      final bool hasNuggets = results.any((FoodItem f) => f.name.contains('McNuggets'));
      final bool hasMcMuffin = results.any((FoodItem f) => f.name.contains('McMuffin'));
      final bool hasFries = results.any((FoodItem f) => f.name.contains('Fries'));

      expect(hasBigMac, isTrue);
      expect(hasNuggets, isTrue);
      expect(hasMcMuffin, isTrue);
      expect(hasFries, isTrue);
    });

    test('Searches staple whole foods (chicken breast, oats, salmon)', () async {
      final List<FoodItem> chicken = await usdaService.searchFoods('chicken breast');
      expect(chicken.isNotEmpty, isTrue);
      expect(chicken.any((FoodItem f) => f.protein >= 20.0), isTrue);

      final List<FoodItem> oats = await usdaService.searchFoods('oats');
      expect(oats.isNotEmpty, isTrue);
      expect(oats.any((FoodItem f) => f.name.toLowerCase().contains('oats')), isTrue);
    });

    test('Looks up foods directly by UPC barcode in SQLite index', () async {
      // Fairlife Chocolate Milk
      final FoodItem? food = await usdaService.lookupBarcode('811620020039');
      expect(food, isNotNull);
      expect(food!.brand?.toUpperCase(), contains('FAIRLIFE'));
      expect(food.protein, isPositive);
      expect(food.calories, isPositive);
    });

    test('FoodDatabaseService seamlessly falls back or uses SQLite database', () async {
      final FoodDatabaseService foodService = FoodDatabaseService();
      final List<FoodItem> results = await foodService.searchLocalFoods('cane');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((FoodItem f) => (f.brand ?? '').contains('Cane')), isTrue);
    });
  });
}
