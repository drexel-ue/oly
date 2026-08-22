import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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

  const WorkoutSessionScreen({super.key, required this.dayTemplate});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final _uuid = const Uuid();
  final Map<String, List<CompletedSet>> _exerciseSets = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final TextEditingController _notesController = TextEditingController();

  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Initialize set entries for exercises
    final liftProvider = Provider.of<LiftProvider>(context, listen: false);
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    final week = programProvider.currentWeek;
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

        // Parse default number of sets (e.g. "4 Sets of 2 Reps" -> 4 sets)
        int setNum = 3;
        final match = RegExp(r'(\d+)\s+Sets').firstMatch(exercise.setScheme);
        if (match != null) {
          setNum = int.tryParse(match.group(1)!) ?? 3;
        }

        // Parse default reps
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

  Future<void> _finishWorkout() async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    final durationSecs = DateTime.now().difference(_startTime).inSeconds;

    final logs = <ExerciseLog>[];
    _exerciseSets.forEach((name, sets) {
      logs.add(
        ExerciseLog(
          exerciseName: name,
          liftId: name.toLowerCase().replaceAll(' ', '_'),
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
      logs: logs,
    );

    await programProvider.saveWorkoutSession(session);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout Logged Successfully! Great work!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = Provider.of<ProgramProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dayTemplate.title,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Week ${program.currentWeek} Periodization',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryAmber),
            ),
          ],
        ),

      ),
      body: SafeArea(
        child: Column(
          children: [
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

                    // Finish Workout Button
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
                            Text(
                              exercise.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
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
