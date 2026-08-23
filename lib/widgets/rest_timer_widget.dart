import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class RestTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onFinished;

  const RestTimerWidget({
    super.key,
    this.initialSeconds = 120, // Default 2 min rest for Olympic lifting
    this.onFinished,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  Timer? _timer;
  late int _totalSeconds;
  late int _secondsRemaining;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _secondsRemaining = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_secondsRemaining <= 0) {
        _secondsRemaining = _totalSeconds;
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsRemaining > 1) {
          setState(() => _secondsRemaining--);
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
  }

  void _triggerFinishAlerts() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (settings.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }

    if (settings.soundAlertsEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Rest Timer Expired! Ready for your next set.'),
          backgroundColor: AppTheme.primaryAmber,
          duration: Duration(seconds: 3),
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
    });
  }

  void _setDuration(int seconds) {
    _timer?.cancel();
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
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
              IconButton(
                icon: Icon(
                  _isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: AppTheme.primaryAmber,
                  size: 36,
                ),
                onPressed: _toggleTimer,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Central Circular Progress Timer Readout
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
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
          const SizedBox(height: 18),

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
          const SizedBox(height: 16),

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
