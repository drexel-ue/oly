import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:provider/provider.dart';

class HelenWodCard extends StatefulWidget {
  const HelenWodCard({
    required this.exercise,
    required this.onCompleted,
    super.key,
    this.isPreviewMode = false,
    this.onSkip,
    this.onOpenSwapModal,
    this.isSwapped = false,
  });

  final MobilityExerciseModel exercise;
  final VoidCallback onCompleted;
  final bool isPreviewMode;
  final VoidCallback? onSkip;
  final VoidCallback? onOpenSwapModal;
  final bool isSwapped;

  @override
  State<HelenWodCard> createState() => _HelenWodCardState();
}

class _HelenWodCardState extends State<HelenWodCard> {
  // Timer state (For Time stopwatch counting UP)
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _hasStarted = false;

  // Active round: 0 = Round 1, 1 = Round 2, 2 = Round 3, 3 = Finished
  int _activeRoundIndex = 0;

  // Cumulative split times (elapsed seconds at completion of each round)
  int? _round1SplitSeconds;
  int? _round2SplitSeconds;
  int? _round3SplitSeconds;

  // Station tracking per round
  // Round 1
  bool _runR1Done = false;
  int _kbR1Done = 0;
  int _pullupsR1Done = 0;

  // Round 2
  bool _runR2Done = false;
  int _kbR2Done = 0;
  int _pullupsR2Done = 0;

  // Round 3
  bool _runR3Done = false;
  int _kbR3Done = 0;
  int _pullupsR3Done = 0;

  // Configuration
  double _kettlebellWeightKg = 24.0; // 53 lb standard Rx Men (16 kg / 35 lb Rx Women)
  bool _isRxWomen = false;
  String _swingType = 'american'; // 'american', 'russian'
  String _pullupVariation = 'kipping';
  String? _pullupBand;
  final int _runDistanceMeters = 400;

  // Manual entry mode
  bool _isManualEntry = false;
  late TextEditingController _manualMinutesController;
  late TextEditingController _manualSecondsController;
  late TextEditingController _notesController;

  late bool _isLiveMode;

  @override
  void initState() {
    super.initState();
    _isLiveMode = !widget.isPreviewMode;
    _manualMinutesController = TextEditingController(text: '9');
    _manualSecondsController = TextEditingController(text: '45');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _manualMinutesController.dispose();
    _manualSecondsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _scalingTier {
    final double rxMinWeight = _isRxWomen ? 15.5 : 23.5;
    final bool isScaled = _swingType == 'russian' ||
        _pullupVariation == 'band_assisted' ||
        _pullupVariation == 'ring_rows' ||
        _pullupVariation == 'jumping' ||
        _pullupBand != null ||
        _kettlebellWeightKg < rxMinWeight ||
        _runDistanceMeters < 400;

    if (isScaled) {
      return 'Scaled';
    }

    final double rxMaxWeight = _isRxWomen ? 17.0 : 25.0;
    final bool isWeighted = _kettlebellWeightKg > rxMaxWeight || _pullupVariation == 'weighted';
    if (isWeighted) {
      return 'Weighted';
    }

    return 'Rx';
  }

  String _formatSeconds(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _playBeepIfEnabled() {
    try {
      final SettingsProvider settings =
          Provider.of<SettingsProvider>(context, listen: false);
      if (settings.soundAlertsEnabled) {
        NotificationService().playTimerBeepSound();
      }
    } catch (_) {
      NotificationService().playTimerBeepSound();
    }
  }

  void _startStopwatch() {
    if (_isTimerRunning) {
      return;
    }
    setState(() {
      _isTimerRunning = true;
      _hasStarted = true;
    });

    _playBeepIfEnabled();

    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _pauseStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() => _isTimerRunning = false);
    HapticFeedback.lightImpact();
  }

  void _resetWorkout() {
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _hasStarted = false;
      _elapsedSeconds = 0;
      _activeRoundIndex = 0;
      _round1SplitSeconds = null;
      _round2SplitSeconds = null;
      _round3SplitSeconds = null;
      _runR1Done = false;
      _kbR1Done = 0;
      _pullupsR1Done = 0;
      _runR2Done = false;
      _kbR2Done = 0;
      _pullupsR2Done = 0;
      _runR3Done = false;
      _kbR3Done = 0;
      _pullupsR3Done = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _completeRound1() {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _runR1Done = true;
      _kbR1Done = 21;
      _pullupsR1Done = 12;
      _round1SplitSeconds = _elapsedSeconds;
      _activeRoundIndex = 1; // Advance to Round 2
    });
  }

  void _completeRound2() {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _runR2Done = true;
      _kbR2Done = 21;
      _pullupsR2Done = 12;
      _round2SplitSeconds = _elapsedSeconds;
      _activeRoundIndex = 2; // Advance to Round 3
    });
  }

  void _completeRound3AndFinish() {
    HapticFeedback.heavyImpact();
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _runR3Done = true;
      _kbR3Done = 21;
      _pullupsR3Done = 12;
      _round3SplitSeconds = _elapsedSeconds;
      _activeRoundIndex = 3; // Finished
    });

    _playBeepIfEnabled();

    _promptSaveScoreDialog();
  }

  Future<void> _promptSaveScoreDialog() async {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context, listen: false);
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context, listen: false);

    final int totalSeconds = _elapsedSeconds > 0 ? _elapsedSeconds : 600; // 10:00 fallback

    final HelenWorkoutLog draft = HelenWorkoutLog(
      totalTimeSeconds: totalSeconds,
      round1TimeSeconds: _round1SplitSeconds,
      round2TimeSeconds: _round2SplitSeconds != null && _round1SplitSeconds != null
          ? _round2SplitSeconds! - _round1SplitSeconds!
          : null,
      round3TimeSeconds: _round3SplitSeconds != null && _round2SplitSeconds != null
          ? _round3SplitSeconds! - _round2SplitSeconds!
          : null,
      kettlebellWeightKg: _kettlebellWeightKg,
      isRxWomen: _isRxWomen,
      swingType: _swingType,
      pullupVariation: _pullupVariation,
      pullupBandAssistance: _pullupBand,
      runDistanceMeters: _runDistanceMeters,
      scalingTier: _scalingTier,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final HelenWorkoutLog? currentPr = recovery.getHelenPersonalRecord(tier: draft.scalingTier);
    final bool isNewPr = currentPr == null || draft.totalTimeSeconds < currentPr.totalTimeSeconds;

    // MET calculation: 11.5 for 3 rounds of running, swings and pull-ups
    final double met = draft.scalingTier == 'Weighted'
        ? 12.5
        : draft.scalingTier == 'Scaled'
            ? 10.0
            : 11.5;
    final BodyCompositionEntry? latestComp = bodyComp.latestEntry;
    final double weightKg = latestComp != null ? latestComp.weightLb * 0.45359237 : 80.0;
    final double durationHours = draft.totalTimeSeconds / 3600.0;
    final int caloriesBurned = (met * weightKg * durationHours).round();

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.emoji_events, color: AppTheme.primaryAmber, size: 28),
              const SizedBox(width: 8),
              Text(
                'Complete Helen WOD',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      'TOTAL FINISH TIME',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.formattedTotalTime,
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            draft.scalingTier.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                        ),
                        if (isNewPr) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW PR! 🏆',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (draft.round1TimeSeconds != null) ...<Widget>[
                Text(
                  'R1: ${draft.formattedRound1Time} • R2: ${draft.formattedRound2Time ?? "--:--"} • R3: ${draft.formattedRound3Time ?? "--:--"}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'KB: ${draft.swingDisplayName} • Pull-ups: ${draft.pullupDisplayName}',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Est. Energy Burned: ~$caloriesBurned kcal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successGreen,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Session Notes (optional)',
                  labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                  hintText: 'e.g. Unbroken swings, split pull-ups 6/6 in round 3',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
                if (!_isLiveMode) {
                  widget.onCompleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceElevated,
                      content: Text(
                        'Preview ended. No session was logged.',
                        style: GoogleFonts.outfit(color: AppTheme.secondaryCyan),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                !_isLiveMode ? "Exit (Don't Save)" : 'Cancel',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _isLiveMode = true;
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check, color: Colors.black),
              label: Text(
                !_isLiveMode ? 'Save as Live Score' : 'Save & Log WOD',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAmber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSave == true && mounted) {
      final HelenWorkoutLog finalized = await recovery.logHelenWorkout(draft);
      final DailyActivityEntry activityEntry = DailyActivityEntry.create(
        activityType: 'workout_wod',
        name: 'CrossFit WOD: Helen (3 Rounds For Time)',
        durationMinutes: finalized.totalTimeSeconds / 60.0,
        metValue: met,
        caloriesBurned: caloriesBurned,
        source: 'wod_auto_sync',
        notes: finalized.scoreDisplay,
      );
      await nutrition.addActivity(activityEntry, latestBodyComp: latestComp);

      widget.onCompleted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceElevated,
            content: Text(
              'Helen WOD logged! ${finalized.scoreDisplay} saved.',
              style: GoogleFonts.outfit(color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveManualScore() async {
    final int minutes = int.tryParse(_manualMinutesController.text) ?? 0;
    final int seconds = (int.tryParse(_manualSecondsController.text) ?? 0).clamp(0, 59);
    final int totalSeconds = (minutes * 60) + seconds;

    setState(() {
      _elapsedSeconds = totalSeconds;
    });

    await _promptSaveScoreDialog();
  }

  @override
  Widget build(BuildContext context) {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final HelenWorkoutLog? bestPr = recovery.getHelenPersonalRecord(tier: _scalingTier);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLiveMode
              ? AppTheme.primaryAmber.withValues(alpha: 0.5)
              : AppTheme.secondaryCyan.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          _buildHeader(bestPr),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // Body: Live vs Manual
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isManualEntry ? _buildManualEntryView() : _buildLiveWorkoutView(),
          ),

          // Bottom Bar (History & PR glance)
          _buildHistoryGlance(recovery),
        ],
      ),
    );
  }

  Widget _buildHeader(HelenWorkoutLog? bestPr) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppTheme.primaryAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'CrossFit: Helen',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '3 ROUNDS',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '400m Run, 21 KB Swings, 12 Pull-ups',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isManualEntry ? Icons.timer_outlined : Icons.edit_note_rounded,
                  color: AppTheme.primaryAmber,
                ),
                tooltip: _isManualEntry ? 'Switch to Live Timer' : 'Manual Entry',
                onPressed: () {
                  setState(() => _isManualEntry = !_isManualEntry);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons: Setup Explainer & Scaling Tier Badge
          Row(
            children: <Widget>[
              InkWell(
                onTap: () {
                  WodSetupExplainerSheet.show(
                    context,
                    WodCatalog.helen,
                    onStartWod: () {
                      if (!_isTimerRunning) {
                        _startStopwatch();
                      }
                    },
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        size: 14,
                        color: AppTheme.secondaryCyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Setup & Strategy Guide',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'TIER: $_scalingTier',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveWorkoutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Main Stopwatch Display
        Center(
          child: Column(
            children: <Widget>[
              Text(
                'ELAPSED TIME',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatSeconds(_elapsedSeconds),
                style: GoogleFonts.outfit(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: _isTimerRunning ? AppTheme.primaryAmber : AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Stopwatch Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _isTimerRunning ? _pauseStopwatch : _startStopwatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTimerRunning ? Colors.amber.shade800 : AppTheme.primaryAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
              label: Text(
                _isTimerRunning ? 'PAUSE' : (_hasStarted ? 'RESUME' : 'START CLOCK'),
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            if (_hasStarted) ...<Widget>[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetWorkout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.surfaceElevated),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'RESET',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 20),

        // Load & Variation Configuration Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Kettlebell:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<double>(
                    value: _kettlebellWeightKg,
                    dropdownColor: AppTheme.surfaceElevated,
                    style: GoogleFonts.outfit(
                      color: AppTheme.primaryAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const <DropdownMenuItem<double>>[
                      DropdownMenuItem<double>(value: 24.0, child: Text('53 lb / 24 kg (Rx Men)')),
                      DropdownMenuItem<double>(value: 16.0, child: Text('35 lb / 16 kg (Rx Women)')),
                      DropdownMenuItem<double>(value: 12.0, child: Text('26 lb / 12 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 32.0, child: Text('70 lb / 32 kg (Heavy)')),
                    ],
                    onChanged: (double? val) {
                      if (val != null) {
                        setState(() {
                          _kettlebellWeightKg = val;
                          _isRxWomen = (val == 16.0);
                        });
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 12, color: AppTheme.surfaceCard),
              Row(
                children: <Widget>[
                  Text(
                    'Swing Type:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _swingType,
                    dropdownColor: AppTheme.surfaceElevated,
                    style: GoogleFonts.outfit(
                      color: AppTheme.primaryAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'american', child: Text('American Overhead (Rx)')),
                      DropdownMenuItem<String>(value: 'russian', child: Text('Russian Eye-level (Scaled)')),
                    ],
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() => _swingType = val);
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 12, color: AppTheme.surfaceCard),
              Row(
                children: <Widget>[
                  Text(
                    'Pull-up Style:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _pullupVariation,
                    dropdownColor: AppTheme.surfaceElevated,
                    style: GoogleFonts.outfit(
                      color: AppTheme.secondaryCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'kipping', child: Text('Kipping (Rx)')),
                      DropdownMenuItem<String>(value: 'butterfly', child: Text('Butterfly (Rx)')),
                      DropdownMenuItem<String>(value: 'standard', child: Text('Strict (Rx)')),
                      DropdownMenuItem<String>(value: 'band_assisted', child: Text('Banded (Scaled)')),
                      DropdownMenuItem<String>(value: 'ring_rows', child: Text('Ring Rows (Scaled)')),
                      DropdownMenuItem<String>(value: 'jumping', child: Text('Jumping (Scaled)')),
                    ],
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() => _pullupVariation = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Round 1 Card
        _buildRoundCard(
          roundNum: 1,
          runDone: _runR1Done,
          kbDone: _kbR1Done,
          pullupsDone: _pullupsR1Done,
          splitSeconds: _round1SplitSeconds,
          isActive: _activeRoundIndex == 0,
          isCompleted: _activeRoundIndex > 0,
          onRunToggle: () => setState(() => _runR1Done = !_runR1Done),
          onKbAdd: (int n) => setState(() => _kbR1Done = (_kbR1Done + n).clamp(0, 21)),
          onPullupAdd: (int n) => setState(() => _pullupsR1Done = (_pullupsR1Done + n).clamp(0, 12)),
          onCompleteRound: _completeRound1,
          buttonText: 'COMPLETE ROUND 1 (${_formatSeconds(_elapsedSeconds)}) -> GO TO ROUND 2',
        ),

        const SizedBox(height: 12),

        // Round 2 Card
        _buildRoundCard(
          roundNum: 2,
          runDone: _runR2Done,
          kbDone: _kbR2Done,
          pullupsDone: _pullupsR2Done,
          splitSeconds: _round2SplitSeconds != null && _round1SplitSeconds != null
              ? _round2SplitSeconds! - _round1SplitSeconds!
              : null,
          isActive: _activeRoundIndex == 1,
          isCompleted: _activeRoundIndex > 1,
          onRunToggle: () => setState(() => _runR2Done = !_runR2Done),
          onKbAdd: (int n) => setState(() => _kbR2Done = (_kbR2Done + n).clamp(0, 21)),
          onPullupAdd: (int n) => setState(() => _pullupsR2Done = (_pullupsR2Done + n).clamp(0, 12)),
          onCompleteRound: _completeRound2,
          buttonText: 'COMPLETE ROUND 2 (${_formatSeconds(_elapsedSeconds)}) -> GO TO ROUND 3',
        ),

        const SizedBox(height: 12),

        // Round 3 Card
        _buildRoundCard(
          roundNum: 3,
          runDone: _runR3Done,
          kbDone: _kbR3Done,
          pullupsDone: _pullupsR3Done,
          splitSeconds: _round3SplitSeconds != null && _round2SplitSeconds != null
              ? _round3SplitSeconds! - _round2SplitSeconds!
              : null,
          isActive: _activeRoundIndex == 2,
          isCompleted: _activeRoundIndex > 2,
          onRunToggle: () => setState(() => _runR3Done = !_runR3Done),
          onKbAdd: (int n) => setState(() => _kbR3Done = (_kbR3Done + n).clamp(0, 21)),
          onPullupAdd: (int n) => setState(() => _pullupsR3Done = (_pullupsR3Done + n).clamp(0, 12)),
          onCompleteRound: _completeRound3AndFinish,
          buttonText: 'FINISH HELEN! 🏁 (${_formatSeconds(_elapsedSeconds)})',
          isFinalRound: true,
        ),
      ],
    );
  }

  Widget _buildRoundCard({
    required int roundNum,
    required bool runDone,
    required int kbDone,
    required int pullupsDone,
    required int? splitSeconds,
    required bool isActive,
    required bool isCompleted,
    required VoidCallback onRunToggle,
    required void Function(int) onKbAdd,
    required void Function(int) onPullupAdd,
    required VoidCallback onCompleteRound,
    required String buttonText,
    bool isFinalRound = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.surfaceElevated : AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryAmber
              : isCompleted
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : AppTheme.surfaceElevated,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.greenAccent
                      : isActive
                          ? AppTheme.primaryAmber
                          : AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : Text(
                          '$roundNum',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.black : AppTheme.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Round $roundNum of 3',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '400m Run + 21 KB Swings + 12 Pull-ups',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (splitSeconds != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SPLIT: ${_formatSeconds(splitSeconds)}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isActive) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.surfaceCard),
            const SizedBox(height: 12),

            // Station 1: 400m Run Toggle
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onRunToggle();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: runDone
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: runDone
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : AppTheme.surfaceElevated,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      runDone ? Icons.check_circle_rounded : Icons.directions_run_rounded,
                      color: runDone ? Colors.greenAccent : AppTheme.secondaryCyan,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '400m Run',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: runDone ? Colors.greenAccent : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            runDone ? 'Completed! Head straight to kettlebell' : 'Tap to mark 400m complete',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: runDone,
                      activeTrackColor: Colors.greenAccent,
                      onChanged: (_) => onRunToggle(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Station 2: 21 KB Swings Sub-counter
            _buildMovementCounter(
              name: '21 Kettlebell Swings',
              done: kbDone,
              target: 21,
              color: AppTheme.primaryAmber,
              onAdd: onKbAdd,
              chips: <Widget>[
                _buildRepChip('+7', () => onKbAdd(7)),
                _buildRepChip('+11', () => onKbAdd(11)),
                _buildRepChip('-1', () => onKbAdd(-1)),
                _buildRepChip('Unbroken 21', () => onKbAdd(21), isHighlight: true),
              ],
            ),

            const SizedBox(height: 12),

            // Station 3: 12 Pull-ups Sub-counter
            _buildMovementCounter(
              name: '12 Pull-ups',
              done: pullupsDone,
              target: 12,
              color: AppTheme.secondaryCyan,
              onAdd: onPullupAdd,
              chips: <Widget>[
                _buildRepChip('+4', () => onPullupAdd(4)),
                _buildRepChip('+6', () => onPullupAdd(6)),
                _buildRepChip('-1', () => onPullupAdd(-1)),
                _buildRepChip('Unbroken 12', () => onPullupAdd(12), isHighlight: true),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCompleteRound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFinalRound ? Colors.greenAccent.shade700 : AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(isFinalRound ? Icons.flag_rounded : Icons.check_circle_outline, size: 18),
                label: Text(
                  buttonText,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMovementCounter({
    required String name,
    required int done,
    required int target,
    required Color color,
    required void Function(int) onAdd,
    required List<Widget> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '$name: $done / $target',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            const Spacer(),
            Text(
              '${((done / target) * 100).toInt()}%',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (done / target).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppTheme.surfaceCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildRepChip(String label, VoidCallback onTap, {bool isHighlight = false}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppTheme.primaryAmber.withValues(alpha: 0.2)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? AppTheme.primaryAmber : AppTheme.surfaceElevated,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppTheme.primaryAmber : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'MANUAL HELEN LOG',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryCyan,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _manualMinutesController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _manualSecondsController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Seconds (0–59)',
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<double>(
                initialValue: _kettlebellWeightKg,
                decoration: InputDecoration(
                  labelText: 'KB Weight',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                dropdownColor: AppTheme.surfaceElevated,
                items: const <DropdownMenuItem<double>>[
                  DropdownMenuItem<double>(value: 24.0, child: Text('53 lb (Rx Men)')),
                  DropdownMenuItem<double>(value: 16.0, child: Text('35 lb (Rx Women)')),
                  DropdownMenuItem<double>(value: 12.0, child: Text('26 lb (Scaled)')),
                  DropdownMenuItem<double>(value: 32.0, child: Text('70 lb (Heavy)')),
                ],
                onChanged: (double? val) {
                  if (val != null) {
                    setState(() {
                      _kettlebellWeightKg = val;
                      _isRxWomen = (val == 16.0);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _swingType,
                decoration: InputDecoration(
                  labelText: 'Swing Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                dropdownColor: AppTheme.surfaceElevated,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'american', child: Text('American (Rx)')),
                  DropdownMenuItem<String>(value: 'russian', child: Text('Russian (Scaled)')),
                ],
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() => _swingType = val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _pullupVariation,
          decoration: InputDecoration(
            labelText: 'Pull-up Style',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          dropdownColor: AppTheme.surfaceElevated,
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(value: 'kipping', child: Text('Kipping (Rx)')),
            DropdownMenuItem<String>(value: 'butterfly', child: Text('Butterfly (Rx)')),
            DropdownMenuItem<String>(value: 'standard', child: Text('Strict (Rx)')),
            DropdownMenuItem<String>(value: 'band_assisted', child: Text('Banded (Scaled)')),
            DropdownMenuItem<String>(value: 'ring_rows', child: Text('Ring Rows (Scaled)')),
          ],
          onChanged: (String? val) {
            if (val != null) {
              setState(() => _pullupVariation = val);
            }
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g. Unbroken swings, smooth run pace',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveManualScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.save_rounded),
            label: Text(
              'LOG MANUAL HELEN SCORE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryGlance(RecoveryProvider recovery) {
    final List<HelenWorkoutLog> history = recovery.getHelenWorkoutHistory();
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final HelenWorkoutLog latest = history.first;
    final HelenWorkoutLog? pr = recovery.getHelenPersonalRecord();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.history_rounded, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Latest: ${latest.formattedTotalTime} (${DateFormat('MM/dd').format(latest.date)})',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          if (pr != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PR: ${pr.formattedTotalTime}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
