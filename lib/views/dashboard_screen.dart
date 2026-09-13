import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/views/breathing/wim_hof_setup_sheet.dart';
import 'package:oly/views/c25k/c25k_program_detail_screen.dart';
import 'package:oly/views/grip/dynamometer_entry_sheet.dart';
import 'package:oly/views/grip/grip_hang_detail_screen.dart';
import 'package:oly/views/lifts_screen.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'package:oly/views/nutrition/renpho_scanner_sheet.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/wod_hub_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/athlete_summary_overview_card.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/kinetic_counter.dart';
import 'package:oly/widgets/motion/oly_entry_reveal.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:oly/widgets/plate_modal.dart';
import 'package:oly/widgets/settings_modal.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const new({super.key, this.onNavigateTab});
  final void Function(int, [int?])? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final ProgramProvider program = Provider.of<ProgramProvider>(context);
    final LiftProvider lifts = Provider.of<LiftProvider>(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    GoalProvider? goalProvider;
    try {
      goalProvider = Provider.of<GoalProvider>(context);
    } catch (_) {}
    GripHangProvider? grip;
    try {
      grip = Provider.of<GripHangProvider>(context);
    } catch (_) {}
    C25kProvider? c25k;
    try {
      c25k = Provider.of<C25kProvider>(context);
    } catch (_) {}

    final DayTemplate currentDay = program.currentDayTemplate;
    final double olyTotalKg = lifts.getOlympicTotal();
    final double snatchKg = lifts.getLift('snatch')?.currentMax ?? 0.0;
    final double cjKg = lifts.getLift('clean_and_jerk')?.currentMax ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'OLY',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.pie_chart_outline_rounded,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Plate Calculator',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const PlateModal(initialWeightKg: 100),
              );
            },
          ),
          IconButton(
            icon: Icon(
              settings.isLbs ? Icons.scale_outlined : Icons.scale,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Toggle KG / LBS',
            onPressed: settings.toggleUnit,
          ),
          if (grip != null)
            IconButton(
              icon: const Icon(
                Icons.pan_tool_outlined,
                color: AppTheme.primaryAmber,
              ),
              tooltip: 'Home Grip Dynamometer',
              onPressed: () => DynamometerEntrySheet.show(context),
            ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Settings & Data Backup',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SettingsModal(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Athlete Daily Briefing / Summary Overview Card
              OlyEntryReveal(
                child: AthleteSummaryOverviewCard(
                  dayTemplate: currentDay,
                  onNavigateTab: onNavigateTab,
                ),
              ),
              const SizedBox(height: 16),

              // Active Cycle Banner
              OlyEntryReveal(
                index: 1,
                child: _buildCycleCard(context, program),
              ),
              const SizedBox(height: 16),

              // Active In-Progress Workout Resume Card (if present)
              if (program.hasActiveDraft) ...<Widget>[
                OlyEntryReveal(
                  index: 1,
                  child: _buildActiveSessionResumeCard(context, program),
                ),
                const SizedBox(height: 16),
              ],

              // Today's Scheduled Workout Card
              OlyEntryReveal(
                index: 2,
                child: _buildTodayWorkoutCard(context, program, currentDay, goalProvider),
              ),
              const SizedBox(height: 16),

              // CrossFit & Hero Conditioning Hub Showcase
              OlyEntryReveal(
                index: 3,
                child: _buildCrossfitWodShowcaseCard(context),
              ),
              const SizedBox(height: 16),

              // Olympic Total & Primary PRs
              OlyEntryReveal(
                index: 4,
                child: _buildOlympicTotalCard(
                  context,
                  program,
                  lifts,
                  settings,
                  snatchKg,
                  cjKg,
                  olyTotalKg,
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions (Warmup & Plate Loader)
              OlyEntryReveal(
                index: 5,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Guided Warm-Up',
                        subtitle: 'Row, DROMs & Barbell',
                        icon: Icons.directions_run,
                        accentColor: AppTheme.secondaryCyan,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  WarmupSessionScreen(dayTemplate: currentDay),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Plate Loader',
                        subtitle: 'Bar & Bumper Calc',
                        icon: Icons.pie_chart,
                        accentColor: AppTheme.primaryAmber,
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                const PlateModal(initialWeightKg: 100),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Nutrition & Renpho Scale Scanner Row
              OlyEntryReveal(
                index: 6,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Calorie & Macros',
                        subtitle: 'Daily Food & Fuel',
                        icon: Icons.restaurant,
                        accentColor: AppTheme.primaryAmber,
                        onTap: () {
                          if (onNavigateTab != null) {
                            onNavigateTab!(2); // Switch to FUEL tab
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const NutritionDashboardScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Renpho Scale Scan',
                        subtitle: 'LBM, BF% & BMR',
                        icon: Icons.document_scanner,
                        accentColor: AppTheme.successGreen,
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const RenphoScannerSheet(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Wim Hof Breathwork & Analytics Row
              OlyEntryReveal(
                index: 7,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Wim Hof Breath',
                        subtitle: 'Oxygen & Retention',
                        icon: Icons.air,
                        accentColor: AppTheme.secondaryCyan,
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const WimHofSetupSheet(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Breath Analytics',
                        subtitle: 'PRs & Hold Trends',
                        icon: Icons.insights_outlined,
                        accentColor: AppTheme.primaryAmber,
                        onTap: () {
                          if (onNavigateTab != null) {
                            onNavigateTab!(3, 3); // Analytics Tab -> Breathwork
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AnalyticsScreen(initialTabIndex: 3),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Goals & Extensible Tracks Row (Grip/Hang & C25K Running)
              if (grip != null && c25k != null) ...<Widget>[
                OlyEntryReveal(
                  index: 8,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Grip & Hang Protocol',
                          subtitle: '${grip.bestTwoHandSeconds > 0 ? (grip.bestTwoHandSeconds ~/ 60).toString() : '0'}m PR • 5m/2m Goals',
                          icon: Icons.pan_tool_outlined,
                          accentColor: AppTheme.primaryAmber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const GripHangDetailScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'C25K Running Engine',
                          subtitle: 'Week ${c25k.currentWeek} Day ${c25k.currentDay} Up Next',
                          icon: Icons.directions_run,
                          accentColor: AppTheme.secondaryCyan,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const C25kProgramDetailScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Routine Explorer
              OlyEntryReveal(
                index: 8,
                child: _buildActionCard(
                  context,
                  title: 'Routine Explorer',
                  subtitle: 'Preview Any Periodization Week & Day',
                  icon: Icons.explore,
                  accentColor: AppTheme.secondaryCyan,
                  onTap: () => _showRoutineExplorerSheet(context, program),
                ),
              ),
              const SizedBox(height: 16),

              // Ratio Balance Glance
              OlyEntryReveal(
                index: 9,
                child: _buildRatioGlanceCard(context, lifts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleCard(BuildContext context, ProgramProvider program) {
    final bool isRetest = program.isRetestWeek;
    final String weekTitle = isRetest
        ? 'Week 5: 1RM RETEST WEEK'
        : 'Week ${program.currentWeek} of 4: ${program.currentWeek == 4
              ? "Deload & Prep"
              : program.currentWeek == 3
              ? "Peak Loading"
              : "Base Loading"}';

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      ambientGlowColor: isRetest ? Colors.redAccent : AppTheme.primaryAmber,
      gradient: LinearGradient(
        colors: isRetest
            ? <Color>[const Color(0xFF5A0000), const Color(0xFF1E0000)]
            : <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'CYCLE ${program.currentCycle} PERIODIZATION',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isRetest ? Colors.redAccent : AppTheme.primaryAmber,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isRetest ? Colors.redAccent : AppTheme.primaryAmber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isRetest ? 'RETEST ACTIVE' : 'W${program.currentWeek}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weekTitle,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRetest
                ? 'Retest 1RM baselines to reset your training percentages'
                : (program.currentWeek % 2 != 0
                    ? 'Snatch Emphasis (2:1 Alternating Focus)'
                    : 'Clean & Jerk Emphasis (1:2 Alternating Focus)'),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isRetest ? Colors.redAccent : AppTheme.primaryAmber,
            ),
          ),
          const SizedBox(height: 12),
          // Week selection pills (Week 1..4 + Week 5 Retest)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final int w = index + 1;
              final bool isSelected = program.currentWeek == w;
              final String label = w == 5 ? 'Retest' : 'W$w';

              return OlyPressable(
                onPressed: () => program.selectWeek(w),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (w == 5 ? Colors.redAccent : AppTheme.primaryAmber)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          OlyPressable(
            onPressed: () => _showRoutineExplorerSheet(context, program),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.explore,
                    color: AppTheme.secondaryCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Explore Any Week or Routine (Preview Mode)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionResumeCard(
    BuildContext context,
    ProgramProvider program,
  ) {
    final ActiveWorkoutDraft draft = program.activeDraft!;
    final DayTemplate matchingDay = program.days.firstWhere(
      (d) => d.dayNumber == draft.dayNumber,
      orElse: () => program.currentDayTemplate,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2C1E0A), Color(0xFF19191D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryAmber, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryAmber.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WORKOUT IN PROGRESS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  draft.totalSetsCount > 0
                      ? '${draft.totalCompletedSets}/${draft.totalSetsCount} Sets Done'
                      : '${draft.totalCompletedDynamic}/${draft.totalDynamicCount} Items Done',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            draft.dayTitle,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: draft.completionPercentage,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryAmber,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => WorkoutSessionScreen(
                          dayTemplate: matchingDay,
                          initialDraft: draft,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: Text(
                    'Resume Session',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    _confirmDiscardDraft(context, program);
                  },
                  child: Text(
                    'Discard',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDiscardDraft(BuildContext context, ProgramProvider program) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: <Widget>[
            const Icon(Icons.delete_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Discard Session Draft?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to discard your in-progress workout session? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await program.clearActiveDraft();
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('In-progress workout draft discarded.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWorkoutCard(
    BuildContext context,
    ProgramProvider program,
    DayTemplate day,
    GoalProvider? goalProvider,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      ambientGlowColor: day.isActiveRecovery
          ? AppTheme.secondaryCyan
          : AppTheme.primaryAmber,
      ambientGlowRadius: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "TODAY'S WORKOUT",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (day.isActiveRecovery)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active Recovery',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Day Selector Override Pills
          Row(
            children: program.days.map((d) {
              final bool isSelected = program.currentDay == d.dayNumber;
              String label;
              if (d.dayNumber == 1) {
                label = 'Day 1';
              } else if (d.dayNumber == 2) {
                label = 'Recovery';
              } else if (d.dayNumber == 3) {
                label = 'Day 2';
              } else if (d.dayNumber == 4) {
                label = 'Recovery';
              } else if (d.dayNumber == 5) {
                label = 'Day 3';
              } else {
                label = 'Recovery';
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => program.selectDay(d.dayNumber),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (d.isActiveRecovery
                                ? AppTheme.secondaryCyan
                                : AppTheme.primaryAmber)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : AppTheme.borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.black
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            day.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Composed Goal Track Indicators
          Builder(
            builder: (context) {
              if (goalProvider == null) {
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _buildGoalTrackChip(
                      icon: Icons.fitness_center,
                      label: 'Olympic Lifting',
                      color: AppTheme.primaryAmber,
                    ),
                  ],
                );
              }

              final DailySessionPlan dailyPlan = goalProvider.getDailyPlanForDate(
                date: DateTime.now(),
                currentOlyDay: day,
              );

              if (dailyPlan.blocks.isEmpty) {
                return _buildGoalTrackChip(
                  icon: Icons.hotel,
                  label: 'Rest & Recovery Day',
                  color: AppTheme.textSecondary,
                );
              }

              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: dailyPlan.blocks.map((block) {
                  IconData icon = Icons.fitness_center;
                  Color color = AppTheme.primaryAmber;
                  if (block.type == SessionBlockType.hang) {
                    icon = Icons.pan_tool_outlined;
                    color = AppTheme.primaryAmber;
                  } else if (block.type == SessionBlockType.c25k) {
                    icon = Icons.directions_run;
                    color = AppTheme.secondaryCyan;
                  }
                  return _buildGoalTrackChip(
                    icon: icon,
                    label: block.title,
                    color: color,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (day.isActiveRecovery) {
                      final LiftProvider lifts = Provider.of<LiftProvider>(
                        context,
                        listen: false,
                      );
                      final RecoveryProvider rec =
                          Provider.of<RecoveryProvider>(context, listen: false);
                      final GeneratedRecoveryRoutine routine = rec.getRoutine(
                        ratioAnalyses: lifts.getRatioAnalysis(),
                        lastSession: program.sessions.isNotEmpty
                            ? program.sessions.first
                            : null,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RecoverySessionScreen(
                            routine: routine,
                            isPreviewMode: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => WorkoutSessionScreen(
                            dayTemplate: day,
                            isPreviewMode: true,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.explore,
                    color: AppTheme.secondaryCyan,
                    size: 18,
                  ),
                  label: Text(
                    'Preview Day',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    side: const BorderSide(color: AppTheme.secondaryCyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (day.isActiveRecovery) {
                      final LiftProvider lifts = Provider.of<LiftProvider>(
                        context,
                        listen: false,
                      );
                      final RecoveryProvider rec =
                          Provider.of<RecoveryProvider>(context, listen: false);
                      final GeneratedRecoveryRoutine routine = rec.getRoutine(
                        ratioAnalyses: lifts.getRatioAnalysis(),
                        lastSession: program.sessions.isNotEmpty
                            ? program.sessions.first
                            : null,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              RecoverySessionScreen(routine: routine),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              WorkoutSessionScreen(dayTemplate: day),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  label: Text(
                    'Start Live',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: day.isActiveRecovery
                        ? AppTheme.secondaryCyan
                        : AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTrackChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOlympicTotalCard(
    BuildContext context,
    ProgramProvider program,
    LiftProvider lifts,
    SettingsProvider settings,
    double snatch,
    double cj,
    double total,
  ) {
    return OlyPressable(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const LiftsScreen(),
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        ambientGlowColor: AppTheme.primaryAmber,
        ambientGlowRadius: 1.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Hero(
              tag: 'olympic_total_hero_header',
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'OLYMPIC TOTAL',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    KineticCounter(
                      value: settings.toDisplayWeight(total),
                      suffix: ' ${settings.unitLabel}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Snatch 1RM',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    KineticCounter(
                      value: settings.toDisplayWeight(snatch),
                      suffix: ' ${settings.unitLabel}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 35, color: AppTheme.borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Clean & Jerk 1RM',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      KineticCounter(
                        value: settings.toDisplayWeight(cj),
                        suffix: ' ${settings.unitLabel}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.fitness_center,
                    color: AppTheme.secondaryCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lifetime Weight Moved',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                program.formatTotalTons(isLbs: settings.isLbs),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryCyan,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return OlyPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        ambientGlowColor: accentColor,
        ambientGlowRadius: 0.9,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossfitWodShowcaseCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      ambientGlowColor: AppTheme.primaryAmber,
      ambientGlowRadius: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CROSSFIT & HERO WODS',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '248 HEROES',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryAmber,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Official Memorial Biographies & Interactive Benchmark Trackers',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tribute workouts honoring fallen military and first responders, plus classic benchmarks (Cindy, Fran, DT, Grace, Murph).',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildWodChip(context, 'Cindy (AMRAP 20m)'),
              _buildWodChip(context, 'Murph (Memorial)'),
              _buildWodChip(context, 'DT (5 Rds Rx)'),
              _buildWodChip(context, 'Fran (21-15-9)'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OlyPressable(
              borderRadius: BorderRadius.circular(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const WodHubScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(
                  'Explore WOD Hub & Memorials',
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
    );
  }

  Widget _buildWodChip(BuildContext context, String label) {
    return OlyPressable(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const WodHubScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bolt_rounded,
              color: AppTheme.primaryAmber,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioGlanceCard(BuildContext context, LiftProvider lifts) {
    final List<LiftRatioAnalysis> ratios = lifts.getRatioAnalysis();
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      ambientGlowColor: AppTheme.secondaryCyan,
      ambientGlowRadius: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'LIFT RATIO BALANCE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryAmber,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ratios.isEmpty)
            Text(
              'No lift data yet.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            )
          else
            ...ratios.take(2).map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${r.lift.name} / ${r.anchorLift.name}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(r.actualRatio * 100).toStringAsFixed(0)}% (Target: ${(r.targetRatio * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: r.status == 'Balanced'
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showRoutineExplorerSheet(
    BuildContext context,
    ProgramProvider program,
  ) {
    int selectedWeek = program.currentWeek;
    int selectedDayNum = program.currentDay;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final List<DayTemplate> previewDays =
                ProgramCycle.getBuiltInProgram(week: selectedWeek);
            final DayTemplate day = previewDays.firstWhere(
              (d) => d.dayNumber == selectedDayNum,
              orElse: () => previewDays.first,
            );

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Routine Explorer',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Text(
                        'Preview any week and routine day without affecting your history or analytics.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Select Week Pills
                      Text(
                        'SELECT WEEK TO PREVIEW:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (i) {
                          final int w = i + 1;
                          final bool isSel = selectedWeek == w;
                          return InkWell(
                            onTap: () => setStateModal(() => selectedWeek = w),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppTheme.secondaryCyan
                                    : AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? Colors.white
                                      : AppTheme.borderColor,
                                ),
                              ),
                              child: Text(
                                w == 5 ? 'Retest' : 'W$w',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: isSel
                                      ? Colors.black
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Select Day Pills
                      Text(
                        'SELECT ROUTINE DAY:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: previewDays.map((d) {
                          final bool isSel = selectedDayNum == d.dayNumber;
                          String label;
                          if (d.dayNumber == 1) {
                            label = 'Day 1';
                          } else if (d.dayNumber == 2) {
                            label = 'Recovery';
                          } else if (d.dayNumber == 3) {
                            label = 'Day 2';
                          } else if (d.dayNumber == 4) {
                            label = 'Recovery';
                          } else if (d.dayNumber == 5) {
                            label = 'Day 3';
                          } else {
                            label = 'Recovery';
                          }

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setStateModal(
                                () => selectedDayNum = d.dayNumber,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (d.isActiveRecovery
                                            ? AppTheme.secondaryCyan
                                            : AppTheme.primaryAmber)
                                      : AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.white
                                        : AppTheme.borderColor,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel
                                          ? Colors.black
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Selected Routine Overview
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              day.title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons: Preview vs Live
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (day.isActiveRecovery) {
                                  final LiftProvider lifts =
                                      Provider.of<LiftProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final RecoveryProvider rec =
                                      Provider.of<RecoveryProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final GeneratedRecoveryRoutine routine = rec
                                      .getRoutine(
                                        ratioAnalyses: lifts.getRatioAnalysis(),
                                        lastSession: program.sessions.isNotEmpty
                                            ? program.sessions.first
                                            : null,
                                      );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => RecoverySessionScreen(
                                        routine: routine,
                                        isPreviewMode: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => WorkoutSessionScreen(
                                        dayTemplate: day,
                                        isPreviewMode: true,
                                        previewWeek: selectedWeek,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.explore,
                                color: AppTheme.secondaryCyan,
                              ),
                              label: Text(
                                'Preview',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryCyan,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                side: const BorderSide(
                                  color: AppTheme.secondaryCyan,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (day.isActiveRecovery) {
                                  final LiftProvider lifts =
                                      Provider.of<LiftProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final RecoveryProvider rec =
                                      Provider.of<RecoveryProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final GeneratedRecoveryRoutine routine = rec
                                      .getRoutine(
                                        ratioAnalyses: lifts.getRatioAnalysis(),
                                        lastSession: program.sessions.isNotEmpty
                                            ? program.sessions.first
                                            : null,
                                      );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => RecoverySessionScreen(
                                        routine: routine,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => WorkoutSessionScreen(
                                        dayTemplate: day,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                              ),
                              label: Text(
                                'Start Live Log',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                backgroundColor: day.isActiveRecovery
                                    ? AppTheme.secondaryCyan
                                    : AppTheme.primaryAmber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
