import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/c25k_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class C25kActiveRunScreen extends StatelessWidget {
  const new({
    super.key,
    this.week,
    this.day,
  });

  final int? week;
  final int? day;

  @override
  Widget build(BuildContext context) {
    final C25kProvider c25k = Provider.of<C25kProvider>(context);
    final ActiveSessionProvider activeSession =
        Provider.of<ActiveSessionProvider>(context, listen: false);

    final C25kWorkout workout = c25k.activeWorkout ??
        C25kCurriculum.getWorkout(
          week ?? c25k.currentWeek,
          day ?? c25k.currentDay,
        );

    final C25kIntervalStep? step = c25k.currentStep;
    final bool isRunning = step?.type == C25kStepType.jog;

    final Color accentColor = isRunning
        ? AppTheme.primaryAmber
        : (step?.type == C25kStepType.walk
            ? AppTheme.secondaryCyan
            : AppTheme.successGreen);

    final int remainingSecs = c25k.currentStepRemainingSeconds;
    final int stepMins = remainingSecs ~/ 60;
    final int stepSecs = remainingSecs % 60;
    final String formattedStepTime =
        '${stepMins.toString().padLeft(2, '0')}:${stepSecs.toString().padLeft(2, '0')}';

    final int totalSecs = c25k.totalElapsedSeconds;
    final int totalMins = totalSecs ~/ 60;
    final int totalRemSecs = totalSecs % 60;
    final String formattedTotalTime =
        '${totalMins.toString().padLeft(2, '0')}:${totalRemSecs.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: !c25k.isRunActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        c25k.cancelRunSession();
        if (activeSession.sessionType == SessionType.c25k) {
          activeSession.endSession();
        } else {
          activeSession.updateExercise(currentExercise: '', currentSetInfo: '');
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceCard,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                workout.title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Step ${c25k.currentStepIndex + 1} of ${workout.steps.length}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Run Session',
              onPressed: () {
                c25k.cancelRunSession();
                if (activeSession.sessionType == SessionType.c25k) {
                  activeSession.endSession();
                } else {
                  activeSession.updateExercise(
                      currentExercise: '', currentSetInfo: '');
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // Overall Workout Timeline Progress Bar
              ClipRRect(
                child: LinearProgressIndicator(
                  value: c25k.overallWorkoutProgress,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 24),

            // Step Label Badge (e.g. JOG / WALK)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Text(
                step?.type.displayName.toUpperCase() ?? 'GET READY',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Big Radial Step Timer
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CircularProgressIndicator(
                        value: c25k.currentStepProgress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            formattedStepTime,
                            style: GoogleFonts.outfit(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            step?.label ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Metrics Summary Row (Elapsed, Jog Time, Walk Time)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _buildMetricCol('ELAPSED', formattedTotalTime),
                    _buildMetricCol(
                      'JOG TIME',
                      '${c25k.accumulatedJogSeconds ~/ 60}m ${c25k.accumulatedJogSeconds % 60}s',
                      color: AppTheme.primaryAmber,
                    ),
                    _buildMetricCol(
                      'WALK TIME',
                      '${c25k.accumulatedWalkSeconds ~/ 60}m ${c25k.accumulatedWalkSeconds % 60}s',
                      color: AppTheme.secondaryCyan,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Running Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: <Widget>[
                  // Skip Step Button
                  IconButton.filledTonal(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 28,
                    tooltip: 'Skip Step',
                    onPressed: () {
                      c25k.skipToNextStep();
                      activeSession.updateC25kProgress(
                        intervalLabel: c25k.currentStep?.label ?? 'C25K',
                        remainingSeconds: c25k.currentStepRemainingSeconds,
                      );
                    },
                  ),
                  const SizedBox(width: 12),

                  // Pause / Resume Main Button
                  Expanded(
                    child: OlyPressable(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (c25k.isPaused) {
                          c25k.resumeRunSession();
                        } else {
                          c25k.pauseRunSession();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: c25k.isPaused
                              ? AppTheme.primaryAmber
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                c25k.isPaused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                color: c25k.isPaused
                                    ? Colors.black
                                    : AppTheme.textPrimary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c25k.isPaused ? 'RESUME RUN' : 'PAUSE',
                                style: GoogleFonts.outfit(
                                  color: c25k.isPaused
                                      ? Colors.black
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Finish Workout Button
                  IconButton.filledTonal(
                    icon: const Icon(Icons.flag_outlined),
                    iconSize: 28,
                    tooltip: 'Complete Run',
                    onPressed: () async {
                      final C25kSessionLog log =
                          await c25k.finishRunSession();
                      activeSession.endSession();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'C25K Week ${log.week} Day ${log.day} Completed! (${log.netCaloriesBurned.toStringAsFixed(0)} kcal)',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppTheme.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMetricCol(String label, String value, {Color? color}) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
