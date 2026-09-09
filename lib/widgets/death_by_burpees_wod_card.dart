import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/death_by_burpees_log.dart';
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

class DeathByBurpeesWodCard extends StatefulWidget {
  const DeathByBurpeesWodCard({
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
  State<DeathByBurpeesWodCard> createState() => _DeathByBurpeesWodCardState();
}

class _DeathByBurpeesWodCardState extends State<DeathByBurpeesWodCard> {
  // Timer State (EMOM)
  Timer? _emomTimer;
  int _elapsedTotalSeconds = 0;
  int _secondsRemainingInMinute = 60;
  int _currentMinute = 1;
  int _completedMinutes = 0;
  int _currentMinuteReps = 0;
  bool _isTimerRunning = false;
  bool _hasStarted = false;

  // Configuration & Variation
  String _burpeeVariation = 'standard'; // 'standard' (Rx), 'no_pushup', 'box_elevated'

  // Manual Entry State
  bool _isManualEntry = false;
  late TextEditingController _manualMinutesController;
  late TextEditingController _manualPartialRepsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _manualMinutesController = TextEditingController(text: '12');
    _manualPartialRepsController = TextEditingController(text: '0');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _emomTimer?.cancel();
    _manualMinutesController.dispose();
    _manualPartialRepsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _scalingTier => _burpeeVariation == 'standard' ? 'Rx' : 'Scaled';

  int get _currentMinuteTarget => _currentMinute;

  bool get _isTargetMet => _currentMinuteReps >= _currentMinuteTarget;

  int get _currentCumulativeReps {
    final int fullReps = _completedMinutes > 0
        ? (_completedMinutes * (_completedMinutes + 1)) ~/ 2
        : 0;
    return fullReps + _currentMinuteReps;
  }

  String _formatDuration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getBenchmarkTier(int minutes) {
    if (minutes >= 19) {
      return 'Elite';
    }
    if (minutes >= 16) {
      return 'Advanced';
    }
    if (minutes >= 12) {
      return 'Intermediate';
    }
    if (minutes >= 8) {
      return 'Beginner';
    }
    return 'Novice';
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

  void _startTimer() {
    if (_isTimerRunning) {
      return;
    }
    setState(() {
      _isTimerRunning = true;
      _hasStarted = true;
    });

    _playBeepIfEnabled();

    _emomTimer?.cancel();
    _emomTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedTotalSeconds++;
        _secondsRemainingInMinute--;
      });

      // Countdown audio & haptic alerts in last 3 seconds
      if (_secondsRemainingInMinute <= 3 && _secondsRemainingInMinute > 0) {
        HapticFeedback.selectionClick();
      }

      // Minute expired
      if (_secondsRemainingInMinute <= 0) {
        _handleMinuteExpired();
      }
    });
  }

  void _pauseTimer() {
    _emomTimer?.cancel();
    setState(() => _isTimerRunning = false);
    HapticFeedback.lightImpact();
  }

  void _resetWorkout() {
    _emomTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _hasStarted = false;
      _elapsedTotalSeconds = 0;
      _secondsRemainingInMinute = 60;
      _currentMinute = 1;
      _completedMinutes = 0;
      _currentMinuteReps = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _handleMinuteExpired() {
    if (_isTargetMet) {
      // Completed the minute's target burpees!
      HapticFeedback.mediumImpact();
      _playBeepIfEnabled();
      setState(() {
        _completedMinutes++;
        _currentMinute++;
        _currentMinuteReps = 0;
        _secondsRemainingInMinute = 60;
      });
    } else {
      // Failed to hit the required burpees in 60s! EMOM cutoff.
      _emomTimer?.cancel();
      setState(() => _isTimerRunning = false);
      _playBeepIfEnabled();
      HapticFeedback.heavyImpact();

      _showCompletionDialog(
        completedMinutes: _completedMinutes,
        partialReps: _currentMinuteReps,
        durationSeconds: _elapsedTotalSeconds,
      );
    }
  }

  void _addMinuteReps(int delta) {
    if (!_hasStarted && !_isTimerRunning && delta > 0) {
      _startTimer();
    }

    HapticFeedback.selectionClick();
    setState(() {
      _currentMinuteReps = (_currentMinuteReps + delta).clamp(0, _currentMinuteTarget + 10);
    });

    if (_currentMinuteReps == _currentMinuteTarget) {
      HapticFeedback.heavyImpact();
    }
  }

  void _markTargetComplete() {
    if (!_hasStarted && !_isTimerRunning) {
      _startTimer();
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _currentMinuteReps = _currentMinuteTarget;
    });
  }

  void _advanceToNextMinuteNow() {
    HapticFeedback.mediumImpact();
    _playBeepIfEnabled();
    setState(() {
      _completedMinutes++;
      _currentMinute++;
      _currentMinuteReps = 0;
      _secondsRemainingInMinute = 60;
    });
  }

  void _tapOut() {
    _pauseTimer();
    HapticFeedback.heavyImpact();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Tap Out / Finish WOD?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'You completed $_completedMinutes full minute(s) + $_currentMinuteReps rep(s) in Minute $_currentMinute.\n\nTotal: $_currentCumulativeReps Burpees in ${_formatDuration(_elapsedTotalSeconds)}.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startTimer();
            },
            child: Text(
              'KEEP FIGHTING',
              style: GoogleFonts.outfit(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final int finalMinutes = _isTargetMet ? _completedMinutes + 1 : _completedMinutes;
              final int finalPartial = _isTargetMet ? 0 : _currentMinuteReps;
              _showCompletionDialog(
                completedMinutes: finalMinutes,
                partialReps: finalPartial,
                durationSeconds: _elapsedTotalSeconds,
              );
            },
            child: Text(
              'FINISH & LOG',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog({
    required int completedMinutes,
    required int partialReps,
    required int durationSeconds,
  }) {
    final RecoveryProvider recovery =
        Provider.of<RecoveryProvider>(context, listen: false);
    final DeathByBurpeesLog? currentPr =
        recovery.getDeathByBurpeesPersonalRecord(tier: _scalingTier);

    final DeathByBurpeesLog draft = DeathByBurpeesLog(
      completedMinutes: completedMinutes,
      partialReps: partialReps,
      totalDurationSeconds: durationSeconds,
      burpeeVariation: _burpeeVariation,
      scalingTier: _scalingTier,
    );

    final bool isNewPr = currentPr == null || draft.totalReps > currentPr.totalReps;

    // Calories: MET ~11.0
    final BodyCompProvider bodyComp =
        Provider.of<BodyCompProvider>(context, listen: false);
    final BodyCompositionEntry? latestEntry = bodyComp.latestEntry;
    final double weightKg = latestEntry?.weightKg ?? 75.0;
    final double hours = durationSeconds / 3600.0;
    final int caloriesBurned = (11.0 * weightKg * hours).round().clamp(10, 1500);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: <Widget>[
                  const Icon(Icons.bolt_rounded, color: AppTheme.primaryAmber, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isPreviewMode ? 'Workout Complete (Preview)' : 'EMOM Cutoff / Finished!',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Score Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            'DEATH BY BURPEES SCORE',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partialReps > 0
                                ? '$completedMinutes Mins + $partialReps Reps'
                                : '$completedMinutes Minutes',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryAmber,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${draft.totalReps} Total Burpees',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _scalingTier.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryCyan,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getBenchmarkTier(completedMinutes).toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryAmber,
                                  ),
                                ),
                              ),
                              if (isNewPr)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Total Duration: ${_formatDuration(durationSeconds)}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Variation: ${draft.variationDisplayName}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Est. Energy Burned: ~$caloriesBurned kcal',
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
                        hintText: 'e.g. Started slowing down at Minute 13...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resetWorkout();
                  },
                  child: Text(
                    'DISCARD',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final NavigatorState navigator = Navigator.of(ctx);
                    final NutritionProvider nutrition =
                        Provider.of<NutritionProvider>(context, listen: false);
                    if (!widget.isPreviewMode) {
                      final DeathByBurpeesLog logToSave = draft.copyWith(
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                      );
                      await recovery.logDeathByBurpees(logToSave);

                      try {
                        final DailyActivityEntry activityEntry = DailyActivityEntry.create(
                          activityType: 'workout_wod',
                          name: 'CrossFit: Death By Burpees ($_scalingTier)',
                          durationMinutes: durationSeconds / 60.0,
                          metValue: 11.0,
                          caloriesBurned: caloriesBurned,
                          source: 'wod_auto_sync',
                          notes: logToSave.scoreDisplay,
                        );
                        await nutrition.addActivity(activityEntry, latestBodyComp: latestEntry);
                      } catch (_) {}
                    }

                    if (mounted) {
                      navigator.pop();
                      widget.onCompleted();
                    }
                  },
                  child: Text(
                    widget.isPreviewMode ? 'DISMISS' : 'SAVE TO LOGS',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveManualEntry() async {
    final int completedMinutes = int.tryParse(_manualMinutesController.text.trim()) ?? 0;
    final int partialReps = int.tryParse(_manualPartialRepsController.text.trim()) ?? 0;

    if (completedMinutes <= 0 && partialReps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter valid completed minutes or partial reps.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final int durationSeconds = (completedMinutes * 60) + (partialReps > 0 ? 60 : 0);
    _showCompletionDialog(
      completedMinutes: completedMinutes,
      partialReps: partialReps,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final DeathByBurpeesLog? bestPr =
        recovery.getDeathByBurpeesPersonalRecord(tier: _scalingTier);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.primaryAmber,
                  size: 24,
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
                          'DEATH BY BURPEES',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'EMOM',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Minute N = N Burpees until cutoff',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                tooltip: 'Setup & Standards',
                onPressed: () {
                  WodSetupExplainerSheet.show(context, WodCatalog.deathByBurpees);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // PR Banner if present
          if (bestPr != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.emoji_events, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Personal Record ($_scalingTier):',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bestPr.scoreDisplay,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),

          // Segmented Switch: LIVE TRACKER vs MANUAL ENTRY
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isManualEntry = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isManualEntry
                            ? AppTheme.primaryAmber.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'LIVE EMOM TRACKER',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: !_isManualEntry
                                ? AppTheme.primaryAmber
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isManualEntry = true);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isManualEntry
                            ? AppTheme.secondaryCyan.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'MANUAL SCORE LOG',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isManualEntry
                                ? AppTheme.secondaryCyan
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Burpee Variation Selector
          Row(
            children: <Widget>[
              Text(
                'Variation:',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _burpeeVariation,
                      dropdownColor: AppTheme.surfaceElevated,
                      isExpanded: true,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'standard',
                          child: Text('Chest-to-Floor Burpees (Rx)'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'no_pushup',
                          child: Text('No-Pushup Sprawls (Scaled)'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'box_elevated',
                          child: Text('Elevated Hands on Box (Scaled)'),
                        ),
                      ],
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() => _burpeeVariation = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isManualEntry)
            _buildManualEntryView()
          else
            _buildLiveTrackerView(),
        ],
      ),
    );
  }

  Widget _buildLiveTrackerView() {
    final double minuteProgress = (60 - _secondsRemainingInMinute) / 60.0;

    return Column(
      children: <Widget>[
        // Main Clocks Display: Minute Countdown & Total Elapsed
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppTheme.surfaceElevated, AppTheme.darkBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isTargetMet
                  ? Colors.greenAccent.withValues(alpha: 0.6)
                  : (_secondsRemainingInMinute <= 10
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : AppTheme.borderColor),
              width: 1.5,
            ),
          ),
          child: Column(
            children: <Widget>[
              // Minute Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'MINUTE $_currentMinute',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryAmber,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    'Total Time: ${_formatDuration(_elapsedTotalSeconds)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 60-Second Countdown Dial
              Text(
                '$_secondsRemainingInMinute',
                style: GoogleFonts.outfit(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: _secondsRemainingInMinute <= 10
                      ? Colors.redAccent
                      : AppTheme.textPrimary,
                  height: 1.0,
                ),
              ),
              Text(
                'SECONDS REMAINING IN ROUND',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: minuteProgress,
                  backgroundColor: AppTheme.surfaceCard,
                  color: _isTargetMet ? Colors.greenAccent : AppTheme.primaryAmber,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Current Minute Target & Rep Counter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isTargetMet
                  ? Colors.greenAccent.withValues(alpha: 0.4)
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'MINUTE $_currentMinute TARGET:',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_currentMinuteTarget BURPEES',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Reps Done vs Target
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    '$_currentMinuteReps',
                    style: GoogleFonts.outfit(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: _isTargetMet ? Colors.greenAccent : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    ' / $_currentMinuteTarget',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              if (_isTargetMet) ...<Widget>[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Target met! Rest until next minute',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Rep Stepper Buttons (-1, +1, +2, +5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildStepperButton('-1', () => _addMinuteReps(-1), isSubtle: true),
                  _buildStepperButton('+1', () => _addMinuteReps(1)),
                  _buildStepperButton('+2', () => _addMinuteReps(2)),
                  _buildStepperButton('+5', () => _addMinuteReps(5)),
                  ElevatedButton(
                    onPressed: _markTargetComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTargetMet ? Colors.green : AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'TARGET MET ✓',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),

              if (_isTargetMet) ...<Widget>[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _advanceToNextMinuteNow,
                  icon: const Icon(Icons.fast_forward_rounded, size: 16),
                  label: Text(
                    'ADVANCE TO NEXT MINUTE NOW',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryCyan,
                    side: const BorderSide(color: AppTheme.secondaryCyan),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Total Burpees so far & Tier
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Total Reps Done: $_currentCumulativeReps',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Current Tier: ${_getBenchmarkTier(_completedMinutes)}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Main Timer Control Buttons (Start / Pause / Reset / Tap Out)
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTimerRunning ? Colors.orangeAccent : AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                icon: Icon(
                  _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 24,
                ),
                label: Text(
                  !_hasStarted
                      ? 'START EMOM'
                      : (_isTimerRunning ? 'PAUSE CLOCK' : 'RESUME CLOCK'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (_hasStarted) ...<Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: _tapOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'TAP OUT',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                tooltip: 'Reset',
                onPressed: _resetWorkout,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStepperButton(String label, VoidCallback onTap, {bool isSubtle = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSubtle ? AppTheme.surfaceCard : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSubtle ? AppTheme.borderColor : AppTheme.primaryAmber.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSubtle ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'LOG COMPLETED DEATH BY BURPEES SESSION',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Completed Minutes',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _manualMinutesController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 14',
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Partial Reps (Final Min)',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _manualPartialRepsController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 8',
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Total Burpees Preview
          Builder(
            builder: (BuildContext context) {
              final int mins = int.tryParse(_manualMinutesController.text) ?? 0;
              final int partial = int.tryParse(_manualPartialRepsController.text) ?? 0;
              final int fullReps = mins > 0 ? (mins * (mins + 1)) ~/ 2 : 0;
              final int total = fullReps + partial;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Total Calculated Burpees:',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '$total Reps (${_getBenchmarkTier(mins)})',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveManualEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                'LOG BENCHMARK SCORE',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
