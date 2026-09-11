import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/services/fasting_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FastingBiomarkerEntry & GKI Tests', () {
    test('Calculates Seyfried GKI accurately and categorizes metabolic zones', () {
      // 80 mg/dL glucose, 1.5 mmol/L ketones
      // (80 / 18.016) / 1.5 = 4.44 / 1.5 = ~2.96 (High Ketosis)
      final FastingBiomarkerEntry entry1 = FastingBiomarkerEntry.create(
        id: '1',
        glucoseMgDl: 80.0,
        ketoneMmolL: 1.5,
      );
      expect(entry1.gki, closeTo(2.96, 0.02));
      expect(entry1.zone, equals(GkiMetabolicZone.highKetosis));

      // 70 mg/dL glucose, 4.0 mmol/L ketones (Deep Fasting Autophagy)
      // (70 / 18.016) / 4.0 = 3.885 / 4.0 = ~0.97 (Therapeutic Autophagy < 1.0)
      final FastingBiomarkerEntry entry2 = FastingBiomarkerEntry.create(
        id: '2',
        glucoseMgDl: 70.0,
        ketoneMmolL: 4.0,
      );
      expect(entry2.gki, closeTo(0.97, 0.02));
      expect(entry2.zone, equals(GkiMetabolicZone.therapeuticAutophagy));

      // 100 mg/dL glucose, 0.2 mmol/L ketones (Fed / Baseline)
      final FastingBiomarkerEntry entry3 = FastingBiomarkerEntry.create(
        id: '3',
        glucoseMgDl: 100.0,
        ketoneMmolL: 0.2,
      );
      expect(entry3.zone, equals(GkiMetabolicZone.notInKetosis));
    });
  });

  group('FastingSession & Stage Transitions', () {
    test('Correctly maps elapsed hours to biological stages', () {
      final DateTime now = DateTime.now();

      // 2 hours in -> Fed
      final FastingSession sFed = FastingSession(
        id: 'f1',
        protocol: FastingProtocol.intermittent16_8,
        targetDurationSeconds: 16 * 3600,
        startTime: now.subtract(const Duration(hours: 2)),
      );
      expect(sFed.currentStage, equals(FastingBiologicalStage.fed));

      // 8 hours in -> Post-Absorptive
      final FastingSession sPost = FastingSession(
        id: 'f2',
        protocol: FastingProtocol.intermittent16_8,
        targetDurationSeconds: 16 * 3600,
        startTime: now.subtract(const Duration(hours: 8)),
      );
      expect(sPost.currentStage, equals(FastingBiologicalStage.postAbsorptive));

      // 15 hours in -> Ketosis Onset
      final FastingSession sKeto = FastingSession(
        id: 'f3',
        protocol: FastingProtocol.intermittent16_8,
        targetDurationSeconds: 16 * 3600,
        startTime: now.subtract(const Duration(hours: 15)),
      );
      expect(sKeto.currentStage, equals(FastingBiologicalStage.ketosisOnset));

      // 20 hours in -> Autophagy Active
      final FastingSession sAuto = FastingSession(
        id: 'f4',
        protocol: FastingProtocol.dinnerToDinner24,
        targetDurationSeconds: 24 * 3600,
        startTime: now.subtract(const Duration(hours: 20)),
      );
      expect(sAuto.currentStage, equals(FastingBiologicalStage.autophagyActive));

      // 36 hours in -> Deep Autophagy & HGH Pulse
      final FastingSession sDeep = FastingSession(
        id: 'f5',
        protocol: FastingProtocol.monkFast36,
        targetDurationSeconds: 36 * 3600,
        startTime: now.subtract(const Duration(hours: 36)),
      );
      expect(sDeep.currentStage, equals(FastingBiologicalStage.deepAutophagy));

      // 60 hours in -> Stem Cell & Immune Reset
      final FastingSession sStem = FastingSession(
        id: 'f6',
        protocol: FastingProtocol.apex72,
        targetDurationSeconds: 72 * 3600,
        startTime: now.subtract(const Duration(hours: 60)),
      );
      expect(sStem.currentStage, equals(FastingBiologicalStage.stemCellReset));
    });
  });

  group('FastingEngineService Tests', () {
    test('Provides appropriate barbell load advice across fasting durations', () {
      expect(
        FastingEngineService.getBarbellAdvisory(12.0),
        contains('Full Olympic Lifting & Metcons Permitted'),
      );
      expect(
        FastingEngineService.getBarbellAdvisory(24.0),
        contains('Technique & Moderate Volume'),
      );
      expect(
        FastingEngineService.getBarbellAdvisory(38.0),
        contains('Deload / Light Barbell'),
      );
      expect(
        FastingEngineService.getBarbellAdvisory(65.0),
        contains('Fasting Peak — Zero Heavy Lifting'),
      );
    });

    test('Generates 7-day forward schedule projection', () {
      final List<FastingScheduleDay> projection =
          FastingEngineService.generateProjection(
        currentProtocol: FastingProtocol.intermittent16_8,
        config: const AthleteCircadianConfig(),
        daysCount: 7,
      );

      expect(projection.length, equals(7));
      expect(projection.first.fastingStartHour, equals('6:00 PM'));
      expect(projection.first.fastingEndHour, equals('10:00 AM'));
      expect(projection.first.feedingWindowSummary, contains('10:00 AM – 6:00 PM'));
    });

    test('Returns comprehensive seed pantry and refeeding groceries', () {
      final items = FastingEngineService.getSeedPantryItems();
      expect(items.length, greaterThanOrEqualTo(10));
      expect(items.any((i) => i.name.contains('Salt')), isTrue);
      expect(items.any((i) => i.name.contains('Bone Broth')), isTrue);
      expect(items.any((i) => i.name.contains('Pasture-Raised Organic Eggs')), isTrue);
    });
  });

  group('FastingProvider Flow Tests', () {
    test('Starts fast, logs electrolytes & biomarkers, and completes session', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      final FastingProvider provider = FastingProvider(storage);

      expect(provider.isFastingActive, isFalse);

      // Start 16:8 Fast
      await provider.startFast(protocol: FastingProtocol.intermittent16_8);
      expect(provider.isFastingActive, isTrue);
      expect(provider.activeSession!.protocol, equals(FastingProtocol.intermittent16_8));

      // Log Sodium and Water
      await provider.logSodium(500);
      await provider.logWater(500);
      expect(provider.activeSession!.sodiumLoggedMg, equals(500));
      expect(provider.activeSession!.waterLoggedMl, equals(500));

      // Log Keto-Mojo Reading
      await provider.addBiomarkerEntry(
        glucoseMgDl: 78.0,
        ketoneMmolL: 1.8,
        notes: 'Fasted baseline test',
      );
      expect(provider.activeSession!.biomarkers.length, equals(1));
      expect(provider.latestBiomarker!.glucoseMgDl, equals(78.0));

      // Toggle pantry item
      final String firstItemId = provider.pantryItems.first.id;
      final bool initialStatus = provider.pantryItems.first.isChecked;
      await provider.togglePantryItem(firstItemId);
      expect(provider.pantryItems.first.isChecked, equals(!initialStatus));

      // End Fast
      await provider.endFast(
        energyRating: 9,
        mentalClarityRating: 10,
        hungerWaveRating: 2,
        notes: 'Great 16:8 fast, felt strong for 6am lift!',
      );

      expect(provider.isFastingActive, isFalse);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.isCompleted, isTrue);
      expect(provider.history.first.energyRating, equals(9));
    });
  });
}
