import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/grace_workout_log.dart';
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

class GraceWodCard extends StatefulWidget {
  const GraceWodCard({
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
  State<GraceWodCard> createState() => _GraceWodCardState();
}

class _GraceWodCardState extends State<GraceWodCard> {
  // Timer state (For Time stopwatch counting UP)
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _hasStarted = false;

  // Rep tracking (0 to 30)
  int _completedReps = 0;

  // Split milestones
  int? _splitAt10Seconds;
  int? _splitAt20Seconds;

  // Configuration
  double _barbellWeightKg = 61.2; // 135 lb standard Rx Men (43.1 kg / 95 lb Rx Women)
  bool _isRxWomen = false;
  String _repPacingScheme = 'quick_singles'; // 'quick_singles', 'touch_and_go', 'sets_of_5', 'unbroken'
  final String _cleanTechnique = 'power_clean'; // 'power_clean', 'squat_clean'
  final String _jerkTechnique = 'push_jerk'; // 'push_jerk', 'split_jerk', 'push_press'

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
    _manualMinutesController = TextEditingController(text: '3');
    _manualSecondsController = TextEditingController(text: '15');
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
    final double rxMinWeight = _isRxWomen ? 42.0 : 60.0;
    if (_barbellWeightKg < rxMinWeight) {
      return 'Scaled';
    }

    final double rxMaxWeight = _isRxWomen ? 45.0 : 63.5;
    if (_barbellWeightKg > rxMaxWeight) {
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
      _completedReps = 0;
      _splitAt10Seconds = null;
      _splitAt20Seconds = null;
    });
    HapticFeedback.mediumImpact();
  }

  void _addReps(int delta) {
    if (!_hasStarted && !_isTimerRunning && delta > 0) {
      _startStopwatch();
    }

    final int newTotal = (_completedReps + delta).clamp(0, 30);
    HapticFeedback.selectionClick();

    setState(() {
      _completedReps = newTotal;

      // Auto-record milestone splits
      if (_completedReps >= 10 && _splitAt10Seconds == null) {
        _splitAt10Seconds = _elapsedSeconds;
        HapticFeedback.heavyImpact();
      }
      if (_completedReps >= 20 && _splitAt20Seconds == null) {
        _splitAt20Seconds = _elapsedSeconds;
        HapticFeedback.heavyImpact();
      }
    });

    if (newTotal == 30) {
      _finishGrace();
    }
  }

  void _finishGrace() {
    HapticFeedback.heavyImpact();
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _completedReps = 30;
    });

    _playBeepIfEnabled();

    _promptSaveScoreDialog();
  }

  Future<void> _promptSaveScoreDialog() async {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context, listen: false);
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context, listen: false);

    final int totalSeconds = _elapsedSeconds > 0 ? _elapsedSeconds : 195; // 3:15 fallback

    final GraceWorkoutLog draft = GraceWorkoutLog(
      totalTimeSeconds: totalSeconds,
      splitAt10Seconds: _splitAt10Seconds,
      splitAt20Seconds: _splitAt20Seconds,
      barbellWeightKg: _barbellWeightKg,
      isRxWomen: _isRxWomen,
      repPacingScheme: _repPacingScheme,
      cleanTechnique: _cleanTechnique,
      jerkTechnique: _jerkTechnique,
      scalingTier: _scalingTier,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final GraceWorkoutLog? currentPr = recovery.getGracePersonalRecord(tier: draft.scalingTier);
    final bool isNewPr = currentPr == null || draft.totalTimeSeconds < currentPr.totalTimeSeconds;

    // MET calculation: 12.5 for maximal Olympic clean and jerk sprint
    final double met = draft.scalingTier == 'Weighted'
        ? 13.5
        : draft.scalingTier == 'Scaled'
            ? 11.0
            : 12.5;
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
                'Complete Grace WOD',
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
              if (draft.splitAt10Seconds != null) ...<Widget>[
                Text(
                  '10 Reps: ${draft.formattedSplitAt10} • 20 Reps: ${draft.formattedSplitAt20 ?? "--:--"} • 30 Reps: ${draft.formattedTotalTime}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Barbell: ${draft.loadDisplayName} • Pacing: ${draft.repPacingScheme.replaceAll('_', ' ').toUpperCase()}',
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
                  hintText: 'e.g. Quick singles every 4s, 5 touch-and-go finish',
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
      final GraceWorkoutLog finalized = await recovery.logGraceWorkout(draft);
      final DailyActivityEntry activityEntry = DailyActivityEntry.create(
        activityType: 'workout_wod',
        name: 'CrossFit WOD: Grace (30 Clean & Jerks For Time)',
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
              'Grace WOD logged! ${finalized.scoreDisplay} saved.',
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
    final GraceWorkoutLog? bestPr = recovery.getGracePersonalRecord(tier: _scalingTier);

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

  Widget _buildHeader(GraceWorkoutLog? bestPr) {
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
                          'CrossFit: Grace',
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
                            '30 REPS',
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
                      '30 Clean & Jerks For Time (135/95 lb)',
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
                    WodCatalog.grace,
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
    final double progress = (_completedReps / 30.0).clamp(0.0, 1.0);

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

        // Barbell & Pacing Configuration
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
                    'Barbell Load:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<double>(
                    value: _barbellWeightKg,
                    dropdownColor: AppTheme.surfaceElevated,
                    style: GoogleFonts.outfit(
                      color: AppTheme.primaryAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const <DropdownMenuItem<double>>[
                      DropdownMenuItem<double>(value: 61.2, child: Text('135 lb / 61 kg (Rx Men)')),
                      DropdownMenuItem<double>(value: 43.1, child: Text('95 lb / 43 kg (Rx Women)')),
                      DropdownMenuItem<double>(value: 52.2, child: Text('115 lb / 52 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 34.0, child: Text('75 lb / 34 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 70.3, child: Text('155 lb / 70 kg (Heavy)')),
                      DropdownMenuItem<double>(value: 83.9, child: Text('185 lb / 84 kg (Elite)')),
                    ],
                    onChanged: (double? val) {
                      if (val != null) {
                        setState(() {
                          _barbellWeightKg = val;
                          _isRxWomen = (val == 43.1);
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
                    'Pacing Style:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _repPacingScheme,
                    dropdownColor: AppTheme.surfaceElevated,
                    style: GoogleFonts.outfit(
                      color: AppTheme.secondaryCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'quick_singles', child: Text('Quick Singles (Recommended)')),
                      DropdownMenuItem<String>(value: 'touch_and_go', child: Text('Touch & Go Cycling')),
                      DropdownMenuItem<String>(value: 'sets_of_5', child: Text('Sets of 5 Reps')),
                      DropdownMenuItem<String>(value: 'unbroken', child: Text('Unbroken Sprint')),
                    ],
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() => _repPacingScheme = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Rep Counter Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _completedReps >= 30
                  ? Colors.greenAccent
                  : AppTheme.primaryAmber.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'CLEAN & JERKS COMPLETED',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Text(
                            '$_completedReps',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: _completedReps == 30 ? Colors.greenAccent : AppTheme.primaryAmber,
                            ),
                          ),
                          Text(
                            ' / 30',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Split Checkpoints display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (_splitAt10Seconds != null) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '10: ${_formatSeconds(_splitAt10Seconds!)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                      if (_splitAt20Seconds != null) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '20: ${_formatSeconds(_splitAt20Seconds!)}',
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
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _completedReps == 30 ? Colors.greenAccent : AppTheme.primaryAmber,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Big Main "+1 Single" button for rapid cycling
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completedReps < 30 ? () => _addReps(1) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  label: Text(
                    '+1 QUICK SINGLE (${_completedReps + 1} / 30)',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Stepper chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _buildRepChip('+3', () => _addReps(3)),
                  _buildRepChip('+5', () => _addReps(5)),
                  _buildRepChip('-1', () => _addReps(-1)),
                  _buildRepChip('Complete 30 Reps 🏁', _finishGrace, isHighlight: true),
                ],
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            fontSize: 12,
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
          'MANUAL GRACE LOG',
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
                initialValue: _barbellWeightKg,
                decoration: InputDecoration(
                  labelText: 'Barbell Load',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                dropdownColor: AppTheme.surfaceElevated,
                items: const <DropdownMenuItem<double>>[
                  DropdownMenuItem<double>(value: 61.2, child: Text('135 lb (Rx Men)')),
                  DropdownMenuItem<double>(value: 43.1, child: Text('95 lb (Rx Women)')),
                  DropdownMenuItem<double>(value: 52.2, child: Text('115 lb (Scaled)')),
                  DropdownMenuItem<double>(value: 34.0, child: Text('75 lb (Scaled)')),
                  DropdownMenuItem<double>(value: 70.3, child: Text('155 lb (Heavy)')),
                ],
                onChanged: (double? val) {
                  if (val != null) {
                    setState(() {
                      _barbellWeightKg = val;
                      _isRxWomen = (val == 43.1);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _repPacingScheme,
                decoration: InputDecoration(
                  labelText: 'Pacing Style',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                dropdownColor: AppTheme.surfaceElevated,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'quick_singles', child: Text('Quick Singles')),
                  DropdownMenuItem<String>(value: 'touch_and_go', child: Text('Touch & Go')),
                  DropdownMenuItem<String>(value: 'sets_of_5', child: Text('Sets of 5')),
                ],
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() => _repPacingScheme = val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g. Fast singles, good hip drive',
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
              'LOG MANUAL GRACE SCORE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryGlance(RecoveryProvider recovery) {
    final List<GraceWorkoutLog> history = recovery.getGraceWorkoutHistory();
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final GraceWorkoutLog latest = history.first;
    final GraceWorkoutLog? pr = recovery.getGracePersonalRecord();

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
