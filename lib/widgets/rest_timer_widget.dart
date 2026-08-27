import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class RestTimerWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final int initialSeconds;
  final List<int>? presetSeconds;
  final Color? primaryColor;
  final bool isEmbedded;
  final String notificationTitle;
  final String notificationBody;
  final VoidCallback? onFinished;
  final FocusNode? notesFocusNode;

  const RestTimerWidget({
    super.key,
    this.title = 'Rest Timer',
    this.icon = Icons.timer_outlined,
    this.initialSeconds = 120, // Default 2 min rest for Olympic lifting
    this.presetSeconds,
    this.primaryColor,
    this.isEmbedded = false,
    this.notificationTitle = '⏰ Rest Timer Expired!',
    this.notificationBody = 'Time for your next set! Keep pushing.',
    this.onFinished,
    this.notesFocusNode,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> with WidgetsBindingObserver {
  Timer? _timer;
  late int _totalSeconds;
  late int _secondsRemaining;
  DateTime? _targetEndTime;
  bool _isRunning = false;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = widget.initialSeconds;
    _secondsRemaining = widget.initialSeconds;
    widget.notesFocusNode?.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant RestTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSeconds != widget.initialSeconds && !_isRunning) {
      _totalSeconds = widget.initialSeconds;
      _secondsRemaining = widget.initialSeconds;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.notesFocusNode?.removeListener(_handleFocusChange);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning && _targetEndTime != null) {
      final diff = _targetEndTime!.difference(DateTime.now()).inSeconds;
      setState(() {
        if (diff > 0) {
          _secondsRemaining = diff;
        } else {
          _secondsRemaining = 0;
          _isRunning = false;
          _timer?.cancel();
          _triggerFinishAlerts(isForeground: false);
          if (widget.onFinished != null) {
            widget.onFinished!();
          }
        }
      });
    }
  }

  void _handleFocusChange() {
    if (widget.notesFocusNode?.hasFocus == true && !_isMinimized) {
      setState(() {
        _isMinimized = true;
      });
    }
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      NotificationService().cancelTimerNotification();
      setState(() => _isRunning = false);
    } else {
      if (_secondsRemaining <= 0) {
        _secondsRemaining = _totalSeconds;
      }
      _startTimer();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    NotificationService().cancelTimerNotification();
    setState(() {
      _secondsRemaining = _totalSeconds;
      _isRunning = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _targetEndTime = DateTime.now().add(Duration(seconds: _secondsRemaining));
    setState(() => _isRunning = true);

    NotificationService().scheduleTimerNotification(
      secondsRemaining: _secondsRemaining,
      title: widget.notificationTitle,
      body: widget.notificationBody,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_targetEndTime == null) return;
      final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;

      if (remaining > 0) {
        setState(() => _secondsRemaining = remaining);
      } else {
        t.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        _triggerFinishAlerts(isForeground: true);
        if (widget.onFinished != null) {
          widget.onFinished!();
        }
      }
    });
  }

  void _triggerFinishAlerts({bool isForeground = true}) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    NotificationService().cancelTimerNotification();

    if (isForeground) {
      if (settings.hapticsEnabled) {
        NotificationService().triggerIntenseVibration();
      }

      if (settings.soundAlertsEnabled) {
        NotificationService().playTimerBeepSound();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.notificationTitle} Finished!'),
          backgroundColor: widget.primaryColor ?? AppTheme.primaryAmber,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _adjustTime(int deltaSeconds) {
    setState(() {
      final updated = _secondsRemaining + deltaSeconds;
      _secondsRemaining = updated < 0 ? 0 : updated;
      if (_secondsRemaining > _totalSeconds) {
        _totalSeconds = _secondsRemaining;
      }
      if (_isRunning) {
        _startTimer();
      }
    });
  }

  void _setDuration(int seconds) {
    _timer?.cancel();
    NotificationService().cancelTimerNotification();
    setState(() {
      _totalSeconds = seconds;
      _secondsRemaining = seconds;
      _isRunning = false;
    });
  }

  String get _formattedTime {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDurationLabel(int seconds) {
    if (seconds >= 60 && seconds % 60 == 0) {
      return '${seconds ~/ 60}m';
    } else if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m}m${s}s';
    } else {
      return '${seconds}s';
    }
  }

  List<int> get _presetDurations {
    if (widget.presetSeconds != null && widget.presetSeconds!.isNotEmpty) {
      return widget.presetSeconds!;
    }
    // Default preset options
    return [30, 60, 90, 120, 180, 300];
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.primaryColor ?? AppTheme.primaryAmber;
    final progress = _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0.0;

    if (widget.isEmbedded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Embedded Header with Title & Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: themeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Central Circular Progress Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 106,
                  height: 106,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.surfaceCard,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formattedTime,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _isRunning ? 'ACTIVE' : 'PAUSED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isRunning ? themeColor : AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Big Start / Pause CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.orangeAccent : themeColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isRunning ? 'PAUSE TIMER' : 'START TIMER',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Micro Adjustment Steppers
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAdjustmentChip('-10s', -10, themeColor),
                  const SizedBox(width: 6),
                  _buildAdjustmentChip('-5s', -5, themeColor),
                  const SizedBox(width: 6),
                  _buildAdjustmentChip('-1s', -1, themeColor),
                  Container(
                    height: 20,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppTheme.borderColor,
                  ),
                  _buildAdjustmentChip('+1s', 1, themeColor),
                  const SizedBox(width: 6),
                  _buildAdjustmentChip('+5s', 5, themeColor),
                  const SizedBox(width: 6),
                  _buildAdjustmentChip('+10s', 10, themeColor),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Duration Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _presetDurations.map((dur) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildPresetChip(_formatDurationLabel(dur), dur, themeColor),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 200) {
            // Dragged down -> Minimize
            setState(() => _isMinimized = true);
          } else if (details.primaryVelocity! < -200) {
            // Dragged up -> Expand
            setState(() => _isMinimized = false);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isMinimized
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildExpandedView(progress, themeColor),
          secondChild: _buildCollapsedBar(progress, themeColor),
        ),
      ),
    );
  }

  Widget _buildExpandedView(double progress, Color themeColor) {
    return Column(
      key: const ValueKey('expanded'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag Handle Pill
        GestureDetector(
          onTap: () => setState(() => _isMinimized = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: themeColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: themeColor,
                    size: 34,
                  ),
                  onPressed: _toggleTimer,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary, size: 26),
                  tooltip: 'Minimize Timer Bar',
                  onPressed: () => setState(() => _isMinimized = true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Central Circular Progress Timer Readout
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 106,
              height: 106,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
            Text(
              _formattedTime,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Horizontal Quick Adjustment Buttons (-10s -5s -1s | +1s +5s +10s)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAdjustmentChip('-10s', -10, themeColor),
              const SizedBox(width: 8),
              _buildAdjustmentChip('-5s', -5, themeColor),
              const SizedBox(width: 8),
              _buildAdjustmentChip('-1s', -1, themeColor),
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppTheme.borderColor,
              ),
              _buildAdjustmentChip('+1s', 1, themeColor),
              const SizedBox(width: 8),
              _buildAdjustmentChip('+5s', 5, themeColor),
              const SizedBox(width: 8),
              _buildAdjustmentChip('+10s', 10, themeColor),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Preset Duration Selectors
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _presetDurations.map((dur) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildPresetChip(_formatDurationLabel(dur), dur, themeColor),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedBar(double progress, Color themeColor) {
    return GestureDetector(
      key: const ValueKey('collapsed'),
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        height: 48,
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Timer Icon + Time Readout + Mini Progress Indicator
            Row(
              children: [
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formattedTime,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunning ? 'ACTIVE' : 'PAUSED',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),

            // Right: Play/Pause button + Expand Chevron
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: themeColor,
                    size: 24,
                  ),
                  onPressed: _toggleTimer,
                ),
                const Icon(
                  Icons.keyboard_arrow_up,
                  color: AppTheme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentChip(String label, int deltaSeconds, Color themeColor) {
    return InkWell(
      onTap: () => _adjustTime(deltaSeconds),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: deltaSeconds > 0
                ? themeColor.withValues(alpha: 0.4)
                : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: deltaSeconds > 0 ? themeColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int seconds, Color themeColor) {
    final isSelected = _totalSeconds == seconds;
    return InkWell(
      onTap: () => _setDuration(seconds),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? themeColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
