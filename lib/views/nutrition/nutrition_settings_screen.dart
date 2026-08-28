import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/nutrition_goal_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class NutritionSettingsScreen extends StatefulWidget {
  const NutritionSettingsScreen({super.key});

  @override
  State<NutritionSettingsScreen> createState() =>
      _NutritionSettingsScreenState();
}

class _NutritionSettingsScreenState extends State<NutritionSettingsScreen> {
  late GoalType _goalType;
  late double _targetBfPct;
  late double _proteinMultiplier;
  late int _calorieAdjustment;
  late bool _carbCyclingEnabled;
  late int _trainingBonusCals;
  late double _trainingBonusCarbs;

  @override
  void initState() {
    super.initState();
    final NutritionGoalModel goal = Provider.of<NutritionProvider>(
      context,
      listen: false,
    ).goal;
    _goalType = goal.goalType;
    _targetBfPct = goal.targetBodyFatPct;
    _proteinMultiplier = goal.proteinGramsPerLbLbm;
    _calorieAdjustment = goal.dailyCalorieAdjustment;
    _carbCyclingEnabled = goal.carbCyclingEnabled;
    _trainingBonusCals = goal.trainingDayBonusCalories;
    _trainingBonusCarbs = goal.trainingDayCarbBonusGrams;
  }

  void _saveGoal() {
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(
      context,
      listen: false,
    );
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(
      context,
      listen: false,
    );

    final NutritionGoalModel updated = nutrition.goal.copyWith(
      goalType: _goalType,
      targetBodyFatPct: _targetBfPct,
      proteinGramsPerLbLbm: _proteinMultiplier,
      dailyCalorieAdjustment: _calorieAdjustment,
      carbCyclingEnabled: _carbCyclingEnabled,
      trainingDayBonusCalories: _trainingBonusCals,
      trainingDayCarbBonusGrams: _trainingBonusCarbs,
    );

    nutrition.updateGoal(updated, latestBodyComp: bodyComp.latestEntry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Nutrition & Macro Goals',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PRIMARY STRATEGY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // Goal Type Selection Cards
              ...GoalType.values.map((GoalType type) {
                final bool isSelected = _goalType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _goalType = type;
                      if (type == GoalType.cutting) {
                        _calorieAdjustment = -450;
                      }
                      if (type == GoalType.leanBulking) {
                        _calorieAdjustment = 250;
                      }
                      if (type == GoalType.recomposition) {
                        _calorieAdjustment = 0;
                      }
                      if (type == GoalType.maintenance) {
                        _calorieAdjustment = 0;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryAmber.withValues(alpha: 0.12)
                          : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryAmber
                            : AppTheme.borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppTheme.primaryAmber
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                type.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Protein Multiplier Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Protein Target (per lb Lean Mass)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${_proteinMultiplier.toStringAsFixed(2)} g/lb LBM',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Strength standard: 1.0 to 1.15 g per lb of Fat-Free Mass to prevent muscle loss.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Slider(
                      value: _proteinMultiplier,
                      min: 0.80,
                      max: 1.40,
                      divisions: 12,
                      activeColor: AppTheme.secondaryCyan,
                      inactiveColor: Colors.white10,
                      onChanged: (double val) =>
                          setState(() => _proteinMultiplier = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Carb Cycling & Training Day Fueling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Periodized Carb Cycling',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Automatically boosts carbs and calories on heavy training days.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch.adaptive(
                          value: _carbCyclingEnabled,
                          activeTrackColor: AppTheme.primaryAmber,
                          onChanged: (bool val) =>
                              setState(() => _carbCyclingEnabled = val),
                        ),
                      ],
                    ),
                    if (_carbCyclingEnabled) ...<Widget>[
                      const Divider(color: AppTheme.borderColor, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Training Day Calorie Bonus',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '+$_trainingBonusCals kcal (+${_trainingBonusCarbs.toStringAsFixed(0)}g Carbs)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Daily Hydration Algorithm Strategy
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D2FF)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: Color(0xFF00D2FF),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Smart Hydration Algorithm',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'ACSM / ISSN Lean Body Mass & Exertion Model',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• 0.65 oz per lb Lean Mass (muscle is ~75% water)\n'
                      '• 0.25 oz per lb Fat Mass\n'
                      '• +24 oz on Olympic lifting & training days\n'
                      '• +12 oz recovery boost when Renpho Body Water < 55%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Nutrition Strategy',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
