import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/theme/app_theme.dart';

class HoldStopwatchCard extends StatefulWidget {
  const new({
    required this.exerciseName,
    required this.targetSeconds,
    required this.activeSetIndex,
    required this.totalSets,
    required this.isAllCompleted,
    required this.onCompleteHold,
    this.onTargetSecondsChanged,
    super.key,
  });

  final String exerciseName;
  final int targetSeconds;
  final int activeSetIndex;
  final int totalSets;
  final bool isAllCompleted;
  final void Function({required int setIndex, required int elapsedSeconds})
  onCompleteHold;
  final void Function(int newSeconds)? onTargetSecondsChanged;

  @override
  State<HoldStopwatchCard> createState() => _HoldStopwatchCardState();
}

class _HoldStopwatchCardState extends State<HoldStopwatchCard> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  late int _targetSeconds;
  bool _isRunning = false;
  bool _isCountdown = true;

  @override
  void initState() {
    super.initState();
    _targetSeconds = widget.targetSeconds > 0 ? widget.targetSeconds : 30;
  }

  @override
  void didUpdateWidget(covariant HoldStopwatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSetIndex != widget.activeSetIndex) {
      _stopTimer();
      _elapsedSeconds = 0;
    }
    if (oldWidget.targetSeconds != widget.targetSeconds && !_isRunning) {
      _targetSeconds = widget.targetSeconds > 0 ? widget.targetSeconds : 30;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_isCountdown && _elapsedSeconds >= _targetSeconds) {
          HapticFeedback.heavyImpact();
          // Keep ticking or pause when finished
          _stopTimer();
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
    HapticFeedback.selectionClick();
    _stopTimer();
    setState(() {
      _elapsedSeconds = 0;
    });
  }

  void _adjustTarget(int delta) {
    HapticFeedback.selectionClick();
    final int newTarget = (_targetSeconds + delta).clamp(5, 900);
    setState(() {
      _targetSeconds = newTarget;
    });
    widget.onTargetSecondsChanged?.call(newTarget);
  }

  void _showCustomDurationDialog() {
    final TextEditingController textCtrl = TextEditingController(
      text: '$_targetSeconds',
    );
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text(
            'Target Hold Duration',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: textCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryCyan,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Duration (Seconds)',
                  suffixText: 'sec',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <int>[15, 20, 30, 45, 60, 90, 120].map((s) {
                  return ActionChip(
                    label: Text('${s}s'),
                    onPressed: () {
                      textCtrl.text = '$s';
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAmber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final int? parsed = int.tryParse(textCtrl.text.trim());
                if (parsed != null && parsed > 0) {
                  setState(() {
                    _targetSeconds = parsed;
                  });
                  widget.onTargetSecondsChanged?.call(parsed);
                }
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();
    final int recordedSeconds = _elapsedSeconds > 0
        ? _elapsedSeconds
        : _targetSeconds;
    _stopTimer();
    _elapsedSeconds = 0;
    widget.onCompleteHold(
      setIndex: widget.activeSetIndex,
      elapsedSeconds: recordedSeconds,
    );
  }

  String _formatTime(int totalSeconds) {
    final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final int minutes = safeSeconds ~/ 60;
    final int seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final int displaySeconds = _isCountdown
        ? (_targetSeconds - _elapsedSeconds)
        : _elapsedSeconds;
    final double progress = _targetSeconds > 0
        ? (_elapsedSeconds / _targetSeconds).clamp(0.0, 1.0)
        : 0.0;
    final bool isTargetReached = _elapsedSeconds >= _targetSeconds && _targetSeconds > 0;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRunning
              ? AppTheme.secondaryCyan.withValues(alpha: 0.6)
              : (isTargetReached
                  ? AppTheme.primaryAmber.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08)),
          width: _isRunning ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header Row: Hold Mode badge + Set indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: _isRunning
                        ? AppTheme.secondaryCyan
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'HOLD STOPWATCH',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: _isRunning
                          ? AppTheme.secondaryCyan
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Mode toggle (Countdown vs Stopwatch)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCountdown = !_isCountdown;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        _isCountdown ? 'COUNTDOWN' : 'STOPWATCH',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Set indicator badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isAllCompleted
                          ? Colors.green.withValues(alpha: 0.2)
                          : AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isAllCompleted
                            ? Colors.green
                            : AppTheme.primaryAmber,
                      ),
                    ),
                    child: Text(
                      widget.isAllCompleted
                          ? 'ALL SETS DONE'
                          : 'SET ${widget.activeSetIndex + 1} OF ${widget.totalSets}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.isAllCompleted
                            ? Colors.green
                            : AppTheme.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Central Time Display + Target Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Digital timer display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _formatTime(displaySeconds),
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isTargetReached
                          ? AppTheme.primaryAmber
                          : (_isRunning
                              ? AppTheme.secondaryCyan
                              : AppTheme.textPrimary),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        'Target: ${_targetSeconds}s hold',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: _showCustomDurationDialog,
                        child: const Icon(
                          Icons.edit,
                          size: 13,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Quick Stepper Chips: -5s, +5s, +10s
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    backgroundColor: AppTheme.surfaceCard,
                    side: const BorderSide(color: AppTheme.borderColor),
                    label: Text(
                      '-5s',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    onPressed: () => _adjustTarget(-5),
                  ),
                  const SizedBox(width: 4),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    backgroundColor: AppTheme.surfaceCard,
                    side: const BorderSide(color: AppTheme.borderColor),
                    label: Text(
                      '+5s',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                    onPressed: () => _adjustTarget(5),
                  ),
                  const SizedBox(width: 4),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    backgroundColor: AppTheme.surfaceCard,
                    side: const BorderSide(color: AppTheme.borderColor),
                    label: Text(
                      '+10s',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                    onPressed: () => _adjustTarget(10),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isTargetReached ? AppTheme.primaryAmber : AppTheme.secondaryCyan,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action Controls: Play/Pause, Reset, Complete Set
          Row(
            children: <Widget>[
              // Start / Pause
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Colors.amber.shade800
                        : AppTheme.secondaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _isRunning
                        ? 'PAUSE'
                        : (_elapsedSeconds > 0 ? 'RESUME' : 'START HOLD'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _toggleTimer,
                ),
              ),
              const SizedBox(width: 6),

              // Reset
              if (_elapsedSeconds > 0 || _isRunning) ...<Widget>[
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceCard,
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Reset Timer',
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 6),
              ],

              // Complete Set Button
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTargetReached
                        ? AppTheme.primaryAmber
                        : AppTheme.surfaceCard,
                    foregroundColor: isTargetReached
                        ? Colors.black
                        : AppTheme.textPrimary,
                    side: BorderSide(
                      color: isTargetReached
                          ? AppTheme.primaryAmber
                          : AppTheme.borderColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: isTargetReached ? Colors.black : AppTheme.primaryAmber,
                  ),
                  label: Text(
                    widget.isAllCompleted
                        ? 'LOG EXTRA SET'
                        : 'COMPLETE (${_elapsedSeconds > 0 ? _elapsedSeconds : _targetSeconds}s)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _completeSet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
