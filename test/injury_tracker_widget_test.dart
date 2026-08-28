import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/injury_tracker_screen.dart';
import 'package:oly/widgets/interactive_body_map.dart';
import 'package:oly/widgets/post_session_body_checkin_dialog.dart';
import 'package:oly/widgets/session_injury_adaptation_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget(Widget child, {InjuryProvider? injuryProvider}) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: injuryProvider != null
          ? ChangeNotifierProvider<InjuryProvider>.value(
              value: injuryProvider,
              child: Scaffold(body: child),
            )
          : Scaffold(body: child),
    );
  }

  group('InteractiveBodyMap Widget Tests', () {
    testWidgets('Renders body map with Front view and toggles to Back view', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          InteractiveBodyMap(
            injuries: <InjuryRecord>[
              InjuryRecord(
                id: '1',
                name: 'Knee Strain',
                region: InjuryRegion.leftKnee,
                onsetDate: DateTime.now().subtract(const Duration(days: 3)),
                painScale: 4,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ANTERIOR (FRONT)'), findsOneWidget);
      expect(find.text('Front'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('POSTERIOR (BACK)'), findsOneWidget);
    });

    testWidgets('Triggers onRegionSelected callback on canvas tap', (
      WidgetTester tester,
    ) async {
      InjuryRegion? selected;

      await tester.pumpWidget(
        createTestWidget(
          InteractiveBodyMap(
            injuries: const <InjuryRecord>[],
            onRegionSelected: (InjuryRegion r) => selected = r,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the top center of the custom paint canvas (Head / Neck region)
      final Finder customPaint = find.byType(CustomPaint).last;
      await tester.tapAt(tester.getCenter(customPaint) - const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
    });
  });

  group('SessionInjuryAdaptationCard Widget Tests', () {
    testWidgets('Renders active injury adaptations and triggers onApplySwaps', (
      WidgetTester tester,
    ) async {
      final DayTemplate day1 = ProgramCycle.getBuiltInProgram().first;
      final List<InjuryRecord> injuries = <InjuryRecord>[
        InjuryRecord(
          id: 'k1',
          name: 'Patellar Tendinopathy',
          region: InjuryRegion.leftKnee,
          onsetDate: DateTime.now().subtract(const Duration(days: 4)),
          painScale: 5,
          constraints: <BiomechanicalConstraint>[
            BiomechanicalConstraint.avoidDeepKneeFlexion,
          ],
          safeSubstitutions: <InjurySubstitution>[
            InjurySubstitution(
              targetExercise: 'Snatch',
              replacementName: 'Power Snatch from Blocks',
              replacementLiftId: 'power_snatch',
              weightMultiplier: 0.82,
              rationale: 'High blocks eliminate catch shock.',
            ),
          ],
        ),
      ];

      Map<String, String>? appliedSwaps;

      await tester.pumpWidget(
        createTestWidget(
          SessionInjuryAdaptationCard(
            dayTemplate: day1,
            activeInjuries: injuries,
            currentWeek: 1,
            currentMaxes: const <String, double>{
              'snatch': 100.0,
              'power_snatch': 85.0,
            },
            onApplySwaps: (Map<String, String> swaps, Map<String, double> weights) {
              appliedSwaps = swaps;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Injury Adaptive Shield Active'), findsOneWidget);
      expect(find.text('Patellar Tendinopathy'), findsOneWidget);
      expect(find.text('Apply Recommended Rehab Swaps'), findsOneWidget);

      await tester.tap(find.text('Apply Recommended Rehab Swaps'));
      await tester.pumpAndSettle();

      expect(appliedSwaps, isNotNull);
      expect(
        appliedSwaps!['Power Snatch + Overhead Squat'],
        equals('Power Snatch from Blocks'),
      );
    });
  });

  group('InjuryTrackerScreen Full View Tests', () {
    testWidgets('Renders header metrics, tabs, and empty state message', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final InjuryProvider provider = InjuryProvider(storage);

      await tester.pumpWidget(
        createTestWidget(
          const InjuryTrackerScreen(),
          injuryProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Body Map & Injuries'), findsOneWidget);
      expect(find.text('Active Strains'), findsOneWidget);
      expect(find.text('All Joints & Tissues Healthy!'), findsOneWidget);
      expect(find.text('Log Strain'), findsOneWidget);
    });
  });

  group('PostSessionBodyCheckinDialog Widget Tests', () {
    testWidgets('Renders post-session check-in dialog and completes', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final InjuryProvider provider = InjuryProvider(storage);

      bool isCompleted = false;

      await tester.pumpWidget(
        createTestWidget(
          PostSessionBodyCheckinDialog(
            onComplete: (Map<InjuryRegion, int> pain, List<String> tags) {
              isCompleted = true;
            },
          ),
          injuryProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Post-Session Strain Check-In'), findsOneWidget);
      expect(find.text('Save & Finish'), findsOneWidget);

      await tester.tap(find.text('Save & Finish'));
      await tester.pumpAndSettle();

      expect(isCompleted, isTrue);
    });
  });
}
