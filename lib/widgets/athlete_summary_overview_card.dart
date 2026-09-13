import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/motion/animated_barbell_loader.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:oly/widgets/motion/pulsing_glow.dart';
import 'package:oly/widgets/plate_modal.dart';
import 'package:provider/provider.dart';

/// The high-level Athlete Daily Briefing / Summary Overview Card that sits
/// prominently at the top of the TRAIN domain view, unifying physiological
/// readiness, today's workout prescription, and the multi-pillar micro-HUD.
class AthleteSummaryOverviewCard extends StatelessWidget {
  const new({
    required this.dayTemplate,
    super.key,
    this.onNavigateTab,
  });

  final DayTemplate dayTemplate;
  final void Function(int, [int?])? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final ProgramProvider program = Provider.of<ProgramProvider>(context);
    final InjuryProvider injuries = Provider.of<InjuryProvider>(context);
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context);
    final BreathingProvider breathing = Provider.of<BreathingProvider>(context);
    final LiftProvider lifts = Provider.of<LiftProvider>(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);

    final List<InjuryRecord> activeInjuries = injuries.activeInjuries;

    // Calculate holistic readiness
    int readinessScore = 95;
    if (activeInjuries.isNotEmpty) {
      final int deduction = activeInjuries.fold<int>(
        0,
        (sum, i) => sum + (i.painScale * 4),
      );
      readinessScore = (readinessScore - deduction).clamp(35, 100);
    }

    final Color readinessColor = readinessScore >= 85
        ? AppTheme.successGreen
        : (readinessScore >= 65 ? AppTheme.primaryAmber : Colors.redAccent);

    final String todayDateStr =
        DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase();

    final bool hasDraft = program.hasActiveDraft;
    final ActiveWorkoutDraft? draft = program.activeDraft;
    final DayTemplate activeDay = hasDraft
        ? program.days.firstWhere(
            (d) => d.dayNumber == draft!.dayNumber,
            orElse: () => dayTemplate,
          )
        : dayTemplate;

    final int movementCount = activeDay.phases.fold<int>(
      0,
      (sum, p) => sum + p.exercises.length,
    );

    double peakLoadKg = 100;
    if (!activeDay.isActiveRecovery) {
      if (activeDay.title.toLowerCase().contains('snatch')) {
        final double max = lifts.getLift('snatch')?.currentMax ?? 100.0;
        peakLoadKg = (max * 0.85).roundToDouble();
      } else if (activeDay.title.toLowerCase().contains('clean')) {
        final double max = lifts.getLift('clean_and_jerk')?.currentMax ?? 120.0;
        peakLoadKg = (max * 0.85).roundToDouble();
      } else {
        final double max = lifts.getLift('back_squat')?.currentMax ?? 140.0;
        peakLoadKg = (max * 0.80).roundToDouble();
      }
      if (peakLoadKg <= 0) {
        peakLoadKg = 100.0;
      }
    }

    return PulsingGlow(
      glowColor: AppTheme.primaryAmber,
      isPulsing: hasDraft,
      borderRadius: BorderRadius.circular(24),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        ambientGlowColor:
            hasDraft ? AppTheme.primaryAmber : AppTheme.primaryAmber.withValues(alpha: 0.4),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: Date & Readiness Pill
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        todayDateStr,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  OlyPressable(
                    onPressed: () => onNavigateTab?.call(1), // Jump to RECOVER tab
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: readinessColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: readinessColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: readinessColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$readinessScore% READINESS',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: readinessColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderColor),

          // Main Training Mission Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (hasDraft) ...<Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 14,
                          color: AppTheme.primaryAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'IN-PROGRESS SESSION DETECTED',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Text(
                  'Week ${program.currentWeek}, Day ${activeDay.dayNumber} • ${activeDay.title}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeDay.isActiveRecovery
                      ? 'Active Mobility & Dynamic Recovery Routine • ~25 min'
                      : '$movementCount Movements • Peak Load 85% 1RM • Est. 60 min',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),

                // Adaptive Injury Notification
                if (activeInjuries.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.warningOrange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppTheme.warningOrange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active joint strains: ${activeInjuries.map((e) => e.name).join(', ')}. Scale accordingly.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Dynamic Loaded Olympic Barbell Visualizer
                if (!activeDay.isActiveRecovery) ...<Widget>[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PlateModal(initialWeightKg: peakLoadKg),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.fitness_center,
                                    size: 13,
                                    color: AppTheme.primaryAmber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TARGET BARBELL LOAD',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: AppTheme.primaryAmber,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${settings.toDisplayWeight(peakLoadKg).toStringAsFixed(1)} ${settings.unitLabel.toUpperCase()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                            AnimatedBarbellLoader(
                            targetWeight: settings.toDisplayWeight(peakLoadKg),
                            barWeight: settings.barWeight,
                            collarWeight: settings.collarWeight,
                            isLbs: settings.isLbs,
                            height: 90,
                            showBreakdownChips: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Action Buttons Row
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: OlyPressable(
                        borderRadius: BorderRadius.circular(14),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => WorkoutSessionScreen(
                                  dayTemplate: activeDay,
                                  initialDraft: draft,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            hasDraft
                                ? Icons.play_arrow_rounded
                                : Icons.flash_on_rounded,
                            size: 20,
                          ),
                          label: Text(
                            hasDraft ? 'RESUME SESSION' : 'START WORKOUT',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OlyPressable(
                        borderRadius: BorderRadius.circular(14),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    WarmupSessionScreen(dayTemplate: activeDay),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.directions_run_rounded,
                            size: 18,
                            color: AppTheme.primaryAmber,
                          ),
                          label: Text(
                            'Warm-Up',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Micro-HUD Multi-Pillar Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: <Widget>[
                // Fuel Micro HUD
                Expanded(
                  child: InkWell(
                    onTap: () => onNavigateTab?.call(2), // FUEL Tab
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.restaurant_rounded,
                                size: 13,
                                color: AppTheme.primaryAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FUEL',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryAmber,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${nutrition.currentDayLog.totalCalories.toStringAsFixed(0)} / ${nutrition.currentDayLog.targetCalories.toStringAsFixed(0)} kcal',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Protein: ${nutrition.currentDayLog.totalProtein.toStringAsFixed(0)}g',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  height: 36,
                  width: 1,
                  color: AppTheme.borderColor,
                ),

                // Recover / Breath Micro HUD
                Expanded(
                  child: InkWell(
                    onTap: () => onNavigateTab?.call(1), // RECOVER Tab
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.air_rounded,
                                size: 13,
                                color: AppTheme.secondaryCyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BREATH',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.secondaryCyan,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            breathing.todayCompletedRounds > 0
                                ? '${breathing.todayCompletedRounds} Rds Done'
                                : 'Pending Today',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            activeInjuries.isEmpty
                                ? 'Joints: Clear'
                                : '${activeInjuries.length} Joint Strain',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: activeInjuries.isEmpty
                                  ? AppTheme.successGreen
                                  : AppTheme.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
