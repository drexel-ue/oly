import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/nutrition/edit_food_entry_sheet.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Widget buildTestWidget(NutritionEntry entry) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<NutritionProvider>.value(
          value: nutritionProvider,
        ),
        ChangeNotifierProvider<BodyCompProvider>.value(value: bodyCompProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => EditFoodEntrySheet(entry: entry),
                    );
                  },
                  child: const Text('Open Edit Sheet'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('EditFoodEntrySheet renders initial entry values and saves edits', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final NutritionEntry entry = NutritionEntry.create(
      name: 'Chicken Rice Bowl',
      calories: 520,
      proteinGrams: 42,
      carbsGrams: 58,
      fatGrams: 10,
      category: MealCategory.lunch,
      portion: '200g chicken + 1.5 cup rice',
    );
    await nutritionProvider.addFoodEntry(entry);

    await tester.pumpWidget(buildTestWidget(entry));
    await tester.pumpAndSettle();

    // Open Bottom Sheet
    await tester.tap(find.text('Open Edit Sheet'));
    await tester.pumpAndSettle();

    // Verify initial values in UI
    expect(find.text('Edit Logged Food'), findsOneWidget);
    expect(find.text('Chicken Rice Bowl'), findsOneWidget);
    expect(find.text('520'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('200g chicken + 1.5 cup rice'), findsOneWidget);

    // Edit Name
    await tester.enterText(
      find.widgetWithText(TextField, 'Food Name'),
      'Grilled Chicken & Jasmine Rice',
    );

    // Edit Protein
    await tester.enterText(
      find.widgetWithText(TextField, 'Protein (g)'),
      '50',
    );

    // Edit Carbs
    await tester.enterText(
      find.widgetWithText(TextField, 'Carbs (g)'),
      '65',
    );

    // Edit Fat
    await tester.enterText(
      find.widgetWithText(TextField, 'Fat (g)'),
      '12',
    );

    // Edit Portion Notes
    await tester.enterText(
      find.widgetWithText(TextField, 'Portion / Serving Notes (optional)'),
      '250g chicken + 2 cups rice',
    );

    // Tap +50 quick calorie button
    await tester.tap(find.text('+50'));
    await tester.pumpAndSettle();
    expect(find.text('570'), findsOneWidget);

    // Switch Category to Dinner
    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();
    expect(find.text('Moving to Dinner'), findsOneWidget);

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify provider updated
    final NutritionEntry updated = nutritionProvider.currentDayLog.entries.first;
    expect(updated.name, equals('Grilled Chicken & Jasmine Rice'));
    expect(updated.calories, equals(570));
    expect(updated.proteinGrams, equals(50.0));
    expect(updated.carbsGrams, equals(65.0));
    expect(updated.fatGrams, equals(12.0));
    expect(updated.portion, equals('250g chicken + 2 cups rice'));
    expect(updated.category, equals(MealCategory.dinner));
  });

  testWidgets('EditFoodEntrySheet deletes item upon confirmation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final NutritionEntry entry = NutritionEntry.create(
      name: 'Oatmeal & Berries',
      calories: 320,
      proteinGrams: 12,
      carbsGrams: 54,
      fatGrams: 6,
      category: MealCategory.breakfast,
    );
    await nutritionProvider.addFoodEntry(entry);
    expect(nutritionProvider.currentDayLog.entries.length, equals(1));

    await tester.pumpWidget(buildTestWidget(entry));
    await tester.pumpAndSettle();

    // Open Bottom Sheet
    await tester.tap(find.text('Open Edit Sheet'));
    await tester.pumpAndSettle();

    // Tap Delete Icon Button
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Dialog prompt appears
    expect(find.text('Delete Food Item'), findsOneWidget);
    expect(
      find.text('Are you sure you want to remove "Oatmeal & Berries" from your daily log?'),
      findsOneWidget,
    );

    // Confirm Delete
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    // Item deleted from log
    expect(nutritionProvider.currentDayLog.entries.length, equals(0));

    // Tap Undo on SnackBar
    expect(find.text('UNDO'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();

    // Item restored!
    expect(nutritionProvider.currentDayLog.entries.length, equals(1));
    expect(nutritionProvider.currentDayLog.entries.first.name, equals('Oatmeal & Berries'));
  });
}
