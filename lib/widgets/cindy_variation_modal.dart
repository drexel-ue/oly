import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class CindyVariationModal extends StatefulWidget {
  const CindyVariationModal({
    required this.initialPullupVariation,
    required this.initialPushupVariation,
    required this.initialSquatVariation,
    required this.onApply,
    super.key,
    this.initialPullupWeightKg,
    this.initialPullupBand,
    this.initialPushupWeightKg,
    this.initialSquatWeightKg,
    this.initialSelectedMovement, // 'pull_ups', 'push_ups', 'squats', or null for all
  });

  final String initialPullupVariation;
  final double? initialPullupWeightKg;
  final String? initialPullupBand;

  final String initialPushupVariation;
  final double? initialPushupWeightKg;

  final String initialSquatVariation;
  final double? initialSquatWeightKg;

  final String? initialSelectedMovement;

  final void Function({
    required String pullupVariation,
    required String pushupVariation,
    required String squatVariation,
    double? pullupWeightKg,
    String? pullupBand,
    double? pushupWeightKg,
    double? squatWeightKg,
  }) onApply;

  @override
  State<CindyVariationModal> createState() => _CindyVariationModalState();
}

class _CindyVariationModalState extends State<CindyVariationModal> {
  late String _pullupVariation;
  late String? _pullupBand;
  late TextEditingController _pullupWeightController;

  late String _pushupVariation;
  late TextEditingController _pushupWeightController;

  late String _squatVariation;
  late TextEditingController _squatWeightController;

  @override
  void initState() {
    super.initState();
    _pullupVariation = widget.initialPullupVariation;
    _pullupBand = widget.initialPullupBand ?? 'medium';
    _pullupWeightController = TextEditingController(
      text: widget.initialPullupWeightKg != null
          ? widget.initialPullupWeightKg!.toStringAsFixed(1)
          : '10.0',
    );

    _pushupVariation = widget.initialPushupVariation;
    _pushupWeightController = TextEditingController(
      text: widget.initialPushupWeightKg != null
          ? widget.initialPushupWeightKg!.toStringAsFixed(1)
          : '10.0',
    );

    _squatVariation = widget.initialSquatVariation;
    _squatWeightController = TextEditingController(
      text: widget.initialSquatWeightKg != null
          ? widget.initialSquatWeightKg!.toStringAsFixed(1)
          : '16.0',
    );
  }

  @override
  void dispose() {
    _pullupWeightController.dispose();
    _pushupWeightController.dispose();
    _squatWeightController.dispose();
    super.dispose();
  }

  String _calculateTier() {
    final bool isScaled = _pullupVariation == 'band_assisted' ||
        _pullupVariation == 'ring_rows' ||
        _pullupVariation == 'jumping' ||
        _pushupVariation == 'knee' ||
        _pushupVariation == 'incline' ||
        _squatVariation == 'box_squat';

    if (isScaled) {
      return 'Scaled';
    }

    final bool isWeighted = _pullupVariation == 'weighted' ||
        _pushupVariation == 'weighted' ||
        _pushupVariation == 'pike' ||
        _pushupVariation == 'hspu' ||
        _squatVariation == 'goblet' ||
        _squatVariation == 'weighted_vest';

    if (isWeighted) {
      return 'Weighted';
    }

    return 'Rx';
  }

  void _applyChanges(SettingsProvider settings) {
    HapticFeedback.mediumImpact();
    double? pullupWeight;
    if (_pullupVariation == 'weighted') {
      final double entered = double.tryParse(_pullupWeightController.text) ?? 10.0;
      pullupWeight = settings.toBaseKg(entered);
    }

    double? pushupWeight;
    if (_pushupVariation == 'weighted') {
      final double entered = double.tryParse(_pushupWeightController.text) ?? 10.0;
      pushupWeight = settings.toBaseKg(entered);
    }

    double? squatWeight;
    if (_squatVariation == 'goblet' || _squatVariation == 'weighted_vest') {
      final double entered = double.tryParse(_squatWeightController.text) ?? 16.0;
      squatWeight = settings.toBaseKg(entered);
    }

    widget.onApply(
      pullupVariation: _pullupVariation,
      pullupWeightKg: pullupWeight,
      pullupBand: _pullupVariation == 'band_assisted' ? _pullupBand : null,
      pushupVariation: _pushupVariation,
      pushupWeightKg: pushupWeight,
      squatVariation: _squatVariation,
      squatWeightKg: squatWeight,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final String tier = _calculateTier();
    final Color tierColor = tier == 'Rx'
        ? AppTheme.primaryAmber
        : tier == 'Weighted'
            ? Colors.purpleAccent
            : Colors.tealAccent;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Movement Progressions',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Configure variations for this round & beyond',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      tier.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 24),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // 1. Pull-up Section
                    _buildSectionHeader(
                      title: '1. PULL-UPS (5 REPS)',
                      icon: Icons.fitness_center,
                      color: AppTheme.primaryAmber,
                    ),
                    const SizedBox(height: 8),
                    _buildVariationChips(
                      options: const <Map<String, String>>[
                        <String, String>{'id': 'standard', 'label': 'Strict (Rx)'},
                        <String, String>{'id': 'chin_up', 'label': 'Chin-up (Rx)'},
                        <String, String>{'id': 'band_assisted', 'label': 'Banded'},
                        <String, String>{'id': 'ring_rows', 'label': 'Ring Rows'},
                        <String, String>{'id': 'jumping', 'label': 'Jumping'},
                        <String, String>{'id': 'weighted', 'label': 'Weighted'},
                      ],
                      selectedId: _pullupVariation,
                      onSelected: (String id) {
                        setState(() => _pullupVariation = id);
                      },
                    ),
                    if (_pullupVariation == 'band_assisted') ...<Widget>[
                      const SizedBox(height: 10),
                      _buildSubOptionRow(
                        label: 'Band Tension:',
                        child: Row(
                          children: <String>['light', 'medium', 'heavy'].map((String band) {
                            final bool isSel = _pullupBand == band;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(band.toUpperCase()),
                                selected: isSel,
                                onSelected: (_) => setState(() => _pullupBand = band),
                                selectedColor: Colors.tealAccent.withValues(alpha: 0.2),
                                labelStyle: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.tealAccent : AppTheme.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (_pullupVariation == 'weighted') ...<Widget>[
                      const SizedBox(height: 10),
                      _buildWeightInputRow(
                        label: 'Added Load:',
                        controller: _pullupWeightController,
                        unit: settings.unitLabel,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 2. Push-up Section
                    _buildSectionHeader(
                      title: '2. PUSH-UPS (10 REPS)',
                      icon: Icons.sports_gymnastics,
                      color: AppTheme.secondaryCyan,
                    ),
                    const SizedBox(height: 8),
                    _buildVariationChips(
                      options: const <Map<String, String>>[
                        <String, String>{'id': 'standard', 'label': 'Strict (Rx)'},
                        <String, String>{'id': 'knee', 'label': 'Knee'},
                        <String, String>{'id': 'incline', 'label': 'Incline'},
                        <String, String>{'id': 'pike', 'label': 'Pike'},
                        <String, String>{'id': 'hspu', 'label': 'HSPU'},
                        <String, String>{'id': 'weighted', 'label': 'Weighted'},
                      ],
                      selectedId: _pushupVariation,
                      onSelected: (String id) {
                        setState(() => _pushupVariation = id);
                      },
                    ),
                    if (_pushupVariation == 'weighted') ...<Widget>[
                      const SizedBox(height: 10),
                      _buildWeightInputRow(
                        label: 'Plate / Load:',
                        controller: _pushupWeightController,
                        unit: settings.unitLabel,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 3. Squat Section
                    _buildSectionHeader(
                      title: '3. SQUATS (15 REPS)',
                      icon: Icons.directions_walk,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildVariationChips(
                      options: const <Map<String, String>>[
                        <String, String>{'id': 'standard', 'label': 'Air Squat (Rx)'},
                        <String, String>{'id': 'box_squat', 'label': 'Box Squat'},
                        <String, String>{'id': 'goblet', 'label': 'Goblet'},
                        <String, String>{'id': 'weighted_vest', 'label': 'Weight Vest'},
                      ],
                      selectedId: _squatVariation,
                      onSelected: (String id) {
                        setState(() => _squatVariation = id);
                      },
                    ),
                    if (_squatVariation == 'goblet' || _squatVariation == 'weighted_vest') ...<Widget>[
                      const SizedBox(height: 10),
                      _buildWeightInputRow(
                        label: _squatVariation == 'goblet' ? 'KB/DB Weight:' : 'Vest Weight:',
                        controller: _squatWeightController,
                        unit: settings.unitLabel,
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _applyChanges(settings),
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: Text(
                    'Apply Progressions ($tier)',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildVariationChips({
    required List<Map<String, String>> options,
    required String selectedId,
    required void Function(String id) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((Map<String, String> opt) {
        final String id = opt['id']!;
        final String label = opt['label']!;
        final bool isSel = id == selectedId;
        return ChoiceChip(
          label: Text(label),
          selected: isSel,
          onSelected: (_) => onSelected(id),
          backgroundColor: AppTheme.surfaceElevated,
          selectedColor: AppTheme.primaryAmber.withValues(alpha: 0.2),
          side: BorderSide(
            color: isSel ? AppTheme.primaryAmber : AppTheme.borderColor,
          ),
          labelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSel ? AppTheme.primaryAmber : AppTheme.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubOptionRow({
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildWeightInputRow({
    required String label,
    required TextEditingController controller,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                suffixText: unit,
                suffixStyle: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
