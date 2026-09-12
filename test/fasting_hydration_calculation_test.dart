import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/services/fasting_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fasting Hydration & Biomarker Science Tests', () {
    test('Zero adjustment during fed / early post-absorptive state (<4 hrs)', () {
      final FastingHydrationAdjustment adj =
          FastingEngineService.calculateFastingHydrationAdjustment(
        elapsedHours: 2.5,
      );

      expect(adj.bonusOz, equals(0.0));
      expect(adj.bonusMl, equals(0));
      expect(adj.suggestedSodiumMg, equals(0));
      expect(adj.isDeepKetosis, isFalse);
      expect(adj.isHemoconcentrationRisk, isFalse);
    });

    test('Stage-based adjustments for 14h, 18h, and 26h fasting without meter readings', () {
      // 14 hours (ketosis onset)
      final FastingHydrationAdjustment adj14 =
          FastingEngineService.calculateFastingHydrationAdjustment(
        elapsedHours: 14.0,
      );
      expect(adj14.bonusOz, equals(6.0));
      expect(adj14.bonusMl, equals(177));
      expect(adj14.suggestedSodiumMg, equals(300));

      // 18 hours (natriuresis active)
      final FastingHydrationAdjustment adj18 =
          FastingEngineService.calculateFastingHydrationAdjustment(
        elapsedHours: 18.0,
      );
      expect(adj18.bonusOz, equals(12.0));
      expect(adj18.bonusMl, equals(355));
      expect(adj18.suggestedSodiumMg, equals(500));

      // 26 hours (extended fast / deep autophagy)
      final FastingHydrationAdjustment adj26 =
          FastingEngineService.calculateFastingHydrationAdjustment(
        elapsedHours: 26.0,
      );
      expect(adj26.bonusOz, equals(18.0));
      expect(adj26.bonusMl, equals(532));
      expect(adj26.suggestedSodiumMg, equals(700));
      expect(adj26.isDeepKetosis, isTrue);
    });

    test('Keto-Mojo reading with deep ketosis (GKI < 3.0, BOHB >= 1.5) triggers natriuresis surcharge', () {
      final FastingBiomarkerEntry deepKetosisEntry = FastingBiomarkerEntry.create(
        id: 'test_entry_1',
        glucoseMgDl: 72.0,
        ketoneMmolL: 2.2,
      );

      final FastingHydrationAdjustment adj =
          FastingEngineService.calculateFastingHydrationAdjustment(
        elapsedHours: 16.0,
        latestBiomarker: deepKetosisEntry,
      );

      expect(adj.bonusOz, equals(16.0));
      expect(adj.bonusMl, equals(473));
      expect(adj.suggestedSodiumMg, equals(600));
      expect(adj.isDeepKetosis, isTrue);
      expect(adj.rationale, contains('Deep Ketosis Natriuresis'));
    });

    test('Hemoconcentration detection (elevated glucose >110 with elevated ketones) triggers rehydration surge', () {
      final FastingBiomarkerEntry hemoEntry = FastingBiomarkerEntry.create(
        id: 'test_hemo',
        glucoseMgDl: 125.0,
        ketoneMmolL: 1.4,
      );

      final FastingHydrationAdjustment adj =
          FastingEngineService.calculateFastingHydrationAdjustment(
        elapsedHours: 17.0,
        latestBiomarker: hemoEntry,
      );

      expect(adj.bonusOz, equals(24.0));
      expect(adj.bonusMl, equals(710));
      expect(adj.suggestedSodiumMg, equals(800));
      expect(adj.isHemoconcentrationRisk, isTrue);
      expect(adj.rationale, contains('Hemoconcentration Alert'));
    });
  });

  group('AthleteCircadianConfig Model Tests', () {
    test('Defaults to syncWithFuelWaterTarget=true and adjustForFastingBiomarkers=true', () {
      const AthleteCircadianConfig config = AthleteCircadianConfig();
      expect(config.syncWithFuelWaterTarget, isTrue);
      expect(config.adjustForFastingBiomarkers, isTrue);
      expect(config.dailyWaterTargetMl, equals(3000));
    });

    test('Serializes and deserializes sync flags properly', () {
      const AthleteCircadianConfig config = AthleteCircadianConfig(
        dailyWaterTargetMl: 3500,
        syncWithFuelWaterTarget: false,
        adjustForFastingBiomarkers: false,
      );

      final Map<String, dynamic> json = config.toJson();
      final AthleteCircadianConfig restored =
          AthleteCircadianConfig.fromJson(json);

      expect(restored.dailyWaterTargetMl, equals(3500));
      expect(restored.syncWithFuelWaterTarget, isFalse);
      expect(restored.adjustForFastingBiomarkers, isFalse);
    });
  });

  group('FastingProvider Dynamic Target Integration Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      storage = await StorageService.init();
    });

    test('Calculates effective target from synced Fuel target with training day surcharge', () async {
      final FastingProvider provider = FastingProvider(storage);

      // Sync rest day Fuel target of 100 oz (~2,957 mL)
      provider.syncFuelContext(fuelWaterOz: 100.0, isTrainingDay: false);
      expect(provider.effectiveDailyWaterTargetMl, equals(2957));

      // Sync training day Fuel target with +24 oz lifting surcharge (124 oz ~ 3,667 mL)
      provider.syncFuelContext(fuelWaterOz: 124.0, isTrainingDay: true);
      expect(provider.effectiveDailyWaterTargetMl, equals(3667));
    });

    test('Combines Fuel target with deep ketosis biomarker bonus when active', () async {
      final FastingProvider provider = FastingProvider(storage);

      provider.syncFuelContext(fuelWaterOz: 100.0, isTrainingDay: false);

      // Start an active fast so elapsed hours > 0
      await provider.startFast(
        protocol: FastingProtocol.intermittent16_8,
        customHours: 16,
      );

      // Log a deep ketosis biomarker
      await provider.addBiomarkerEntry(
        glucoseMgDl: 70.0,
        ketoneMmolL: 2.0,
      );

      // 100 oz (2957 mL) + 16 oz ketosis bonus (473 mL) = 3430 mL
      expect(provider.effectiveDailyWaterTargetMl, equals(2957 + 473));
    });

    test('Falls back to manual circadian target when syncWithFuelWaterTarget is disabled', () async {
      final FastingProvider provider = FastingProvider(storage);

      provider.syncFuelContext(fuelWaterOz: 124.0, isTrainingDay: true);

      await provider.updateCircadianConfig(
        provider.circadianConfig.copyWith(
          syncWithFuelWaterTarget: false,
          adjustForFastingBiomarkers: false,
          dailyWaterTargetMl: 4000,
        ),
      );

      expect(provider.effectiveDailyWaterTargetMl, equals(4000));
    });

    test('Bridges water logging in mL to Fuel tab ounces via onLogToFuel callback', () async {
      final FastingProvider provider = FastingProvider(storage);
      await provider.startFast(protocol: FastingProtocol.intermittent16_8);

      double loggedFuelOz = 0.0;
      await provider.logWater(500, onLogToFuel: (double oz) {
        loggedFuelOz += oz;
      });

      expect(provider.activeSession!.waterLoggedMl, equals(500));
      expect(loggedFuelOz, closeTo(16.9, 0.1));
    });
  });
}
