import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/kettlebell_mile_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class KettlebellMileCard extends StatefulWidget {
  const KettlebellMileCard({
    required this.exercise,
    required this.onCompleted,
    required this.onSkip,
    required this.onOpenSwapModal,
    super.key,
    this.isSwapped = false,
  });

  final MobilityExerciseModel exercise;
  final VoidCallback onCompleted;
  final VoidCallback onSkip;
  final VoidCallback onOpenSwapModal;
  final bool isSwapped;

  @override
  State<KettlebellMileCard> createState() => _KettlebellMileCardState();
}

class _KettlebellMileCardState extends State<KettlebellMileCard> {
  double _kettlebellWeightKg = 10.0;
  double _kettlebellPctBw = 10.0;
  double _speedMph = 3.5;
  double _inclinePct = 1.0;

  // Timer / Stopwatch state
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isManualTimeEntry = false;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  bool _initialized = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '18');
    _secondsController = TextEditingController(text: '45');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
      final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context, listen: false);

      final BodyCompositionEntry? latestBodyComp = bodyComp.latestEntry;
      final double athleteWeightKg = latestBodyComp != null
          ? latestBodyComp.weightLb * 0.45359237
          : 90.0;

      final KettlebellMileLog? latestLog = recovery.latestKettlebellMileLog;
      if (latestLog != null) {
        _kettlebellPctBw = recovery.getCurrentKettlebellTargetPercentage();
        _kettlebellWeightKg = recovery.calculateSuggestedKettlebellWeightKg(
          athleteWeightKg: athleteWeightKg,
        );
        _speedMph = latestLog.speedMph;
        _inclinePct = latestLog.inclinePct;
      } else {
        _kettlebellPctBw = 10.0;
        _kettlebellWeightKg = recovery.calculateSuggestedKettlebellWeightKg(
          athleteWeightKg: athleteWeightKg,
        );
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _stopwatchTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        setState(() {
          _elapsedSeconds++;
          _minutesController.text = (_elapsedSeconds ~/ 60).toString();
          _secondsController.text = (_elapsedSeconds % 60).toString().padLeft(2, '0');
        });
      });
    }
  }

  void _resetTimer() {
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _elapsedSeconds = 0;
      _minutesController.text = '0';
      _secondsController.text = '00';
    });
  }

  int get _currentTimeSeconds {
    if (_isManualTimeEntry) {
      final int m = int.tryParse(_minutesController.text.trim()) ?? 0;
      final int s = int.tryParse(_secondsController.text.trim()) ?? 0;
      return (m * 60) + s;
    }
    return _elapsedSeconds;
  }

  bool get _isUnder20Minutes => _currentTimeSeconds > 0 && _currentTimeSeconds < 1200;

  /// Formatted estimated mile time at current speed: 60 / speedMph
  String get _estimatedMileTimeAtCurrentSpeed {
    if (_speedMph <= 0) {
      return '--:--';
    }
    final double totalMinutes = 60.0 / _speedMph;
    final int mins = totalMinutes.toInt();
    final int secs = ((totalMinutes - mins) * 60).round();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _isSpeedUnder20MinPace => _speedMph >= 3.0;

  void _adjustSpeed(double delta) {
    setState(() {
      _speedMph = double.parse(((_speedMph + delta).clamp(1.0, 10.0)).toStringAsFixed(1));
    });
  }

  void _setSpeed(double speed) {
    setState(() {
      _speedMph = double.parse(speed.clamp(1.0, 10.0).toStringAsFixed(1));
    });
  }

  void _adjustIncline(double delta) {
    setState(() {
      _inclinePct = double.parse(((_inclinePct + delta).clamp(0.0, 25.0)).toStringAsFixed(1));
    });
  }

  void _setIncline(double incline) {
    setState(() {
      _inclinePct = double.parse(incline.clamp(0.0, 25.0).toStringAsFixed(1));
    });
  }

  void _adjustWeight(double deltaKg) {
    setState(() {
      _kettlebellWeightKg = (_kettlebellWeightKg + deltaKg).clamp(2.0, 100.0);
    });
  }

  void _selectPctMilestone(double pct, double athleteWeightKg) {
    setState(() {
      _kettlebellPctBw = pct;
      _kettlebellWeightKg = double.parse((athleteWeightKg * (pct / 100.0)).toStringAsFixed(1));
    });
  }

  Future<void> _showCustomValueDialog({
    required String title,
    required String initialValue,
    required String unit,
    required ValueChanged<double> onSubmitted,
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: unit,
                  suffixStyle: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentBlue),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? val = double.tryParse(controller.text.trim());
                if (val != null) {
                  onSubmitted(val);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Set $title', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAndComplete(RecoveryProvider recovery) async {
    final int finalDuration = _currentTimeSeconds > 0 ? _currentTimeSeconds : 1140; // Default 19m
    await recovery.logKettlebellMile(
      weightKg: _kettlebellWeightKg,
      bodyweightPercentage: _kettlebellPctBw,
      speedMph: _speedMph,
      inclinePct: _inclinePct,
      durationSeconds: finalDuration,
      completedUnder20Min: finalDuration < 1200,
      notes: '1.0 Mile Kettlebell Carry @ ${_kettlebellPctBw.toStringAsFixed(1)}% BW',
    );
    setState(() => _isSaved = true);
    widget.onCompleted();
  }

  void _showHistorySheet(
    BuildContext context,
    RecoveryProvider recovery,
    SettingsProvider settings,
  ) {
    final List<KettlebellMileLog> history = recovery.getKettlebellMileHistory();
    final String unit = settings.unitLabel.toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kettlebell Mile History',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Progressing 10% ➔ 30% Bodyweight',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryAmber),
                      ),
                      child: Text(
                        'Goal: 30% BW',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No Kettlebell Mile sessions logged yet.\nComplete your first mile to track speed, incline, and weight progression!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        final KettlebellMileLog item = history[idx];
                        final String dateStr = DateFormat('MMM d, yyyy • h:mm a').format(item.date);
                        final double dispWeight = settings.toDisplayWeight(item.weightKg);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.completedUnder20Min
                                  ? AppTheme.accentBlue.withValues(alpha: 0.5)
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        '⏱ ${item.formattedDuration}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: item.completedUnder20Min
                                              ? Colors.greenAccent
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${item.speedMph} mph • ${item.inclinePct}% inc',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentBlue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.bodyweightPercentage.toStringAsFixed(1)}% BW',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dispWeight.toStringAsFixed(1)} $unit',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context);

    final BodyCompositionEntry? latestBodyComp = bodyComp.latestEntry;
    final double athleteWeightKg = latestBodyComp != null
        ? latestBodyComp.weightLb * 0.45359237
        : 90.0;
    final double displayAthleteWeight = settings.toDisplayWeight(athleteWeightKg);
    final double displayKbWeight = settings.toDisplayWeight(_kettlebellWeightKg);
    final String unitLabel = settings.unitLabel.toUpperCase();

    final KettlebellMileLog? latestLog = recovery.latestKettlebellMileLog;
    final bool previousUnlocked = latestLog != null && latestLog.completedUnder20Min;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Category Badges & Action Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'AEROBIC FLUSH & CARRY',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '1.0 MILE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // History Button
                  InkWell(
                    onTap: () => _showHistorySheet(context, recovery, settings),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.show_chart, size: 14, color: AppTheme.accentBlue),
                          const SizedBox(width: 4),
                          Text(
                            'History',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Swap Action
                  InkWell(
                    onTap: widget.onOpenSwapModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isSwapped
                            ? AppTheme.accentBlue.withValues(alpha: 0.2)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.isSwapped ? AppTheme.accentBlue : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: widget.isSwapped ? AppTheme.accentBlue : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isSwapped ? 'SWAPPED' : 'Swap',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.isSwapped ? AppTheme.accentBlue : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Skip Action
                  InkWell(
                    onTap: widget.onSkip,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.skip_next, size: 14, color: Colors.orangeAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Skip',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
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
          const SizedBox(height: 12),

          // Exercise Title & Description
          Text(
            widget.exercise.name,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.exercise.description,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),

          // PROGRESSION BANNER: 10% to 30% BW & < 20 MIN GOAL
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppTheme.secondaryCyan.withValues(alpha: 0.15),
                  AppTheme.accentBlue.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.fitness_center, size: 16, color: AppTheme.secondaryCyan),
                        const SizedBox(width: 6),
                        Text(
                          'KETTLEBELL MILE PROGRESSION',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryCyan,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Goal: 30% BW',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Athlete Weight: ${displayAthleteWeight.toStringAsFixed(1)} $unitLabel • Start @ 10% BW (${(displayAthleteWeight * 0.10).toStringAsFixed(1)} $unitLabel). Complete in < 20:00 to unlock higher load!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (previousUnlocked) ...<Widget>[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.check_circle, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Previous Mile was < 20:00! Target progressed to ${_kettlebellPctBw.toStringAsFixed(1)}% BW.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // WEIGHT SELECTOR & STEPPERS
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
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
                      'KETTLEBELL LOAD',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_kettlebellPctBw.toStringAsFixed(1)}% OF BODYWEIGHT',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      '${displayKbWeight.toStringAsFixed(1)} $unitLabel',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildStepperBtn('-2.5', () => _adjustWeight(-2.5)),
                    const SizedBox(width: 6),
                    _buildStepperBtn('+2.5', () => _adjustWeight(2.5)),
                    const SizedBox(width: 6),
                    _buildStepperBtn('+5.0', () => _adjustWeight(5.0)),
                  ],
                ),
                const SizedBox(height: 10),
                // Percentage Quick Select Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <double>[10.0, 15.0, 20.0, 25.0, 30.0].map((double pct) {
                      final bool isSel = (_kettlebellPctBw - pct).abs() < 0.1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${pct.toInt()}% BW'),
                          selected: isSel,
                          onSelected: (_) => _selectPctMilestone(pct, athleteWeightKg),
                          selectedColor: AppTheme.accentBlue,
                          backgroundColor: AppTheme.surfaceCard,
                          labelStyle: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.black : AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // INTUITIVE TREADMILL CONTROLS: SPEED & INCLINE CONSOLES
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // SPEED CONSOLE
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSpeedUnder20MinPace
                          ? Colors.tealAccent.withValues(alpha: 0.4)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.speed, size: 16, color: Colors.tealAccent),
                              const SizedBox(width: 4),
                              Text(
                                'SPEED',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showCustomValueDialog(
                              title: 'Speed',
                              initialValue: _speedMph.toStringAsFixed(1),
                              unit: 'mph',
                              onSubmitted: _setSpeed,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: AppTheme.accentBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Big Tactile Speed Controls (- Display +)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildLargeTactileBtn(
                            icon: Icons.remove,
                            onTap: () => _adjustSpeed(-0.1),
                          ),
                          GestureDetector(
                            onTap: () => _showCustomValueDialog(
                              title: 'Speed',
                              initialValue: _speedMph.toStringAsFixed(1),
                              unit: 'mph',
                              onSubmitted: _setSpeed,
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  _speedMph.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'MPH',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildLargeTactileBtn(
                            icon: Icons.add,
                            onTap: () => _adjustSpeed(0.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Speed Presets
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <double>[2.5, 3.0, 3.5, 4.0, 4.5].map((double spd) {
                            final bool isSel = (_speedMph - spd).abs() < 0.05;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: InkWell(
                                onTap: () => _setSpeed(spd),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? Colors.tealAccent
                                        : AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSel ? Colors.tealAccent : AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    spd.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.black : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Calculated Mile Pace Helper
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isSpeedUnder20MinPace
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⏱ Pace: $_estimatedMileTimeAtCurrentSpeed / mi ${_isSpeedUnder20MinPace ? "(<20m)" : "(≥20m)"}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isSpeedUnder20MinPace ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // INCLINE CONSOLE
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.terrain, size: 16, color: AppTheme.primaryAmber),
                              const SizedBox(width: 4),
                              Text(
                                'INCLINE',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showCustomValueDialog(
                              title: 'Incline',
                              initialValue: _inclinePct.toStringAsFixed(1),
                              unit: '%',
                              onSubmitted: _setIncline,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: AppTheme.accentBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Big Tactile Incline Controls (- Display +)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildLargeTactileBtn(
                            icon: Icons.remove,
                            onTap: () => _adjustIncline(-0.5),
                          ),
                          GestureDetector(
                            onTap: () => _showCustomValueDialog(
                              title: 'Incline',
                              initialValue: _inclinePct.toStringAsFixed(1),
                              unit: '%',
                              onSubmitted: _setIncline,
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  _inclinePct.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '% GRADE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildLargeTactileBtn(
                            icon: Icons.add,
                            onTap: () => _adjustIncline(0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Incline Presets
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <double>[0.0, 1.0, 2.0, 3.0, 5.0].map((double inc) {
                            final bool isSel = (_inclinePct - inc).abs() < 0.05;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: InkWell(
                                onTap: () => _setIncline(inc),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppTheme.primaryAmber
                                        : AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSel ? AppTheme.primaryAmber : AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    '${inc.toInt()}%',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.black : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Incline Grade Category Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _inclinePct <= 0.5
                              ? '⛰ Flat Grade'
                              : _inclinePct <= 2.5
                                  ? '⛰ Road Grade'
                                  : _inclinePct <= 5.0
                                      ? '⛰ Moderate Hill'
                                      : '⛰ Steep Carry',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TIME TAKEN & STOPWATCH SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isUnder20Minutes
                    ? Colors.greenAccent.withValues(alpha: 0.5)
                    : AppTheme.primaryAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: _isUnder20Minutes ? Colors.greenAccent : AppTheme.primaryAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '1.0 MILE COMPLETION TIME',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isUnder20Minutes ? Colors.greenAccent : AppTheme.primaryAmber,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isManualTimeEntry = !_isManualTimeEntry),
                      child: Text(
                        _isManualTimeEntry ? 'Use Stopwatch' : 'Edit Time',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (!_isManualTimeEntry) ...<Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _isUnder20Minutes ? Colors.greenAccent : AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          ElevatedButton.icon(
                            onPressed: _toggleTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTimerRunning ? Colors.orangeAccent : AppTheme.accentBlue,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 18),
                            label: Text(
                              _isTimerRunning ? 'PAUSE' : 'START MILE',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                            tooltip: 'Reset Timer',
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...<Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Mins',
                            labelStyle: GoogleFonts.inter(fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            filled: true,
                            fillColor: AppTheme.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(':', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _secondsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Secs',
                            labelStyle: GoogleFonts.inter(fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            filled: true,
                            fillColor: AppTheme.surfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _isUnder20Minutes
                              ? '⚡ Sub-20 Min Milestone Achieved!'
                              : 'Target: < 20:00 to progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isUnder20Minutes ? Colors.greenAccent : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                if (_isUnder20Minutes)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.bolt, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'PROGRESSION UNLOCKED! Finished in under 20 mins. Next recovery session unlocks higher weight towards 30% BW.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // COMPLETE MILE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaved ? null : () => _saveAndComplete(recovery),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaved ? Colors.green : AppTheme.primaryAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_isSaved ? Icons.check_circle : Icons.check, color: Colors.black),
              label: Text(
                _isSaved ? 'MILE LOGGED' : 'LOG KETTLEBELL MILE & NEXT',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTactileBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildStepperBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: label.startsWith('+') ? AppTheme.primaryAmber : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
