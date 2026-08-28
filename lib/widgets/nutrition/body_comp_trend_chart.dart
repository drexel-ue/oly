import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/theme/app_theme.dart';

enum ChartMetricType { weightAndLeanMass, bodyFatPercentage, muscleMass }

class BodyCompTrendChart extends StatefulWidget {
  const BodyCompTrendChart({required this.entries, super.key});
  final List<BodyCompositionEntry> entries;

  @override
  State<BodyCompTrendChart> createState() => _BodyCompTrendChartState();
}

class _BodyCompTrendChartState extends State<BodyCompTrendChart> {
  ChartMetricType _selectedType = ChartMetricType.weightAndLeanMass;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          'No scan history recorded yet',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }

    final List<BodyCompositionEntry> sortedEntries =
        List<BodyCompositionEntry>.from(widget.entries)..sort(
          (BodyCompositionEntry a, BodyCompositionEntry b) =>
              a.timestamp.compareTo(b.timestamp),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header & Metric Segment Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'BODY COMPOSITION TREND',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              // Segmented Choice
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    _buildSegmentButton(
                      'Weight/LBM',
                      ChartMetricType.weightAndLeanMass,
                    ),
                    _buildSegmentButton(
                      'BF %',
                      ChartMetricType.bodyFatPercentage,
                    ),
                    _buildSegmentButton('Muscle', ChartMetricType.muscleMass),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Chart
          SizedBox(
            height: 180,
            child: LineChart(_buildChartData(sortedEntries)),
          ),

          const SizedBox(height: 12),

          // Legend
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, ChartMetricType type) {
    final bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<BodyCompositionEntry> entries) {
    List<LineChartBarData> lines = <LineChartBarData>[];

    if (_selectedType == ChartMetricType.weightAndLeanMass) {
      // Line 1: Total Weight
      final List<FlSpot> weightSpots = entries.asMap().entries.map((
        MapEntry<int, BodyCompositionEntry> e,
      ) {
        return FlSpot(e.key.toDouble(), e.value.weightLb);
      }).toList();

      // Line 2: Lean Body Mass (LBM)
      final List<FlSpot> leanSpots = entries.asMap().entries.map((
        MapEntry<int, BodyCompositionEntry> e,
      ) {
        return FlSpot(e.key.toDouble(), e.value.leanBodyMassLb);
      }).toList();

      lines = <LineChartBarData>[
        LineChartBarData(
          spots: weightSpots,
          isCurved: true,
          color: const Color(0xFF00D2FF),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: leanSpots,
          isCurved: true,
          color: const Color(0xFF30D158),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
      ];
    } else if (_selectedType == ChartMetricType.bodyFatPercentage) {
      final List<FlSpot> bfSpots = entries.asMap().entries.map((
        MapEntry<int, BodyCompositionEntry> e,
      ) {
        return FlSpot(e.key.toDouble(), e.value.bodyFatPct ?? 0);
      }).toList();

      lines = <LineChartBarData>[
        LineChartBarData(
          spots: bfSpots,
          isCurved: true,
          color: const Color(0xFFFF9F0A),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
      ];
    } else {
      final List<FlSpot> muscleSpots = entries.asMap().entries.map((
        MapEntry<int, BodyCompositionEntry> e,
      ) {
        return FlSpot(
          e.key.toDouble(),
          e.value.skeletalMuscleLb ?? (e.value.weightLb * 0.5),
        );
      }).toList();

      lines = <LineChartBarData>[
        LineChartBarData(
          spots: muscleSpots,
          isCurved: true,
          color: const Color(0xFF30D158),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
        ),
      ];
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (double value) => FlLine(
          color: AppTheme.borderColor.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (double value, TitleMeta meta) => Text(
              value.toStringAsFixed(0),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              final int index = value.toInt();
              if (index >= 0 && index < entries.length) {
                return Text(
                  DateFormat('MM/dd').format(entries[index].timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: lines,
    );
  }

  Widget _buildChartLegend() {
    if (_selectedType == ChartMetricType.weightAndLeanMass) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildLegendIndicator(const Color(0xFF00D2FF), 'Total Weight (lb)'),
          const SizedBox(width: 16),
          _buildLegendIndicator(const Color(0xFF30D158), 'Lean Body Mass (lb)'),
        ],
      );
    } else if (_selectedType == ChartMetricType.bodyFatPercentage) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildLegendIndicator(const Color(0xFFFF9F0A), 'Body Fat %'),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildLegendIndicator(
            const Color(0xFF30D158),
            'Skeletal Muscle (lb)',
          ),
        ],
      );
    }
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
