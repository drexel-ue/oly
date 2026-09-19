import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/illness_model.dart';
import 'package:oly/providers/illness_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IllnessRecord Domain Model & Neck Rule Tests', () {
    test('Mild Above Neck cold reflects Neck Rule parameters', () {
      final IllnessRecord record = IllnessRecord.createNew(
        severity: IllnessSeverity.mildAboveNeck,
        symptoms: <IllnessSymptom>[
          IllnessSymptom.runnyNose,
          IllnessSymptom.nasalCongestion,
          IllnessSymptom.sneezing,
        ],
      );

      expect(record.isActive, isTrue);
      expect(record.isConvalescing, isFalse);
      expect(record.isFullyResolved, isFalse);
      expect(record.readinessDeduction, equals(25));
      expect(record.suggestedLoadScale, equals(0.70));
      expect(record.isBallisticContraindicated, isFalse);
      expect(record.isFastingContraindicated, isFalse);
      expect(record.isWimHofContraindicated, isFalse);
      expect(record.hydrationBonusMl, equals(500));
    });

    test('Systemic Fever viral illness applies complete rest constraints', () {
      final IllnessRecord record = IllnessRecord.createNew(
        severity: IllnessSeverity.systemicFever,
        symptoms: <IllnessSymptom>[
          IllnessSymptom.feverOrChills,
          IllnessSymptom.muscleAches,
          IllnessSymptom.fatigueAndMalaise,
        ],
        hasFever: true,
        temperatureCelsius: 38.8,
      );

      expect(record.isActive, isTrue);
      expect(record.readinessDeduction, equals(70));
      expect(record.suggestedLoadScale, equals(0.0));
      expect(record.isBallisticContraindicated, isTrue);
      expect(record.isFastingContraindicated, isTrue);
      expect(record.isWimHofContraindicated, isTrue);
      expect(record.hydrationBonusMl, equals(1000));
    });

    test('Deep respiratory illness contraindicates breathwork and ballistics', () {
      final IllnessRecord record = IllnessRecord.createNew(
        severity: IllnessSeverity.respiratoryDeep,
        symptoms: <IllnessSymptom>[
          IllnessSymptom.deepChestCough,
          IllnessSymptom.shortnessOfBreath,
        ],
      );

      expect(record.readinessDeduction, equals(55));
      expect(record.isBallisticContraindicated, isTrue);
      expect(record.isWimHofContraindicated, isTrue);
      expect(record.hydrationBonusMl, equals(750));
    });

    test('Gastrointestinal bug contraindicates fasting and adds 1000ml fluid', () {
      final IllnessRecord record = IllnessRecord.createNew(
        severity: IllnessSeverity.gastrointestinal,
        symptoms: <IllnessSymptom>[
          IllnessSymptom.nauseaOrVomiting,
          IllnessSymptom.gastrointestinalUpset,
        ],
      );

      expect(record.readinessDeduction, equals(60));
      expect(record.isFastingContraindicated, isTrue);
      expect(record.hydrationBonusMl, equals(1000));
    });

    test('JSON serialization roundtrip preserves all fields', () {
      final IllnessRecord original = IllnessRecord(
        id: 'illness_test_123',
        onsetDate: DateTime(2026, 9, 14, 8, 30),
        severity: IllnessSeverity.systemicFever,
        symptoms: const <IllnessSymptom>[
          IllnessSymptom.feverOrChills,
          IllnessSymptom.headache,
        ],
        hasFever: true,
        temperatureCelsius: 38.6,
        notes: 'Prescribed bed rest by team doc',
        reEntryStage: ReEntryStage.stage1LightRecovery,
        reEntryStageStartedAt: DateTime(2026, 9, 16, 9),
      );

      final Map<String, dynamic> json = original.toJson();
      final IllnessRecord deserialized = IllnessRecord.fromJson(json);

      expect(deserialized.id, equals(original.id));
      expect(deserialized.severity, equals(IllnessSeverity.systemicFever));
      expect(deserialized.hasFever, isTrue);
      expect(deserialized.temperatureCelsius, equals(38.6));
      expect(deserialized.notes, equals('Prescribed bed rest by team doc'));
      expect(deserialized.reEntryStage, equals(ReEntryStage.stage1LightRecovery));
      expect(deserialized.isTrainingFrozen, isTrue);
      expect(deserialized.symptoms.length, equals(2));
    });
  });

  group('IllnessProvider State & Return-to-Play Protocol Tests', () {
    late StorageService storage;
    late IllnessProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      provider = IllnessProvider(storage);
    });

    test('Initial state has no active illness or convalescence', () {
      expect(provider.allRecords, isEmpty);
      expect(provider.activeRecords, isEmpty);
      expect(provider.hasActiveIllness, isFalse);
      expect(provider.isConvalescing, isFalse);
      expect(provider.effectiveReadinessDeduction, equals(0));
      expect(provider.effectiveLoadScale, equals(1.0));
      expect(provider.isTrainingFrozen, isFalse);
    });

    test('Logging an illness updates provider getters and persists', () async {
      await provider.logIllness(
        severity: IllnessSeverity.systemicFever,
        symptoms: <IllnessSymptom>[
          IllnessSymptom.feverOrChills,
          IllnessSymptom.muscleAches,
        ],
        hasFever: true,
        temperatureCelsius: 39,
      );

      expect(provider.hasActiveIllness, isTrue);
      expect(provider.activeRecord, isNotNull);
      expect(provider.isTrainingFrozen, isTrue);
      expect(provider.effectiveReadinessDeduction, equals(70));
      expect(provider.effectiveLoadScale, equals(0));
      expect(provider.isFastingContraindicated, isTrue);
      expect(provider.isWimHofContraindicated, isTrue);
      expect(provider.hydrationBonusMl, equals(1000));

      // Check persistence with fresh instance
      final IllnessProvider reloaded = IllnessProvider(storage);
      expect(reloaded.hasActiveIllness, isTrue);
      expect(reloaded.effectiveReadinessDeduction, equals(70));
    });

    test('Resolving illness initiates 3-Day Return-to-Play Re-Entry ramp', () async {
      await provider.logIllness(
        severity: IllnessSeverity.systemicFever,
        hasFever: true,
      );

      final String illnessId = provider.activeRecord!.id;

      // 1. Mark Resolved -> Moves to Re-Entry Stage 1
      await provider.resolveIllness(illnessId);

      expect(provider.hasActiveIllness, isFalse);
      expect(provider.isConvalescing, isTrue);
      expect(provider.convalescingRecord, isNotNull);
      expect(
        provider.convalescingRecord!.reEntryStage,
        equals(ReEntryStage.stage1LightRecovery),
      );
      expect(provider.effectiveReadinessDeduction, equals(30));
      expect(provider.effectiveLoadScale, equals(0.50));
      expect(provider.isTrainingFrozen, isFalse);

      // 2. Advance to Stage 2 (70% Load Cap)
      await provider.advanceReEntryStage(illnessId);

      expect(provider.isConvalescing, isTrue);
      expect(
        provider.convalescingRecord!.reEntryStage,
        equals(ReEntryStage.stage2ModerateVolume),
      );
      expect(provider.effectiveReadinessDeduction, equals(15));
      expect(provider.effectiveLoadScale, equals(0.70));

      // 3. Advance to Stage 3 (Full Clearance)
      await provider.advanceReEntryStage(illnessId);

      expect(provider.isConvalescing, isFalse);
      expect(provider.effectiveReadinessDeduction, equals(0));
      expect(provider.effectiveLoadScale, equals(1.0));
      expect(provider.allRecords.first.isFullyResolved, isTrue);
    });

    test('Delete illness cleans up record and resets provider state', () async {
      await provider.logIllness(
        severity: IllnessSeverity.mildAboveNeck,
      );
      expect(provider.hasActiveIllness, isTrue);

      final String id = provider.activeRecord!.id;
      await provider.deleteIllness(id);

      expect(provider.allRecords, isEmpty);
      expect(provider.hasActiveIllness, isFalse);
      expect(provider.effectiveReadinessDeduction, equals(0));
    });
  });
}
