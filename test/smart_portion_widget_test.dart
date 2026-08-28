import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/nutrition/food_search_sheet.dart';
import 'package:oly/views/nutrition/live_barcode_scanner_sheet.dart';
import 'package:oly/widgets/nutrition/smart_portion_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late NutritionProvider nutritionProvider;
  late BodyCompProvider bodyCompProvider;

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

        await tester.pumpWidget(buildTestableWidget(const FoodSearchSheet()));
        await tester.pumpAndSettle();

        expect(find.text('RECENT SCANNED PANTRY ITEMS'), findsOneWidget);
        expect(find.text('1 cached'), findsOneWidget);
        expect(find.text('Pure Protein Bar Chocolate PB'), findsWidgets);
      },
    );
  });
}
