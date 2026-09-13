import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class DynamometerEntrySheet extends StatefulWidget {
  const new({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DynamometerEntrySheet(),
    );
  }

  @override
  State<DynamometerEntrySheet> createState() => _DynamometerEntrySheetState();
}

class _DynamometerEntrySheetState extends State<DynamometerEntrySheet> {
  late TextEditingController _leftController;
  late TextEditingController _rightController;
  late TextEditingController _notesController;

  double _leftKg = 48;
  double _rightKg = 50;

  @override
  void initState() {
    super.initState();
    final GripHangProvider grip =
        Provider.of<GripHangProvider>(context, listen: false);
    final DynamometerEntry? latest = grip.latestDynamometerEntry;
    if (latest != null) {
      _leftKg = latest.leftHandKg;
      _rightKg = latest.rightHandKg;
    }
    _leftController = TextEditingController(text: _leftKg.toStringAsFixed(1));
    _rightController = TextEditingController(text: _rightKg.toStringAsFixed(1));
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onLeftChanged(String val) {
    final double? parsed = double.tryParse(val);
    if (parsed != null && parsed >= 0) {
      setState(() => _leftKg = parsed);
    }
  }

  void _onRightChanged(String val) {
    final double? parsed = double.tryParse(val);
    if (parsed != null && parsed >= 0) {
      setState(() => _rightKg = parsed);
    }
  }

  void _stepValue({required bool isLeft, required double delta}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isLeft) {
        _leftKg = (_leftKg + delta).clamp(0, 150);
        _leftController.text = _leftKg.toStringAsFixed(1);
      } else {
        _rightKg = (_rightKg + delta).clamp(0, 150);
        _rightController.text = _rightKg.toStringAsFixed(1);
      }
    });
  }

  Future<void> _saveEntry() async {
    await HapticFeedback.heavyImpact();
    if (!mounted) return;
    final GripHangProvider grip =
        Provider.of<GripHangProvider>(context, listen: false);

    await grip.addDynamometerEntry(
      leftHandKg: _leftKg,
      rightHandKg: _rightKg,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Grip force logged: ${_rightKg.toStringAsFixed(1)} kg R / ${_leftKg.toStringAsFixed(1)} kg L',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GripHangProvider grip = Provider.of<GripHangProvider>(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final bool isLbs = settings.isLbs;

    final double maxVal = _leftKg > _rightKg ? _leftKg : _rightKg;
    final double minVal = _leftKg < _rightKg ? _leftKg : _rightKg;
    final double asymmetry =
        maxVal > 0 ? ((maxVal - minVal) / maxVal) * 100.0 : 0.0;
    final String dominant = _rightKg >= _leftKg ? 'Right' : 'Left';

    final double displayLeft = isLbs ? _leftKg * 2.20462 : _leftKg;
    final double displayRight = isLbs ? _rightKg * 2.20462 : _rightKg;
    final String unitLabel = isLbs ? 'lbs' : 'kg';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grab Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pan_tool_outlined,
                    color: AppTheme.primaryAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Home Dynamometer Test',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Isometric Peak Grip Force & CNS Readiness',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
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
            const SizedBox(height: 20),

            // Bilateral Symmetry & CNS Readiness Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: asymmetry <= 10.0
                      ? AppTheme.successGreen.withValues(alpha: 0.4)
                      : AppTheme.primaryAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            asymmetry <= 10.0
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: asymmetry <= 10.0
                                ? AppTheme.successGreen
                                : AppTheme.primaryAmber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            asymmetry <= 10.0
                                ? 'Bilateral Balance: Symmetric'
                                : '$dominant Dominant (+${asymmetry.toStringAsFixed(1)}%)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CNS: ${grip.cnsReadinessPercent}%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _rightKg + _leftKg > 0
                          ? _leftKg / (_leftKg + _rightKg)
                          : 0.5,
                      backgroundColor: AppTheme.primaryAmber,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.secondaryCyan,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Left: ${displayLeft.toStringAsFixed(1)} $unitLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.secondaryCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Right: ${displayRight.toStringAsFixed(1)} $unitLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.primaryAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hand Stepper Inputs Row
            Row(
              children: <Widget>[
                // Left Hand Input
                Expanded(
                  child: _buildHandInputCard(
                    title: 'LEFT HAND',
                    color: AppTheme.secondaryCyan,
                    valueKg: _leftKg,
                    controller: _leftController,
                    unitLabel: unitLabel,
                    onChanged: _onLeftChanged,
                    onDecrement: () =>
                        _stepValue(isLeft: true, delta: -0.5),
                    onIncrement: () =>
                        _stepValue(isLeft: true, delta: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                // Right Hand Input
                Expanded(
                  child: _buildHandInputCard(
                    title: 'RIGHT HAND',
                    color: AppTheme.primaryAmber,
                    valueKg: _rightKg,
                    controller: _rightController,
                    unitLabel: unitLabel,
                    onChanged: _onRightChanged,
                    onDecrement: () =>
                        _stepValue(isLeft: false, delta: -0.5),
                    onIncrement: () =>
                        _stepValue(isLeft: false, delta: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes field
            TextField(
              controller: _notesController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Notes (e.g. Morning test, pre-workout, fatigued)...',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryAmber),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            OlyPressable(
              onPressed: _saveEntry,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppTheme.primaryAmber, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'LOG GRIP MEASUREMENT',
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),

            // Recent Logs Glance
            if (grip.dynamometerEntries.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Text(
                'RECENT MEASUREMENTS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...grip.dynamometerEntries.take(3).map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        DateFormat('MMM d, h:mm a').format(e.date),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${e.rightHandKg.toStringAsFixed(1)} kg R / ${e.leftHandKg.toStringAsFixed(1)} kg L (${e.asymmetryPercent.toStringAsFixed(0)}% asym)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHandInputCard({
    required String title,
    required Color color,
    required double valueKg,
    required TextEditingController controller,
    required String unitLabel,
    required ValueChanged<String> onChanged,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.textSecondary,
                iconSize: 22,
                onPressed: onDecrement,
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.textSecondary,
                iconSize: 22,
                onPressed: onIncrement,
              ),
            ],
          ),
          Text(
            unitLabel.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
