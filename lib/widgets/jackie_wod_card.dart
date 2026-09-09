import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/jackie_workout_log.dart';
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

class JackieWodCard extends StatefulWidget {
  const JackieWodCard({
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
  State<JackieWodCard> createState() => _JackieWodCardState();
}

class _JackieWodCardState extends State<JackieWodCard> {
  // Timer state (For Time stopwatch counting UP)
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _hasStarted = false;

  // Station flow: 0 = Row (1000m), 1 = Thrusters (50 reps), 2 = Pull-ups (30 reps), 3 = Finished
  int _activeStationIndex = 0;

  // Split times
  int? _rowSplitSeconds;
  int? _thrusterSplitSeconds;
  int? _pullupSplitSeconds;

  // Station 2: Thrusters state
  int _thrusterRepsDone = 0;
  double _barbellWeightKg = 20.4; // 45 lb standard Rx

  // Station 3: Pull-ups state
  int _pullupRepsDone = 0;
  String _pullupVariation = 'kipping'; // 'standard', 'kipping', 'butterfly', 'band_assisted', 'ring_rows', 'jumping', 'weighted'
  String? _pullupBand;

  // Manual entry toggle
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
    final bool isScaled = _pullupVariation == 'band_assisted' ||
        _pullupVariation == 'ring_rows' ||
        _pullupVariation == 'jumping' ||
        _pullupBand != null ||
        _barbellWeightKg < 20.0;
    if (isScaled) {
      return 'Scaled';
    }
    final bool isWeighted = _barbellWeightKg > 21.0 || _pullupVariation == 'weighted';
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
      _activeStationIndex = 0;
      _rowSplitSeconds = null;
      _thrusterSplitSeconds = null;
      _pullupSplitSeconds = null;
      _thrusterRepsDone = 0;
      _pullupRepsDone = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _completeRowStation() {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _rowSplitSeconds = _elapsedSeconds;
      _activeStationIndex = 1; // Advance to Thrusters
    });
  }

  void _completeThrusterStation() {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _thrusterRepsDone = 50;
      _thrusterSplitSeconds = _elapsedSeconds;
      _activeStationIndex = 2; // Advance to Pull-ups
    });
  }

  void _completePullupStationAndFinish() {
    HapticFeedback.heavyImpact();
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _pullupRepsDone = 30;
      _pullupSplitSeconds = _elapsedSeconds;
      _activeStationIndex = 3; // Finished
    });

    _playBeepIfEnabled();

    _promptSaveScoreDialog();
  }

  Future<void> _promptSaveScoreDialog() async {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context, listen: false);
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context, listen: false);

    final int totalSeconds = _elapsedSeconds > 0 ? _elapsedSeconds : 570; // 9:30 fallback
    final int? rowSec = _rowSplitSeconds;
    final int? thrusterDuration = _thrusterSplitSeconds != null && rowSec != null
        ? _thrusterSplitSeconds! - rowSec
        : null;
    final int? pullupDuration = _thrusterSplitSeconds != null
        ? totalSeconds - _thrusterSplitSeconds!
        : null;

    final JackieWorkoutLog draft = JackieWorkoutLog(
      totalTimeSeconds: totalSeconds,
      rowTimeSeconds: rowSec,
      thrusterTimeSeconds: thrusterDuration,
      pullupTimeSeconds: pullupDuration,
      barbellWeightKg: _barbellWeightKg,
      pullupVariation: _pullupVariation,
      pullupBandAssistance: _pullupBand,
      scalingTier: _scalingTier,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final JackieWorkoutLog? currentPr = recovery.getJackiePersonalRecord(tier: draft.scalingTier);
    final bool isNewPr = currentPr == null || draft.totalTimeSeconds < currentPr.totalTimeSeconds;

    // MET calculation: High intensity erg + barbell chipper
    final double met = draft.scalingTier == 'Weighted'
        ? 12.0
        : draft.scalingTier == 'Scaled'
            ? 9.5
            : 11.0;
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
                'Complete Jackie WOD',
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
                        fontSize: 32,
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
              if (draft.rowTimeSeconds != null) ...<Widget>[
                Text(
                  'Row: ${draft.formattedRowTime} • Thrusters: ${draft.formattedThrusterTime ?? "--:--"} • Pull-ups: ${draft.formattedPullupTime ?? "--:--"}',
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
                  hintText: 'e.g. Row split held 1:52, thrusters broken 20/15/15',
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
      final JackieWorkoutLog finalized = await recovery.logJackieWorkout(draft);
      final DailyActivityEntry activityEntry = DailyActivityEntry.create(
        activityType: 'workout_wod',
        name: 'CrossFit WOD: Jackie (For Time)',
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
              'Jackie WOD logged! ${finalized.scoreDisplay} saved.',
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
    final JackieWorkoutLog? bestPr = recovery.getJackiePersonalRecord(tier: _scalingTier);

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

  Widget _buildHeader(JackieWorkoutLog? bestPr) {
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
                  Icons.rowing_rounded,
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
                          'CrossFit: Jackie',
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
                            'FOR TIME',
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
                      '1,000m Row • 50 Thrusters (45 lb) • 30 Pull-ups',
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
                    WodCatalog.jackie,
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

        // Stations Stepper / Navigation
        _buildStationCard(
          index: 0,
          title: 'Station 1: 1,000m Row',
          subtitle: 'Concept2 Ergometer • Damper 4–6',
          splitTime: _rowSplitSeconds,
          isActive: _activeStationIndex == 0,
          isCompleted: _activeStationIndex > 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Hold a steady 500m split 5–8s slower than 2k PR to keep legs primed for thrusters.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeRowStation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'ROW COMPLETE (${_formatSeconds(_elapsedSeconds)}) -> GO TO THRUSTERS',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildStationCard(
          index: 1,
          title: 'Station 2: 50 Thrusters (45 lb)',
          subtitle: 'Barbell starts from floor • Hip crease below knee',
          splitTime: _thrusterSplitSeconds != null && _rowSplitSeconds != null
              ? _thrusterSplitSeconds! - _rowSplitSeconds!
              : null,
          isActive: _activeStationIndex == 1,
          isCompleted: _activeStationIndex > 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Barbell Weight Selector
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
                      DropdownMenuItem<double>(value: 20.4, child: Text('45 lb / 20.4 kg (Rx)')),
                      DropdownMenuItem<double>(value: 15.9, child: Text('35 lb / 15.9 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 13.6, child: Text('30 lb DBs / 13.6 kg (Scaled)')),
                      DropdownMenuItem<double>(value: 29.5, child: Text('65 lb / 29.5 kg (Heavy)')),
                      DropdownMenuItem<double>(value: 43.1, child: Text('95 lb / 43.1 kg (Elite)'))
                    ],
                    onChanged: (double? val) {
                      if (val != null) {
                        setState(() => _barbellWeightKg = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rep counter & progress bar
              Row(
                children: <Widget>[
                  Text(
                    'Reps: $_thrusterRepsDone / 50',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((_thrusterRepsDone / 50) * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_thrusterRepsDone / 50).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
                ),
              ),
              const SizedBox(height: 10),
              // Quick rep increments
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _buildRepChip('+5', () {
                    setState(() => _thrusterRepsDone = (_thrusterRepsDone + 5).clamp(0, 50));
                  }),
                  _buildRepChip('+10', () {
                    setState(() => _thrusterRepsDone = (_thrusterRepsDone + 10).clamp(0, 50));
                  }),
                  _buildRepChip('+15', () {
                    setState(() => _thrusterRepsDone = (_thrusterRepsDone + 15).clamp(0, 50));
                  }),
                  _buildRepChip('-1', () {
                    setState(() => _thrusterRepsDone = (_thrusterRepsDone - 1).clamp(0, 50));
                  }),
                  _buildRepChip('50 Unbroken', () {
                    setState(() => _thrusterRepsDone = 50);
                  }, isHighlight: true),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeThrusterStation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'THRUSTERS DONE (${_formatSeconds(_elapsedSeconds)}) -> GO TO PULL-UPS',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildStationCard(
          index: 2,
          title: 'Station 3: 30 Pull-ups',
          subtitle: 'Chin over bar • Dead-hang lockout',
          splitTime: _pullupSplitSeconds != null && _thrusterSplitSeconds != null
              ? _pullupSplitSeconds! - _thrusterSplitSeconds!
              : null,
          isActive: _activeStationIndex == 2,
          isCompleted: _activeStationIndex > 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Pull-up Variation Dropdown
              Row(
                children: <Widget>[
                  Text(
                    'Style:',
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
                      DropdownMenuItem<String>(value: 'kipping', child: Text('Kipping Pull-ups (Rx)')),
                      DropdownMenuItem<String>(value: 'butterfly', child: Text('Butterfly Pull-ups (Rx)')),
                      DropdownMenuItem<String>(value: 'standard', child: Text('Strict Pull-ups (Rx)')),
                      DropdownMenuItem<String>(value: 'band_assisted', child: Text('Banded Pull-ups (Scaled)')),
                      DropdownMenuItem<String>(value: 'ring_rows', child: Text('Ring Rows (Scaled)')),
                      DropdownMenuItem<String>(value: 'jumping', child: Text('Jumping Pull-ups (Scaled)')),
                      DropdownMenuItem<String>(value: 'chest_to_bar', child: Text('Chest-to-Bar (Hard)')),
                    ],
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() => _pullupVariation = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rep counter & progress bar
              Row(
                children: <Widget>[
                  Text(
                    'Reps: $_pullupRepsDone / 30',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((_pullupRepsDone / 30) * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_pullupRepsDone / 30).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryCyan),
                ),
              ),
              const SizedBox(height: 10),
              // Quick rep increments
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _buildRepChip('+5', () {
                    setState(() => _pullupRepsDone = (_pullupRepsDone + 5).clamp(0, 30));
                  }),
                  _buildRepChip('+10', () {
                    setState(() => _pullupRepsDone = (_pullupRepsDone + 10).clamp(0, 30));
                  }),
                  _buildRepChip('-1', () {
                    setState(() => _pullupRepsDone = (_pullupRepsDone - 1).clamp(0, 30));
                  }),
                  _buildRepChip('30 Unbroken', () {
                    setState(() => _pullupRepsDone = 30);
                  }, isHighlight: true),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completePullupStationAndFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 22),
                  label: Text(
                    'FINISH JACKIE! 🏁 (${_formatSeconds(_elapsedSeconds)})',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard({
    required int index,
    required String title,
    required String subtitle,
    required int? splitTime,
    required bool isActive,
    required bool isCompleted,
    required Widget child,
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
                width: 24,
                height: 24,
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
                          '${index + 1}',
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
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (splitTime != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SPLIT: ${_formatSeconds(splitTime)}',
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
            child,
          ],
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppTheme.primaryAmber.withValues(alpha: 0.2)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? AppTheme.primaryAmber : AppTheme.surfaceCard,
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
          'MANUAL LOG ENTRY',
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
        // Barbell & pullup selection
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
                  DropdownMenuItem<double>(value: 20.4, child: Text('45 lb (Rx)')),
                  DropdownMenuItem<double>(value: 15.9, child: Text('35 lb (Scaled)')),
                  DropdownMenuItem<double>(value: 29.5, child: Text('65 lb (Heavy)')),
                ],
                onChanged: (double? val) {
                  if (val != null) {
                    setState(() => _barbellWeightKg = val);
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
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g. Broken thrusters 20/15/15',
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
              'LOG MANUAL JACKIE SCORE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryGlance(RecoveryProvider recovery) {
    final List<JackieWorkoutLog> history = recovery.getJackieWorkoutHistory();
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final JackieWorkoutLog latest = history.first;
    final JackieWorkoutLog? pr = recovery.getJackiePersonalRecord();

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
