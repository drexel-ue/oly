import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/dt_workout_log.dart';
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

class DtWodCard extends StatefulWidget {
  const DtWodCard({
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
  State<DtWodCard> createState() => _DtWodCardState();
}

class _DtWodCardState extends State<DtWodCard> {
  // Timer state (For Time stopwatch counting UP)
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _hasStarted = false;

  // Active round: 0..4 (Rounds 1–5), 5 = Finished
  int _activeRoundIndex = 0;

  // Cumulative split times (elapsed seconds at completion of each round)
  final List<int?> _roundSplits = <int?>[null, null, null, null, null];

  // Reps done per round: List of [deadlifts, cleans, jerks]
  final List<List<int>> _repsDone = <List<int>>[
    <int>[0, 0, 0], // R1
    <int>[0, 0, 0], // R2
    <int>[0, 0, 0], // R3
    <int>[0, 0, 0], // R4
    <int>[0, 0, 0], // R5
  ];

  // Configuration
  double _barbellWeightKg = 70.3; // 155 lb standard Rx Men (47.6 kg / 105 lb Rx Women)
  bool _isRxWomen = false;

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
    _manualMinutesController = TextEditingController(text: '7');
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
    final double rxMinWeight = _isRxWomen ? 46.0 : 69.0;
    if (_barbellWeightKg < rxMinWeight) {
      return 'Scaled';
    }

    final double rxMaxWeight = _isRxWomen ? 50.0 : 73.0;
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
      _activeRoundIndex = 0;
      for (int i = 0; i < 5; i++) {
        _roundSplits[i] = null;
        _repsDone[i] = <int>[0, 0, 0];
      }
    });
    HapticFeedback.mediumImpact();
  }

  void _completeRound(int roundIndex) {
    HapticFeedback.heavyImpact();
    _playBeepIfEnabled();

    setState(() {
      _repsDone[roundIndex] = <int>[12, 9, 6];
      _roundSplits[roundIndex] = _elapsedSeconds;
      _activeRoundIndex = roundIndex + 1;
    });

    if (roundIndex == 4) {
      // Completed all 5 rounds!
      _stopwatchTimer?.cancel();
      _isTimerRunning = false;
      _promptSaveScoreDialog();
    }
  }

  Future<void> _promptSaveScoreDialog() async {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context, listen: false);
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context, listen: false);

    final int totalSeconds = _elapsedSeconds > 0 ? _elapsedSeconds : 450; // 7:30 fallback

    final DtWorkoutLog draft = DtWorkoutLog(
      totalTimeSeconds: totalSeconds,
      round1TimeSeconds: _roundSplits[0],
      round2TimeSeconds: _roundSplits[1] != null && _roundSplits[0] != null
          ? _roundSplits[1]! - _roundSplits[0]!
          : null,
      round3TimeSeconds: _roundSplits[2] != null && _roundSplits[1] != null
          ? _roundSplits[2]! - _roundSplits[1]!
          : null,
      round4TimeSeconds: _roundSplits[3] != null && _roundSplits[2] != null
          ? _roundSplits[3]! - _roundSplits[2]!
          : null,
      round5TimeSeconds: _roundSplits[4] != null && _roundSplits[3] != null
          ? _roundSplits[4]! - _roundSplits[3]!
          : null,
      barbellWeightKg: _barbellWeightKg,
      isRxWomen: _isRxWomen,
      scalingTier: _scalingTier,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final DtWorkoutLog? currentPr = recovery.getDtPersonalRecord(tier: draft.scalingTier);
    final bool isNewPr = currentPr == null || draft.totalTimeSeconds < currentPr.totalTimeSeconds;

    // MET calculation: 12.5 for heavy 5-round Olympic barbell sprint
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
                'Complete DT WOD',
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
                  'R1: ${draft.formattedRound1Time} • R2: ${draft.formattedRound2Time ?? "--:--"} • R3: ${draft.formattedRound3Time ?? "--:--"}\nR4: ${draft.formattedRound4Time ?? "--:--"} • R5: ${draft.formattedRound5Time ?? "--:--"}' ,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Barbell: ${draft.loadDisplayName}',
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
                  hintText: 'e.g. 11-1 deadlift break worked great',
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
      final DtWorkoutLog finalized = await recovery.logDtWorkout(draft);
      final DailyActivityEntry activityEntry = DailyActivityEntry.create(
        activityType: 'workout_wod',
        name: 'CrossFit Hero WOD: DT (5 Rounds For Time)',
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
              'DT Hero WOD logged! ${finalized.scoreDisplay} saved.',
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
    final DtWorkoutLog? bestPr = recovery.getDtPersonalRecord(tier: _scalingTier);

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

  Widget _buildHeader(DtWorkoutLog? bestPr) {
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
                  Icons.shield_outlined,
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
                          'CrossFit Hero: DT',
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
                            '5 ROUNDS',
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
                      '12 Deadlifts, 9 Hang Cleans, 6 Push Jerks (155/105 lb)',
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
                    WodCatalog.dt,
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

        // Load Selector Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
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
                  DropdownMenuItem<double>(value: 70.3, child: Text('155 lb / 70.3 kg (Rx Men)')),
                  DropdownMenuItem<double>(value: 47.6, child: Text('105 lb / 47.6 kg (Rx Women)')),
                  DropdownMenuItem<double>(value: 61.2, child: Text('135 lb / 61.2 kg (Scaled)')),
                  DropdownMenuItem<double>(value: 52.2, child: Text('115 lb / 52.2 kg (Scaled)')),
                  DropdownMenuItem<double>(value: 43.1, child: Text('95 lb / 43.1 kg (Scaled)')),
                  DropdownMenuItem<double>(value: 34.0, child: Text('75 lb / 34.0 kg (Light)')),
                ],
                onChanged: (double? val) {
                  if (val != null) {
                    setState(() {
                      _barbellWeightKg = val;
                      _isRxWomen = (val == 47.6);
                    });
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 5 Rounds Cards
        for (int round = 0; round < 5; round++) ...<Widget>[
          _buildRoundCard(
            roundNum: round + 1,
            deadliftsDone: _repsDone[round][0],
            cleansDone: _repsDone[round][1],
            jerksDone: _repsDone[round][2],
            splitSeconds: _roundSplits[round] != null
                ? (round == 0 ? _roundSplits[0] : _roundSplits[round]! - _roundSplits[round - 1]!)
                : null,
            isActive: _activeRoundIndex == round,
            isCompleted: _activeRoundIndex > round,
            onDeadliftAdd: (int n) => setState(() => _repsDone[round][0] = (_repsDone[round][0] + n).clamp(0, 12)),
            onCleanAdd: (int n) => setState(() => _repsDone[round][1] = (_repsDone[round][1] + n).clamp(0, 9)),
            onJerkAdd: (int n) => setState(() => _repsDone[round][2] = (_repsDone[round][2] + n).clamp(0, 6)),
            onCompleteRound: () => _completeRound(round),
            buttonText: round == 4
                ? 'FINISH DT! 🏁 (${_formatSeconds(_elapsedSeconds)})'
                : 'COMPLETE ROUND ${round + 1} (${_formatSeconds(_elapsedSeconds)}) -> GO TO ROUND ${round + 2}',
            isFinalRound: round == 4,
          ),
          if (round < 4) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRoundCard({
    required int roundNum,
    required int deadliftsDone,
    required int cleansDone,
    required int jerksDone,
    required int? splitSeconds,
    required bool isActive,
    required bool isCompleted,
    required void Function(int) onDeadliftAdd,
    required void Function(int) onCleanAdd,
    required void Function(int) onJerkAdd,
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
                      'Round $roundNum of 5',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '12 Deadlifts • 9 Hang Cleans • 6 Push Jerks',
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

            // Station 1: 12 Deadlifts
            _buildMovementCounter(
              name: '12 Deadlifts',
              done: deadliftsDone,
              target: 12,
              color: AppTheme.primaryAmber,
              chips: <Widget>[
                _buildRepChip('+6', () => onDeadliftAdd(6)),
                _buildRepChip('+11 (Drop)', () => onDeadliftAdd(11)),
                _buildRepChip('-1', () => onDeadliftAdd(-1)),
                _buildRepChip('12 Unbroken', () => onDeadliftAdd(12), isHighlight: true),
              ],
            ),

            const SizedBox(height: 12),

            // Station 2: 9 Hang Power Cleans
            _buildMovementCounter(
              name: '9 Hang Power Cleans',
              done: cleansDone,
              target: 9,
              color: AppTheme.secondaryCyan,
              chips: <Widget>[
                _buildRepChip('+4', () => onCleanAdd(4)),
                _buildRepChip('+8 (Drop)', () => onCleanAdd(8)),
                _buildRepChip('-1', () => onCleanAdd(-1)),
                _buildRepChip('9 Unbroken', () => onCleanAdd(9), isHighlight: true),
              ],
            ),

            const SizedBox(height: 12),

            // Station 3: 6 Push Jerks
            _buildMovementCounter(
              name: '6 Push Jerks',
              done: jerksDone,
              target: 6,
              color: Colors.orangeAccent,
              chips: <Widget>[
                _buildRepChip('+3', () => onJerkAdd(3)),
                _buildRepChip('-1', () => onJerkAdd(-1)),
                _buildRepChip('6 Unbroken', () => onJerkAdd(6), isHighlight: true),
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
          'MANUAL DT LOG',
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
        DropdownButtonFormField<double>(
          initialValue: _barbellWeightKg,
          decoration: InputDecoration(
            labelText: 'Barbell Load',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          dropdownColor: AppTheme.surfaceElevated,
          items: const <DropdownMenuItem<double>>[
            DropdownMenuItem<double>(value: 70.3, child: Text('155 lb (Rx Men)')),
            DropdownMenuItem<double>(value: 47.6, child: Text('105 lb (Rx Women)')),
            DropdownMenuItem<double>(value: 61.2, child: Text('135 lb (Scaled)')),
            DropdownMenuItem<double>(value: 52.2, child: Text('115 lb (Scaled)')),
            DropdownMenuItem<double>(value: 43.1, child: Text('95 lb (Scaled)')),
            DropdownMenuItem<double>(value: 34.0, child: Text('75 lb (Light)')),
          ],
          onChanged: (double? val) {
            if (val != null) {
              setState(() {
                _barbellWeightKg = val;
                _isRxWomen = (val == 47.6);
              });
            }
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g. 11-1 deadlift break worked cleanly',
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
              'LOG MANUAL DT SCORE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryGlance(RecoveryProvider recovery) {
    final List<DtWorkoutLog> history = recovery.getDtWorkoutHistory();
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final DtWorkoutLog latest = history.first;
    final DtWorkoutLog? pr = recovery.getDtPersonalRecord();

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
