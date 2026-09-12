import 'package:oly/models/injury_model.dart';

/// Represents a contraindicated movement within a CrossFit WOD matching an athlete's active injury.
class WodInjuryPrecaution {
  const new({
    required this.movement,
    required this.injury,
    required this.cautionReason,
  });

  final String movement;
  final InjuryRecord injury;
  final String cautionReason;
}

/// Utility service to analyze WOD movement lists against an athlete's active injuries.
class WodInjuryAnalyzer {
  static List<WodInjuryPrecaution> analyzePrecautions({
    required List<String> movements,
    required List<InjuryRecord> activeInjuries,
  }) {
    if (movements.isEmpty || activeInjuries.isEmpty) {
      return const <WodInjuryPrecaution>[];
    }

    final List<InjuryRecord> active =
        activeInjuries.where((i) => i.isActive).toList();
    if (active.isEmpty) {
      return const <WodInjuryPrecaution>[];
    }

    final List<WodInjuryPrecaution> precautions = <WodInjuryPrecaution>[];
    final Set<String> seenPairs = <String>{};

    for (final String movement in movements) {
      final String mLower = movement.toLowerCase();

      for (final InjuryRecord injury in active) {
        String? reason;

        // Knee checks
        if (injury.region == InjuryRegion.leftKnee ||
            injury.region == InjuryRegion.rightKnee ||
            injury.constraints.contains(BiomechanicalConstraint.avoidDeepKneeFlexion)) {
          if (mLower.contains('squat') ||
              mLower.contains('thruster') ||
              mLower.contains('wall ball') ||
              mLower.contains('lunge') ||
              mLower.contains('pistol') ||
              mLower.contains('box jump')) {
            reason = 'Deep knee flexion and high patellofemoral shear may aggravate ${injury.name}';
          }
        }

        // Shoulder / Overhead checks
        if (reason == null &&
            (injury.region == InjuryRegion.leftShoulder ||
                injury.region == InjuryRegion.rightShoulder ||
                injury.constraints.contains(BiomechanicalConstraint.avoidOverheadLockout))) {
          if (mLower.contains('snatch') ||
              mLower.contains('jerk') ||
              mLower.contains('press') ||
              mLower.contains('thruster') ||
              mLower.contains('overhead') ||
              mLower.contains('pull-up') ||
              mLower.contains('muscle-up') ||
              mLower.contains('handstand') ||
              mLower.contains('hspu') ||
              mLower.contains('toes-to-bar')) {
            reason = 'Overhead lockout and dynamic shoulder pull may stress ${injury.name}';
          }
        }

        // Lumbar / Lower back checks
        if (reason == null &&
            (injury.region == InjuryRegion.lumbarSpine ||
                injury.constraints.contains(BiomechanicalConstraint.avoidAxialSpinalShear) ||
                injury.constraints.contains(BiomechanicalConstraint.avoidFloorPullShear) ||
                injury.constraints.contains(BiomechanicalConstraint.avoidAggressiveHipHinge))) {
          if (mLower.contains('deadlift') ||
              mLower.contains('clean') ||
              mLower.contains('snatch') ||
              mLower.contains('swing') ||
              mLower.contains('good morning') ||
              mLower.contains('back squat') ||
              mLower.contains('row')) {
            reason = 'Spinal compression or hinging pull may strain ${injury.name}';
          }
        }

        // Wrist checks
        if (reason == null &&
            (injury.region == InjuryRegion.leftWrist ||
                injury.region == InjuryRegion.rightWrist ||
                injury.constraints.contains(BiomechanicalConstraint.avoidWristExtension))) {
          if (mLower.contains('clean') ||
              mLower.contains('front squat') ||
              mLower.contains('thruster') ||
              mLower.contains('handstand') ||
              mLower.contains('push-up') ||
              mLower.contains('push press') ||
              mLower.contains('jerk')) {
            reason = 'Front rack wrist extension angle may irritate ${injury.name}';
          }
        }

        // Elbow checks
        if (reason == null &&
            (injury.region == InjuryRegion.leftElbow ||
                injury.region == InjuryRegion.rightElbow)) {
          if (mLower.contains('press') ||
              mLower.contains('push-up') ||
              mLower.contains('push press') ||
              mLower.contains('jerk') ||
              mLower.contains('muscle-up') ||
              mLower.contains('dip')) {
            reason = 'Loaded elbow extension may stress ${injury.name}';
          }
        }

        // Calf / Achilles / Ankle checks
        if (reason == null &&
            (injury.region == InjuryRegion.leftCalfAnkle ||
                injury.region == InjuryRegion.rightCalfAnkle)) {
          if (mLower.contains('double-under') ||
              mLower.contains('jump') ||
              mLower.contains('run') ||
              mLower.contains('sprint') ||
              mLower.contains('burpee')) {
            reason = 'High-impact landing or repetitive plantarflexion may strain ${injury.name}';
          }
        }

        // Hamstring checks
        if (reason == null &&
            (injury.region == InjuryRegion.leftHamstring ||
                injury.region == InjuryRegion.rightHamstring ||
                injury.constraints.contains(BiomechanicalConstraint.avoidHeavyEccentricStretch))) {
          if (mLower.contains('deadlift') ||
              mLower.contains('swing') ||
              mLower.contains('sprint') ||
              mLower.contains('run')) {
            reason = 'Dynamic hip hinge and eccentric hamstring load may aggravate ${injury.name}';
          }
        }

        // Chest / Pecs checks
        if (reason == null && injury.region == InjuryRegion.chestPecs) {
          if (mLower.contains('push-up') ||
              mLower.contains('bench') ||
              mLower.contains('dip') ||
              mLower.contains('muscle-up')) {
            reason = 'Heavy horizontal pressing may stress ${injury.name}';
          }
        }

        if (reason != null) {
          final String key = '${movement}_${injury.id}';
          if (!seenPairs.contains(key)) {
            seenPairs.add(key);
            precautions.add(
              WodInjuryPrecaution(
                movement: movement,
                injury: injury,
                cautionReason: reason,
              ),
            );
          }
        }
      }
    }

    return precautions;
  }
}
