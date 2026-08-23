import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/program_model.dart';
import '../providers/settings_provider.dart';
import '../services/warmup_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/video_player_card.dart';

class WarmupSessionScreen extends StatefulWidget {
  final DayTemplate? dayTemplate;

  const WarmupSessionScreen({super.key, this.dayTemplate});

  @override
  State<WarmupSessionScreen> createState() => _WarmupSessionScreenState();
}

class _WarmupSessionScreenState extends State<WarmupSessionScreen> {
  int _currentIndex = 0;
  final Set<String> _completedExerciseIds = {};
  late GeneratedWarmupRoutine _warmupRoutine;

  final ScrollController _phaseScrollController = ScrollController();
  final List<GlobalKey> _phaseKeys = [];

  @override
  void initState() {
    super.initState();
    _warmupRoutine = WarmupEngineService.generateWarmup(dayTemplate: widget.dayTemplate);
    _phaseKeys.addAll(
      List.generate(_warmupRoutine.phaseGroups.length, (_) => GlobalKey()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentPhase());
  }

  @override
  void dispose() {
    _phaseScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPhase() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentEx = _warmupRoutine.exercises[_currentIndex];
      int currentPhaseIndex = -1;
      for (int i = 0; i < _warmupRoutine.phaseGroups.length; i++) {
        if (_warmupRoutine.phaseGroups[i].exercises.contains(currentEx)) {
          currentPhaseIndex = i;
          break;
        }
      }

      if (currentPhaseIndex != -1 && currentPhaseIndex < _phaseKeys.length) {
        final keyContext = _phaseKeys[currentPhaseIndex].currentContext;
        if (keyContext != null) {
          Scrollable.ensureVisible(
            keyContext,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      }
    });
  }

  void _setExerciseIndex(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
    _scrollToCurrentPhase();
  }

  void _markExerciseCompleted(String id) {
    setState(() {
      _completedExerciseIds.add(id);
    });
  }

  void _nextExercise() {
    if (_currentIndex < _warmupRoutine.exercises.length - 1) {
      _setExerciseIndex(_currentIndex + 1);
    } else {
      _finishWarmup();
    }
  }

  void _prevExercise() {
    if (_currentIndex > 0) {
      _setExerciseIndex(_currentIndex - 1);
    }
  }

  void _finishWarmup() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔥 Guided Warm-Up complete! Ready to lift.'),
        backgroundColor: AppTheme.primaryAmber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final exercises = _warmupRoutine.exercises;
    final currentEx = exercises[_currentIndex];
    final progress = (_currentIndex + 1) / exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guided Olympic Warm-Up',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workout Context Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_gymnastics, color: AppTheme.primaryAmber, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'PREPPING FOR TODAY\'S SESSION',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _warmupRoutine.workoutTitle,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_warmupRoutine.diagnosticReasons.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ..._warmupRoutine.diagnosticReasons.map((reason) {
                        return Text(
                          '• ${settings.formatTextUnits(reason)}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              // 4-Phase Indicator Pill Bar (Auto-scrolls to active phase)
              SingleChildScrollView(
                controller: _phaseScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_warmupRoutine.phaseGroups.length, (index) {
                    final group = _warmupRoutine.phaseGroups[index];
                    final isCurrentGroup = group.exercises.contains(currentEx);
                    return GestureDetector(
                      key: index < _phaseKeys.length ? _phaseKeys[index] : null,
                      onTap: () {
                        final firstIndex = exercises.indexOf(group.exercises.first);
                        if (firstIndex != -1) {
                          _setExerciseIndex(firstIndex);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrentGroup ? AppTheme.primaryAmber : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isCurrentGroup ? Colors.white : AppTheme.borderColor),
                        ),
                        child: Text(
                          'P${group.phaseNumber}: ${group.title.replaceAll("Phase ${group.phaseNumber}: ", "")}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrentGroup ? Colors.black : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Stepper Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EXERCISE ${_currentIndex + 1} OF ${exercises.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentIndex > 0 ? _prevExercise : null,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: AppTheme.primaryAmber,
                      ),
                      IconButton(
                        onPressed: _nextExercise,
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        color: AppTheme.primaryAmber,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Embedded Video & Exercise Player Card
              VideoPlayerCard(
                key: ValueKey(currentEx.id),
                exercise: currentEx,
                onCompleted: () => _markExerciseCompleted(currentEx.id),
              ),
              const SizedBox(height: 24),

              // Bottom Navigation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _prevExercise,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('PREVIOUS'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton.icon(
                    onPressed: _nextExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      _currentIndex == exercises.length - 1 ? Icons.check_circle : Icons.chevron_right,
                    ),
                    label: Text(
                      _currentIndex == exercises.length - 1 ? 'START WORKOUT' : 'NEXT PREP DRILL',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
