import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/log_wod_score_sheet.dart';
import 'package:provider/provider.dart';

/// Modal bottom sheet displaying historical completion attempts & PR for a specific WOD.
class WodHistorySheet extends StatelessWidget {
  const WodHistorySheet({
    required this.wodId,
    required this.wodName,
    this.wodFormat,
    this.wod,
    this.heroWod,
    super.key,
  });

  final String wodId;
  final String wodName;
  final String? wodFormat;
  final WodDefinition? wod;
  final CrossfitHeroWod? heroWod;

  static void show(
    BuildContext context, {
    required String wodId,
    required String wodName,
    String? wodFormat,
    WodDefinition? wod,
    CrossfitHeroWod? heroWod,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WodHistorySheet(
        wodId: wodId,
        wodName: wodName,
        wodFormat: wodFormat,
        wod: wod,
        heroWod: heroWod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final List<BenchmarkWodLog> history = recovery.getBenchmarkWodHistory(wodId);
    final BenchmarkWodLog? pr = recovery.getBenchmarkWodPersonalRecord(wodId);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.primaryAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$wodName History',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${history.length} ${history.length == 1 ? "attempt" : "attempts"} recorded',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // PR Highlight Card (if any)
          if (pr != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppTheme.primaryAmber.withValues(alpha: 0.2),
                      AppTheme.surfaceCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryAmber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ALL-TIME PERSONAL BEST',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: <Widget>[
                              Text(
                                pr.scoreDisplay,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: pr.isRx
                                      ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                                      : AppTheme.secondaryCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pr.isRx ? 'Rx' : 'Scaled',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: pr.isRx ? AppTheme.primaryAmber : AppTheme.secondaryCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat.yMMMd().format(pr.date),
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ATTEMPT HISTORY (${history.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),

          // History List
          Flexible(
            child: history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.fitness_center_rounded, size: 40, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No recorded attempts yet for $wodName.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Log your first score to start tracking your PR progression.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext ctx, int index) {
                      final BenchmarkWodLog log = history[index];
                      return _buildAttemptCard(ctx, log, recovery);
                    },
                  ),
          ),

          // Bottom Action: Log Attempt
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(top: BorderSide(color: AppTheme.surfaceElevated)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    LogWodScoreSheet.show(
                      context,
                      wod: wod,
                      heroWod: heroWod,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 20),
                  label: Text(
                    '+ LOG NEW SCORE',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptCard(BuildContext context, BenchmarkWodLog log, RecoveryProvider recovery) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: log.isPr
              ? AppTheme.primaryAmber.withValues(alpha: 0.4)
              : AppTheme.surfaceElevated,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Score
              Text(
                log.scoreDisplay,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              // Rx / Scaled
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: log.isRx
                      ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                      : AppTheme.secondaryCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.isRx ? 'Rx' : 'Scaled',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: log.isRx ? AppTheme.primaryAmber : AppTheme.secondaryCyan,
                  ),
                ),
              ),
              if (log.isPr) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.emoji_events, size: 12, color: Colors.greenAccent),
                      const SizedBox(width: 3),
                      Text(
                        'PR',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                DateFormat.yMMMd().format(log.date),
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textSecondary),
                onPressed: () => _confirmDelete(context, log, recovery),
                tooltip: 'Delete Log',
              ),
            ],
          ),
          if (log.scalingModifications != null && log.scalingModifications!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Mods: ${log.scalingModifications}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.secondaryCyan),
            ),
          ],
          if (log.rpe != null || log.notes != null) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                if (log.rpe != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'RPE ${log.rpe}/10',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (log.notes != null && log.notes!.isNotEmpty) ...<Widget>[
                  Expanded(
                    child: Text(
                      log.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BenchmarkWodLog log, RecoveryProvider recovery) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text(
            'Delete Log?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          content: Text(
            'Are you sure you want to remove this attempt (${log.scoreDisplay}) from your history?',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await recovery.deleteBenchmarkWodLog(log.id);
                HapticFeedback.mediumImpact();
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
