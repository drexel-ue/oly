import 'dart:math';

enum WodFormat {
  amrap,
  forTime,
  emom,
  intervals,
}

extension WodFormatExtension on WodFormat {
  String get displayName {
    switch (this) {
      case WodFormat.amrap:
        return 'AMRAP';
      case WodFormat.forTime:
        return 'For Time';
      case WodFormat.emom:
        return 'EMOM';
      case WodFormat.intervals:
        return 'Intervals';
    }
  }
}

class WodMovementStandard {
  const WodMovementStandard({
    required this.movementName,
    required this.repsOrDistance,
    required this.standards,
    this.rxLoad,
  });

  final String movementName;
  final String repsOrDistance;
  final List<String> standards;
  final String? rxLoad;
}

class WodSetupExplainer {
  const WodSetupExplainer({
    required this.floorPlanAdvice,
    required this.equipmentChecklist,
    required this.movementStandards,
    required this.pacingStrategy,
    required this.targetTimes,
    required this.scalingOptions,
  });

  /// Practical advice on positioning machines, barbells, and rigs for rapid transitions
  final String floorPlanAdvice;

  /// Items to gather and prep before starting the clock
  final List<String> equipmentChecklist;

  /// Formal movement standards and judging cues
  final List<WodMovementStandard> movementStandards;

  /// Strategic pacing recommendations, breakdown schemes, and split advice
  final List<String> pacingStrategy;

  /// Benchmark performance targets (e.g. Elite, Advanced, Intermediate, Beginner)
  final Map<String, String> targetTimes;

  /// Rx vs Scaled vs Beginner modifications
  final Map<String, String> scalingOptions;
}

class WodDefinition {
  const WodDefinition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.format,
    required this.category,
    required this.targetTimeOrCap,
    required this.equipment,
    required this.movementsSummary,
    required this.setupExplainer,
    this.targetCapSeconds,
    this.hasInteractiveTracker = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final WodFormat format;
  final String category;
  final String targetTimeOrCap;
  final int? targetCapSeconds;
  final List<String> equipment;
  final List<String> movementsSummary;
  final WodSetupExplainer setupExplainer;
  final bool hasInteractiveTracker;
}

class WodCatalog {
  WodCatalog._();

  static const WodDefinition cindy = WodDefinition(
    id: 'cindy',
    name: 'Cindy',
    subtitle: '20-Minute Bodyweight Engine Triplet',
    format: WodFormat.amrap,
    category: 'The Girls Benchmark',
    targetTimeOrCap: '20:00 AMRAP',
    targetCapSeconds: 1200,
    hasInteractiveTracker: true,
    equipment: <String>[
      'Pull-up Bar',
      'Chalk (optional)',
    ],
    movementsSummary: <String>[
      '5 Pull-ups (Strict or Kipping)',
      '10 Push-ups',
      '15 Air Squats',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Set up your workout station directly beneath or adjacent to your pull-up bar. Ensure a clear 6x6 ft floor space for push-ups and air squats with non-slip flooring so you do not waste transition seconds.',
      equipmentChecklist: <String>[
        'Secure pull-up bar with good grip clearance',
        'Gymnastics chalk ready',
        'Resistance band mounted on bar if scaling pull-ups',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Pull-up',
          repsOrDistance: '5 Reps',
          standards: <String>[
            'Start in a full dead-hang with elbows fully extended and feet off the floor.',
            'Chin must clearly rise above the horizontal plane of the bar.',
            'Strict, kipping, and butterfly pull-ups are all permitted for Rx.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Push-up',
          repsOrDistance: '10 Reps',
          standards: <String>[
            'Start in full plank lockout with shoulders, hips, and ankles aligned.',
            'Chest (sternum) must touch the ground at the bottom.',
            'Full elbow lockout at the top of every rep without sagging hips.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Air Squat',
          repsOrDistance: '15 Reps',
          standards: <String>[
            'Crease of the hip must drop clearly below the top of the patella (below parallel).',
            'Full extension of hips and knees at the top with torso upright.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'Aerobic Consistency: Aim for ~50–60 seconds per round early. Avoid sprinting the first 5 rounds.',
        'Push-up Economy: Push-ups are the universal bottleneck. Break them into 5/5 or 6/4 early before muscle failure.',
        'Air Squats as Recovery: Use the squats to catch your breath with steady rhythmic breathing.',
        'Target Rounds: 15–18 rounds is solid intermediate; 20+ rounds is advanced; 25+ is elite.',
      ],
      targetTimes: <String, String>{
        'Elite': '25+ Rounds',
        'Advanced': '20–24 Rounds',
        'Intermediate': '15–19 Rounds',
        'Beginner': '10–14 Rounds',
      },
      scalingOptions: <String, String>{
        'Rx': 'Strict/kipping pull-ups, full push-ups on toes, deep air squats',
        'Scaled': 'Banded pull-ups or ring rows, knee push-ups or box push-ups, air squats to 14" target',
        'Beginner': 'Ring rows, elevated hands push-ups, air squats to parallel',
      },
    ),
  );

  static const WodDefinition jackie = WodDefinition(
    id: 'jackie',
    name: 'Jackie',
    subtitle: 'Classic Erg & Barbell Chipper',
    format: WodFormat.forTime,
    category: 'The Girls Benchmark',
    targetTimeOrCap: 'For Time (Target: 7–12 min)',
    targetCapSeconds: 1200, // 20 min cap standard
    hasInteractiveTracker: true,
    equipment: <String>[
      'Concept2 Indoor Rower',
      'Olympic Barbell (45 lb / 20.4 kg)',
      'Pull-up Rig / Bar',
      'Gymnastics Chalk',
    ],
    movementsSummary: <String>[
      '1,000 Meter Row',
      '50 Barbell Thrusters (45 lb / 20.4 kg)',
      '30 Pull-ups',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Position the Concept2 Rower directly in line with your barbell and pull-up rig. Place the barbell on the floor 3–4 feet from the rower footrests, with the pull-up bar right behind it. Your transition from rower to barbell to pull-up bar should take under 5 seconds.',
      equipmentChecklist: <String>[
        'Concept2 Rower with monitor set to 1,000m countdown or standard single distance',
        'Damper set between 4 and 6 (drag factor ~120–130)',
        'Standard 45 lb (20.4 kg) Olympic barbell on floor (or 35 lb bar + 5 lb bumper plates)',
        'Pull-up bar prepped with chalk and bands if scaling',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: '1,000m Row',
          repsOrDistance: '1,000 Meters',
          standards: <String>[
            'Athlete must remain strapped in the seat until the monitor displays 1,000 meters.',
            'Do not unstrap or stand up before 1,000m is recorded.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Barbell Thruster',
          repsOrDistance: '50 Reps',
          rxLoad: '45 lb / 20.4 kg (Standard empty Olympic Bar)',
          standards: <String>[
            'Barbell begins on the ground; first rep can be a squat clean thruster.',
            'Hip crease must clearly pass below the top of the knee at the bottom.',
            'Continuous fluid motion upward pressing overhead (no pausing at the shoulders).',
            'Full lockout of hips, knees, and elbows overhead with bar over heels.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Pull-up',
          repsOrDistance: '30 Reps',
          standards: <String>[
            'Full hang with arms straight and feet off floor at the bottom.',
            'Chin clearly breaks the horizontal plane of the pull-up bar at the top.',
            'Kipping, butterfly, or strict pull-ups are all permitted for Rx.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'The Row: Do NOT sprint the first 500m! Hold a 500m split pace that is 5–8 seconds slower than your 2k PR (e.g. 1:50–1:54/500m for ~3:40–3:48 finish). Your legs must be fresh for thrusters.',
        'Thrusters: 50 reps unbroken is tempting but will torch your heart rate. Recommended breaking schemes: 25/15/10 (advanced), 15/15/10/10 (balanced), or 10x5 with 4-second rests.',
        'Pull-ups: Your lats and grip are pre-fatigued. Aim for 3 sets of 10 or 5 sets of 6 with quick chalk breaks.',
      ],
      targetTimes: <String, String>{
        'Elite': 'Sub 6:30',
        'Advanced': '7:00 – 8:59',
        'Intermediate': '9:00 – 11:59',
        'Beginner': '12:00 – 16:00',
      },
      scalingOptions: <String, String>{
        'Rx': '1,000m Row, 45 lb Barbell, 30 Pull-ups (Kipping/Strict)',
        'Scaled': '800m–1,000m Row, 35 lb Barbell or pair of 15–20 lb Dumbbells, 30 Band-assisted Pull-ups or Ring Rows',
        'Beginner': '600m Row, 35 Dumbbell Thrusters (10–15 lb), 20–30 Ring Rows',
      },
    ),
  );

  static const WodDefinition fran = WodDefinition(
    id: 'fran',
    name: 'Fran',
    subtitle: 'The Quintessential 21-15-9 Sprint',
    format: WodFormat.forTime,
    category: 'The Girls Benchmark',
    targetTimeOrCap: 'For Time (Target: 3–8 min)',
    targetCapSeconds: 600,
    hasInteractiveTracker: true,
    equipment: <String>[
      'Olympic Barbell (95 lb men / 65 lb women)',
      'Bumper Plates & Collars',
      'Pull-up Rig',
    ],
    movementsSummary: <String>[
      '21 Thrusters • 21 Pull-ups',
      '15 Thrusters • 15 Pull-ups',
      '9 Thrusters • 9 Pull-ups',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Place your barbell 4 feet from the pull-up rig directly in front of your station. Ensure collars are clamped tight.',
      equipmentChecklist: <String>[
        'Barbell loaded to 95 lb (43 kg) or 65 lb (30 kg) with collars locked',
        'Pull-up station clear with chalk block at the base of the upright',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Barbell Thruster',
          repsOrDistance: '21 - 15 - 9 Reps',
          rxLoad: '95 lb (43 kg) / 65 lb (30 kg)',
          standards: <String>[
            'Full front squat with hip crease below knee.',
            'Direct fluid press overhead with full lockout.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Pull-up',
          repsOrDistance: '21 - 15 - 9 Reps',
          standards: <String>[
            'Dead-hang start, chin over bar at top.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'Round of 21: Pace smoothly. If you drop the bar, count 3 breaths and pick it back up.',
        'Round of 15: This is the mental barrier. Push through unbroken if possible.',
        'Round of 9: Empty the tank with a flat-out sprint.',
      ],
      targetTimes: <String, String>{
        'Elite': 'Sub 3:00',
        'Advanced': '3:00 – 4:59',
        'Intermediate': '5:00 – 7:59',
        'Beginner': '8:00 – 12:00',
      },
      scalingOptions: <String, String>{
        'Rx': '95 lb / 65 lb Barbell, Kipping/Butterfly Pull-ups',
        'Scaled': '65 lb / 45 lb Barbell or Dumbbells, Jumping Pull-ups or Ring Rows',
        'Beginner': '35–45 lb Barbell / Dumbbells, Ring Rows',
      },
    ),
  );

  static const WodDefinition grace = WodDefinition(
    id: 'grace',
    name: 'Grace',
    subtitle: '30 Clean & Jerks for Speed & Power',
    format: WodFormat.forTime,
    category: 'The Girls Benchmark',
    targetTimeOrCap: 'For Time (Target: 2–6 min)',
    targetCapSeconds: 600,
    hasInteractiveTracker: true,
    equipment: <String>[
      'Olympic Barbell (135 lb men / 95 lb women)',
      'Bumper Plates & Spring Collars',
      'Lifting Platform or Rubber Floor',
    ],
    movementsSummary: <String>[
      '30 Clean & Jerks for Time (135 / 95 lb)',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Set up on a standard 8x8 platform or open lifting bay with at least 5 feet of clearance on all sides so you can safely drop or cycle the barbell.',
      equipmentChecklist: <String>[
        'Olympic Barbell with bumper plates loaded to 135 lb (61 kg) / 95 lb (43 kg)',
        'Barbell spring collars securely locked',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Clean & Jerk',
          repsOrDistance: '30 Reps',
          rxLoad: '135 lb (61 kg) / 95 lb (43 kg)',
          standards: <String>[
            'Bar starts on the floor; power clean or full clean into front rack.',
            'Barbell must go from shoulders to overhead (push press, push jerk, or split jerk).',
            'Full lockout of elbows, hips, and knees with feet in line overhead.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'Quick Singles Strategy: Dropping each rep from overhead and quickly resetting within 2 seconds saves massive lower back fatigue.',
        'Touch & Go: Only for athletes confident in cycling 135/95 unbroken in sets of 5–8.',
      ],
      targetTimes: <String, String>{
        'Elite': 'Sub 2:00',
        'Advanced': '2:00 – 3:30',
        'Intermediate': '3:31 – 5:30',
        'Beginner': '5:31 – 8:00',
      },
      scalingOptions: <String, String>{
        'Rx': '135 lb / 95 lb',
        'Scaled': '95 lb / 65 lb or 75 lb / 55 lb',
        'Beginner': '45–65 lb training barbell',
      },
    ),
  );

  static const WodDefinition annie = WodDefinition(
    id: 'annie',
    name: 'Annie',
    subtitle: 'High-Cadence Jump Rope & Core Sprint',
    format: WodFormat.forTime,
    category: 'The Girls Benchmark',
    targetTimeOrCap: 'For Time (Target: 6–10 min)',
    targetCapSeconds: 900,
    hasInteractiveTracker: false,
    equipment: <String>[
      'Speed Jump Rope',
      'AbMat or Yoga Mat',
    ],
    movementsSummary: <String>[
      '50 - 40 - 30 - 20 - 10 Double Unders',
      '50 - 40 - 30 - 20 - 10 AbMat Sit-ups',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Place your AbMat directly beside your jump rope landing spot. Ensure at least 8 feet of vertical ceiling clearance for double-unders.',
      equipmentChecklist: <String>[
        'Sized speed rope with smooth swivel bearings',
        'AbMat with wider edge placed against lower back lumbar curve',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Double Under',
          repsOrDistance: '50-40-30-20-10 Reps',
          standards: <String>[
            'Rope must pass beneath feet twice for every single jump.',
          ],
        ),
        WodMovementStandard(
          movementName: 'AbMat Sit-up',
          repsOrDistance: '50-40-30-20-10 Reps',
          standards: <String>[
            'Shoulders and hands touch the floor behind head at the bottom.',
            'Torso rises upright so shoulders pass the hip crease and hands touch toes.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'Double Unders: Relax wrists and shoulders. Breathe steadily to keep heart rate down.',
        'Sit-ups: Use your arms as momentum pendulums to keep a fast, uninterrupted rhythm.',
      ],
      targetTimes: <String, String>{
        'Elite': 'Sub 5:00',
        'Advanced': '5:00 – 7:30',
        'Intermediate': '7:31 – 10:00',
        'Beginner': '10:01 – 14:00',
      },
      scalingOptions: <String, String>{
        'Rx': 'Double Unders + AbMat Sit-ups',
        'Scaled': '2x Single Unders (100-80-60-40-20) or Double Under attempts',
        'Beginner': 'Single unders + standard crunches/sit-ups',
      },
    ),
  );

  static const WodDefinition murph = WodDefinition(
    id: 'murph',
    name: 'Murph',
    subtitle: 'The Legendary Hero Memorial Grind',
    format: WodFormat.forTime,
    category: 'Hero Benchmark',
    targetTimeOrCap: 'For Time (Target: 35–60 min)',
    targetCapSeconds: 4200,
    hasInteractiveTracker: false,
    equipment: <String>[
      '20 lb / 14 lb Weighted Vest (Rx)',
      'Pull-up Bar',
      'Running Track or 1-Mile GPS/Outdoor Route',
    ],
    movementsSummary: <String>[
      '1 Mile Run',
      '100 Pull-ups',
      '200 Push-ups',
      '300 Air Squats',
      '1 Mile Run',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Establish a safe 1-mile marked running loop from your gym doorway. Set up pull-up chalk and a dedicated floor area right by the entrance for minimal transit time between running and the bodyweight calisthenics.',
      equipmentChecklist: <String>[
        '20 lb / 14 lb tactical weight vest securely cinched',
        'Sturdy pull-up station with hand grips/chalk',
        'Hydration bottle nearby',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Mile Run',
          repsOrDistance: '1 Mile (Out and Back)',
          standards: <String>[
            'Must complete the exact 1-mile route before and after calisthenics.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Pull-up / Push-up / Air Squat',
          repsOrDistance: '100 / 200 / 300 Reps',
          standards: <String>[
            'Can partition reps as desired (e.g. 20 rounds of 5 pull-ups, 10 push-ups, 15 air squats).',
            'Full range of motion: chest to ground, chin over bar, hips below knees.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'Partition Scheme: The 20 rounds of Cindy (5/10/15) is by far the most effective partition scheme.',
        'Run 1 Pacing: Hold an aerobic conversation pace; do not sprint the first mile.',
        'Hydration & Muscle Preservation: Shake out arms between push-up sets to prevent pec cramps.',
      ],
      targetTimes: <String, String>{
        'Elite (with Vest)': 'Sub 38:00',
        'Advanced (with Vest)': '38:00 – 48:00',
        'Intermediate (no Vest)': '48:00 – 60:00',
        'Beginner (Scaled)': '60:00 – 75:00',
      },
      scalingOptions: <String, String>{
        'Rx': 'With 20 lb / 14 lb Vest, full reps',
        'Scaled': 'Unpartitioned or partitioned with no vest, ring rows, knee push-ups',
        'Half Murph': '800m Run, 50 Pull-ups, 100 Push-ups, 150 Squats, 800m Run',
      },
    ),
  );

  static const WodDefinition helen = WodDefinition(
    id: 'helen',
    name: 'Helen',
    subtitle: '3 Rounds of Running, Swings & Pull-ups',
    format: WodFormat.forTime,
    category: 'The Girls Benchmark',
    targetTimeOrCap: '3 Rounds For Time (Target: 8–13 min)',
    targetCapSeconds: 1200,
    hasInteractiveTracker: true,
    equipment: <String>[
      '400m Running Course / Track',
      'Kettlebell (53 lb / 24 kg men, 35 lb / 16 kg women)',
      'Pull-up Rig',
    ],
    movementsSummary: <String>[
      '3 Rounds For Time:',
      '400 Meter Run',
      '21 American Kettlebell Swings (53 / 35 lb)',
      '12 Pull-ups',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Place the kettlebell 3 feet from your pull-up bar right on the pathway returning from the 400m run.',
      equipmentChecklist: <String>[
        '53 lb (24 kg) or 35 lb (16 kg) kettlebell',
        'Pull-up bar prepped with chalk',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: '400m Run',
          repsOrDistance: '400 Meters',
          standards: <String>['Complete full 400m loop each round.'],
        ),
        WodMovementStandard(
          movementName: 'American KB Swing',
          repsOrDistance: '21 Reps',
          rxLoad: '53 lb (24 kg) / 35 lb (16 kg)',
          standards: <String>[
            'Kettlebell bell passes directly over shoulders and heels overhead, bottom of bell inverted upward.',
            'Hips and knees locked out at top.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Pull-up',
          repsOrDistance: '12 Reps',
          standards: <String>['Chin over bar, full arm extension at bottom.'],
        ),
      ],
      pacingStrategy: <String>[
        'Run 1 & 2 at 85% effort so you can pick up the kettlebell immediately without standing over it.',
        'Swings should be unbroken (all 21 in one go).',
      ],
      targetTimes: <String, String>{
        'Elite': 'Sub 8:00',
        'Advanced': '8:00 – 9:59',
        'Intermediate': '10:00 – 12:59',
        'Beginner': '13:00 – 16:00',
      },
      scalingOptions: <String, String>{
        'Rx': '53 lb / 35 lb American Swings, Kipping Pull-ups',
        'Scaled': '35 lb / 26 lb Russian or American Swings, Banded Pull-ups or Ring Rows',
        'Beginner': '200m–300m Run, light KB, Ring Rows',
      },
    ),
  );

  static const WodDefinition dt = WodDefinition(
    id: 'dt',
    name: 'DT',
    subtitle: '5 Rounds of Barbell Grit & Pacing',
    format: WodFormat.forTime,
    category: 'Hero Benchmark',
    targetTimeOrCap: '5 Rounds For Time (Target: 6–10 min)',
    targetCapSeconds: 900,
    hasInteractiveTracker: true,
    equipment: <String>[
      'Olympic Barbell (155 lb men / 105 lb women)',
      'Bumper Plates & Collars',
      'Lifting Platform or Rubber Mat',
    ],
    movementsSummary: <String>[
      '5 Rounds For Time:',
      '12 Deadlifts (155 / 105 lb)',
      '9 Hang Power Cleans (155 / 105 lb)',
      '6 Push Jerks (155 / 105 lb)',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Set up your barbell on a clear 8x8 lifting station with chalk nearby. Ensure collars are locked tight since you will be cycling 135 total barbell reps.',
      equipmentChecklist: <String>[
        'Olympic barbell loaded to 155 lb (70.3 kg) or 105 lb (47.6 kg)',
        'Barbell collars clamped tight',
        'Gymnastics chalk ready for grip preservation',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Deadlift',
          repsOrDistance: '12 Reps',
          rxLoad: '155 lb (70 kg) / 105 lb (48 kg)',
          standards: <String>[
            'Bar begins on floor; athlete stands to full lockout of knees and hips with shoulders behind bar.',
            'Touch-and-go is allowed; no bouncing allowed off the floor.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Hang Power Clean',
          repsOrDistance: '9 Reps',
          rxLoad: '155 lb (70 kg) / 105 lb (48 kg)',
          standards: <String>[
            'Barbell must deadlift to hip before first clean; bar must not pass below the top of the kneecaps.',
            'Catch in partial squat (above parallel) with elbows clearly in front of the bar.',
          ],
        ),
        WodMovementStandard(
          movementName: 'Push Jerk',
          repsOrDistance: '6 Reps',
          rxLoad: '155 lb (70 kg) / 105 lb (48 kg)',
          standards: <String>[
            'Barbell goes from front rack to full lockout overhead.',
            'Athlete must dip, drive, and re-dip under the bar; hips, knees, and elbows fully locked out overhead.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'The 11-1 Deadlift Strategy: Do 11 Deadlifts, rest 5-10s with bar on floor, then lift rep 12 directly into Hang Cleans.',
        'The 8-1 Clean Strategy: Do 8 Hang Cleans, rest with bar on floor, do clean 9 directly into your first Push Jerk.',
        'Push Jerks: Hold on and sprint through all 6 reps unbroken without dropping the bar overhead.',
      ],
      targetTimes: <String, String>{
        'Elite': 'Sub 5:00',
        'Advanced': '5:00 – 7:30',
        'Intermediate': '7:31 – 10:30',
        'Beginner': '10:31 – 15:00',
      },
      scalingOptions: <String, String>{
        'Rx': '155 lb / 105 lb Barbell, all 5 rounds',
        'Scaled': '135 lb / 95 lb or 115 lb / 75 lb Barbell',
        'Beginner': '75 lb / 55 lb or pair of 35/25 lb Dumbbells',
      },
    ),
  );

  static const WodDefinition deathByBurpees = WodDefinition(
    id: 'death_by_burpees',
    name: 'Death By Burpees',
    subtitle: 'Ascending Minute-by-Minute Burpee Ladder',
    format: WodFormat.emom,
    category: 'Benchmark EMOM',
    targetTimeOrCap: 'EMOM Until Failure (Cap: 20–30 min)',
    targetCapSeconds: 1800,
    hasInteractiveTracker: true,
    equipment: <String>[
      'Floor Space (6x6 ft)',
      'Yoga Mat (optional)',
    ],
    movementsSummary: <String>[
      'Min 1: 1 Burpee',
      'Min 2: 2 Burpees',
      'Min 3: 3 Burpees...',
      'Continue until failure to complete within 60s',
    ],
    setupExplainer: WodSetupExplainer(
      floorPlanAdvice:
          'Clear a 6x6 open floor space with non-slip rubber matting. Position yourself facing the timer clock so you can track the 60-second countdown continuously.',
      equipmentChecklist: <String>[
        'Flat, non-slip training floor or exercise mat',
        'Water bottle nearby for post-workout recovery',
      ],
      movementStandards: <WodMovementStandard>[
        WodMovementStandard(
          movementName: 'Chest-to-Floor Burpee',
          repsOrDistance: 'Ascending by 1 each minute',
          standards: <String>[
            'Start in fully standing position.',
            'Drop down until chest and thighs clearly touch the ground.',
            'Jump or step feet back up and finish with small jump overhead with hands clapping behind ears.',
          ],
        ),
      ],
      pacingStrategy: <String>[
        'Minutes 1–8: Smooth, calm, and conversational. Step up or jump up with relaxed breathing; do not sprint early.',
        'Minutes 9–14: Heart rate elevates. Plan to finish reps in the first 25–35 seconds of each minute to secure recovery time.',
        'Minutes 15+: Full sprint. Jump down fast, rebound out of the bottom, and fight for every single rep.',
      ],
      targetTimes: <String, String>{
        'Elite': '19+ Minutes (190+ Burpees)',
        'Advanced': '16–18 Minutes (136–171 Burpees)',
        'Intermediate': '12–15 Minutes (78–120 Burpees)',
        'Beginner': '8–11 Minutes (36–66 Burpees)',
      },
      scalingOptions: <String, String>{
        'Rx': 'Standard Chest-to-Floor Burpees with jump and clap overhead',
        'Scaled': 'No-pushup burpees (down-ups/sprawls) or stepping back and stepping up',
        'Beginner': 'Elevating hands on a 20" or 24" plyo box',
      },
    ),
  );

  /// All seeded benchmarks
  static const List<WodDefinition> allWods = <WodDefinition>[
    cindy,
    jackie,
    fran,
    grace,
    annie,
    murph,
    helen,
    dt,
    deathByBurpees,
  ];

  /// Find WOD by ID
  static WodDefinition? getById(String id) {
    try {
      return allWods.firstWhere((WodDefinition w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Select a random WOD (Shuffle feature)
  static WodDefinition getRandomWod({String? excludeId}) {
    final Random random = Random();
    List<WodDefinition> candidates = allWods;
    if (excludeId != null && candidates.length > 1) {
      candidates = candidates.where((WodDefinition w) => w.id != excludeId).toList();
    }
    return candidates[random.nextInt(candidates.length)];
  }
}
