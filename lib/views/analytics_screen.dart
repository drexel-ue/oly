import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/breathing_analytics_tab.dart';
import 'package:oly/widgets/ratio_chart_widget.dart';
import 'package:oly/widgets/wod_history_sheet.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProgramProvider program = Provider.of<ProgramProvider>(context);
    final LiftProvider lifts = Provider.of<LiftProvider>(context);
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);

    final List<WorkoutSession> sessions = program.sessions;
    final Map<String, List<AccessoryLog>> groupedAccessories =
        recovery.groupedAccessoryProgressions;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Analytics & Session Logs',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryAmber,
            labelColor: AppTheme.primaryAmber,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: <Widget>[
              Tab(text: 'Workouts'),
              Tab(text: 'WODs & Heroes'),
              Tab(text: 'Accessories'),
              Tab(text: 'Breathwork'),
              Tab(text: 'Ratios'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: <Widget>[
              // TAB 1: Session History Log + Tonnage Summary
              _buildWorkoutSessionsTab(program, sessions, settings),

              // TAB 2: CrossFit WODs & Hero Benchmark Progress
              _buildWodAnalyticsTab(context, recovery),

              // TAB 3: Accessory Weight Progressions
              _buildAccessoryProgressionsTab(
                groupedAccessories,
                recovery,
                settings,
              ),

              // TAB 4: Wim Hof Breathwork Retention Analytics
              const BreathingAnalyticsTab(),

              // TAB 5: Ratio Balance Chart
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
    List<WorkoutSession> sessions,
    SettingsProvider settings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Tonnage Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'TOTAL WEIGHT MOVED',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    const Icon(
                      Icons.fitness_center,
                      color: AppTheme.primaryAmber,
                      size: 22,
                    ),
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
                  children: <Widget>[
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

          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No completed workout sessions yet.',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (BuildContext context, int index) {
                final WorkoutSession session = sessions[index];
                final String dateStr = DateFormat('EEE, MMM d, yyyy • h:mm a')
                    .format(session.date);

                final String sessionVolStr = settings.isLbs
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
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Cycle ${session.cycleNumber} • Week ${session.weekNumber} Day ${session.dayNumber}',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
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
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 4),
                      ...session.logs.map((ExerciseLog log) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  log.exerciseName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${log.sets.length} sets completed',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
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
    final String unit = settings.unitLabel.toUpperCase();
    final int totalEntries = recovery.accessoryLogs.length;
    final int totalSets = recovery.accessoryLogs.fold(
      0,
      (int sum, AccessoryLog e) => sum + e.sets,
    );
    final int totalReps = recovery.accessoryLogs.fold(
      0,
      (int sum, AccessoryLog e) => sum + (e.sets * e.reps),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Accessory Overview Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'ACCESSORY WEIGHT PROGRESSIONS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const Icon(
                      Icons.trending_up,
                      color: AppTheme.accentBlue,
                      size: 22,
                    ),
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
                  children: <Widget>[
                    _buildStatBadge(
                      'Logged Sets',
                      '$totalSets',
                      color: AppTheme.accentBlue,
                    ),
                    _buildStatBadge(
                      'Logged Reps',
                      '$totalReps',
                      color: AppTheme.accentBlue,
                    ),
                    _buildStatBadge(
                      'Entries',
                      '$totalEntries',
                      color: AppTheme.accentBlue,
                    ),
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
                children: <Widget>[
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No accessory weights logged yet.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete accessory sets in Guided Warm-Ups or Active Recovery routines to automatically record weight progressions and PRs!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...groupedAccessories.entries.map((
              MapEntry<String, List<AccessoryLog>> entry,
            ) {
              final String name = entry.key;
              final List<AccessoryLog> logs =
                  entry.value; // chronological order
              final double pb = logs
                  .map((AccessoryLog l) => l.weightKg)
                  .reduce((double a, double b) => a > b ? a : b);
              final AccessoryLog latest = logs.last;
              final AccessoryLog first = logs.first;
              final double deltaKg = latest.weightKg - first.weightKg;
              final double displayPb = settings.toDisplayWeight(pb);
              final double displayLatest = settings.toDisplayWeight(
                latest.weightKg,
              );
              final double displayDelta = settings.toDisplayWeight(
                deltaKg.abs(),
              );

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
                  children: <Widget>[
                    // Title & Current / PB Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
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
                                '${logs.length} sessions logged • ${logs.fold(0, (int sum, AccessoryLog l) => sum + l.sets)} total sets',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // PB Tag
                        if (pb > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryAmber.withValues(
                                  alpha: 0.5,
                                ),
                              ),
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
                      children: <Widget>[
                        Text(
                          'Latest: ${latest.weightKg > 0 ? '${displayLatest.toStringAsFixed(1)} $unit' : 'BW'}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (deltaKg > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 12,
                                  color: Colors.greenAccent,
                                ),
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
                        children: logs.map((AccessoryLog log) {
                          final String dateStr = DateFormat('MMM d')
                              .format(log.date);
                          final double w = settings.toDisplayWeight(
                            log.weightKg,
                          );
                          final bool isPb = log.weightKg >= pb && pb > 0;

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPb
                                  ? AppTheme.primaryAmber.withValues(
                                      alpha: 0.12,
                                    )
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isPb
                                    ? AppTheme.primaryAmber.withValues(
                                        alpha: 0.4,
                                      )
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  log.weightKg > 0
                                      ? '${w.toStringAsFixed(1)}$unit'
                                      : 'BW',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isPb
                                        ? AppTheme.primaryAmber
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${log.sets}×${log.reps}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: AppTheme.textSecondary,
                                  ),
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

  Widget _buildWodAnalyticsTab(
    BuildContext context,
    RecoveryProvider recovery,
  ) {
    final int completedHeroCount = recovery.totalCompletedHeroWodsCount;
    final double heroPercent = (completedHeroCount / 248.0).clamp(0.0, 1.0);
    final Map<String, BenchmarkWodLog> allPrsMap = recovery.getAllBenchmarkPersonalRecords();
    final List<BenchmarkWodLog> prsList = allPrsMap.values.toList()
      ..sort((BenchmarkWodLog a, BenchmarkWodLog b) => a.wodName.compareTo(b.wodName));
    final List<BenchmarkWodLog> recentLogs = recovery.benchmarkWodLogs.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Hero WOD Progress Odyssey Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'CROSSFIT HERO WOD ODYSSEY',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    const Icon(
                      Icons.military_tech_rounded,
                      color: AppTheme.primaryAmber,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedHeroCount / 248 Hero WODs',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: heroPercent,
                    backgroundColor: AppTheme.darkBackground,
                    color: AppTheme.primaryAmber,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(heroPercent * 100).toStringAsFixed(1)}% completed • ${248 - completedHeroCount} remaining tributes',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildStatBadge('Total WODs', '${recovery.totalAllWodCompletionsCount}'),
                    _buildStatBadge('Hero Tributes', '$completedHeroCount'),
                    _buildStatBadge('All-Time PRs', '${allPrsMap.length}', color: Colors.greenAccent),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PR Leaderboard Section
          Text(
            'BENCHMARK PERSONAL RECORDS',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.primaryAmber,
            ),
          ),
          const SizedBox(height: 12),

          if (prsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceElevated),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 36,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Benchmark PRs logged yet',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete and log workouts from the WOD Hub to start tracking your records!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...prsList.map((BenchmarkWodLog pr) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      WodHistorySheet.show(
                        context,
                        wodId: pr.wodId,
                        wodName: pr.wodName,
                        wodFormat: pr.format,
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.greenAccent,
                        size: 18,
                      ),
                    ),
                    title: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            pr.wodName,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: pr.isRx
                                ? Colors.greenAccent.withValues(alpha: 0.15)
                                : Colors.orangeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pr.isRx ? 'Rx' : 'Scaled',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: pr.isRx ? Colors.greenAccent : Colors.orangeAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'PR: ${pr.scoreDisplay}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.greenAccent,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(pr.date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }),

          if (recentLogs.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'RECENT WOD SESSIONS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primaryAmber,
              ),
            ),
            const SizedBox(height: 12),
            ...recentLogs.map((BenchmarkWodLog log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceElevated),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      WodHistorySheet.show(
                        context,
                        wodId: log.wodId,
                        wodName: log.wodName,
                        wodFormat: log.format,
                      );
                    },
                  title: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          log.wodName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (log.isPr)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.emoji_events_rounded, size: 10, color: Colors.greenAccent),
                              const SizedBox(width: 2),
                              Text(
                                'PR',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${log.scoreDisplay} (${log.isRx ? "Rx" : "Scaled"})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(log.date),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, {Color? color}) {
    final Color themeColor = color ?? AppTheme.primaryAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: <Widget>[
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
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
