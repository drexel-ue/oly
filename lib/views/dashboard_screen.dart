import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/plate_modal.dart';
import '../widgets/warmup_sheet.dart';
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
        ],
      ),
      body: SingleChildScrollView(
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

            // Olympic Total & Primary PRs
            _buildOlympicTotalCard(context, lifts, settings, snatchKg, cjKg, olyTotalKg),
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
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const WarmupSheet(),
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
          const SizedBox(height: 6),
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
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutSessionScreen(dayTemplate: day),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
              label: Text(
                'Start ${day.title.split(':').first}',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOlympicTotalCard(BuildContext context, LiftProvider lifts, SettingsProvider settings,
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
}
