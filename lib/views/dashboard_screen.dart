import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/recovery_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/active_recovery_card.dart';
import '../widgets/plate_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/warmup_sheet.dart';
import 'recovery_session_screen.dart';
import 'warmup_session_screen.dart';
import 'workout_session_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final program = Provider.of<ProgramProvider>(context);
    final lifts = Provider.of<LiftProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final currentDay = program.currentDayTemplate;
    final olyTotalKg = lifts.getOlympicTotal();
    final snatchKg = lifts.getLift('snatch')?.currentMax ?? 0.0;
    final cjKg = lifts.getLift('clean_and_jerk')?.currentMax ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.black, size: 20),
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
        actions: [
          IconButton(
            icon: Icon(
              settings.isLbs ? Icons.scale_outlined : Icons.scale,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Toggle KG / LBS',
            onPressed: () => settings.toggleUnit(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryAmber),
            tooltip: 'Settings & Data Backup',
            onPressed: () {
              showModalBottomSheet(
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
          children: [
            // Active Cycle Banner
            _buildCycleCard(context, program),
            const SizedBox(height: 16),

            // Today's Scheduled Workout Card
            _buildTodayWorkoutCard(context, program, currentDay),
            const SizedBox(height: 16),

            // Active Recovery & Mobility Routine
            const ActiveRecoveryCard(),
            const SizedBox(height: 16),

            // Olympic Total & Primary PRs
            _buildOlympicTotalCard(context, program, lifts, settings, snatchKg, cjKg, olyTotalKg),
            const SizedBox(height: 16),

            // Quick Actions (Warmup & Plate Loader)
            Row(
              children: [
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
                        MaterialPageRoute(
                          builder: (_) => WarmupSessionScreen(dayTemplate: currentDay),
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
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PlateModal(initialWeightKg: 100.0),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ratio Balance Glance
            _buildRatioGlanceCard(context, lifts),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCycleCard(BuildContext context, ProgramProvider program) {
    final isRetest = program.isRetestWeek;
    final weekTitle = isRetest
        ? 'Week 5: 1RM RETEST WEEK'
        : 'Week ${program.currentWeek} of 4: ${program.currentWeek == 4 ? "Deload & Prep" : program.currentWeek == 3 ? "Peak Loading" : "Base Loading"}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRetest
              ? [const Color(0xFF8E0000), const Color(0xFF2A0000)]
              : [AppTheme.surfaceElevated, AppTheme.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRetest ? Colors.redAccent : AppTheme.primaryAmber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 12),
          // Week selection pills (Week 1..4 + Week 5 Retest)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final w = index + 1;
              final isSelected = program.currentWeek == w;
              final label = w == 5 ? 'Retest' : 'W$w';

              return InkWell(
                onTap: () => program.selectWeek(w),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          InkWell(
            onTap: () => _showRoutineExplorerSheet(context, program),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondaryCyan.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore, color: AppTheme.secondaryCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Explore Any Week or Routine (Preview Mode)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryCyan,
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

  Widget _buildTodayWorkoutCard(BuildContext context, ProgramProvider program, day) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY\'S WORKOUT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (day.isActiveRecovery)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withOpacity(0.2),
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
              final isSelected = program.currentDay == d.dayNumber;
              String label;
              if (d.dayNumber == 1) {
                label = 'Day 1';
              } else if (d.dayNumber == 2) {
                label = 'Recovery';
              } else if (d.dayNumber == 3) {
                label = 'Day 2';
              } else if (d.dayNumber == 4) {
                label = 'Recovery';
              } else {
                label = 'Day 3';
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => program.selectDay(d.dayNumber),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (d.isActiveRecovery ? AppTheme.secondaryCyan : AppTheme.primaryAmber)
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
                          color: isSelected ? Colors.black : AppTheme.textSecondary,
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
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (day.isActiveRecovery) {
                      final lifts = Provider.of<LiftProvider>(context, listen: false);
                      final rec = Provider.of<RecoveryProvider>(context, listen: false);
                      final routine = rec.getRoutine(
                        ratioAnalyses: lifts.getRatioAnalysis(),
                        lastSession: program.sessions.isNotEmpty ? program.sessions.first : null,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecoverySessionScreen(
                            routine: routine,
                            isPreviewMode: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutSessionScreen(
                            dayTemplate: day,
                            isPreviewMode: true,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.explore, color: AppTheme.secondaryCyan, size: 18),
                  label: Text(
                    'Preview Day',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    side: const BorderSide(color: AppTheme.secondaryCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (day.isActiveRecovery) {
                      final lifts = Provider.of<LiftProvider>(context, listen: false);
                      final rec = Provider.of<RecoveryProvider>(context, listen: false);
                      final routine = rec.getRoutine(
                        ratioAnalyses: lifts.getRatioAnalysis(),
                        lastSession: program.sessions.isNotEmpty ? program.sessions.first : null,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecoverySessionScreen(routine: routine),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutSessionScreen(dayTemplate: day),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                  label: Text(
                    'Start Live',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: day.isActiveRecovery ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOlympicTotalCard(BuildContext context, ProgramProvider program, LiftProvider lifts, SettingsProvider settings,
      double snatch, double cj, double total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OLYMPIC TOTAL',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                settings.formatWeight(total),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Snatch 1RM', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      settings.formatWeight(snatch),
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
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
                    children: [
                      Text('Clean & Jerk 1RM', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        settings.formatWeight(cj),
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
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
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center, color: AppTheme.secondaryCyan, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Lifetime Weight Moved',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
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
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color accentColor,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioGlanceCard(BuildContext context, LiftProvider lifts) {
    final ratios = lifts.getRatioAnalysis();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIFT RATIO BALANCE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(Icons.analytics_outlined, color: AppTheme.primaryAmber, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          if (ratios.isEmpty)
            Text('No lift data yet.', style: GoogleFonts.inter(color: AppTheme.textSecondary))
          else
            ...ratios.take(2).map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${r.lift.name} / ${r.anchorLift.name}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
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
            }).toList(),
        ],
      ),
    );
  }

  void _showRoutineExplorerSheet(BuildContext context, ProgramProvider program) {
    int selectedWeek = program.currentWeek;
    int selectedDayNum = program.currentDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final day = program.days.firstWhere(
              (d) => d.dayNumber == selectedDayNum,
              orElse: () => program.days.first,
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
                    children: [
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
                        children: [
                          Text(
                            'Routine Explorer',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Text(
                        'Preview any week and routine day without affecting your history or analytics.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Select Week Pills
                      Text('SELECT WEEK TO PREVIEW:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (i) {
                          final w = i + 1;
                          final isSel = selectedWeek == w;
                          return InkWell(
                            onTap: () => setStateModal(() => selectedWeek = w),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.secondaryCyan : AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSel ? Colors.white : AppTheme.borderColor),
                              ),
                              child: Text(
                                w == 5 ? 'Retest' : 'W$w',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.black : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Select Day Pills
                      Text('SELECT ROUTINE DAY:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: program.days.map((d) {
                          final isSel = selectedDayNum == d.dayNumber;
                          String label;
                          if (d.dayNumber == 1) {
                            label = 'Day 1';
                          } else if (d.dayNumber == 2) {
                            label = 'Recovery';
                          } else if (d.dayNumber == 3) {
                            label = 'Day 2';
                          } else if (d.dayNumber == 4) {
                            label = 'Recovery';
                          } else {
                            label = 'Day 3';
                          }

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setStateModal(() => selectedDayNum = d.dayNumber),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (d.isActiveRecovery ? AppTheme.secondaryCyan : AppTheme.primaryAmber)
                                      : AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? Colors.white : AppTheme.borderColor),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.black : AppTheme.textSecondary,
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
                          children: [
                            Text(day.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(day.subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons: Preview vs Live
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (day.isActiveRecovery) {
                                  final lifts = Provider.of<LiftProvider>(context, listen: false);
                                  final rec = Provider.of<RecoveryProvider>(context, listen: false);
                                  final routine = rec.getRoutine(
                                    ratioAnalyses: lifts.getRatioAnalysis(),
                                    lastSession: program.sessions.isNotEmpty ? program.sessions.first : null,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecoverySessionScreen(
                                        routine: routine,
                                        isPreviewMode: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutSessionScreen(
                                        dayTemplate: day,
                                        isPreviewMode: true,
                                        previewWeek: selectedWeek,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.explore, color: AppTheme.secondaryCyan),
                              label: Text('Preview', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                side: const BorderSide(color: AppTheme.secondaryCyan),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (day.isActiveRecovery) {
                                  final lifts = Provider.of<LiftProvider>(context, listen: false);
                                  final rec = Provider.of<RecoveryProvider>(context, listen: false);
                                  final routine = rec.getRoutine(
                                    ratioAnalyses: lifts.getRatioAnalysis(),
                                    lastSession: program.sessions.isNotEmpty ? program.sessions.first : null,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecoverySessionScreen(routine: routine),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutSessionScreen(
                                        dayTemplate: day,
                                        isPreviewMode: false,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.play_arrow, color: Colors.black),
                              label: Text('Start Live Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                backgroundColor: day.isActiveRecovery ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
