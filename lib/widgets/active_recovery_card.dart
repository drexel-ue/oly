import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:provider/provider.dart';

class ActiveRecoveryCard extends StatelessWidget {
  const ActiveRecoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final LiftProvider liftProvider = Provider.of<LiftProvider>(context);
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
    );
    final RecoveryProvider recoveryProvider = Provider.of<RecoveryProvider>(
      context,
    );
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);

    final List<LiftRatioAnalysis> ratioAnalyses = liftProvider
        .getRatioAnalysis();
    final WorkoutSession? lastSession = programProvider.sessions.isNotEmpty
        ? programProvider.sessions.first
        : null;

    final GeneratedRecoveryRoutine routine = recoveryProvider.getRoutine(
      ratioAnalyses: ratioAnalyses,
      lastSession: lastSession,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.surfaceCard, AppTheme.surfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Badge & Duration Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.bolt, color: AppTheme.accentBlue, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'ACTIVE RECOVERY FLOW',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentBlue.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${routine.totalEstimatedMinutes} MINS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            'Targeted Mobility & Accessories',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Diagnostic Reasons list
          ...routine.diagnosticReasons.take(2).map((String reason) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 3, right: 6),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      settings.formatTextUnits(reason),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // 5-Phase Preview Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: routine.phaseGroups.map((RecoveryPhaseGroup group) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  group.title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // CTA Launch Button & Quick Stats
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecoverySessionScreen(
                          routine: routine,
                          isPreviewMode: true,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    side: const BorderSide(color: AppTheme.accentBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.explore,
                    color: AppTheme.accentBlue,
                    size: 18,
                  ),
                  label: Text(
                    'PREVIEW',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecoverySessionScreen(routine: routine),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                  ),
                  label: Text(
                    'START FLOW',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (recoveryProvider.totalSessionsCompleted > 0) ...<Widget>[
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${recoveryProvider.totalSessionsCompleted} Recovery Sessions Logged • ${recoveryProvider.totalMobilityMinutes} Total Mins',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
