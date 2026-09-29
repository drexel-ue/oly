import 'package:flutter/material.dart';

enum BodypartCategory {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  quads,
  hamstrings,
  calves,
  abs,
  glutes,
  mobilityArmor,
}

extension BodypartCategoryExtension on BodypartCategory {
  String get displayName {
    switch (this) {
      case BodypartCategory.chest:
        return 'Chest';
      case BodypartCategory.back:
        return 'Back';
      case BodypartCategory.shoulders:
        return 'Shoulders';
      case BodypartCategory.biceps:
        return 'Biceps';
      case BodypartCategory.triceps:
        return 'Triceps';
      case BodypartCategory.quads:
        return 'Quads';
      case BodypartCategory.hamstrings:
        return 'Hamstrings';
      case BodypartCategory.calves:
        return 'Calves';
      case BodypartCategory.abs:
        return 'Abs';
      case BodypartCategory.glutes:
        return 'Glutes (Bonus)';
      case BodypartCategory.mobilityArmor:
        return 'Mobility & Armor';
    }
  }

  IconData get icon {
    switch (this) {
      case BodypartCategory.chest:
        return Icons.fitness_center;
      case BodypartCategory.back:
        return Icons.line_weight;
      case BodypartCategory.shoulders:
        return Icons.shield_outlined;
      case BodypartCategory.biceps:
        return Icons.sports_mma;
      case BodypartCategory.triceps:
        return Icons.pan_tool_alt;
      case BodypartCategory.quads:
        return Icons.directions_walk;
      case BodypartCategory.hamstrings:
        return Icons.run_circle_outlined;
      case BodypartCategory.calves:
        return Icons.hiking;
      case BodypartCategory.abs:
        return Icons.view_compact;
      case BodypartCategory.glutes:
        return Icons.bolt;
      case BodypartCategory.mobilityArmor:
        return Icons.self_improvement;
    }
  }

  Color get color {
    switch (this) {
      case BodypartCategory.chest:
        return const Color(0xFFFF5E00);
      case BodypartCategory.back:
        return const Color(0xFF00D2FF);
      case BodypartCategory.shoulders:
        return const Color(0xFFA855F7);
      case BodypartCategory.biceps:
        return const Color(0xFFFF9F0A);
      case BodypartCategory.triceps:
        return const Color(0xFFE02424);
      case BodypartCategory.quads:
        return const Color(0xFF10B981);
      case BodypartCategory.hamstrings:
        return const Color(0xFF3B82F6);
      case BodypartCategory.calves:
        return const Color(0xFFF59E0B);
      case BodypartCategory.abs:
        return const Color(0xFFEC4899);
      case BodypartCategory.glutes:
        return const Color(0xFF8B5CF6);
      case BodypartCategory.mobilityArmor:
        return const Color(0xFF06B6D4);
    }
  }
}

class BodybuildingExercise {
  const new({
    required this.id,
    required this.name,
    required this.bodypart,
    required this.role,
    required this.targetMuscles,
    required this.setsReps,
    required this.whyItWorks,
    required this.cues,
    this.videoUrl = 'https://www.youtube.com/watch?v=eYdaAb77oSI',
    this.isBonus = false,
  });

  final String id;
  final String name;
  final BodypartCategory bodypart;
  final String role;
  final String targetMuscles;
  final String setsReps;
  final String whyItWorks;
  final List<String> cues;
  final String videoUrl;
  final bool isBonus;

  static List<BodybuildingExercise> get19Exercises() {
    return const <BodybuildingExercise>[
      // --- CHEST (3) ---
      BodybuildingExercise(
        id: 'bb_bench_press',
        name: 'Barbell Flat Bench Press',
        bodypart: BodypartCategory.chest,
        role: 'Horizontal Press',
        targetMuscles: 'Sternal Pectoralis, Anterior Deltoids, Triceps',
        setsReps: '4 Sets of 8-10 Reps',
        whyItWorks:
            'The foundational upper body push. Overloads mid and lower pec fibers under massive mechanical tension.',
        cues: <String>[
          'Plant feet flat into the ground and arch thoracic spine slightly',
          'Retract and depress scapulae tight into the bench pad',
          'Lower bar with control (2-3s) to lower sternum',
          'Drive bar up explosively without flaring elbows past 75°',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_incline_press',
        name: 'Incline Dumbbell Bench Press',
        bodypart: BodypartCategory.chest,
        role: 'Incline Press',
        targetMuscles: 'Clavicular Pectoralis (Upper Chest), Anterior Deltoid',
        setsReps: '3-4 Sets of 10-12 Reps',
        whyItWorks:
            'A 30° to 45° incline angles the line of force to the clavicular fibers for upper chest thickness without shoulder impingement.',
        cues: <String>[
          'Set incline bench between 30° and 45°',
          'Angle dumbbells semi-neutral (~45°) to preserve shoulder capsule',
          'Lower dumbbells to collarbone level with deep pec stretch',
          'Converge dumbbells at top without clanking bells together',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_cable_fly',
        name: 'Cable Chest Fly / Pec Deck',
        bodypart: BodypartCategory.chest,
        role: 'Chest Isolation (Fly)',
        targetMuscles: 'Pectoralis Major (Horizontal Adduction & Squeeze)',
        setsReps: '3 Sets of 12-15 Reps',
        whyItWorks:
            'Free weights lose tension at peak contraction. Cables or pec deck machine maintain continuous tension across full horizontal adduction.',
        cues: <String>[
          'Maintain a soft, locked bend at the elbows throughout',
          'Envision hugging a massive tree or barrel as you fly inward',
          'Hold full peak contraction for 1 second at center',
          'Resist the eccentric back into a comfortable outer stretch',
        ],
      ),

      // --- BACK (3) ---
      BodybuildingExercise(
        id: 'bb_lat_pulldown',
        name: 'Wide-Grip Lat Pulldown / Pull-ups',
        bodypart: BodypartCategory.back,
        role: 'Vertical Pull',
        targetMuscles: 'Latissimus Dorsi (Width & Flare), Teres Major, Biceps',
        setsReps: '4 Sets of 8-10 Reps',
        whyItWorks:
            'Vertical pulling drives coronal plane humeral adduction, creating the iconic wide V-taper lat flare.',
        cues: <String>[
          'Depress and pack shoulder blades before initiating elbow pull',
          'Drive elbows straight down towards your back hip pockets',
          'Pull upper chest toward the bar; avoid excessive backward lean',
          'Control the ascent for full lat stretch at top extension',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_chest_supported_row',
        name: 'Chest-Supported Row / Barbell Row',
        bodypart: BodypartCategory.back,
        role: 'Horizontal Pull',
        targetMuscles: 'Latissimus Dorsi, Rhomboids, Mid/Lower Trapezius',
        setsReps: '4 Sets of 10-12 Reps',
        whyItWorks:
            'Horizontal rowing builds back thickness and scapular armor. Chest-support eliminates lower back fatigue.',
        cues: <String>[
          'Anchor chest against support pad with neutral cervical spine',
          'Pull elbows backward past torso plane with violent retraction',
          'Pinch shoulder blades together tightly at apex',
          'Let scapulae protract smoothly around ribs on stretch',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_dumbbell_pullover',
        name: 'Dumbbell Pullover',
        bodypart: BodypartCategory.back,
        role: 'Vertical Lat Stretch & Serratus',
        targetMuscles: 'Latissimus Dorsi, Teres Major, Serratus Anterior',
        setsReps: '3 Sets of 12-15 Reps',
        whyItWorks:
            'Loaded shoulder extension through deep flexion that stimulates long muscle fiber hypertrophy and ribcage expansion.',
        cues: <String>[
          'Lay perpendicular across bench with shoulders firmly supported',
          'Cup inner plate of dumbbell with diamond hand position',
          'Lower bell behind head in an arc while keeping hips dipped',
          'Pull exclusively through lats back to forehead plane only',
        ],
      ),

      // --- SHOULDERS (3) ---
      BodybuildingExercise(
        id: 'bb_overhead_press',
        name: 'Overhead Shoulder Press (Barbell / DB)',
        bodypart: BodypartCategory.shoulders,
        role: 'Compound Press',
        targetMuscles: 'Anterior Deltoids, Lateral Deltoids, Triceps',
        setsReps: '3-4 Sets of 8-10 Reps',
        whyItWorks:
            'Heavy vertical compound pushing builds overall shoulder density and clavicular stability.',
        cues: <String>[
          'Grip just outside shoulder width with forearms vertically stacked',
          'Brace glutes and abs hard to prevent lower back sway',
          'Clear head backward as bar passes nose, then tuck head forward',
          'Lock out directly overhead with active upper trapezius',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_lateral_raises',
        name: 'Dumbbell / Cable Lateral Raises',
        bodypart: BodypartCategory.shoulders,
        role: 'Lateral Delts Isolation',
        targetMuscles: 'Lateral (Medial) Deltoid Head',
        setsReps: '4-5 Sets of 12-15 Reps',
        whyItWorks:
            'Direct isolation for the lateral deltoid head. Crucial for building capped 3D shoulders and upper frame width.',
        cues: <String>[
          'Tilt torso slightly forward (10-15°) in the scapular plane',
          'Lead with elbows; pinkies slightly higher than thumbs',
          'Raise strictly to shoulder height without swinging hips',
          'Control the 2-second negative to milk tension in stretch',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_rear_delt_fly',
        name: 'Reverse Pec Deck / Cable Face Pulls',
        bodypart: BodypartCategory.shoulders,
        role: 'Rear Delts Isolation',
        targetMuscles: 'Posterior Deltoids, Infraspinatus, Teres Minor',
        setsReps: '4 Sets of 15 Reps',
        whyItWorks:
            'Rear delts balance anterior pushing volume, preventing shoulder internal rotation and building 3D capped boulders.',
        cues: <String>[
          'Maintain a soft elbow bend; do not use triceps to push',
          'Drive elbows and back of hands out and back horizontally',
          'Focus purely on the back of the shoulder doing the pull',
          'Hold peak abduction for 1 full second',
        ],
      ),

      // --- BICEPS (2) ---
      BodybuildingExercise(
        id: 'bb_barbell_curl',
        name: 'Standing Barbell Bicep Curl',
        bodypart: BodypartCategory.biceps,
        role: 'Main Bicep Curl',
        targetMuscles: 'Biceps Brachii (Long & Short Heads)',
        setsReps: '3-4 Sets of 10-12 Reps',
        whyItWorks:
            'Fully supinated grip loads both heads of the biceps with heavy progressive overload through full elbow flexion.',
        cues: <String>[
          'Pin elbows against sides and do not let them flare forward',
          'Keep wrists supinated flat throughout the entire range',
          'Squeeze biceps hard at top without shifting torso',
          'Lower under strict control through eccentric phase',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_hammer_curl',
        name: 'Neutral-Grip Dumbbell Hammer Curl',
        bodypart: BodypartCategory.biceps,
        role: 'Brachialis & Forearm Armor',
        targetMuscles: 'Brachialis, Brachioradialis',
        setsReps: '3-4 Sets of 12 Reps',
        whyItWorks:
            'Neutral grip shifts primary torque to the brachialis, pushing the bicep belly outward for thicker, wider arm appearance.',
        cues: <String>[
          'Maintain neutral thumb-up grip for the entire set',
          'Curl dumbbell toward collarbone without rotational torque',
          'Keep upper arm fixed against ribcage',
          'Controlled descent protects distal biceps tendon',
        ],
      ),

      // --- TRICEPS (2) ---
      BodybuildingExercise(
        id: 'bb_tricep_pushdown',
        name: 'Cable Triceps Pushdown',
        bodypart: BodypartCategory.triceps,
        role: 'Lateral & Medial Head Isolation',
        targetMuscles: 'Lateral Head & Medial Head of Triceps',
        setsReps: '4 Sets of 12-15 Reps',
        whyItWorks:
            'Shoulders in extension isolate the lateral head, creating the prominent horseshoe curve on the outer upper arm.',
        cues: <String>[
          'Lock elbows firmly at ribs; lean torso slightly forward',
          'Push bar or rope down until elbows achieve complete lockout',
          'Flare rope handles outward at bottom for extra peak contraction',
          'Do not allow elbows to travel forward on the way up',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_overhead_tricep_ext',
        name: 'Overhead Cable Triceps Extension',
        bodypart: BodypartCategory.triceps,
        role: 'Long Head Triceps Stretch',
        targetMuscles: 'Long Head of Triceps',
        setsReps: '4 Sets of 12-15 Reps',
        whyItWorks:
            'The long head crosses the shoulder joint and only reaches full stretch when the shoulder is elevated overhead. Key for total arm mass.',
        cues: <String>[
          'Anchor cable at waist height or use incline bench',
          'Keep upper arms angled overhead alongside ears',
          'Allow elbows to bend fully behind head for deep stretch',
          'Extend forward to lockout while keeping elbows tucked inward',
        ],
      ),

      BodybuildingExercise(
        id: 'bb_squat',
        name: 'Barbell Front Squat / Olympic Squat',
        bodypart: BodypartCategory.quads,
        role: 'Compound Front Squat',
        targetMuscles:
            'Vastus Lateralis, Vastus Medialis (VMO), Rectus Abdominis, Glutes',
        setsReps: '4 Sets of 8-10 Reps',
        whyItWorks:
            'The anterior barbell rack forces an upright torso, shifting maximum mechanical tension onto the quads while requiring immense thoracic extension and anterior core bracing with minimal lumbar shear.',
        cues: <String>[
          'Clean grip with fingertips or cross-arm rack with high elbows parallel to floor',
          'Brace anterior core tight; keep chest proud and tall throughout the rep',
          'Descend deep between hips, driving knees forward over toes',
          'Drive straight up out of the hole, keeping elbows elevated to prevent forward dump',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_leg_extension',
        name: 'Seated Leg Extension',
        bodypart: BodypartCategory.quads,
        role: 'Quad Isolation (Rectus Femoris)',
        targetMuscles: 'Rectus Femoris, Vastus Medialis (VMO)',
        setsReps: '3-4 Sets of 15 Reps',
        whyItWorks:
            'Squats do not fully challenge rectus femoris at terminal knee extension. Leg extensions deliver peak shortening contraction and patellar blood flow.',
        cues: <String>[
          'Align machine pivot directly with lateral knee joint',
          'Point toes slightly up toward shins (dorsiflexed)',
          'Extend legs fully and pause at top lockout for 1 second',
          'Lower smoothly over 3 seconds under strict tension',
        ],
      ),

      // --- HAMSTRINGS (2) ---
      BodybuildingExercise(
        id: 'bb_romanian_deadlift',
        name: 'Romanian Deadlift (RDL)',
        bodypart: BodypartCategory.hamstrings,
        role: 'Compound Hip Hinge',
        targetMuscles: 'Hamstrings (Lengthened State), Gluteus Maximus, Erectors',
        setsReps: '4 Sets of 8-10 Reps',
        whyItWorks:
            'Hamstrings thrive on stretch-mediated hypertrophy. The RDL trains hamstrings under intense loaded elongation at hip flexion.',
        cues: <String>[
          'Soft bend in knees; fix knee angle in place',
          'Push hips straight backward toward wall behind you',
          'Keep bar or dumbbells glued against thighs and shins',
          'Reverse direction as soon as hips stop moving backward; squeeze glutes',
        ],
      ),
      BodybuildingExercise(
        id: 'bb_hamstring_curl',
        name: 'Lying or Seated Hamstring Leg Curl',
        bodypart: BodypartCategory.hamstrings,
        role: 'Hamstring Isolation (Knee Flexion)',
        targetMuscles: 'Biceps Femoris, Semitendinosus, Semimembranosus',
        setsReps: '3-4 Sets of 12-15 Reps',
        whyItWorks:
            'Hamstrings act as both hip extensors and knee flexors. Knee flexion curls are mandatory for full muscle belly development.',
        cues: <String>[
          'Lock thighs and hips tight into the machine pad',
          'Pull heels rapidly toward glutes in an explosive arc',
          'Squeeze hard at full flexion without hips lifting off pad',
          'Resist the eccentric cadence for 3 full seconds',
        ],
      ),

      // --- CALVES (1) ---
      BodybuildingExercise(
        id: 'bb_calf_raise',
        name: 'Standing Calf Raise',
        bodypart: BodypartCategory.calves,
        role: 'Calf Plantarflexion',
        targetMuscles: 'Gastrocnemius, Soleus, Achilles Tendon',
        setsReps: '4 Sets of 15-20 Reps',
        whyItWorks:
            'Standing knee lockout stretches both heads of the gastrocnemius under deep ankle dorsiflexion, triggering robust lower leg hypertrophy.',
        cues: <String>[
          'Keep knees straight with locked quad tension (not hyper-extended)',
          'Lower heels deeply into full stretch and pause for 2 seconds',
          'Explode onto balls of big toes and pause for 2 seconds at peak',
          'Eliminate bouncing to remove Achilles tendon elastic assist',
        ],
      ),

      // --- ABS (1) ---
      BodybuildingExercise(
        id: 'bb_cable_crunch',
        name: 'Kneeling Rope Cable Crunch',
        bodypart: BodypartCategory.abs,
        role: 'Loaded Abdominal Flexion',
        targetMuscles: 'Rectus Abdominis (Six-Pack Core)',
        setsReps: '4 Sets of 15-20 Reps',
        whyItWorks:
            'Abs require progressive overload with spinal flexion resistance to build thick, deep muscle ridges rather than just endurance sit-ups.',
        cues: <String>[
          'Kneel and position rope handles by ears or collarbones',
          'Lock hips in space; do NOT sit backward on your heels',
          'Curl torso down by rolling ribcage into pelvis like a scroll',
          'Exhale all air at bottom crunch and hold for 1 second',
        ],
      ),

      // --- BONUS: GLUTES (1) ---
      BodybuildingExercise(
        id: 'bb_hip_thrust',
        name: 'Barbell Hip Thrust',
        bodypart: BodypartCategory.glutes,
        role: 'Glute Hip Extension (Bonus)',
        targetMuscles: 'Gluteus Maximus',
        setsReps: '3-4 Sets of 10-12 Reps',
        whyItWorks:
            'Trainer Winny highlights hip extension movements for sports performance, athletic power, and glute hypertrophy.',
        cues: <String>[
          'Rest upper back across bench; place barbell across hip crease with pad',
          'Keep chin tucked looking forward throughout',
          'Drive through heels to full horizontal hip lockout',
          'Hold intense glute squeeze at top for 2 full seconds',
        ],
        isBonus: true,
      ),

      // --- MOBILITY & ARMOR (4 Movements) ---
      BodybuildingExercise(
        id: 'bb_barbell_wrist_curls',
        name: 'Barbell Wrist Curls (Flexion & Extension)',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Forearm Flexor & Tendon Armor',
        targetMuscles: 'Flexor Carpi Radialis, Extensors, Medial Epicondyle',
        setsReps: '3 Sets of 15 Reps',
        whyItWorks:
            "Direct forearm flexor overload strengthens the tendons of the elbow joint and resolves medial epicondylitis (golfer's elbow) from heavy curls and presses.",
        cues: <String>[
          'Rest forearms flat across flat bench with wrists hanging off edge',
          'Let barbell roll down to fingertips for full flexor stretch',
          'Curl wrists upward forcefully and pause for 1 second at peak contraction',
          'Perform reverse extension curls with overhand grip to balance forearm extensors',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_banded_hip_rotations',
        name: 'Banded Internal Hip Rotations',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Hip Capsule Mobility Primer',
        targetMuscles: 'Tensor Fasciae Latae, Gluteus Medius, Internal Rotators',
        setsReps: '2 Sets of 15 Reps per side',
        whyItWorks:
            'Primes deep hip internal rotation and femoral head centering before heavy squats, preventing hip pinch, impingement, and knee valgus.',
        cues: <String>[
          'Anchor light resistance band to rig at knee height',
          'Stand sideways to rig with band looped around inside thigh or knee',
          'Rotate femur internally against elastic tension with steady pelvis',
          'Hold 2-second isometric contraction at end-range internal rotation',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_elephant_walks',
        name: 'Elephant Walks',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Posterior Chain & Hamstring Flossing',
        targetMuscles: 'Hamstrings, Gastrocnemius, Lumbar Fascia, Sciatic Nerve',
        setsReps: '2 Sets of 30 Alternating Reps',
        whyItWorks:
            'Dynamically flossing the hamstrings and calves decompresses the lumbar spine and restores ankle dorsiflexion after heavy squats and C25K running.',
        cues: <String>[
          'Place hands flat on floor or elevated yoga block with soft knees',
          'Keep one leg bent while driving the other heel down into complete knee lockout',
          'Alternate smoothly from side to side in a rhythmic flossing cadence',
          'Breathe deeply into belly to signal hamstring relaxation',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_jefferson_curls',
        name: 'Jefferson Curls',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Loaded Spinal Flexion & Posterior Resilience',
        targetMuscles: 'Erector Spinae, Multifidus, Hamstrings, Posterior Ligaments',
        setsReps: '3 Sets of 8 Reps',
        whyItWorks:
            'Light progressive spinal flexion builds bulletproof tensile strength in spinal discs and ligaments, protecting against lumbar injury during heavy RDLs and squats.',
        cues: <String>[
          'Stand elevated on bench or sturdy block holding light barbell with arms relaxed',
          'Tuck chin tightly to chest and round upper, middle, and lower spine vertebra by vertebra',
          'Reach barbell past toes into deepest comfortable hang without bending knees',
          'Slowly reverse movement by unrolling spine from lumbar to cervical to tall lockout',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_couch_stretch',
        name: 'Couch Stretch (Quad & Hip Flexor)',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Anterior Hip & Rectus Femoris Lengthening',
        targetMuscles: 'Rectus Femoris, Psoas Major, Iliacus, Patellar Tendon',
        setsReps: '2 Sets of 60-90s per side',
        whyItWorks:
            'Heavy squats, leg extensions, and C25K running drastically shorten the rectus femoris and psoas. The couch stretch restores true hip extension and relieves patellar tendon strain.',
        cues: <String>[
          'Place rear shin flush against wall or box with knee on cushioned pad',
          'Step front foot forward into 90-degree lunge stance',
          'Squeeze rear glute hard to posteriorly tilt pelvis before lifting torso upright',
          'Breathe deeply into the front-hip and quad stretch; keep ribs down and core engaged',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_landmine_rotations',
        name: 'Landmine Rotations (Rainbows)',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Rotational Power & Transverse Deceleration',
        targetMuscles: 'Internal Obliques, External Obliques, Transverse Abdominis, Hips',
        setsReps: '3 Sets of 10-12 Reps per side',
        whyItWorks:
            'Transfers dynamic rotational torque from the pivoting rear hip through the obliques into the barbell, while building elite eccentric rotary braking strength to protect the lower back during athletics and running.',
        cues: <String>[
          'Anchor barbell in landmine or corner, clasping end of collar with interlaced grip',
          'Extend arms overhead with soft elbows and athletic shoulder-width stance',
          'Arc barbell down toward outside hip while pivoting rear foot and engaging core',
          'Brake barbell deceleration with obliques before hip level, then explosively drive back up to center',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_pallof_press',
        name: 'Standing Cable Pallof Press',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Anti-Rotation Core & Pelvic Anti-Shift',
        targetMuscles: 'Transverse Abdominis, Internal & External Obliques, Quadratus Lumborum',
        setsReps: '3 Sets of 10-12 Reps (2s Lockout Hold) per side',
        whyItWorks:
            'Prevents rotational shear and lateral hip shifting during heavy squats and deadlifts. Builds a rigid transverse cylinder that stabilizes the pelvis under asymmetric ground strikes in C25K running.',
        cues: <String>[
          'Stand athletic and perpendicular to cable pulley set at chest height holding D-handle at sternum',
          'Drop hips, screw feet into floor, and brace abdominal wall tight',
          'Press handle straight out in front of chest without letting torso rotate toward stack',
          'Lock out arms and hold for 2 full seconds against rotational pull before returning slowly',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_ab_wheel_rollout',
        name: 'Ab Wheel Rollouts',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Anti-Extension Core & Anterior Wall Stiffness',
        targetMuscles: 'Rectus Abdominis, Transverse Abdominis, Serratus Anterior, Lats',
        setsReps: '3 Sets of 8-10 Controlled Reps',
        whyItWorks:
            'The premier exercise to prevent lumbar hyperextension under overhead pressing and heavy spinal loads. Enforces ribcage-to-pelvis lock, eliminating swayback posture and protecting the spine during high-impact running.',
        cues: <String>[
          'Kneel on padded mat with knees hip-width apart and hands on ab wheel handles',
          'Tuck pelvis into posterior tilt, squeeze glutes, and round upper back slightly into hollow body',
          'Roll wheel forward slowly as far as possible without letting lumbar spine arch or sag',
          'Pull through lats and contract abs to pull wheel back to starting position',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_bulgarian_split_squat',
        name: 'Bulgarian Split Squats (Rear-Foot Elevated)',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Unilateral Knee Extension & Pelvic Stability',
        targetMuscles: 'Quadriceps, Gluteus Maximus, Gluteus Medius, Adductors',
        setsReps: '3 Sets of 8-10 Reps per leg',
        whyItWorks:
            'Unilateral knee flexion creates massive quadriceps and glute hypertrophy while training the gluteus medius and adductors to eliminate pelvic drop during running gait.',
        cues: <String>[
          'Elevate rear foot on bench or low box with laces down',
          'Step front foot forward into comfortable lunge distance',
          'Descend under control until front thigh is parallel to floor',
          'Drive through front mid-foot and heel to return to tall lockout without hyperextending knee',
        ],
        isBonus: true,
      ),

      BodybuildingExercise(
        id: 'bb_single_leg_rdl',
        name: 'Free Single-Leg Romanian Deadlift',
        bodypart: BodypartCategory.mobilityArmor,
        role: 'Unilateral Hip Hinge, Hamstring Length & Ankle Proprioception',
        targetMuscles: 'Hamstrings, Gluteus Maximus, Gluteus Medius, Foot & Ankle Stabilizers',
        setsReps: '3 Sets of 8-10 Reps per leg',
        whyItWorks:
            'Suspends the rear leg in free air to challenge the foot arch, ankle evertors, and hip stabilizers, while delivering deep eccentric hamstring loading to bulletproof the posterior chain against sprinting and running strain.',
        cues: <String>[
          'Stand on one leg with soft knee, holding dumbbells at sides or in opposite hand',
          'Hinge at the hip, extending non-working leg straight behind like a pendulum',
          'Keep hips and shoulders square to floor, resisting rotation toward the open side',
          'Descend until deep stretch in front hamstring, then drive front hip forward to tall stance',
        ],
        isBonus: true,
      ),
    ];
  }
}
