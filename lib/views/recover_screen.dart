import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/wim_hof_setup_sheet.dart';
import 'package:oly/views/injury_tracker_screen.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:provider/provider.dart';

/// The dedicated RECOVER domain view for physiological readiness,
/// active mobility routines, Wim Hof breathwork, and joint injury tracking.
class RecoverScreen extends StatelessWidget {
  const RecoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final InjuryProvider injuries = Provider.of<InjuryProvider>(context);
    final BreathingProvider breathing = Provider.of<BreathingProvider>(context);
    final LiftProvider lifts = Provider.of<LiftProvider>(context);
    final ProgramProvider program = Provider.of<ProgramProvider>(context);

    final List<InjuryRecord> activeInjuries = injuries.activeInjuries;
    final WimHofConfig breathConfig = breathing.config;
    final int todayBreathingRounds = breathing.todayCompletedRounds;
    final int bestRetentionSecs = breathing.personalBestRetentionSeconds;

    // Generate dynamic mobility protocol
    final GeneratedRecoveryRoutine mobilityRoutine = recovery.getRoutine(
      ratioAnalyses: lifts.getRatioAnalysis(),
      lastSession: program.sessions.isNotEmpty ? program.sessions.first : null,
    );

    // Compute holistic readiness (100 base minus fatigue and injury severity)
    int readinessScore = 95;
    if (activeInjuries.isNotEmpty) {
      final int injuryDeduction = activeInjuries.fold<int>(
        0,
        (int sum, InjuryRecord i) => sum + (i.painScale * 4),
      );
      readinessScore = (readinessScore - injuryDeduction).clamp(30, 100);
    }

    final Color readinessColor = readinessScore >= 85
        ? AppTheme.successGreen
        : (readinessScore >= 65 ? AppTheme.primaryAmber : Colors.redAccent);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'RECOVER',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.2,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Readiness, Mobility & Down-Regulation',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.healing_outlined,
              color: AppTheme.secondaryCyan,
            ),
            tooltip: 'Injury Body Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const InjuryTrackerScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.air_rounded,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Guided Breathwork',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const WimHofSetupSheet(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: <Widget>[
            // 1. Holistic Daily Readiness Score Card
            _buildReadinessCard(
              context,
              readinessScore,
              readinessColor,
              activeInjuries,
              todayBreathingRounds,
            ),
            const SizedBox(height: 16),

            // 2. Active Dynamic Mobility Protocol Hero Card
            _buildMobilityHeroCard(context, mobilityRoutine),
            const SizedBox(height: 16),

            // 3. Wim Hof Breathwork Hub Card
            _buildBreathworkCard(
              context,
              breathConfig,
              todayBreathingRounds,
              bestRetentionSecs,
            ),
            const SizedBox(height: 16),

            // 4. Joint & Soreness Tracker Card
            _buildInjurySummaryCard(context, activeInjuries),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessCard(
    BuildContext context,
    int score,
    Color color,
    List<InjuryRecord> injuries,
    int breathingRounds,
  ) {
    final String statusLabel = score >= 85
        ? 'OPTIMAL STATE'
        : (score >= 65 ? 'MODERATE FATIGUE' : 'REST & RECHARGE');

    final String recommendation = score >= 85
        ? 'CNS and joint health cleared for peak load training today.'
        : (injuries.isNotEmpty
            ? '${injuries.length} active strain flag${injuries.length > 1 ? 's' : ''} logged. Prioritize pre-lift mobilization.'
            : 'Slight fatigue detected. Engage dynamic warmup and post-session down-regulation.');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.08),
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
                  Icon(Icons.shield_outlined, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY READINESS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              // Circular Gauge
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 7,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recommendation,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        _buildMicroMetric(
                          icon: Icons.healing,
                          label: injuries.isEmpty
                              ? 'Joints: Clear'
                              : 'Joints: ${injuries.length}',
                          color: injuries.isEmpty
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                        ),
                        const SizedBox(width: 14),
                        _buildMicroMetric(
                          icon: Icons.air,
                          label: breathingRounds > 0
                              ? '$breathingRounds Rds Done'
                              : 'Breath: Pending',
                          color: breathingRounds > 0
                              ? AppTheme.secondaryCyan
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMetric({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMobilityHeroCard(
    BuildContext context,
    GeneratedRecoveryRoutine routine,
  ) {
    final String subtitle = routine.diagnosticReasons.isNotEmpty
        ? routine.diagnosticReasons.first
        : 'Targeting movement mechanics & dynamic recovery balance';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryCyan.withValues(alpha: 0.35),
        ),
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
                      Icons.accessibility_new_rounded,
                      color: AppTheme.secondaryCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'DYNAMIC MOBILITY ROUTINE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondaryCyan,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '~${routine.totalEstimatedMinutes} MIN',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Targeted Mobility & Remodeling',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Exercise preview pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: routine.exercises.take(3).map((MobilityExerciseModel item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RecoverySessionScreen(routine: routine),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'START MOBILITY PROTOCOL',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathworkCard(
    BuildContext context,
    WimHofConfig config,
    int todayRounds,
    int bestRetentionSecs,
  ) {
    final String bestRetentionFormatted =
        '${bestRetentionSecs ~/ 60}m ${(bestRetentionSecs % 60).toString().padLeft(2, '0')}s';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryAmber.withValues(alpha: 0.35),
        ),
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
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'WIM HOF BREATHWORK',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryAmber,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              if (bestRetentionSecs > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 13,
                        color: AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PR $bestRetentionFormatted',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Neuro-Vascular Down-Regulation',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            todayRounds > 0
                ? '$todayRounds rounds completed today. Recommended post-lift or evening recovery.'
                : '30-40 diaphragmatic breaths + deep hypoxic retention for recovery & focus.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WimHofSetupSheet(),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    '${config.defaultRounds} Rds • Setup',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WimHofSetupSheet(),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    'START BREATHING',
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

  Widget _buildInjurySummaryCard(
    BuildContext context,
    List<InjuryRecord> activeInjuries,
  ) {
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
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.healing_outlined,
                      color: AppTheme.secondaryCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'JOINT & SORENESS TRACKER',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const InjuryTrackerScreen(),
                    ),
                  );
                },
                child: Text(
                  'Manage Body Map',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activeInjuries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No active joint strains or soreness flags logged. You are cleared for all dynamic movement patterns.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeInjuries.map((InjuryRecord inj) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.warningOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${inj.name} (${inj.painScale}/10)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
