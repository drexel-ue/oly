import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/grip_hang_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class HangSessionBlockWidget extends StatefulWidget {
  const new({
    super.key,
    this.onCompleted,
    this.isEmbeddedInWorkout = false,
  });

  final VoidCallback? onCompleted;
  final bool isEmbeddedInWorkout;

  @override
  State<HangSessionBlockWidget> createState() => _HangSessionBlockWidgetState();
}

class _HangSessionBlockWidgetState extends State<HangSessionBlockWidget> {
  HangMode _selectedMode = HangMode.twoHand;
  HangStyle _selectedStyle = HangStyle.activeScapular;

  @override
  void dispose() {
    try {
      final ActiveSessionProvider activeSession =
          Provider.of<ActiveSessionProvider>(context, listen: false);
      if (!activeSession.isMinimized) {
        final GripHangProvider grip =
            Provider.of<GripHangProvider>(context, listen: false);
        if (grip.isHangTimerRunning) {
          grip.stopHangTimer();
        }
      }
    } catch (_) {}
    super.dispose();
  }

  void _startHang(
    GripHangProvider grip,
    ActiveSessionProvider? activeSession,
    int targetSeconds,
  ) {
    HapticFeedback.heavyImpact();
    grip.startHangTimer(
      mode: _selectedMode,
      style: _selectedStyle,
      onTick: (secs) {
        activeSession?.updateHangProgress(
          modeLabel: _selectedMode.displayName,
          durationSeconds: secs,
          targetSeconds: targetSeconds,
        );
      },
    );

    activeSession?.registerEndSessionCallback(grip.resetHangTimer);

    if (widget.isEmbeddedInWorkout ||
        activeSession?.sessionType == SessionType.workout) {
      activeSession?.updateHangProgress(
        modeLabel: _selectedMode.displayName,
        durationSeconds: 0,
        targetSeconds: targetSeconds,
      );
    } else {
      activeSession?.startSession(
        sessionTitle: _selectedMode.displayName,
        sessionType: SessionType.hang,
        currentExercise: _selectedMode.displayName,
        currentSetInfo: '00:00 / ${_formatSeconds(targetSeconds)}',
      );
    }
  }

  Future<void> _stopHang(
    GripHangProvider grip,
    ActiveSessionProvider? activeSession,
  ) async {
    await HapticFeedback.heavyImpact();
    final int duration = grip.stopHangTimer();
    activeSession?.unregisterEndSessionCallback(grip.resetHangTimer);

    if (!widget.isEmbeddedInWorkout &&
        activeSession?.sessionType == SessionType.hang) {
      activeSession?.endSession();
    } else {
      activeSession?.updateExercise(
        currentExercise: '',
        currentSetInfo: '',
      );
    }

    if (duration > 0) {
      await grip.recordHangSession(
        mode: _selectedMode,
        style: _selectedStyle,
        durationSeconds: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hold logged: ${_formatSeconds(duration)} (${_selectedMode.displayName})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      widget.onCompleted?.call();
    }
  }

  void _resetHang(
    GripHangProvider grip,
    ActiveSessionProvider? activeSession,
  ) {
    grip.resetHangTimer();
    activeSession?.unregisterEndSessionCallback(grip.resetHangTimer);
    if (!widget.isEmbeddedInWorkout &&
        activeSession?.sessionType == SessionType.hang) {
      activeSession?.endSession();
    } else {
      activeSession?.updateExercise(
        currentExercise: '',
        currentSetInfo: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GripHangProvider grip = Provider.of<GripHangProvider>(context);
    ActiveSessionProvider? activeSession;
    try {
      activeSession = Provider.of<ActiveSessionProvider>(context, listen: false);
    } catch (_) {}

    final bool isRunning = grip.isHangTimerRunning;
    final int currentSeconds = grip.currentHangSeconds;
    final int targetSeconds = _selectedMode.standardGoalSeconds;
    final double progress =
        targetSeconds > 0 ? (currentSeconds / targetSeconds).clamp(0, 1) : 0;

    final int minutes = currentSeconds ~/ 60;
    final int seconds = currentSeconds % 60;
    final String formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final int bestForMode = _selectedMode == HangMode.twoHand
        ? grip.bestTwoHandSeconds
        : (_selectedMode == HangMode.singleHandLeft
            ? grip.bestLeftHandSeconds
            : grip.bestRightHandSeconds);

    final bool isNewPr = isRunning && currentSeconds > bestForMode && bestForMode > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRunning
              ? AppTheme.primaryAmber
              : Colors.white.withValues(alpha: 0.08),
          width: isRunning ? 2.0 : 1.0,
        ),
        boxShadow: isRunning
            ? <BoxShadow>[
                BoxShadow(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.accessibility_new,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ACTIVE HANG PROTOCOL',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                      Text(
                        'Target Goal: ${_formatSeconds(targetSeconds)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bestForMode > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.emoji_events_outlined,
                          size: 14, color: AppTheme.primaryAmber),
                      const SizedBox(width: 4),
                      Text(
                        'PR: ${_formatSeconds(bestForMode)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Hang Mode Selector Tabs (Two-Hand vs Left vs Right)
          if (!isRunning)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  _buildModeTab(
                    title: 'Both Hands (5m)',
                    mode: HangMode.twoHand,
                  ),
                  _buildModeTab(
                    title: 'Left Arm (2m)',
                    mode: HangMode.singleHandLeft,
                  ),
                  _buildModeTab(
                    title: 'Right Arm (2m)',
                    mode: HangMode.singleHandRight,
                  ),
                ],
              ),
            ),
          if (!isRunning) const SizedBox(height: 12),

          // Scapular Style Toggle
          if (!isRunning)
            Row(
              children: <Widget>[
                Text(
                  'Style: ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Active Scapular',
                      style: GoogleFonts.outfit(fontSize: 11)),
                  selected: _selectedStyle == HangStyle.activeScapular,
                  selectedColor: AppTheme.primaryAmber,
                  labelStyle: TextStyle(
                    color: _selectedStyle == HangStyle.activeScapular
                        ? Colors.black
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (sel) {
                    if (sel) {
                      setState(
                          () => _selectedStyle = HangStyle.activeScapular);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Passive Decompress',
                      style: GoogleFonts.outfit(fontSize: 11)),
                  selected: _selectedStyle == HangStyle.passiveDecompression,
                  selectedColor: AppTheme.secondaryCyan,
                  labelStyle: TextStyle(
                    color: _selectedStyle == HangStyle.passiveDecompression
                        ? Colors.black
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (sel) {
                    if (sel) {
                      setState(
                          () => _selectedStyle = HangStyle.passiveDecompression);
                    }
                  },
                ),
              ],
            ),
          const SizedBox(height: 16),

          // PR Alert Banner
          if (isNewPr)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryAmber),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.star, color: AppTheme.primaryAmber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'NEW PERSONAL RECORD! Keep holding!',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ],
              ),
            ),

          // Stopwatch Display
          Center(
            child: Column(
              children: <Widget>[
                Text(
                  formattedTime,
                  style: GoogleFonts.outfit(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isRunning
                        ? (isNewPr ? AppTheme.primaryAmber : Colors.white)
                        : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}% of ${_selectedMode.displayName} Goal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? AppTheme.successGreen
                          : AppTheme.primaryAmber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Milestone Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <int>[30, 60, 120, 180, 240, 300].map((sec) {
              final bool reached = currentSeconds >= sec;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: reached
                      ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: reached ? AppTheme.primaryAmber : Colors.white10,
                  ),
                ),
                child: Text(
                  sec >= 60 ? '${sec ~/ 60}m' : '${sec}s',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight:
                        reached ? FontWeight.bold : FontWeight.w500,
                    color: reached
                        ? AppTheme.primaryAmber
                        : AppTheme.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Control Buttons
          Row(
            children: <Widget>[
              if (!isRunning) ...<Widget>[
                Expanded(
                  child: OlyPressable(
                    onPressed: () => _startHang(grip, activeSession, targetSeconds),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[AppTheme.primaryAmber, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.play_arrow,
                                color: Colors.black, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'START HANG TIMER',
                              style: GoogleFonts.outfit(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...<Widget>[
                Expanded(
                  child: OlyPressable(
                    onPressed: () => _stopHang(grip, activeSession),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.stop,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'STOP & RECORD HOLD',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                  tooltip: 'Reset Timer',
                  onPressed: () => _resetHang(grip, activeSession),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({required String title, required HangMode mode}) {
    final bool isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryAmber : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    if (s == 0) return '$m:00';
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
