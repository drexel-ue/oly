import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/theme/app_theme.dart';

class FastingRadialGauge extends StatelessWidget {
  const FastingRadialGauge({
    required this.session,
    super.key,
    this.size = 240.0,
  });

  final FastingSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double elapsedHours = session.elapsedHours;
    final int targetHours =
        (session.targetDurationSeconds / 3600).round();
    final double progress = session.progressRatio;
    final FastingBiologicalStage stage = session.currentStage;

    // Formatting elapsed string
    final int totalSecs = session.elapsedSeconds;
    final int hours = totalSecs ~/ 3600;
    final int minutes = (totalSecs % 3600) ~/ 60;
    final int seconds = totalSecs % 60;
    final String timeStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Remaining string
    final int remSecs = session.remainingSeconds;
    final int remH = remSecs ~/ 3600;
    final int remM = (remSecs % 3600) ~/ 60;
    final String remStr = remSecs > 0
        ? '${remH}h ${remM}m remaining'
        : 'Target Reached! (${hours}h fast)';

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Custom Painted Segmented Ring
            CustomPaint(
              size: Size(size, size),
              painter: _FastingGaugePainter(
                progress: progress,
                targetHours: targetHours,
                elapsedHours: elapsedHours,
                activeStage: stage,
              ),
            ),

            // Inner Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Stage Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stage.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stage.color.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: stage.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stage.shortTitle.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: stage.color,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Elapsed Time
                Text(
                  timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),

                // Target / Remaining
                Text(
                  remStr,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Percentage Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}% of ${targetHours}h goal',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryAmber,
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

class _FastingGaugePainter extends CustomPainter {
  _FastingGaugePainter({
    required this.progress,
    required this.targetHours,
    required this.elapsedHours,
    required this.activeStage,
  });

  final double progress;
  final int targetHours;
  final double elapsedHours;
  final FastingBiologicalStage activeStage;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 14;
    const double strokeWidth = 12.0;

    // Background track paint
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF1E1E24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw active progress arc with dynamic gradient
    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    // Gradient based on stage
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    const SweepGradient gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + 2 * math.pi,
      colors: <Color>[
        Color(0xFF42A5F5), // Blue (Post-Absorptive)
        Color(0xFF26C6DA), // Cyan (Ketosis)
        Color(0xFFAB47BC), // Purple (Autophagy)
        AppTheme.primaryAmber, // Gold (Deep Autophagy)
        Color(0xFF00E676), // Green (Stem Cell Reset)
      ],
      stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
    );

    progressPaint.shader = gradient.createShader(rect);

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glowing tip indicator
      final double tipAngle = startAngle + sweepAngle;
      final Offset tipOffset = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      final Paint glowPaint = Paint()
        ..color = activeStage.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(tipOffset, strokeWidth * 0.8, glowPaint);

      final Paint pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipOffset, strokeWidth * 0.35, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FastingGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.elapsedHours != elapsedHours ||
        oldDelegate.activeStage != activeStage;
  }
}
