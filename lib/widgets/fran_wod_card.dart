import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/fran_workout_log.dart';
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

class FranWodCard extends StatefulWidget {
  const FranWodCard({
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
  State<FranWodCard> createState() => _FranWodCardState();
}

class _FranWodCardState extends State<FranWodCard> {
  // Timer state (For Time stopwatch counting UP)
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _hasStarted = false;

  // Active round: 0 = Round of 21, 1 = Round of 15, 2 = Round of 9, 3 = Finished
  int _activeRoundIndex = 0;

  // Split times
  int? _round1SplitSeconds;
  int? _round2SplitSeconds;
  int? _round3SplitSeconds;

  // Rep tracking
  int _thrustersR1Done = 0;
  int _pullupsR1Done = 0;

  int _thrustersR2Done = 0;
  int _pullupsR2Done = 0;

  int _thrustersR3Done = 0;
  int _pullupsR3Done = 0;

  // Configuration
  double _barbellWeightKg = 43.1; // 95 lb standard Rx Men
  bool _isRxWomen = false;
  String _pullupVariation = 'kipping';
  String? _pullupBand;

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
    _manualMinutesController = TextEditingController(text: '4');
    _manualSecondsController = TextEditingController(text: '30');
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
    final double rxMin = _isRxWomen ? 29.0 : 42.0;
    final bool isScaled = _pullupVariation == 'band_assisted' ||
        _pullupVariation == 'ring_rows' ||
        _pullupVariation == 'jumping' ||
        _pullupBand != null ||
        _barbellWeightKg < rxMin;
    if (isScaled) {
      return 'Scaled';
    }
    final double rxMax = _isRxWomen ? 31.0 : 45.0;
    final bool isWeighted = _barbellWeightKg > rxMax || _pullupVariation == 'weighted';
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
      _thrustersR1Done = 0;
      _pullupsR1Done = 0;
      _thrustersR2Done = 0;
      _pullupsR2Done = 0;
      _thrustersR3Done = 0;
      _pullupsR3Done = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _completeRound1() {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _thrustersR1Done = 21;
      _pullupsR1Done = 21;
      _round1SplitSeconds = _elapsedSeconds;
      _activeRoundIndex = 1; // Advance to 15s
    });
  }

  void _completeRound2() {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _thrustersR2Done = 15;
      _pullupsR2Done = 15;
      _round2SplitSeconds = _elapsedSeconds;
      _activeRoundIndex = 2; // Advance to 9s
    });
  }

  void _completeRound3AndFinish() {
    HapticFeedback.heavyImpact();
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _thrustersR3Done = 9;
      _pullupsR3Done = 9;
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

    final int totalSeconds = _elapsedSeconds > 0 ? _elapsedSeconds : 270; // 4:30 fallback

    final FranWorkoutLog draft = FranWorkoutLog(
      totalTimeSeconds: totalSeconds,
      round1TimeSeconds: _round1SplitSeconds,
      round2TimeSeconds: _round2SplitSeconds,
      round3TimeSeconds: _round3SplitSeconds,
      barbellWeightKg: _barbellWeightKg,
      isRxWomen: _isRxWomen,
      pullupVariation: _pullupVariation,
      pullupBandAssistance: _pullupBand,
      scalingTier: _scalingTier,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final FranWorkoutLog? currentPr = recovery.getFranPersonalRecord(tier: draft.scalingTier);
    final bool isNewPr = currentPr == null || draft.totalTimeSeconds < currentPr.totalTimeSeconds;

    // MET calculation: 12.0 for all-out barbell + gymnastics sprint
    final double met = draft.scalingTier == 'Weighted'
        ? 13.0
        : draft.scalingTier == 'Scaled'
            ? 10.5
            : 12.0;
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
                'Complete Fran WOD',
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
                  'R21: ${draft.formattedRound1Time} • R15: ${draft.formattedRound2Time ?? "--:--"} • R9: ${draft.formattedRound3Time ?? "--:--"}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Barbell: ${_barbellWeightKg.toStringAsFixed(1)} kg • Pull-ups: ${draft.pullupDisplayName}',
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
                  hintText: 'e.g. Unbroken 21 thrusters, broke pullups 12/9',
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
      final FranWorkoutLog finalized = await recovery.logFranWorkout(draft);
      final DailyActivityEntry activityEntry = DailyActivityEntry.create(
        activityType: 'workout_wod',
        name: 'CrossFit WOD: Fran (21-15-9 For Time)',
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
              'Fran WOD logged! ${finalized.scoreDisplay} saved.',
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
    final FranWorkoutLog? bestPr = recovery.getFranPersonalRecord(tier: _scalingTier);

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

  Widget _buildHeader(FranWorkoutLog? bestPr) {
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
                  Icons.flash_on_rounded,
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
                          'CrossFit: Fran',
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
                            '21-15-9',
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
                      'Thrusters (95/65 lb) & Pull-ups For Time',
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
                    WodCatalog.fran,
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
                      DropdownMenuItem<double>(value: 43.1, child: Text('95 lb / 43 kg (Rx Men)')),
                      DropdownMenuItem<double>(value: 29.5, child: Text('65 lb / 29.5 kg (Rx Women)')),
                      DropdownMenuItem<double>(value: 34.0, child: Text('75 lb / 34 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 20.4, child: Text('45 lb / 20.4 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 52.2, child: Text('115 lb / 52 kg (Heavy)')),
                      DropdownMenuItem<double>(value: 61.2, child: Text('135 lb / 61 kg (Elite)'))
                    ],
                    onChanged: (double? val) {
                      if (val != null) {
                        setState(() {
                          _barbellWeightKg = val;
                          _isRxWomen = (val == 29.5);
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

        // Round of 21
        _buildRoundCard(
          roundNum: 1,
          repTarget: 21,
          thrustersDone: _thrustersR1Done,
          pullupsDone: _pullupsR1Done,
          splitSeconds: _round1SplitSeconds,
          isActive: _activeRoundIndex == 0,
          isCompleted: _activeRoundIndex > 0,
          onThrusterAdd: (int n) => setState(() => _thrustersR1Done = (_thrustersR1Done + n).clamp(0, 21)),
          onPullupAdd: (int n) => setState(() => _pullupsR1Done = (_pullupsR1Done + n).clamp(0, 21)),
          onCompleteRound: _completeRound1,
          buttonText: 'COMPLETE 21s (${_formatSeconds(_elapsedSeconds)}) -> GO TO 15s',
        ),

        const SizedBox(height: 12),

        // Round of 15
        _buildRoundCard(
          roundNum: 2,
          repTarget: 15,
          thrustersDone: _thrustersR2Done,
          pullupsDone: _pullupsR2Done,
          splitSeconds: _round2SplitSeconds != null && _round1SplitSeconds != null
              ? _round2SplitSeconds! - _round1SplitSeconds!
              : null,
          isActive: _activeRoundIndex == 1,
          isCompleted: _activeRoundIndex > 1,
          onThrusterAdd: (int n) => setState(() => _thrustersR2Done = (_thrustersR2Done + n).clamp(0, 15)),
          onPullupAdd: (int n) => setState(() => _pullupsR2Done = (_pullupsR2Done + n).clamp(0, 15)),
          onCompleteRound: _completeRound2,
          buttonText: 'COMPLETE 15s (${_formatSeconds(_elapsedSeconds)}) -> GO TO 9s',
        ),

        const SizedBox(height: 12),

        // Round of 9
        _buildRoundCard(
          roundNum: 3,
          repTarget: 9,
          thrustersDone: _thrustersR3Done,
          pullupsDone: _pullupsR3Done,
          splitSeconds: _round3SplitSeconds != null && _round2SplitSeconds != null
              ? _round3SplitSeconds! - _round2SplitSeconds!
              : null,
          isActive: _activeRoundIndex == 2,
          isCompleted: _activeRoundIndex > 2,
          onThrusterAdd: (int n) => setState(() => _thrustersR3Done = (_thrustersR3Done + n).clamp(0, 9)),
          onPullupAdd: (int n) => setState(() => _pullupsR3Done = (_pullupsR3Done + n).clamp(0, 9)),
          onCompleteRound: _completeRound3AndFinish,
          buttonText: 'FINISH FRAN! 🏁 (${_formatSeconds(_elapsedSeconds)})',
          isFinalRound: true,
        ),
      ],
    );
  }

  Widget _buildRoundCard({
    required int roundNum,
    required int repTarget,
    required int thrustersDone,
    required int pullupsDone,
    required int? splitSeconds,
    required bool isActive,
    required bool isCompleted,
    required void Function(int) onThrusterAdd,
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
                          '$repTarget',
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
                      'Round of $repTarget Reps',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$repTarget Thrusters + $repTarget Pull-ups',
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

            // Thruster Sub-counter
            _buildMovementCounter(
              name: 'Thrusters',
              done: thrustersDone,
              target: repTarget,
              color: AppTheme.primaryAmber,
              onAdd: onThrusterAdd,
            ),

            const SizedBox(height: 12),

            // Pull-up Sub-counter
            _buildMovementCounter(
              name: 'Pull-ups',
              done: pullupsDone,
              target: repTarget,
              color: AppTheme.secondaryCyan,
              onAdd: onPullupAdd,
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
          children: <Widget>[
            _buildRepChip('+5', () => onAdd(5)),
            _buildRepChip('+${(target / 2).ceil()}', () => onAdd((target / 2).ceil())),
            _buildRepChip('-1', () => onAdd(-1)),
            _buildRepChip('Unbroken $target', () => onAdd(target), isHighlight: true),
          ],
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
          'MANUAL FRAN LOG',
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
                  DropdownMenuItem<double>(value: 43.1, child: Text('95 lb (Rx Men)')),
                  DropdownMenuItem<double>(value: 29.5, child: Text('65 lb (Rx Women)')),
                  DropdownMenuItem<double>(value: 34.0, child: Text('75 lb (Scaled)')),
                  DropdownMenuItem<double>(value: 20.4, child: Text('45 lb (Scaled)')),
                ],
                onChanged: (double? val) {
                  if (val != null) {
                    setState(() {
                      _barbellWeightKg = val;
                      _isRxWomen = (val == 29.5);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
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
                ],
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() => _pullupVariation = val);
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
            hintText: 'e.g. Broken 21s, unbroken 15s and 9s',
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
              'LOG MANUAL FRAN SCORE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryGlance(RecoveryProvider recovery) {
    final List<FranWorkoutLog> history = recovery.getFranWorkoutHistory();
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final FranWorkoutLog latest = history.first;
    final FranWorkoutLog? pr = recovery.getFranPersonalRecord();

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
