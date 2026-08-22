import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lift_provider.dart';
import '../theme/app_theme.dart';

class RatioChartWidget extends StatelessWidget {
  final List<LiftRatioAnalysis> ratios;

  const RatioChartWidget({super.key, required this.ratios});

  @override
  Widget build(BuildContext context) {
    if (ratios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          'Log 1RMs to generate lift variation ratio analysis.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: ratios.map((analysis) {
        final pct = (analysis.ratioPercentage / 100.0).clamp(0.0, 1.5);
        Color statusColor = AppTheme.successGreen;
        if (analysis.status == 'Underdeveloped') {
          statusColor = AppTheme.warningOrange;
        } else if (analysis.status == 'Dominant') {
          statusColor = AppTheme.secondaryCyan;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${analysis.lift.name} vs ${analysis.anchorLift.name}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      analysis.status,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Actual: ${(analysis.actualRatio * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Target: ${(analysis.targetRatio * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryAmber),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (pct / 1.2).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
