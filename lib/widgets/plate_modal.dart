import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/plate_calc.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class PlateModal extends StatefulWidget {
  final double initialWeightKg;

  const PlateModal({super.key, required this.initialWeightKg});

  @override
  State<PlateModal> createState() => _PlateModalState();
}

class _PlateModalState extends State<PlateModal> {
  late double _targetWeight;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _targetWeight = widget.initialWeightKg;
    _controller = TextEditingController(text: _targetWeight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateWeight(double newWeight) {
    setState(() {
      _targetWeight = newWeight < 0 ? 0 : newWeight;
      _controller.text = _targetWeight % 1 == 0
          ? _targetWeight.toInt().toString()
          : _targetWeight.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isLbs = settings.isLbs;

    final displayTarget = settings.toDisplayWeight(_targetWeight);
    final result = PlateCalculator.calculate(
      targetWeight: displayTarget,
      barWeight: settings.barWeight,
      collarWeight: settings.collarWeight,
      isLbs: isLbs,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Barbell Plate Loader',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Weight Controls
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Target:',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                            decoration: const InputDecoration(border: InputBorder.none),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null) {
                                setState(() {
                                  _targetWeight = settings.toBaseKg(parsed);
                                });
                              }
                            },
                          ),
                        ),
                        Text(
                          settings.unitLabel.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick increment buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepButton('-10', () => _updateWeight(_targetWeight - (isLbs ? 10 : 5))),
                _buildStepButton('-2.5', () => _updateWeight(_targetWeight - (isLbs ? 2.5 : 2.5))),
                _buildStepButton('+2.5', () => _updateWeight(_targetWeight + (isLbs ? 2.5 : 2.5))),
                _buildStepButton('+10', () => _updateWeight(_targetWeight + (isLbs ? 10 : 5))),
              ],
            ),
            const SizedBox(height: 24),

            // VISUAL BARBELL DISPLAY
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
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
                      height: 16,
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
                  // Collar stop
                  Positioned(
                    left: 40,
                    child: Container(
                      width: 14,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A4E5C),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  ),
                  // Sleeve & Plates
                  Positioned(
                    left: 54,
                    right: 12,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Collar plate
                          if (result.collarWeight > 0)
                            Container(
                              width: 10,
                              height: 30,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          // Plates rendered per side
                          ...result.platesPerSide.map((plate) {
                            final plateHeight = 110.0 * plate.heightFactor;
                            final plateWidth = plate.isFractional ? 12.0 : 18.0;
                            return Container(
                              width: plateWidth,
                              height: plateHeight,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: plate.color,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black26),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 3,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    plate.label,
                                    style: TextStyle(
                                      color: plate.textColor,
                                      fontSize: plate.isFractional ? 9 : 11,
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
            const SizedBox(height: 16),

            // Breakdown Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Weight: ${result.actualWeight.toStringAsFixed(1)} ${result.unit}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                      Text(
                        'Bar: ${result.barWeight} ${result.unit}',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Per Side Plates:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  if (result.platesPerSide.isEmpty)
                    Text(
                      'Empty Bar (No plates required)',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _groupPlates(result.platesPerSide).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.key.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.value}x ${item.key.label} ${result.unit}',
                            style: TextStyle(
                              color: item.key.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  List<MapEntry<PlateSpec, int>> _groupPlates(List<PlateSpec> plates) {
    final map = <PlateSpec, int>{};
    for (var p in plates) {
      map[p] = (map[p] ?? 0) + 1;
    }
    return map.entries.toList();
  }

  Widget _buildStepButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryAmber,
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
    );
  }
}
