import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/wim_hof_setup_sheet.dart';
import 'package:provider/provider.dart';

class BreathingAnalyticsTab extends StatefulWidget {
  const BreathingAnalyticsTab({super.key});

  @override
  State<BreathingAnalyticsTab> createState() => _BreathingAnalyticsTabState();
}

class _BreathingAnalyticsTabState extends State<BreathingAnalyticsTab> {
  bool _showMaxTrend = true;

  @override
  Widget build(BuildContext context) {
    final BreathingProvider breathingProvider =
        Provider.of<BreathingProvider>(context);
    final List<BreathingSessionLog> sessions = breathingProvider.sessions;

    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Hero KPI Overview Card
          _buildHeroOverviewCard(breathingProvider),
          const SizedBox(height: 18),

          // Retention Trend Line Chart
          _buildTrendChartCard(breathingProvider),
          const SizedBox(height: 18),

          // Round Progression Average Breakdown
          _buildRoundAveragesCard(breathingProvider),
          const SizedBox(height: 24),

          // Historical Logs Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'BREATHWORK SESSION HISTORY',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${sessions.length} Completed',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.secondaryCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Session History List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            itemBuilder: (BuildContext context, int index) {
              final BreathingSessionLog session = sessions[index];
              return _buildSessionLogCard(context, session, breathingProvider);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.air,
                size: 56,
                color: AppTheme.secondaryCyan,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Breathwork Sessions Yet',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first guided Wim Hof session to track breath hold progression, oxygenation, and personal records.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const WimHofSetupSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'START FIRST BREATHWORK FLOW',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroOverviewCard(BreathingProvider breathing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.secondaryCyan.withValues(alpha: 0.35),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.secondaryCyan.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'ALL-TIME BREATHWORK TOTALS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.secondaryCyan,
                ),
              ),
              const Icon(Icons.air, color: AppTheme.secondaryCyan, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            breathing.formattedAllTimeTotalRetention,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Total Time in Retention / Breath Hold',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildMiniStat(
                  'MAX PR HOLD',
                  breathing.formattedAllTimeMaxHold,
                  AppTheme.primaryAmber,
                  Icons.emoji_events_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  'AVG HOLD',
                  breathing.formattedAverageHold,
                  AppTheme.secondaryCyan,
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  'ROUNDS',
                  '${breathing.totalRoundsCompleted}',
                  AppTheme.successGreen,
                  Icons.repeat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard(BreathingProvider breathing) {
    final List<BreathingSessionLog> chronological =
        List<BreathingSessionLog>.from(breathing.sessions)
          ..sort((BreathingSessionLog a, BreathingSessionLog b) =>
              a.date.compareTo(b.date));

    final List<FlSpot> spots = _showMaxTrend
        ? breathing.maxHoldTrendSpots
        : breathing.avgHoldTrendSpots;

    return Container(
      padding: const EdgeInsets.all(18),
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
                'RETENTION DURATION PROGRESSION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => setState(() => _showMaxTrend = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _showMaxTrend
                              ? AppTheme.primaryAmber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Max Hold',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _showMaxTrend
                                ? Colors.black
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showMaxTrend = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: !_showMaxTrend
                              ? AppTheme.secondaryCyan
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Avg Hold',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: !_showMaxTrend
                                ? Colors.black
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: AppTheme.borderColor.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int sec = value.toInt();
                        final int m = sec ~/ 60;
                        final int s = sec % 60;
                        return Text(
                          '$m:${s.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index >= 0 && index < chronological.length) {
                          return Text(
                            DateFormat('M/d').format(chronological[index].date),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _showMaxTrend
                        ? AppTheme.primaryAmber
                        : AppTheme.secondaryCyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (_showMaxTrend
                              ? AppTheme.primaryAmber
                              : AppTheme.secondaryCyan)
                          .withValues(alpha: 0.15),
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

  Widget _buildRoundAveragesCard(BreathingProvider breathing) {
    final Map<int, double> roundAverages = breathing.roundAveragesMap;
    if (roundAverages.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<int> sortedRounds = roundAverages.keys.toList()..sort();
    final double highestRoundAvg = roundAverages.values.isNotEmpty
        ? roundAverages.values.reduce((double a, double b) => a > b ? a : b)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.bar_chart,
                color: AppTheme.secondaryCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'AVERAGE HOLD DURATION BY ROUND',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sortedRounds.map((int roundNum) {
            final double avgSeconds = roundAverages[roundNum] ?? 0.0;
            final double ratio = highestRoundAvg > 0
                ? (avgSeconds / highestRoundAvg).clamp(0.0, 1.0)
                : 0.0;
            final int sec = avgSeconds.round();
            final String formatted =
                '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Round $roundNum',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 12,
                        backgroundColor: AppTheme.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    child: Text(
                      formatted,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                      textAlign: TextAlign.right,
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

  Widget _buildSessionLogCard(
    BuildContext context,
    BreathingSessionLog session,
    BreathingProvider breathing,
  ) {
    final String dateStr =
        DateFormat('EEE, MMM d, yyyy • h:mm a').format(session.date);

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
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.air,
                      color: AppTheme.secondaryCyan,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${session.rounds.length} Rounds',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                color: AppTheme.surfaceElevated,
                onSelected: (String val) {
                  if (val == 'delete') {
                    _confirmDelete(context, session, breathing);
                  }
                },
                itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Log',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
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
          const SizedBox(height: 12),

          // Round pills row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: session.rounds.map((BreathingRoundLog r) {
              final bool isMax =
                  r.retentionSeconds == session.maxHoldSeconds &&
                      session.maxHoldSeconds > 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMax
                      ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMax
                        ? AppTheme.primaryAmber
                        : AppTheme.borderColor,
                  ),
                ),
                child: Text(
                  'R${r.roundNumber}: ${r.formattedRetentionTime}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMax
                        ? AppTheme.primaryAmber
                        : AppTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),

          if (session.notes != null && session.notes!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '“${session.notes}”',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    BreathingSessionLog session,
    BreathingProvider breathing,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text(
          'Delete Breathwork Log?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this ${session.rounds.length}-round session log?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await breathing.deleteSession(session.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
