import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mobility_exercise_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class VideoPlayerCard extends StatefulWidget {
  final MobilityExerciseModel exercise;
  final VoidCallback onCompleted;

  const VideoPlayerCard({
    super.key,
    required this.exercise,
    required this.onCompleted,
  });

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  // Mobility Drill Timer State
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isRunning = false;

  // Accessory Sets Completed Tracker State
  late List<bool> _setsCompleted;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.exercise.durationSeconds;
    _setsCompleted = List.filled(widget.exercise.defaultSets, false);
  }

  @override
  void didUpdateWidget(covariant VideoPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _stopTimer();
      _secondsRemaining = widget.exercise.durationSeconds;
      _setsCompleted = List.filled(widget.exercise.defaultSets, false);
      _isRunning = false;
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        _stopTimer();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        widget.onCompleted();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _pauseTimer() {
    _stopTimer();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _secondsRemaining = widget.exercise.durationSeconds;
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _launchVideoUrl() async {
    Uri? primaryUri;
    if (widget.exercise.videoUrl.isNotEmpty) {
      primaryUri = Uri.tryParse(widget.exercise.videoUrl);
    }

    bool launched = false;
    if (primaryUri != null && await canLaunchUrl(primaryUri)) {
      try {
        launched = await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched) {
      // Fallback: Launch a targeted YouTube search for the exercise tutorial
      final query = '${widget.exercise.name} Catalyst Athletics weightlifting tutorial';
      final searchUri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');

      if (await canLaunchUrl(searchUri)) {
        await launchUrl(searchUri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video for ${widget.exercise.name}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final ex = widget.exercise;
    final isMobility = ex.category == MobilityCategory.mobilityDrill;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Category Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isMobility
                      ? AppTheme.accentBlue.withValues(alpha: 0.15)
                      : AppTheme.primaryAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMobility
                        ? AppTheme.accentBlue.withValues(alpha: 0.5)
                        : AppTheme.primaryAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _categoryLabel(ex.category),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMobility ? AppTheme.accentBlue : AppTheme.primaryAmber,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  _focusAreaLabel(ex.focusArea),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Exercise Name & Description
          Text(
            ex.name,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            settings.formatTextUnits(ex.description),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Embedded Video Launcher Card
          GestureDetector(
            onTap: _launchVideoUrl,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                image: const DecorationImage(
                  image: AssetImage('assets/icon/splash.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.25,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Watch Video Demonstration',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ex.isYoutube ? Icons.subscriptions : Icons.ondemand_video,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ex.isYoutube ? 'YouTube Coaching Tutorial' : 'Exercise Clip',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Technique Cues Bullet List
          Text(
            'KEY FORM CUES',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAmber,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...ex.cues.map((cue) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: Icon(Icons.check_circle_outline, size: 14, color: AppTheme.accentBlue),
                  ),
                  Expanded(
                    child: Text(
                      settings.formatTextUnits(cue),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Interactive Execution Controls (Timer for Mobility vs Sets Checklist for Accessory)
          isMobility ? _buildMobilityTimerSection() : _buildAccessorySetsSection(),
        ],
      ),
    );
  }

  Widget _buildMobilityTimerSection() {
    final mins = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                '$mins:$secs',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.orangeAccent : AppTheme.accentBlue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isRunning ? 'PAUSE' : 'START TIMER',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _resetTimer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('RESET'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessorySetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET SETS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${widget.exercise.defaultSets} Sets × ${widget.exercise.defaultReps} Reps (Light)',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.exercise.defaultSets, (index) {
              final isDone = _setsCompleted[index];
              return ChoiceChip(
                label: Text(
                  'Set ${index + 1}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.black : AppTheme.textPrimary,
                  ),
                ),
                selected: isDone,
                selectedColor: AppTheme.primaryAmber,
                backgroundColor: AppTheme.surfaceCard,
                avatar: isDone ? const Icon(Icons.check, color: Colors.black, size: 18) : null,
                onSelected: (val) {
                  setState(() => _setsCompleted[index] = val);
                  if (_setsCompleted.every((e) => e)) {
                    widget.onCompleted();
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _focusAreaLabel(MobilityFocusArea focus) {
    switch (focus) {
      case MobilityFocusArea.thoracicSpine:
        return 'Thoracic Spine';
      case MobilityFocusArea.shoulderOverhead:
        return 'Shoulder & Overhead';
      case MobilityFocusArea.hipCapsule:
        return 'Hip Mobility';
      case MobilityFocusArea.ankleDorsiflexion:
        return 'Ankle Dorsiflexion';
      case MobilityFocusArea.posteriorChain:
        return 'Posterior Chain';
      case MobilityFocusArea.quadriceps:
        return 'Quads & Glutes';
      case MobilityFocusArea.cardio:
        return 'Aerobic Recovery';
      case MobilityFocusArea.arms:
        return 'Arms & Upper';
      case MobilityFocusArea.absCore:
        return 'Abs & Core';
      case MobilityFocusArea.gripStrength:
        return 'Grip Strength';
      case MobilityFocusArea.barbellSnatch:
        return 'Snatch Prep';
      case MobilityFocusArea.barbellCleanJerk:
        return 'Clean & Jerk Prep';
      case MobilityFocusArea.barbellSquat:
        return 'Squat Prep';
    }
  }

  String _categoryLabel(MobilityCategory category) {
    switch (category) {
      case MobilityCategory.mobilityDrill:
        return 'MOBILITY DRILL';
      case MobilityCategory.liftingAccessory:
        return 'WEAK-POINT ACCESSORY';
      case MobilityCategory.cardioConditioning:
        return 'ZONE 2 CARDIO';
      case MobilityCategory.hypertrophyCore:
        return 'HYPERTROPHY & CORE';
      case MobilityCategory.foamRolling:
        return 'FOAM ROLLING';
      case MobilityCategory.barbellPrep:
        return 'BARBELL PREP';
    }
  }
}
