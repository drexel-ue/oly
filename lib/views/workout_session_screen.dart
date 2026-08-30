import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';
import 'package:oly/widgets/plate_modal.dart';
import 'package:oly/widgets/post_session_body_checkin_dialog.dart';
import 'package:oly/widgets/rest_timer_widget.dart';
import 'package:oly/widgets/session_injury_adaptation_card.dart';
import 'package:oly/widgets/workout_set_edit_dialog.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    required this.dayTemplate,
    super.key,
    this.isPreviewMode = false,
    this.previewWeek,
    this.initialDraft,
  });
  final DayTemplate dayTemplate;
  final bool isPreviewMode;
  final int? previewWeek;
  final ActiveWorkoutDraft? initialDraft;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final Uuid _uuid = const Uuid();
  final Map<String, List<CompletedSet>> _exerciseSets =
      <String, List<CompletedSet>>{};
  final Map<String, TextEditingController> _weightControllers =
      <String, TextEditingController>{};
  final Map<String, String> _swappedExerciseNames = <String, String>{};
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  DateTime _startTime = DateTime.now();
  late bool _isLiveMode;

  int _selectedRpe = 8;
  final Set<String> _selectedJointStrains = <String>{};

  @override
  void initState() {
    super.initState();
    _isLiveMode = widget.initialDraft != null
        ? !widget.initialDraft!.isPreviewMode
        : !widget.isPreviewMode;
    _startTime = widget.initialDraft?.startTime ?? DateTime.now();

    final LiftProvider liftProvider = Provider.of<LiftProvider>(
      context,
      listen: false,
    );
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );

    final int week =
        widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;
    final Map<String, double> maxes = liftProvider.currentMaxes;

    if (widget.initialDraft != null) {
      final ActiveWorkoutDraft draft = widget.initialDraft!;
      _selectedRpe = draft.selectedRpe;
      _selectedJointStrains.addAll(draft.selectedJointStrains);
      _notesController.text = draft.notes;
      _swappedExerciseNames.addAll(draft.swappedExerciseNames);

      draft.exerciseSets.forEach((String name, List<CompletedSet> sets) {
        _exerciseSets[name] = List.from(sets);
      });

      draft.exerciseWeights.forEach((String name, double weight) {
        _weightControllers[name] = TextEditingController(
          text: weight.toStringAsFixed(1),
        );
      });
    }

    for (final PhaseTemplate phase in widget.dayTemplate.phases) {
      for (final ExerciseTemplate exercise in phase.exercises) {
        final double targetKg = exercise.calculateTargetWeight(
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
          final RegExpMatch? match = RegExp(r'(\d+)\s+Sets')
              .firstMatch(exercise.setScheme);
          if (match != null) {
            setNum = int.tryParse(match.group(1)!) ?? 3;
          }

          int reps = 5;
          final RegExpMatch? repMatch = RegExp(r'(\d+)\s+Reps')
              .firstMatch(exercise.setScheme);
          if (repMatch != null) {
            reps = int.tryParse(repMatch.group(1)!) ?? 5;
          }

          _exerciseSets[exercise.name] = List.generate(
            setNum,
            (int i) => CompletedSet(
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
    if (!_isLiveMode || !mounted) {
      return;
    }
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    final Map<String, double> weights = <String, double>{};
    _weightControllers.forEach((String k, TextEditingController v) {
      final double? parsed = double.tryParse(v.text);
      if (parsed != null) {
        weights[k] = parsed;
      }
    });

    final ActiveWorkoutDraft draft = ActiveWorkoutDraft(
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
    final bool hasCompletedSets = _exerciseSets.values.any(
      (List<CompletedSet> sets) => sets.any((CompletedSet s) => s.isCompleted),
    );
    return !hasCompletedSets && _notesController.text.trim().isEmpty;
  }

  Future<bool?> _showExitPrompt(BuildContext context) async {
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: <Widget>[
            const Icon(
              Icons.pause_circle_outline,
              color: AppTheme.primaryAmber,
            ),
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
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await programProvider.clearActiveDraft();
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
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
    for (final TextEditingController controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSetCompletion(String exerciseName, int setIndex) {
    setState(() {
      final List<CompletedSet>? list = _exerciseSets[exerciseName];
      if (list != null && setIndex < list.length) {
        final CompletedSet current = list[setIndex];
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
    final String query =
        '$exerciseName Catalyst Athletics weightlifting tutorial';
    final Uri searchUri = Uri.parse(
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
    final LiftProvider liftProvider = Provider.of<LiftProvider>(
      context,
      listen: false,
    );
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    final int currentWeek =
        widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;

    final String? currentSwapped = _swappedExerciseNames[exercise.name];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ExerciseSwapModal(
          exercise: exercise,
          currentSwappedName: currentSwapped,
          currentWeek: currentWeek,
          onSwapSelected: (LiftModel newLift) {
            final double targetKg = ExerciseSwapHelper.calculateSwappedWeight(
              newLift: newLift,
              exerciseTemplate: exercise,
              currentWeek: currentWeek,
              currentMaxes: liftProvider.currentMaxes,
            );

            setState(() {
              _swappedExerciseNames[exercise.name] = newLift.name;
              _weightControllers[exercise.name]?.text = targetKg
                  .toStringAsFixed(1);

              final List<CompletedSet>? sets = _exerciseSets[exercise.name];
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
            final double originalTargetKg = exercise.calculateTargetWeight(
              week: currentWeek,
              currentMaxes: liftProvider.currentMaxes,
            );

            setState(() {
              _swappedExerciseNames.remove(exercise.name);
              _weightControllers[exercise.name]?.text = originalTargetKg
                  .toStringAsFixed(1);

              final List<CompletedSet>? sets = _exerciseSets[exercise.name];
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
                content: Text('Restored to original: ${exercise.name}'),
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
    final LiftProvider liftProvider = Provider.of<LiftProvider>(
      context,
      listen: false,
    );
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    final int currentWeek =
        widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;

    final String displayName =
        _swappedExerciseNames[exercise.name] ?? exercise.name;
    final double currentWeightKg =
        double.tryParse(_weightControllers[exercise.name]?.text ?? '0') ??
        exercise.calculateTargetWeight(
          week: currentWeek,
          currentMaxes: liftProvider.currentMaxes,
        );

    final List<CompletedSet>? currentSets = _exerciseSets[exercise.name];
    final int currentReps = currentSets != null && currentSets.isNotEmpty
        ? currentSets.first.reps
        : WorkoutWeightHelper.extractRepsCount(exercise.setScheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return WorkoutWeightDialog(
          exercise: exercise,
          displayName: displayName,
          initialWeightKg: currentWeightKg,
          initialReps: currentReps,
          currentWeek: currentWeek,
          onWeightUpdated:
              ({
                required double newWeightKg,
                int? newReps,
                required bool update1RM,
                double? new1RMKg,
              }) async {
                final int finalReps = newReps ?? currentReps;
                setState(() {
                  _weightControllers[exercise.name]?.text = newWeightKg
                      .toStringAsFixed(1);

                  final List<CompletedSet>? sets = _exerciseSets[exercise.name];
                  if (sets != null) {
                    for (int i = 0; i < sets.length; i++) {
                      sets[i] = CompletedSet(
                        setIndex: sets[i].setIndex,
                        weight: newWeightKg,
                        reps: finalReps,
                        rpe: sets[i].rpe,
                        isCompleted: sets[i].isCompleted,
                        completedAt: sets[i].completedAt,
                      );
                    }
                  }
                });

                _persistDraft();

                if (update1RM && new1RMKg != null && new1RMKg > 0) {
                  final LiftModel targetLift = liftProvider.lifts.firstWhere(
                    (LiftModel l) =>
                        l.name.toLowerCase() == displayName.toLowerCase(),
                    orElse: () => liftProvider.lifts.firstWhere(
                      (LiftModel l) =>
                          l.id.toLowerCase() == exercise.liftId.toLowerCase(),
                      orElse: () => liftProvider.lifts.first,
                    ),
                  );

                  await liftProvider.updateMax(
                    targetLift.id,
                    new1RMKg,
                    notes:
                        'Recalculated from workout ($displayName @ ${newWeightKg.toStringAsFixed(1)} kg × $finalReps reps)',
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🔥 ${targetLift.name} 1RM updated to ${new1RMKg.toStringAsFixed(1)} kg! Target set to ${newWeightKg.toStringAsFixed(1)} kg × $finalReps reps.',
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
                        'Working target updated to ${newWeightKg.toStringAsFixed(1)} kg × $finalReps reps.',
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

  void _showSetEditDialog(String exerciseName, int setIndex) {
    final List<CompletedSet>? sets = _exerciseSets[exerciseName];
    if (sets == null || setIndex >= sets.length) {
      return;
    }
    final CompletedSet currentSet = sets[setIndex];
    final String displayName =
        _swappedExerciseNames[exerciseName] ?? exerciseName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return WorkoutSetEditDialog(
          exerciseName: displayName,
          currentSet: currentSet,
          totalSets: sets.length,
          onSaveSet: ({
            required double newWeightKg,
            required int newReps,
            required bool isCompleted,
            bool applyToSubsequentSets = false,
          }) {
            final SettingsProvider settings = Provider.of<SettingsProvider>(
              context,
              listen: false,
            );
            setState(() {
              sets[setIndex] = CompletedSet(
                setIndex: currentSet.setIndex,
                weight: newWeightKg,
                reps: newReps,
                rpe: currentSet.rpe,
                isCompleted: isCompleted,
                completedAt: isCompleted
                    ? (currentSet.completedAt ?? DateTime.now())
                    : null,
              );

              if (applyToSubsequentSets) {
                for (int i = setIndex + 1; i < sets.length; i++) {
                  sets[i] = CompletedSet(
                    setIndex: sets[i].setIndex,
                    weight: newWeightKg,
                    reps: newReps,
                    rpe: sets[i].rpe,
                    isCompleted: sets[i].isCompleted,
                    completedAt: sets[i].completedAt,
                  );
                }
              }
            });

            _persistDraft();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Set ${currentSet.setIndex} updated: ${settings.formatWeight(newWeightKg)} × $newReps reps (${isCompleted ? 'Completed' : 'Pending'})',
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
      builder: (BuildContext dialogCtx) => StatefulBuilder(
        builder: (BuildContext context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.darkBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: <Widget>[
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
                children: <Widget>[
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
                    onChanged: (double val) {
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
                    "Targets tomorrow's Active Recovery day routines.",
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
                        <String>[
                          'Shoulders',
                          'Hips',
                          'Lower Back',
                          'Knees',
                          'Wrists',
                        ].map((String tag) {
                          final bool isSelected = _selectedJointStrains
                              .contains(tag);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(
                              tag,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            selectedColor: AppTheme.primaryAmber,
                            backgroundColor: AppTheme.surfaceElevated,
                            onSelected: (bool val) {
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
            actions: <Widget>[
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
    // Prompt Before/After Post-Session Body Check-In in live mode
    if (_isLiveMode && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => PostSessionBodyCheckinDialog(
          initialJointStrains: _selectedJointStrains.toList(),
          onComplete: (
            Map<InjuryRegion, int> updatedPain,
            List<String> jointTags,
          ) async {
            _selectedJointStrains.clear();
            _selectedJointStrains.addAll(jointTags);

            final InjuryProvider? injuryProvider =
                Provider.of<InjuryProvider?>(context, listen: false);
            if (injuryProvider != null) {
              await injuryProvider.processPostSessionCheckin(
                postSessionPain: updatedPain,
                sessionNotes: _notesController.text,
                sessionRpe: _selectedRpe,
              );
            }
          },
        ),
      );
    }

    if (!mounted) {
      return;
    }

    final ProgramProvider programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    final int durationSecs = DateTime.now().difference(_startTime).inSeconds;

    final List<ExerciseLog> logs = <ExerciseLog>[];
    _exerciseSets.forEach((String name, List<CompletedSet> sets) {
      final String displayName = _swappedExerciseNames[name] ?? name;
      logs.add(
        ExerciseLog(
          exerciseName: displayName,
          liftId: displayName.toLowerCase().replaceAll(' ', '_'),
          sets: sets.where((CompletedSet s) => s.isCompleted).toList(),
        ),
      );
    });

    final WorkoutSession session = WorkoutSession(
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
      final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(
        context,
        listen: false,
      );
      final NutritionProvider nutritionProvider =
          Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.syncWorkoutSession(session, bodyComp.latestEntry);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 Workout Session Logged! Active Recovery & Energy synced.',
          ),
          backgroundColor: AppTheme.primaryAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final InjuryProvider? injuryProvider =
        Provider.of<InjuryProvider?>(context);
    final LiftProvider liftProvider = Provider.of<LiftProvider>(context);
    final ProgramProvider programProvider = Provider.of<ProgramProvider>(context);

    final int week = widget.previewWeek ??
        widget.initialDraft?.weekNumber ??
        programProvider.currentWeek;
    final Map<String, double> maxes = liftProvider.currentMaxes;

    return PopScope(
      canPop: !_isLiveMode || _isDraftEmpty(),
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool? shouldLeave = await _showExitPrompt(context);
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
          actions: <Widget>[
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
                    builder: (_) =>
                        WarmupSessionScreen(dayTemplate: widget.dayTemplate),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              if (!_isLiveMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                  child: Row(
                    children: <Widget>[
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
                    children: <Widget>[
                      // Active Injury Biomechanical Adaptation Banner
                      if (injuryProvider != null &&
                          injuryProvider.activeInjuries.isNotEmpty)
                        SessionInjuryAdaptationCard(
                          dayTemplate: widget.dayTemplate,
                          activeInjuries: injuryProvider.activeInjuries,
                          currentWeek: week,
                          currentMaxes: maxes,
                          appliedSwaps: _swappedExerciseNames,
                          onApplySwaps: (
                            Map<String, String> swaps,
                            Map<String, double> weights,
                          ) {
                            setState(() {
                              _swappedExerciseNames.addAll(swaps);
                              weights.forEach((String exName, double wt) {
                                if (_weightControllers.containsKey(exName)) {
                                  _weightControllers[exName]!.text =
                                      wt.toStringAsFixed(1);
                                }
                              });
                            });
                            _persistDraft();
                          },
                        ),

                      // Phases & Exercises
                      ...widget.dayTemplate.phases.map((PhaseTemplate phase) {
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
                          children: <Widget>[
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
        children: <Widget>[
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
          ...phase.exercises.map((ExerciseTemplate exercise) {
            final String displayName =
                _swappedExerciseNames[exercise.name] ?? exercise.name;
            final List<CompletedSet> sets =
                _exerciseSets[exercise.name] ?? <CompletedSet>[];
            final TextEditingController? weightCtrl =
                _weightControllers[exercise.name];
            final bool isSwapped = _swappedExerciseNames.containsKey(
              exercise.name,
            );
            final int targetReps = sets.isNotEmpty
                ? sets.first.reps
                : WorkoutWeightHelper.extractRepsCount(exercise.setScheme);

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
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Left: Exercise Title & Set Scheme Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
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
                                if (isSwapped) ...<Widget>[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAmber.withValues(
                                        alpha: 0.15,
                                      ),
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
                        children: <Widget>[
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
                            onPressed: () => _showSwapVariationDialog(exercise),
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
                              final double currentKg =
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
                        children: <Widget>[
                          const Icon(
                            Icons.tune,
                            size: 14,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Target: ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${settings.formatWeight(double.tryParse(weightCtrl?.text ?? '0') ?? 0.0)} × $targetReps ${targetReps == 1 ? 'rep' : 'reps'}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Tune / Recalc 1RM',
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
                    children: List.generate(sets.length, (int index) {
                      final CompletedSet setItem = sets[index];
                      return GestureDetector(
                        onLongPress: () =>
                            _showSetEditDialog(exercise.name, index),
                        child: FilterChip(
                          selected: setItem.isCompleted,
                          avatar: setItem.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.black,
                                )
                              : null,
                          label: Text(
                            'Set ${setItem.setIndex}: ${settings.formatWeight(setItem.weight, includeUnit: false)} × ${setItem.reps}',
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
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to complete • Long-press to edit weight & reps',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
