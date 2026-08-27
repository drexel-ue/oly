import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/body_composition_entry.dart';
import '../../theme/app_theme.dart';

class BodyDonutChart extends StatelessWidget {
  final BodyCompositionEntry entry;

  const BodyDonutChart({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final waterLb = entry.bodyWaterLb ?? (entry.weightLb * 0.55);
    final proteinLb = entry.proteinLb ?? (entry.weightLb * 0.18);
    final fatLb = entry.bodyFatLb ?? (entry.weightLb * 0.21);
    final boneLb = entry.boneMassLb ?? (entry.weightLb * 0.04);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BODY COMPOSITION BREAKDOWN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Renpho Ingested',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 44,
                        sections: [
                          PieChartSectionData(
                            value: waterLb,
                            color: const Color(0xFF00D2FF),
                            radius: 18,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: proteinLb,
                            color: const Color(0xFF30D158),
                            radius: 18,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: fatLb,
                            color: const Color(0xFFFF9F0A),
                            radius: 18,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: boneLb,
                            color: const Color(0xFFFF453A),
                            radius: 18,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Weight',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          entry.weightLb.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'lb',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF00D2FF),
                      label: 'Body Water',
                      value: '${waterLb.toStringAsFixed(1)} lb',
                      pct: entry.bodyWaterPct != null ? '${entry.bodyWaterPct!.toStringAsFixed(1)}%' : null,
                    ),
                    const SizedBox(height: 6),
                    _buildLegendItem(
                      color: const Color(0xFF30D158),
                      label: 'Protein / Muscle',
                      value: '${proteinLb.toStringAsFixed(1)} lb',
                      pct: entry.proteinPct != null ? '${entry.proteinPct!.toStringAsFixed(1)}%' : null,
                    ),
                    const SizedBox(height: 6),
                    _buildLegendItem(
                      color: const Color(0xFFFF9F0A),
                      label: 'Body Fat',
                      value: '${fatLb.toStringAsFixed(1)} lb',
                      pct: entry.bodyFatPct != null ? '${entry.bodyFatPct!.toStringAsFixed(1)}%' : null,
                    ),
                    const SizedBox(height: 6),
                    _buildLegendItem(
                      color: const Color(0xFFFF453A),
                      label: 'Bone Mass',
                      value: '${boneLb.toStringAsFixed(1)} lb',
                      pct: entry.boneMassPct != null ? '${entry.boneMassPct!.toStringAsFixed(1)}%' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
    String? pct,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (pct != null) ...[
              const SizedBox(width: 4),
              Text(
                '($pct)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
