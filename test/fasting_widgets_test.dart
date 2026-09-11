import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/fasting_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/views/nutrition/fasting_biomarker_history_sheet.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'package:oly/widgets/nutrition/fasting_cellular_card.dart';
import 'package:oly/widgets/nutrition/fasting_projection_card.dart';
import 'package:oly/widgets/nutrition/fasting_radial_gauge.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FastingRadialGauge displays time, stage pill, and progress badge',
      (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final FastingSession session = FastingSession(
      id: 'test_gauge',
      protocol: FastingProtocol.intermittent16_8,
      targetDurationSeconds: 16 * 3600,
      startTime: now.subtract(const Duration(hours: 14)), // 14h in -> Ketosis Onset
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingRadialGauge(session: session),
        ),
      ),
    );

    expect(find.text('KETOSIS ONSET'), findsOneWidget);
    expect(find.textContaining('14:00'), findsOneWidget);
    expect(find.textContaining('87% of 16h goal'), findsOneWidget);
  });

  testWidgets('FastingCellularCard displays biological breakdown and barbell advisory',
      (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final FastingSession session = FastingSession(
      id: 'test_cellular',
      protocol: FastingProtocol.dinnerToDinner24,
      targetDurationSeconds: 24 * 3600,
      startTime: now.subtract(const Duration(hours: 20)), // 20h in -> Autophagy Active
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingCellularCard(session: session),
        ),
      ),
    );

    expect(find.text('CELLULAR & METABOLIC STATUS'), findsOneWidget);
    expect(find.text('Active Autophagy (AMPK Surge)'), findsOneWidget);
    expect(find.textContaining('AMPK surges and turns off mTOR'), findsOneWidget);
    expect(find.textContaining('Technique & Moderate Volume'), findsOneWidget);
  });

  testWidgets('FastingProjectionCard displays 7-day forward schedule',
      (WidgetTester tester) async {
    final List<FastingScheduleDay> projection =
        FastingEngineService.generateProjection(
      currentProtocol: FastingProtocol.intermittent16_8,
      config: const AthleteCircadianConfig(),
      daysCount: 7,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingProjectionCard(scheduleDays: projection),
        ),
      ),
    );

    expect(find.text('7-DAY FASTING & TRAINING PLANNER'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.textContaining('10:00 AM – 6:00 PM'), findsWidgets);
  });

  testWidgets('NutritionDashboardScreen includes Fasting tab and switches views',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final StorageService storage = StorageService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NutritionProvider>(
            create: (_) => NutritionProvider(storage),
          ),
          ChangeNotifierProvider<BodyCompProvider>(
            create: (_) => BodyCompProvider(storage),
          ),
          ChangeNotifierProvider<FastingProvider>(
            create: (_) => FastingProvider(storage),
          ),
        ],
        child: const MaterialApp(
          home: NutritionDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify view selector shows Energy In vs Out, Macro Targets, and Fasting
    expect(find.text('Energy In vs Out'), findsOneWidget);
    expect(find.text('Macro Targets'), findsOneWidget);
    expect(find.text('Fasting'), findsOneWidget);

    // Tap 'Fasting' tab
    await tester.tap(find.text('Fasting'));
    await tester.pumpAndSettle();

    // Verify Guided Fasting view appears
    expect(find.text('No Active Fast in Progress'), findsOneWidget);
    expect(find.text('START GUIDED FAST'), findsOneWidget);
    expect(find.text('KETO-MOJO BIOMARKERS & GKI'), findsOneWidget);
    expect(find.text('RECORD FIRST BLOOD TEST'), findsOneWidget);
    expect(find.text('GKI TRACKING'), findsOneWidget);
    expect(find.text('7-DAY FASTING & TRAINING PLANNER'), findsOneWidget);
  });

  testWidgets('FastingBiomarkerHistorySheet displays logged entries and GKI',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final StorageService storage = StorageService(prefs);
    final FastingProvider fastingProvider = FastingProvider(storage);

    // Log two biomarker entries
    await fastingProvider.addBiomarkerEntry(
      glucoseMgDl: 85.0,
      ketoneMmolL: 1.2,
      notes: 'Morning baseline',
    );
    await fastingProvider.addBiomarkerEntry(
      glucoseMgDl: 75.0,
      ketoneMmolL: 2.5,
      notes: 'Post-lift fast',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<FastingProvider>.value(value: fastingProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FastingBiomarkerHistorySheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify history sheet header and items
    expect(find.text('BIOMARKER TRACKING & GKI'), findsOneWidget);
    expect(find.text('Capillary Blood History (2 readings)'), findsOneWidget);
    expect(find.text('85 mg/dL'), findsOneWidget);
    expect(find.text('75 mg/dL'), findsOneWidget);
    expect(find.text('1.2 mmol/L'), findsOneWidget);
    expect(find.text('2.5 mmol/L'), findsOneWidget);
    expect(find.text('📝 Morning baseline'), findsOneWidget);
    expect(find.text('📝 Post-lift fast'), findsOneWidget);
    expect(find.text('LOG NEW BIOMARKER READING'), findsOneWidget);
  });
}
