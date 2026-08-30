import 'package:oly/models/exercise_database_model.dart';

enum MobilityFocusArea {
  thoracicSpine,
  shoulderOverhead,
  hipCapsule,
  ankleDorsiflexion,
  posteriorChain,
  quadriceps,
  cardio,
  arms,
  absCore,
  gripStrength,
  barbellSnatch,
  barbellCleanJerk,
  barbellSquat,
}

enum MobilityCategory {
  mobilityDrill,
  liftingAccessory,
  cardioConditioning,
  hypertrophyCore,
  foamRolling,
  barbellPrep,
}

class MobilityExerciseModel {
  MobilityExerciseModel({
    required this.id,
    required this.name,
    required this.focusArea,
    required this.category,
    required this.description,
    required this.cues,
    required this.videoUrl,
    this.durationSeconds = 60,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.isYoutube = true,
    this.thumbnailUrl,
  });

  factory MobilityExerciseModel.fromDatabaseModel(ExerciseDatabaseModel dbModel) {
    MobilityFocusArea focus = MobilityFocusArea.hipCapsule;
    final String muscle = dbModel.targetMuscle.toLowerCase();
    final String bodyPart = dbModel.bodyPart.toLowerCase();

    if (muscle.contains('abs') ||
        muscle.contains('oblique') ||
        bodyPart.contains('core') ||
        bodyPart.contains('waist')) {
      focus = MobilityFocusArea.absCore;
    } else if (muscle.contains('bicep') ||
        muscle.contains('tricep') ||
        muscle.contains('forearm') ||
        bodyPart.contains('arm')) {
      focus = MobilityFocusArea.arms;
    } else if (muscle.contains('deltoid') || bodyPart.contains('shoulder')) {
      focus = MobilityFocusArea.shoulderOverhead;
    } else if (muscle.contains('quad')) {
      focus = MobilityFocusArea.quadriceps;
    } else if (muscle.contains('hamstring') ||
        muscle.contains('glute') ||
        muscle.contains('back') ||
        muscle.contains('lat') ||
        muscle.contains('trap')) {
      focus = MobilityFocusArea.posteriorChain;
    } else if (muscle.contains('calv') || muscle.contains('ankle')) {
      focus = MobilityFocusArea.ankleDorsiflexion;
    } else if (dbModel.category == 'cardio' || bodyPart.contains('cardio')) {
      focus = MobilityFocusArea.cardio;
    } else if (dbModel.category == 'olympic_weightlifting') {
      if (dbModel.name.toLowerCase().contains('snatch')) {
        focus = MobilityFocusArea.barbellSnatch;
      } else if (dbModel.name.toLowerCase().contains('squat')) {
        focus = MobilityFocusArea.barbellSquat;
      } else {
        focus = MobilityFocusArea.barbellCleanJerk;
      }
    }

    List<String> cues = <String>[];
    if (dbModel.instructions != null && dbModel.instructions!.isNotEmpty) {
      cues = dbModel.instructions!
          .split('\n')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    if (dbModel.tips != null && dbModel.tips!.isNotEmpty) {
      cues.add('Coach Tip: ${dbModel.tips!}');
    }

    final String videoUrl = dbModel.videoUrl != null && dbModel.videoUrl!.isNotEmpty
        ? dbModel.videoUrl!
        : 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${dbModel.name} Exercise Form Tutorial')}';

    return MobilityExerciseModel(
      id: dbModel.id,
      name: dbModel.name,
      focusArea: focus,
      category: dbModel.category == 'mobility'
          ? MobilityCategory.mobilityDrill
          : (dbModel.category == 'cardio'
              ? MobilityCategory.cardioConditioning
              : (focus == MobilityFocusArea.arms || focus == MobilityFocusArea.absCore
                  ? MobilityCategory.hypertrophyCore
                  : MobilityCategory.liftingAccessory)),
      description: dbModel.instructions != null && dbModel.instructions!.isNotEmpty
          ? dbModel.instructions!.split('\n').first
          : '${dbModel.name} (${dbModel.displayEquipment}, targeting ${dbModel.displayTargetMuscle})',
      cues: cues.isNotEmpty ? cues : <String>['Perform with controlled tempo and strict form.'],
      videoUrl: videoUrl,
      isYoutube: true,
      thumbnailUrl: dbModel.gifUrl,
    );
  }

  factory MobilityExerciseModel.fromJson(Map<String, dynamic> json) {
    return MobilityExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      focusArea: MobilityFocusArea.values.firstWhere(
        (MobilityFocusArea e) => e.name == json['focusArea'],
        orElse: () => MobilityFocusArea.hipCapsule,
      ),
      category: MobilityCategory.values.firstWhere(
        (MobilityCategory e) => e.name == json['category'],
        orElse: () => MobilityCategory.mobilityDrill,
      ),
      description: json['description'] as String,
      cues:
          (json['cues'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
      durationSeconds: json['durationSeconds'] as int? ?? 60,
      defaultSets: json['defaultSets'] as int? ?? 3,
      defaultReps: json['defaultReps'] as int? ?? 10,
      videoUrl: json['videoUrl'] as String? ?? '',
      isYoutube: json['isYoutube'] as bool? ?? true,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
  final String id;
  final String name;
  final MobilityFocusArea focusArea;
  final MobilityCategory category;
  final String description;
  final List<String> cues;
  final int durationSeconds;
  final int defaultSets;
  final int defaultReps;
  final String videoUrl;
  final bool isYoutube;
  final String? thumbnailUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'focusArea': focusArea.name,
      'category': category.name,
      'description': description,
      'cues': cues,
      'durationSeconds': durationSeconds,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'videoUrl': videoUrl,
      'isYoutube': isYoutube,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  static String _youtubeSearchUrl(String query) {
    return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$query Catalyst Athletics weightlifting tutorial')}';
  }

  static List<MobilityExerciseModel> defaultExercises() {
    return <MobilityExerciseModel>[
      // RECOVERY CONDITIONING & LOADED CARRIES
      MobilityExerciseModel(
        id: 'kettlebell_mile',
        name: 'Kettlebell Mile (Loaded Carry)',
        focusArea: MobilityFocusArea.cardio,
        category: MobilityCategory.cardioConditioning,
        description: 'Loaded carry aerobic flush. Start at 10% bodyweight, tracking speed, incline, and time. Progress to 30% BW when finished in <20 mins.',
        cues: <String>[
          'Maintain upright torso and engaged core while walking with kettlebells.',
          'Record speed, treadmill incline %, and total time taken for the 1.0 mile.',
          'Target completing the mile in under 20:00 to unlock next weight progression milestone.',
        ],
        durationSeconds: 1200,
        defaultSets: 1,
        defaultReps: 1,
        videoUrl: _youtubeSearchUrl('Kettlebell Mile Loaded Carry'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'zone2_cardio_row',
        name: 'Ergometer Row / Bike (Cardio Opener)',
        focusArea: MobilityFocusArea.cardio,
        category: MobilityCategory.cardioConditioning,
        description: 'Increases core body temperature and heart rate to prime muscles for heavy loading.',
        cues: <String>[
          'Row or bike at an easy, conversational pace (3-5 minutes).',
          'Focus on driving through the heels and relaxing upper body.',
          'Gradually increase stroke rate during the final minute.',
        ],
        durationSeconds: 180,
        videoUrl: _youtubeSearchUrl('Concept2 Ergometer Rowing Technique'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'farmers_walk_mile',
        name: "Farmer's Walk Mile (Swap Alternative)",
        focusArea: MobilityFocusArea.cardio,
        category: MobilityCategory.cardioConditioning,
        description: 'Alternative loaded carry conditioning mile using dual dumbbells or kettlebells.',
        cues: <String>[
          'Carry weights with shoulders pinned down and back.',
          'Keep a steady cadence and avoid swinging weights.',
        ],
        durationSeconds: 1200,
        defaultSets: 1,
        defaultReps: 1,
        videoUrl: _youtubeSearchUrl('Farmers Walk Mile'),
        isYoutube: true,
      ),

      // FOAM ROLLING
      MobilityExerciseModel(
        id: 'thoracic_foam_roll',
        name: 'Thoracic Extension Foam Roll',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.foamRolling,
        description: 'Mobilizes upper back extension necessary for upright catch positions in snatch & front squat.',
        cues: <String>[
          'Support your head with your hands, elbows pointed forward.',
          'Gently arch over the roller without letting your ribs flare.',
          'Pause and take 3 deep breaths at each stiff segment.',
        ],
        durationSeconds: 90,
        videoUrl: _youtubeSearchUrl('Thoracic Spine Extension Foam Roller'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'quads_lats_foam_roll',
        name: 'Quads & Lats Foam Roll',
        focusArea: MobilityFocusArea.quadriceps,
        category: MobilityCategory.foamRolling,
        description: 'Releases quad and upper lat stiffness before squatting and turnover pulls.',
        cues: <String>[
          'Roll 8-10 slow passes along the front of quads and side of lats.',
          'Pause on tender spots for 5-10 seconds to allow tissue release.',
        ],
        durationSeconds: 90,
        videoUrl: _youtubeSearchUrl('Foam Rolling Quads and Lats'),
        isYoutube: true,
      ),

      // JOINT MOBILIZATION & DROMS
      MobilityExerciseModel(
        id: 'hip_90_90_switches',
        name: '90/90 Hip Mobility Switches',
        focusArea: MobilityFocusArea.hipCapsule,
        category: MobilityCategory.mobilityDrill,
        description: 'Mobilizes internal and external hip rotation for deep squat receiving positions.',
        cues: <String>[
          'Sit on floor with knees bent at 90-degree angles.',
          'Rotate hips to transition from left side to right side smoothly.',
          'Keep chest tall and avoid leaning far back.',
        ],
        durationSeconds: 90,
        videoUrl: _youtubeSearchUrl('90 90 Hip Mobility Switches'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'banded_ankle_distraction',
        name: 'Banded Ankle Dorsiflexion Mobilization',
        focusArea: MobilityFocusArea.ankleDorsiflexion,
        category: MobilityCategory.mobilityDrill,
        description: 'Clears anterior ankle joint pinching to allow deeper, upright squat positioning.',
        cues: <String>[
          'Attach heavy resistance band low on rig and loop around ankle talus bone.',
          'Step forward into tension and drive knee over pinky toe.',
          'Oscillate gently forward and backward for 60 seconds per ankle.',
        ],
        durationSeconds: 90,
        videoUrl: _youtubeSearchUrl('Banded Ankle Dorsiflexion Mobilization'),
        isYoutube: true,
      ),

      // BARBELL PREP: SNATCH SPECIFIC
      MobilityExerciseModel(
        id: 'burgener_snatch_warmup',
        name: 'Burgener Empty Barbell Snatch Warm-Up',
        focusArea: MobilityFocusArea.barbellSnatch,
        category: MobilityCategory.barbellPrep,
        description: 'The standard Olympic lifting warmup complex for snatch trajectory, speed, and extension.',
        cues: <String>[
          'Perform 5 reps of: Dip & Drive (Down & Up).',
          '5 reps of: Dip-Drive & Elbows High and Outside.',
          '5 reps of: Muscle Snatch.',
          '5 reps of: Snatch Lands (Footwork) & Snatch Drops.',
        ],
        defaultSets: 1,
        defaultReps: 5,
        videoUrl: _youtubeSearchUrl('Burgener Snatch Warm Up'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'sotts_press',
        name: 'Press in Snatch Bottom (Sotts Press)',
        focusArea: MobilityFocusArea.barbellSnatch,
        category: MobilityCategory.barbellPrep,
        description: 'Builds extreme overhead stability and hip/ankle flexibility in the bottom of the snatch.',
        cues: <String>[
          'Sit in deep snatch squat with empty barbell or PVC pipe.',
          'Press bar straight up overhead without standing up.',
          'Lock elbows firmly and hold top position for 2 seconds.',
        ],
        defaultSets: 2,
        defaultReps: 5,
        videoUrl: _youtubeSearchUrl('Press in Snatch Bottom Sotts Press'),
        isYoutube: true,
      ),

      // BARBELL PREP: CLEAN & JERK SPECIFIC
      MobilityExerciseModel(
        id: 'clean_jerk_bar_prep',
        name: 'Empty Barbell Clean & Jerk Prep Complex',
        focusArea: MobilityFocusArea.barbellCleanJerk,
        category: MobilityCategory.barbellPrep,
        description: 'Preps front rack delivery, dip-and-drive verticality, and jerk split receiver.',
        cues: <String>[
          'Perform 5 reps of: Empty Bar Front Squats.',
          '5 reps of: Tall Cleans (High Pull + Quick Drop under).',
          '5 reps of: Push Press.',
          '5 reps of: Split Jerk footwork drops.',
        ],
        defaultSets: 1,
        defaultReps: 5,
        videoUrl: _youtubeSearchUrl('Clean and Jerk Warmup Complex'),
        isYoutube: true,
      ),

      // BARBELL PREP: SQUAT SPECIFIC
      MobilityExerciseModel(
        id: 'squat_bar_prep',
        name: 'Empty Barbell Paused Squat Prep',
        focusArea: MobilityFocusArea.barbellSquat,
        category: MobilityCategory.barbellPrep,
        description: 'Primes deep squat positioning, adductors, and core bracing under barbell load.',
        cues: <String>[
          'Perform 5 empty bar Front or Back Squats with a 3-second pause in the hole.',
          'Focus on driving knees out and keeping chest upright.',
          'Perform 5 explosive squat jumps with empty bar.',
        ],
        defaultSets: 2,
        defaultReps: 5,
        videoUrl: _youtubeSearchUrl('Paused Squat Warmup'),
        isYoutube: true,
      ),

      // ACCESSORIES & HYPERTROPHY
      MobilityExerciseModel(
        id: 'lu_raises',
        name: 'Lu Raises (Lateral Full Range)',
        focusArea: MobilityFocusArea.shoulderOverhead,
        category: MobilityCategory.liftingAccessory,
        description: 'Popularized by Lu Xiaojun; strengthens deltoids and upper traps across full overhead extension.',
        cues: <String>[
          'Use 1.25kg - 2.5kg micro plates or light dumbbells.',
          'Raise arms outward and overhead until plates touch at top.',
          'Lower smoothly under control for a 3-second eccentric.',
        ],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: _youtubeSearchUrl('Lu Raises Lu Xiaojun'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'cossack_squat',
        name: 'Bodyweight Cossack Squats',
        focusArea: MobilityFocusArea.hipCapsule,
        category: MobilityCategory.liftingAccessory,
        description: 'Increases groin, adductor, and ankle flexibility while strengthening lateral hip stability.',
        cues: <String>[
          'Take a wide stance and squat deep onto one side.',
          'Keep working heel glued to floor and opposite toe pointing up.',
          'Drive through working heel to return to center.',
        ],
        defaultSets: 3,
        defaultReps: 8,
        videoUrl: _youtubeSearchUrl('Bodyweight Cossack Squat'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'jefferson_curl',
        name: 'Jefferson Curls (Weighted Segmented Hinge)',
        focusArea: MobilityFocusArea.posteriorChain,
        category: MobilityCategory.liftingAccessory,
        description: 'Strengthens and lengthens spinal erectors and hamstrings through full flexed mobility.',
        cues: <String>[
          'Stand on box with light kettlebell or empty bar (8-16kg).',
          'Tuck chin and roll down spine segment by segment.',
          'Reach down past toes smoothly, then roll up sequentially.',
        ],
        defaultSets: 3,
        defaultReps: 6,
        videoUrl: _youtubeSearchUrl('Jefferson Curl'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'couch_stretch',
        name: 'Couch Stretch (Quad & Hip Flexor)',
        focusArea: MobilityFocusArea.quadriceps,
        category: MobilityCategory.mobilityDrill,
        description: 'Relieves intense quad and hip flexor tightness resulting from heavy squat cycles.',
        cues: <String>[
          'Place back shin flush against wall with knee on floor pad.',
          'Bring front foot flat on floor in 90-degree angle.',
          'Squeeze back glute and lift torso upright.',
        ],
        durationSeconds: 90,
        videoUrl: _youtubeSearchUrl('Couch Stretch Quad Hip Flexor'),
        isYoutube: true,
      ),

      // CORE: CABLE CRUNCHES & DRAGON FLAGS
      MobilityExerciseModel(
        id: 'cable_crunches',
        name: 'Cable Crunches',
        focusArea: MobilityFocusArea.absCore,
        category: MobilityCategory.hypertrophyCore,
        description: 'Kneeling rope cable crunches for loaded core flexion, rectus abdominis development, and spinal bracing.',
        cues: <String>[
          'Kneel facing the high cable pulley with rope attachment held at temple level.',
          'Flex spine and crunch ribcage down toward pelvis, contracting abs intensely at bottom.',
          'Resist cable stack on eccentric ascent without letting hips rock backward.',
        ],
        defaultSets: 3,
        defaultReps: 8,
        videoUrl: _youtubeSearchUrl('Kneeling Cable Crunches Rope Form'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'dragon_flags',
        name: 'Dragon Flags',
        focusArea: MobilityFocusArea.absCore,
        category: MobilityCategory.hypertrophyCore,
        description: 'Legendary Bruce Lee core exercise developing maximal anti-extension bracing strength.',
        cues: <String>[
          'Anchor hands firmly behind head on bench or sturdy upright.',
          'Raise entire body in straight line from shoulders to toes.',
          'Lower body slowly under control without breaking at the hips.',
        ],
        defaultSets: 3,
        defaultReps: 5,
        videoUrl: _youtubeSearchUrl('Dragon Flag Progression Form'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'hanging_leg_raises',
        name: 'Hanging Leg Raises',
        focusArea: MobilityFocusArea.absCore,
        category: MobilityCategory.hypertrophyCore,
        description: 'Strengthens lower abs and hip flexors for bracing under heavy squat & pull loads.',
        cues: <String>[
          'Hang from pull-up bar with straight active shoulders.',
          'Raise legs up to parallel (or toes to bar) without swinging body.',
          'Lower legs under control to prevent momentum.',
        ],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: _youtubeSearchUrl('Hanging Leg Raises'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'ab_wheel_rollout',
        name: 'Ab Wheel Rollout / Plank Hold',
        focusArea: MobilityFocusArea.absCore,
        category: MobilityCategory.hypertrophyCore,
        description: 'Develops anti-extension core strength to prevent lumbar arching under heavy overhead loads.',
        cues: <String>[
          'Kneel on pad and roll wheel out keeping spine slightly rounded (hollow body).',
          'Squeeze abs hard at full extension before pulling back to knees.',
          'Alternatively hold a forearm plank for 60 seconds.',
        ],
        durationSeconds: 60,
        defaultSets: 3,
        defaultReps: 10,
        videoUrl: _youtubeSearchUrl('Ab Wheel Rollout'),
        isYoutube: true,
      ),

      // ARMS & HYPERTROPHY (BICEPS & TRICEPS)
      MobilityExerciseModel(
        id: 'db_bicep_curls',
        name: 'Dumbbell Bicep Curls',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Builds elbow flexor strength and bicep tendon resilience for heavy clean catches.',
        cues: <String>[
          'Stand tall with dumbbells at sides, palms facing forward.',
          'Curl weights up keeping elbows pinned to your ribs.',
          'Squeeze biceps hard at top contraction, then lower with a 2-second tempo.',
        ],
        defaultSets: 3,
        defaultReps: 10,
        videoUrl: _youtubeSearchUrl('Dumbbell Bicep Curls'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'hammer_curls',
        name: 'Dumbbell Hammer Curls',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Targets brachialis and brachioradialis for elbow joint stability and thick forearms.',
        cues: <String>[
          'Hold dumbbells with neutral grip (palms facing each other).',
          'Curl upward keeping wrists rigid and elbows pinned.',
          'Lower smoothly for 2 seconds.',
        ],
        defaultSets: 3,
        defaultReps: 10,
        videoUrl: _youtubeSearchUrl('Dumbbell Hammer Curls'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'bayesian_cable_curl',
        name: 'Bayesian Cable Curl (Behind-the-Back)',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Single-arm cable curl performed facing away from the pulley with the shoulder in hyperextension, placing maximal eccentric load and stretch tension on the bicep long head.',
        cues: <String>[
          'Set single cable pulley to lowest or wrist height with D-handle.',
          'Step 1-2 feet forward facing away from the stack until arm is drawn back behind torso.',
          'Keep upper arm locked stationary behind torso line.',
          'Curl handle forward into peak flexion without letting elbow swing forward.',
          'Control eccentric descent for 3 seconds into full stretch.',
        ],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: _youtubeSearchUrl('Bayesian Cable Curl Tutorial'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'barbell_bicep_curls',
        name: 'Barbell / EZ-Bar Bicep Curls',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Overload bicep exercise with barbell or EZ-curl bar.',
        cues: <String>[
          'Shoulder-width underhand grip on barbell.',
          'Drive elbows slightly forward at contraction peak.',
          'Control eccentric descent.',
        ],
        defaultSets: 3,
        defaultReps: 10,
        videoUrl: _youtubeSearchUrl('Barbell Bicep Curls Form'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'overhead_tricep_ext',
        name: 'Overhead DB Tricep Extension',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Strengthens tricep long-head for punch-out power in snatch & jerk lockouts.',
        cues: <String>[
          'Hold dumbbell overhead with both hands supporting top plate.',
          'Lower weight behind head keeping elbows pointed straight forward.',
          'Extend arms fully overhead to lockout without flaring elbows.',
        ],
        defaultSets: 3,
        defaultReps: 10,
        videoUrl: _youtubeSearchUrl('Overhead Dumbbell Tricep Extension'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'skull_crushers',
        name: 'Lying Tricep Extensions (Skull Crushers)',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Direct tricep mass builder for elbow extension power in jerk recoveries.',
        cues: <String>[
          'Lie flat on bench with EZ-bar or dumbbells extended above chest.',
          'Hinge at elbows to lower weight toward forehead/crown.',
          'Press back to lockout keeping upper arms stationary.',
        ],
        defaultSets: 3,
        defaultReps: 10,
        videoUrl: _youtubeSearchUrl('Lying Tricep Extensions Skull Crushers'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'tricep_pushdown',
        name: 'Cable Tricep Pushdowns',
        focusArea: MobilityFocusArea.arms,
        category: MobilityCategory.hypertrophyCore,
        description: 'Isolates lateral and medial tricep heads with constant cable tension.',
        cues: <String>[
          'Grip rope or bar attachment at chest level.',
          'Push downward until arms are fully locked out at sides.',
          'Return slowly to 90-degree elbow angle.',
        ],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: _youtubeSearchUrl('Cable Tricep Pushdown Form'),
        isYoutube: true,
      ),

      // GRIP STRENGTH
      MobilityExerciseModel(
        id: 'farmers_carries',
        name: "Heavy Farmer's Carries",
        focusArea: MobilityFocusArea.gripStrength,
        category: MobilityCategory.hypertrophyCore,
        description: 'Builds crushed grip, trap, and oblique stability required for heavy pulling volume.',
        cues: <String>[
          'Pick up heavy dumbbells or kettlebells with flat back.',
          'Walk 30-40 meters with tall posture, shoulders pulled back.',
          'Do not let weights bounce against your legs.',
        ],
        durationSeconds: 45,
        defaultSets: 3,
        defaultReps: 1,
        videoUrl: _youtubeSearchUrl('Farmer Carry Exercise'),
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'barbell_dead_hang',
        name: 'Barbell / Rig Dead Hangs',
        focusArea: MobilityFocusArea.gripStrength,
        category: MobilityCategory.hypertrophyCore,
        description: 'Decompresses spine after heavy squatting while building forearm grip endurance.',
        cues: <String>[
          'Grip pull-up bar with overhand hook or double overhand grip.',
          'Relax lower body completely and let spine stretch out.',
          'Hold grip firmly for 45-60 seconds per set.',
        ],
        durationSeconds: 45,
        defaultSets: 3,
        defaultReps: 1,
        videoUrl: _youtubeSearchUrl('Dead Hang Exercise'),
        isYoutube: true,
      ),
    ];
  }
}
