import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/c25k_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/c25k/c25k_active_run_screen.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class C25kSessionBlockWidget extends StatelessWidget {
  const new({
    super.key,
    this.week,
    this.day,
    this.onCompleted,
  });

  final int? week;
  final int? day;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    final C25kProvider c25k = Provider.of<C25kProvider>(context);
    ActiveSessionProvider? activeSession;
    try {
      activeSession = Provider.of<ActiveSessionProvider>(context, listen: false);
    } catch (_) {}

    final int targetWeek = week ?? c25k.currentWeek;
    final int targetDay = day ?? c25k.currentDay;
    final C25kWorkout workout =
        C25kCurriculum.getWorkout(targetWeek, targetDay);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      color: AppTheme.secondaryCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AEROBIC ENGINE: C25K',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                      Text(
                        workout.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  workout.formattedTotalDuration,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Workout Description
          Text(
            workout.description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Interval Steps Pills Glance
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: workout.steps.map((step) {
                final bool isJog = step.type == C25kStepType.jog;
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isJog
                        ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                        : (step.type == C25kStepType.walk
                            ? AppTheme.secondaryCyan.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isJog
                          ? AppTheme.primaryAmber
                          : (step.type == C25kStepType.walk
                              ? AppTheme.secondaryCyan
                              : Colors.white10),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    step.formattedDuration,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isJog
                          ? AppTheme.primaryAmber
                          : (step.type == C25kStepType.walk
                              ? AppTheme.secondaryCyan
                              : AppTheme.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Start Run Button
          OlyPressable(
            onPressed: () {
              HapticFeedback.heavyImpact();
              c25k.startRunSession(week: targetWeek, day: targetDay);
              activeSession?.registerEndSessionCallback(c25k.cancelRunSession);

              if (activeSession?.sessionType == SessionType.workout) {
                activeSession?.updateC25kProgress(
                  intervalLabel: workout.steps.first.label ?? 'Warm-Up Walk',
                  remainingSeconds: workout.steps.first.durationSeconds,
                );
              } else {
                activeSession?.startSession(
                  sessionTitle: workout.title,
                  sessionType: SessionType.c25k,
                  currentExercise: workout.steps.first.label ?? 'Warm-Up Walk',
                  currentSetInfo:
                      '00:00 / ${workout.formattedTotalDuration}',
                );
              }

              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => C25kActiveRunScreen(
                    week: targetWeek,
                    day: targetDay,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[AppTheme.secondaryCyan, Color(0xFF0077B6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'START RUN INTERVALS',
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
