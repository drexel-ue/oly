import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/activity_expenditure_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ActivityLogSheet extends StatefulWidget {
  const ActivityLogSheet({super.key});

  @override
  State<ActivityLogSheet> createState() => _ActivityLogSheetState();
}

class _ActivityLogSheetState extends State<ActivityLogSheet> {
  String _selectedActivityType = 'walking_steps';
  String _activityName = 'Brisk Walk (3.5 mph)';
  double _metValue = 3.8;
  double _durationMinutes = 30.0;
  int _stepsCount = 6000;
  double _distanceMiles = 2.8;
  final TextEditingController _nameController = TextEditingController(
    text: 'Brisk Walk (3.5 mph)',
  );
  final TextEditingController _notesController = TextEditingController();

  final List<CompendiumActivity> _presets =
      ActivityExpenditureService.compendiumCatalog;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectPreset(CompendiumActivity preset) {
    setState(() {
      _selectedActivityType = preset.id;
      _activityName = preset.name;
      _nameController.text = preset.name;
      _metValue = preset.met;
      if (preset.id.contains('sprint')) {
        _durationMinutes = 10.0;
      } else if (preset.id.contains('walking')) {
        _durationMinutes = 30.0;
      }
    });
  }

  void _onStepsChanged(int steps, double lbmLb, double weightLb) {
    final (
      int cal,
      double miles,
    ) = ActivityExpenditureService.calculateStepsExpenditure(
      steps: steps,
      weightLb: weightLb,
      leanBodyMassLb: lbmLb,
    );
    setState(() {
      _stepsCount = steps;
      _distanceMiles = miles;
      _durationMinutes = (miles * 17.0)
          .roundToDouble(); // ~17 min/mile brisk walk
    });
  }

  @override
  Widget build(BuildContext context) {
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context);
    final double lbm = bodyComp.latestEntry?.leanBodyMassLb ?? 208.6;
    final double weight = bodyComp.latestEntry?.weightLb ?? 264.8;

    final int calAlgorithmB =
        ActivityExpenditureService.calculateAdjustedCalories(
          met: _metValue,
          leanBodyMassLb: lbm,
          durationMinutes: _durationMinutes,
        );

    final int calAlgorithmA =
        ActivityExpenditureService.calculateStandardCalories(
          met: _metValue,
          weightKg: weight / 2.20462,
          durationMinutes: _durationMinutes,
        );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Log Activity & Energy Out',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Preset Chips
                  Text(
                    'COMPENDIUM ACTIVITY PRESETS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((CompendiumActivity preset) {
                      final bool isSelected =
                          _selectedActivityType == preset.id;
                      return ChoiceChip(
                        label: Text(
                          preset.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryAmber.withValues(
                          alpha: 0.2,
                        ),
                        backgroundColor: AppTheme.surfaceCard,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryAmber
                              : AppTheme.textPrimary,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryAmber
                              : AppTheme.borderColor,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            _selectPreset(preset);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Calculated Energy Box (Algorithm B vs A)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.bolt,
                                  color: AppTheme.secondaryCyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ESTIMATED CALORIES (ALGORITHM B)',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$calAlgorithmB kcal',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryCyan,
                              ),
                            ),
                            Text(
                              'Standard Algorithm A: $calAlgorithmA kcal (${((calAlgorithmA - calAlgorithmB) / calAlgorithmB * 100).round()}% higher)',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            '$_metValue MET',
                            style: GoogleFonts.firaCode(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Step Calculator (if walking/steps selected)
                  if (_selectedActivityType.contains('walking')) ...<Widget>[
                    Text(
                      'DAILY STEPS CALCULATOR',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                '$_stepsCount steps',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '~$_distanceMiles miles',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.primaryAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _stepsCount.toDouble(),
                            min: 1000,
                            max: 25000,
                            divisions: 48,
                            activeColor: AppTheme.primaryAmber,
                            inactiveColor: AppTheme.borderColor,
                            onChanged: (double val) =>
                                _onStepsChanged(val.round(), lbm, weight),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Duration Slider
                  Text(
                    'DURATION: ${_durationMinutes.round()} MINUTES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: _durationMinutes,
                    min: 5,
                    max: 180,
                    divisions: 35,
                    activeColor: AppTheme.secondaryCyan,
                    inactiveColor: AppTheme.borderColor,
                    onChanged: (double val) =>
                        setState(() => _durationMinutes = val),
                  ),

                  const SizedBox(height: 12),

                  // Name / Notes TextField
                  Text(
                    'ACTIVITY NAME / NOTES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Activity title',
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final DailyActivityEntry entry =
                            DailyActivityEntry.create(
                              activityType: _selectedActivityType,
                              name: _nameController.text.trim().isNotEmpty
                                  ? _nameController.text.trim()
                                  : _activityName,
                              durationMinutes: _durationMinutes,
                              stepsCount:
                                  _selectedActivityType.contains('walking')
                                  ? _stepsCount
                                  : null,
                              distanceMiles:
                                  _selectedActivityType.contains('walking')
                                  ? _distanceMiles
                                  : null,
                              metValue: _metValue,
                              caloriesBurned: calAlgorithmB,
                              source: 'manual',
                            );

                        final NutritionProvider provider =
                            Provider.of<NutritionProvider>(
                              context,
                              listen: false,
                            );
                        provider.addActivity(
                          entry,
                          latestBodyComp: bodyComp.latestEntry,
                        );

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ Logged ${entry.name} ($calAlgorithmB kcal burned)',
                            ),
                            backgroundColor: AppTheme.secondaryCyan,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Log $calAlgorithmB kcal Activity',
                        style: GoogleFonts.inter(
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
        ],
      ),
    );
  }
}
