import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lift_provider.dart';
import '../theme/app_theme.dart';

import 'standard_ratios_sheet.dart';

class RatioChartWidget extends StatelessWidget {
  final List<LiftRatioAnalysis> ratios;

  const RatioChartWidget({super.key, required this.ratios});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Standard Ratios Reference Chart Launcher Card
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const StandardRatiosSheet(),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: AppTheme.secondaryCyan, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olympic Ratio Standards Reference Chart',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                      Text(
                        'View full standard ratio percentages & ideal targets',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.secondaryCyan),
              ],
            ),
          ),
        ),

        if (ratios.isEmpty)
          Container(
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
          )
        else
          ...ratios.map((analysis) {
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
                  Expanded(
                    child: Text(
                      '${analysis.lift.name} vs ${analysis.anchorLift.name}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
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
      }),
    ],
  );
}
}
