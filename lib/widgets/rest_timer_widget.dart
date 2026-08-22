import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
          if (widget.onFinished != null) {
            widget.onFinished!();
          }
        }
      });
    }
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
                icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: AppTheme.primaryAmber, size: 28),
                onPressed: _toggleTimer,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Circular progress timer indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
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
          const SizedBox(height: 16),

          // Preset duration selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetChip('60s', 60),
              _buildPresetChip('90s', 90),
              _buildPresetChip('2m', 120),
              _buildPresetChip('3m', 180),
              _buildPresetChip('5m', 300),
            ],
          ),
        ],
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
