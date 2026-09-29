import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/gtg_model.dart';
import 'package:oly/providers/gtg_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/gtg/grease_the_groove_screen.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/kinetic_counter.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

/// A dashboard showcase card for the Grease the Groove protocol.
/// Displays daily submax pull-ups, active scapular hangs (micro-elbow bend),
/// streak status, and one-tap quick log actions.
class GtgDashboardCard extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final GtgProvider gtg = Provider.of<GtgProvider>(context);
    final GtgConfig config = gtg.config;

    return OlyPressable(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const GreaseTheGrooveScreen(),
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        ambientGlowColor: AppTheme.primaryAmber,
        ambientGlowRadius: 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Header: Icon, Title, and Streak Badge
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.electric_bolt_rounded,
                    color: AppTheme.primaryAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Grease the Groove',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Daily Neural Volume • Zero Fatigue',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (gtg.currentStreakDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('🔥', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '${gtg.currentStreakDays}d',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (config.remindersEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentElectricCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accentElectricCyan.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: AppTheme.accentElectricCyan,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${config.intervalMinutes}m',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentElectricCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Form Technique Cue Badge (Active Scapula + Micro-Bend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentElectricCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentElectricCyan.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.accentElectricCyan,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Active Scapula • Micro-Bend Elbows (Tendon Armor)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentElectricCyan,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Dual Metrics Row (Pull-Ups & Active Hangs)
            Row(
              children: <Widget>[
                // Pull-Ups Pod
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.fitness_center_rounded,
                              size: 13,
                              color: AppTheme.primaryAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'PULL-UPS',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            KineticCounter(
                              value: gtg.todayPullUpReps,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' / ${config.dailyPullUpGoal}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: gtg.pullUpProgressRatio,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryAmber,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Active Hangs Pod
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentElectricCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.timer_outlined,
                              size: 13,
                              color: AppTheme.accentElectricCyan,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ACTIVE HANG',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppTheme.accentElectricCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            KineticCounter(
                              value: gtg.todayHangSeconds,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              's / ${config.dailyHangSecondsGoal}s',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: gtg.hangProgressRatio,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.accentElectricCyan,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Quick Actions
            Row(
              children: <Widget>[
                Expanded(
                  child: OlyPressable(
                    onPressed: () async {
                      await gtg.logPullUpSet();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logged ${config.targetPullUpReps} submax pull-ups!',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            backgroundColor: AppTheme.surfaceElevated,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.add_rounded,
                            size: 15,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${config.targetPullUpReps} Pull-Ups',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OlyPressable(
                    onPressed: () async {
                      await gtg.logActiveHangSet();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logged ${config.targetHangSeconds}s active hang (micro-bend)!',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            backgroundColor: AppTheme.surfaceElevated,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentElectricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentElectricCyan.withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.add_rounded,
                            size: 15,
                            color: AppTheme.accentElectricCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${config.targetHangSeconds}s Hang',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentElectricCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
