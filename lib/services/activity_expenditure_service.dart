import 'dart:math';
import '../models/body_composition_entry.dart';
import '../models/daily_activity_entry.dart';
import '../models/workout_session.dart';

class CompendiumActivity {
  final String id;
  final String code;
  final String name;
  final String category;
  final double met;
  final String description;

  const CompendiumActivity({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.met,
    required this.description,
  });
}

class ActivityExpenditureService {
  /// Curated Compendium of Physical Activities catalog
  static const List<CompendiumActivity> compendiumCatalog = [
    CompendiumActivity(
      id: 'walking_brisk',
      code: '17151',
      name: 'Brisk Walk (3.5 mph)',
      category: 'Walking',
      met: 3.8,
      description: 'Standard walking at a moderate-to-brisk pace on flat ground.',
    ),
    CompendiumActivity(
      id: 'walking_moderate',
      code: '17170',
      name: 'Casual Walking (3.0 mph)',
      category: 'Walking',
      met: 3.3,
      description: 'Casual daily walking, strolling or commuting.',
    ),
    CompendiumActivity(
      id: 'rucking_pack',
      code: '17165',
      name: 'Rucking (20-30 lb Pack)',
      category: 'Walking / Rucking',
      met: 6.0,
      description: 'Walking with a weighted pack/vest or moderate hill incline.',
    ),
    CompendiumActivity(
      id: 'running_moderate',
      code: '12020',
      name: 'Running (6.0 mph / 10 min mile)',
      category: 'Running',
      met: 9.8,
      description: 'Moderate steady-state endurance running.',
    ),
    CompendiumActivity(
      id: 'airdyne_assault_bike',
      code: '02010',
      name: 'Assault Bike / AirDyne (Moderate)',
      category: 'Cardio Equipment',
      met: 7.0,
      description: 'Moderate steady pace on fan bike or stationary cycle.',
    ),
    CompendiumActivity(
      id: 'airdyne_assault_sprints',
      code: '02015',
      name: 'Assault Bike HIIT Sprints',
      category: 'Cardio Equipment',
      met: 11.5,
      description: 'High-intensity interval sprints on assault/fan bike.',
    ),
    CompendiumActivity(
      id: 'concept2_rowing',
      code: '02070',
      name: 'Concept2 Rowing (150W Moderate)',
      category: 'Cardio Equipment',
      met: 7.0,
      description: 'Moderate ergo rowing machine pace.',
    ),
    CompendiumActivity(
      id: 'mobility_stretching',
      code: '02100',
      name: 'Dynamic Stretching & Mobility Flow',
      category: 'Mobility & Recovery',
      met: 2.8,
      description: 'Warmup mobility, hip opening, and dynamic stretching flows.',
    ),
    CompendiumActivity(
      id: 'olympic_weightlifting',
      code: '02050',
      name: 'Olympic Weightlifting (Snatch, C&J)',
      category: 'Resistance Training',
      met: 6.5,
      description: 'Explosive full-body Olympic lifts with intra-set rest.',
    ),
    CompendiumActivity(
      id: 'heavy_strength_lifting',
      code: '02052',
      name: 'Compound Squats & Pulls',
      category: 'Resistance Training',
      met: 6.0,
      description: 'Heavy compound strength lifting (Back/Front Squats, Deadlifts, Pulls).',
    ),
    CompendiumActivity(
      id: 'accessory_hypertrophy',
      code: '02054',
      name: 'Accessory Circuit & Hypertrophy',
      category: 'Resistance Training',
      met: 4.5,
      description: 'Accessory lifts, arms, shoulders, and core work.',
    ),
  ];

  /// Algorithm A: Standard Clinical Formula (assuming generic 1-MET = 3.5 mL O2/kg/min)
  /// Calories = Duration (min) * (MET * 3.5 * Weight_kg / 200)
  static int calculateStandardCalories({
    required double met,
    required double weightKg,
    required double durationMinutes,
  }) {
    if (durationMinutes <= 0 || weightKg <= 0 || met <= 0) return 0;
    final cal = durationMinutes * (met * 3.5 * (weightKg / 200.0));
    return cal.round();
  }

  /// Algorithm B: Personalized Katch-McArdle REE Formula
  /// Uses actual Lean Body Mass (LBM) to compute true Resting Energy Expenditure per minute:
  /// REE_min = (370 + 21.6 * LBM_kg) / 1440
  /// Calories = MET * REE_min * Duration_min
  static int calculateAdjustedCalories({
    required double met,
    required double leanBodyMassLb,
    required double durationMinutes,
  }) {
    if (durationMinutes <= 0 || leanBodyMassLb <= 0 || met <= 0) return 0;
    final lbmKg = leanBodyMassLb / 2.20462;
    final bmr = 370.0 + (21.6 * lbmKg);
    final reePerMin = bmr / 1440.0;
    final cal = met * reePerMin * durationMinutes;
    return cal.round();
  }

  /// Best-Effort Calorie Burner: Uses Algorithm B if LBM is known; falls back to Algorithm A
  static int calculateActivityCalories({
    required double met,
    required double durationMinutes,
    double? leanBodyMassLb,
    double fallbackWeightLb = 200.0,
  }) {
    if (leanBodyMassLb != null && leanBodyMassLb > 0) {
      return calculateAdjustedCalories(
        met: met,
        leanBodyMassLb: leanBodyMassLb,
        durationMinutes: durationMinutes,
      );
    } else {
      return calculateStandardCalories(
        met: met,
        weightKg: fallbackWeightLb / 2.20462,
        durationMinutes: durationMinutes,
      );
    }
  }

  /// ACSM Step-to-Calorie Estimation
  /// Standard stride length: ~2,150 steps per mile
  /// Calories / mile = 0.57 * Bodyweight_lb
  static (int calories, double miles) calculateStepsExpenditure({
    required int steps,
    required double weightLb,
    double? leanBodyMassLb,
  }) {
    if (steps <= 0) return (0, 0.0);
    final miles = (steps / 2150.0);
    final durationMins = miles * 17.0; // ~3.5 mph brisk pace = ~17 min/mile

    final calories = calculateActivityCalories(
      met: 3.8, // Brisk walk 3.5 mph
      durationMinutes: durationMins,
      leanBodyMassLb: leanBodyMassLb,
      fallbackWeightLb: weightLb,
    );

    return (calories, double.parse(miles.toStringAsFixed(2)));
  }

  /// Categorizes an exercise and maps to its distinct Compendium MET intensity
  static double getMetForLift(String liftId, String exerciseName) {
    final lId = liftId.toLowerCase();
    final eName = exerciseName.toLowerCase();
    if (lId.contains('accessories') || lId.contains('accessory') || lId.contains('warmup') || lId.contains('recovery')) {
      return 4.5;
    }
    if (eName.contains('split squat') || eName.contains('lunge') || eName.contains('hyperextension') || eName.contains('core') || eName.contains('ab')) {
      return 4.5;
    }
    final combined = '$lId $eName';
    if (combined.contains('pull') || combined.contains('deadlift') || combined.contains('squat')) {
      return 6.0; // Heavy compound squat/pull
    } else if (combined.contains('snatch') || combined.contains('clean') || combined.contains('jerk')) {
      return 6.5; // Explosive full-body Olympic lift
    } else if (combined.contains('press') || combined.contains('bench') || combined.contains('row')) {
      return 5.0; // Upper body press/pull
    } else {
      return 4.5; // Accessory / core / hypertrophy
    }
  }

  /// Analyzes an ExerciseLog and derives active duration, rest time, and calories burned
  static (double durationMins, int calories, double tonnageKg) calculateExerciseExpenditure({
    required ExerciseLog exercise,
    required double? leanBodyMassLb,
    required double fallbackWeightLb,
  }) {
    final completedSets = exercise.sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) return (0.0, 0, 0.0);

    final tonnage = exercise.totalVolumeKg;
    final met = getMetForLift(exercise.liftId, exercise.exerciseName);

    // Calculate duration: If timestamps are recorded on sets, compute real span
    double durationMins = 0.0;
    final timestamps = completedSets.map((s) => s.completedAt).whereType<DateTime>().toList();
    if (timestamps.length >= 2) {
      timestamps.sort();
      final spanSec = timestamps.last.difference(timestamps.first).inSeconds;
      durationMins = (spanSec / 60.0) + 1.0; // add 1 min for final set recovery
    } else {
      // Fallback: TUT + Rest model
      final reps = exercise.totalReps;
      final setsCount = completedSets.length;
      final restPerSet = (met >= 6.0) ? 2.5 : 1.5; // 2.5m rest for heavy/Oly, 1.5m for accessories
      final activeTutMins = (reps * 4.0) / 60.0;
      final restMins = max(0, setsCount - 1) * restPerSet;
      durationMins = activeTutMins + restMins;
    }

    final calories = calculateActivityCalories(
      met: met,
      durationMinutes: durationMins,
      leanBodyMassLb: leanBodyMassLb,
      fallbackWeightLb: fallbackWeightLb,
    );

    return (durationMins, calories, tonnage);
  }

  /// Analyzes a full WorkoutSession and generates a comprehensive expenditure summary
  static (int totalCalories, double totalDurationMins, double totalTonnageKg, Map<String, int> exerciseBreakdown) calculateSessionExpenditure({
    required WorkoutSession session,
    required BodyCompositionEntry? bodyComp,
    double fallbackWeightLb = 200.0,
  }) {
    final lbm = bodyComp?.leanBodyMassLb;
    final weight = bodyComp?.weightLb ?? fallbackWeightLb;

    int totalCalories = 0;
    double totalDuration = 0.0;
    double totalTonnage = 0.0;
    final Map<String, int> breakdown = {};

    for (final exercise in session.logs) {
      final (dur, cal, tonnage) = calculateExerciseExpenditure(
        exercise: exercise,
        leanBodyMassLb: lbm,
        fallbackWeightLb: weight,
      );
      totalCalories += cal;
      totalDuration += dur;
      totalTonnage += tonnage;
      breakdown[exercise.exerciseName] = cal;
    }

    // If session duration in seconds is explicitly provided and longer than exercise sum,
    // account for general gym active rest and warmup
    if (session.durationSeconds > 0) {
      final sessionMins = session.durationSeconds / 60.0;
      if (sessionMins > totalDuration) {
        final extraMins = sessionMins - totalDuration;
        final extraCal = calculateActivityCalories(
          met: 3.5, // Active transition / warmup rate
          durationMinutes: extraMins,
          leanBodyMassLb: lbm,
          fallbackWeightLb: weight,
        );
        totalCalories += extraCal;
        totalDuration = sessionMins;
      }
    }

    return (totalCalories, totalDuration, totalTonnage, breakdown);
  }

  /// Generates or updates an auto-synced DailyActivityEntry from a WorkoutSession
  static DailyActivityEntry createWodActivityEntry({
    required WorkoutSession session,
    required BodyCompositionEntry? bodyComp,
    DailyActivityEntry? existingEntry,
    double fallbackWeightLb = 200.0,
  }) {
    final (calories, durationMins, tonnage, breakdown) = calculateSessionExpenditure(
      session: session,
      bodyComp: bodyComp,
      fallbackWeightLb: fallbackWeightLb,
    );

    final tonnageLb = (tonnage * 2.20462).round();
    final name = 'Olympic Lifting (Day ${session.dayNumber}, Wk ${session.weekNumber})';

    return DailyActivityEntry(
      id: existingEntry?.id ?? 'wod_${session.id}',
      timestamp: session.date,
      date: "${session.date.year.toString().padLeft(4, '0')}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}",
      activityType: 'workout_wod',
      name: name,
      durationMinutes: durationMins.clamp(10.0, 180.0),
      metValue: 6.2, // Blended average for strength session
      caloriesBurned: calories,
      source: 'wod_auto_sync',
      sessionId: session.id,
      notes: '$tonnageLb lb tonnage • ${session.logs.length} movements',
      metadata: {
        'tonnageKg': tonnage,
        'tonnageLb': tonnageLb,
        'exerciseCount': session.logs.length,
        'breakdown': breakdown,
      },
    );
  }
}
