import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/illness_model.dart';
import 'package:oly/providers/illness_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/illness_checkin_sheet.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:oly/widgets/motion/pulsing_glow.dart';
import 'package:provider/provider.dart';

class SicknessShieldBanner extends StatelessWidget {
  const new({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final IllnessProvider illnessProvider =
        Provider.of<IllnessProvider>(context);

    if (!illnessProvider.hasActiveIllness && !illnessProvider.isConvalescing) {
      return const SizedBox.shrink();
    }

    final IllnessRecord? record = illnessProvider.hasActiveIllness
        ? illnessProvider.activeRecord
        : illnessProvider.convalescingRecord;

    if (record == null) return const SizedBox.shrink();

    final bool isConvalescing = illnessProvider.isConvalescing;
    final bool isSevere = !isConvalescing &&
        (record.hasFever ||
            record.severity != IllnessSeverity.mildAboveNeck);

    final Color primaryColor = isConvalescing
        ? AppTheme.secondaryCyan
        : (isSevere ? Colors.redAccent : AppTheme.primaryAmber);

    final IconData iconData = isConvalescing
        ? Icons.trending_up_rounded
        : (isSevere ? Icons.shield_rounded : Icons.health_and_safety_outlined);

    final String title = isConvalescing
        ? 'RETURN-TO-PLAY: ${record.reEntryStage.shortLabel.toUpperCase()}'
        : (isSevere
            ? 'SICKNESS SHIELD ACTIVE: ${record.severity.shortLabel.toUpperCase()}'
            : 'NECK RULE ACTIVE: HEAD COLD');

    final String subtitle = isConvalescing
        ? record.reEntryStage.prescription
        : (isSevere
            ? 'Cycle Frozen • Full Rest Prescribed • +${record.hydrationBonusMl}ml Hydration Target'
            : '-30% Load Auto-Deload • Max RPE 6 • Avoid Ballistic Failures');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: PulsingGlow(
        glowColor: primaryColor,
        isPulsing: isSevere,
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          ambientGlowColor: primaryColor.withValues(alpha: 0.35),
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: primaryColor,
                      size: compact ? 18 : 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: compact ? 12 : 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (record.isTrainingFrozen && !isConvalescing) ...<Widget>[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FROZEN',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: compact ? 11 : 12,
                            color: AppTheme.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!compact) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OlyPressable(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        IllnessCheckInSheet.show(
                          context,
                          existingRecord: record,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 14,
                              color: AppTheme.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Update Symptoms',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isConvalescing)
                      OlyPressable(
                        onPressed: () async {
                          await HapticFeedback.mediumImpact();
                          await illnessProvider.advanceReEntryStage(record.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  AppTheme.secondaryCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppTheme.secondaryCyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                record.reEntryStage ==
                                        ReEntryStage.stage1LightRecovery
                                    ? 'Advance to Stage 2'
                                    : 'Full Clearance',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.secondaryCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      OlyPressable(
                        onPressed: () async {
                          await HapticFeedback.mediumImpact();
                          await illnessProvider.resolveIllness(record.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  AppTheme.secondaryCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: AppTheme.secondaryCyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mark Recovered',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.secondaryCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
