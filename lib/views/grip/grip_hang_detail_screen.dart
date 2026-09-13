import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/grip/dynamometer_entry_sheet.dart';
import 'package:oly/views/grip/hang_session_block_widget.dart';
import 'package:oly/widgets/motion/oly_entry_reveal.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class GripHangDetailScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final GripHangProvider grip = Provider.of<GripHangProvider>(context);
    ActiveSessionProvider? activeSession;
    try {
      activeSession =
          Provider.of<ActiveSessionProvider>(context, listen: false);
    } catch (_) {}

    return PopScope(
      canPop: !grip.isHangTimerRunning,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        grip.stopHangTimer();
        if (activeSession?.sessionType == SessionType.hang &&
            activeSession?.isMinimized == false) {
          activeSession?.endSession();
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (grip.isHangTimerRunning) {
                grip.stopHangTimer();
              }
              if (activeSession?.sessionType == SessionType.hang &&
                  activeSession?.isMinimized == false) {
                activeSession?.endSession();
              }
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Grip & Active Hang',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            if (activeSession != null && activeSession.isActive)
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                tooltip: 'Minimize to Dock',
                onPressed: () {
                  activeSession?.minimizeSession();
                  Navigator.pop(context);
                },
              ),
            IconButton(
              icon: const Icon(Icons.add_chart_outlined, color: AppTheme.primaryAmber),
              tooltip: 'Log Dynamometer',
              onPressed: () => DynamometerEntrySheet.show(context),
            ),
          ],
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // TOP: 3 Milestone Progress Rings Card
              OlyEntryReveal(
                child: _buildMilestoneRingsCard(context, grip),
              ),
              const SizedBox(height: 16),

              // CNS Dynamometer Quick Glance Card
              OlyEntryReveal(
                index: 1,
                child: _buildDynamometerGlanceCard(context, grip),
              ),
              const SizedBox(height: 16),

              // Active Hang Stopwatch Card
              const OlyEntryReveal(
                index: 2,
                child: HangSessionBlockWidget(),
              ),
              const SizedBox(height: 20),

              // Curated Protocols Showcase
              OlyEntryReveal(
                index: 3,
                child: Text(
                  'STRUCTURED TRAINING PROTOCOLS',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...HangProtocol.getProtocols().map((proto) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildProtocolCard(proto),
                );
              }),
              const SizedBox(height: 16),

              // Recent Hang Logs
              if (grip.hangLogs.isNotEmpty) ...<Widget>[
                Text(
                  'RECENT HANG SESSIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...grip.hangLogs.take(5).map((log) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: log.isPersonalRecord
                            ? AppTheme.primaryAmber.withValues(alpha: 0.5)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            if (log.isPersonalRecord)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.emoji_events,
                                    color: AppTheme.primaryAmber, size: 18),
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  log.mode.displayName,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, yyyy • h:mm a')
                                      .format(log.date),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          log.formattedDuration,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: log.isPersonalRecord
                                ? AppTheme.primaryAmber
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMilestoneRingsCard(BuildContext context, GripHangProvider grip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.military_tech_outlined,
                  color: AppTheme.primaryAmber, size: 20),
              const SizedBox(width: 8),
              Text(
                'HANG TIME GOAL TRACKERS',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildRingItem(
                  title: 'Two-Hand',
                  targetLabel: '5:00',
                  currentSeconds: grip.bestTwoHandSeconds,
                  targetSeconds: 300,
                  color: AppTheme.primaryAmber,
                ),
              ),
              Expanded(
                child: _buildRingItem(
                  title: 'Left Arm',
                  targetLabel: '2:00',
                  currentSeconds: grip.bestLeftHandSeconds,
                  targetSeconds: 120,
                  color: AppTheme.secondaryCyan,
                ),
              ),
              Expanded(
                child: _buildRingItem(
                  title: 'Right Arm',
                  targetLabel: '2:00',
                  currentSeconds: grip.bestRightHandSeconds,
                  targetSeconds: 120,
                  color: Colors.deepOrangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingItem({
    required String title,
    required String targetLabel,
    required int currentSeconds,
    required int targetSeconds,
    required Color color,
  }) {
    final double ratio = (currentSeconds / targetSeconds).clamp(0.0, 1.0);
    final int minutes = currentSeconds ~/ 60;
    final int seconds = currentSeconds % 60;
    final String currentStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: <Widget>[
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CircularProgressIndicator(
                value: ratio,
                strokeWidth: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${(ratio * 100).round()}%',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          '$currentStr / $targetLabel',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamometerGlanceCard(
      BuildContext context, GripHangProvider grip) {
    final DynamometerEntry? latest = grip.latestDynamometerEntry;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'HOME DYNAMOMETER STATUS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.9,
                    color: AppTheme.primaryAmber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latest != null
                      ? '${latest.rightHandKg.toStringAsFixed(1)} kg R • ${latest.leftHandKg.toStringAsFixed(1)} kg L'
                      : 'No dynamometer measurement logged',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  latest != null
                      ? 'CNS: ${grip.cnsReadinessPercent}% (${grip.cnsStatusText})'
                      : 'Log daily at home outside workout context',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OlyPressable(
            onPressed: () => DynamometerEntrySheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryAmber),
              ),
              child: Text(
                'LOG SQUEEZE',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard(HangProtocol proto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                proto.title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Target: ${proto.targetAccumulatedSeconds}s',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            proto.description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
