import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/services/usda_database_service.dart';
import 'package:oly/views/nutrition/food_search_sheet.dart';
import 'package:oly/views/nutrition/live_barcode_scanner_sheet.dart';
import 'package:oly/widgets/nutrition/smart_portion_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late StorageService storageService;
  late NutritionProvider nutritionProvider;
  late BodyCompProvider bodyCompProvider;

  setUpAll(() async {
    await UsdaDatabaseService.instance.initDatabase();
  });

  tearDownAll(() async {
    await UsdaDatabaseService.instance.close();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    nutritionProvider = NutritionProvider(storageService);
    bodyCompProvider = BodyCompProvider(storageService);
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<NutritionProvider>.value(
          value: nutritionProvider,
        ),
        ChangeNotifierProvider<BodyCompProvider>.value(value: bodyCompProvider),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('Smart Portion & Scanner Enhancement Tests', () {
    const FoodItem testFood = FoodItem(
      id: 'test_protein_bar',
      name: 'Pure Protein Bar Chocolate PB',
      brand: 'Pure Protein',
      servingSize: '50g bar',
      servingWeightGrams: 50,
      calories: 200,
      protein: 20.0,
      carbs: 17.0,
      fat: 6.0,
      fiber: 2.0,
      barcode: '737628064502',
      source: 'open_food_facts',
    );

    testWidgets(
      'SmartPortionDrawer renders protein density, macro split bar, and step chips',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const SmartPortionDrawer(
              initialFoodItem: testFood,
              defaultCategory: MealCategory.snack,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PURE PROTEIN'), findsOneWidget);
        expect(find.text('Pure Protein Bar Chocolate PB'), findsOneWidget);
        expect(
          find.textContaining('10.0g P / 100 kcal'),
          findsOneWidget,
        ); // 20g / 200 kcal = 10.0
        expect(find.text('HIGH PROTEIN'), findsOneWidget);

        // Verify serving multipliers
        expect(find.text('1.0x'), findsOneWidget);
        expect(find.text('2.0x'), findsOneWidget);

        // Switch to Grams Mode
        await tester.tap(find.text('By Grams'));
        await tester.pumpAndSettle();

        expect(find.text('+10g'), findsOneWidget);
        expect(find.text('+50g'), findsOneWidget);

        // Tap +50g chip
        await tester.tap(find.text('+50g'));
        await tester.pumpAndSettle();

        // Tap Add to Snack
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pumpAndSettle();

        final DailyNutritionLog currentLog = nutritionProvider.currentDayLog;
        expect(currentLog.entries.isNotEmpty, isTrue);
        expect(currentLog.entries.first.name.contains('Pure Protein'), isTrue);
      },
    );

    testWidgets(
      'LiveBarcodeScannerSheet renders live camera viewfinder, reticle, and manual barcode entry',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(const LiveBarcodeScannerSheet()),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Live Scanner'), findsOneWidget);
        expect(find.text('Align Barcode Here'), findsOneWidget);
        expect(find.text('Enter Barcode Manually'), findsOneWidget);

        // Tap Manual Keyboard entry button
        await tester.tap(find.text('Enter Barcode Manually'));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Enter Barcode (UPC/EAN)'), findsOneWidget);
        expect(find.text('Lookup Product'), findsOneWidget);

        // Close manual dialog
        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'FoodSearchSheet renders recent scans ribbon when cached products exist',
      (WidgetTester tester) async {
        await storageService.saveCachedProductJson(
          testFood.barcode!,
          testFood.toJson(),
        );
        await storageService.addRecentScannedBarcode(testFood.barcode!);

        final MockClient mockClient = MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{'foods': <dynamic>[], 'products': <dynamic>[]}),
            200,
          );
        });

        await tester.runAsync(() async {
          await tester.pumpWidget(
            buildTestableWidget(
              FoodSearchSheet(
                foodDatabaseService: FoodDatabaseService(client: mockClient),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          await tester.pump();
        });
        await tester.pumpAndSettle();

        expect(find.text('RECENT SCANNED PANTRY ITEMS'), findsOneWidget);
        expect(find.text('1 cached'), findsOneWidget);
        expect(find.text('Pure Protein Bar Chocolate PB'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'LiveBarcodeScannerSheet manual barcode lookup opens portion drawer and logs entry',
      (WidgetTester tester) async {
        // Cache the test food item
        await storageService.saveCachedProductJson(
          testFood.barcode!,
          testFood.toJson(),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            const LiveBarcodeScannerSheet(defaultCategory: MealCategory.lunch),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Open manual dialog
        await tester.tap(find.text('Enter Barcode Manually'));
        await tester.pump(const Duration(milliseconds: 200));

        // Enter barcode
        await tester.enterText(
          find.byType(TextField),
          testFood.barcode!,
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Lookup Product
        await tester.tap(find.text('Lookup Product'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify SmartPortionDrawer opened
        expect(find.text('PURE PROTEIN'), findsOneWidget);
        expect(find.text('Pure Protein Bar Chocolate PB'), findsWidgets);

        // Tap Add to Lunch in bottom sheet
        await tester.tap(find.textContaining('Add to Lunch'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Bottom sheet should be dismissed and entry added to nutrition provider
        expect(find.text('PURE PROTEIN'), findsNothing);
        final DailyNutritionLog currentLog = nutritionProvider.currentDayLog;
        expect(currentLog.entries.isNotEmpty, isTrue);
        expect(currentLog.entries.first.name.contains('Pure Protein'), isTrue);
        expect(find.textContaining('Logged Pure Protein Bar Chocolate PB'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'SmartPortionDrawer onScanAnother callback cleanly pops the modal bottom sheet',
      (WidgetTester tester) async {
        bool popped = false;
        await tester.pumpWidget(
          buildTestableWidget(
            SmartPortionDrawer(
              initialFoodItem: testFood,
              defaultCategory: MealCategory.lunch,
              onScanAnother: () {
                popped = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Scan Another Barcode'), findsOneWidget);
        await tester.tap(find.byTooltip('Scan Another Barcode'));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
      },
    );

    testWidgets(
      'FoodSearchSheet searches Wingstop and logs custom wing count using piece chips',
      (WidgetTester tester) async {
        final MockClient mockClient = MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{'foods': <dynamic>[], 'products': <dynamic>[]}),
            200,
          );
        });
        final FoodDatabaseService foodService = FoodDatabaseService(
          client: mockClient,
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(
            buildTestableWidget(
              FoodSearchSheet(foodDatabaseService: foodService),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        });
        await tester.pumpAndSettle();

        // Type "wingstop lemon" in search
        await tester.runAsync(() async {
          await tester.enterText(find.byType(TextField), 'wingstop lemon');
          await Future<void>.delayed(const Duration(milliseconds: 400));
          await tester.pump();
        });
        await tester.pumpAndSettle();

        // Verify Wingstop results appear
        expect(find.textContaining('WINGSTOP'), findsWidgets);
        expect(find.textContaining('Lemon Pepper'), findsWidgets);

        // Hide keyboard
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // Tap on Lemon Pepper Wings
        await tester.tap(find.textContaining('Lemon Pepper').first);
        await tester.pumpAndSettle();

        expect(find.byType(SmartPortionDrawer), findsOneWidget);
        expect(find.text('6 wings'), findsOneWidget);
        expect(find.text('10 wings'), findsOneWidget);

        // Select 10 wings
        await tester.tap(find.text('10 wings'));
        await tester.pumpAndSettle();

        // Verify scaled calories: 10 * 80 = 800 kcal (or 10 * 100 = 1000 kcal)
        expect(find.textContaining('kcal'), findsWidgets);

        // Tap Add to Lunch
        await tester.tap(find.textContaining('Add to Lunch'));
        await tester.pumpAndSettle();

        final DailyNutritionLog log = nutritionProvider.currentDayLog;
        expect(log.entries.isNotEmpty, isTrue);
        final NutritionEntry entry = log.entries.first;
        expect(entry.name, contains('Wingstop'));
        expect(entry.name, contains('Lemon Pepper'));
        expect(entry.calories, isIn(<int>[800, 1000]));
        expect(entry.portion, equals('10 wings'));

        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
