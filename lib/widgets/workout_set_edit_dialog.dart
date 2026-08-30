import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class WorkoutSetEditDialog extends StatefulWidget {
  const WorkoutSetEditDialog({
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    required this.onSaveSet,
    super.key,
  });

  final String exerciseName;
  final CompletedSet currentSet;
  final int totalSets;
  final void Function({
    required double newWeightKg,
    required int newReps,
    required bool isCompleted,
    bool applyToSubsequentSets,
  }) onSaveSet;

  @override
  State<WorkoutSetEditDialog> createState() => _WorkoutSetEditDialogState();
}

class _WorkoutSetEditDialogState extends State<WorkoutSetEditDialog> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  late double _currentWeightKg;
  late int _currentReps;
  late bool _isCompleted;
  bool _applyToSubsequent = false;

  @override
  void initState() {
    super.initState();
    _currentWeightKg = widget.currentSet.weight;
    _currentReps = widget.currentSet.reps;
    _isCompleted = widget.currentSet.isCompleted;

    _weightController = TextEditingController();
    _repsController = TextEditingController(text: '$_currentReps');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SettingsProvider settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final double displayWeight = settings.toDisplayWeight(_currentWeightKg);
    _weightController.text = _formatNumber(displayWeight);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  String _formatNumber(double val) {
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  void _adjustWeight(double deltaDisplay, SettingsProvider settings) {
    final double currentDisplay =
        double.tryParse(_weightController.text) ??
        settings.toDisplayWeight(_currentWeightKg);
    final double newDisplay = (currentDisplay + deltaDisplay).clamp(0.0, 999.0);
    final double newKg = settings.toBaseKg(newDisplay);
    setState(() {
      _currentWeightKg = newKg;
      _weightController.text = _formatNumber(newDisplay);
    });
  }

  void _adjustReps(int delta) {
    final int current = int.tryParse(_repsController.text) ?? _currentReps;
    final int newReps = (current + delta).clamp(1, 99);
    setState(() {
      _currentReps = newReps;
      _repsController.text = '$_currentReps';
    });
  }

  void _setReps(int reps) {
    if (reps < 1) return;
    setState(() {
      _currentReps = reps;
      _repsController.text = '$_currentReps';
    });
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final List<double> steppers = settings.isLbs
        ? <double>[-10.0, -5.0, -2.5, 2.5, 5.0, 10.0]
        : <double>[-5.0, -2.5, -1.0, 1.0, 2.5, 5.0];
    const List<int> repPresets = <int>[1, 2, 3, 5, 8, 10, 12];

    final bool hasSubsequentSets = widget.currentSet.setIndex < widget.totalSets;

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
            children: <Widget>[
              // Drag handle
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Edit Set ${widget.currentSet.setIndex}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
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

              const SizedBox(height: 16),

              // WEIGHT SECTION
              Text(
                'SET WEIGHT (${settings.unitLabel.toUpperCase()})',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryAmber, width: 1.5),
                ),
                child: Row(
                  children: <Widget>[
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
                        onChanged: (String val) {
                          final double? parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            setState(() {
                              _currentWeightKg = settings.toBaseKg(parsed);
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

              // Weight Steppers
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: steppers.map((double delta) {
                    final bool isPositive = delta > 0;
                    final String text = isPositive ? '+$delta' : '$delta';
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

              const SizedBox(height: 16),

              // REPS SECTION
              Text(
                'COMPLETED REPS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.secondaryCyan, width: 1.5),
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _currentReps > 1
                          ? AppTheme.secondaryCyan
                          : AppTheme.textSecondary.withValues(alpha: 0.3),
                      onPressed: _currentReps > 1
                          ? () => _adjustReps(-1)
                          : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '1',
                        ),
                        onChanged: (String val) {
                          final int? parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 1) {
                            setState(() {
                              _currentReps = parsed;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.secondaryCyan,
                      onPressed: () => _adjustReps(1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REPS',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Rep Presets Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: repPresets.map((int r) {
                    final bool isSelected = _currentReps == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSelected,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        backgroundColor: AppTheme.surfaceElevated,
                        selectedColor: AppTheme.secondaryCyan.withValues(alpha: 0.25),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.secondaryCyan
                              : AppTheme.borderColor,
                        ),
                        label: Text(
                          '$r ${r == 1 ? 'Rep' : 'Reps'}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppTheme.secondaryCyan
                                : AppTheme.textSecondary,
                          ),
                        ),
                        onSelected: (_) => _setReps(r),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // COMPLETION TOGGLE CARD
              InkWell(
                onTap: () {
                  setState(() {
                    _isCompleted = !_isCompleted;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isCompleted
                          ? AppTheme.primaryAmber.withValues(alpha: 0.5)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Mark Set as Completed',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isCompleted
                                  ? 'Counts toward total volume & active MET'
                                  : 'Pending completion',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _isCompleted
                                    ? AppTheme.primaryAmber
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isCompleted,
                        activeColor: AppTheme.primaryAmber,
                        onChanged: (bool val) {
                          setState(() {
                            _isCompleted = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (hasSubsequentSets) ...<Widget>[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(() {
                      _applyToSubsequent = !_applyToSubsequent;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                          value: _applyToSubsequent,
                          activeColor: AppTheme.primaryAmber,
                          checkColor: Colors.black,
                          onChanged: (bool? val) {
                            setState(() {
                              _applyToSubsequent = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Apply weight & reps to remaining sets (${widget.currentSet.setIndex + 1} to ${widget.totalSets})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ACTION BUTTONS
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        widget.onSaveSet(
                          newWeightKg: _currentWeightKg,
                          newReps: _currentReps,
                          isCompleted: _isCompleted,
                          applyToSubsequentSets: _applyToSubsequent,
                        );
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.check, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Save Set',
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
