import 'dart:math';

import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';

class CompendiumActivity {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.met,
    required this.description,
  });
  final String id;
  final String code;
  final String name;
  final String category;
  final double met;
  final String description;
}

class ActivityExpenditureService {
  /// Curated Compendium of Physical Activities catalog
  static const List<CompendiumActivity> compendiumCatalog =
      <CompendiumActivity>[
        CompendiumActivity(
          id: 'walking_brisk',
          code: '17151',
          name: 'Brisk Walk (3.5 mph)',
          category: 'Walking',
          met: 3.8,
          description:
              'Standard walking at a moderate-to-brisk pace on flat ground.',
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
          met: 6,
          description:
              'Walking with a weighted pack/vest or moderate hill incline.',
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
          met: 7,
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
          met: 7,
          description: 'Moderate ergo rowing machine pace.',
        ),
        CompendiumActivity(
          id: 'mobility_stretching',
          code: '02100',
          name: 'Dynamic Stretching & Mobility Flow',
          category: 'Mobility & Recovery',
          met: 2.8,
          description:
              'Warmup mobility, hip opening, and dynamic stretching flows.',
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
          met: 6,
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
    if (durationMinutes <= 0 || weightKg <= 0 || met <= 0) {
      return 0;
    }
    final double cal = durationMinutes * (met * 3.5 * (weightKg / 200.0));
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
    if (durationMinutes <= 0 || leanBodyMassLb <= 0 || met <= 0) {
      return 0;
    }
    final double lbmKg = leanBodyMassLb / 2.20462;
    final double bmr = 370.0 + (21.6 * lbmKg);
    final double reePerMin = bmr / 1440.0;
    final double cal = met * reePerMin * durationMinutes;
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
    if (steps <= 0) {
      return (0, 0.0);
    }
    final double miles = steps / 2150.0;
    final double durationMins =
        miles * 17.0; // ~3.5 mph brisk pace = ~17 min/mile

    final int calories = calculateActivityCalories(
      met: 3.8, // Brisk walk 3.5 mph
      durationMinutes: durationMins,
      leanBodyMassLb: leanBodyMassLb,
      fallbackWeightLb: weightLb,
    );

    return (calories, double.parse(miles.toStringAsFixed(2)));
  }

  /// Categorizes an exercise and maps to its distinct Compendium MET intensity
  static double getMetForLift(
    String liftId,
    String exerciseName, {
    TrainingTrack? track,
  }) {
    final String lId = liftId.toLowerCase().trim();
    final String eName = exerciseName.toLowerCase().trim();
    final String combined = '$lId $eName';

    // 0. Accessory and generic recovery sets
    if (lId.contains('accessories') ||
        lId.contains('accessory') ||
        lId.contains('recovery') ||
        lId.contains('warmup')) {
      return 4.5;
    }

    // 1. Mobility, active recovery, static/dynamic stretching (Compendium 02100: 2.8 - 3.5 MET)
    if (combined.contains('stretch') ||
        combined.contains('elephant_walk') ||
        combined.contains('hip_90_90') ||
        combined.contains('butterfly') ||
        combined.contains('banded_hip') ||
        combined.contains('couch_stretch') ||
        lId.contains('mobility')) {
      return 3;
    }

    // 2. High-intensity explosive Olympic lifts (Compendium 02050: 6.5 MET)
    // Snatch, Clean & Jerk, Power variants, Jerks, Snatch Balance
    if (combined.contains('snatch') ||
        combined.contains('clean') ||
        combined.contains('jerk')) {
      // Olympic pulls (snatch pull, clean pull, high pull)
      if (combined.contains('pull')) {
        return 6; // Heavy compound pull
      }
      return 6.5; // Explosive full-body Olympic lift
    }

    // 3. Heavy compound barbell power lifts (Compendium 02052: 5.5 - 6.0 MET)
    if (combined.contains('back_squat') ||
        combined.contains('front_squat') ||
        (combined.contains('deadlift') &&
            !combined.contains('romanian') &&
            !combined.contains('rdl')) ||
        (combined.contains('squat') &&
            !combined.contains('split squat') &&
            !combined.contains('bulgarian'))) {
      return 6; // Heavy compound squat/deadlift
    }

    // 4. Upper body compound & moderate compound lifts (Compendium 02054: 5.0 MET)
    // Bench press, OHP, incline press, rows, lat pulldowns, Romanian deadlifts, split squats
    if (combined.contains('bench') ||
        combined.contains('press') ||
        combined.contains('row') ||
        combined.contains('pulldown') ||
        combined.contains('pullover') ||
        combined.contains('pushup') ||
        combined.contains('dip') ||
        combined.contains('rdl') ||
        combined.contains('romanian_deadlift') ||
        combined.contains('hip_thrust') ||
        combined.contains('leg_press') ||
        combined.contains('split squat') ||
        combined.contains('lunge')) {
      return 5; // Upper body press/pull / moderate compound
    }

    // 5. Bodybuilding isolation, core, and arm accessories (Compendium 02054: 4.5 MET)
    if (combined.contains('curl') ||
        combined.contains('pushdown') ||
        combined.contains('tricep') ||
        combined.contains('extension') ||
        combined.contains('raise') ||
        combined.contains('fly') ||
        combined.contains('delt') ||
        combined.contains('rotations') ||
        combined.contains('landmine') ||
        combined.contains('pallof') ||
        combined.contains('hyperextension') ||
        combined.contains('crunch') ||
        combined.contains('ab') ||
        combined.contains('core') ||
        combined.contains('rollout') ||
        combined.contains('tibialis') ||
        combined.contains('miracle_grow') ||
        lId.startsWith('bb_')) {
      return 4.5; // Accessory / core / hypertrophy
    }

    // Track-based fallbacks
    if (track == TrainingTrack.bodybuilding) {
      return 5;
    }
    if (track == TrainingTrack.mobility) {
      return 3;
    }

    return 4.5;
  }

  /// Analyzes an ExerciseLog and derives active duration, rest time, and calories burned
  static (double durationMins, int calories, double tonnageKg)
  calculateExerciseExpenditure({
    required ExerciseLog exercise,
    required double? leanBodyMassLb,
    required double fallbackWeightLb,
    TrainingTrack? track,
  }) {
    final List<CompletedSet> completedSets = exercise.sets
        .where((s) => s.isCompleted)
        .toList();
    if (completedSets.isEmpty) {
      return (0.0, 0, 0.0);
    }

    final double tonnage = exercise.totalVolumeKg;
    final double met = getMetForLift(
      exercise.liftId,
      exercise.exerciseName,
      track: track,
    );

    // Calculate duration: If timestamps are recorded on sets, compute real span
    double durationMins = 0;
    final List<DateTime> timestamps = completedSets
        .map((s) => s.completedAt)
        .whereType<DateTime>()
        .toList();
    if (timestamps.length >= 2) {
      timestamps.sort();
      final int spanSec = timestamps.last
          .difference(timestamps.first)
          .inSeconds;
      durationMins = (spanSec / 60.0) + 1.0; // add 1 min for final set recovery
    } else {
      // Fallback: TUT + Rest model
      final int reps = exercise.totalReps;
      final int setsCount = completedSets.length;
      final double restPerSet = (met >= 6.0)
          ? 2.5
          : 1.5; // 2.5m rest for heavy/Oly, 1.5m for accessories
      final double activeTutMins = (reps * 4.0) / 60.0;
      final double restMins = max(0, setsCount - 1) * restPerSet;
      durationMins = activeTutMins + restMins;
    }

    final int calories = calculateActivityCalories(
      met: met,
      durationMinutes: durationMins,
      leanBodyMassLb: leanBodyMassLb,
      fallbackWeightLb: fallbackWeightLb,
    );

    return (durationMins, calories, tonnage);
  }

  /// Calculates the blended average MET for a full WorkoutSession
  static double calculateSessionMet(WorkoutSession session) {
    if (session.logs.isEmpty) {
      switch (session.inferredTrack) {
        case TrainingTrack.bodybuilding:
          return 5;
        case TrainingTrack.mobility:
          return 3;
        case TrainingTrack.olympic:
          return 6.2;
      }
    }
    double totalDuration = 0;
    double weightedMetSum = 0;

    for (final ExerciseLog exercise in session.logs) {
      final List<CompletedSet> completedSets =
          exercise.sets.where((s) => s.isCompleted).toList();
      if (completedSets.isEmpty) {
        continue;
      }

      final double met = getMetForLift(
        exercise.liftId,
        exercise.exerciseName,
        track: session.inferredTrack,
      );
      final int reps = exercise.totalReps;
      final int setsCount = completedSets.length;
      final double restPerSet = (met >= 6.0) ? 2.5 : 1.5;
      final double dur =
          ((reps * 4.0) / 60.0) + (max(0, setsCount - 1) * restPerSet);
      totalDuration += dur;
      weightedMetSum += dur * met;
    }

    if (totalDuration <= 0) {
      switch (session.inferredTrack) {
        case TrainingTrack.bodybuilding:
          return 5;
        case TrainingTrack.mobility:
          return 3;
        case TrainingTrack.olympic:
          return 6.2;
      }
    }

    final double blended = weightedMetSum / totalDuration;
    return double.parse(blended.toStringAsFixed(1));
  }

  /// Returns user-facing activity name matching the completed track and day/phase
  static String formatSessionActivityName(WorkoutSession session) {
    switch (session.inferredTrack) {
      case TrainingTrack.bodybuilding:
        return 'Bodybuilding (${session.displayTitle})';
      case TrainingTrack.mobility:
        return 'Mobility (${session.displayTitle})';
      case TrainingTrack.olympic:
        return 'Olympic Lifting (${session.displayTitle})';
    }
  }

  /// Analyzes a full WorkoutSession and generates a comprehensive expenditure summary
  static (
    int totalCalories,
    double totalDurationMins,
    double totalTonnageKg,
    Map<String, int> exerciseBreakdown,
    double sessionMet,
  )
  calculateSessionExpenditure({
    required WorkoutSession session,
    required BodyCompositionEntry? bodyComp,
    double fallbackWeightLb = 200.0,
  }) {
    final double? lbm = bodyComp?.leanBodyMassLb;
    final double weight = bodyComp?.weightLb ?? fallbackWeightLb;

    int totalCalories = 0;
    double totalDuration = 0;
    double totalTonnage = 0;
    final Map<String, int> breakdown = <String, int>{};
    double metDurationSum = 0;

    for (final ExerciseLog exercise in session.logs) {
      final (
        double dur,
        int cal,
        double tonnage,
      ) = calculateExerciseExpenditure(
        exercise: exercise,
        leanBodyMassLb: lbm,
        fallbackWeightLb: weight,
        track: session.inferredTrack,
      );
      if (dur > 0) {
        final double met = getMetForLift(
          exercise.liftId,
          exercise.exerciseName,
          track: session.inferredTrack,
        );
        totalCalories += cal;
        totalDuration += dur;
        totalTonnage += tonnage;
        metDurationSum += dur * met;
        breakdown[exercise.exerciseName] = cal;
      }
    }

    final double exerciseDurSum = totalDuration;
    final double rawMet = exerciseDurSum > 0
        ? (metDurationSum / exerciseDurSum)
        : (session.inferredTrack == TrainingTrack.bodybuilding
            ? 5
            : (session.inferredTrack == TrainingTrack.mobility ? 3 : 6.2));
    final double sessionMet = double.parse(rawMet.toStringAsFixed(1));

    // If session duration in seconds is explicitly provided and longer than exercise sum,
    // account for general gym active rest and warmup
    if (session.durationSeconds > 0) {
      final double sessionMins = session.durationSeconds / 60.0;
      if (sessionMins > totalDuration) {
        final double extraMins = sessionMins - totalDuration;
        const double transitionMet = 3.5; // Active transition / warmup rate
        final int extraCal = calculateActivityCalories(
          met: transitionMet,
          durationMinutes: extraMins,
          leanBodyMassLb: lbm,
          fallbackWeightLb: weight,
        );
        totalCalories += extraCal;
        totalDuration = sessionMins;
      }
    }

    return (
      totalCalories,
      totalDuration,
      totalTonnage,
      breakdown,
      sessionMet,
    );
  }

  /// Generates or updates an auto-synced DailyActivityEntry from a WorkoutSession
  static DailyActivityEntry createWodActivityEntry({
    required WorkoutSession session,
    required BodyCompositionEntry? bodyComp,
    DailyActivityEntry? existingEntry,
    double fallbackWeightLb = 200.0,
  }) {
    final (
      int calories,
      double durationMins,
      double tonnage,
      Map<String, int> breakdown,
      double sessionMet,
    ) = calculateSessionExpenditure(
      session: session,
      bodyComp: bodyComp,
      fallbackWeightLb: fallbackWeightLb,
    );

    final int tonnageLb = (tonnage * 2.20462).round();
    final String name = formatSessionActivityName(session);

    return DailyActivityEntry(
      id: existingEntry?.id ?? 'wod_${session.id}',
      timestamp: session.date,
      date:
          "${session.date.year.toString().padLeft(4, '0')}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}",
      activityType: 'workout_wod',
      name: name,
      durationMinutes: durationMins.clamp(10.0, 180.0),
      metValue: sessionMet,
      caloriesBurned: calories,
      source: 'wod_auto_sync',
      sessionId: session.id,
      notes: '$tonnageLb lb tonnage • ${session.logs.length} movements',
      metadata: <String, dynamic>{
        'tonnageKg': tonnage,
        'tonnageLb': tonnageLb,
        'exerciseCount': session.logs.length,
        'breakdown': breakdown,
        'track': session.inferredTrack.name,
        'sessionMet': sessionMet,
      },
    );
  }
}
