import 'package:oly/models/mobility_exercise_model.dart';

enum InjuryRegion {
  neck,
  leftShoulder,
  rightShoulder,
  chestPecs,
  thoracicSpine,
  lumbarSpine,
  coreAbs,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHipGlute,
  rightHipGlute,
  leftQuad,
  rightQuad,
  leftHamstring,
  rightHamstring,
  leftKnee,
  rightKnee,
  leftCalfAnkle,
  rightCalfAnkle,
}

extension InjuryRegionExtension on InjuryRegion {
  String get displayName {
    switch (this) {
      case InjuryRegion.neck:
        return 'Neck / Cervical';
      case InjuryRegion.leftShoulder:
        return 'Left Shoulder';
      case InjuryRegion.rightShoulder:
        return 'Right Shoulder';
      case InjuryRegion.chestPecs:
        return 'Chest / Pecs';
      case InjuryRegion.thoracicSpine:
        return 'Upper / Mid Back';
      case InjuryRegion.lumbarSpine:
        return 'Lower Back (Lumbar)';
      case InjuryRegion.coreAbs:
        return 'Core / Abdominals';
      case InjuryRegion.leftElbow:
        return 'Left Elbow';
      case InjuryRegion.rightElbow:
        return 'Right Elbow';
      case InjuryRegion.leftWrist:
        return 'Left Wrist';
      case InjuryRegion.rightWrist:
        return 'Right Wrist';
      case InjuryRegion.leftHipGlute:
        return 'Left Hip & Glute';
      case InjuryRegion.rightHipGlute:
        return 'Right Hip & Glute';
      case InjuryRegion.leftQuad:
        return 'Left Quadriceps';
      case InjuryRegion.rightQuad:
        return 'Right Quadriceps';
      case InjuryRegion.leftHamstring:
        return 'Left Hamstring';
      case InjuryRegion.rightHamstring:
        return 'Right Hamstring';
      case InjuryRegion.leftKnee:
        return 'Left Knee';
      case InjuryRegion.rightKnee:
        return 'Right Knee';
      case InjuryRegion.leftCalfAnkle:
        return 'Left Calf & Ankle';
      case InjuryRegion.rightCalfAnkle:
        return 'Right Calf & Ankle';
    }
  }

  bool get isPosteriorDefault {
    switch (this) {
      case InjuryRegion.thoracicSpine:
      case InjuryRegion.lumbarSpine:
      case InjuryRegion.leftHamstring:
      case InjuryRegion.rightHamstring:
        return true;
      default:
        return false;
    }
  }
}

enum InjurySubRegion {
  // Knee
  patellarTendon,
  quadricepsTendon,
  medialCompartment,
  lateralCompartment,
  posteriorKnee,
  generalKnee,

  // Lower Leg, Ankle, Foot
  achillesTendonMid,
  achillesTendonInsertional,
  ankleJointDorsi,
  lateralAnkle,
  gastrocnemius,
  soleus,
  shinSplints,
  plantarFascia,
  bigToeMtp,
  generalCalfAnkle,

  // Hips & Pelvis
  hipFlexorPsoas,
  adductorGroin,
  gluteMediusPiriformis,
  gluteMaximus,
  siJoint,
  hipCapsuleFai,
  generalHip,

  // Shoulder & Scapula
  rotatorCuff,
  subacromialBursa,
  acJoint,
  bicepsLongHead,
  posteriorDeltoid,
  generalShoulder,

  // Back & Neck
  upperTrapezius,
  cervicalSpine,
  levatorScapulae,
  scapulaRhomboids,
  latissimusDorsi,
  midThoracicSpine,
  lumbarErectors,
  lumbarDisc,
  quadratusLumborum,
  generalBack,

  // Arms, Elbows & Wrists
  medialEpicondyle,
  lateralEpicondyle,
  tricepsTendon,
  distalBiceps,
  dorsalWristExtensor,
  tfccUlnarWrist,
  thumbHookGrip,
  carpalTunnelVentral,
  generalArmHand,

  // Thighs
  rectusFemoris,
  vmoVastusMedialis,
  vastusLateralis,
  proximalHamstringIschial,
  bicepsFemoris,
  semitendinosus,
  generalThigh,

  // Torso
  sternalPecMajor,
  sternumCostochondral,
  rectusAbdominis,
  obliques,
  intercostalsSerratus,
  generalTorso,
}

extension InjurySubRegionExtension on InjurySubRegion {
  String get shortName {
    switch (this) {
      case InjurySubRegion.patellarTendon:
        return 'Patellar Tendon';
      case InjurySubRegion.quadricepsTendon:
        return 'Quad Tendon';
      case InjurySubRegion.medialCompartment:
        return 'Medial Knee / MCL';
      case InjurySubRegion.lateralCompartment:
        return 'Lateral Knee / ITB';
      case InjurySubRegion.posteriorKnee:
        return 'Posterior Knee';
      case InjurySubRegion.generalKnee:
        return 'General Knee';

      case InjurySubRegion.achillesTendonMid:
        return 'Mid-Achilles';
      case InjurySubRegion.achillesTendonInsertional:
        return 'Insertional Achilles';
      case InjurySubRegion.ankleJointDorsi:
        return 'Ankle Mortise';
      case InjurySubRegion.lateralAnkle:
        return 'Lateral Ankle';
      case InjurySubRegion.gastrocnemius:
        return 'Upper Calf (Gastroc)';
      case InjurySubRegion.soleus:
        return 'Deep Calf (Soleus)';
      case InjurySubRegion.shinSplints:
        return 'Shin / Tibialis';
      case InjurySubRegion.plantarFascia:
        return 'Plantar Fascia';
      case InjurySubRegion.bigToeMtp:
        return 'Big Toe / 1st MTP';
      case InjurySubRegion.generalCalfAnkle:
        return 'General Lower Leg';

      case InjurySubRegion.hipFlexorPsoas:
        return 'Hip Flexor / Psoas';
      case InjurySubRegion.adductorGroin:
        return 'Adductor / Groin';
      case InjurySubRegion.gluteMediusPiriformis:
        return 'Glute Med / Piriformis';
      case InjurySubRegion.gluteMaximus:
        return 'Gluteus Maximus';
      case InjurySubRegion.siJoint:
        return 'SI Joint / Sacrum';
      case InjurySubRegion.hipCapsuleFai:
        return 'Hip Impingement (FAI)';
      case InjurySubRegion.generalHip:
        return 'General Hip';

      case InjurySubRegion.rotatorCuff:
        return 'Rotator Cuff';
      case InjurySubRegion.subacromialBursa:
        return 'Subacromial Impingement';
      case InjurySubRegion.acJoint:
        return 'AC Joint';
      case InjurySubRegion.bicepsLongHead:
        return 'Biceps Long Head';
      case InjurySubRegion.posteriorDeltoid:
        return 'Posterior Shoulder';
      case InjurySubRegion.generalShoulder:
        return 'General Shoulder';

      case InjurySubRegion.upperTrapezius:
        return 'Upper Traps';
      case InjurySubRegion.cervicalSpine:
        return 'Cervical Spine';
      case InjurySubRegion.levatorScapulae:
        return 'Levator Scapulae';
      case InjurySubRegion.scapulaRhomboids:
        return 'Scapular Rhomboids';
      case InjurySubRegion.latissimusDorsi:
        return 'Latissimus Dorsi';
      case InjurySubRegion.midThoracicSpine:
        return 'Mid-Thoracic Spine';
      case InjurySubRegion.lumbarErectors:
        return 'Lumbar Erectors';
      case InjurySubRegion.lumbarDisc:
        return 'Lumbar Disc (L4-S1)';
      case InjurySubRegion.quadratusLumborum:
        return 'QL (Flank)';
      case InjurySubRegion.generalBack:
        return 'General Back';

      case InjurySubRegion.medialEpicondyle:
        return "Golfer's Elbow";
      case InjurySubRegion.lateralEpicondyle:
        return 'Tennis Elbow';
      case InjurySubRegion.tricepsTendon:
        return 'Triceps Tendon';
      case InjurySubRegion.distalBiceps:
        return 'Distal Biceps';
      case InjurySubRegion.dorsalWristExtensor:
        return 'Wrist Extensors';
      case InjurySubRegion.tfccUlnarWrist:
        return 'TFCC (Pinky Side)';
      case InjurySubRegion.thumbHookGrip:
        return 'Hook Grip Thumb';
      case InjurySubRegion.carpalTunnelVentral:
        return 'Ventral Wrist';
      case InjurySubRegion.generalArmHand:
        return 'General Arm / Hand';

      case InjurySubRegion.rectusFemoris:
        return 'Rectus Femoris';
      case InjurySubRegion.vmoVastusMedialis:
        return 'VMO (Teardrop)';
      case InjurySubRegion.vastusLateralis:
        return 'Vastus Lateralis';
      case InjurySubRegion.proximalHamstringIschial:
        return 'Proximal Hamstring';
      case InjurySubRegion.bicepsFemoris:
        return 'Lateral Hamstring';
      case InjurySubRegion.semitendinosus:
        return 'Medial Hamstring';
      case InjurySubRegion.generalThigh:
        return 'General Thigh';

      case InjurySubRegion.sternalPecMajor:
        return 'Pectoralis Major';
      case InjurySubRegion.sternumCostochondral:
        return 'Sternum / Costochondral';
      case InjurySubRegion.rectusAbdominis:
        return 'Rectus Abdominis';
      case InjurySubRegion.obliques:
        return 'Obliques';
      case InjurySubRegion.intercostalsSerratus:
        return 'Ribs / Serratus';
      case InjurySubRegion.generalTorso:
        return 'General Torso';
    }
  }

  String get displayName {
    switch (this) {
      case InjurySubRegion.patellarTendon:
        return "Patellar Tendon (Jumper's Knee)";
      case InjurySubRegion.quadricepsTendon:
        return 'Quadriceps Tendon';
      case InjurySubRegion.medialCompartment:
        return 'Medial Joint Line / MCL / Meniscus';
      case InjurySubRegion.lateralCompartment:
        return 'Lateral Joint Line / ITB / LCL';
      case InjurySubRegion.posteriorKnee:
        return 'Posterior Knee / Popliteal Fossa';
      case InjurySubRegion.generalKnee:
        return 'General / Diffuse Knee Pain';

      case InjurySubRegion.achillesTendonMid:
        return 'Achilles Tendon (Mid-Portion)';
      case InjurySubRegion.achillesTendonInsertional:
        return 'Achilles Tendon (Insertional / Heel)';
      case InjurySubRegion.ankleJointDorsi:
        return 'Ankle Mortise / Anterior Impingement';
      case InjurySubRegion.lateralAnkle:
        return 'Lateral Ankle Ligaments (ATFL / Sprain)';
      case InjurySubRegion.gastrocnemius:
        return 'Gastrocnemius Muscle Belly (Upper Calf)';
      case InjurySubRegion.soleus:
        return 'Soleus / Deep Lower Calf';
      case InjurySubRegion.shinSplints:
        return 'Shin / Anterior Tibialis (Shin Splints)';
      case InjurySubRegion.plantarFascia:
        return 'Plantar Fascia / Arch';
      case InjurySubRegion.bigToeMtp:
        return 'Big Toe / 1st MTP Joint (Turf Toe / Split Jerk)';
      case InjurySubRegion.generalCalfAnkle:
        return 'General Lower Leg / Ankle';

      case InjurySubRegion.hipFlexorPsoas:
        return 'Hip Flexor / Psoas / Rectus Femoris';
      case InjurySubRegion.adductorGroin:
        return 'Adductor / Groin (Inner Thigh)';
      case InjurySubRegion.gluteMediusPiriformis:
        return 'Gluteus Medius / Piriformis';
      case InjurySubRegion.gluteMaximus:
        return 'Gluteus Maximus Muscle Belly';
      case InjurySubRegion.siJoint:
        return 'Sacroiliac (SI) Joint / Sacrum';
      case InjurySubRegion.hipCapsuleFai:
        return 'Hip Capsule / Impingement (FAI)';
      case InjurySubRegion.generalHip:
        return 'General Hip / Pelvic Girdle';

      case InjurySubRegion.rotatorCuff:
        return 'Rotator Cuff (Supraspinatus / Infraspinatus)';
      case InjurySubRegion.subacromialBursa:
        return 'Subacromial Impingement / Bursa';
      case InjurySubRegion.acJoint:
        return 'AC Joint (Acromioclavicular)';
      case InjurySubRegion.bicepsLongHead:
        return 'Biceps Long Head Tendon (Anterior Shoulder)';
      case InjurySubRegion.posteriorDeltoid:
        return 'Posterior Shoulder / Teres Minor';
      case InjurySubRegion.generalShoulder:
        return 'General Shoulder Complex';

      case InjurySubRegion.upperTrapezius:
        return 'Upper Trapezius / Neck Ridge';
      case InjurySubRegion.cervicalSpine:
        return 'Cervical Spine / Neck Extensors';
      case InjurySubRegion.levatorScapulae:
        return 'Levator Scapulae';
      case InjurySubRegion.scapulaRhomboids:
        return 'Scapular Stabilizers / Rhomboids';
      case InjurySubRegion.latissimusDorsi:
        return 'Latissimus Dorsi (Lats / Flank)';
      case InjurySubRegion.midThoracicSpine:
        return 'Mid-Thoracic Vertebrae';
      case InjurySubRegion.lumbarErectors:
        return 'Lumbar Erector Spinae';
      case InjurySubRegion.lumbarDisc:
        return 'Lower Lumbar / Disc / Central (L4-S1)';
      case InjurySubRegion.quadratusLumborum:
        return 'Quadratus Lumborum (QL / Flank)';
      case InjurySubRegion.generalBack:
        return 'General Back / Spine Strain';

      case InjurySubRegion.medialEpicondyle:
        return "Medial Epicondyle (Golfer's Elbow / Flexor)";
      case InjurySubRegion.lateralEpicondyle:
        return 'Lateral Epicondyle (Tennis Elbow / Extensor)';
      case InjurySubRegion.tricepsTendon:
        return 'Triceps Tendon Insertion (Elbow Point)';
      case InjurySubRegion.distalBiceps:
        return 'Distal Biceps Tendon (Front Elbow)';
      case InjurySubRegion.dorsalWristExtensor:
        return 'Dorsal Wrist Extensors / Ganglion Area';
      case InjurySubRegion.tfccUlnarWrist:
        return 'TFCC / Ulnar Side Wrist (Pinky Side)';
      case InjurySubRegion.thumbHookGrip:
        return 'Thumb Base / UCL / Hook Grip Base';
      case InjurySubRegion.carpalTunnelVentral:
        return 'Ventral Wrist / Flexor Crease';
      case InjurySubRegion.generalArmHand:
        return 'General Arm / Elbow / Wrist';

      case InjurySubRegion.rectusFemoris:
        return 'Rectus Femoris (Mid-Thigh)';
      case InjurySubRegion.vmoVastusMedialis:
        return 'Vastus Medialis (VMO / Teardrop)';
      case InjurySubRegion.vastusLateralis:
        return 'Vastus Lateralis (Outer Quad)';
      case InjurySubRegion.proximalHamstringIschial:
        return 'Proximal Hamstring (High Sit-Bone / Ischial)';
      case InjurySubRegion.bicepsFemoris:
        return 'Biceps Femoris (Lateral Hamstring)';
      case InjurySubRegion.semitendinosus:
        return 'Semitendinosus (Medial Hamstring)';
      case InjurySubRegion.generalThigh:
        return 'General Thigh / Upper Leg';

      case InjurySubRegion.sternalPecMajor:
        return 'Pectoralis Major (Chest)';
      case InjurySubRegion.sternumCostochondral:
        return 'Costochondral Joint / Sternum (Barbell Catch)';
      case InjurySubRegion.rectusAbdominis:
        return 'Rectus Abdominis (Abs)';
      case InjurySubRegion.obliques:
        return 'Internal / External Obliques';
      case InjurySubRegion.intercostalsSerratus:
        return 'Intercostals / Serratus Anterior (Ribs)';
      case InjurySubRegion.generalTorso:
        return 'General Chest / Core';
    }
  }

  String get description {
    switch (this) {
      case InjurySubRegion.patellarTendon:
        return 'Directly below patella, sharp pain during deep knee flexion or bounce.';
      case InjurySubRegion.quadricepsTendon:
        return 'Superior border of patella, strained under heavy eccentric squat loads.';
      case InjurySubRegion.medialCompartment:
        return 'Inner knee joint line, aggravated by knee valgus collapse or twisting.';
      case InjurySubRegion.lateralCompartment:
        return 'Outer knee pain, friction over lateral femoral condyle.';
      case InjurySubRegion.posteriorKnee:
        return 'Deep behind the knee or distal hamstring tendon insertion.';
      case InjurySubRegion.generalKnee:
        return 'Broad or non-localized knee discomfort.';

      case InjurySubRegion.achillesTendonMid:
        return '2-6 cm above heel bone, morning stiffness, painful on explosive push-off.';
      case InjurySubRegion.achillesTendonInsertional:
        return 'Directly on the calcaneus heel bone, aggravated by deep ankle dorsiflexion.';
      case InjurySubRegion.ankleJointDorsi:
        return 'Front of ankle pinch at bottom of deep clean or overhead squat.';
      case InjurySubRegion.lateralAnkle:
        return 'Outer ankle roll or residual inversion instability.';
      case InjurySubRegion.gastrocnemius:
        return 'Fleshy upper calf strain during triple extension push-off.';
      case InjurySubRegion.soleus:
        return 'Lower calf endurance tightness, aching under bent-knee positions.';
      case InjurySubRegion.shinSplints:
        return 'Ache along anterior/medial tibia from repetitive impact or jumping.';
      case InjurySubRegion.plantarFascia:
        return 'Sharp underside arch or heel pain upon initial weight-bearing.';
      case InjurySubRegion.bigToeMtp:
        return 'Base of great toe, aggravated during rear-foot extension in Split Jerk.';
      case InjurySubRegion.generalCalfAnkle:
        return 'Unspecified lower leg or ankle strain.';

      case InjurySubRegion.hipFlexorPsoas:
        return 'Anterior hip crease pinch during deep squat catch or leg drive.';
      case InjurySubRegion.adductorGroin:
        return 'Inner thigh strain from wide squat stance or lateral stabilization.';
      case InjurySubRegion.gluteMediusPiriformis:
        return 'Lateral buttock or deep ache, often mimics sciatica under heavy loads.';
      case InjurySubRegion.gluteMaximus:
        return 'Main buttock extensor strain during hip drive off the floor.';
      case InjurySubRegion.siJoint:
        return 'One-sided lower back / pelvis junction pain aggravated by asymmetrical loading.';
      case InjurySubRegion.hipCapsuleFai:
        return 'Deep groin pinch on deep hip flexion and internal rotation.';
      case InjurySubRegion.generalHip:
        return 'Broad hip or pelvic discomfort.';

      case InjurySubRegion.rotatorCuff:
        return 'Pain on abduction, external rotation, or snatch overhead stability.';
      case InjurySubRegion.subacromialBursa:
        return 'Pinching under acromion on overhead lockout or upright row.';
      case InjurySubRegion.acJoint:
        return 'Top of shoulder focal pain when front racking clean or bench pressing.';
      case InjurySubRegion.bicepsLongHead:
        return 'Front shoulder groove tenderness aggravated by clean catch / dips.';
      case InjurySubRegion.posteriorDeltoid:
        return 'Rear shoulder tension during bar path control and snatches.';
      case InjurySubRegion.generalShoulder:
        return 'Broad shoulder strain.';

      case InjurySubRegion.upperTrapezius:
        return 'Upper shoulder ridge tightness from explosive shrugs and jerks.';
      case InjurySubRegion.cervicalSpine:
        return 'Stiff neck, discomfort looking up during overhead lifts.';
      case InjurySubRegion.levatorScapulae:
        return 'Neck-to-shoulder blade trigger point, pain on head turning.';
      case InjurySubRegion.scapulaRhomboids:
        return 'Between shoulder blades, fatigue maintaining retracted back in pulls.';
      case InjurySubRegion.latissimusDorsi:
        return 'Large back puller muscle strain during cleans, pulls, or pullups.';
      case InjurySubRegion.midThoracicSpine:
        return 'Mid-back stiffness limiting thoracic extension in front squat.';
      case InjurySubRegion.lumbarErectors:
        return 'Lower back muscle pump or spasm from heavy pulls and deadlifts.';
      case InjurySubRegion.lumbarDisc:
        return 'Central deep back ache or nerve irritation under spinal compression.';
      case InjurySubRegion.quadratusLumborum:
        return 'One-sided deep lateral lower back pain when bracing.';
      case InjurySubRegion.generalBack:
        return 'Diffuse back or spinal ache.';

      case InjurySubRegion.medialEpicondyle:
        return 'Inner elbow pain from heavy grip, clean rack, or pulling.';
      case InjurySubRegion.lateralEpicondyle:
        return 'Outer elbow pain from wrist extension and snatch stabilization.';
      case InjurySubRegion.tricepsTendon:
        return 'Posterior elbow pain right above the olecranon on jerk lockout.';
      case InjurySubRegion.distalBiceps:
        return 'Antecubital crease pain from underhand pulling or arm bend.';
      case InjurySubRegion.dorsalWristExtensor:
        return 'Top of wrist pain on full extension in clean rack or front squat.';
      case InjurySubRegion.tfccUlnarWrist:
        return 'Pinky-side wrist pain during rotation and overhead lockout.';
      case InjurySubRegion.thumbHookGrip:
        return 'First metacarpal / thumb joint strain from aggressive hook grip.';
      case InjurySubRegion.carpalTunnelVentral:
        return 'Palmar wrist crease tenderness under heavy load.';
      case InjurySubRegion.generalArmHand:
        return 'Diffuse arm or wrist discomfort.';

      case InjurySubRegion.rectusFemoris:
        return 'Anterior central thigh strain, painful on high-speed sprinting or cleans.';
      case InjurySubRegion.vmoVastusMedialis:
        return 'Inner quad teardrop fatigue or terminal knee extension weakness.';
      case InjurySubRegion.vastusLateralis:
        return 'Outer thigh stiffness pulling on lateral patella.';
      case InjurySubRegion.proximalHamstringIschial:
        return 'High hamstring attachment pain under hip hinge / RDL stretch.';
      case InjurySubRegion.bicepsFemoris:
        return 'Outer back of thigh strain during rapid extension.';
      case InjurySubRegion.semitendinosus:
        return 'Inner back of thigh strain.';
      case InjurySubRegion.generalThigh:
        return 'Diffuse thigh ache.';

      case InjurySubRegion.sternalPecMajor:
        return 'Chest muscle strain from bench press, dips, or overhead catch.';
      case InjurySubRegion.sternumCostochondral:
        return 'Barbell collarbone/sternum contact pain on heavy clean catch.';
      case InjurySubRegion.rectusAbdominis:
        return 'Front abdominal wall strain from heavy valsalva bracing.';
      case InjurySubRegion.obliques:
        return 'Flank abdominal strain during rotational or asymmetrical lifts.';
      case InjurySubRegion.intercostalsSerratus:
        return 'Rib cage tenderness on deep breathing or overhead reaching.';
      case InjurySubRegion.generalTorso:
        return 'General chest or core strain.';
    }
  }

  bool get isGeneral {
    switch (this) {
      case InjurySubRegion.generalKnee:
      case InjurySubRegion.generalCalfAnkle:
      case InjurySubRegion.generalHip:
      case InjurySubRegion.generalShoulder:
      case InjurySubRegion.generalBack:
      case InjurySubRegion.generalArmHand:
      case InjurySubRegion.generalThigh:
      case InjurySubRegion.generalTorso:
        return true;
      default:
        return false;
    }
  }

  List<BiomechanicalConstraint> get defaultConstraints {
    switch (this) {
      case InjurySubRegion.patellarTendon:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ];
      case InjurySubRegion.quadricepsTendon:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
          BiomechanicalConstraint.avoidHeavyEccentricStretch,
        ];
      case InjurySubRegion.medialCompartment:
      case InjurySubRegion.lateralCompartment:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
        ];
      case InjurySubRegion.achillesTendonMid:
      case InjurySubRegion.achillesTendonInsertional:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidBallisticCatchImpact,
          BiomechanicalConstraint.avoidHeavyEccentricStretch,
        ];
      case InjurySubRegion.ankleJointDorsi:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
        ];
      case InjurySubRegion.bigToeMtp:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ];
      case InjurySubRegion.adductorGroin:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
          BiomechanicalConstraint.avoidAggressiveHipHinge,
        ];
      case InjurySubRegion.hipFlexorPsoas:
      case InjurySubRegion.hipCapsuleFai:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidAggressiveHipHinge,
          BiomechanicalConstraint.avoidDeepKneeFlexion,
        ];
      case InjurySubRegion.rotatorCuff:
      case InjurySubRegion.subacromialBursa:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidOverheadLockout,
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ];
      case InjurySubRegion.acJoint:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidOverheadLockout,
        ];
      case InjurySubRegion.dorsalWristExtensor:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidWristExtension,
        ];
      case InjurySubRegion.lumbarDisc:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidAxialSpinalShear,
          BiomechanicalConstraint.avoidFloorPullShear,
        ];
      case InjurySubRegion.lumbarErectors:
      case InjurySubRegion.siJoint:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidFloorPullShear,
        ];
      case InjurySubRegion.proximalHamstringIschial:
        return <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidAggressiveHipHinge,
          BiomechanicalConstraint.avoidHeavyEccentricStretch,
        ];
      default:
        return <BiomechanicalConstraint>[];
    }
  }

  static List<InjurySubRegion> forRegion(InjuryRegion region) {
    switch (region) {
      case InjuryRegion.leftKnee:
      case InjuryRegion.rightKnee:
        return <InjurySubRegion>[
          InjurySubRegion.patellarTendon,
          InjurySubRegion.quadricepsTendon,
          InjurySubRegion.medialCompartment,
          InjurySubRegion.lateralCompartment,
          InjurySubRegion.posteriorKnee,
          InjurySubRegion.generalKnee,
        ];

      case InjuryRegion.leftCalfAnkle:
      case InjuryRegion.rightCalfAnkle:
        return <InjurySubRegion>[
          InjurySubRegion.achillesTendonMid,
          InjurySubRegion.achillesTendonInsertional,
          InjurySubRegion.ankleJointDorsi,
          InjurySubRegion.lateralAnkle,
          InjurySubRegion.gastrocnemius,
          InjurySubRegion.soleus,
          InjurySubRegion.shinSplints,
          InjurySubRegion.plantarFascia,
          InjurySubRegion.bigToeMtp,
          InjurySubRegion.generalCalfAnkle,
        ];

      case InjuryRegion.leftHipGlute:
      case InjuryRegion.rightHipGlute:
        return <InjurySubRegion>[
          InjurySubRegion.hipFlexorPsoas,
          InjurySubRegion.adductorGroin,
          InjurySubRegion.gluteMediusPiriformis,
          InjurySubRegion.gluteMaximus,
          InjurySubRegion.siJoint,
          InjurySubRegion.hipCapsuleFai,
          InjurySubRegion.generalHip,
        ];

      case InjuryRegion.leftShoulder:
      case InjuryRegion.rightShoulder:
        return <InjurySubRegion>[
          InjurySubRegion.rotatorCuff,
          InjurySubRegion.subacromialBursa,
          InjurySubRegion.acJoint,
          InjurySubRegion.bicepsLongHead,
          InjurySubRegion.posteriorDeltoid,
          InjurySubRegion.generalShoulder,
        ];

      case InjuryRegion.thoracicSpine:
        return <InjurySubRegion>[
          InjurySubRegion.scapulaRhomboids,
          InjurySubRegion.latissimusDorsi,
          InjurySubRegion.midThoracicSpine,
          InjurySubRegion.generalBack,
        ];

      case InjuryRegion.lumbarSpine:
        return <InjurySubRegion>[
          InjurySubRegion.lumbarErectors,
          InjurySubRegion.lumbarDisc,
          InjurySubRegion.quadratusLumborum,
          InjurySubRegion.siJoint,
          InjurySubRegion.generalBack,
        ];

      case InjuryRegion.neck:
        return <InjurySubRegion>[
          InjurySubRegion.upperTrapezius,
          InjurySubRegion.cervicalSpine,
          InjurySubRegion.levatorScapulae,
          InjurySubRegion.generalBack,
        ];

      case InjuryRegion.leftElbow:
      case InjuryRegion.rightElbow:
        return <InjurySubRegion>[
          InjurySubRegion.medialEpicondyle,
          InjurySubRegion.lateralEpicondyle,
          InjurySubRegion.tricepsTendon,
          InjurySubRegion.distalBiceps,
          InjurySubRegion.generalArmHand,
        ];

      case InjuryRegion.leftWrist:
      case InjuryRegion.rightWrist:
        return <InjurySubRegion>[
          InjurySubRegion.dorsalWristExtensor,
          InjurySubRegion.tfccUlnarWrist,
          InjurySubRegion.thumbHookGrip,
          InjurySubRegion.carpalTunnelVentral,
          InjurySubRegion.generalArmHand,
        ];

      case InjuryRegion.leftQuad:
      case InjuryRegion.rightQuad:
        return <InjurySubRegion>[
          InjurySubRegion.rectusFemoris,
          InjurySubRegion.vmoVastusMedialis,
          InjurySubRegion.vastusLateralis,
          InjurySubRegion.generalThigh,
        ];

      case InjuryRegion.leftHamstring:
      case InjuryRegion.rightHamstring:
        return <InjurySubRegion>[
          InjurySubRegion.proximalHamstringIschial,
          InjurySubRegion.bicepsFemoris,
          InjurySubRegion.semitendinosus,
          InjurySubRegion.generalThigh,
        ];

      case InjuryRegion.chestPecs:
        return <InjurySubRegion>[
          InjurySubRegion.sternalPecMajor,
          InjurySubRegion.sternumCostochondral,
          InjurySubRegion.generalTorso,
        ];

      case InjuryRegion.coreAbs:
        return <InjurySubRegion>[
          InjurySubRegion.rectusAbdominis,
          InjurySubRegion.obliques,
          InjurySubRegion.intercostalsSerratus,
          InjurySubRegion.generalTorso,
        ];
    }
  }
}

enum InjurySeverity {
  mild,     // Pain 1 - 3
  moderate, // Pain 4 - 6
  severe,   // Pain 7 - 10
}

extension InjurySeverityExtension on InjurySeverity {
  String get displayName {
    switch (this) {
      case InjurySeverity.mild:
        return 'Mild (1-3)';
      case InjurySeverity.moderate:
        return 'Moderate (4-6)';
      case InjurySeverity.severe:
        return 'Severe (7-10)';
    }
  }

  static InjurySeverity fromPain(int pain) {
    if (pain <= 3) {
      return InjurySeverity.mild;
    }
    if (pain <= 6) {
      return InjurySeverity.moderate;
    }
    return InjurySeverity.severe;
  }
}

enum InjuryStage {
  acute,    // < 14 days
  subacute, // 14 - 42 days (2 - 6 weeks)
  chronic,  // > 42 days (6+ weeks)
}

extension InjuryStageExtension on InjuryStage {
  String get label {
    switch (this) {
      case InjuryStage.acute:
        return 'ACUTE';
      case InjuryStage.subacute:
        return 'SUBACUTE';
      case InjuryStage.chronic:
        return 'CHRONIC';
    }
  }

  String get description {
    switch (this) {
      case InjuryStage.acute:
        return 'Recent onset (< 2 weeks) - Active protection and inflammation control.';
      case InjuryStage.subacute:
        return 'Healing phase (2-6 weeks) - Progressive remodeling and controlled tempo loading.';
      case InjuryStage.chronic:
        return 'Persistent (6+ weeks) - Movement pattern modification and capacity building.';
    }
  }
}

enum BiomechanicalConstraint {
  avoidDeepKneeFlexion,
  avoidOverheadLockout,
  avoidAxialSpinalShear,
  avoidFloorPullShear,
  avoidWristExtension,
  avoidBallisticCatchImpact,
  avoidHeavyEccentricStretch,
  avoidAggressiveHipHinge,
}

extension BiomechanicalConstraintExtension on BiomechanicalConstraint {
  String get displayName {
    switch (this) {
      case BiomechanicalConstraint.avoidDeepKneeFlexion:
        return 'Limit Deep Knee Flexion';
      case BiomechanicalConstraint.avoidOverheadLockout:
        return 'Limit Overhead Lockout';
      case BiomechanicalConstraint.avoidAxialSpinalShear:
        return 'Limit Spinal Axial Compression';
      case BiomechanicalConstraint.avoidFloorPullShear:
        return 'Limit Floor Pulls';
      case BiomechanicalConstraint.avoidWristExtension:
        return 'Limit Wrist Extension Rack';
      case BiomechanicalConstraint.avoidBallisticCatchImpact:
        return 'Avoid Ballistic Catch Shock';
      case BiomechanicalConstraint.avoidHeavyEccentricStretch:
        return 'Limit Deep Eccentric Stretch';
      case BiomechanicalConstraint.avoidAggressiveHipHinge:
        return 'Limit Forward Hip Hinge';
    }
  }
}

class InjurySubstitution {
  InjurySubstitution({
    required this.targetExercise,
    required this.replacementName,
    required this.replacementLiftId,
    required this.weightMultiplier,
    required this.rationale,
  });

  factory InjurySubstitution.fromJson(Map<String, dynamic> json) {
    return InjurySubstitution(
      targetExercise: json['targetExercise'] as String? ?? '',
      replacementName: json['replacementName'] as String? ?? '',
      replacementLiftId: json['replacementLiftId'] as String? ?? '',
      weightMultiplier: (json['weightMultiplier'] as num?)?.toDouble() ?? 1.0,
      rationale: json['rationale'] as String? ?? '',
    );
  }

  final String targetExercise;
  final String replacementName;
  final String replacementLiftId;
  final double weightMultiplier;
  final String rationale;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'targetExercise': targetExercise,
      'replacementName': replacementName,
      'replacementLiftId': replacementLiftId,
      'weightMultiplier': weightMultiplier,
      'rationale': rationale,
    };
  }
}

class CatalogInjury {
  CatalogInjury({
    required this.id,
    required this.osiicsCode,
    required this.name,
    required this.region,
    required this.supportedRegions,
    required this.description,
    required this.acuteDurationDays,
    required this.chronicThresholdDays,
    required this.aggravatingVectors,
    required this.contraindicatedLifts,
    required this.safeSubstitutions,
    required this.rehabFocusAreas,
    required this.rehabCues,
    this.subRegion,
  });

  factory CatalogInjury.fromJson(Map<String, dynamic> json) {
    return CatalogInjury(
      id: json['id'] as String,
      osiicsCode: json['osiicsCode'] as String? ?? '',
      name: json['name'] as String,
      region: InjuryRegion.values.firstWhere(
        (InjuryRegion r) => r.name == json['region'],
        orElse: () => InjuryRegion.leftKnee,
      ),
      subRegion: json['subRegion'] != null
          ? InjurySubRegion.values.firstWhere(
              (InjurySubRegion s) => s.name == json['subRegion'],
              orElse: () => InjurySubRegion.generalKnee,
            )
          : null,
      supportedRegions: (json['supportedRegions'] as List<dynamic>?)
              ?.map(
                (dynamic e) => InjuryRegion.values.firstWhere(
                  (InjuryRegion r) => r.name == e,
                  orElse: () => InjuryRegion.leftKnee,
                ),
              )
              .toList() ??
          <InjuryRegion>[],
      description: json['description'] as String? ?? '',
      acuteDurationDays: json['acuteDurationDays'] as int? ?? 14,
      chronicThresholdDays: json['chronicThresholdDays'] as int? ?? 42,
      aggravatingVectors: (json['aggravatingVectors'] as List<dynamic>?)
              ?.map(
                (dynamic e) => BiomechanicalConstraint.values.firstWhere(
                  (BiomechanicalConstraint c) => c.name == e,
                  orElse: () => BiomechanicalConstraint.avoidDeepKneeFlexion,
                ),
              )
              .toList() ??
          <BiomechanicalConstraint>[],
      contraindicatedLifts: (json['contraindicatedLifts'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
      safeSubstitutions: (json['safeSubstitutions'] as List<dynamic>?)
              ?.map((dynamic e) => InjurySubstitution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <InjurySubstitution>[],
      rehabFocusAreas: (json['rehabFocusAreas'] as List<dynamic>?)
              ?.map(
                (dynamic e) => MobilityFocusArea.values.firstWhere(
                  (MobilityFocusArea f) => f.name == e,
                  orElse: () => MobilityFocusArea.hipCapsule,
                ),
              )
              .toList() ??
          <MobilityFocusArea>[],
      rehabCues: (json['rehabCues'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
    );
  }

  final String id;
  final String osiicsCode;
  final String name;
  final InjuryRegion region;
  final InjurySubRegion? subRegion;
  final List<InjuryRegion> supportedRegions;
  final String description;
  final int acuteDurationDays;
  final int chronicThresholdDays;
  final List<BiomechanicalConstraint> aggravatingVectors;
  final List<String> contraindicatedLifts;
  final List<InjurySubstitution> safeSubstitutions;
  final List<MobilityFocusArea> rehabFocusAreas;
  final List<String> rehabCues;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'osiicsCode': osiicsCode,
      'name': name,
      'region': region.name,
      if (subRegion != null) 'subRegion': subRegion!.name,
      'supportedRegions': supportedRegions.map((InjuryRegion r) => r.name).toList(),
      'description': description,
      'acuteDurationDays': acuteDurationDays,
      'chronicThresholdDays': chronicThresholdDays,
      'aggravatingVectors': aggravatingVectors.map((BiomechanicalConstraint c) => c.name).toList(),
      'contraindicatedLifts': contraindicatedLifts,
      'safeSubstitutions': safeSubstitutions.map((InjurySubstitution s) => s.toJson()).toList(),
      'rehabFocusAreas': rehabFocusAreas.map((MobilityFocusArea f) => f.name).toList(),
      'rehabCues': rehabCues,
    };
  }
}

class InjuryHistoryEntry {
  InjuryHistoryEntry({
    required this.date,
    required this.painScale,
    this.notes = '',
    this.sessionRpe,
  });

  factory InjuryHistoryEntry.fromJson(Map<String, dynamic> json) {
    return InjuryHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      painScale: json['painScale'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
      sessionRpe: json['sessionRpe'] as int?,
    );
  }

  final DateTime date;
  final int painScale;
  final String notes;
  final int? sessionRpe;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'painScale': painScale,
      'notes': notes,
      'sessionRpe': sessionRpe,
    };
  }
}

class InjuryRecord {
  InjuryRecord({
    required this.id,
    required this.name,
    required this.region,
    required this.onsetDate,
    required this.painScale,
    this.subRegion,
    this.osiicsCode = '',
    this.constraints = const <BiomechanicalConstraint>[],
    this.notes = '',
    this.isActive = true,
    this.resolvedAt,
    List<InjuryHistoryEntry>? history,
    this.safeSubstitutions = const <InjurySubstitution>[],
    this.rehabFocusAreas = const <MobilityFocusArea>[],
    this.rehabCues = const <String>[],
  }) : history = history ?? <InjuryHistoryEntry>[];

  factory InjuryRecord.fromJson(Map<String, dynamic> json) {
    return InjuryRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      osiicsCode: json['osiicsCode'] as String? ?? '',
      region: InjuryRegion.values.firstWhere(
        (InjuryRegion r) => r.name == json['region'],
        orElse: () => InjuryRegion.leftKnee,
      ),
      subRegion: json['subRegion'] != null
          ? InjurySubRegion.values.firstWhere(
              (InjurySubRegion s) => s.name == json['subRegion'],
              orElse: () => InjurySubRegion.generalKnee,
            )
          : null,
      onsetDate: DateTime.parse(json['onsetDate'] as String),
      painScale: json['painScale'] as int? ?? 3,
      constraints: (json['constraints'] as List<dynamic>?)
              ?.map(
                (dynamic e) => BiomechanicalConstraint.values.firstWhere(
                  (BiomechanicalConstraint c) => c.name == e,
                  orElse: () => BiomechanicalConstraint.avoidDeepKneeFlexion,
                ),
              )
              .toList() ??
          <BiomechanicalConstraint>[],
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      history: (json['history'] as List<dynamic>?)
              ?.map((dynamic e) => InjuryHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <InjuryHistoryEntry>[],
      safeSubstitutions: (json['safeSubstitutions'] as List<dynamic>?)
              ?.map((dynamic e) => InjurySubstitution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <InjurySubstitution>[],
      rehabFocusAreas: (json['rehabFocusAreas'] as List<dynamic>?)
              ?.map(
                (dynamic e) => MobilityFocusArea.values.firstWhere(
                  (MobilityFocusArea f) => f.name == e,
                  orElse: () => MobilityFocusArea.hipCapsule,
                ),
              )
              .toList() ??
          <MobilityFocusArea>[],
      rehabCues: (json['rehabCues'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
    );
  }

  final String id;
  final String name;
  final String osiicsCode;
  final InjuryRegion region;
  final InjurySubRegion? subRegion;
  final DateTime onsetDate;
  int painScale; // 1 to 10
  final List<BiomechanicalConstraint> constraints;
  String notes;
  bool isActive;
  DateTime? resolvedAt;
  final List<InjuryHistoryEntry> history;
  final List<InjurySubstitution> safeSubstitutions;
  final List<MobilityFocusArea> rehabFocusAreas;
  final List<String> rehabCues;

  InjurySeverity get severity => InjurySeverityExtension.fromPain(painScale);

  String get fullDisplayName {
    if (subRegion != null && !subRegion!.isGeneral) {
      return '${region.displayName} • ${subRegion!.shortName}';
    }
    return region.displayName;
  }

  int get durationInDays {
    final DateTime endDate = resolvedAt ?? DateTime.now();
    return endDate.difference(onsetDate).inDays.clamp(0, 9999);
  }

  InjuryStage get stage {
    if (durationInDays < 14) {
      return InjuryStage.acute;
    }
    if (durationInDays <= 42) {
      return InjuryStage.subacute;
    }
    return InjuryStage.chronic;
  }

  String get formattedDuration {
    final int days = durationInDays;
    if (days == 0) {
      return 'Today';
    }
    if (days == 1) {
      return '1 day';
    }
    if (days < 14) {
      return '$days days';
    }
    final int weeks = (days / 7).floor();
    if (weeks < 8) {
      return '$weeks weeks ($days d)';
    }
    final int months = (days / 30).floor();
    return '$months+ months ($days d)';
  }

  InjuryRecord copyWith({
    String? id,
    String? name,
    String? osiicsCode,
    InjuryRegion? region,
    InjurySubRegion? subRegion,
    bool clearSubRegion = false,
    DateTime? onsetDate,
    int? painScale,
    List<BiomechanicalConstraint>? constraints,
    String? notes,
    bool? isActive,
    DateTime? resolvedAt,
    List<InjuryHistoryEntry>? history,
    List<InjurySubstitution>? safeSubstitutions,
    List<MobilityFocusArea>? rehabFocusAreas,
    List<String>? rehabCues,
  }) {
    return InjuryRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      osiicsCode: osiicsCode ?? this.osiicsCode,
      region: region ?? this.region,
      subRegion: clearSubRegion ? null : (subRegion ?? this.subRegion),
      onsetDate: onsetDate ?? this.onsetDate,
      painScale: painScale ?? this.painScale,
      constraints: constraints ?? List<BiomechanicalConstraint>.from(this.constraints),
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      history: history ?? List<InjuryHistoryEntry>.from(this.history),
      safeSubstitutions: safeSubstitutions ?? List<InjurySubstitution>.from(this.safeSubstitutions),
      rehabFocusAreas: rehabFocusAreas ?? List<MobilityFocusArea>.from(this.rehabFocusAreas),
      rehabCues: rehabCues ?? List<String>.from(this.rehabCues),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'osiicsCode': osiicsCode,
      'region': region.name,
      if (subRegion != null) 'subRegion': subRegion!.name,
      'onsetDate': onsetDate.toIso8601String(),
      'painScale': painScale,
      'constraints': constraints.map((BiomechanicalConstraint c) => c.name).toList(),
      'notes': notes,
      'isActive': isActive,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'history': history.map((InjuryHistoryEntry h) => h.toJson()).toList(),
      'safeSubstitutions': safeSubstitutions.map((InjurySubstitution s) => s.toJson()).toList(),
      'rehabFocusAreas': rehabFocusAreas.map((MobilityFocusArea f) => f.name).toList(),
      'rehabCues': rehabCues,
    };
  }
}

class InjuryCheckinDiff {
  InjuryCheckinDiff({
    required this.region,
    required this.initialPain,
    required this.postPain,
    this.notes = '',
  });

  final InjuryRegion region;
  final int initialPain;
  final int postPain;
  final String notes;

  int get deltaPain => postPain - initialPain;
  bool get hasWorsened => deltaPain > 0;
  bool get hasImproved => deltaPain < 0;
  bool get isUnchanged => deltaPain == 0;
}
