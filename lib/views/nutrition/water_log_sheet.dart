import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// Modal bottom sheet allowing athletes to log water flexibly in either mL or oz,
/// input custom arbitrary values (e.g. 739 mL from circadian hydration reminders),
/// or adjust daily cumulative totals.
class WaterLogSheet extends StatefulWidget {
  const new({super.key, this.initialMl});

  final double? initialMl;

  static Future<void> show(BuildContext context, {double? initialMl}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WaterLogSheet(initialMl: initialMl),
    );
  }

  @override
  State<WaterLogSheet> createState() => _WaterLogSheetState();
}

class _WaterLogSheetState extends State<WaterLogSheet> {
  late TextEditingController _controller;
  late bool _isMl;

  @override
  void initState() {
    super.initState();
    final NutritionProvider nutrition =
        Provider.of<NutritionProvider>(context, listen: false);
    final FastingProvider fasting =
        Provider.of<FastingProvider>(context, listen: false);

    // If initialMl was provided, default to mL; otherwise use user's persisted preference
    if (widget.initialMl != null) {
      _isMl = true;
      _controller = TextEditingController(
        text: widget.initialMl!.round().toString(),
      );
    } else {
      _isMl = nutrition.isWaterUnitMl;
      if (_isMl) {
        final int defaultMl = fasting.scheduledPortionMl > 0
            ? fasting.scheduledPortionMl
            : 500;
        _controller = TextEditingController(text: defaultMl.toString());
      } else {
        final double defaultOz = fasting.scheduledPortionOz > 0
            ? fasting.scheduledPortionOz
            : 16.0;
        _controller = TextEditingController(
          text: defaultOz.toStringAsFixed(defaultOz % 1 == 0 ? 0 : 1),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _currentInputValue =>
      double.tryParse(_controller.text.trim()) ?? 0.0;

  void _switchUnit(bool toMl) {
    if (_isMl == toMl) return;
    HapticFeedback.selectionClick();
    final double currentVal = _currentInputValue;
    setState(() {
      _isMl = toMl;
      if (currentVal > 0) {
        if (_isMl) {
          // oz -> mL
          final double ml = DailyNutritionLog.ozToMl(currentVal);
          _controller.text = ml.round().toString();
        } else {
          // mL -> oz
          final double oz = DailyNutritionLog.mlToOz(currentVal);
          _controller.text =
              oz.toStringAsFixed(oz >= 10 ? 1 : 1).replaceAll(RegExp(r'\.0$'), '');
        }
      }
    });
    // Persist preferred unit in provider
    Provider.of<NutritionProvider>(context, listen: false)
        .setWaterUnitPreference(_isMl ? 'ml' : 'oz');
  }

  void _applyPreset(double amount, bool isAmountMl) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isMl) {
        final double ml =
            isAmountMl ? amount : DailyNutritionLog.ozToMl(amount);
        _controller.text = ml.round().toString();
      } else {
        final double oz =
            isAmountMl ? DailyNutritionLog.mlToOz(amount) : amount;
        _controller.text =
            oz.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      }
    });
  }

  void _stepAdjust(double delta) {
    HapticFeedback.selectionClick();
    final double currentVal = _currentInputValue;
    final double nextVal = (currentVal + delta).clamp(0.0, _isMl ? 5000.0 : 200.0);
    setState(() {
      if (_isMl) {
        _controller.text = nextVal.round().toString();
      } else {
        _controller.text =
            nextVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      }
    });
  }

  Future<void> _submitAdd(NutritionProvider nutrition) async {
    final double val = _currentInputValue;
    if (val <= 0) return;
    unawaited(HapticFeedback.mediumImpact());

    final FastingProvider? fasting = () {
      try {
        return Provider.of<FastingProvider>(context, listen: false);
      } catch (_) {
        return null;
      }
    }();

    if (_isMl) {
      await nutrition.addWaterMl(val);
    } else {
      await nutrition.addWater(val);
    }
    if (fasting != null) {
      await fasting.syncWaterFromFuel(nutrition.currentDayLog.waterMl.round());
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D2538),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF00D2FF), width: 0.8),
          ),
          content: Row(
            children: <Widget>[
              const Icon(Icons.water_drop, color: Color(0xFF00E5FF), size: 18),
              const SizedBox(width: 8),
              Text(
                'Added +${_isMl ? '${val.round()} mL' : '${val.toStringAsFixed(1)} oz'} water',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitSetTotal(NutritionProvider nutrition) async {
    final double val = _currentInputValue;
    if (val < 0) return;
    unawaited(HapticFeedback.mediumImpact());

    final FastingProvider? fasting = () {
      try {
        return Provider.of<FastingProvider>(context, listen: false);
      } catch (_) {
        return null;
      }
    }();

    if (_isMl) {
      await nutrition.setWaterMl(val);
      if (fasting != null) {
        await fasting.setWaterFromFuel(val.round());
      }
    } else {
      await nutrition.setWaterOz(val);
      if (fasting != null) {
        await fasting.setWaterFromFuel(DailyNutritionLog.ozToMl(val).round());
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D2538),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF00D2FF), width: 0.8),
          ),
          content: Row(
            children: <Widget>[
              const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 18),
              const SizedBox(width: 8),
              Text(
                'Daily hydration total set to ${_isMl ? '${val.round()} mL' : '${val.toStringAsFixed(1)} oz'}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final NutritionProvider nutrition = context.watch<NutritionProvider>();
    final FastingProvider fasting = context.watch<FastingProvider>();
    final DailyNutritionLog log = nutrition.currentDayLog;

    final int scheduledPortionMl = fasting.scheduledPortionMl;
    final double scheduledPortionOz = fasting.scheduledPortionOz;

    final double inputVal = _currentInputValue;
    final String convertedHint = _isMl
        ? '≈ ${DailyNutritionLog.mlToOz(inputVal).toStringAsFixed(1)} fl oz'
        : '≈ ${DailyNutritionLog.ozToMl(inputVal).round()} mL';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Unit Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF00D2FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Log Hydration',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Precision fluid intake',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Unit Selector Pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildUnitSegment(
                      label: 'mL',
                      isSelected: _isMl,
                      onTap: () => _switchUnit(true),
                    ),
                    _buildUnitSegment(
                      label: 'oz',
                      isSelected: !_isMl,
                      onTap: () => _switchUnit(false),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current Daily Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131822),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Today's Progress",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log.waterOz.toStringAsFixed(0)} oz (${log.waterMl.round()} mL) / ${log.targetWaterOz.toStringAsFixed(0)} oz (${log.targetWaterMl.round()} mL)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(log.waterProgress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notification Scheduled Portion Hero Chip (e.g. 739 mL)
          if (scheduledPortionMl > 0) ...<Widget>[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _applyPreset(
                _isMl ? scheduledPortionMl.toDouble() : scheduledPortionOz,
                _isMl,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      const Color(0xFF00D2FF).withValues(alpha: 0.18),
                      const Color(0xFF0072FF).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF00E5FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Scheduled Notification Dose',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00E5FF),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$scheduledPortionMl mL (${scheduledPortionOz.toStringAsFixed(1)} oz) · Tap to set input',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.touch_app_outlined,
                      color: Color(0xFF00E5FF),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Main Number Input Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.white60,
                  iconSize: 26,
                  onPressed: () => _stepAdjust(_isMl ? -100.0 : -4.0),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixText: _isMl ? 'mL' : 'oz',
                          suffixStyle: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00D2FF),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (inputVal > 0)
                        Text(
                          convertedHint,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF00E5FF),
                  iconSize: 26,
                  onPressed: () => _stepAdjust(_isMl ? 100.0 : 4.0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Preset Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _isMl
                  ? <Widget>[
                      _buildPresetChip('250 mL', 250, true),
                      const SizedBox(width: 8),
                      _buildPresetChip('500 mL', 500, true),
                      const SizedBox(width: 8),
                      if (scheduledPortionMl > 0) ...<Widget>[
                        _buildPresetChip(
                          '$scheduledPortionMl mL ⚡',
                          scheduledPortionMl.toDouble(),
                          true,
                          isHighlighted: true,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildPresetChip('750 mL', 750, true),
                      const SizedBox(width: 8),
                      _buildPresetChip('1000 mL', 1000, true),
                    ]
                  : <Widget>[
                      _buildPresetChip('8 oz', 8, false),
                      const SizedBox(width: 8),
                      _buildPresetChip('16 oz', 16, false),
                      const SizedBox(width: 8),
                      if (scheduledPortionOz > 0) ...<Widget>[
                        _buildPresetChip(
                          '${scheduledPortionOz.toStringAsFixed(1)} oz ⚡',
                          scheduledPortionOz,
                          false,
                          isHighlighted: true,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildPresetChip('24 oz', 24, false),
                      const SizedBox(width: 8),
                      _buildPresetChip('32 oz', 32, false),
                    ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          ElevatedButton(
            onPressed: inputVal > 0 ? () => _submitAdd(nutrition) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D2FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.add, size: 20, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  inputVal > 0
                      ? 'Add +${_isMl ? '${inputVal.round()} mL' : '${inputVal.toStringAsFixed(1)} oz'} to Today'
                      : 'Enter Water Amount',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          OutlinedButton(
            onPressed: inputVal >= 0 ? () => _submitSetTotal(nutrition) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Set Total for Today (${_isMl ? '${inputVal.round()} mL' : '${inputVal.toStringAsFixed(1)} oz'})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildUnitSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    double amount,
    bool isMl, {
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: () => _applyPreset(amount, isMl),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFF00D2FF).withValues(alpha: 0.22)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF00D2FF).withValues(alpha: 0.6)
                : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? const Color(0xFF00E5FF) : Colors.white,
          ),
        ),
      ),
    );
  }
}
