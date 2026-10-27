import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/theme/app_theme.dart';

/// Interactive EMOM (Every Minute On the Minute) interval training card.
/// Features a 60-second rolling interval engine, work/rest state transitions,
/// round-by-round rep logging, tactile/audio countdown cues, and duration presets.
class EmomTimerCard extends StatefulWidget {
  const new({
    required this.exerciseName,
    required this.targetRepsPerMin,
    required this.activeRoundIndex,
    required this.totalRounds,
    required this.isAllCompleted,
    required this.onRoundCompleted,
    this.onTotalRoundsChanged,
    this.onTargetRepsChanged,
    this.currentWeightKg = 0.0,
    super.key,
  });

  final String exerciseName;
  final int targetRepsPerMin;
  final int activeRoundIndex;
  final int totalRounds;
  final bool isAllCompleted;
  final void Function({
    required int roundIndex,
    required int reps,
    required double weight,
  }) onRoundCompleted;
  final void Function(int newTotalRounds)? onTotalRoundsChanged;
  final void Function(int newTargetReps)? onTargetRepsChanged;
  final double currentWeightKg;

  @override
  State<EmomTimerCard> createState() => _EmomTimerCardState();
}

class _EmomTimerCardState extends State<EmomTimerCard> {
  Timer? _timer;
  int _secondsRemainingInMinute = 60;
  int _totalElapsedSeconds = 0;
  late int _currentRound;
  late int _targetReps;
  late int _totalRounds;
  bool _isRunning = false;
  bool _isWorkPhase = true;
  bool _isBeepEnabled = true;
  final Map<int, int> _loggedRoundReps = <int, int>{};

  @override
  void initState() {
    super.initState();
    _currentRound = (widget.activeRoundIndex + 1).clamp(1, widget.totalRounds);
    _targetReps = widget.targetRepsPerMin > 0 ? widget.targetRepsPerMin : 5;
    _totalRounds = widget.totalRounds > 0 ? widget.totalRounds : 20;
  }

  @override
  void didUpdateWidget(covariant EmomTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRoundIndex != widget.activeRoundIndex && !_isRunning) {
      _currentRound = (widget.activeRoundIndex + 1).clamp(1, widget.totalRounds);
    }
    if (oldWidget.totalRounds != widget.totalRounds) {
      _totalRounds = widget.totalRounds > 0 ? widget.totalRounds : 20;
    }
    if (oldWidget.targetRepsPerMin != widget.targetRepsPerMin && !_isRunning) {
      _targetReps = widget.targetRepsPerMin > 0 ? widget.targetRepsPerMin : 5;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_isBeepEnabled && _totalElapsedSeconds == 0) {
      NotificationService().playChronoPulse();
    }
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _totalElapsedSeconds++;
        if (_secondsRemainingInMinute > 1) {
          _secondsRemainingInMinute--;

          // 3-2-1 Audio & Haptic Countdown
          if (_secondsRemainingInMinute <= 3 && _secondsRemainingInMinute >= 1) {
            HapticFeedback.selectionClick();
          }
        } else {
          // Top of the minute! (00:00 rollover to next round)
          _secondsRemainingInMinute = 60;
          HapticFeedback.heavyImpact();
          if (_isBeepEnabled) {
            NotificationService().playChronoPulse();
          }

          // Complete the current round automatically if not already logged
          final int reps = _loggedRoundReps[_currentRound] ?? _targetReps;
          _loggedRoundReps[_currentRound] = reps;
          widget.onRoundCompleted(
            roundIndex: _currentRound - 1,
            reps: reps,
            weight: widget.currentWeightKg,
          );

          if (_currentRound < _totalRounds) {
            _currentRound++;
            _isWorkPhase = true;
          } else {
            // Reached end of EMOM workout!
            _stopTimer();
            _isWorkPhase = false;
          }
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _stopTimer();
    setState(() {
      _secondsRemainingInMinute = 60;
      _totalElapsedSeconds = 0;
      _currentRound = 1;
      _isWorkPhase = true;
      _loggedRoundReps.clear();
    });
  }

  void _logMinuteAndRest() {
    HapticFeedback.mediumImpact();
    final int roundIdx = _currentRound - 1;
    final int reps = _targetReps;
    _loggedRoundReps[_currentRound] = reps;
    widget.onRoundCompleted(
      roundIndex: roundIdx,
      reps: reps,
      weight: widget.currentWeightKg,
    );

    setState(() {
      _isWorkPhase = false;
    });
  }

  void _skipToNextMinute() {
    HapticFeedback.mediumImpact();
    // Complete current round if needed
    if (!_loggedRoundReps.containsKey(_currentRound)) {
      _loggedRoundReps[_currentRound] = _targetReps;
      widget.onRoundCompleted(
        roundIndex: _currentRound - 1,
        reps: _targetReps,
        weight: widget.currentWeightKg,
      );
    }

    if (_currentRound < _totalRounds) {
      setState(() {
        _currentRound++;
        _secondsRemainingInMinute = 60;
        _isWorkPhase = true;
      });
    } else {
      _stopTimer();
      setState(() {
        _isWorkPhase = false;
      });
    }
  }

  void _adjustTargetReps(int delta) {
    HapticFeedback.selectionClick();
    final int newReps = (_targetReps + delta).clamp(1, 50);
    setState(() {
      _targetReps = newReps;
    });
    widget.onTargetRepsChanged?.call(newReps);
  }

  void _setDurationPreset(int minutes) {
    HapticFeedback.selectionClick();
    if (_isRunning) return;
    setState(() {
      _totalRounds = minutes;
      if (_currentRound > _totalRounds) {
        _currentRound = _totalRounds;
      }
    });
    widget.onTotalRoundsChanged?.call(minutes);
  }

  String _formatTime(int totalSecs) {
    final int m = totalSecs ~/ 60;
    final int s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalLoggedReps {
    return _loggedRoundReps.values.fold(0, (sum, r) => sum + r);
  }

  @override
  Widget build(BuildContext context) {
    const Color emomAmber = Color(0xFFFF9100);
    final double minuteProgress =
        (60 - _secondsRemainingInMinute) / 60;
    final int completedRoundsCount = _loggedRoundReps.length;
    final bool isSessionComplete =
        widget.isAllCompleted || completedRoundsCount >= _totalRounds;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRunning
              ? emomAmber.withValues(alpha: 0.7)
              : (isSessionComplete
                  ? AppTheme.accentElectricCyan.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.10)),
          width: _isRunning ? 1.8 : 1.0,
        ),
        boxShadow: _isRunning
            ? <BoxShadow>[
                BoxShadow(
                  color: emomAmber.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header Row: EMOM Title + Beep Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: emomAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: emomAmber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EMOM INTERVAL TIMER',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: emomAmber,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Beep Toggle Pill
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isBeepEnabled = !_isBeepEnabled;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isBeepEnabled
                            ? emomAmber.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isBeepEnabled
                              ? emomAmber.withValues(alpha: 0.5)
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _isBeepEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 12,
                            color: _isBeepEnabled
                                ? emomAmber
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isBeepEnabled ? 'BEEP ON' : 'MUTED',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isBeepEnabled
                                  ? emomAmber
                                  : AppTheme.textSecondary,
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

          // Central Display: Minute Countdown, Round Counter, Work/Rest Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    // Minute / Round Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'ROUND $_currentRound OF $_totalRounds',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(_secondsRemainingInMinute),
                          style: GoogleFonts.outfit(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _secondsRemainingInMinute <= 3 && _isRunning
                                ? Colors.redAccent
                                : (_isWorkPhase ? emomAmber : AppTheme.secondaryCyan),
                          ),
                        ),
                      ],
                    ),

                    // Work / Rest Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isWorkPhase
                                ? emomAmber.withValues(alpha: 0.18)
                                : AppTheme.secondaryCyan.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isWorkPhase
                                  ? emomAmber
                                  : AppTheme.secondaryCyan,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                _isWorkPhase
                                    ? Icons.bolt_rounded
                                    : Icons.nightlife_rounded,
                                size: 14,
                                color: _isWorkPhase
                                    ? emomAmber
                                    : AppTheme.secondaryCyan,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isWorkPhase ? 'WORK' : 'REST',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: _isWorkPhase
                                      ? emomAmber
                                      : AppTheme.secondaryCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isWorkPhase
                              ? 'Perform $_targetReps reps'
                              : 'Resting for ${_secondsRemainingInMinute}s',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 60-Second Linear Interval Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: minuteProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isWorkPhase ? emomAmber : AppTheme.secondaryCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Target Reps Stepper + Duration Presets Row
          Row(
            children: <Widget>[
              // Target Reps Adjuster
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Reps: $_targetReps',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _adjustTargetReps(-1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _adjustTargetReps(1),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 13,
                          color: emomAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Duration Preset Chips (10m, 15m, 20m, 30m)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <int>[10, 15, 20, 25, 30].map((m) {
                      final bool isSelected = _totalRounds == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _setDurationPreset(m),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? emomAmber.withValues(alpha: 0.20)
                                  : AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? emomAmber
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              '${m}m',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? emomAmber
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Primary Action Buttons Row
          Row(
            children: <Widget>[
              // Start / Pause Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(
                    _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isRunning ? 'PAUSE' : 'START EMOM',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.amber[800] : emomAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Done with Reps (Rest) Button
              if (_isRunning && _isWorkPhase) ...<Widget>[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _logMinuteAndRest,
                    icon: const Icon(Icons.check_circle_outline, size: 17),
                    label: Text(
                      'REST NOW',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Next Minute Button
              if (_isRunning) ...<Widget>[
                InkWell(
                  onTap: _skipToNextMinute,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Icon(
                      Icons.skip_next_rounded,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Reset Button
              InkWell(
                onTap: _resetTimer,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Footer Stats: Elapsed Time + Total Reps Done
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Elapsed: ${_formatTime(_totalElapsedSeconds)} • Total: ${_formatTime(_totalRounds * 60)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Total Volume: $_totalLoggedReps reps',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: emomAmber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
