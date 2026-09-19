import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/illness_model.dart';
import 'package:oly/providers/illness_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class IllnessCheckInSheet extends StatefulWidget {
  const new({
    super.key,
    this.existingRecord,
  });

  final IllnessRecord? existingRecord;

  static Future<void> show(
    BuildContext context, {
    IllnessRecord? existingRecord,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IllnessCheckInSheet(existingRecord: existingRecord),
    );
  }

  @override
  State<IllnessCheckInSheet> createState() => _IllnessCheckInSheetState();
}

class _IllnessCheckInSheetState extends State<IllnessCheckInSheet> {
  late IllnessSeverity _selectedSeverity;
  late Set<IllnessSymptom> _selectedSymptoms;
  late bool _hasFever;
  double? _temperatureCelsius;
  late bool _freezeTraining;
  late TextEditingController _notesController;
  late TextEditingController _tempController;

  @override
  void initState() {
    super.initState();
    final IllnessRecord? existing = widget.existingRecord;
    _selectedSeverity = existing?.severity ?? IllnessSeverity.mildAboveNeck;
    _selectedSymptoms = Set<IllnessSymptom>.from(
      existing?.symptoms ?? <IllnessSymptom>[
        IllnessSymptom.runnyNose,
        IllnessSymptom.nasalCongestion,
      ],
    );
    _hasFever = existing?.hasFever ?? false;
    _temperatureCelsius = existing?.temperatureCelsius;
    _freezeTraining = existing?.isTrainingFrozen ?? true;
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _tempController = TextEditingController(
      text: _temperatureCelsius != null
          ? _temperatureCelsius!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  void _onSeveritySelected(IllnessSeverity severity) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSeverity = severity;
      if (severity == IllnessSeverity.systemicFever) {
        _hasFever = true;
        _selectedSymptoms.add(IllnessSymptom.feverOrChills);
        _selectedSymptoms.add(IllnessSymptom.muscleAches);
      }
    });
  }

  void _toggleSymptom(IllnessSymptom symptom) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
        if (symptom == IllnessSymptom.feverOrChills) {
          _hasFever = true;
        }
      }
    });
  }

  Future<void> _handleSave() async {
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    final IllnessProvider provider = Provider.of<IllnessProvider>(
      context,
      listen: false,
    );

    double? parsedTemp;
    if (_hasFever && _tempController.text.trim().isNotEmpty) {
      parsedTemp = double.tryParse(_tempController.text.trim());
    }

    if (widget.existingRecord != null) {
      final IllnessRecord updated = widget.existingRecord!.copyWith(
        severity: _selectedSeverity,
        symptoms: _selectedSymptoms.toList(),
        hasFever: _hasFever,
        temperatureCelsius: parsedTemp,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isTrainingFrozen: _freezeTraining,
      );
      await provider.updateIllness(updated);
    } else {
      await provider.logIllness(
        severity: _selectedSeverity,
        symptoms: _selectedSymptoms.toList(),
        hasFever: _hasFever,
        temperatureCelsius: parsedTemp,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isTrainingFrozen: _freezeTraining,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingRecord != null
                ? 'Health check-in updated.'
                : 'Sickness logged. Sickness Shield active.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primaryAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleMarkRecovered() async {
    if (widget.existingRecord == null) return;
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    final IllnessProvider provider = Provider.of<IllnessProvider>(
      context,
      listen: false,
    );
    await provider.resolveIllness(widget.existingRecord!.id);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Illness marked resolved. Re-Entry Stage 1 (50% Load) initiated.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.secondaryCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    if (widget.existingRecord == null) return;
    await HapticFeedback.heavyImpact();
    if (!mounted) return;
    final IllnessProvider provider = Provider.of<IllnessProvider>(
      context,
      listen: false,
    );
    await provider.deleteIllness(widget.existingRecord!.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0F121C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.sick_rounded,
                    color: AppTheme.primaryAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'SICKNESS & HEALTH CHECK-IN',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Clinical Neck Rule & Medical Freeze Protocol',
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderColor),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Severity Classification
                  _buildSectionHeader('1. CLINICAL SEVERITY & THE NECK RULE'),
                  const SizedBox(height: 10),
                  ...IllnessSeverity.values.map(_buildSeverityOption),
                  const SizedBox(height: 18),

                  // 2. Fever & Temperature
                  _buildSectionHeader('2. FEVER & SYSTEMIC INFECTION'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
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
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.thermostat_rounded,
                                  color: _hasFever
                                      ? Colors.redAccent
                                      : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Fever Present? (≥ 37.8°C / 100°F)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Training with fever carries cardiac risks',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _hasFever,
                              activeTrackColor: Colors.redAccent,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _hasFever = val;
                                  if (val) {
                                    _selectedSymptoms
                                        .add(IllnessSymptom.feverOrChills);
                                  } else {
                                    _selectedSymptoms
                                        .remove(IllnessSymptom.feverOrChills);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_hasFever) ...<Widget>[
                          const Divider(height: 20, color: AppTheme.borderColor),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Peak Temperature (°C):',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: _tempController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.redAccent,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '38.5',
                                    hintStyle: GoogleFonts.outfit(
                                      color: Colors.white24,
                                    ),
                                    suffixText: '°C',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor:
                                        Colors.redAccent.withValues(alpha: 0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Symptoms Tagging
                  _buildSectionHeader('3. SYMPTOM MANIFESTATION'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: IllnessSymptom.values.map((symptom) {
                      final bool isSelected =
                          _selectedSymptoms.contains(symptom);
                      final bool isSystemic = symptom.isBelowNeckOrSystemic;

                      return FilterChip(
                        selected: isSelected,
                        label: Text(
                          symptom.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? (isSystemic
                                    ? Colors.redAccent
                                    : AppTheme.primaryAmber)
                                : AppTheme.textSecondary,
                          ),
                        ),
                        selectedColor: (isSystemic
                                ? Colors.redAccent
                                : AppTheme.primaryAmber)
                            .withValues(alpha: 0.18),
                        backgroundColor: AppTheme.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? (isSystemic
                                    ? Colors.redAccent
                                    : AppTheme.primaryAmber)
                                : AppTheme.borderColor,
                          ),
                        ),
                        onSelected: (_) => _toggleSymptom(symptom),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 4. Program Protection / Freeze
                  _buildSectionHeader('4. TRAINING CYCLE PROTECTION'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.pause_circle_filled_rounded,
                          color: AppTheme.secondaryCyan,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Freeze Training Cycle (Recommended)',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Preserves streak and holds cycle day in place without penalty',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _freezeTraining,
                          activeTrackColor: AppTheme.secondaryCyan,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _freezeTraining = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Clinical Advisory Box
                  _buildClinicalAdvisoryBox(),
                  const SizedBox(height: 18),

                  // 6. Notes Field
                  _buildSectionHeader('5. CLINICAL NOTES (OPTIONAL)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Medications, hydration status, physician guidance...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white24,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OlyPressable(
                          onPressed: _handleSave,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.existingRecord != null
                                  ? 'UPDATE HEALTH CHECK-IN'
                                  : 'ACTIVATE SICKNESS SHIELD',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Secondary Actions if editing
                  if (widget.existingRecord != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OlyPressable(
                            onPressed: _handleMarkRecovered,
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.secondaryCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      AppTheme.secondaryCyan.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: AppTheme.secondaryCyan,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MARK RESOLVED (START RE-ENTRY)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.secondaryCyan,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete check-in',
                          onPressed: _handleDelete,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSeverityOption(IllnessSeverity severity) {
    final bool isSelected = _selectedSeverity == severity;
    final bool isSevere = severity != IllnessSeverity.mildAboveNeck;
    final Color activeColor = isSevere ? Colors.redAccent : AppTheme.primaryAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: OlyPressable(
        onPressed: () => _onSeveritySelected(severity),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : AppTheme.borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? activeColor : AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            severity.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (severity == IllnessSeverity.mildAboveNeck
                                    ? AppTheme.primaryAmber
                                    : Colors.redAccent)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            severity == IllnessSeverity.mildAboveNeck
                                ? 'NECK RULE: DELOAD'
                                : 'FULL REST PRESCRIBED',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: severity == IllnessSeverity.mildAboveNeck
                                  ? AppTheme.primaryAmber
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      severity.clinicalGuidance,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalAdvisoryBox() {
    final bool isSevere =
        _hasFever || _selectedSeverity != IllnessSeverity.mildAboveNeck;
    final Color boxColor = isSevere ? Colors.redAccent : AppTheme.primaryAmber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: boxColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isSevere ? Icons.warning_amber_rounded : Icons.info_outline,
                color: boxColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSevere
                      ? 'SYSTEMIC IMMUNE ALERT'
                      : 'ABOVE-THE-NECK ADAPTIVE PLAN',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: boxColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSevere
                ? '• Heavy Olympic lifts & ballistic complexes strictly contraindicated.\n'
                    '• Intermittent fasting paused: metabolic recovery requires hydration and calories.\n'
                    '• Readiness penalty: -55 to -70 pts (Rest Mode Active).'
                : '• Neck Rule: Low-intensity aerobic work and mobility permitted.\n'
                    '• Barbell load scaled to 70% (-30% auto-deload in workout session).\n'
                    '• Wim Hof breathing permitted if no respiratory distress.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textPrimary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
