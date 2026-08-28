import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/services/app_log_service.dart';

class InjuryDatabaseService {
  InjuryDatabaseService._();
  static final InjuryDatabaseService instance = InjuryDatabaseService._();

  List<CatalogInjury> _cachedCatalog = <CatalogInjury>[];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<CatalogInjury> get catalog => List.unmodifiable(_cachedCatalog);

  Future<List<CatalogInjury>> loadCatalog({AssetBundle? bundle}) async {
    if (_isLoaded && _cachedCatalog.isNotEmpty) {
      return _cachedCatalog;
    }

    final AssetBundle activeBundle = bundle ?? rootBundle;

    try {
      final String jsonStr = await activeBundle.loadString(
        'assets/data/sports_injuries_catalog.json',
      );
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedCatalog = list
          .map((dynamic e) => CatalogInjury.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
      AppLogService.instance.info(
        'INJURY_DB',
        'Loaded ${_cachedCatalog.length} sports injury definitions from local OSIICS catalog.',
      );
      return _cachedCatalog;
    } catch (e, st) {
      AppLogService.instance.warning(
        'INJURY_DB',
        'Failed to load sports_injuries_catalog.json from asset bundle. Falling back to built-in presets: $e',
        stackTrace: st.toString(),
      );
      _cachedCatalog = _builtInFallbackCatalog();
      _isLoaded = true;
      return _cachedCatalog;
    }
  }

  List<CatalogInjury> getByRegion(InjuryRegion region) {
    if (!_isLoaded || _cachedCatalog.isEmpty) {
      return _builtInFallbackCatalog()
          .where((CatalogInjury c) => c.supportedRegions.contains(region) || c.region == region)
          .toList();
    }
    return _cachedCatalog
        .where((CatalogInjury c) => c.supportedRegions.contains(region) || c.region == region)
        .toList();
  }

  List<CatalogInjury> search(String query) {
    final String clean = query.trim().toLowerCase();
    final List<CatalogInjury> source =
        _isLoaded && _cachedCatalog.isNotEmpty ? _cachedCatalog : _builtInFallbackCatalog();

    if (clean.isEmpty) {
      return source;
    }

    return source.where((CatalogInjury c) {
      return c.name.toLowerCase().contains(clean) ||
          c.osiicsCode.toLowerCase().contains(clean) ||
          c.description.toLowerCase().contains(clean) ||
          c.region.displayName.toLowerCase().contains(clean);
    }).toList();
  }

  CatalogInjury? findById(String id) {
    final List<CatalogInjury> source =
        _isLoaded && _cachedCatalog.isNotEmpty ? _cachedCatalog : _builtInFallbackCatalog();
    try {
      return source.firstWhere((CatalogInjury c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Built-in emergency catalog in case assets are mocked or bundle is uninitialized in headless tests
  static List<CatalogInjury> _builtInFallbackCatalog() {
    return <CatalogInjury>[
      CatalogInjury(
        id: 'patellar_tendinopathy',
        osiicsCode: 'KJTP',
        name: "Patellar Tendinopathy (Jumper's Knee)",
        region: InjuryRegion.leftKnee,
        supportedRegions: <InjuryRegion>[InjuryRegion.leftKnee, InjuryRegion.rightKnee],
        description: 'Pain and microtrauma at the inferior pole of the patella, aggravated by deep knee flexion.',
        acuteDurationDays: 14,
        chronicThresholdDays: 42,
        aggravatingVectors: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidDeepKneeFlexion,
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ],
        contraindicatedLifts: <String>['Snatch', 'Clean and Jerk', 'Clean', 'Front Squat', 'Back Squat'],
        safeSubstitutions: <InjurySubstitution>[
          InjurySubstitution(
            targetExercise: 'Snatch',
            replacementName: 'Power Snatch from Blocks',
            replacementLiftId: 'power_snatch',
            weightMultiplier: 0.82,
            rationale: 'High blocks eliminate deep knee catch shock and reduce patellofemoral torque.',
          ),
          InjurySubstitution(
            targetExercise: 'Front Squat',
            replacementName: 'Box Squat (Vertical Shin)',
            replacementLiftId: 'back_squat',
            weightMultiplier: 0.85,
            rationale: 'Box squat shifts torque to posterior chain and eliminates forward knee translation.',
          ),
        ],
        rehabFocusAreas: <MobilityFocusArea>[],
        rehabCues: <String>['Perform Spanish squat isometric holds (5x45s).'],
      ),
      CatalogInjury(
        id: 'shoulder_impingement',
        osiicsCode: 'SJSI',
        name: 'Subacromial Impingement / Rotator Cuff Tendinopathy',
        region: InjuryRegion.leftShoulder,
        supportedRegions: <InjuryRegion>[InjuryRegion.leftShoulder, InjuryRegion.rightShoulder],
        description: 'Compression of rotator cuff tendons during overhead abduction and internal rotation.',
        acuteDurationDays: 14,
        chronicThresholdDays: 42,
        aggravatingVectors: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidOverheadLockout,
          BiomechanicalConstraint.avoidBallisticCatchImpact,
        ],
        contraindicatedLifts: <String>['Snatch', 'Overhead Squat', 'Jerk', 'Military Press', 'Push Press'],
        safeSubstitutions: <InjurySubstitution>[
          InjurySubstitution(
            targetExercise: 'Snatch',
            replacementName: 'Snatch High Pull (Straps)',
            replacementLiftId: 'snatch',
            weightMultiplier: 0.90,
            rationale: 'Maintains triple extension power without putting shoulder into overhead lockout.',
          ),
          InjurySubstitution(
            targetExercise: 'Military Press',
            replacementName: 'Landmine Press (Neutral Grip)',
            replacementLiftId: 'military_press',
            weightMultiplier: 0.75,
            rationale: 'Scapular plane pressing relieves subacromial space pressure.',
          ),
        ],
        rehabFocusAreas: <MobilityFocusArea>[],
        rehabCues: <String>['Perform face pulls and band external rotations.'],
      ),
      CatalogInjury(
        id: 'lumbar_disc_strain',
        osiicsCode: 'LBLS',
        name: 'Lumbar Strain / Low Back Pain',
        region: InjuryRegion.lumbarSpine,
        supportedRegions: <InjuryRegion>[InjuryRegion.lumbarSpine],
        description: 'Ache or sharp tightness in the lower back with flexion and spinal axial compression.',
        acuteDurationDays: 14,
        chronicThresholdDays: 42,
        aggravatingVectors: <BiomechanicalConstraint>[
          BiomechanicalConstraint.avoidAxialSpinalShear,
          BiomechanicalConstraint.avoidFloorPullShear,
          BiomechanicalConstraint.avoidAggressiveHipHinge,
        ],
        contraindicatedLifts: <String>['Snatch Deadlift', 'Clean Deadlift', 'Back Squat', 'Romanian Deadlift (RDL)'],
        safeSubstitutions: <InjurySubstitution>[
          InjurySubstitution(
            targetExercise: 'Snatch Deadlift',
            replacementName: 'Block Pulls (Above Knee)',
            replacementLiftId: 'snatch',
            weightMultiplier: 0.85,
            rationale: 'Pulling from above knee significantly reduces lumbar moment arm.',
          ),
          InjurySubstitution(
            targetExercise: 'Back Squat',
            replacementName: 'Belt Squat / Front Foot Elevated Split Squat',
            replacementLiftId: 'back_squat',
            weightMultiplier: 0.70,
            rationale: 'Eliminates spinal axial compression while training leg drive.',
          ),
        ],
        rehabFocusAreas: <MobilityFocusArea>[],
        rehabCues: <String>['Perform McGill Big 3 prior to training.'],
      ),
    ];
  }
}
