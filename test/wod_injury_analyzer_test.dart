import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/services/wod_injury_analyzer.dart';

void main() {
  group('WodInjuryAnalyzer', () {
    test('returns empty when no injuries or movements', () {
      expect(
        WodInjuryAnalyzer.analyzePrecautions(
          movements: <String>[],
          activeInjuries: <InjuryRecord>[],
        ),
        isEmpty,
      );
    });

    test('detects knee contraindications for squatting movements', () {
      final InjuryRecord kneeInjury = InjuryRecord(
        id: 'inj-knee',
        name: 'Patellar Tendonitis',
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now(),
        painScale: 5,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
        ],
      );

      final List<WodInjuryPrecaution> precautions =
          WodInjuryAnalyzer.analyzePrecautions(
        movements: <String>['21 Thrusters (95 lbs)', '21 Pull-ups'],
        activeInjuries: <InjuryRecord>[kneeInjury],
      );

      expect(precautions.length, 1);
      expect(precautions.first.movement, '21 Thrusters (95 lbs)');
      expect(precautions.first.injury.id, 'inj-knee');
      expect(precautions.first.cautionReason, contains('knee flexion'));
    });

    test('detects shoulder contraindications for overhead movements', () {
      final InjuryRecord shoulderInjury = InjuryRecord(
        id: 'inj-shoulder',
        name: 'Shoulder Impingement',
        region: InjuryRegion.rightShoulder,
        onsetDate: DateTime.now(),
        painScale: 4,
        constraints: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidOverheadLockout,
        ],
      );

      final List<WodInjuryPrecaution> precautions =
          WodInjuryAnalyzer.analyzePrecautions(
        movements: <String>[
          '30 Clean and Jerks',
          'Run 400m',
        ],
        activeInjuries: <InjuryRecord>[shoulderInjury],
      );

      expect(precautions.length, 1);
      expect(precautions.first.movement, '30 Clean and Jerks');
      expect(precautions.first.injury.name, 'Shoulder Impingement');
    });

    test('ignores resolved injuries', () {
      final InjuryRecord resolvedKnee = InjuryRecord(
        id: 'inj-resolved',
        name: 'Old Knee Sprain',
        region: InjuryRegion.rightKnee,
        onsetDate: DateTime.now().subtract(const Duration(days: 60)),
        painScale: 0,
        isActive: false,
      );

      final List<WodInjuryPrecaution> precautions =
          WodInjuryAnalyzer.analyzePrecautions(
        movements: <String>['Back Squat 5x5'],
        activeInjuries: <InjuryRecord>[resolvedKnee],
      );

      expect(precautions, isEmpty);
    });
  });
}
