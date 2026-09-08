import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/cindy_variation_modal.dart';
import 'package:provider/provider.dart';

class CindyWodCard extends StatefulWidget {
  const CindyWodCard({
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
  State<CindyWodCard> createState() => _CindyWodCardState();
}

class _CindyWodCardState extends State<CindyWodCard> {
  // Timer state (20 minutes = 1200 seconds)
  static const int _totalWodSeconds = 1200;
  Timer? _wodTimer;
  int _secondsRemaining = _totalWodSeconds;
  bool _isTimerRunning = false;
  bool _hasStarted = false;
  bool _isEmomBeepEnabled = false;
  bool _initializedSettings = false;

  // Active round state
  int _completedRounds = 0;
  int _currentPullups = 0;
  int _currentPushups = 0;
  int _currentSquats = 0;

  // Active variations (carry over per round)
  String _currentPullupVariation = 'standard';
  double? _currentPullupWeightKg;
  String? _currentPullupBand;

  String _currentPushupVariation = 'standard';
  double? _currentPushupWeightKg;

  String _currentSquatVariation = 'standard';
  double? _currentSquatWeightKg;

  // Per-round tracking
  final List<CindyRoundDetail> _loggedRounds = <CindyRoundDetail>[];
  int _lastRoundEndElapsed = 0;

  // Manual entry toggle
  bool _isManualEntry = false;
  late TextEditingController _manualRoundsController;
  late TextEditingController _manualPullupsController;
  late TextEditingController _manualPushupsController;
  late TextEditingController _manualSquatsController;
  late TextEditingController _notesController;

  bool _isSaved = false;
  late bool _isLiveMode;

  @override
  void initState() {
    super.initState();
    _isLiveMode = !widget.isPreviewMode;
    _manualRoundsController = TextEditingController(text: '15');
    _manualPullupsController = TextEditingController(text: '0');
    _manualPushupsController = TextEditingController(text: '0');
    _manualSquatsController = TextEditingController(text: '0');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _wodTimer?.cancel();
    _manualRoundsController.dispose();
    _manualPullupsController.dispose();
    _manualPushupsController.dispose();
    _manualSquatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _elapsedSeconds => _totalWodSeconds - _secondsRemaining;

  int get _currentEmomMinute => ((_elapsedSeconds ~/ 60) + 1).clamp(1, 20);

  int get _secondsLeftInMinute {
    if (_secondsRemaining <= 0) {
      return 0;
    }
    final int rem = _secondsRemaining % 60;
    return rem == 0 ? 60 : rem;
  }

  double get _currentMinuteProgress => (60 - _secondsLeftInMinute) / 60.0;

  int get _currentTotalReps {
    return (_completedRounds * 30) + _currentPullups + _currentPushups + _currentSquats;
  }

  String get _currentRoundTier {
    final bool isScaled = _currentPullupVariation == 'band_assisted' ||
        _currentPullupVariation == 'ring_rows' ||
        _currentPullupVariation == 'jumping' ||
        _currentPushupVariation == 'knee' ||
        _currentPushupVariation == 'incline' ||
        _currentSquatVariation == 'box_squat';
    if (isScaled) {
      return 'Scaled';
    }

    final bool isWeighted = _currentPullupVariation == 'weighted' ||
        _currentPushupVariation == 'weighted' ||
        _currentPushupVariation == 'pike' ||
        _currentPushupVariation == 'hspu' ||
        _currentSquatVariation == 'goblet' ||
        _currentSquatVariation == 'weighted_vest';
    if (isWeighted) {
      return 'Weighted';
    }

    return 'Rx';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedSettings) {
      try {
        final SettingsProvider settings =
            Provider.of<SettingsProvider>(context, listen: false);
        _isEmomBeepEnabled = settings.cindyEmomBeepEnabled;
      } catch (_) {}
      _initializedSettings = true;
    }
  }

  void _toggleEmomBeep() {
    HapticFeedback.selectionClick();
    final bool updated = !_isEmomBeepEnabled;
    setState(() {
      _isEmomBeepEnabled = updated;
    });
    try {
      final SettingsProvider settings =
          Provider.of<SettingsProvider>(context, listen: false);
      settings.setCindyEmomBeepEnabled(updated);
    } catch (_) {}
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

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isTimerRunning) {
      _wodTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (!_hasStarted) {
        _playBeepIfEnabled();
        _hasStarted = true;
      }
      setState(() => _isTimerRunning = true);
      _wodTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });

          // Expiration & countdown alerts
          if (_secondsRemaining == 0) {
            _handleTimeExpired();
          } else if (_secondsRemaining <= 5) {
            HapticFeedback.selectionClick();
          } else if (_isEmomBeepEnabled) {
            final int secInMin = _secondsRemaining % 60;
            if (secInMin == 0) {
              // Top of the minute interval beep!
              HapticFeedback.heavyImpact();
              _playBeepIfEnabled();
            } else if (secInMin <= 3 && secInMin >= 1) {
              // 3-2-1 tactile countdown clicks
              HapticFeedback.selectionClick();
            }
          }
        } else {
          timer.cancel();
          setState(() => _isTimerRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _wodTimer?.cancel();
    setState(() {
      _secondsRemaining = _totalWodSeconds;
      _isTimerRunning = false;
      _hasStarted = false;
      _completedRounds = 0;
      _currentPullups = 0;
      _currentPushups = 0;
      _currentSquats = 0;
      _loggedRounds.clear();
      _lastRoundEndElapsed = 0;
      _isSaved = false;
    });
  }

  void _handleTimeExpired() {
    _wodTimer?.cancel();
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();
    setState(() => _isTimerRunning = false);
    _promptFinishWorkout();
  }

  void _completeRound() {
    HapticFeedback.mediumImpact();
    final int elapsed = _elapsedSeconds;
    final int roundDuration = elapsed - _lastRoundEndElapsed;
    _lastRoundEndElapsed = elapsed;

    final CindyRoundDetail detail = CindyRoundDetail(
      roundNumber: _completedRounds + 1,
      pullupVariation: _currentPullupVariation,
      pullupAddedWeightKg: _currentPullupWeightKg,
      pullupBandAssistance: _currentPullupBand,
      pushupVariation: _currentPushupVariation,
      pushupAddedWeightKg: _currentPushupWeightKg,
      squatVariation: _currentSquatVariation,
      squatAddedWeightKg: _currentSquatWeightKg,
      splitTimeSeconds: elapsed,
      roundDurationSeconds: roundDuration > 0 ? roundDuration : 0,
    );

    setState(() {
      _loggedRounds.add(detail);
      _completedRounds++;
      _currentPullups = 0;
      _currentPushups = 0;
      _currentSquats = 0;
    });
  }

  void _togglePullups() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentPullups == 5) {
        _currentPullups = 0;
      } else {
        _currentPullups = 5;
        _checkAutoRoundComplete();
      }
    });
  }

  void _togglePushups() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentPushups == 10) {
        _currentPushups = 0;
      } else {
        _currentPushups = 10;
        _checkAutoRoundComplete();
      }
    });
  }

  void _toggleSquats() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentSquats == 15) {
        _currentSquats = 0;
      } else {
        _currentSquats = 15;
        _checkAutoRoundComplete();
      }
    });
  }

  void _checkAutoRoundComplete() {
    if (_currentPullups == 5 && _currentPushups == 10 && _currentSquats == 15) {
      _completeRound();
    }
  }

  void _openVariationModal({String? movementFocus}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => CindyVariationModal(
        initialPullupVariation: _currentPullupVariation,
        initialPullupWeightKg: _currentPullupWeightKg,
        initialPullupBand: _currentPullupBand,
        initialPushupVariation: _currentPushupVariation,
        initialPushupWeightKg: _currentPushupWeightKg,
        initialSquatVariation: _currentSquatVariation,
        initialSquatWeightKg: _currentSquatWeightKg,
        initialSelectedMovement: movementFocus,
        onApply: ({
          required String pullupVariation,
          required String pushupVariation,
          required String squatVariation,
          double? pullupWeightKg,
          String? pullupBand,
          double? pushupWeightKg,
          double? squatWeightKg,
        }) {
          setState(() {
            _currentPullupVariation = pullupVariation;
            _currentPullupWeightKg = pullupWeightKg;
            _currentPullupBand = pullupBand;
            _currentPushupVariation = pushupVariation;
            _currentPushupWeightKg = pushupWeightKg;
            _currentSquatVariation = squatVariation;
            _currentSquatWeightKg = squatWeightKg;
          });
        },
      ),
    );
  }

  Future<void> _promptFinishWorkout() async {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context, listen: false);
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context, listen: false);

    final int rounds = _completedRounds;
    final int extraPull = _currentPullups;
    final int extraPush = _currentPushups;
    final int extraSquat = _currentSquats;

    final CindyWorkoutLog draft = CindyWorkoutLog(
      durationSeconds: _elapsedSeconds > 0 ? _elapsedSeconds : _totalWodSeconds,
      completedRounds: rounds,
      partialPullups: extraPull,
      partialPushups: extraPush,
      partialSquats: extraSquat,
      rounds: List<CindyRoundDetail>.from(_loggedRounds),
      partialPullupVariation: _currentPullupVariation,
      partialPushupVariation: _currentPushupVariation,
      partialSquatVariation: _currentSquatVariation,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final CindyWorkoutLog? currentPr = recovery.getCindyPersonalRecord(tier: draft.scalingTier);
    final bool isNewPr = currentPr == null || draft.totalReps > currentPr.totalReps;

    // MET calculation: Scaled = 7.5, Rx = 8.5, Weighted = 9.5
    final double met = draft.scalingTier == 'Weighted'
        ? 9.5
        : draft.scalingTier == 'Scaled'
            ? 7.5
            : 8.5;
    final BodyCompositionEntry? latestComp = bodyComp.latestEntry;
    final double weightKg = latestComp != null ? latestComp.weightLb * 0.45359237 : 80.0;
    final double durationHours = draft.durationSeconds / 3600.0;
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
                'Complete Cindy AMRAP',
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
                      'TOTAL SCORE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      draft.scoreDisplay,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
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
              Text(
                'Progression: ${draft.progressionSummary}',
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
                  hintText: 'e.g. Switched to banded at round 8, felt great grip',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
      final CindyWorkoutLog finalized = await recovery.logCindyWorkout(draft);
      final DailyActivityEntry activityEntry = DailyActivityEntry.create(
        activityType: 'workout_wod',
        name: 'CrossFit WOD: Cindy (AMRAP 20m)',
        durationMinutes: finalized.durationSeconds / 60.0,
        metValue: met,
        caloriesBurned: caloriesBurned,
        source: 'wod_auto_sync',
        notes: finalized.scoreDisplay,
      );
      await nutrition.addActivity(activityEntry, latestBodyComp: latestComp);

      setState(() => _isSaved = true);
      widget.onCompleted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceElevated,
            content: Text(
              'Cindy WOD logged! ${finalized.scoreDisplay} saved.',
              style: GoogleFonts.outfit(color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveManualScore() async {
    final int rounds = int.tryParse(_manualRoundsController.text) ?? 0;
    final int extraPull = (int.tryParse(_manualPullupsController.text) ?? 0).clamp(0, 5);
    final int extraPush = (int.tryParse(_manualPushupsController.text) ?? 0).clamp(0, 10);
    final int extraSquat = (int.tryParse(_manualSquatsController.text) ?? 0).clamp(0, 15);

    setState(() {
      _completedRounds = rounds;
      _currentPullups = extraPull;
      _currentPushups = extraPush;
      _currentSquats = extraSquat;
    });

    await _promptFinishWorkout();
  }

  void _showHistorySheet(BuildContext context, RecoveryProvider recovery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final List<CindyWorkoutLog> history = recovery.getCindyWorkoutHistory();
        final CindyWorkoutLog? pr = recovery.getCindyPersonalRecord();

        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Cindy AMRAP History',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                if (pr != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            AppTheme.primaryAmber.withValues(alpha: 0.15),
                            AppTheme.surfaceElevated,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.emoji_events, color: AppTheme.primaryAmber, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'ALL-TIME PERSONAL BEST',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryAmber,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  pr.scoreDisplay,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd().format(pr.date),
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            'No Cindy sessions logged yet.\nComplete an AMRAP to start tracking your score!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: history.length,
                          separatorBuilder: (BuildContext _, int _) => const Divider(color: AppTheme.borderColor),
                          itemBuilder: (BuildContext _, int index) {
                            final CindyWorkoutLog log = history[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: log.isPr
                                      ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                                      : AppTheme.surfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  log.isPr ? Icons.emoji_events : Icons.fitness_center,
                                  size: 18,
                                  color: log.isPr ? AppTheme.primaryAmber : AppTheme.secondaryCyan,
                                ),
                              ),
                              title: Text(
                                log.scoreDisplay,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat.yMMMd().format(log.date)} • ${log.progressionSummary}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Text(
                                  log.scalingTier,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: log.scalingTier == 'Rx'
                                        ? AppTheme.primaryAmber
                                        : log.scalingTier == 'Weighted'
                                            ? Colors.purpleAccent
                                            : Colors.tealAccent,
                                  ),
                                ),
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
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final CindyWorkoutLog? allTimePr = recovery.getCindyPersonalRecord();

    final int minutes = _secondsRemaining ~/ 60;
    final int seconds = _secondsRemaining % 60;
    final String timerFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

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
          // Preview Mode Banner if active
          if (!_isLiveMode) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.explore, color: AppTheme.secondaryCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PREVIEW MODE — Test timers & scalings without saving.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isLiveMode = true);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'GO LIVE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Header: Category Badges & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'CROSSFIT WOD',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '20M AMRAP',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  // History
                  InkWell(
                    onTap: () => _showHistorySheet(context, recovery),
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
                          const Icon(Icons.show_chart, size: 14, color: AppTheme.secondaryCyan),
                          const SizedBox(width: 4),
                          Text(
                            'History',
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
                  if (widget.onOpenSwapModal != null) ...<Widget>[
                    const SizedBox(width: 6),
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
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(
            'Cindy (AMRAP 20)',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '5 Pull-ups • 10 Push-ups • 15 Squats for as many rounds as possible in 20:00.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // PR Glance
          if (allTimePr != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.emoji_events, size: 16, color: AppTheme.primaryAmber),
                  const SizedBox(width: 6),
                  Text(
                    'Best Score: ${allTimePr.scoreDisplay} (${allTimePr.scalingTier})',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ],
              ),
            ),

          // Live Timer / Manual Entry Segmented Switch
          Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isManualEntry = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isManualEntry ? AppTheme.secondaryCyan : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Live AMRAP Timer',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !_isManualEntry ? Colors.black : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isManualEntry = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _isManualEntry ? AppTheme.secondaryCyan : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Manual Score Entry',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isManualEntry ? Colors.black : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_isManualEntry) ...<Widget>[
            // 20:00 Timer Display & Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isTimerRunning ? AppTheme.secondaryCyan : AppTheme.borderColor,
                ),
              ),
              child: Column(
                children: <Widget>[
                  // Top Row: Label & EMOM Beep Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'TIME REMAINING',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      // EMOM Beep Pill Switch
                      InkWell(
                        onTap: _toggleEmomBeep,
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isEmomBeepEnabled
                                ? AppTheme.successGreen.withValues(alpha: 0.15)
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isEmomBeepEnabled
                                  ? AppTheme.successGreen
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                _isEmomBeepEnabled
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_off_outlined,
                                size: 13,
                                color: _isEmomBeepEnabled
                                    ? AppTheme.successGreen
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isEmomBeepEnabled ? 'EMOM BEEP ON' : 'EMOM BEEP OFF',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isEmomBeepEnabled
                                      ? AppTheme.successGreen
                                      : AppTheme.textSecondary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Middle Row: Big Digits & Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        timerFormatted,
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: _secondsRemaining < 60 ? Colors.redAccent : AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          IconButton.filled(
                            onPressed: _toggleTimer,
                            icon: Icon(
                              _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.black,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  _isTimerRunning ? AppTheme.warningOrange : AppTheme.secondaryCyan,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // EMOM Pacer Bar (visible when EMOM Beep is enabled)
                  if (_isEmomBeepEnabled) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.successGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isTimerRunning ? AppTheme.successGreen : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'EMOM Min $_currentEmomMinute of 20',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _secondsRemaining == 0
                                    ? 'Workout Complete'
                                    : 'Beep in ${_secondsLeftInMinute}s',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _secondsLeftInMinute <= 5
                                      ? AppTheme.successGreen
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _currentMinuteProgress,
                              minHeight: 4,
                              backgroundColor: AppTheme.borderColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _secondsLeftInMinute <= 3
                                    ? AppTheme.primaryAmber
                                    : AppTheme.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Rounds & Reps Counter
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'CURRENT ROUND',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Round ${_completedRounds + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                      // Round Tier Pill with Configure Action
                      InkWell(
                        onTap: () => _openVariationModal(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _currentRoundTier == 'Rx'
                                ? AppTheme.primaryAmber.withValues(alpha: 0.15)
                                : _currentRoundTier == 'Weighted'
                                    ? Colors.purpleAccent.withValues(alpha: 0.15)
                                    : Colors.tealAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _currentRoundTier == 'Rx'
                                  ? AppTheme.primaryAmber
                                  : _currentRoundTier == 'Weighted'
                                      ? Colors.purpleAccent
                                      : Colors.tealAccent,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                _currentRoundTier.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _currentRoundTier == 'Rx'
                                      ? AppTheme.primaryAmber
                                      : _currentRoundTier == 'Weighted'
                                          ? Colors.purpleAccent
                                          : Colors.tealAccent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.tune, size: 14, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderColor, height: 20),

                  // Sub-Rep Checkers with 1-Tap Variation Pills
                  _buildExerciseCheckRow(
                    title: '5 Pull-ups',
                    count: _currentPullups,
                    target: 5,
                    variationLabel: _getPullupLabel(),
                    onTapCount: _togglePullups,
                    onTapVariation: () => _openVariationModal(movementFocus: 'pull_ups'),
                  ),
                  const SizedBox(height: 10),
                  _buildExerciseCheckRow(
                    title: '10 Push-ups',
                    count: _currentPushups,
                    target: 10,
                    variationLabel: _getPushupLabel(),
                    onTapCount: _togglePushups,
                    onTapVariation: () => _openVariationModal(movementFocus: 'push_ups'),
                  ),
                  const SizedBox(height: 10),
                  _buildExerciseCheckRow(
                    title: '15 Squats',
                    count: _currentSquats,
                    target: 15,
                    variationLabel: _getSquatLabel(),
                    onTapCount: _toggleSquats,
                    onTapVariation: () => _openVariationModal(movementFocus: 'squats'),
                  ),
                  const SizedBox(height: 14),

                  // Complete Round Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _completeRound,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                      label: Text(
                        '+1 ROUND COMPLETE',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Live Summary & Finish Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Live Score: $_completedRounds Rds + ${_currentPullups + _currentPushups + _currentSquats} Reps ($_currentTotalReps reps)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
                ElevatedButton(
                  onPressed: _promptFinishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isSaved ? 'SAVED' : 'FINISH WOD',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            if (_loggedRounds.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                'ROUND SPLIT TIMELINE (${_loggedRounds.length} Completed)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _loggedRounds.length,
                  separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext _, int index) {
                    final CindyRoundDetail r = _loggedRounds[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Rd ${r.roundNumber} • ${r.formattedSplit}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            r.roundTier,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: r.roundTier == 'Rx'
                                  ? AppTheme.primaryAmber
                                  : r.roundTier == 'Weighted'
                                      ? Colors.purpleAccent
                                      : Colors.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ] else ...<Widget>[
            // Manual Score Entry View
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'MANUAL AMRAP ENTRY',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Completed Rounds',
                          controller: _manualRoundsController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Extra Reps at 20:00 Buzzer:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Pull-ups (0..5)',
                          controller: _manualPullupsController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Push-ups (0..10)',
                          controller: _manualPushupsController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Squats (0..15)',
                          controller: _manualSquatsController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Progression / Tier: $_currentRoundTier',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openVariationModal(),
                        icon: const Icon(Icons.tune, size: 14, color: AppTheme.secondaryCyan),
                        label: Text(
                          'Variations',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveManualScore,
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: Text(
                        'Save Manual WOD Score',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseCheckRow({
    required String title,
    required int count,
    required int target,
    required String variationLabel,
    required VoidCallback onTapCount,
    required VoidCallback onTapVariation,
  }) {
    final bool isDone = count >= target;
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            onTap: onTapCount,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.greenAccent.withValues(alpha: 0.15)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone ? Colors.greenAccent : AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isDone ? Colors.greenAccent : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.greenAccent : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$count / $target',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDone ? Colors.greenAccent : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onTapVariation,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  variationLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.secondaryCyan),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getPullupLabel() {
    switch (_currentPullupVariation) {
      case 'chin_up':
        return 'Chin-up';
      case 'band_assisted':
        return 'Banded';
      case 'ring_rows':
        return 'Ring Rows';
      case 'jumping':
        return 'Jumping';
      case 'weighted':
        return 'Weighted';
      case 'standard':
      default:
        return 'Strict';
    }
  }

  String _getPushupLabel() {
    switch (_currentPushupVariation) {
      case 'knee':
        return 'Knee';
      case 'incline':
        return 'Incline';
      case 'pike':
        return 'Pike';
      case 'hspu':
        return 'HSPU';
      case 'weighted':
        return 'Weighted';
      case 'standard':
      default:
        return 'Strict';
    }
  }

  String _getSquatLabel() {
    switch (_currentSquatVariation) {
      case 'box_squat':
        return 'Box';
      case 'goblet':
        return 'Goblet';
      case 'weighted_vest':
        return 'Vest';
      case 'standard':
      default:
        return 'Air';
    }
  }
}
