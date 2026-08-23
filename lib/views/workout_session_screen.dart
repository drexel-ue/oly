import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/lift_model.dart';
import '../models/program_model.dart';
import '../models/workout_session.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/plate_modal.dart';
import '../widgets/rest_timer_widget.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final DayTemplate dayTemplate;
  final bool isPreviewMode;
  final int? previewWeek;

  const WorkoutSessionScreen({
    super.key,
    required this.dayTemplate,
    this.isPreviewMode = false,
    this.previewWeek,
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

  DateTime _startTime = DateTime.now();
  late bool _isLiveMode;

  int _selectedRpe = 8;
  final Set<String> _selectedJointStrains = {};

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _isLiveMode = !widget.isPreviewMode;

    final liftProvider = Provider.of<LiftProvider>(context, listen: false);
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    final week = widget.previewWeek ?? programProvider.currentWeek;
    final maxes = liftProvider.currentMaxes;

    for (var phase in widget.dayTemplate.phases) {
      for (var exercise in phase.exercises) {
        final targetKg = exercise.calculateTargetWeight(
          week: week,
          currentMaxes: maxes,
        );

        _weightControllers[exercise.name] = TextEditingController(
          text: targetKg.toStringAsFixed(1),
        );

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

  @override
  void dispose() {
    _notesController.dispose();
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
  }

  void _showSwapVariationDialog(String originalExerciseName, String currentLiftId) {
    final liftProvider = Provider.of<LiftProvider>(context, listen: false);
    final allLifts = liftProvider.lifts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Swap Movement Variation',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Replace $originalExerciseName while preserving program periodization percentages.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allLifts.length,
                  itemBuilder: (context, index) {
                    final lift = allLifts[index];
                    return ListTile(
                      title: Text(lift.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '1RM: ${lift.currentMax.toStringAsFixed(1)} kg (${lift.category.name})',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.swap_horiz, color: AppTheme.primaryAmber),
                      onTap: () {
                        setState(() {
                          _swappedExerciseNames[originalExerciseName] = lift.name;
                          // Recalculate weights based on selected lift's 1RM
                          final sets = _exerciseSets[originalExerciseName];
                          if (sets != null) {
                            final targetKg = lift.currentMax * 0.75; // Default 75%
                            _weightControllers[originalExerciseName]?.text = targetKg.toStringAsFixed(1);
                            for (int i = 0; i < sets.length; i++) {
                              sets[i] = CompletedSet(
                                setIndex: sets[i].setIndex,
                                weight: targetKg,
                                reps: sets[i].reps,
                                isCompleted: sets[i].isCompleted,
                              );
                            }
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Swapped to ${lift.name}! Weights updated.'),
                            backgroundColor: AppTheme.primaryAmber,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RPE $_selectedRpe — ${_rpeDescription(_selectedRpe)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryAmber),
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
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Targets tomorrow\'s Active Recovery day routines.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Shoulders', 'Hips', 'Lower Back', 'Knees', 'Wrists'].map((tag) {
                      final isSelected = _selectedJointStrains.contains(tag);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(tag, style: GoogleFonts.inter(fontSize: 12)),
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
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dayTemplate.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_run, color: AppTheme.primaryAmber),
            tooltip: 'Guided Warm-Up',
            onPressed: () {
              Navigator.pushNamed(context, '/warmup', arguments: widget.dayTemplate);
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: AppTheme.secondaryCyan, size: 18),
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
                    }).toList(),

                    const SizedBox(height: 16),

                    // Session Notes input
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Workout Notes (RPE, feel, fatigue)...',
                        hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
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
                          icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                          label: Text(
                            'Complete & Save Session',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                side: const BorderSide(color: AppTheme.borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text('Exit Preview', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                                    content: Text('Switched to Live Workout! You can now log your sets.'),
                                    backgroundColor: AppTheme.primaryAmber,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow, color: Colors.black),
                              label: Text('Start Live Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: AppTheme.primaryAmber,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const RestTimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(BuildContext context, PhaseTemplate phase, SettingsProvider settings) {
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
            final displayName = _swappedExerciseNames[exercise.name] ?? exercise.name;
            final sets = _exerciseSets[exercise.name] ?? [];
            final weightCtrl = _weightControllers[exercise.name];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz, size: 20, color: AppTheme.accentBlue),
                                  tooltip: 'Swap Movement Variation',
                                  onPressed: () => _showSwapVariationDialog(exercise.name, exercise.liftId),
                                ),
                              ],
                            ),
                            Text(
                              exercise.setScheme,
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // Plate Calculator Button
                      IconButton(
                        icon: const Icon(Icons.pie_chart_outline, color: AppTheme.primaryAmber),
                        tooltip: 'Plate Loader',
                        onPressed: () {
                          final currentKg = double.tryParse(weightCtrl?.text ?? '100') ?? 100.0;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => PlateModal(initialWeightKg: currentKg),
                          );
                        },
                      ),
                    ],
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
                            color: setItem.isCompleted ? Colors.black : AppTheme.textPrimary,
                          ),
                        ),
                        selectedColor: AppTheme.primaryAmber,
                        backgroundColor: AppTheme.surfaceCard,
                        onSelected: (_) => _toggleSetCompletion(exercise.name, index),
                      );
                    }),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
