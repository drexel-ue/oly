import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/accessory_log.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/recovery_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ratio_chart_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final program = Provider.of<ProgramProvider>(context);
    final lifts = Provider.of<LiftProvider>(context);
    final recovery = Provider.of<RecoveryProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final sessions = program.sessions;
    final groupedAccessories = recovery.groupedAccessoryProgressions;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Analytics & Session Logs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryAmber,
            labelColor: AppTheme.primaryAmber,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Workouts'),
              Tab(text: 'Accessories'),
              Tab(text: 'Ratios'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // TAB 1: Session History Log + Tonnage Summary
              _buildWorkoutSessionsTab(program, sessions, settings),

              // TAB 2: Accessory Weight Progressions
              _buildAccessoryProgressionsTab(groupedAccessories, recovery, settings),

              // TAB 3: Ratio Balance Chart
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

  Widget _buildWorkoutSessionsTab(
    ProgramProvider program,
    List<dynamic> sessions,
    SettingsProvider settings,
  ) {
    return SingleChildScrollView(
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
                                  Expanded(
                                    child: Text(
                                      log.exerciseName,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
    );
  }

  Widget _buildAccessoryProgressionsTab(
    Map<String, List<AccessoryLog>> groupedAccessories,
    RecoveryProvider recovery,
    SettingsProvider settings,
  ) {
    final unit = settings.unitLabel.toUpperCase();
    final totalEntries = recovery.accessoryLogs.length;
    final totalSets = recovery.accessoryLogs.fold(0, (sum, e) => sum + e.sets);
    final totalReps = recovery.accessoryLogs.fold(0, (sum, e) => sum + (e.sets * e.reps));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accessory Overview Banner
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
              border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACCESSORY WEIGHT PROGRESSIONS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const Icon(Icons.trending_up, color: AppTheme.accentBlue, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${groupedAccessories.keys.length} Movements Tracked',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBadge('Logged Sets', '$totalSets', color: AppTheme.accentBlue),
                    _buildStatBadge('Logged Reps', '$totalReps', color: AppTheme.accentBlue),
                    _buildStatBadge('Entries', '$totalEntries', color: AppTheme.accentBlue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'TRACKED ACCESSORY MOVEMENTS',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          if (groupedAccessories.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.fitness_center, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No accessory weights logged yet.',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete accessory sets in Guided Warm-Ups or Active Recovery routines to automatically record weight progressions and PRs!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...groupedAccessories.entries.map((entry) {
              final name = entry.key;
              final logs = entry.value; // chronological order
              final pb = logs.map((l) => l.weightKg).reduce((a, b) => a > b ? a : b);
              final latest = logs.last;
              final first = logs.first;
              final deltaKg = latest.weightKg - first.weightKg;
              final displayPb = settings.toDisplayWeight(pb);
              final displayLatest = settings.toDisplayWeight(latest.weightKg);
              final displayDelta = settings.toDisplayWeight(deltaKg.abs());

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Current / PB Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${logs.length} sessions logged • ${logs.fold(0, (sum, l) => sum + l.sets)} total sets',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // PB Tag
                        if (pb > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'PB: ${displayPb.toStringAsFixed(1)} $unit',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progression summary row
                    Row(
                      children: [
                        Text(
                          'Latest: ${latest.weightKg > 0 ? '${displayLatest.toStringAsFixed(1)} $unit' : 'BW'}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (deltaKg > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_upward, size: 12, color: Colors.greenAccent),
                                const SizedBox(width: 2),
                                Text(
                                  '+${displayDelta.toStringAsFixed(1)} $unit',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal progression chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: logs.map((log) {
                          final dateStr = DateFormat('MMM d').format(log.date);
                          final w = settings.toDisplayWeight(log.weightKg);
                          final isPb = log.weightKg >= pb && pb > 0;

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPb
                                  ? AppTheme.primaryAmber.withValues(alpha: 0.12)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isPb
                                    ? AppTheme.primaryAmber.withValues(alpha: 0.4)
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  log.weightKg > 0 ? '${w.toStringAsFixed(1)}$unit' : 'BW',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isPb ? AppTheme.primaryAmber : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${log.sets}×${log.reps}',
                                  style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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

  Widget _buildStatBadge(String label, String value, {Color? color}) {
    final themeColor = color ?? AppTheme.primaryAmber;
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
              color: themeColor,
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
