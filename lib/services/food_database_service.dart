import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:openfoodfacts/openfoodfacts.dart';
import '../models/nutrition_entry.dart';
import 'app_log_service.dart';
import 'storage_service.dart';

class FoodItem {
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

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    required this.servingSize,
    required this.servingWeightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.barcode,
    required this.source,
    this.imageUrl,
    this.servingUnitName,
  });

  /// Athlete Protein Density: grams of protein per 100 kcal
  double get proteinDensity => calories > 0 ? (protein / (calories / 100.0)) : 0.0;

  String get proteinDensityLabel => '${proteinDensity.toStringAsFixed(1)}g P / 100 kcal';

  bool get isHighProtein => proteinDensity >= 10.0 || proteinCaloriePct >= 35.0;

  double get proteinCaloriePct => calories > 0 ? ((protein * 4.0) / calories * 100.0).clamp(0.0, 100.0) : 0.0;
  double get carbsCaloriePct => calories > 0 ? ((carbs * 4.0) / calories * 100.0).clamp(0.0, 100.0) : 0.0;
  double get fatCaloriePct => calories > 0 ? ((fat * 9.0) / calories * 100.0).clamp(0.0, 100.0) : 0.0;

  NutritionEntry toNutritionEntry({
    required MealCategory mealCategory,
    double servingMultiplier = 1.0,
    double? customGrams,
  }) {
    final effectiveMultiplier = customGrams != null && servingWeightGrams > 0
        ? (customGrams / servingWeightGrams)
        : servingMultiplier;

    final scaledCalories = (calories * effectiveMultiplier).round();
    final scaledProtein = protein * effectiveMultiplier;
    final scaledCarbs = carbs * effectiveMultiplier;
    final scaledFat = fat * effectiveMultiplier;
    final scaledWeight = customGrams ?? (servingWeightGrams * effectiveMultiplier);

    final displayName = brand != null && brand!.isNotEmpty
        ? '$brand - $name'
        : name;

    final portionLabel = customGrams != null
        ? '${customGrams.round()}g'
        : (servingMultiplier == 1.0 ? servingSize : '${servingMultiplier.toStringAsFixed(1)}x ($servingSize)');

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
    return {
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

  factory FoodItem.fromJson(Map<String, dynamic> json, {String defaultSource = 'offline_staple'}) {
    return FoodItem(
      id: json['id'] as String? ?? json['code'] as String? ?? '',
      name: json['name'] as String? ?? json['product_name'] as String? ?? 'Food Item',
      brand: json['brand'] as String? ?? json['brands'] as String?,
      category: json['category'] as String?,
      servingSize: json['servingSize'] as String? ?? json['serving_size'] as String? ?? '100g',
      servingWeightGrams: (json['servingWeightGrams'] as num?)?.toDouble() ?? 100.0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      barcode: json['barcode'] as String? ?? json['code'] as String?,
      source: json['source'] as String? ?? defaultSource,
      imageUrl: json['imageUrl'] as String? ?? json['image_front_url'] as String?,
      servingUnitName: json['servingUnitName'] as String?,
    );
  }
}

class FoodDatabaseService {
  final http.Client _client;
  List<FoodItem>? _cachedStaples;

  FoodDatabaseService({http.Client? client}) : _client = client ?? http.Client() {
    _initOpenFoodFactsSdk();
  }

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
    if (_cachedStaples != null) return _cachedStaples!;

    try {
      final jsonString = await rootBundle.loadString('assets/data/staple_foods.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      _cachedStaples = list.map((item) => FoodItem.fromJson(item as Map<String, dynamic>, defaultSource: 'offline_staple')).toList();
      return _cachedStaples!;
    } catch (e) {
      return [];
    }
  }

  /// Searches offline staple foods by query string
  Future<List<FoodItem>> searchStapleFoods(String query) async {
    final staples = await getStapleFoods();
    if (query.trim().isEmpty) return staples;

    final q = query.toLowerCase().trim();
    return staples.where((item) {
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
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    AppLogService.instance.info('FOOD_DB', 'Looking up barcode: $cleanBarcode (forceRefresh: $forceRefresh)');

    // 1. Check local offline cache if not forcing a refresh
    if (!forceRefresh && storage != null) {
      final cachedJson = storage.loadCachedProductsJson()[cleanBarcode];
      if (cachedJson != null) {
        AppLogService.instance.debug('FOOD_DB', 'Cache hit for barcode: $cleanBarcode');
        await storage.addRecentScannedBarcode(cleanBarcode);
        return FoodItem.fromJson(cachedJson, defaultSource: 'open_food_facts');
      }
    }

    // 2. Query using OpenFoodFacts SDK
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        cleanBarcode,
        version: ProductQueryVersion.v3,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.SERVING_QUANTITY,
          ProductField.IMAGE_FRONT_URL,
        ],
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);
      if (result.product != null) {
        final product = result.product!;
        final nutriments = product.nutriments;

        final name = product.productName ?? 'Scanned Product';
        final brand = product.brands;
        final servingSize = product.servingSize ?? '100g';
        final servingWeight = product.servingQuantity ?? 100.0;

        final cal = nutriments?.getValue(Nutrient.energyKCal, PerSize.serving)?.toInt() ??
            nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)?.toInt() ??
            (((nutriments?.getValue(Nutrient.energyKJ, PerSize.oneHundredGrams) ?? 0.0)) / 4.184).round();

        final protein = nutriments?.getValue(Nutrient.proteins, PerSize.serving) ??
            nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ??
            0.0;

        final carbs = nutriments?.getValue(Nutrient.carbohydrates, PerSize.serving) ??
            nutriments?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ??
            0.0;

        final fat = nutriments?.getValue(Nutrient.fat, PerSize.serving) ??
            nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ??
            0.0;

        final fiber = nutriments?.getValue(Nutrient.fiber, PerSize.serving) ??
            nutriments?.getValue(Nutrient.fiber, PerSize.oneHundredGrams);

        final item = FoodItem(
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
      AppLogService.instance.warning('FOOD_DB', 'SDK lookup failed for $cleanBarcode: $e', stackTrace: stack.toString());
    }

    // 3. Fallback direct HTTP REST query
    final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$cleanBarcode.json');
    try {
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'OlyOlympicWeightliftingApp/1.0 (contact@lamontlabs.com)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'] as Map<String, dynamic>;
          final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

          final name = product['product_name'] as String? ?? 'Scanned Product';
          final brand = product['brands'] as String?;
          final servingSize = product['serving_size'] as String? ?? '100g';

          final cal = (nutriments['energy-kcal_serving'] as num?)?.toInt() ??
              (nutriments['energy-kcal_100g'] as num?)?.toInt() ??
              (((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184).round();

          final protein = (nutriments['proteins_serving'] as num?)?.toDouble() ??
              (nutriments['proteins_100g'] as num?)?.toDouble() ??
              0.0;

          final carbs = (nutriments['carbohydrates_serving'] as num?)?.toDouble() ??
              (nutriments['carbohydrates_100g'] as num?)?.toDouble() ??
              0.0;

          final fat = (nutriments['fat_serving'] as num?)?.toDouble() ??
              (nutriments['fat_100g'] as num?)?.toDouble() ??
              0.0;

          final fiber = (nutriments['fiber_serving'] as num?)?.toDouble() ??
              (nutriments['fiber_100g'] as num?)?.toDouble();

          final servingWeight = (product['serving_quantity'] as num?)?.toDouble() ?? 100.0;

          final item = FoodItem(
            id: cleanBarcode,
            name: name,
            brand: brand,
            servingSize: servingSize,
            servingWeightGrams: servingWeight,
            calories: cal,
            protein: double.parse(protein.toStringAsFixed(1)),
            carbs: double.parse(carbs.toStringAsFixed(1)),
            fat: double.parse(fat.toStringAsFixed(1)),
            fiber: fiber != null ? double.parse(fiber.toStringAsFixed(1)) : null,
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
      AppLogService.instance.error('FOOD_DB', 'HTTP fallback lookup failed for $cleanBarcode: $e', error: e, stackTrace: stack);
    }

    return null;
  }

  /// Searches products in Open Food Facts by search query
  Future<List<FoodItem>> searchOnlineFoods(String query) async {
    final q = Uri.encodeComponent(query.trim());
    if (q.isEmpty) return [];

    final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$q&search_simple=1&action=process&json=1&page_size=12');
    try {
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'OlyOlympicWeightliftingApp/1.0 (contact@lamontlabs.com)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final products = data['products'] as List<dynamic>? ?? [];

        final List<FoodItem> items = [];
        for (final p in products) {
          final product = p as Map<String, dynamic>;
          final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
          final name = product['product_name'] as String? ?? '';
          if (name.trim().isEmpty) continue;

          final brand = product['brands'] as String?;
          final servingSize = product['serving_size'] as String? ?? '100g';
          final code = product['code'] as String? ?? '';

          final cal = (nutriments['energy-kcal_100g'] as num?)?.toInt() ??
              (((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184).round();

          final protein = (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0;
          final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0;
          final fat = (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0;
          final fiber = (nutriments['fiber_100g'] as num?)?.toDouble();

          items.add(FoodItem(
            id: code.isNotEmpty ? code : name,
            name: name,
            brand: brand,
            servingSize: servingSize,
            servingWeightGrams: 100.0,
            calories: cal,
            protein: double.parse(protein.toStringAsFixed(1)),
            carbs: double.parse(carbs.toStringAsFixed(1)),
            fat: double.parse(fat.toStringAsFixed(1)),
            fiber: fiber != null ? double.parse(fiber.toStringAsFixed(1)) : null,
            barcode: code.isNotEmpty ? code : null,
            source: 'open_food_facts',
            imageUrl: product['image_front_url'] as String?,
          ));
        }
        return items;
      }
    } catch (_) {}
    return [];
  }

  void dispose() {
    _client.close();
  }
}
