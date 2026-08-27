import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_nutrition_log.dart';
import '../../theme/app_theme.dart';

class MacroRingCard extends StatelessWidget {
  final DailyNutritionLog log;
  final VoidCallback? onToggleTrainingDay;

  const MacroRingCard({
    super.key,
    required this.log,
    this.onToggleTrainingDay,
  });

  @override
  Widget build(BuildContext context) {
    final remainingCals = log.remainingCalories;
    final isSurplus = remainingCals < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row: Calorie Summary & Training Day Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY TARGET',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${isSurplus ? '+' : ''}${remainingCals.abs()}',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isSurplus ? AppTheme.warningOrange : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSurplus ? 'kcal over' : 'kcal remaining',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Training Day Pill
              InkWell(
                onTap: onToggleTrainingDay,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: log.isTrainingDay
                        ? AppTheme.primaryAmber.withOpacity(0.15)
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: log.isTrainingDay ? AppTheme.primaryAmber : AppTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 16,
                        color: log.isTrainingDay ? AppTheme.primaryAmber : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.isTrainingDay ? 'Training Day' : 'Rest Day',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: log.isTrainingDay ? AppTheme.primaryAmber : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Macro Sub-bars (Protein, Carbs, Fats)
          Row(
            children: [
              Expanded(
                child: _buildMacroBar(
                  label: 'Protein',
                  current: log.totalProtein,
                  target: log.targetProteinGrams,
                  color: AppTheme.secondaryCyan,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroBar(
                  label: 'Carbs',
                  current: log.totalCarbs,
                  target: log.targetCarbsGrams,
                  color: AppTheme.primaryAmber,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroBar(
                  label: 'Fats',
                  current: log.totalFat,
                  target: log.targetFatGrams,
                  color: const Color(0xFFFF453A),
                  unit: 'g',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Eaten vs Goal Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Eaten: ${log.totalCalories} kcal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Budget: ${log.targetCalories} kcal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar({
    required String label,
    required double current,
    required double target,
    required Color color,
    required String unit,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isTargetMet = current >= target;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (isTargetMet)
                const Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                current.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                ' / ${target.toStringAsFixed(0)}$unit',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
