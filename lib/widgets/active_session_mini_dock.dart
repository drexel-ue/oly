import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:provider/provider.dart';

/// A floating, glassmorphic 54px mini-dock that hovers directly above
/// the bottom navigation bar during active workout sessions, mobility flows,
/// preview sessions, and live rest timers.
class ActiveSessionMiniDock extends StatelessWidget {
  const ActiveSessionMiniDock({
    super.key,
    this.onTapExpand,
  });

  final VoidCallback? onTapExpand;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ActiveSessionProvider, ProgramProvider>(
      builder: (
        BuildContext context,
        ActiveSessionProvider session,
        ProgramProvider program,
        Widget? child,
      ) {
        // Render if a session is actively running or an active draft exists with a running timer
        final bool shouldShow = session.isActive ||
            (program.hasActiveDraft && session.isRestTimerRunning);

        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        final bool isMobility = session.sessionType == SessionType.mobility;
        final bool isPreview = session.isPreviewMode;
        final bool isResting = session.isRestTimerRunning;

        final Color accentColor = isResting
            ? AppTheme.primaryAmber
            : (isMobility
                ? AppTheme.secondaryCyan
                : (isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber));

        final String defaultTitle = isMobility
            ? 'Active Recovery Routine'
            : (program.activeDraft?.dayTitle ?? 'Active Workout');

        final String titleText = session.currentExercise.isNotEmpty
            ? session.currentExercise
            : (session.sessionTitle.isNotEmpty
                ? session.sessionTitle
                : defaultTitle);

        final String subtitleText = isResting
            ? 'RESTING • ${session.formattedRestTime}'
            : (session.currentSetInfo.isNotEmpty
                ? session.currentSetInfo
                : (session.restSecondsRemaining > 0
                    ? 'PAUSED • ${session.formattedRestTime}'
                    : (isMobility
                        ? 'MOBILITY FLOW IN PROGRESS'
                        : (isPreview
                            ? 'PREVIEW EXPLORATION'
                            : 'SESSION IN PROGRESS'))));

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleExpand(context, session, program),
                splashColor: accentColor.withValues(alpha: 0.15),
                highlightColor: accentColor.withValues(alpha: 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // 2.5px Dynamic Progress Bar along top edge
                    if (session.restTotalSeconds > 0)
                      LinearProgressIndicator(
                        value: session.timerProgress,
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          // Glowing Pulsing Session Indicator
                          _buildPulseIcon(
                            isResting: isResting,
                            isMobility: isMobility,
                            accentColor: accentColor,
                          ),
                          const SizedBox(width: 12),

                          // Session & Timer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    if (isPreview) ...<Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryCyan
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppTheme.secondaryCyan,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'PREVIEW',
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.secondaryCyan,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isMobility && !isPreview) ...<Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryCyan
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppTheme.secondaryCyan
                                                .withValues(alpha: 0.6),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'RECOVERY',
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.secondaryCyan,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Flexible(
                                      child: Text(
                                        titleText,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (session.currentSetInfo.isNotEmpty &&
                                        session.currentExercise.isNotEmpty) ...<Widget>[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceCard,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppTheme.borderColor,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          session.currentSetInfo,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: <Widget>[
                                    if (isResting) ...<Widget>[
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 13,
                                        color: AppTheme.primaryAmber,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      subtitleText,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isResting
                                            ? AppTheme.primaryAmber
                                            : AppTheme.textSecondary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Quick Timer Action (Play / Pause if timer has time)
                          if (session.restSecondsRemaining > 0) ...<Widget>[
                            IconButton(
                              icon: Icon(
                                isResting
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: accentColor,
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: isResting ? 'Pause Rest' : 'Resume Rest',
                              onPressed: () {
                                if (isResting) {
                                  session.pauseRestTimer();
                                } else {
                                  session.resumeRestTimer();
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Expand Chevron
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: AppTheme.textPrimary,
                              size: 26,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Expand Session',
                            onPressed: () =>
                                _handleExpand(context, session, program),
                          ),
                          const SizedBox(width: 4),

                          // Close / Dismiss Button
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            tooltip: isPreview
                                ? 'Dismiss Preview'
                                : 'Dismiss Session',
                            onPressed: () => _handleDismiss(context, session),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseIcon({
    required bool isResting,
    required bool isMobility,
    required Color accentColor,
  }) {
    final IconData icon = isResting
        ? Icons.timer_rounded
        : (isMobility
            ? Icons.self_improvement_rounded
            : Icons.fitness_center_rounded);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: accentColor,
          size: 17,
        ),
      ),
    );
  }

  void _handleExpand(
    BuildContext context,
    ActiveSessionProvider session,
    ProgramProvider program,
  ) {
    if (onTapExpand != null) {
      onTapExpand!();
      return;
    }

    session.maximizeSession();

    if (session.sessionType == SessionType.mobility &&
        session.activeMobilityRoutine != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RecoverySessionScreen(
            routine: session.activeMobilityRoutine!,
            isPreviewMode: session.isPreviewMode,
          ),
        ),
      );
      return;
    }

    final ActiveWorkoutDraft? draft = program.activeDraft;
    final DayTemplate matchingDay = draft != null
        ? program.days.firstWhere(
            (DayTemplate d) => d.dayNumber == draft.dayNumber,
            orElse: () => program.currentDayTemplate,
          )
        : program.currentDayTemplate;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WorkoutSessionScreen(
          dayTemplate: matchingDay,
          initialDraft: draft,
          isPreviewMode: session.isPreviewMode,
        ),
      ),
    );
  }

  void _handleDismiss(BuildContext context, ActiveSessionProvider session) {
    HapticFeedback.lightImpact();
    if (session.isPreviewMode) {
      session.endSession();
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: <Widget>[
            const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'End Active Session?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          session.sessionType == SessionType.mobility
              ? 'Are you sure you want to stop this mobility routine? Your progress will not be saved.'
              : 'Are you sure you want to dismiss the active workout dock? Any logged sets remain safely stored in your draft.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              session.endSession();
            },
            child: const Text('Dismiss Session'),
          ),
        ],
      ),
    );
  }
}
