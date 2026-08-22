import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/plate_calc.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class PlateCalculatorScreen extends StatefulWidget {
  const PlateCalculatorScreen({super.key});

  @override
  State<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends State<PlateCalculatorScreen> {
  double _targetWeightKg = 100.0;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '100.0');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setWeight(double weightKg) {
    setState(() {
      _targetWeightKg = weightKg < 0 ? 0 : weightKg;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final displayVal = settings.toDisplayWeight(_targetWeightKg);
      _controller.text = displayVal % 1 == 0
          ? displayVal.toInt().toString()
          : displayVal.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isLbs = settings.isLbs;

    final displayTarget = settings.toDisplayWeight(_targetWeightKg);
    final result = PlateCalculator.calculate(
      targetWeight: displayTarget,
      barWeight: settings.barWeight,
      collarWeight: settings.collarWeight,
      isLbs: isLbs,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Barbell Plate Loader', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar & Collar Settings Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BAR & COLLAR SPECIFICATIONS',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Barbell Weight:', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      DropdownButton<double>(
                        value: settings.barWeight,
                        dropdownColor: AppTheme.surfaceCard,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(value: 20.0, child: Text('20 kg (Men\'s Bar)', style: GoogleFonts.outfit())),
                          DropdownMenuItem(value: 15.0, child: Text('15 kg (Women\'s Bar)', style: GoogleFonts.outfit())),
                          DropdownMenuItem(value: 10.0, child: Text('10 kg (Technique Bar)', style: GoogleFonts.outfit())),
                          DropdownMenuItem(value: 45.0, child: Text('45 lbs (Standard Bar)', style: GoogleFonts.outfit())),
                        ],
                        onChanged: (val) => val != null ? settings.setBarWeight(val) : null,
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Collars Weight:', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      DropdownButton<double>(
                        value: settings.collarWeight,
                        dropdownColor: AppTheme.surfaceCard,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(value: 2.5, child: Text('2.5 kg Collars', style: GoogleFonts.outfit())),
                          DropdownMenuItem(value: 0.5, child: Text('0.5 kg Collars', style: GoogleFonts.outfit())),
                          DropdownMenuItem(value: 0.0, child: Text('No Collars', style: GoogleFonts.outfit())),
                        ],
                        onChanged: (val) => val != null ? settings.setCollarWeight(val) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weight Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('TARGET WEIGHT:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setState(() {
                                _targetWeightKg = settings.toBaseKg(parsed);
                              });
                            }
                          },
                        ),
                      ),
                      Text(settings.unitLabel.toUpperCase(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetChip('60', 60),
                      _buildPresetChip('80', 80),
                      _buildPresetChip('100', 100),
                      _buildPresetChip('120', 120),
                      _buildPresetChip('140', 140),
                      _buildPresetChip('160', 160),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Graphic Olympic Bar Rendering
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Bar Shaft
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A8F9E), Color(0xFFD0D5E0), Color(0xFF8A8F9E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Sleeve Stopper
                  Positioned(
                    left: 45,
                    child: Container(
                      width: 14,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3E4C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Bumper & Fractional Plates per side
                  Positioned(
                    left: 59,
                    right: 12,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (result.collarWeight > 0)
                            Container(
                              width: 10,
                              height: 35,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ...result.platesPerSide.map((plate) {
                            final plateHeight = 125.0 * plate.heightFactor;
                            final plateWidth = plate.isFractional ? 13.0 : 20.0;
                            return Container(
                              width: plateWidth,
                              height: plateHeight,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: plate.color,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    plate.label,
                                    style: TextStyle(
                                      color: plate.textColor,
                                      fontSize: plate.isFractional ? 9 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plate summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
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
                        'Total Loaded: ${result.actualWeight.toStringAsFixed(1)} ${result.unit}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                      ),
                      Text(
                        'Bar: ${result.barWeight} ${result.unit}',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('PLATES REQUIRED PER SIDE:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (result.platesPerSide.isEmpty)
                    Text('Empty Bar (0 plates required)', style: GoogleFonts.inter(color: AppTheme.textSecondary))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _groupPlates(result.platesPerSide).map((e) {
                        return Chip(
                          backgroundColor: e.key.color,
                          label: Text(
                            '${e.value}x ${e.key.label} ${result.unit}',
                            style: TextStyle(color: e.key.textColor, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double valKg) {
    return ActionChip(
      backgroundColor: AppTheme.surfaceElevated,
      label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryAmber)),
      onPressed: () => _setWeight(valKg),
    );
  }

  List<MapEntry<PlateSpec, int>> _groupPlates(List<PlateSpec> plates) {
    final map = <PlateSpec, int>{};
    for (var p in plates) {
      map[p] = (map[p] ?? 0) + 1;
    }
    return map.entries.toList();
  }
}
