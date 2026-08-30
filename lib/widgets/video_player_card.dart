import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/accessory_log.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/kettlebell_mile_card.dart';
import 'package:oly/widgets/mobility_exercise_swap_modal.dart';
import 'package:oly/widgets/rest_timer_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerCard extends StatefulWidget {
  const VideoPlayerCard({
    required this.exercise,
    required this.onCompleted,
    super.key,
    this.originalExercise,
    this.isSwapped = false,
    this.onSwapExercise,
    this.onResetExercise,
    this.onSkip,
  });
  final MobilityExerciseModel exercise;
  final MobilityExerciseModel? originalExercise;
  final bool isSwapped;
  final ValueChanged<MobilityExerciseModel>? onSwapExercise;
  final VoidCallback? onResetExercise;
  final VoidCallback? onSkip;
  final VoidCallback onCompleted;

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  late List<bool> _setsCompleted;
  late TextEditingController _weightController;
  double _accessoryWeight = 0.0;
  bool _showAccessoryRestTimer = false;
  bool _initializedWeight = false;

  @override
  void initState() {
    super.initState();
    _setsCompleted = List.filled(widget.exercise.defaultSets, false);
    _accessoryWeight = widget.exercise.category == MobilityCategory.barbellPrep
        ? 20.0
        : 10.0;
    _weightController = TextEditingController(
      text: _accessoryWeight > 0 ? _accessoryWeight.toStringAsFixed(1) : '0',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedWeight) {
      final RecoveryProvider recovery = Provider.of<RecoveryProvider>(
        context,
        listen: false,
      );
      final AccessoryLog? latest = recovery.getLatestAccessoryLog(
        widget.exercise.id,
      );
      if (latest != null && latest.weightKg > 0) {
        _accessoryWeight = latest.weightKg;
        _weightController.text = _accessoryWeight.toStringAsFixed(1);
      }
      _initializedWeight = true;
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _setsCompleted = List.filled(widget.exercise.defaultSets, false);
      final RecoveryProvider recovery = Provider.of<RecoveryProvider>(
        context,
        listen: false,
      );
      final AccessoryLog? latest = recovery.getLatestAccessoryLog(
        widget.exercise.id,
      );
      if (latest != null && latest.weightKg > 0) {
        _accessoryWeight = latest.weightKg;
      } else {
        _accessoryWeight =
            widget.exercise.category == MobilityCategory.barbellPrep
            ? 20.0
            : 10.0;
      }
      _weightController.text = _accessoryWeight > 0
          ? _accessoryWeight.toStringAsFixed(1)
          : '0';
      _showAccessoryRestTimer = false;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _adjustAccessoryWeight(double delta) {
    setState(() {
      _accessoryWeight = (_accessoryWeight + delta).clamp(0.0, 300.0);
      _weightController.text = _accessoryWeight.toStringAsFixed(1);
    });
  }

  bool get _isTimedDrill {
    return widget.exercise.category == MobilityCategory.cardioConditioning ||
        widget.exercise.category == MobilityCategory.foamRolling ||
        widget.exercise.category == MobilityCategory.mobilityDrill;
  }

  Future<void> _launchVideoUrl() async {
    Uri? primaryUri;
    if (widget.exercise.videoUrl.isNotEmpty) {
      primaryUri = Uri.tryParse(widget.exercise.videoUrl);
    }

    bool launched = false;
    if (primaryUri != null && await canLaunchUrl(primaryUri)) {
      try {
        launched = await launchUrl(
          primaryUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }
    }

    if (!launched) {
      final String query =
          '${widget.exercise.name} Catalyst Athletics weightlifting tutorial';
      final Uri searchUri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      );

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

  void _showAccessoryHistorySheet(
    BuildContext context,
    RecoveryProvider recovery,
    SettingsProvider settings,
  ) {
    final List<AccessoryLog> history = recovery.getAccessoryHistory(
      widget.exercise.id,
    );
    final double pb = recovery.getAccessoryPersonalBest(widget.exercise.id);
    final String unit = settings.unitLabel.toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.exercise.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Weight Progression History',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pb > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryAmber),
                        ),
                        child: Text(
                          'PB: ${settings.toDisplayWeight(pb).toStringAsFixed(1)} $unit',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No logged sets for this movement yet.\nComplete sets to start tracking weight progression!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        final AccessoryLog item = history[idx];
                        final String dateStr = DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(item.date);
                        final double itemWeight = settings.toDisplayWeight(
                          item.weightKg,
                        );
                        final bool isPb = item.weightKg >= pb && pb > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPb
                                  ? AppTheme.primaryAmber.withValues(alpha: 0.5)
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${item.sets} Sets × ${item.reps} Reps',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  if (isPb)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryAmber,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PR',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    item.weightKg > 0
                                        ? '${itemWeight.toStringAsFixed(1)} $unit'
                                        : 'Bodyweight',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isPb
                                          ? AppTheme.primaryAmber
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSwapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => MobilityExerciseSwapModal(
        exercise: widget.exercise,
        originalExercise: widget.originalExercise,
        onSwapSelected: (MobilityExerciseModel replacement) {
          if (widget.onSwapExercise != null) {
            widget.onSwapExercise!(replacement);
          }
        },
        onResetToOriginal: widget.onResetExercise,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercise.id == 'kettlebell_mile') {
      return KettlebellMileCard(
        exercise: widget.exercise,
        isSwapped: widget.isSwapped,
        onCompleted: widget.onCompleted,
        onSkip: widget.onSkip ?? () {},
        onOpenSwapModal: () => _openSwapModal(context),
      );
    }

    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final MobilityExerciseModel ex = widget.exercise;
    final bool isMobility =
        ex.category == MobilityCategory.mobilityDrill ||
        ex.category == MobilityCategory.foamRolling;
    final bool isCardio = ex.category == MobilityCategory.cardioConditioning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Category Badges & Swap Button
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCardio
                          ? Colors.tealAccent.withValues(alpha: 0.15)
                          : isMobility
                          ? AppTheme.accentBlue.withValues(alpha: 0.15)
                          : AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCardio
                            ? Colors.tealAccent.withValues(alpha: 0.5)
                            : isMobility
                            ? AppTheme.accentBlue.withValues(alpha: 0.5)
                            : AppTheme.primaryAmber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _categoryLabel(ex.category),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCardio
                            ? Colors.tealAccent
                            : isMobility
                            ? AppTheme.accentBlue
                            : AppTheme.primaryAmber,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
              if (widget.onSwapExercise != null)
                InkWell(
                  onTap: () => _openSwapModal(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSwapped
                          ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isSwapped
                            ? AppTheme.primaryAmber
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.swap_horiz,
                          size: 14,
                          color: widget.isSwapped
                              ? AppTheme.primaryAmber
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.isSwapped ? 'SWAPPED' : 'Swap',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.isSwapped
                                ? AppTheme.primaryAmber
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.onSkip != null) ...<Widget>[
                const SizedBox(width: 6),
                InkWell(
                  onTap: widget.onSkip,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.skip_next,
                          size: 14,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Skip',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                border: Border.all(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/icon/splash.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.25,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.primaryAmber.withValues(
                                alpha: 0.5,
                              ),
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
                        children: <Widget>[
                          Icon(
                            ex.isYoutube
                                ? Icons.subscriptions
                                : Icons.ondemand_video,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ex.isYoutube
                                ? 'YouTube Coaching Tutorial'
                                : 'Exercise Clip',
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
          ...ex.cues.map((String cue) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: AppTheme.accentBlue,
                    ),
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

          // Unified Execution Controls: Reusable Timer for Timed Drills vs Workout-Matched Sets for Accessories
          if (_isTimedDrill)
            _buildUnifiedDrillTimerSection(settings)
          else
            _buildWorkoutMatchedSetsSection(settings),
        ],
      ),
    );
  }

  Widget _buildUnifiedDrillTimerSection(SettingsProvider settings) {
    final MobilityExerciseModel ex = widget.exercise;
    final bool isCardio = ex.category == MobilityCategory.cardioConditioning;
    final bool isFoamRoll = ex.category == MobilityCategory.foamRolling;

    String timerTitle = 'Mobility Drill Timer';
    IconData timerIcon = Icons.timer_outlined;
    List<int> presets = <int>[30, 45, 60, 90, 120];
    Color primaryColor = AppTheme.accentBlue;

    if (isCardio) {
      timerTitle = 'Cardio Interval Timer';
      timerIcon = Icons.directions_run;
      presets = <int>[60, 120, 180, 300, 480, 600]; // 1m, 2m, 3m, 5m, 8m, 10m
      primaryColor = AppTheme.primaryAmber;
    } else if (isFoamRoll) {
      timerTitle = 'Foam Roll Timer';
      timerIcon = Icons.self_improvement;
      presets = <int>[30, 45, 60, 90, 120];
      primaryColor = AppTheme.secondaryCyan;
    }

    final int duration = ex.durationSeconds > 0
        ? ex.durationSeconds
        : (isCardio ? 180 : 60);

    return RestTimerWidget(
      key: ValueKey('${ex.id}_timer'),
      title: timerTitle,
      icon: timerIcon,
      initialSeconds: duration,
      presetSeconds: presets,
      primaryColor: primaryColor,
      isEmbedded: true,
      notificationTitle: isCardio
          ? '🏃 Cardio Interval Complete!'
          : isFoamRoll
          ? '🧘 Foam Rolling Complete!'
          : '✨ Mobility Drill Complete!',
      notificationBody: '${ex.name} finished. Ready for the next movement.',
      onFinished: widget.onCompleted,
    );
  }

  Widget _buildWorkoutMatchedSetsSection(SettingsProvider settings) {
    final MobilityExerciseModel ex = widget.exercise;
    final double displayWeight = settings.toDisplayWeight(_accessoryWeight);
    final String unitLabel = settings.unitLabel.toUpperCase();
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);

    final double pbKg = recovery.getAccessoryPersonalBest(ex.id);
    final AccessoryLog? latestLog = recovery.getLatestAccessoryLog(ex.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header: Target Scheme, Rest Timer Toggle & Progression History
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Text(
                'TARGET SETS & WEIGHT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${ex.defaultSets} Sets × ${ex.defaultReps} Reps',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Progression History Button
                  InkWell(
                    onTap: () =>
                        _showAccessoryHistorySheet(context, recovery, settings),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.show_chart,
                            size: 14,
                            color: AppTheme.accentBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'History',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Rest Timer Toggle
                  InkWell(
                    onTap: () => setState(
                      () => _showAccessoryRestTimer = !_showAccessoryRestTimer,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _showAccessoryRestTimer
                            ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                            : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showAccessoryRestTimer
                              ? AppTheme.primaryAmber
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: _showAccessoryRestTimer
                                ? AppTheme.primaryAmber
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rest',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _showAccessoryRestTimer
                                  ? AppTheme.primaryAmber
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

          // Working Weight Banner & Steppers (Matching Live Workout Session)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.fitness_center,
                  color: AppTheme.primaryAmber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weight:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _accessoryWeight == 0.0
                        ? 'Bodyweight / Band'
                        : '${displayWeight.toStringAsFixed(1)} $unitLabel',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                // Steppers
                _buildWeightStepButton('-2.5', -2.5),
                const SizedBox(width: 4),
                _buildWeightStepButton('+2.5', 2.5),
                const SizedBox(width: 4),
                _buildWeightStepButton('+5.0', 5.0),
              ],
            ),
          ),

          // Personal Best & Previous Log progression indicators
          if (pbKg > 0 || latestLog != null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                if (pbKg > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 12,
                          color: AppTheme.primaryAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PB: ${settings.toDisplayWeight(pbKg).toStringAsFixed(1)} $unitLabel',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (latestLog != null)
                  Text(
                    'Last: ${settings.toDisplayWeight(latestLog.weightKg).toStringAsFixed(1)} $unitLabel',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Workout-Matched Interactive Set Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(ex.defaultSets, (int index) {
              final bool isDone = _setsCompleted[index];
              final String weightText = _accessoryWeight > 0
                  ? '${displayWeight.toStringAsFixed(1)}$unitLabel'
                  : 'BW';

              return InkWell(
                onTap: () async {
                  setState(() => _setsCompleted[index] = !isDone);
                  if (_setsCompleted.every((bool e) => e)) {
                    // Log accessory progression into history
                    await recovery.logAccessoryWeight(
                      exerciseId: ex.id,
                      exerciseName: ex.name,
                      weightKg: _accessoryWeight,
                      sets: ex.defaultSets,
                      reps: ex.defaultReps,
                      source: 'routine',
                    );
                    widget.onCompleted();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.withValues(alpha: 0.25)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone ? Colors.greenAccent : AppTheme.borderColor,
                      width: isDone ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isDone
                            ? Colors.greenAccent
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Set ${index + 1}: $weightText',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? Colors.greenAccent
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Optional In-line Rest Timer
          if (_showAccessoryRestTimer) ...<Widget>[
            const SizedBox(height: 14),
            RestTimerWidget(
              key: ValueKey('${ex.id}_rest_timer'),
              title: 'Accessory Rest Timer',
              icon: Icons.timer_outlined,
              initialSeconds: 60,
              presetSeconds: const <int>[30, 45, 60, 90, 120],
              primaryColor: AppTheme.primaryAmber,
              isEmbedded: true,
              notificationTitle: '⏰ Rest Complete!',
              notificationBody: 'Time for your next set of ${ex.name}.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightStepButton(String label, double delta) {
    return InkWell(
      onTap: () => _adjustAccessoryWeight(delta),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: delta > 0 ? AppTheme.primaryAmber : AppTheme.textSecondary,
          ),
        ),
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
