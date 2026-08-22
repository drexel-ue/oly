import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ratio_chart_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final program = Provider.of<ProgramProvider>(context);
    final lifts = Provider.of<LiftProvider>(context);

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
            // TAB 1: Session History Log
            sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No completed workout sessions yet.',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final dateStr = DateFormat('EEE, MMM d, yyyy • h:mm a').format(session.date);

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
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
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
                            }).toList(),
                          ],
                        ),
                      );
                    },
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
}
