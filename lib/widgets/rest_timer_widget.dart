import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class RestTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onFinished;
  final FocusNode? notesFocusNode;

  const RestTimerWidget({
    super.key,
    this.initialSeconds = 120, // Default 2 min rest for Olympic lifting
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
          _triggerFinishAlerts();
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

  void _startTimer() {
    _timer?.cancel();
    _targetEndTime = DateTime.now().add(Duration(seconds: _secondsRemaining));
    setState(() => _isRunning = true);

    NotificationService().scheduleTimerNotification(
      secondsRemaining: _secondsRemaining,
      title: '⏰ Rest Timer Expired!',
      body: 'Time for your next set! Keep pushing.',
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
        _triggerFinishAlerts();
        if (widget.onFinished != null) {
          widget.onFinished!();
        }
      }
    });
  }

  void _triggerFinishAlerts() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    NotificationService().cancelTimerNotification();

    if (settings.hapticsEnabled) {
      NotificationService().triggerIntenseVibration();
    }

    if (settings.soundAlertsEnabled) {
      NotificationService().playTimerBeepSound();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Rest Timer Expired! Ready for your next set.'),
          backgroundColor: AppTheme.primaryAmber,
          duration: Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0.0;

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
          firstChild: _buildExpandedView(progress),
          secondChild: _buildCollapsedBar(progress),
        ),
      ),
    );
  }

  Widget _buildExpandedView(double progress) {
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
                const Icon(Icons.timer_outlined, color: AppTheme.primaryAmber, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Rest Timer',
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
                    color: AppTheme.primaryAmber,
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
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
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
              _buildAdjustmentChip('-10s', -10),
              const SizedBox(width: 8),
              _buildAdjustmentChip('-5s', -5),
              const SizedBox(width: 8),
              _buildAdjustmentChip('-1s', -1),
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppTheme.borderColor,
              ),
              _buildAdjustmentChip('+1s', 1),
              const SizedBox(width: 8),
              _buildAdjustmentChip('+5s', 5),
              const SizedBox(width: 8),
              _buildAdjustmentChip('+10s', 10),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Preset Duration Selectors (30s, 60s, 90s, 2m, 3m, 5m)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetChip('30s', 30),
              const SizedBox(width: 8),
              _buildPresetChip('60s', 60),
              const SizedBox(width: 8),
              _buildPresetChip('90s', 90),
              const SizedBox(width: 8),
              _buildPresetChip('2m', 120),
              const SizedBox(width: 8),
              _buildPresetChip('3m', 180),
              const SizedBox(width: 8),
              _buildPresetChip('5m', 300),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedBar(double progress) {
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
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formattedTime,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunning ? 'RESTING' : 'PAUSED',
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
                    color: AppTheme.primaryAmber,
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

  Widget _buildAdjustmentChip(String label, int deltaSeconds) {
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
                ? AppTheme.primaryAmber.withValues(alpha: 0.4)
                : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: deltaSeconds > 0 ? AppTheme.primaryAmber : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int seconds) {
    final isSelected = _totalSeconds == seconds;
    return InkWell(
      onTap: () => _setDuration(seconds),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAmber : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
