import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/nutrition/water_log_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WaterLogSheet Widget & Precision Input Tests', () {
    late StorageService storage;
    late NutritionProvider nutrition;
    late FastingProvider fasting;
    late BodyCompProvider bodyComp;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      nutrition = NutritionProvider(storage);
      fasting = FastingProvider(storage);
      bodyComp = BodyCompProvider(storage);
    });

    Widget buildTestableSheet({double? initialMl}) {
      return MultiProvider(
        providers: <InheritedProvider<dynamic>>[
          ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
          ChangeNotifierProvider<FastingProvider>.value(value: fasting),
          ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => WaterLogSheet.show(context, initialMl: initialMl),
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('Opens WaterLogSheet and displays scheduled dose banner', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Log Hydration'), findsOneWidget);
      expect(find.text('Precision fluid intake'), findsOneWidget);
      expect(find.text('Scheduled Notification Dose'), findsOneWidget);
      final int scheduledMl = fasting.scheduledPortionMl;
      expect(find.textContaining('$scheduledMl mL'), findsWidgets);
    });

    testWidgets('Types custom 739 mL and adds to today', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Switch to mL mode if in oz
      if (find.text('mL').evaluate().isNotEmpty) {
        await tester.tap(find.text('mL'));
        await tester.pumpAndSettle();
      }

      // Enter 739 into the text field
      final Finder textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '739');
      await tester.pumpAndSettle();

      expect(find.textContaining('≈ 25.0 fl oz'), findsOneWidget);

      // Tap Add to Today button
      final Finder addButton = find.text('Add +739 mL to Today');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final DailyNutritionLog log = nutrition.currentDayLog;
      expect(log.waterMl, closeTo(739.0, 0.01));
      expect(log.waterOz, closeTo(24.988, 0.01));
    });

    testWidgets('Sets exact daily total to 1500 mL', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Switch to mL
      await tester.tap(find.text('mL'));
      await tester.pumpAndSettle();

      final Finder textField = find.byType(TextField);
      await tester.enterText(textField, '1500');
      await tester.pumpAndSettle();

      final Finder setTotalButton = find.text('Set Total for Today (1500 mL)');
      expect(setTotalButton, findsOneWidget);
      await tester.tap(setTotalButton);
      await tester.pumpAndSettle();

      final DailyNutritionLog log = nutrition.currentDayLog;
      expect(log.waterMl, closeTo(1500.0, 0.01));
    });
  });
}
