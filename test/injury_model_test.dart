import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';

void main() {
  group('InjuryRecord & Stage Classification Tests', () {
    test('Classifies Acute stage for injuries under 14 days old', () {
      final InjuryRecord acuteInjury = InjuryRecord(
        id: 'inj_1',
        name: 'Left Patellar Strain',
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now().subtract(const Duration(days: 4)),
        painScale: 4,
      );

      expect(acuteInjury.durationInDays, equals(4));
      expect(acuteInjury.stage, equals(InjuryStage.acute));
      expect(acuteInjury.stage.label, equals('ACUTE'));
      expect(acuteInjury.formattedDuration, equals('4 days'));
    });

    test('Classifies Subacute stage for injuries between 14 and 42 days old', () {
      final InjuryRecord subacuteInjury = InjuryRecord(
        id: 'inj_2',
        name: 'Shoulder Impingement',
        region: InjuryRegion.rightShoulder,
        onsetDate: DateTime.now().subtract(const Duration(days: 21)),
        painScale: 3,
      );

      expect(subacuteInjury.durationInDays, equals(21));
      expect(subacuteInjury.stage, equals(InjuryStage.subacute));
      expect(subacuteInjury.stage.label, equals('SUBACUTE'));
      expect(subacuteInjury.formattedDuration, contains('3 weeks'));
    });

    test('Classifies Chronic stage for injuries older than 42 days (6+ weeks)', () {
      final InjuryRecord chronicInjury = InjuryRecord(
        id: 'inj_3',
        name: 'Lumbar Disc Strain',
        region: InjuryRegion.lumbarSpine,
        onsetDate: DateTime.now().subtract(const Duration(days: 60)),
        painScale: 5,
      );

      expect(chronicInjury.durationInDays, equals(60));
      expect(chronicInjury.stage, equals(InjuryStage.chronic));
      expect(chronicInjury.stage.label, equals('CHRONIC'));
      expect(chronicInjury.formattedDuration, contains('2+ months'));
    });

    test('Classifies Severity correctly from pain scale', () {
      expect(InjurySeverityExtension.fromPain(2), equals(InjurySeverity.mild));
      expect(InjurySeverityExtension.fromPain(5), equals(InjurySeverity.moderate));
      expect(InjurySeverityExtension.fromPain(8), equals(InjurySeverity.severe));
    });

    test('Serializes and deserializes InjuryRecord correctly', () {
      final DateTime onset = DateTime(2026, 1, 15, 10, 0);
      final InjuryRecord original = InjuryRecord(
        id: 'test_id',
        name: 'Patellar Tendinopathy',
        osiicsCode: 'KJTP',
        region: InjuryRegion.leftKnee,
        onsetDate: onset,
        painScale: 6,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ],
        notes: 'Pain on deep catch',
        isActive: true,
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
      );

      final Map<String, dynamic> json = original.toJson();
      final InjuryRecord restored = InjuryRecord.fromJson(json);

      expect(restored.id, equals('test_id'));
      expect(restored.name, equals('Patellar Tendinopathy'));
      expect(restored.osiicsCode, equals('KJTP'));
      expect(restored.region, equals(InjuryRegion.leftKnee));
      expect(restored.painScale, equals(6));
      expect(restored.severity, equals(InjurySeverity.moderate));
      expect(restored.constraints, contains(BiomechanicalConstraint.avoidDeepKneeFlexion));
      expect(restored.safeSubstitutions.first.replacementName, equals('Power Snatch from Blocks'));
    });

    test('InjuryCheckinDiff calculates delta pain correctly', () {
      final InjuryCheckinDiff worsened = InjuryCheckinDiff(
        region: InjuryRegion.rightShoulder,
        initialPain: 2,
        postPain: 5,
      );
      expect(worsened.deltaPain, equals(3));
      expect(worsened.hasWorsened, isTrue);
      expect(worsened.hasImproved, isFalse);

      final InjuryCheckinDiff improved = InjuryCheckinDiff(
        region: InjuryRegion.leftKnee,
        initialPain: 4,
        postPain: 2,
      );
      expect(improved.deltaPain, equals(-2));
      expect(improved.hasImproved, isTrue);
      expect(improved.hasWorsened, isFalse);
    });

    test('InjurySubRegion returns appropriate targets for each InjuryRegion', () {
      final List<InjurySubRegion> kneeTargets =
          InjurySubRegionExtension.forRegion(InjuryRegion.leftKnee);
      expect(kneeTargets, contains(InjurySubRegion.patellarTendon));
      expect(kneeTargets, contains(InjurySubRegion.quadricepsTendon));
      expect(kneeTargets, contains(InjurySubRegion.medialCompartment));
      expect(kneeTargets, contains(InjurySubRegion.generalKnee));

      final List<InjurySubRegion> ankleTargets =
          InjurySubRegionExtension.forRegion(InjuryRegion.leftCalfAnkle);
      expect(ankleTargets, contains(InjurySubRegion.achillesTendonMid));
      expect(ankleTargets, contains(InjurySubRegion.bigToeMtp));
      expect(ankleTargets, contains(InjurySubRegion.shinSplints));

      final List<InjurySubRegion> hipTargets =
          InjurySubRegionExtension.forRegion(InjuryRegion.rightHipGlute);
      expect(hipTargets, contains(InjurySubRegion.adductorGroin));
      expect(hipTargets, contains(InjurySubRegion.hipFlexorPsoas));
      expect(hipTargets, contains(InjurySubRegion.siJoint));
    });

    test('InjuryRecord fullDisplayName handles sub-regions correctly', () {
      final InjuryRecord withSub = InjuryRecord(
        id: 'rec_sub',
        name: 'Patellar Tendon Soreness',
        region: InjuryRegion.leftKnee,
        subRegion: InjurySubRegion.patellarTendon,
        onsetDate: DateTime.now(),
        painScale: 4,
      );
      expect(withSub.fullDisplayName, equals('Left Knee • Patellar Tendon'));

      final InjuryRecord withGeneral = InjuryRecord(
        id: 'rec_gen',
        name: 'Left Knee Strain',
        region: InjuryRegion.leftKnee,
        subRegion: InjurySubRegion.generalKnee,
        onsetDate: DateTime.now(),
        painScale: 3,
      );
      expect(withGeneral.fullDisplayName, equals('Left Knee'));

      final InjuryRecord withoutSub = InjuryRecord(
        id: 'rec_none',
        name: 'Left Knee Strain',
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now(),
        painScale: 3,
      );
      expect(withoutSub.fullDisplayName, equals('Left Knee'));
    });

    test('InjuryRecord serializes and deserializes subRegion with backwards compatibility', () {
      final InjuryRecord recordWithSub = InjuryRecord(
        id: 'rec_1',
        name: 'Groin Strain',
        region: InjuryRegion.leftHipGlute,
        subRegion: InjurySubRegion.adductorGroin,
        onsetDate: DateTime.now(),
        painScale: 5,
      );

      final Map<String, dynamic> json = recordWithSub.toJson();
      expect(json['subRegion'], equals('adductorGroin'));

      final InjuryRecord restored = InjuryRecord.fromJson(json);
      expect(restored.subRegion, equals(InjurySubRegion.adductorGroin));

      // Legacy JSON without subRegion
      final Map<String, dynamic> legacyJson = <String, dynamic>{
        'id': 'legacy_1',
        'name': 'Shoulder Ache',
        'region': 'rightShoulder',
        'onsetDate': DateTime.now().toIso8601String(),
        'painScale': 3,
      };
      final InjuryRecord legacyRestored = InjuryRecord.fromJson(legacyJson);
      expect(legacyRestored.subRegion, isNull);
      expect(legacyRestored.fullDisplayName, equals('Right Shoulder'));
    });
  });
}
