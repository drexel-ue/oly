import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/theme/app_theme.dart';

class FastingActiveCard extends StatelessWidget {
  const FastingActiveCard({
    required this.session,
    super.key,
    this.onTap,
  });

  final FastingSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final FastingBiologicalStage stage = session.currentStage;
    final int totalSecs = session.elapsedSeconds;
    final int hours = totalSecs ~/ 3600;
    final int minutes = (totalSecs % 3600) ~/ 60;
    final String timeStr = '${hours}h ${minutes}m';

    final int targetHours =
        (session.targetDurationSeconds / 3600).round();
    final double progress = session.progressRatio;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stage.color.withValues(alpha: 0.4)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: stage.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Mini Ring or Icon
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(stage.color),
                    strokeWidth: 4,
                  ),
                ),
                Icon(
                  Icons.hourglass_top,
                  size: 20,
                  color: stage.color,
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.protocol.shortCode,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stage.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stage.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$timeStr elapsed of ${targetHours}h goal (${(progress * 100).toInt()}%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
