import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/kettlebell_mile_log.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kettlebell Mile Model & Progression Tests', () {
    test('KettlebellMileLog serializes and deserializes correctly', () {
      final KettlebellMileLog log = KettlebellMileLog(
        id: 'kb_test_1',
        date: DateTime.now(),
        weightKg: 12.0,
        bodyweightPercentage: 10.0,
        speedMph: 3.8,
        inclinePct: 2.0,
        durationSeconds: 1120, // 18m 40s (< 20 mins)
        completedUnder20Min: true,
        notes: 'Felt strong, solid carry',
      );

      final Map<String, dynamic> json = log.toJson();
      final KettlebellMileLog restored = KettlebellMileLog.fromJson(json);

      expect(restored.id, equals('kb_test_1'));
      expect(restored.weightKg, equals(12.0));
      expect(restored.bodyweightPercentage, equals(10.0));
      expect(restored.speedMph, equals(3.8));
      expect(restored.inclinePct, equals(2.0));
      expect(restored.durationSeconds, equals(1120));
      expect(restored.completedUnder20Min, isTrue);
      expect(restored.formattedDuration, equals('18:40'));
      expect(restored.notes, equals('Felt strong, solid carry'));
    });

    test('StorageService persists and retrieves kettlebell mile logs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);

      expect(storage.loadKettlebellMileLogs(), isEmpty);

      await storage.logKettlebellMileSet(
        weightKg: 10.0,
        bodyweightPercentage: 10.0,
        speedMph: 3.5,
        inclinePct: 1.0,
        durationSeconds: 1140, // 19m (< 20m)
        completedUnder20Min: true,
      );

      final List<KettlebellMileLog> history = storage.getKettlebellMileHistory();
      expect(history.length, equals(1));
      expect(history.first.weightKg, equals(10.0));
      expect(history.first.completedUnder20Min, isTrue);
    });

    test('RecoveryProvider starts at 10% bodyweight and calculates weight correctly', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final RecoveryProvider recovery = RecoveryProvider(storage);

      // Baseline with no history should be 10%
      expect(recovery.getCurrentKettlebellTargetPercentage(), equals(10.0));

      // For 100kg athlete -> 10kg
      expect(
        recovery.calculateSuggestedKettlebellWeightKg(athleteWeightKg: 100.0),
        equals(10.0),
      );

      // For 80kg athlete -> 8kg
      expect(
        recovery.calculateSuggestedKettlebellWeightKg(athleteWeightKg: 80.0),
        equals(8.0),
      );
    });

    test('RecoveryProvider unlocks progression (+2.5% BW) when mile completed in < 20 mins', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final RecoveryProvider recovery = RecoveryProvider(storage);

      // Log a successful sub-20 minute mile (e.g. 18:30 = 1110s)
      await recovery.logKettlebellMile(
        weightKg: 10.0,
        bodyweightPercentage: 10.0,
        speedMph: 3.6,
        inclinePct: 1.5,
        durationSeconds: 1110,
        completedUnder20Min: true,
      );

      // Next target percentage should progress from 10% to 12.5%
      expect(recovery.getCurrentKettlebellTargetPercentage(), equals(12.5));
      expect(
        recovery.calculateSuggestedKettlebellWeightKg(athleteWeightKg: 100.0),
        equals(12.5),
      );

      // Log another sub-20 minute mile at 12.5%
      await recovery.logKettlebellMile(
        weightKg: 12.5,
        bodyweightPercentage: 12.5,
        speedMph: 3.7,
        inclinePct: 1.5,
        durationSeconds: 1150,
        completedUnder20Min: true,
      );

      // Next target percentage should progress to 15.0%
      expect(recovery.getCurrentKettlebellTargetPercentage(), equals(15.0));
    });

    test('RecoveryProvider does not progress weight when mile takes >= 20 mins', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final RecoveryProvider recovery = RecoveryProvider(storage);

      // Log a session taking 22 minutes (1320s >= 1200s)
      await recovery.logKettlebellMile(
        weightKg: 10.0,
        bodyweightPercentage: 10.0,
        speedMph: 3.0,
        inclinePct: 1.0,
        durationSeconds: 1320,
        completedUnder20Min: false,
      );

      // Target percentage remains at 10.0%
      expect(recovery.getCurrentKettlebellTargetPercentage(), equals(10.0));
    });

    test('RecoveryProvider caps max progression at 30% bodyweight', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final RecoveryProvider recovery = RecoveryProvider(storage);

      // Log a session at 30% completed under 20 mins
      await recovery.logKettlebellMile(
        weightKg: 30.0,
        bodyweightPercentage: 30.0,
        speedMph: 4.0,
        inclinePct: 2.0,
        durationSeconds: 1100,
        completedUnder20Min: true,
      );

      // Target percentage remains capped at 30.0%
      expect(recovery.getCurrentKettlebellTargetPercentage(), equals(30.0));
    });
  });
}
