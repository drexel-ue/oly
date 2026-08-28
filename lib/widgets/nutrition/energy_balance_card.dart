import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/body_composition_entry.dart';
import '../../models/daily_nutrition_log.dart';
import '../../models/nutrition_goal_model.dart';
import '../../theme/app_theme.dart';
import '../../views/nutrition/metabolic_science_explainer_screen.dart';

class EnergyBalanceCard extends StatefulWidget {
  final DailyNutritionLog log;
  final BodyCompositionEntry? latestBodyComp;
  final NutritionGoalModel goal;
  final VoidCallback? onLogActivityTap;
  final VoidCallback? onWodSyncTap;

  const EnergyBalanceCard({
    super.key,
    required this.log,
    this.latestBodyComp,
    required this.goal,
    this.onLogActivityTap,
    this.onWodSyncTap,
  });

  @override
  State<EnergyBalanceCard> createState() => _EnergyBalanceCardState();
}

class _EnergyBalanceCardState extends State<EnergyBalanceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bmr = widget.latestBodyComp?.bmrKcal ??
        (widget.latestBodyComp != null
            ? widget.latestBodyComp!.katchMcArdleBmr
            : 2394);

    final energyIn = widget.log.totalCalories;
    final activityBurn = widget.log.totalActivityCalories;
    final totalEnergyOut = bmr + activityBurn;
    final netBalance = energyIn - totalEnergyOut;

    // Target Deficit / Surplus based on goal
    final int targetDeficit = widget.goal.goalType == GoalType.cutting
        ? (widget.goal.dailyCalorieAdjustment != 0 ? -widget.goal.dailyCalorieAdjustment.abs() : -450)
        : (widget.goal.goalType == GoalType.leanBulking ? 250 : 0);

    final bool isDeficit = netBalance < 0;
    final String netLabel = isDeficit ? '${netBalance.abs()} kcal DEFICIT' : '+$netBalance kcal SURPLUS';

    final wodActivity = widget.log.activities.where((a) => a.activityType == 'workout_wod').firstOrNull;
    final nonWodActivities = widget.log.activities.where((a) => a.activityType != 'workout_wod').toList();
    final nonWodBurn = nonWodActivities.fold(0, (sum, a) => sum + a.caloriesBurned);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt, color: AppTheme.secondaryCyan, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DAILY ENERGY BALANCE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MetabolicScienceExplainerScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 13, color: AppTheme.primaryAmber),
                        const SizedBox(width: 4),
                        Text(
                          'Science',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dual Energy Rings & Center Balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Energy IN
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: AppTheme.primaryAmber),
                            const SizedBox(width: 4),
                            Text('ENERGY IN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$energyIn',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                        ),
                        Text('Target: ${widget.log.targetCalories} kcal', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('vs', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ),

                // Energy OUT
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.secondaryCyan.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: 14, color: AppTheme.secondaryCyan),
                            const SizedBox(width: 4),
                            Text('ENERGY OUT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalEnergyOut',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                        ),
                        Text('BMR ($bmr) + Active ($activityBurn)', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Net Balance Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDeficit ? AppTheme.secondaryCyan.withOpacity(0.12) : AppTheme.primaryAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDeficit ? AppTheme.secondaryCyan.withOpacity(0.35) : AppTheme.primaryAmber.withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDeficit ? Icons.trending_down : Icons.trending_up,
                        size: 18,
                        color: isDeficit ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        netLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDeficit ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Goal: $targetDeficit kcal',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Toggle Expand Breakdown
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXPENDITURE BREAKDOWN (ALGORITHM B)',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppTheme.textSecondary),
                    ),
                    Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 8),
              _buildBreakdownRow('Basal Metabolism (Renpho LBM)', '$bmr kcal', AppTheme.textPrimary, Icons.accessibility_new),
              const SizedBox(height: 6),
              _buildBreakdownRow(
                wodActivity != null ? wodActivity.name : "Today's Lifting WOD",
                wodActivity != null ? '+${wodActivity.caloriesBurned} kcal' : '0 kcal (Rest/Untracked)',
                AppTheme.primaryAmber,
                Icons.fitness_center,
              ),
              if (nonWodBurn > 0) ...[
                const SizedBox(height: 6),
                _buildBreakdownRow(
                  'Daily Steps & Cardio (${nonWodActivities.length} logged)',
                  '+$nonWodBurn kcal',
                  AppTheme.secondaryCyan,
                  Icons.directions_walk,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
