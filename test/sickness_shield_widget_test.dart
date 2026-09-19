import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/illness_model.dart';
import 'package:oly/providers/illness_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/illness_checkin_sheet.dart';
import 'package:oly/widgets/sickness_shield_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SicknessShieldBanner & IllnessCheckInSheet Widget Tests', () {
    late StorageService storage;
    late IllnessProvider illnessProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      illnessProvider = IllnessProvider(storage);
    });

    Widget createWidgetUnderTest(Widget child) {
      return ChangeNotifierProvider<IllnessProvider>.value(
        value: illnessProvider,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        ),
      );
    }

    testWidgets('Renders empty SizedBox when no illness is active', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const SicknessShieldBanner()));
      expect(find.byType(SicknessShieldBanner), findsOneWidget);
      expect(find.textContaining('SICKNESS SHIELD'), findsNothing);
    });

    testWidgets('Renders Systemic Illness Sickness Shield Banner with frozen badge', (tester) async {
      await illnessProvider.logIllness(
        severity: IllnessSeverity.systemicFever,
        hasFever: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(const SicknessShieldBanner()));
      await tester.pumpAndSettle();

      expect(find.textContaining('SICKNESS SHIELD ACTIVE: SYSTEMIC / FEVER'), findsOneWidget);
      expect(find.text('FROZEN'), findsOneWidget);
      expect(find.text('Mark Recovered'), findsOneWidget);
      expect(find.text('Update Symptoms'), findsOneWidget);
    });

    testWidgets('Renders Re-Entry Stage Banner during convalescence', (tester) async {
      await illnessProvider.logIllness(
        severity: IllnessSeverity.mildAboveNeck,
      );
      final String id = illnessProvider.activeRecord!.id;
      await illnessProvider.resolveIllness(id);

      await tester.pumpWidget(createWidgetUnderTest(const SicknessShieldBanner()));
      await tester.pumpAndSettle();

      expect(find.textContaining('RETURN-TO-PLAY: STAGE 1 (50%)'), findsOneWidget);
      expect(find.text('Advance to Stage 2'), findsOneWidget);
    });

    testWidgets('IllnessCheckInSheet renders severity options and saves', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => IllnessCheckInSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('SICKNESS & HEALTH CHECK-IN'), findsOneWidget);
      expect(find.text('Above the Neck (Head Cold)'), findsOneWidget);
      expect(find.text('Systemic Viral / Fever'), findsOneWidget);
      expect(find.text('ACTIVATE SICKNESS SHIELD'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('ACTIVATE SICKNESS SHIELD'),
        200,
        scrollable: find.descendant(
          of: find.byType(IllnessCheckInSheet),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACTIVATE SICKNESS SHIELD'));
      await tester.pumpAndSettle();

      expect(illnessProvider.hasActiveIllness, isTrue);
    });
  });
}
