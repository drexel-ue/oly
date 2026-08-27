import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/lift_model.dart';
import '../models/program_model.dart';
import '../providers/lift_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class WorkoutWeightHelper {
  /// Calculates the implied 1RM given the working weight and periodization rules.
  static double calculateImplied1RMPeriodization({
    required double workingWeightKg,
    required ExerciseTemplate exerciseTemplate,
    required int currentWeek,
  }) {
    if (workingWeightKg <= 0) return 0.0;

    if (exerciseTemplate.weekPercentages != null &&
        exerciseTemplate.weekPercentages!.containsKey(currentWeek)) {
      final pct = exerciseTemplate.weekPercentages![currentWeek]!;
      if (pct > 0) {
        return workingWeightKg / (pct / 100.0);
      }
    }

    if (exerciseTemplate.fixedPercentage != null &&
        exerciseTemplate.fixedPercentage! > 0) {
      return workingWeightKg / (exerciseTemplate.fixedPercentage! / 100.0);
    }

    if (exerciseTemplate.weeklyWeightIncrementKg != null) {
      final inc = exerciseTemplate.weeklyWeightIncrementKg!;
      final incTotal = (currentWeek - 1) * inc;
      final adjusted = workingWeightKg - incTotal;
      if (adjusted > 0) {
        return adjusted / 0.60;
      }
      return workingWeightKg / 0.60;
    }

    // Default 75%
    return workingWeightKg / 0.75;
  }

  /// Calculates the implied 1RM using the Epley formula: Weight * (1 + reps / 30.0)
  static double calculateImplied1RMEpley({
    required double workingWeightKg,
    required int reps,
  }) {
    if (workingWeightKg <= 0) return 0.0;
    if (reps <= 1) return workingWeightKg;
    return workingWeightKg * (1.0 + reps / 30.0);
  }

  /// Returns the target percentage as a number (e.g. 70.0 for 70%) if percentage based
  static double? getPeriodizationPercentage({
    required ExerciseTemplate exerciseTemplate,
    required int currentWeek,
  }) {
    if (exerciseTemplate.weekPercentages != null &&
        exerciseTemplate.weekPercentages!.containsKey(currentWeek)) {
      return exerciseTemplate.weekPercentages![currentWeek]!;
    }
    if (exerciseTemplate.fixedPercentage != null) {
      return exerciseTemplate.fixedPercentage!;
    }
    return null;
  }

  /// Extracts the target reps count from setScheme (e.g. '4 Sets of 2 Reps' -> 2)
  static int extractRepsCount(String setScheme) {
    final repMatch = RegExp(r'(\d+)\s+Reps', caseSensitive: false).firstMatch(setScheme);
    if (repMatch != null) {
      return int.tryParse(repMatch.group(1)!) ?? 1;
    }
    return 1;
  }
}

class WorkoutWeightDialog extends StatefulWidget {
  final ExerciseTemplate exercise;
  final String displayName;
  final double initialWeightKg;
  final int currentWeek;
  final void Function({
    required double newWeightKg,
    required bool update1RM,
    double? new1RMKg,
  }) onWeightUpdated;

  const WorkoutWeightDialog({
    super.key,
    required this.exercise,
    required this.displayName,
    required this.initialWeightKg,
    required this.currentWeek,
    required this.onWeightUpdated,
  });

  @override
  State<WorkoutWeightDialog> createState() => _WorkoutWeightDialogState();
}

class _WorkoutWeightDialogState extends State<WorkoutWeightDialog> {
  late TextEditingController _weightController;
  late TextEditingController _target1RMController;

  double _currentWeightKg = 0.0;
  double _calculated1RMKg = 0.0;
  bool _useEpleyFormula = false;

  @override
  void initState() {
    super.initState();
    _currentWeightKg = widget.initialWeightKg;
    _recalculate1RM();

    _weightController = TextEditingController();
    _target1RMController = TextEditingController();

    // Initial controllers text formatted with settings in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final displayWeight = settings.toDisplayWeight(_currentWeightKg);
    _weightController.text = _formatNumber(displayWeight);

    final display1RM = settings.toDisplayWeight(_calculated1RMKg);
    _target1RMController.text = _formatNumber(display1RM);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _target1RMController.dispose();
    super.dispose();
  }

  String _formatNumber(double val) {
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  void _recalculate1RM() {
    if (_useEpleyFormula) {
      final reps = WorkoutWeightHelper.extractRepsCount(widget.exercise.setScheme);
      _calculated1RMKg = WorkoutWeightHelper.calculateImplied1RMEpley(
        workingWeightKg: _currentWeightKg,
        reps: reps,
      );
    } else {
      _calculated1RMKg = WorkoutWeightHelper.calculateImplied1RMPeriodization(
        workingWeightKg: _currentWeightKg,
        exerciseTemplate: widget.exercise,
        currentWeek: widget.currentWeek,
      );
    }
  }

  void _updateWeight(double newWeightKg, SettingsProvider settings) {
    if (newWeightKg < 0) return;
    setState(() {
      _currentWeightKg = newWeightKg;
      _recalculate1RM();

      final displayWeight = settings.toDisplayWeight(_currentWeightKg);
      _weightController.text = _formatNumber(displayWeight);

      final display1RM = settings.toDisplayWeight(_calculated1RMKg);
      _target1RMController.text = _formatNumber(display1RM);
    });
  }

  void _adjustWeight(double deltaDisplay, SettingsProvider settings) {
    final currentDisplay = double.tryParse(_weightController.text) ??
        settings.toDisplayWeight(_currentWeightKg);
    final newDisplay = (currentDisplay + deltaDisplay).clamp(0.0, 999.0);
    final newKg = settings.toBaseKg(newDisplay);
    _updateWeight(newKg, settings);
  }

  LiftModel _resolveTargetLift(LiftProvider liftProvider) {
    // 1. Try finding by displayName (if swapped)
    final byName = liftProvider.lifts.firstWhere(
      (l) => l.name.toLowerCase() == widget.displayName.toLowerCase(),
      orElse: () => liftProvider.lifts.firstWhere(
        (l) => l.id.toLowerCase() == widget.exercise.liftId.toLowerCase(),
        orElse: () => liftProvider.lifts.first,
      ),
    );
    return byName;
  }

  @override
  Widget build(BuildContext context) {
    final liftProvider = Provider.of<LiftProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final targetLift = _resolveTargetLift(liftProvider);
    final reps = WorkoutWeightHelper.extractRepsCount(widget.exercise.setScheme);

    final targetPct = WorkoutWeightHelper.getPeriodizationPercentage(
      exerciseTemplate: widget.exercise,
      currentWeek: widget.currentWeek,
    );

    final deltaKg = _calculated1RMKg - targetLift.currentMax;
    final deltaDisplay = settings.toDisplayWeight(deltaKg);
    final deltaSign = deltaKg >= 0 ? '+' : '';

    final steppers = settings.isLbs
        ? [-10.0, -5.0, -2.5, 2.5, 5.0, 10.0]
        : [-5.0, -2.5, -1.0, 1.0, 2.5, 5.0];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Working Weight & 1RM',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Current Lift Baseline Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppTheme.secondaryCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catalog Lift: ${targetLift.name}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Current 1RM: ${settings.formatWeight(targetLift.currentMax)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (targetPct != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${targetPct.toStringAsFixed(0)}% Target',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SECTION 1: WORKING WEIGHT INPUT
              Text(
                'WORKING WEIGHT (${settings.unitLabel.toUpperCase()})',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryAmber, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.0',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 28,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            final baseKg = settings.toBaseKg(parsed);
                            setState(() {
                              _currentWeightKg = baseKg;
                              _recalculate1RM();
                              final display1RM = settings.toDisplayWeight(
                                _calculated1RMKg,
                              );
                              _target1RMController.text = _formatNumber(
                                display1RM,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    Text(
                      settings.unitLabel.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Quick Adjust Steppers
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: steppers.map((delta) {
                    final isPositive = delta > 0;
                    final text = isPositive ? '+$delta' : '$delta';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        backgroundColor: AppTheme.surfaceElevated,
                        side: const BorderSide(color: AppTheme.borderColor),
                        label: Text(
                          text,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? AppTheme.secondaryCyan
                                : AppTheme.textSecondary,
                          ),
                        ),
                        onPressed: () => _adjustWeight(delta, settings),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: 1RM RECALCULATION & ESTIMATION CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.secondaryCyan,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'RECALCULATED 1RM ESTIMATE',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppTheme.secondaryCyan,
                              ),
                            ),
                          ],
                        ),
                        // Formula switcher
                        InkWell(
                          onTap: () {
                            setState(() {
                              _useEpleyFormula = !_useEpleyFormula;
                              _recalculate1RM();
                              final display1RM = settings.toDisplayWeight(
                                _calculated1RMKg,
                              );
                              _target1RMController.text = _formatNumber(
                                display1RM,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              _useEpleyFormula
                                  ? 'Formula: Epley ($reps Reps)'
                                  : 'Formula: Periodization (${targetPct != null ? '${targetPct.toStringAsFixed(0)}%' : '75%'})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          settings.formatWeight(_calculated1RMKg),
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: deltaKg >= 0
                                ? AppTheme.successGreen.withValues(alpha: 0.15)
                                : AppTheme.warningOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$deltaSign${settings.formatWeight(deltaDisplay.abs())} vs PR',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: deltaKg >= 0
                                  ? AppTheme.successGreen
                                  : AppTheme.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Editable Fine-tune 1RM Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _target1RMController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  'Adjusted 1RM to Save (${settings.unitLabel.toUpperCase()})',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.secondaryCyan,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ACTION BUTTONS
              Row(
                children: [
                  // Button 1: Update Workout Weight Only
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        widget.onWeightUpdated(
                          newWeightKg: _currentWeightKg,
                          update1RM: false,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Weight Only',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Button 2: Update Weight & Recalculate 1RM
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final parsed1RMDisplay = double.tryParse(
                          _target1RMController.text,
                        );
                        final final1RMKg = parsed1RMDisplay != null
                            ? settings.toBaseKg(parsed1RMDisplay)
                            : _calculated1RMKg;

                        widget.onWeightUpdated(
                          newWeightKg: _currentWeightKg,
                          update1RM: true,
                          new1RMKg: final1RMKg,
                        );
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sync_alt, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Update & Recalc 1RM',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
