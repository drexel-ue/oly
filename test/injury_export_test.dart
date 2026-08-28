import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/services/injury_export_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/injury_export_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InjuryExportService Tests', () {
    final List<InjuryRecord> mockInjuries = <InjuryRecord>[
      InjuryRecord(
        id: 'knee_1',
        name: 'Patellar Tendinopathy',
        osiicsCode: 'KJTP',
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now().subtract(const Duration(days: 5)),
        painScale: 6,
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
        rehabFocusAreas: <MobilityFocusArea>[MobilityFocusArea.quadriceps],
        rehabCues: <String>['Spanish squat holds'],
        notes: 'Sharp ache at bottom of catch',
      ),
      InjuryRecord(
        id: 'shoulder_1',
        name: 'Rotator Cuff Impingement',
        osiicsCode: 'SSIP',
        region: InjuryRegion.rightShoulder,
        onsetDate: DateTime.now().subtract(const Duration(days: 50)),
        painScale: 3,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidOverheadLockout,
        ],
        notes: 'Persistent stiffness',
      ),
      InjuryRecord(
        id: 'wrist_1',
        name: 'Wrist Flexor Strain',
        region: InjuryRegion.leftWrist,
        onsetDate: DateTime.now().subtract(const Duration(days: 90)),
        painScale: 0,
        isActive: false,
        resolvedAt: DateTime.now().subtract(const Duration(days: 10)),
        notes: 'Fully resolved with wrist wraps',
      ),
    ];

    test('generateJsonExport produces valid, structured JSON', () {
      final String jsonStr = InjuryExportService.generateJsonExport(
        allInjuries: mockInjuries,
        athleteName: 'Mattie Rogers',
      );

      expect(jsonStr, isNotEmpty);
      final dynamic decoded = jsonDecode(jsonStr);
      expect(decoded, isA<Map<String, dynamic>>());

      final Map<String, dynamic> data = decoded as Map<String, dynamic>;
      expect(data['exportVersion'], equals('1.0.0'));
      expect(data['athleteName'], equals('Mattie Rogers'));

      final Map<String, dynamic> summary = data['athleteSummary'] as Map<String, dynamic>;
      expect(summary['totalInjuriesLogged'], equals(3));
      expect(summary['activeInjuriesCount'], equals(2));
      expect(summary['acuteCount'], equals(1));
      expect(summary['chronicCount'], equals(1));
      expect(summary['resolvedCount'], equals(1));

      final List<Map<String, dynamic>> injuries =
          (data['injuries'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(injuries.length, equals(3));
      expect(injuries.first['name'], equals('Patellar Tendinopathy'));
      expect(injuries.first['regionDisplayName'], equals('Left Knee'));
      expect(injuries.first['stageLabel'], equals('ACUTE'));
    });

    test('generatePdfFileName and generateJsonFileName produce timestamped filenames', () {
      final DateTime testDate = DateTime(2026, 8, 28, 14, 30, 45);
      final String pdfName = InjuryExportService.generatePdfFileName(testDate);
      final String jsonName = InjuryExportService.generateJsonFileName(testDate);

      expect(pdfName, equals('oly_injury_report_20260828_143045.pdf'));
      expect(jsonName, equals('oly_injury_history_20260828_143045.json'));
    });

    test('generatePdfReport produces non-empty PDF document bytes', () async {
      final Uint8List pdfBytes = await InjuryExportService.generatePdfReport(
        allInjuries: mockInjuries,
        athleteName: 'Lasha Talakhadze',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(500));

      // Validate %PDF magic header: 0x25, 0x50, 0x44, 0x46
      expect(pdfBytes[0], equals(0x25));
      expect(pdfBytes[1], equals(0x50));
      expect(pdfBytes[2], equals(0x44));
      expect(pdfBytes[3], equals(0x46));
    });
  });

  group('InjuryExportBottomSheet Widget Tests', () {
    testWidgets('Renders export options, summary metrics, and copies JSON', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final InjuryProvider provider = InjuryProvider(storage);

      final List<InjuryRecord> injuries = <InjuryRecord>[
        InjuryRecord(
          id: 'test_1',
          name: 'Patellar Tendinopathy',
          region: InjuryRegion.leftKnee,
          onsetDate: DateTime.now().subtract(const Duration(days: 3)),
          painScale: 5,
        ),
      ];

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider<InjuryProvider>.value(
            value: provider,
            child: Scaffold(
              body: InjuryExportBottomSheet(injuries: injuries),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Export Injury History'), findsOneWidget);
      expect(find.text('Clinical & Athletic PDF Report'), findsOneWidget);
      expect(find.text('Structured JSON Data Export'), findsOneWidget);
      expect(find.text('Share / Save PDF'), findsOneWidget);
      expect(find.text('Preview / Print'), findsOneWidget);
      expect(find.text('Share .JSON File'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);

      // Tap Copy to Clipboard
      await tester.tap(find.text('Copy to Clipboard'));
      await tester.pumpAndSettle();

      expect(find.text('Copied!'), findsOneWidget);
    });
  });
}
