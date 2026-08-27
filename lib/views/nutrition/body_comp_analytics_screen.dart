import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/body_composition_entry.dart';
import '../../providers/body_comp_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutrition/body_comp_trend_chart.dart';
import '../../widgets/nutrition/body_donut_chart.dart';
import '../../widgets/nutrition/renpho_stat_pill.dart';
import 'renpho_scanner_sheet.dart';

class BodyCompAnalyticsScreen extends StatefulWidget {
  const BodyCompAnalyticsScreen({super.key});

  @override
  State<BodyCompAnalyticsScreen> createState() => _BodyCompAnalyticsScreenState();
}

class _BodyCompAnalyticsScreenState extends State<BodyCompAnalyticsScreen> {
  double _targetBfPct = 15.0;

  @override
  Widget build(BuildContext context) {
    final bodyComp = Provider.of<BodyCompProvider>(context);
    final nutrition = Provider.of<NutritionProvider>(context);
    final latest = bodyComp.latestEntry;
    final entries = bodyComp.entries;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Body Composition Intelligence',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryAmber),
            tooltip: 'Scan New Scale Report',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const RenphoScannerSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (latest != null) ...[
                // Top Donut Breakdown
                BodyDonutChart(entry: latest),
                const SizedBox(height: 14),

                // LBM-Driven Target Weight & Goal Calculator
                _buildGoalTargetCard(latest, nutrition),
                const SizedBox(height: 14),
              ],

              // Historical Trend Chart
              BodyCompTrendChart(entries: entries),
              const SizedBox(height: 16),

              // Full 13-Metric Grid
              if (latest != null) ...[
                Text(
                  'LATEST RENPHO BIOMETRICS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBiometricsGrid(latest, bodyComp),
                const SizedBox(height: 20),
              ],

              // Scan History Timeline
              Text(
                'SCAN AUDIT LOG (${entries.length})',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              _buildHistoryList(entries, bodyComp),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTargetCard(BodyCompositionEntry latest, NutritionProvider nutrition) {
    final lbm = latest.leanBodyMassLb;
    final targetWeight = latest.targetWeightForBodyFat(_targetBfPct);
    final fatToLose = latest.fatToLoseForTargetBf(_targetBfPct);
    final weeksToGoal = (fatToLose / 1.0).ceil(); // ~1 lb fat loss per week

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
              Row(
                children: [
                  const Icon(Icons.track_changes, color: AppTheme.primaryAmber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'LEAN MASS PRESERVATION GOAL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LBM: ${lbm.toStringAsFixed(1)} lb',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Body Fat %',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
              ),
              Text(
                '${_targetBfPct.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ],
          ),

          Slider(
            value: _targetBfPct,
            min: 8.0,
            max: 30.0,
            divisions: 44,
            activeColor: AppTheme.primaryAmber,
            inactiveColor: Colors.white10,
            onChanged: (val) => setState(() => _targetBfPct = val),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Weight', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${targetWeight.toStringAsFixed(1)} lb',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pure Fat to Lose', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '-${fatToLose.toStringAsFixed(1)} lb',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Timeline', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '~$weeksToGoal weeks',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricsGrid(BodyCompositionEntry latest, BodyCompProvider bodyComp) {
    return Column(
      children: [
        RenphoStatPill(
          icon: Icons.scale,
          label: 'Weight',
          value: latest.weightLb.toStringAsFixed(1),
          unit: 'lb',
          status: latest.weightLb > 220 ? 'High' : 'Average',
          delta: bodyComp.weightDeltaVsPrevious,
          isDeltaPositiveGood: false,
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.pie_chart,
          label: 'Body Fat',
          value: latest.bodyFatPct != null ? '${latest.bodyFatPct!.toStringAsFixed(1)}%' : '--',
          subtitle: latest.bodyFatLb != null ? '${latest.bodyFatLb!.toStringAsFixed(1)} lb' : null,
          status: 'Average',
          delta: bodyComp.bodyFatPctDeltaVsPrevious,
          isDeltaPositiveGood: false,
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.accessibility_new,
          label: 'Fat-Free Mass (Lean Body Mass)',
          value: latest.leanBodyMassLb.toStringAsFixed(1),
          unit: 'lb',
          subtitle: 'Katch-McArdle Foundation',
          status: 'Average',
          delta: bodyComp.leanMassDeltaVsPrevious,
          isDeltaPositiveGood: true,
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.fitness_center,
          label: 'Skeletal Muscle',
          value: latest.skeletalMuscleLb != null ? latest.skeletalMuscleLb!.toStringAsFixed(1) : '--',
          unit: 'lb',
          subtitle: latest.skeletalMusclePct != null ? '${latest.skeletalMusclePct!.toStringAsFixed(1)}%' : null,
          status: 'Average',
          delta: bodyComp.skeletalMuscleDeltaVsPrevious,
          isDeltaPositiveGood: true,
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.sports_gymnastics,
          label: 'Muscle Mass',
          value: latest.muscleMassLb != null ? latest.muscleMassLb!.toStringAsFixed(1) : '--',
          unit: 'lb',
          subtitle: latest.muscleMassPct != null ? '${latest.muscleMassPct!.toStringAsFixed(1)}%' : null,
          status: 'High',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.speed,
          label: 'BMI',
          value: latest.bmi != null ? latest.bmi!.toStringAsFixed(1) : '--',
          status: 'High',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.local_fire_department,
          label: 'Basal Metabolic Rate (BMR)',
          value: '${latest.bmrKcal ?? latest.katchMcArdleBmr}',
          unit: 'kcal',
          status: 'Average',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.water_drop,
          label: 'Body Water',
          value: latest.bodyWaterLb != null ? latest.bodyWaterLb!.toStringAsFixed(1) : '--',
          unit: 'lb',
          subtitle: latest.bodyWaterPct != null ? '${latest.bodyWaterPct!.toStringAsFixed(1)}%' : null,
          status: 'Average',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.favorite,
          label: 'Visceral Fat',
          value: latest.visceralFat != null ? '${latest.visceralFat}' : '--',
          status: 'High',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.health_and_safety,
          label: 'Bone Mass',
          value: latest.boneMassLb != null ? latest.boneMassLb!.toStringAsFixed(1) : '--',
          unit: 'lb',
          subtitle: latest.boneMassPct != null ? '${latest.boneMassPct!.toStringAsFixed(1)}%' : null,
          status: 'Average',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.egg_alt_outlined,
          label: 'Protein',
          value: latest.proteinLb != null ? latest.proteinLb!.toStringAsFixed(1) : '--',
          unit: 'lb',
          subtitle: latest.proteinPct != null ? '${latest.proteinPct!.toStringAsFixed(1)}%' : null,
          status: 'Average',
        ),
        const SizedBox(height: 8),
        RenphoStatPill(
          icon: Icons.cake,
          label: 'Metabolic Age',
          value: latest.metabolicAge != null ? '${latest.metabolicAge}' : '--',
          status: 'High',
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<BodyCompositionEntry> entries, BodyCompProvider bodyComp) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = entries[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(item.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LBM: ${item.leanBodyMassLb.toStringAsFixed(1)} lb • BF: ${item.bodyFatPct?.toStringAsFixed(1) ?? '--'}% • BMR: ${item.bmrKcal ?? '--'} kcal',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${item.weightLb.toStringAsFixed(1)} lb',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  if (entries.length > 1) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () => bodyComp.deleteEntry(item.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
