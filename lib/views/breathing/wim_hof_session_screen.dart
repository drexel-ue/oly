import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/wim_hof_summary_screen.dart';
import 'package:provider/provider.dart';

enum SessionPhase { prep, hyperventilation, retention, recovery }

class WimHofSessionScreen extends StatefulWidget {
  const WimHofSessionScreen({required this.config, super.key});
  final WimHofConfig config;

  @override
  State<WimHofSessionScreen> createState() => _WimHofSessionScreenState();
}

class _WimHofSessionScreenState extends State<WimHofSessionScreen>
    with TickerProviderStateMixin {
  int _currentRound = 1;
  int _currentBreath = 1;
  SessionPhase _phase = SessionPhase.prep;
  bool _isPaused = false;

  // Prep Countdown
  int _prepSecondsRemaining = 3;
  Timer? _prepTimer;

  // Hyperventilation Animation
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  bool _isInhaling = true;

  // Retention Stopwatch
  int _retentionSeconds = 0;
  Timer? _retentionTimer;

  // Recovery Countdown
  int _recoverySecondsRemaining = 15;
  Timer? _recoveryTimer;

  // Logged completed rounds
  final List<BreathingRoundLog> _completedRounds = <BreathingRoundLog>[];

  @override
  void initState() {
    super.initState();
    _initAnimationController();
    _startPrep();
  }

  void _initAnimationController() {
    final double cycleSeconds = widget.config.cycleDurationSeconds;
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (cycleSeconds * 1000).round()),
    );

    _breathAnimation = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOutSine,
    );

    _breathController.addStatusListener((AnimationStatus status) {
      if (!mounted || _isPaused || _phase != SessionPhase.hyperventilation) {
        return;
      }

      if (status == AnimationStatus.completed) {
        // Switch to exhale
        setState(() => _isInhaling = false);
        _breathController.reverse();
        if (widget.config.hapticsEnabled) {
          HapticFeedback.lightImpact();
        }
      } else if (status == AnimationStatus.dismissed) {
        // Completed 1 full cycle
        if (_currentBreath >= widget.config.breathsPerRound) {
          _transitionToRetention();
        } else {
          setState(() {
            _currentBreath++;
            _isInhaling = true;
          });
          if (widget.config.hapticsEnabled) {
            HapticFeedback.mediumImpact();
          }
          _breathController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _retentionTimer?.cancel();
    _recoveryTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  // --- PHASE TRANSITIONS ---

  void _startPrep() {
    setState(() {
      _phase = SessionPhase.prep;
      _prepSecondsRemaining = 3;
    });

    _prepTimer?.cancel();
    _prepTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _isPaused) return;

      if (_prepSecondsRemaining > 1) {
        setState(() => _prepSecondsRemaining--);
        if (widget.config.hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
      } else {
        timer.cancel();
        _startHyperventilation();
      }
    });
  }

  void _startHyperventilation() {
    setState(() {
      _phase = SessionPhase.hyperventilation;
      _currentBreath = 1;
      _isInhaling = true;
    });

    if (widget.config.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (widget.config.soundEnabled) {
      NotificationService().playTimerBeepSound();
    }

    _breathController.reset();
    _breathController.forward();
  }

  void _transitionToRetention() {
    _breathController.stop();
    setState(() {
      _phase = SessionPhase.retention;
      _retentionSeconds = 0;
    });

    if (widget.config.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (widget.config.soundEnabled) {
      NotificationService().playTimerBeepSound();
    }

    _retentionTimer?.cancel();
    _retentionTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _isPaused) return;
      setState(() => _retentionSeconds++);
    });
  }

  void _endRetentionAndStartRecovery() {
    _retentionTimer?.cancel();
    final int finalRetention = _retentionSeconds;

    setState(() {
      _phase = SessionPhase.recovery;
      _recoverySecondsRemaining = 15;
    });

    if (widget.config.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (widget.config.soundEnabled) {
      NotificationService().playTimerBeepSound();
    }

    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _isPaused) return;

      if (_recoverySecondsRemaining > 1) {
        setState(() => _recoverySecondsRemaining--);
        if (_recoverySecondsRemaining <= 3 && widget.config.hapticsEnabled) {
          HapticFeedback.mediumImpact();
        }
      } else {
        timer.cancel();
        _onRoundCompleted(finalRetention);
      }
    });
  }

  void _onRoundCompleted(int retentionDuration) {
    final BreathingRoundLog roundLog = BreathingRoundLog(
      roundNumber: _currentRound,
      breathsCount: widget.config.breathsPerRound,
      retentionSeconds: retentionDuration,
      recoverySeconds: 15,
    );

    _completedRounds.add(roundLog);

    if (_currentRound < widget.config.defaultRounds) {
      setState(() {
        _currentRound++;
      });
      _startPrep();
    } else {
      _finishEntireSession();
    }
  }

  void _finishEntireSession() {
    if (widget.config.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (widget.config.soundEnabled) {
      NotificationService().playTimerBeepSound();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WimHofSummaryScreen(
          rounds: _completedRounds,
          config: widget.config,
        ),
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_phase == SessionPhase.hyperventilation) {
      if (_isPaused) {
        _breathController.stop();
      } else {
        if (_isInhaling) {
          _breathController.forward();
        } else {
          _breathController.reverse();
        }
      }
    }
  }

  void _showExitConfirmation() {
    final bool wasPaused = _isPaused;
    if (!_isPaused) {
      _togglePause();
    }

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Text(
          'End Breathwork Session?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          _completedRounds.isNotEmpty
              ? 'You have completed ${_completedRounds.length} round(s). Would you like to save your progress or discard?'
              : 'Are you sure you want to exit? Your progress will not be saved.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              if (!wasPaused) {
                _togglePause(); // resume
              }
            },
            child: const Text('RESUME'),
          ),
          if (_completedRounds.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => WimHofSummaryScreen(
                      rounds: _completedRounds,
                      config: widget.config,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('SAVE ROUNDS'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // exit screen
            },
            child: Text(
              'DISCARD & QUIT',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double overallProgress =
        ((_currentRound - 1) + (_phaseProgressFraction())) /
            widget.config.defaultRounds;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: _showExitConfirmation,
        ),
        title: Column(
          children: <Widget>[
            Text(
              'ROUND $_currentRound OF ${widget.config.defaultRounds}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.secondaryCyan,
              ),
            ),
            Text(
              _phaseTitle(),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              color: AppTheme.primaryAmber,
            ),
            onPressed: _togglePause,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: overallProgress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.secondaryCyan,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Main Interactive Stage
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  _buildStageContent(),
                  const Spacer(),
                  _buildBottomControls(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Paused Overlay
            if (_isPaused)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.pause_circle_outline,
                      size: 64,
                      color: AppTheme.primaryAmber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session Paused',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _togglePause,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'RESUME',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _phaseProgressFraction() {
    switch (_phase) {
      case SessionPhase.prep:
        return 0.0;
      case SessionPhase.hyperventilation:
        return (_currentBreath / widget.config.breathsPerRound) * 0.5;
      case SessionPhase.retention:
        return 0.75;
      case SessionPhase.recovery:
        return 0.95;
    }
  }

  String _phaseTitle() {
    switch (_phase) {
      case SessionPhase.prep:
        return 'Get Ready';
      case SessionPhase.hyperventilation:
        return 'Deep Rhythmic Breathing';
      case SessionPhase.retention:
        return 'Breath Retention (Exhale Hold)';
      case SessionPhase.recovery:
        return 'Recovery Breath (Inhale Hold)';
    }
  }

  Widget _buildStageContent() {
    switch (_phase) {
      case SessionPhase.prep:
        return _buildPrepStage();
      case SessionPhase.hyperventilation:
        return _buildHyperventilationStage();
      case SessionPhase.retention:
        return _buildRetentionStage();
      case SessionPhase.recovery:
        return _buildRecoveryStage();
    }
  }

  // --- 1. PREP STAGE ---
  Widget _buildPrepStage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Round $_currentRound',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Relax your body and prepare for ${_currentRound == 1 ? "the first round" : "the next round"}.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceElevated,
            border: Border.all(color: AppTheme.secondaryCyan, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$_prepSecondsRemaining',
            style: GoogleFonts.outfit(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryCyan,
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. HYPERVENTILATION STAGE ---
  Widget _buildHyperventilationStage() {
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (BuildContext context, Widget? child) {
        final double scale = 0.75 + (_breathAnimation.value * 0.5); // 0.75 -> 1.25
        final Color orbColor = _isInhaling
            ? AppTheme.secondaryCyan
            : AppTheme.primaryAmber;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Breath Counter Indicator
            Text(
              'BREATH $_currentBreath OF ${widget.config.breathsPerRound}',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isInhaling ? 'FULLY IN...' : 'LETTING GO...',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: orbColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 40),

            // Pulsing Breathing Orb
            SizedBox(
              width: 260,
              height: 260,
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          orbColor.withValues(alpha: 0.85),
                          orbColor.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const <double>[0.3, 0.7, 1.0],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: orbColor.withValues(alpha: 0.45),
                          blurRadius: 40 * _breathAnimation.value + 10,
                          spreadRadius: 10 * _breathAnimation.value + 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceCard,
                          border: Border.all(color: orbColor, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_currentBreath',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 3. RETENTION STAGE ---
  Widget _buildRetentionStage() {
    final BreathingProvider breathingProvider =
        Provider.of<BreathingProvider>(context, listen: false);
    final int currentPR = breathingProvider.allTimeMaxHoldSeconds;
    final bool isBeatingPR = currentPR > 0 && _retentionSeconds > currentPR;

    final String minutes = (_retentionSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_retentionSeconds % 60).toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isBeatingPR
                ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isBeatingPR
                  ? AppTheme.primaryAmber
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            isBeatingPR ? '🔥 NEW PERSONAL BEST!' : 'Lungs Empty • Stay Relaxed',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isBeatingPR
                  ? AppTheme.primaryAmber
                  : AppTheme.secondaryCyan,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Stopwatch Timer Display
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceCard,
            border: Border.all(
              color: isBeatingPR
                  ? AppTheme.primaryAmber
                  : AppTheme.secondaryCyan,
              width: 3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (isBeatingPR
                        ? AppTheme.primaryAmber
                        : AppTheme.secondaryCyan)
                    .withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'RETENTION TIME',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.outfit(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              if (currentPR > 0) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  'PR: ${breathingProvider.formattedAllTimeMaxHold}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isBeatingPR
                        ? AppTheme.primaryAmber
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- 4. RECOVERY STAGE ---
  Widget _buildRecoveryStage() {
    final double progress = (15 - _recoverySecondsRemaining) / 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'RECOVERY BREATH',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inhale fully to chest and hold for 15 seconds.',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.successGreen,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$_recoverySecondsRemaining',
                    style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'HOLD FULL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successGreen,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BOTTOM CONTROLS ---
  Widget _buildBottomControls() {
    switch (_phase) {
      case SessionPhase.prep:
        return const SizedBox(height: 54);

      case SessionPhase.hyperventilation:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              if (widget.config.hapticsEnabled) {
                HapticFeedback.selectionClick();
              }
              _transitionToRetention();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondaryCyan,
              side: const BorderSide(color: AppTheme.secondaryCyan),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              'I\'M FULL • START RETENTION HOLD',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );

      case SessionPhase.retention:
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _endRetentionAndStartRecovery,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
            ),
            icon: const Icon(Icons.air, size: 26),
            label: Text(
              'TAP TO INHALE (RECOVERY BREATH)',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );

      case SessionPhase.recovery:
        return Text(
          'Next round will start automatically...',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        );
    }
  }
}
