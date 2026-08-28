import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/views/diagnostics/crash_report_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await AppLogService.instance.init(prefs);
    await AppLogService.instance.clearLogs();
  });

  group('AppLogService & Crash Reporting Tests', () {
    test('Logs messages with correct levels and extracts formatted strings', () {
      final logger = AppLogService.instance;

      logger.info('TEST_TAG', 'User started session');
      logger.warning('TEST_TAG', 'Low battery warning');
      logger.error('TEST_TAG', 'Network timeout', error: 'SocketException');
      logger.crash('TEST_TAG', 'NullPointerException', stackTrace: StackTrace.current);

      expect(logger.logs.length, equals(4));
      expect(logger.crashAndErrorLogs.length, equals(2));

      final export = logger.exportFullLogsText();
      expect(export.contains('OLY SYSTEM DIAGNOSTICS'), isTrue);
      expect(export.contains('NullPointerException'), isTrue);
      expect(export.contains('Network timeout'), isTrue);
    });

    test('Persists errors and crashes across app restarts', () async {
      final prefs = await SharedPreferences.getInstance();
      final logger = AppLogService.instance;

      logger.crash('OCR', 'MLKit model missing', stackTrace: StackTrace.current);
      logger.error('NUTRITION', 'Invalid JSON response');

      // Simulate re-init on fresh app launch
      await logger.init(prefs);

      expect(logger.crashAndErrorLogs.length, greaterThanOrEqualTo(2));
      expect(logger.logs.any((l) => l.message.contains('MLKit model missing')), isTrue);
    });

    testWidgets('CrashReportScreen renders log stats, filters, and probes', (tester) async {
      final logger = AppLogService.instance;
      logger.info('AUTH', 'User login');
      logger.error('CAMERA', 'Camera permission denied');
      logger.crash('ENGINE', 'Fatal unhandled exception');

      await tester.pumpWidget(const MaterialApp(
        home: CrashReportScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Diagnostics & Crash Logs'), findsOneWidget);
      expect(find.text('Total Logs'), findsOneWidget);
      expect(find.text('Crashes'), findsOneWidget);

      // Verify log cards
      expect(find.text('[CAMERA]'), findsOneWidget);
      expect(find.text('[ENGINE]'), findsOneWidget);

      // Tap Crashes filter chip
      await tester.tap(find.textContaining('CRASHES (1)'));
      await tester.pumpAndSettle();

      expect(find.text('[ENGINE]'), findsOneWidget);

      // Tap Probe button to generate a test error
      await tester.tap(find.text('Probe'));
      await tester.pumpAndSettle();

      // Reset to ALL filter chip
      await tester.tap(find.textContaining('ALL'));
      await tester.pumpAndSettle();

      expect(find.text('[DIAGNOSTICS_TEST]'), findsOneWidget);
    });
  });
}
