import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oly/main.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/storage_service.dart';

void main() {
  testWidgets('OlyApp renders home dashboard and navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(create: (_) => LiftProvider(storage)),
          ChangeNotifierProvider(create: (_) => ProgramProvider(storage)),
        ],
        child: const OlyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('OLY'), findsOneWidget);
    expect(find.text('OLYMPIC TOTAL'), findsOneWidget);
  });
}
