import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/theme/app_theme.dart';

class EmptyAddMovementCard extends StatelessWidget {
  const EmptyAddMovementCard({
    required this.onAddPressed,
    super.key,
    this.onLoadRecommendedPressed,
    this.isSessionEmpty = false,
    this.isPreviewMode = false,
  });

  final VoidCallback onAddPressed;
  final VoidCallback? onLoadRecommendedPressed;
  final bool isSessionEmpty;
  final bool isPreviewMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (isSessionEmpty) ...<Widget>[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.secondaryCyan.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPreviewMode
                            ? Icons.explore_outlined
                            : Icons.dashboard_customize_outlined,
                        color: AppTheme.secondaryCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'FREE-FORM CONDITIONING DAY',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPreviewMode
                      ? 'Preview & Plan Your Session'
                      : 'Design Your Own Session',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPreviewMode
                      ? 'Browse and test benchmark WODs, kettlebell carries, hypertrophy accessories, or custom movements without starting timers.'
                      : 'Add CrossFit benchmark WODs, kettlebell carries, hypertrophy accessories, or custom movements. The rest timer and draft saving stay active throughout.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (onLoadRecommendedPressed != null) ...<Widget>[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onLoadRecommendedPressed!();
                    },
                    icon: Icon(
                      isPreviewMode ? Icons.explore : Icons.auto_awesome,
                      size: 16,
                      color: isPreviewMode
                          ? AppTheme.secondaryCyan
                          : AppTheme.primaryAmber,
                    ),
                    label: Text(
                      isPreviewMode
                          ? 'LOAD RECOMMENDED ACTIVE RECOVERY (PREVIEW)'
                          : 'LOAD RECOMMENDED ACTIVE RECOVERY (KB MILE + CORE)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPreviewMode
                            ? AppTheme.secondaryCyan
                            : AppTheme.primaryAmber,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isPreviewMode
                          ? AppTheme.secondaryCyan
                          : AppTheme.primaryAmber,
                      side: BorderSide(
                        color: (isPreviewMode
                                ? AppTheme.secondaryCyan
                                : AppTheme.primaryAmber)
                            .withValues(alpha: 0.6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Dashed / Outlined Add Button Card
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onAddPressed();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSessionEmpty
                    ? (isPreviewMode
                        ? AppTheme.secondaryCyan
                        : AppTheme.primaryAmber)
                    : AppTheme.borderColor.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isPreviewMode
                            ? AppTheme.secondaryCyan
                            : AppTheme.primaryAmber)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPreviewMode ? Icons.explore_rounded : Icons.add_rounded,
                    color: isPreviewMode
                        ? AppTheme.secondaryCyan
                        : AppTheme.primaryAmber,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isSessionEmpty
                      ? 'START BY ADDING A MOVEMENT'
                      : (isPreviewMode
                          ? 'PREVIEW ANOTHER MOVEMENT OR WOD'
                          : 'ADD ANOTHER MOVEMENT OR WOD'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isPreviewMode
                        ? AppTheme.secondaryCyan
                        : AppTheme.primaryAmber,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CrossFit WOD • Kettlebell Mile • Lifts • Core • Accessories',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
