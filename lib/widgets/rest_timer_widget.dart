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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppTheme.primaryAmber),
                  const SizedBox(width: 8),
                  Text(
                    'Rest Timer',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
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
                  size: 28,
                ),
                onPressed: _toggleTimer,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Timer Row with -10/-5/-1s on left and +1/+5/+10s on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Left side decrease buttons
              Column(
                children: [
                  _buildAdjustmentChip('-10s', -10),
                  const SizedBox(height: 6),
                  _buildAdjustmentChip('-5s', -5),
                  const SizedBox(height: 6),
                  _buildAdjustmentChip('-1s', -1),
                ],
              ),

              // Center circular timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              // Right side increase buttons
              Column(
                children: [
                  _buildAdjustmentChip('+10s', 10),
                  const SizedBox(height: 6),
                  _buildAdjustmentChip('+5s', 5),
                  const SizedBox(height: 6),
                  _buildAdjustmentChip('+1s', 1),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset duration selectors
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPresetChip('30s', 30),
                const SizedBox(width: 6),
                _buildPresetChip('60s', 60),
                const SizedBox(width: 6),
                _buildPresetChip('90s', 90),
                const SizedBox(width: 6),
                _buildPresetChip('2m', 120),
                const SizedBox(width: 6),
                _buildPresetChip('3m', 180),
                const SizedBox(width: 6),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAmber : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
