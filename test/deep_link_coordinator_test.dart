import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/deep_link_coordinator.dart';
import 'package:oly/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkCoordinator Tests', () {
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

    tearDown(DeepLinkCoordinator.instance.unregisterTabSwitcher);

    test('DeepLinkCoordinator singleton returns identical instance', () {
      final DeepLinkCoordinator a = DeepLinkCoordinator.instance;
      final DeepLinkCoordinator b = DeepLinkCoordinator.instance;
      expect(identical(a, b), isTrue);
    });

    test('Queues payload on cold start when no switcher registered', () {
      final DeepLinkCoordinator coordinator = DeepLinkCoordinator.instance;
      coordinator.unregisterTabSwitcher();

      // Should queue cleanly without throwing
      coordinator.handlePayload(
        'oly://fuel/water?amount=739&slot=701',
        actionId: 'action_log_water',
      );
    });

    testWidgets('Dispatches tab switching when navigator context and switcher are mounted',
        (tester) async {
      final DeepLinkCoordinator coordinator = DeepLinkCoordinator.instance;
      int? switchedTab;
      int? switchedSubTab;

      coordinator.registerTabSwitcher((tabIndex, [subIndex, onComplete]) {
        switchedTab = tabIndex;
        switchedSubTab = subIndex;
        onComplete?.call();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: <InheritedProvider<dynamic>>[
            ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
            ChangeNotifierProvider<FastingProvider>.value(value: fasting),
            ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
          ],
          child: MaterialApp(
            navigatorKey: coordinator.navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );

      // 1. Fuel Water
      coordinator.handlePayload('oly://fuel/water?amount=739');
      await tester.pumpAndSettle();
      expect(switchedTab, equals(2));

      // 2. Fasting
      coordinator.handlePayload('oly://fuel/fasting');
      await tester.pumpAndSettle();
      expect(switchedTab, equals(2));

      // 3. Analytics sub-tab
      coordinator.handlePayload('oly://analytics?tab=2');
      await tester.pumpAndSettle();
      expect(switchedTab, equals(3));
      expect(switchedSubTab, equals(2));

      // 4. Default fallback
      coordinator.handlePayload('oly://unknown/screen');
      await tester.pumpAndSettle();
      expect(switchedTab, equals(0));
    });

    testWidgets('Processes pending deep link once container mounts', (tester) async {
      final DeepLinkCoordinator coordinator = DeepLinkCoordinator.instance;
      coordinator.unregisterTabSwitcher();

      // Simulate notification tapped while app is starting up
      coordinator.handlePayload('oly://fuel/water?amount=500');

      int? switchedTab;
      await tester.pumpWidget(
        MultiProvider(
          providers: <InheritedProvider<dynamic>>[
            ChangeNotifierProvider<NutritionProvider>.value(value: nutrition),
            ChangeNotifierProvider<FastingProvider>.value(value: fasting),
            ChangeNotifierProvider<BodyCompProvider>.value(value: bodyComp),
          ],
          child: MaterialApp(
            navigatorKey: coordinator.navigatorKey,
            home: Builder(
              builder: (context) {
                coordinator.registerTabSwitcher((tabIndex, [subIndex, onComplete]) {
                  switchedTab = tabIndex;
                  onComplete?.call();
                });
                coordinator.processPendingDeepLink(context);
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(switchedTab, equals(2));
    });
  });
}
