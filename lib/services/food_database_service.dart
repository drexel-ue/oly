import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/services/usda_database_service.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.servingWeightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
    this.brand,
    this.category,
    this.fiber,
    this.barcode,
    this.imageUrl,
    this.servingUnitName,
  });

  factory FoodItem.fromJson(
    Map<String, dynamic> json, {
    String defaultSource = 'offline_staple',
  }) {
    return FoodItem(
      id: json['id'] as String? ?? json['code'] as String? ?? '',
      name:
          json['name'] as String? ??
          json['product_name'] as String? ??
          'Food Item',
      brand: json['brand'] as String? ?? json['brands'] as String?,
      category: json['category'] as String?,
      servingSize:
          json['servingSize'] as String? ??
          json['serving_size'] as String? ??
          '100g',
      servingWeightGrams:
          (json['servingWeightGrams'] as num?)?.toDouble() ?? 100.0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      barcode: json['barcode'] as String? ?? json['code'] as String?,
      source: json['source'] as String? ?? defaultSource,
      imageUrl:
          json['imageUrl'] as String? ?? json['image_front_url'] as String?,
      servingUnitName: json['servingUnitName'] as String?,
    );
  }
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final String servingSize;
  final double servingWeightGrams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final String? barcode;
  final String source; // 'offline_staple', 'open_food_facts', 'usda'
  final String? imageUrl;
  final String? servingUnitName;

  /// Athlete Protein Density: grams of protein per 100 kcal
  double get proteinDensity =>
      calories > 0 ? (protein / (calories / 100.0)) : 0.0;

  String get proteinDensityLabel =>
      '${proteinDensity.toStringAsFixed(1)}g P / 100 kcal';

  bool get isHighProtein => proteinDensity >= 10.0 || proteinCaloriePct >= 35.0;

  double get proteinCaloriePct => calories > 0
      ? ((protein * 4.0) / calories * 100.0).clamp(0.0, 100.0)
      : 0.0;
  double get carbsCaloriePct =>
      calories > 0 ? ((carbs * 4.0) / calories * 100.0).clamp(0.0, 100.0) : 0.0;
  double get fatCaloriePct =>
      calories > 0 ? ((fat * 9.0) / calories * 100.0).clamp(0.0, 100.0) : 0.0;

  NutritionEntry toNutritionEntry({
    required MealCategory mealCategory,
    double servingMultiplier = 1.0,
    double? customGrams,
  }) {
    final double effectiveMultiplier =
        customGrams != null && servingWeightGrams > 0
        ? (customGrams / servingWeightGrams)
        : servingMultiplier;

    final int scaledCalories = (calories * effectiveMultiplier).round();
    final double scaledProtein = protein * effectiveMultiplier;
    final double scaledCarbs = carbs * effectiveMultiplier;
    final double scaledFat = fat * effectiveMultiplier;

    final String displayName = brand != null && brand!.isNotEmpty
        ? '$brand - $name'
        : name;

    final String portionLabel = customGrams != null
        ? '${customGrams.round()}g'
        : (servingUnitName != null
              ? '${servingMultiplier == servingMultiplier.roundToDouble() ? servingMultiplier.round() : servingMultiplier} $servingUnitName${servingMultiplier > 1 && !servingUnitName!.endsWith("s") ? "s" : ""}'
              : (servingMultiplier == 1.0
                    ? servingSize
                    : '${servingMultiplier.toStringAsFixed(1)}x ($servingSize)'));

    return NutritionEntry.create(
      name: displayName,
      category: mealCategory,
      calories: scaledCalories,
      proteinGrams: scaledProtein,
      carbsGrams: scaledCarbs,
      fatGrams: scaledFat,
      portion: portionLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'servingSize': servingSize,
      'servingWeightGrams': servingWeightGrams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'barcode': barcode,
      'source': source,
      'imageUrl': imageUrl,
      'servingUnitName': servingUnitName,
    };
  }
}

class FoodDatabaseService {
  FoodDatabaseService({http.Client? client})
    : _client = client ?? http.Client() {
    _initOpenFoodFactsSdk();
  }
  final http.Client _client;
  static List<FoodItem>? _cachedStaples;
  static List<FoodItem>? _cachedRestaurants;

  /// Configures the official OpenFoodFacts SDK UserAgent
  static void _initOpenFoodFactsSdk() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'Oly',
      version: '1.0.0',
      url: 'https://lamontlabs.com',
      system: 'Flutter',
    );
  }

  /// Loads foundational staple foods from local bundled assets
  Future<List<FoodItem>> getStapleFoods() async {
    if (_cachedStaples != null) {
      return _cachedStaples!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/staple_foods.json',
      );
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      _cachedStaples = list
          .map(
            (item) => FoodItem.fromJson(
              item as Map<String, dynamic>,
              defaultSource: 'offline_staple',
            ),
          )
          .toList();
      return _cachedStaples!;
    } catch (e) {
      return <FoodItem>[];
    }
  }

  /// Loads fast food and restaurant chain menu items from bundled assets
  Future<List<FoodItem>> getRestaurantFoods() async {
    if (_cachedRestaurants != null) {
      return _cachedRestaurants!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/restaurant_foods.json',
      );
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      _cachedRestaurants = list
          .map(
            (item) => FoodItem.fromJson(
              item as Map<String, dynamic>,
              defaultSource: 'offline_restaurant',
            ),
          )
          .toList();
      return _cachedRestaurants!;
    } catch (e, stack) {
      AppLogService.instance.error(
        'FOOD_DB',
        'Failed to load restaurant_foods: $e',
        error: e,
        stackTrace: stack,
      );
      return <FoodItem>[];
    }
  }

  /// Searches local offline staples and restaurant menu items with relevance ranking
  Future<List<FoodItem>> searchLocalFoods(String query) async {
    final String clean = query.trim();

    // 1. Get in-memory cached staples and restaurant foods
    final List<FoodItem> staples = await getStapleFoods();
    final List<FoodItem> restaurants = await getRestaurantFoods();
    final List<FoodItem> allLocal = <FoodItem>[...restaurants, ...staples];

    // 2. Check local SQLite database if available
    try {
      final List<FoodItem> sqliteResults = await UsdaDatabaseService.instance
          .searchFoods(clean, limit: 60);
      if (sqliteResults.isNotEmpty) {
        final Set<String> seenIds = sqliteResults.map((FoodItem f) => f.id).toSet();
        final List<FoodItem> combined = <FoodItem>[
          ...sqliteResults,
          ...allLocal.where((FoodItem f) => !seenIds.contains(f.id)),
        ];
        AppLogService.instance.debug(
          'FOOD_DB',
          'searchLocalFoods("$clean"): SQLite returned ${sqliteResults.length} items, total combined ${combined.length}',
        );
        return combined;
      }
    } catch (e) {
      AppLogService.instance.warning(
        'FOOD_DB',
        'searchLocalFoods SQLite query failed, falling back to memory: $e',
      );
    }

    final String q = clean.toLowerCase();
    if (q.isEmpty) {
      return allLocal;
    }

    final List<String> tokens = q
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .toList();

    final List<MapEntry<FoodItem, int>> scored = <MapEntry<FoodItem, int>>[];

    for (final FoodItem item in allLocal) {
      int score = 0;
      final String nameLower = item.name.toLowerCase();
      final String brandLower = (item.brand ?? '').toLowerCase();
      final String catLower = (item.category ?? '').toLowerCase();

      // Exact brand match
      if (brandLower.isNotEmpty &&
          (brandLower == q || q.contains(brandLower) || brandLower.contains(q))) {
        score += 60;
      }

      // Exact name match or contains full query
      if (nameLower.contains(q)) {
        score += 50;
      }

      // Token matches
      int tokenMatches = 0;
      for (final String token in tokens) {
        if (brandLower.contains(token)) {
          score += 25;
          tokenMatches++;
        } else if (nameLower.contains(token)) {
          score += 15;
          tokenMatches++;
        } else if (catLower.contains(token)) {
          score += 10;
          tokenMatches++;
        }
      }

      if (tokenMatches == tokens.length && tokens.length > 1) {
        score += 30; // All tokens matched
      }

      if (score > 0) {
        scored.add(MapEntry<FoodItem, int>(item, score));
      }
    }

    scored.sort(
      (MapEntry<FoodItem, int> a, MapEntry<FoodItem, int> b) =>
          b.value.compareTo(a.value),
    );
    return scored.map((MapEntry<FoodItem, int> e) => e.key).toList();
  }

  /// Searches offline staple foods by query string
  Future<List<FoodItem>> searchStapleFoods(String query) async {
    final List<FoodItem> staples = await getStapleFoods();
    if (query.trim().isEmpty) {
      return staples;
    }

    final String q = query.toLowerCase().trim();
    return staples.where((FoodItem item) {
      return item.name.toLowerCase().contains(q) ||
          (item.category != null && item.category!.toLowerCase().contains(q)) ||
          (item.brand != null && item.brand!.toLowerCase().contains(q));
    }).toList();
  }

  /// Queries product by barcode using local cache first, then official OpenFoodFacts SDK
  Future<FoodItem?> lookupBarcode(
    String barcode, {
    bool forceRefresh = false,
    StorageService? storage,
  }) async {
    final String cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return null;
    }

    AppLogService.instance.info(
      'FOOD_DB',
      'Looking up barcode: $cleanBarcode (forceRefresh: $forceRefresh)',
    );

    // 1. Check local offline cache if not forcing a refresh
    if (!forceRefresh && storage != null) {
      final Map<String, dynamic>? cachedJson = storage
          .loadCachedProductsJson()[cleanBarcode];
      if (cachedJson != null) {
        AppLogService.instance.debug(
          'FOOD_DB',
          'Cache hit for barcode: $cleanBarcode',
        );
        await storage.addRecentScannedBarcode(cleanBarcode);
        return FoodItem.fromJson(cachedJson, defaultSource: 'open_food_facts');
      }
    }

    // 2. Query local SQLite USDA / Restaurant database
    try {
      final FoodItem? localSqliteFood = await UsdaDatabaseService.instance
          .lookupBarcode(cleanBarcode);
      if (localSqliteFood != null) {
        AppLogService.instance.info(
          'FOOD_DB',
          'Local SQLite hit for barcode: $cleanBarcode (${localSqliteFood.name})',
        );
        if (storage != null) {
          await storage.saveCachedProductJson(cleanBarcode, localSqliteFood.toJson());
          await storage.addRecentScannedBarcode(cleanBarcode);
        }
        return localSqliteFood;
      }
    } catch (_) {}

    // 3. Query using OpenFoodFacts SDK
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        cleanBarcode,
        version: ProductQueryVersion.v3,
        fields: <ProductField>[
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.SERVING_QUANTITY,
          ProductField.IMAGE_FRONT_URL,
        ],
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(
        configuration,
      );
      if (result.product != null) {
        final Product product = result.product!;
        final Nutriments? nutriments = product.nutriments;

        final String name = product.productName ?? 'Scanned Product';
        final String? brand = product.brands;
        final String servingSize = product.servingSize ?? '100g';
        final double servingWeight = product.servingQuantity ?? 100.0;

        final int cal =
            nutriments
                ?.getValue(Nutrient.energyKCal, PerSize.serving)
                ?.toInt() ??
            nutriments
                ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
                ?.toInt() ??
            ((nutriments?.getValue(
                          Nutrient.energyKJ,
                          PerSize.oneHundredGrams,
                        ) ??
                        0.0) /
                    4.184)
                .round();

        final double protein =
            nutriments?.getValue(Nutrient.proteins, PerSize.serving) ??
            nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ??
            0.0;

        final double carbs =
            nutriments?.getValue(Nutrient.carbohydrates, PerSize.serving) ??
            nutriments?.getValue(
              Nutrient.carbohydrates,
              PerSize.oneHundredGrams,
            ) ??
            0.0;

        final double fat =
            nutriments?.getValue(Nutrient.fat, PerSize.serving) ??
            nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ??
            0.0;

        final double? fiber =
            nutriments?.getValue(Nutrient.fiber, PerSize.serving) ??
            nutriments?.getValue(Nutrient.fiber, PerSize.oneHundredGrams);

        final FoodItem item = FoodItem(
          id: cleanBarcode,
          name: name,
          brand: brand,
          servingSize: servingSize,
          servingWeightGrams: servingWeight > 0 ? servingWeight : 100.0,
          calories: cal,
          protein: double.parse(protein.toStringAsFixed(1)),
          carbs: double.parse(carbs.toStringAsFixed(1)),
          fat: double.parse(fat.toStringAsFixed(1)),
          fiber: fiber != null ? double.parse(fiber.toStringAsFixed(1)) : null,
          barcode: cleanBarcode,
          source: 'open_food_facts',
          imageUrl: product.imageFrontUrl,
        );

        // Cache into local storage
        if (storage != null) {
          await storage.saveCachedProductJson(cleanBarcode, item.toJson());
          await storage.addRecentScannedBarcode(cleanBarcode);
        }

        return item;
      }
    } catch (e, stack) {
      AppLogService.instance.warning(
        'FOOD_DB',
        'SDK lookup failed for $cleanBarcode: $e',
        stackTrace: stack.toString(),
      );
    }

    // 3. Fallback direct HTTP REST query
    final Uri url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$cleanBarcode.json',
    );
    try {
      final http.Response response = await _client
          .get(
            url,
            headers: <String, String>{
              'User-Agent':
                  'OlyOlympicWeightliftingApp/1.0 (contact@lamontlabs.com)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['product'] != null) {
          final Map<String, dynamic> product =
              data['product'] as Map<String, dynamic>;
          final Map<String, dynamic> nutriments =
              product['nutriments'] as Map<String, dynamic>? ??
              <String, dynamic>{};

          final String name =
              product['product_name'] as String? ?? 'Scanned Product';
          final String? brand = product['brands'] as String?;
          final String servingSize =
              product['serving_size'] as String? ?? '100g';

          final int cal =
              (nutriments['energy-kcal_serving'] as num?)?.toInt() ??
              (nutriments['energy-kcal_100g'] as num?)?.toInt() ??
              (((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184)
                  .round();

          final double protein =
              (nutriments['proteins_serving'] as num?)?.toDouble() ??
              (nutriments['proteins_100g'] as num?)?.toDouble() ??
              0.0;

          final double carbs =
              (nutriments['carbohydrates_serving'] as num?)?.toDouble() ??
              (nutriments['carbohydrates_100g'] as num?)?.toDouble() ??
              0.0;

          final double fat =
              (nutriments['fat_serving'] as num?)?.toDouble() ??
              (nutriments['fat_100g'] as num?)?.toDouble() ??
              0.0;

          final double? fiber =
              (nutriments['fiber_serving'] as num?)?.toDouble() ??
              (nutriments['fiber_100g'] as num?)?.toDouble();

          final double servingWeight =
              (product['serving_quantity'] as num?)?.toDouble() ?? 100.0;

          final FoodItem item = FoodItem(
            id: cleanBarcode,
            name: name,
            brand: brand,
            servingSize: servingSize,
            servingWeightGrams: servingWeight,
            calories: cal,
            protein: double.parse(protein.toStringAsFixed(1)),
            carbs: double.parse(carbs.toStringAsFixed(1)),
            fat: double.parse(fat.toStringAsFixed(1)),
            fiber: fiber != null
                ? double.parse(fiber.toStringAsFixed(1))
                : null,
            barcode: cleanBarcode,
            source: 'open_food_facts',
            imageUrl: product['image_front_url'] as String?,
          );

          if (storage != null) {
            await storage.saveCachedProductJson(cleanBarcode, item.toJson());
            await storage.addRecentScannedBarcode(cleanBarcode);
          }

          return item;
        }
      }
    } catch (e, stack) {
      AppLogService.instance.error(
        'FOOD_DB',
        'HTTP fallback lookup failed for $cleanBarcode: $e',
        error: e,
        stackTrace: stack,
      );
    }

    return null;
  }

  /// Searches products in Open Food Facts by search query
  Future<List<FoodItem>> searchOnlineFoods(String query) async {
    final String q = Uri.encodeComponent(query.trim());
    if (q.isEmpty) {
      return <FoodItem>[];
    }

    final Uri url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$q&search_simple=1&action=process&json=1&page_size=12',
    );
    try {
      final http.Response response = await _client
          .get(
            url,
            headers: <String, String>{
              'User-Agent':
                  'OlyOlympicWeightliftingApp/1.0 (contact@lamontlabs.com)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> products =
            data['products'] as List<dynamic>? ?? <dynamic>[];

        final List<FoodItem> items = <FoodItem>[];
        for (final p in products) {
          final Map<String, dynamic> product = p as Map<String, dynamic>;
          final Map<String, dynamic> nutriments =
              product['nutriments'] as Map<String, dynamic>? ??
              <String, dynamic>{};
          final String name = product['product_name'] as String? ?? '';
          if (name.trim().isEmpty) {
            continue;
          }

          final String? brand = product['brands'] as String?;
          final String servingSize =
              product['serving_size'] as String? ?? '100g';
          final String code = product['code'] as String? ?? '';

          final int cal =
              (nutriments['energy-kcal_100g'] as num?)?.toInt() ??
              (((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184)
                  .round();

          final double protein =
              (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0;
          final double carbs =
              (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0;
          final double fat =
              (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0;
          final double? fiber = (nutriments['fiber_100g'] as num?)?.toDouble();

          items.add(
            FoodItem(
              id: code.isNotEmpty ? code : name,
              name: name,
              brand: brand,
              servingSize: servingSize,
              servingWeightGrams: 100.0,
              calories: cal,
              protein: double.parse(protein.toStringAsFixed(1)),
              carbs: double.parse(carbs.toStringAsFixed(1)),
              fat: double.parse(fat.toStringAsFixed(1)),
              fiber: fiber != null
                  ? double.parse(fiber.toStringAsFixed(1))
                  : null,
              barcode: code.isNotEmpty ? code : null,
              source: 'open_food_facts',
              imageUrl: product['image_front_url'] as String?,
            ),
          );
        }
        return items;
      }
    } catch (_) {}
    return <FoodItem>[];
  }

  /// Searches foods in USDA FoodData Central API
  Future<List<FoodItem>> searchUsdaFoods(String query) async {
    final String q = Uri.encodeComponent(query.trim());
    if (q.isEmpty) {
      return <FoodItem>[];
    }

    final Uri url = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=DEMO_KEY&query=$q&pageSize=10',
    );
    try {
      final http.Response response = await _client
          .get(
            url,
            headers: <String, String>{
              'User-Agent':
                  'OlyOlympicWeightliftingApp/1.0 (contact@lamontlabs.com)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> foods =
            data['foods'] as List<dynamic>? ?? <dynamic>[];

        final List<FoodItem> items = <FoodItem>[];
        for (final f in foods) {
          final Map<String, dynamic> food = f as Map<String, dynamic>;
          final String name = food['description'] as String? ?? '';
          if (name.trim().isEmpty) {
            continue;
          }

          final String? brand =
              food['brandOwner'] as String? ?? food['brandName'] as String?;
          final int fdcId = (food['fdcId'] as num?)?.toInt() ?? 0;
          final String servingSizeText =
              food['householdServingFullText'] as String? ??
              (food['servingSize'] != null && food['servingSizeUnit'] != null
                  ? '${food['servingSize']} ${food['servingSizeUnit']}'
                  : '100g');
          final double servingWeight =
              (food['servingSize'] as num?)?.toDouble() ?? 100.0;

          final List<dynamic> nutrients =
              food['foodNutrients'] as List<dynamic>? ?? <dynamic>[];

          double cal = 0.0;
          double protein = 0.0;
          double carbs = 0.0;
          double fat = 0.0;
          double? fiber;

          for (final n in nutrients) {
            final Map<String, dynamic> nutrient = n as Map<String, dynamic>;
            final String nName = (nutrient['nutrientName'] as String? ?? '')
                .toLowerCase();
            final String nNumber = nutrient['nutrientNumber'] as String? ?? '';
            final int nId = (nutrient['nutrientId'] as num?)?.toInt() ?? 0;
            final double value = (nutrient['value'] as num?)?.toDouble() ?? 0.0;

            if (nId == 1008 ||
                nNumber == '208' ||
                (nName.contains('energy') &&
                    nutrient['unitName'] == 'KCAL')) {
              cal = value;
            } else if (nId == 1003 ||
                nNumber == '203' ||
                nName.contains('protein')) {
              protein = value;
            } else if (nId == 1005 ||
                nNumber == '205' ||
                nName.contains('carbohydrate')) {
              carbs = value;
            } else if (nId == 1004 ||
                nNumber == '204' ||
                nName.contains('total lipid')) {
              fat = value;
            } else if (nId == 1079 ||
                nNumber == '291' ||
                nName.contains('fiber')) {
              fiber = value;
            }
          }

          items.add(
            FoodItem(
              id: 'usda_$fdcId',
              name: name,
              brand: brand,
              servingSize: servingSizeText,
              servingWeightGrams: servingWeight > 0 ? servingWeight : 100.0,
              calories: cal.round(),
              protein: double.parse(protein.toStringAsFixed(1)),
              carbs: double.parse(carbs.toStringAsFixed(1)),
              fat: double.parse(fat.toStringAsFixed(1)),
              fiber: fiber != null
                  ? double.parse(fiber.toStringAsFixed(1))
                  : null,
              source: 'usda_fooddata',
            ),
          );
        }
        return items;
      }
    } catch (_) {}
    return <FoodItem>[];
  }

  /// Concurrently searches offline local databases (staples + restaurants)
  /// and live online APIs (USDA FoodData Central + OpenFoodFacts).
  Future<List<FoodItem>> searchAllFoods(String query) async {
    final String clean = query.trim();
    if (clean.isEmpty) {
      final List<FoodItem> staples = await getStapleFoods();
      final List<FoodItem> restaurants = await getRestaurantFoods();
      return <FoodItem>[...restaurants, ...staples];
    }

    final List<List<FoodItem>> results = await Future.wait<List<FoodItem>>(<Future<List<FoodItem>>>[
      searchLocalFoods(clean),
      searchUsdaFoods(clean),
      searchOnlineFoods(clean),
    ]);

    final List<FoodItem> localResults = results[0];
    final List<FoodItem> usdaResults = results[1];
    final List<FoodItem> offResults = results[2];

    final Set<String> seenKeys = <String>{};
    final List<FoodItem> merged = <FoodItem>[];

    void addUnique(FoodItem item) {
      final String key =
          '${(item.brand ?? '').toLowerCase().trim()}_${item.name.toLowerCase().trim()}';
      if (!seenKeys.contains(key) && !seenKeys.contains(item.id)) {
        seenKeys.add(key);
        seenKeys.add(item.id);
        merged.add(item);
      }
    }

    // 1. Local results first (exact brand/restaurant and whole food matches)
    localResults.forEach(addUnique);

    // 2. USDA FoodData Central results second
    usdaResults.forEach(addUnique);

    // 3. OpenFoodFacts results third
    offResults.forEach(addUnique);

    return merged;
  }

  void dispose() {
    _client.close();
  }
}
