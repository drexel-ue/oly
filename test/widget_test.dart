import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:oly/main.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('OlyApp renders home dashboard and navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final StorageService storage = StorageService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(create: (_) => LiftProvider(storage)),
          ChangeNotifierProvider(create: (_) => ProgramProvider(storage)),
          ChangeNotifierProvider(create: (_) => RecoveryProvider(storage)),
          ChangeNotifierProvider(create: (_) => BodyCompProvider(storage)),
          ChangeNotifierProvider(create: (_) => NutritionProvider(storage)),
          ChangeNotifierProvider(create: (_) => InjuryProvider(storage)),
        ],
        child: const OlyApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('OLY'), findsWidgets);
    expect(find.text('OLYMPIC TOTAL'), findsOneWidget);
  });
}
