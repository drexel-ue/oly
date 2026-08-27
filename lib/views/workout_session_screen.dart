import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/lift_model.dart';
import '../models/program_model.dart';
import '../models/workout_session.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_swap_modal.dart';
import '../widgets/plate_modal.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/workout_weight_dialog.dart';
import 'warmup_session_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final DayTemplate dayTemplate;
  final bool isPreviewMode;
  final int? previewWeek;
  final ActiveWorkoutDraft? initialDraft;

  const WorkoutSessionScreen({
    super.key,
    required this.dayTemplate,
    this.isPreviewMode = false,
    this.previewWeek,
    this.initialDraft,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final _uuid = const Uuid();
  final Map<String, List<CompletedSet>> _exerciseSets = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, String> _swappedExerciseNames = {};
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  DateTime _startTime = DateTime.now();
  late bool _isLiveMode;

  int _selectedRpe = 8;
  final Set<String> _selectedJointStrains = {};

  @override
  void initState() {
    super.initState();
    _isLiveMode = widget.initialDraft != null
        ? !widget.initialDraft!.isPreviewMode
        : !widget.isPreviewMode;
    _startTime = widget.initialDraft?.startTime ?? DateTime.now();

    final liftProvider = Provider.of<LiftProvider>(context, listen: false);
    final programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );

    final week = widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;
    final maxes = liftProvider.currentMaxes;

    if (widget.initialDraft != null) {
      final draft = widget.initialDraft!;
      _selectedRpe = draft.selectedRpe;
      _selectedJointStrains.addAll(draft.selectedJointStrains);
      _notesController.text = draft.notes;
      _swappedExerciseNames.addAll(draft.swappedExerciseNames);

      draft.exerciseSets.forEach((name, sets) {
        _exerciseSets[name] = List.from(sets);
      });

      draft.exerciseWeights.forEach((name, weight) {
        _weightControllers[name] = TextEditingController(
          text: weight.toStringAsFixed(1),
        );
      });
    }

    for (var phase in widget.dayTemplate.phases) {
      for (var exercise in phase.exercises) {
        final targetKg = exercise.calculateTargetWeight(
          week: week,
          currentMaxes: maxes,
        );

        if (!_weightControllers.containsKey(exercise.name)) {
          _weightControllers[exercise.name] = TextEditingController(
            text: targetKg.toStringAsFixed(1),
          );
        }

        if (!_exerciseSets.containsKey(exercise.name)) {
          int setNum = 3;
          final match = RegExp(r'(\d+)\s+Sets').firstMatch(exercise.setScheme);
          if (match != null) {
            setNum = int.tryParse(match.group(1)!) ?? 3;
          }

          int reps = 5;
          final repMatch = RegExp(r'(\d+)\s+Reps').firstMatch(exercise.setScheme);
          if (repMatch != null) {
            reps = int.tryParse(repMatch.group(1)!) ?? 5;
          }

          _exerciseSets[exercise.name] = List.generate(
            setNum,
            (i) => CompletedSet(
              setIndex: i + 1,
              weight: targetKg,
              reps: reps,
              isCompleted: false,
            ),
          );
        }
      }
    }

    _notesController.addListener(_persistDraft);

    // Initial save of active live session if starting fresh
    if (_isLiveMode && widget.initialDraft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _persistDraft();
      });
    }
  }

  void _persistDraft() {
    if (!_isLiveMode || !mounted) return;
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final weights = <String, double>{};
    _weightControllers.forEach((k, v) {
      final parsed = double.tryParse(v.text);
      if (parsed != null) weights[k] = parsed;
    });

    final draft = ActiveWorkoutDraft(
      dayNumber: widget.dayTemplate.dayNumber,
      weekNumber: widget.previewWeek ?? programProvider.currentWeek,
      cycleNumber: programProvider.currentCycle,
      dayTitle: widget.dayTemplate.title,
      startTime: _startTime,
      exerciseSets: _exerciseSets,
      exerciseWeights: weights,
      swappedExerciseNames: _swappedExerciseNames,
      notes: _notesController.text,
      selectedRpe: _selectedRpe,
      selectedJointStrains: _selectedJointStrains.toList(),
      isPreviewMode: widget.isPreviewMode,
    );

    programProvider.saveActiveDraft(draft);
  }

  bool _isDraftEmpty() {
    final hasCompletedSets = _exerciseSets.values.any(
      (sets) => sets.any((s) => s.isCompleted),
    );
    return !hasCompletedSets && _notesController.text.trim().isEmpty;
  }

  Future<bool?> _showExitPrompt(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: AppTheme.primaryAmber),
            const SizedBox(width: 8),
            Text(
              'Workout in Progress',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Your workout progress has been automatically saved. You can resume this session anytime from the dashboard.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await programProvider.clearActiveDraft();
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text(
              'Discard Session',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keep Draft & Exit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.removeListener(_persistDraft);
    _notesController.dispose();
    _notesFocusNode.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSetCompletion(String exerciseName, int setIndex) {
    setState(() {
      final list = _exerciseSets[exerciseName];
      if (list != null && setIndex < list.length) {
        final current = list[setIndex];
        list[setIndex] = CompletedSet(
          setIndex: current.setIndex,
          weight: current.weight,
          reps: current.reps,
          rpe: current.rpe,
          isCompleted: !current.isCompleted,
          completedAt: !current.isCompleted ? DateTime.now() : null,
        );
      }
    });
    _persistDraft();
  }

  Future<void> _launchExerciseVideo(String exerciseName) async {
    final query = '$exerciseName Catalyst Athletics weightlifting tutorial';
    final searchUri = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
    );

    try {
      if (await canLaunchUrl(searchUri)) {
        await launchUrl(searchUri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video for $exerciseName'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video for $exerciseName'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSwapVariationDialog(ExerciseTemplate exercise) {
    final liftProvider = Provider.of<LiftProvider>(context, listen: false);
    final programProvider =
        Provider.of<ProgramProvider>(context, listen: false);
    final currentWeek = widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;

    final currentSwapped = _swappedExerciseNames[exercise.name];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ExerciseSwapModal(
          exercise: exercise,
          currentSwappedName: currentSwapped,
          currentWeek: currentWeek,
          onSwapSelected: (LiftModel newLift) {
            final targetKg = ExerciseSwapHelper.calculateSwappedWeight(
              newLift: newLift,
              exerciseTemplate: exercise,
              currentWeek: currentWeek,
              currentMaxes: liftProvider.currentMaxes,
            );

            setState(() {
              _swappedExerciseNames[exercise.name] = newLift.name;
              _weightControllers[exercise.name]?.text =
                  targetKg.toStringAsFixed(1);

              final sets = _exerciseSets[exercise.name];
              if (sets != null) {
                for (int i = 0; i < sets.length; i++) {
                  sets[i] = CompletedSet(
                    setIndex: sets[i].setIndex,
                    weight: targetKg,
                    reps: sets[i].reps,
                    rpe: sets[i].rpe,
                    isCompleted: sets[i].isCompleted,
                    completedAt: sets[i].completedAt,
                  );
                }
              }
            });

            _persistDraft();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Swapped to ${newLift.name}! Working weight updated to ${targetKg.toStringAsFixed(1)} kg.',
                ),
                backgroundColor: AppTheme.primaryAmber,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          onResetToOriginal: () {
            final originalTargetKg = exercise.calculateTargetWeight(
              week: currentWeek,
              currentMaxes: liftProvider.currentMaxes,
            );

            setState(() {
              _swappedExerciseNames.remove(exercise.name);
              _weightControllers[exercise.name]?.text =
                  originalTargetKg.toStringAsFixed(1);

              final sets = _exerciseSets[exercise.name];
              if (sets != null) {
                for (int i = 0; i < sets.length; i++) {
                  sets[i] = CompletedSet(
                    setIndex: sets[i].setIndex,
                    weight: originalTargetKg,
                    reps: sets[i].reps,
                    rpe: sets[i].rpe,
                    isCompleted: sets[i].isCompleted,
                    completedAt: sets[i].completedAt,
                  );
                }
              }
            });

            _persistDraft();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Restored to original: ${exercise.name}',
                ),
                backgroundColor: AppTheme.secondaryCyan,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      },
    );
  }

  void _showWeightAdjustDialog(ExerciseTemplate exercise) {
    final liftProvider = Provider.of<LiftProvider>(context, listen: false);
    final programProvider =
        Provider.of<ProgramProvider>(context, listen: false);
    final currentWeek = widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;

    final displayName =
        _swappedExerciseNames[exercise.name] ?? exercise.name;
    final currentWeightKg =
        double.tryParse(_weightControllers[exercise.name]?.text ?? '0') ??
            exercise.calculateTargetWeight(
              week: currentWeek,
              currentMaxes: liftProvider.currentMaxes,
            );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return WorkoutWeightDialog(
          exercise: exercise,
          displayName: displayName,
          initialWeightKg: currentWeightKg,
          currentWeek: currentWeek,
          onWeightUpdated: ({
            required double newWeightKg,
            required bool update1RM,
            double? new1RMKg,
          }) async {
            setState(() {
              _weightControllers[exercise.name]?.text =
                  newWeightKg.toStringAsFixed(1);

              final sets = _exerciseSets[exercise.name];
              if (sets != null) {
                for (int i = 0; i < sets.length; i++) {
                  sets[i] = CompletedSet(
                    setIndex: sets[i].setIndex,
                    weight: newWeightKg,
                    reps: sets[i].reps,
                    rpe: sets[i].rpe,
                    isCompleted: sets[i].isCompleted,
                    completedAt: sets[i].completedAt,
                  );
                }
              }
            });

            _persistDraft();

            if (update1RM && new1RMKg != null && new1RMKg > 0) {
              final targetLift = liftProvider.lifts.firstWhere(
                (l) => l.name.toLowerCase() == displayName.toLowerCase(),
                orElse: () => liftProvider.lifts.firstWhere(
                  (l) =>
                      l.id.toLowerCase() == exercise.liftId.toLowerCase(),
                  orElse: () => liftProvider.lifts.first,
                ),
              );

              await liftProvider.updateMax(
                targetLift.id,
                new1RMKg,
                notes:
                    'Recalculated from workout ($displayName @ ${newWeightKg.toStringAsFixed(1)} kg)',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🔥 ${targetLift.name} 1RM updated to ${new1RMKg.toStringAsFixed(1)} kg! Working weight set to ${newWeightKg.toStringAsFixed(1)} kg.',
                    ),
                    backgroundColor: AppTheme.primaryAmber,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Working weight updated to ${newWeightKg.toStringAsFixed(1)} kg.',
                  ),
                  backgroundColor: AppTheme.secondaryCyan,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _finishWorkout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.darkBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.insights, color: AppTheme.primaryAmber),
                const SizedBox(width: 8),
                Text(
                  'Post-Workout Check-In',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate Overall Session Intensity (RPE)',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RPE $_selectedRpe — ${_rpeDescription(_selectedRpe)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  Slider(
                    value: _selectedRpe.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: AppTheme.primaryAmber,
                    inactiveColor: AppTheme.surfaceElevated,
                    onChanged: (val) {
                      setDialogState(() {
                        _selectedRpe = val.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Joint Strain & Fatigue Tags',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Targets tomorrow\'s Active Recovery day routines.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        [
                          'Shoulders',
                          'Hips',
                          'Lower Back',
                          'Knees',
                          'Wrists',
                        ].map((tag) {
                          final isSelected = _selectedJointStrains.contains(
                            tag,
                          );
                          return FilterChip(
                            selected: isSelected,
                            label: Text(
                              tag,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            selectedColor: AppTheme.primaryAmber,
                            backgroundColor: AppTheme.surfaceElevated,
                            onSelected: (val) {
                              setDialogState(() {
                                if (val) {
                                  _selectedJointStrains.add(tag);
                                } else {
                                  _selectedJointStrains.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  await _saveWorkoutSession();
                },
                child: const Text('Save Workout'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _rpeDescription(int rpe) {
    switch (rpe) {
      case 1:
      case 2:
      case 3:
        return 'Easy Aerobic Recovery';
      case 4:
      case 5:
      case 6:
        return 'Moderate Technical Prep';
      case 7:
        return 'Hard — 3 reps in reserve';
      case 8:
        return 'Heavy — 2 reps in reserve';
      case 9:
        return 'Very Heavy — 1 rep in reserve';
      case 10:
        return 'Maximal Effort / PR';
      default:
        return '';
    }
  }

  Future<void> _saveWorkoutSession() async {
    final programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    final durationSecs = DateTime.now().difference(_startTime).inSeconds;

    final logs = <ExerciseLog>[];
    _exerciseSets.forEach((name, sets) {
      final displayName = _swappedExerciseNames[name] ?? name;
      logs.add(
        ExerciseLog(
          exerciseName: displayName,
          liftId: displayName.toLowerCase().replaceAll(' ', '_'),
          sets: sets.where((s) => s.isCompleted).toList(),
        ),
      );
    });

    final session = WorkoutSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      dayNumber: widget.dayTemplate.dayNumber,
      weekNumber: programProvider.currentWeek,
      cycleNumber: programProvider.currentCycle,
      durationSeconds: durationSecs,
      notes: _notesController.text,
      sessionRpe: _selectedRpe,
      jointStrainTags: _selectedJointStrains.toList(),
      logs: logs,
    );

    await programProvider.saveWorkoutSession(session);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Workout Session Logged! Active Recovery tuned.'),
          backgroundColor: AppTheme.primaryAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return PopScope(
      canPop: !_isLiveMode || _isDraftEmpty(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showExitPrompt(context);
        if (shouldLeave == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.dayTemplate.title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.directions_run,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Guided Warm-Up',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WarmupSessionScreen(
                    dayTemplate: widget.dayTemplate,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLiveMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.explore,
                      color: AppTheme.secondaryCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PREVIEW MODE — Viewing Periodization Week ${widget.previewWeek ?? 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phases & Exercises
                    ...widget.dayTemplate.phases.map((phase) {
                      return _buildPhaseCard(context, phase, settings);
                    }),

                    const SizedBox(height: 16),

                    // Session Notes input
                    TextField(
                      controller: _notesController,
                      focusNode: _notesFocusNode,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Workout Notes (RPE, feel, fatigue)...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons (Live Mode vs Preview Mode)
                    if (_isLiveMode)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _finishWorkout,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.black,
                          ),
                          label: Text(
                            'Complete & Save Session',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Exit Preview',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLiveMode = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Switched to Live Workout! You can now log your sets.',
                                    ),
                                    backgroundColor: AppTheme.primaryAmber,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                              ),
                              label: Text(
                                'Start Live Log',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: AppTheme.primaryAmber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Embedded Rest Timer at bottom
            RestTimerWidget(notesFocusNode: _notesFocusNode),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPhaseCard(
    BuildContext context,
    PhaseTemplate phase,
    SettingsProvider settings,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase.name.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.primaryAmber,
            ),
          ),
          const SizedBox(height: 12),
          ...phase.exercises.map((exercise) {
            final displayName =
                _swappedExerciseNames[exercise.name] ?? exercise.name;
            final sets = _exerciseSets[exercise.name] ?? [];
            final weightCtrl = _weightControllers[exercise.name];
            final isSwapped = _swappedExerciseNames.containsKey(exercise.name);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSwapped
                      ? AppTheme.primaryAmber.withValues(alpha: 0.6)
                      : AppTheme.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Exercise Title & Set Scheme Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSwapped) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAmber
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'SWAPPED',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryAmber,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exercise.setScheme,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Right: Top-Aligned Action Buttons (Video + Swap + Weight Tune + Plate Loader)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.play_circle_outline,
                              size: 22,
                              color: AppTheme.secondaryCyan,
                            ),
                            tooltip: 'Watch Movement Demo',
                            onPressed: () => _launchExerciseVideo(displayName),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              Icons.swap_horiz,
                              size: 22,
                              color: isSwapped
                                  ? AppTheme.primaryAmber
                                  : AppTheme.accentBlue,
                            ),
                            tooltip: 'Swap Movement Variation',
                            onPressed: () => _showSwapVariationDialog(
                              exercise,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.tune,
                              size: 20,
                              color: AppTheme.primaryAmber,
                            ),
                            tooltip: 'Adjust Weight & Recalculate 1RM',
                            onPressed: () => _showWeightAdjustDialog(exercise),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.pie_chart_outline,
                              size: 22,
                              color: AppTheme.primaryAmber,
                            ),
                            tooltip: 'Plate Loader',
                            onPressed: () {
                              final currentKg =
                                  double.tryParse(weightCtrl?.text ?? '100') ??
                                  100.0;
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    PlateModal(initialWeightKg: currentKg),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tappable Weight & 1RM Adjustment Banner
                  InkWell(
                    onTap: () => _showWeightAdjustDialog(exercise),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune,
                            size: 14,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Weight: ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  settings.formatWeight(
                                    double.tryParse(weightCtrl?.text ?? '0') ?? 0.0,
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Adjust / Recalc 1RM',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: AppTheme.primaryAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Set checkboxes row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(sets.length, (index) {
                      final setItem = sets[index];
                      return FilterChip(
                        selected: setItem.isCompleted,
                        label: Text(
                          'Set ${setItem.setIndex}: ${settings.formatWeight(setItem.weight, includeUnit: false)}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: setItem.isCompleted
                                ? Colors.black
                                : AppTheme.textPrimary,
                          ),
                        ),
                        selectedColor: AppTheme.primaryAmber,
                        backgroundColor: AppTheme.surfaceCard,
                        onSelected: (_) =>
                            _toggleSetCompletion(exercise.name, index),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
