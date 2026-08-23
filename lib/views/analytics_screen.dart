import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ratio_chart_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final program = Provider.of<ProgramProvider>(context);
    final lifts = Provider.of<LiftProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final sessions = program.sessions;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Analytics & Session Logs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryAmber,
            labelColor: AppTheme.primaryAmber,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Session History'),
              Tab(text: 'Ratio Balance'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // TAB 1: Session History Log + Tonnage Summary
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tonnage Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.surfaceElevated, AppTheme.surfaceCard],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL WEIGHT MOVED',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: AppTheme.primaryAmber,
                                ),
                              ),
                              const Icon(Icons.fitness_center, color: AppTheme.primaryAmber, size: 22),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            program.formatTotalTons(isLbs: settings.isLbs),
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatBadge('Workouts', '${sessions.length}'),
                              _buildStatBadge('Sets', '${program.totalCompletedSets}'),
                              _buildStatBadge('Reps', '${program.totalCompletedReps}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'COMPLETED WORKOUT LOGS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    sessions.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.history, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No completed workout sessions yet.',
                                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final dateStr = DateFormat('EEE, MMM d, yyyy • h:mm a').format(session.date);

                              final sessionVolStr = settings.isLbs
                                  ? '${(session.totalVolumeKg * 2.20462).toStringAsFixed(0)} lbs'
                                  : '${session.totalVolumeKg.toStringAsFixed(0)} kg';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
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
                                          'Cycle ${session.cycleNumber} • Week ${session.weekNumber} Day ${session.dayNumber}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryAmber,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceElevated,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.borderColor),
                                          ),
                                          child: Text(
                                            sessionVolStr,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: AppTheme.borderColor),
                                    const SizedBox(height: 4),
                                    ...session.logs.map((log) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              log.exerciseName,
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                            Text(
                                              '${log.sets.length} sets completed',
                                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),

            // TAB 2: Ratio Balance
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RatioChartWidget(ratios: lifts.getRatioAnalysis()),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAmber,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
