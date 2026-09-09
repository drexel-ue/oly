import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/death_by_burpees_log.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/fran_workout_log.dart';
import 'package:oly/models/grace_workout_log.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/jackie_workout_log.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/cindy_wod_screen.dart';
import 'package:oly/views/death_by_burpees_screen.dart';
import 'package:oly/views/dt_wod_screen.dart';
import 'package:oly/views/fran_wod_screen.dart';
import 'package:oly/views/grace_wod_screen.dart';
import 'package:oly/views/helen_wod_screen.dart';
import 'package:oly/views/jackie_wod_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/widgets/add_movement_modal_sheet.dart';
import 'package:oly/widgets/empty_add_movement_card.dart';
import 'package:oly/widgets/exercise_swap_modal.dart';
import 'package:oly/widgets/plate_modal.dart';
import 'package:oly/widgets/post_session_body_checkin_dialog.dart';
import 'package:oly/widgets/rest_timer_widget.dart';
import 'package:oly/widgets/session_injury_adaptation_card.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
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
  final List<DynamicWorkoutItem> _dynamicItems = <DynamicWorkoutItem>[];
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
      _dynamicItems.addAll(draft.dynamicItems);

      draft.exerciseSets.forEach((String name, List<CompletedSet> sets) {
        _exerciseSets[name] = List.from(sets);
      });

      draft.exerciseWeights.forEach((String name, double weight) {
        _weightControllers[name] = TextEditingController(
          text: weight.toStringAsFixed(1),
        );
      });
    }

    for (final DynamicWorkoutItem item in _dynamicItems) {
      if (item.type == DynamicItemType.exercise ||
          item.type == DynamicItemType.custom) {
        final double targetKg = item.targetWeightKg ?? 0.0;
        final String scheme = item.setScheme ?? '';
        if (!_weightControllers.containsKey(item.name)) {
          _weightControllers[item.name] = TextEditingController(
            text: targetKg > 0 ? targetKg.toStringAsFixed(1) : '0.0',
          );
        }
        if (!_exerciseSets.containsKey(item.name)) {
          int setNum = 3;
          final RegExpMatch? match =
              RegExp(r'(\d+)\s+Sets').firstMatch(scheme);
          if (match != null) {
            setNum = int.tryParse(match.group(1)!) ?? 3;
          }
          int reps = 8;
          final RegExpMatch? repMatch =
              RegExp(r'(\d+)\s+Reps').firstMatch(scheme);
          if (repMatch != null) {
            reps = int.tryParse(repMatch.group(1)!) ?? 8;
          }
          _exerciseSets[item.name] = List.generate(
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
      dynamicItems: _dynamicItems,
    );

    programProvider.saveActiveDraft(draft);
  }

  bool _isDraftEmpty() {
    final bool hasCompletedSets = _exerciseSets.values.any(
      (List<CompletedSet> sets) => sets.any((CompletedSet s) => s.isCompleted),
    );
    final bool hasCompletedDynamic = _dynamicItems.any(
      (DynamicWorkoutItem i) => i.isCompleted,
    );
    return !hasCompletedSets &&
        !hasCompletedDynamic &&
        _dynamicItems.isEmpty &&
        _notesController.text.trim().isEmpty;
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
                required bool update1RM,
                int? newReps,
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

    for (final DynamicWorkoutItem item in _dynamicItems) {
      if (item.isCompleted && !_exerciseSets.containsKey(item.name)) {
        logs.add(
          ExerciseLog(
            exerciseName: item.name,
            liftId: (item.refId != null && item.refId!.isNotEmpty)
                ? item.refId!
                : item.name.toLowerCase().replaceAll(' ', '_'),
            sets: <CompletedSet>[
              CompletedSet(
                setIndex: 1,
                weight: item.targetWeightKg ?? 0.0,
                reps: 1,
                isCompleted: true,
                completedAt: DateTime.now(),
              ),
            ],
          ),
        );
      }
    }

    final StringBuffer notesBuffer = StringBuffer(_notesController.text.trim());
    final List<DynamicWorkoutItem> completedWods = _dynamicItems
        .where(
          (DynamicWorkoutItem item) =>
              item.isCompleted && item.type == DynamicItemType.wod,
        )
        .toList();
    if (completedWods.isNotEmpty) {
      if (notesBuffer.isNotEmpty) {
        notesBuffer.writeln('\n');
      }
      notesBuffer.writeln('Completed WODs:');
      for (final DynamicWorkoutItem w in completedWods) {
        notesBuffer.writeln('• ${w.name}: ${w.completedResult ?? "Done"}');
      }
    }

    final WorkoutSession session = WorkoutSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      dayNumber: widget.dayTemplate.dayNumber,
      weekNumber: programProvider.currentWeek,
      cycleNumber: programProvider.currentCycle,
      durationSeconds: durationSecs,
      notes: notesBuffer.toString(),
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
            // Mode Toggle Button in AppBar (Preview vs Live)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isLiveMode = !_isLiveMode;
                    });
                    if (_isLiveMode) {
                      _persistDraft();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Switched to Live Workout! You can now log your sets.',
                          ),
                          backgroundColor: AppTheme.primaryAmber,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Switched to Preview Mode. Explore movements and plan your session.',
                          ),
                          backgroundColor: AppTheme.secondaryCyan,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: !_isLiveMode
                          ? AppTheme.secondaryCyan.withValues(alpha: 0.2)
                          : AppTheme.primaryAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_isLiveMode
                            ? AppTheme.secondaryCyan
                            : AppTheme.primaryAmber,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          !_isLiveMode ? Icons.explore : Icons.bolt,
                          size: 14,
                          color: !_isLiveMode
                              ? AppTheme.secondaryCyan
                              : AppTheme.primaryAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          !_isLiveMode ? 'PREVIEW' : 'LIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: !_isLiveMode
                                ? AppTheme.secondaryCyan
                                : AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                          widget.dayTemplate.isFreeform
                              ? 'PREVIEW MODE — Free-Form Canvas & Planning'
                              : 'PREVIEW MODE — Viewing Periodization Week ${widget.previewWeek ?? 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryCyan,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isLiveMode = true;
                          });
                          _persistDraft();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Switched to Live Workout! You can now log your sets.',
                              ),
                              backgroundColor: AppTheme.primaryAmber,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'GO LIVE',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
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

                      // Dynamic Items (WODs, Carries, Custom exercises)
                      if (_dynamicItems.isNotEmpty)
                        _buildDynamicItemsSection(context, settings),

                      // Blank Canvas Hero or Dashed Add Card
                      EmptyAddMovementCard(
                        isSessionEmpty: widget.dayTemplate.phases.isEmpty &&
                            _dynamicItems.isEmpty,
                        isPreviewMode: !_isLiveMode,
                        onAddPressed: _openAddMovementModal,
                        onLoadRecommendedPressed: widget.dayTemplate.isFreeform &&
                                widget.dayTemplate.phases.isEmpty &&
                                _dynamicItems.isEmpty
                            ? _loadRecommendedTemplate
                            : null,
                      ),

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
  void _openAddMovementModal() {
    AddMovementModalSheet.show(
      context,
      onAddMovement: _addDynamicItem,
    );
  }

  void _addDynamicItem(DynamicWorkoutItem item, {bool shouldPersist = true}) {
    setState(() {
      _dynamicItems.add(item);
      if (item.type == DynamicItemType.exercise ||
          item.type == DynamicItemType.custom) {
        final double targetKg = item.targetWeightKg ?? 0.0;
        final String scheme = item.setScheme ?? '';
        if (!_weightControllers.containsKey(item.name)) {
          _weightControllers[item.name] = TextEditingController(
            text: targetKg > 0 ? targetKg.toStringAsFixed(1) : '0.0',
          );
        }
        if (!_exerciseSets.containsKey(item.name)) {
          int setNum = 3;
          final RegExpMatch? match =
              RegExp(r'(\d+)\s+Sets').firstMatch(scheme);
          if (match != null) {
            setNum = int.tryParse(match.group(1)!) ?? 3;
          }
          int reps = 8;
          final RegExpMatch? repMatch =
              RegExp(r'(\d+)\s+Reps').firstMatch(scheme);
          if (repMatch != null) {
            reps = int.tryParse(repMatch.group(1)!) ?? 8;
          }
          _exerciseSets[item.name] = List.generate(
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
    });
    if (shouldPersist) {
      _persistDraft();
    }
  }

  void _removeDynamicItem(int index) {
    if (index < 0 || index >= _dynamicItems.length) {
      return;
    }
    setState(() {
      final DynamicWorkoutItem removed = _dynamicItems.removeAt(index);
      _exerciseSets.remove(removed.name);
      _weightControllers.remove(removed.name)?.dispose();
    });
    _persistDraft();
  }

  void _loadRecommendedTemplate() {
    for (final PhaseTemplate phase
        in DayTemplate.recommendedActiveRecoveryPhases) {
      for (final ExerciseTemplate ex in phase.exercises) {
        final DynamicWorkoutItem item = DynamicWorkoutItem(
          id: _uuid.v4(),
          type: ex.name.toLowerCase().contains('mile')
              ? DynamicItemType.kettlebellMile
              : DynamicItemType.exercise,
          name: ex.name,
          refId: ex.liftId,
          subtitle: phase.name,
          setScheme: ex.setScheme,
          targetWeightKg: 0.0,
        );
        _addDynamicItem(item, shouldPersist: false);
      }
    }
    _persistDraft();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loaded Recommended Active Recovery Template!'),
          backgroundColor: AppTheme.secondaryCyan,
        ),
      );
    }
  }

  void _toggleDynamicItemCompletion(DynamicWorkoutItem item) {
    setState(() {
      item.isCompleted = !item.isCompleted;
      if (item.isCompleted &&
          (item.completedResult == null || item.completedResult!.isEmpty)) {
        item.completedResult = 'Completed';
      }
    });
    _persistDraft();
  }

  Future<void> _launchWodScreen(DynamicWorkoutItem item) async {
    Widget? screen;
    switch (item.refId) {
      case 'cindy':
        screen = CindyWodScreen(isPreviewMode: !_isLiveMode);
        break;
      case 'jackie':
        screen = JackieWodScreen(isPreviewMode: !_isLiveMode);
        break;
      case 'fran':
        screen = FranWodScreen(isPreviewMode: !_isLiveMode);
        break;
      case 'helen':
        screen = HelenWodScreen(isPreviewMode: !_isLiveMode);
        break;
      case 'grace':
        screen = GraceWodScreen(isPreviewMode: !_isLiveMode);
        break;
      case 'dt':
        screen = DtWodScreen(isPreviewMode: !_isLiveMode);
        break;
      case 'death_by_burpees':
        screen = DeathByBurpeesScreen(isPreviewMode: !_isLiveMode);
        break;
    }

    if (screen != null) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => screen!),
      );
      if (mounted) {
        _syncWodResult(item);
      }
    } else {
      final WodDefinition wodDef = WodCatalog.allWods.firstWhere(
        (WodDefinition w) => w.id == item.refId,
        orElse: () => WodCatalog.allWods.first,
      );
      WodSetupExplainerSheet.show(context, wodDef);
    }
  }

  void _syncWodResult(DynamicWorkoutItem item) {
    final RecoveryProvider recovery =
        Provider.of<RecoveryProvider>(context, listen: false);
    final DateTime checkThreshold =
        _startTime.subtract(const Duration(minutes: 5));
    String? result;

    switch (item.refId) {
      case 'cindy':
        final CindyWorkoutLog? log = recovery.latestCindyWorkoutLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
      case 'jackie':
        final JackieWorkoutLog? log = recovery.latestJackieWorkoutLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
      case 'fran':
        final FranWorkoutLog? log = recovery.latestFranWorkoutLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
      case 'helen':
        final HelenWorkoutLog? log = recovery.latestHelenWorkoutLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
      case 'grace':
        final GraceWorkoutLog? log = recovery.latestGraceWorkoutLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
      case 'dt':
        final DtWorkoutLog? log = recovery.latestDtWorkoutLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
      case 'death_by_burpees':
        final DeathByBurpeesLog? log = recovery.latestDeathByBurpeesLog;
        if (log != null && log.date.isAfter(checkThreshold)) {
          result = log.scoreDisplay;
        }
        break;
    }

    if (result != null) {
      setState(() {
        item.isCompleted = true;
        item.completedResult = result;
      });
      _persistDraft();
    }
  }

  Widget _buildDynamicItemsSection(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.dayTemplate.phases.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.dashboard_customize_outlined,
                  size: 16,
                  color: AppTheme.secondaryCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'DYNAMIC MOVEMENTS & WODS',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
              ],
            ),
          ),
        ],
        ...List.generate(_dynamicItems.length, (int index) {
          final DynamicWorkoutItem item = _dynamicItems[index];
          switch (item.type) {
            case DynamicItemType.wod:
              return _buildDynamicWodCard(item, index);
            case DynamicItemType.kettlebellMile:
              return _buildDynamicKettlebellMileCard(item, index, settings);
            case DynamicItemType.exercise:
            case DynamicItemType.custom:
              return _buildDynamicExerciseCard(item, index, settings);
          }
        }),
      ],
    );
  }

  Widget _buildDynamicWodCard(DynamicWorkoutItem item, int index) {
    final bool isDone = item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : AppTheme.borderColor,
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFF97316).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_circle : Icons.local_fire_department,
                  color:
                      isDone ? const Color(0xFF10B981) : const Color(0xFFF97316),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'WOD',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF97316),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (item.setScheme != null && item.setScheme!.isNotEmpty)
                          ? item.setScheme!
                          : (item.subtitle ?? ''),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                tooltip: 'Remove WOD',
                onPressed: () => _removeDynamicItem(index),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isDone) ...<Widget>[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completed: ${item.completedResult ?? "Logged"}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchWodScreen(item),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Re-open',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isLiveMode) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWodScreen(item),
                    icon: const Icon(Icons.explore, size: 18, color: Colors.black),
                    label: Text(
                      'PREVIEW WOD & STANDARDS',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWodScreen(item),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(
                      'LAUNCH LIVE WOD',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final WodDefinition wodDef = WodCatalog.allWods.firstWhere(
                      (WodDefinition w) => w.id == item.refId,
                      orElse: () => WodCatalog.allWods.first,
                    );
                    WodSetupExplainerSheet.show(context, wodDef);
                  },
                  icon: const Icon(Icons.info_outline, size: 20, color: AppTheme.secondaryCyan),
                  tooltip: 'Preview Setup & Standards',
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: () => _toggleDynamicItemCompletion(item),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Mark Done',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicKettlebellMileCard(
    DynamicWorkoutItem item,
    int index,
    SettingsProvider settings,
  ) {
    final bool isDone = item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : AppTheme.secondaryCyan.withValues(alpha: 0.3),
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : AppTheme.secondaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_circle : Icons.directions_walk,
                  color:
                      isDone ? const Color(0xFF10B981) : AppTheme.secondaryCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Kettlebell Mile Carry',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 Mile • 32kg (M) / 24kg (W) • 5 Burpees penalty per drop',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLiveMode)
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.secondaryCyan,
                  ),
                  tooltip: 'Preview Protocol',
                  onPressed: () => _showKettlebellMileProtocolModal(context),
                ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                tooltip: 'Remove Kettlebell Mile',
                onPressed: () => _removeDynamicItem(index),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!_isLiveMode)
            ElevatedButton.icon(
              onPressed: () => _showKettlebellMileProtocolModal(context),
              icon: const Icon(Icons.explore, size: 18, color: Colors.black),
              label: Text(
                'PREVIEW PROTOCOL & STANDARDS',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            InkWell(
              onTap: () => _toggleDynamicItemCompletion(item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      isDone ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isDone
                          ? const Color(0xFF10B981)
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isDone
                          ? '1 Mile Carry Completed!'
                          : 'Tap to Mark 1 Mile Complete',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? const Color(0xFF10B981)
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showKettlebellMileProtocolModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    color: AppTheme.secondaryCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Kettlebell Mile Protocol & Standards',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Loaded Carry Conditioning Standard',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _buildProtocolItem(
                      title: 'Distance Target',
                      desc: '1.0 Continuous Mile (1,609m) carried outdoors or on treadmill. Complete in < 20:00 to advance weight.',
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolItem(
                      title: 'Prescribed Loading Standards',
                      desc: 'Men: 32kg (70 lb) / Women: 24kg (53 lb), or 10%–30% of total bodyweight (farmer carry or rack carry).',
                      icon: Icons.fitness_center_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolItem(
                      title: '5 Burpees Drop Penalty Rule',
                      desc: 'Every time the kettlebells touch the floor: immediately perform 5 Chest-to-Floor Burpees before continuing the walk.',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolItem(
                      title: 'Biomechanical Posture Standards',
                      desc: 'Active shoulder retraction, ribs pulled down, neutral pelvic tilt, short rapid strides to avoid lumbar hyperextension.',
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'GOT IT, CLOSE PREVIEW',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolItem({
    required String title,
    required String desc,
    required IconData icon,
    Color color = AppTheme.secondaryCyan,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicExerciseCard(
    DynamicWorkoutItem item,
    int index,
    SettingsProvider settings,
  ) {
    final List<CompletedSet> sets =
        _exerciseSets[item.name] ?? <CompletedSet>[];
    final TextEditingController? weightCtrl = _weightControllers[item.name];
    final double targetWeight =
        double.tryParse(weightCtrl?.text ?? '0') ??
            (item.targetWeightKg ?? 0.0);
    final int targetReps = sets.isNotEmpty ? sets.first.reps : 8;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (item.subtitle != null && item.subtitle!.isNotEmpty)
                          ? item.subtitle!
                          : (item.setScheme ?? ''),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(
                      Icons.play_circle_outline,
                      size: 20,
                      color: AppTheme.secondaryCyan,
                    ),
                    tooltip: 'Watch Tutorial',
                    onPressed: () => _launchExerciseVideo(item.name),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(
                      Icons.pie_chart_outline,
                      size: 20,
                      color: AppTheme.primaryAmber,
                    ),
                    tooltip: 'Plate Loader',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            PlateModal(initialWeightKg: targetWeight),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Remove Movement',
                    onPressed: () => _removeDynamicItem(index),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Target Weight / Reps banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.fitness_center,
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
                  targetWeight > 0
                      ? '${settings.formatWeight(targetWeight)} × $targetReps reps'
                      : 'Bodyweight / Banded',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final int newSetIndex = sets.length + 1;
                      sets.add(
                        CompletedSet(
                          setIndex: newSetIndex,
                          weight: targetWeight,
                          reps: targetReps,
                          isCompleted: false,
                        ),
                      );
                    });
                    _persistDraft();
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.add_circle_outline,
                        size: 14,
                        color: AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Set',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Set chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sets.length, (int setIdx) {
              final CompletedSet setItem = sets[setIdx];
              return GestureDetector(
                onLongPress: () => _showSetEditDialog(item.name, setIdx),
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
                    setItem.weight > 0
                        ? 'Set ${setItem.setIndex}: ${settings.formatWeight(setItem.weight, includeUnit: false)} × ${setItem.reps}'
                        : 'Set ${setItem.setIndex}: BW × ${setItem.reps}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: setItem.isCompleted
                          ? Colors.black
                          : AppTheme.textPrimary,
                    ),
                  ),
                  selectedColor: AppTheme.primaryAmber,
                  backgroundColor: AppTheme.surfaceElevated,
                  onSelected: (_) => _toggleSetCompletion(item.name, setIdx),
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
  }
}
