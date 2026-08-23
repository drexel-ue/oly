enum MobilityFocusArea {
  thoracicSpine,
  shoulderOverhead,
  hipCapsule,
  ankleDorsiflexion,
  posteriorChain,
  quadriceps,
}

enum MobilityCategory {
  mobilityDrill,
  liftingAccessory,
}

class MobilityExerciseModel {
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

  MobilityExerciseModel({
    required this.id,
    required this.name,
    required this.focusArea,
    required this.category,
    required this.description,
    required this.cues,
    this.durationSeconds = 60,
    this.defaultSets = 3,
    this.defaultReps = 10,
    required this.videoUrl,
    this.isYoutube = true,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
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

  factory MobilityExerciseModel.fromJson(Map<String, dynamic> json) {
    return MobilityExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      focusArea: MobilityFocusArea.values.firstWhere(
        (e) => e.name == json['focusArea'],
        orElse: () => MobilityFocusArea.hipCapsule,
      ),
      category: MobilityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MobilityCategory.mobilityDrill,
      ),
      description: json['description'] as String,
      cues: (json['cues'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      durationSeconds: json['durationSeconds'] as int? ?? 60,
      defaultSets: json['defaultSets'] as int? ?? 3,
      defaultReps: json['defaultReps'] as int? ?? 10,
      videoUrl: json['videoUrl'] as String? ?? '',
      isYoutube: json['isYoutube'] as bool? ?? true,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  static List<MobilityExerciseModel> defaultExercises() {
    return [
      // 1. Thoracic Spine Mobility
      MobilityExerciseModel(
        id: 'thoracic_foam_roll',
        name: 'Thoracic Extension on Foam Roller',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.mobilityDrill,
        description: 'Mobilizes upper back extension necessary for upright catch positions in snatch & front squat.',
        cues: [
          'Support your head with your hands, elbows pointed forward.',
          'Gently arch over the roller without letting your ribs flare.',
          'Pause and take 3 deep breaths at each stiff segment.'
        ],
        durationSeconds: 90,
        videoUrl: 'https://www.youtube.com/watch?v=S3742-GqE0w',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'cat_cow_thoracic',
        name: 'Quadruped Thoracic Rotations',
        focusArea: MobilityFocusArea.thoracicSpine,
        category: MobilityCategory.mobilityDrill,
        description: 'Increases thoracic rotation and rib cage mobility for shoulder overhead positioning.',
        cues: [
          'Place one hand behind your head while in all-fours position.',
          'Rotate your elbow down towards the opposite wrist, then drive it up to the ceiling.',
          'Exhale fully at top extension.'
        ],
        durationSeconds: 60,
        videoUrl: 'https://www.youtube.com/watch?v=g8uF03zTdfY',
        isYoutube: true,
      ),

      // 2. Shoulder & Overhead Stability
      MobilityExerciseModel(
        id: 'banded_shoulder_dislocates',
        name: 'PVC / Banded Shoulder Pass-Throughs',
        focusArea: MobilityFocusArea.shoulderOverhead,
        category: MobilityCategory.mobilityDrill,
        description: 'Opens up lat and chest tightness to improve the snatch lock-out and overhead jerk receiver.',
        cues: [
          'Grip PVC pipe wide with straight arms.',
          'Rotate over your head and touch your lower back smoothly.',
          'Keep core braced and avoid arching your lower back.'
        ],
        durationSeconds: 60,
        videoUrl: 'https://www.youtube.com/watch?v=0k5u1_Xq-F0',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'lu_raises',
        name: 'Lu Raises (Lateral Full Range)',
        focusArea: MobilityFocusArea.shoulderOverhead,
        category: MobilityCategory.liftingAccessory,
        description: 'Popularized by Lu Xiaojun; strengthens deltoids and upper traps across full overhead extension.',
        cues: [
          'Use 1.25kg - 2.5kg micro plates or light dumbbells.',
          'Raise arms outward and overhead until plates touch at top.',
          'Lower smoothly under control for a 3-second eccentric.'
        ],
        defaultSets: 3,
        defaultReps: 12,
        videoUrl: 'https://www.youtube.com/watch?v=sO7u_m-7y88',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'sotts_press',
        name: 'Press in Snatch Bottom (Sotts Press)',
        focusArea: MobilityFocusArea.shoulderOverhead,
        category: MobilityCategory.liftingAccessory,
        description: 'Builds extreme overhead stability and hip/ankle flexibility in the bottom of the snatch.',
        cues: [
          'Sit in deep snatch squat with empty barbell or PVC pipe.',
          'Press bar straight up overhead without standing up.',
          'Lock elbows firmly and hold top position for 2 seconds.'
        ],
        defaultSets: 3,
        defaultReps: 6,
        videoUrl: 'https://www.youtube.com/watch?v=2r1H_vS29lE',
        isYoutube: true,
      ),

      // 3. Hip Capsule & Flexor Opener
      MobilityExerciseModel(
        id: 'hip_90_90_switches',
        name: '90/90 Hip Mobility Switches',
        focusArea: MobilityFocusArea.hipCapsule,
        category: MobilityCategory.mobilityDrill,
        description: 'Mobilizes internal and external hip rotation for deep squat receiving positions.',
        cues: [
          'Sit on floor with knees bent at 90-degree angles.',
          'Rotate hips to transition from left side to right side smoothly.',
          'Keep chest tall and avoid leaning far back.'
        ],
        durationSeconds: 90,
        videoUrl: 'https://www.youtube.com/watch?v=t5J5iZ1rPCo',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'cossack_squat',
        name: 'Bodyweight Cossack Squats',
        focusArea: MobilityFocusArea.hipCapsule,
        category: MobilityCategory.liftingAccessory,
        description: 'Increases groin, adductor, and ankle flexibility while strengthening lateral hip stability.',
        cues: [
          'Take a wide stance and squat deep onto one side.',
          'Keep working heel glued to floor and opposite toe pointing up.',
          'Drive through working heel to return to center.'
        ],
        defaultSets: 3,
        defaultReps: 8,
        videoUrl: 'https://www.youtube.com/watch?v=tpU1U4V9nNo',
        isYoutube: true,
      ),

      // 4. Ankle Dorsiflexion
      MobilityExerciseModel(
        id: 'banded_ankle_distraction',
        name: 'Banded Ankle Dorsiflexion Mobilization',
        focusArea: MobilityFocusArea.ankleDorsiflexion,
        category: MobilityCategory.mobilityDrill,
        description: 'Clears anterior ankle joint pinching to allow deeper, upright squat positioning.',
        cues: [
          'Attach heavy resistance band low on rig and loop around ankle talus bone.',
          'Step forward into tension and drive knee over pinky toe.',
          'Oscillate gently forward and backward for 60 seconds per ankle.'
        ],
        durationSeconds: 90,
        videoUrl: 'https://www.youtube.com/watch?v=1b-9eW2YnQE',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'kettlebell_knee_drives',
        name: 'Weighted Ankle Knee Drives',
        focusArea: MobilityFocusArea.ankleDorsiflexion,
        category: MobilityCategory.mobilityDrill,
        description: 'Uses weight on the knee to force deep ankle dorsiflexion and calf stretch.',
        cues: [
          'Rest kettlebell or plate on knee while in half-kneeling stance.',
          'Lean forward into maximum knee travel over toes.',
          'Hold end position for 5 seconds per rep.'
        ],
        durationSeconds: 60,
        videoUrl: 'https://www.youtube.com/watch?v=U2l-S_W_Gv8',
        isYoutube: true,
      ),

      // 5. Posterior Chain & Hamstrings
      MobilityExerciseModel(
        id: 'jefferson_curl',
        name: 'Jefferson Curls (Weighted Segmented Hinge)',
        focusArea: MobilityFocusArea.posteriorChain,
        category: MobilityCategory.liftingAccessory,
        description: 'Strengthens and lengthens spinal erectors and hamstrings through full flexed mobility.',
        cues: [
          'Stand on box with light kettlebell or empty bar (8-16kg).',
          'Tuck chin and roll down spine segment by segment.',
          'Reach down past toes smoothly, then roll up sequentially.'
        ],
        defaultSets: 3,
        defaultReps: 6,
        videoUrl: 'https://www.youtube.com/watch?v=E73Yx2K-gYg',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'single_leg_rdl',
        name: 'Bodyweight Single-Leg RDL',
        focusArea: MobilityFocusArea.posteriorChain,
        category: MobilityCategory.liftingAccessory,
        description: 'Addresses posterior chain imbalances and improves single-leg hip hinge stability for clean pulls.',
        cues: [
          'Hinge at hip extending non-working leg straight behind you.',
          'Keep hips level to ground and back straight.',
          'Squeeze glute of working leg to return upright.'
        ],
        defaultSets: 3,
        defaultReps: 8,
        videoUrl: 'https://www.youtube.com/watch?v=Vd0nSjV3F3Q',
        isYoutube: true,
      ),

      // 6. Quadriceps & Glute Flush
      MobilityExerciseModel(
        id: 'couch_stretch',
        name: 'Couch Stretch (Quad & Hip Flexor)',
        focusArea: MobilityFocusArea.quadriceps,
        category: MobilityCategory.mobilityDrill,
        description: 'Relieves intense quad and hip flexor tightness resulting from heavy squat cycles.',
        cues: [
          'Place back shin flush against wall with knee on floor pad.',
          'Bring front foot flat on floor in 90-degree angle.',
          'Squeeze back glute and lift torso upright.'
        ],
        durationSeconds: 90,
        videoUrl: 'https://www.youtube.com/watch?v=JmF02wHjRik',
        isYoutube: true,
      ),
      MobilityExerciseModel(
        id: 'segmented_snatch_pull',
        name: 'Segmented Snatch Pull w/ Pause',
        focusArea: MobilityFocusArea.posteriorChain,
        category: MobilityCategory.liftingAccessory,
        description: 'Reinforces proper pull trajectory, lats engagement, and balance over midfoot.',
        cues: [
          'Pause 2 seconds at off-floor, knee, and hip positions.',
          'Keep bar brushed close to body with long arms.',
          'Drive tall onto toes at extension.'
        ],
        defaultSets: 3,
        defaultReps: 3,
        videoUrl: 'https://www.youtube.com/watch?v=4y58g-d6s4k',
        isYoutube: true,
      ),
    ];
  }
}
