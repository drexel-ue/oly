import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/recovery_provider.dart';
import '../services/recovery_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/video_player_card.dart';

class RecoverySessionScreen extends StatefulWidget {
  final GeneratedRecoveryRoutine routine;
  final bool isPreviewMode;

  const RecoverySessionScreen({
    super.key,
    required this.routine,
    this.isPreviewMode = false,
  });

  @override
  State<RecoverySessionScreen> createState() => _RecoverySessionScreenState();
}

class _RecoverySessionScreenState extends State<RecoverySessionScreen> {
  int _currentIndex = 0;
  final Set<String> _completedExerciseIds = {};
  int _readinessRating = 4; // Default 4 stars (Fresh)

  final ScrollController _phaseScrollController = ScrollController();
  final List<GlobalKey> _phaseKeys = [];

  @override
  void initState() {
    super.initState();
    _phaseKeys.addAll(
      List.generate(widget.routine.phaseGroups.length, (_) => GlobalKey()),
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
      final currentEx = widget.routine.exercises[_currentIndex];
      int currentPhaseIndex = -1;
      for (int i = 0; i < widget.routine.phaseGroups.length; i++) {
        if (widget.routine.phaseGroups[i].exercises.contains(currentEx)) {
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
    if (_currentIndex < widget.routine.exercises.length - 1) {
      _setExerciseIndex(_currentIndex + 1);
    } else {
      _showCompletionDialog();
    }
  }

  void _prevExercise() {
    if (_currentIndex > 0) {
      _setExerciseIndex(_currentIndex - 1);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.accentBlue),
              ),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: Colors.black, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recovery Complete!',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'How do your joints and muscles feel now?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Readiness Rating Selector (1 to 5 Stars)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isSelected = starValue == _readinessRating;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => _readinessRating = starValue);
                            setState(() => _readinessRating = starValue);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentBlue.withValues(alpha: 0.2)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _readinessEmoji(starValue),
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$starValue ★',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _readinessLabel(_readinessRating),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (!widget.isPreviewMode) {
                      final recoveryProvider = Provider.of<RecoveryProvider>(context, listen: false);
                      await recoveryProvider.saveCompletedSession(
                        durationMinutes: widget.routine.totalEstimatedMinutes,
                        completedExerciseIds: _completedExerciseIds.toList(),
                        readinessRating: _readinessRating,
                        diagnosticReasons: widget.routine.diagnosticReasons,
                      );
                    }
                    if (mounted) {
                      Navigator.pop(ctx); // Close dialog
                      Navigator.pop(context); // Exit recovery screen back to dashboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.isPreviewMode
                              ? '👁 Recovery Routine preview finished.'
                              : '⚡ Active Recovery Session logged successfully!'),
                          backgroundColor: AppTheme.accentBlue,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.isPreviewMode ? 'FINISH PREVIEW' : 'LOG SESSION & CLOSE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _readinessEmoji(int rating) {
    switch (rating) {
      case 1:
        return '😫';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '⚡';
      case 5:
        return '🚀';
      default:
        return '🙂';
    }
  }

  String _readinessLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Stiff / Sore';
      case 2:
        return 'Moderate Tightness';
      case 3:
        return 'Feeling Normal';
      case 4:
        return 'Fresh & Loose';
      case 5:
        return 'Primed & Ready to PR!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.routine.exercises;
    final currentEx = exercises[_currentIndex];
    final progress = (_currentIndex + 1) / exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Active Recovery Routine',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isPreviewMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, color: AppTheme.secondaryCyan, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PREVIEW MODE — Test videos, timers & form cues freely without saving.',
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
              ],
              // 5-Phase Indicator Pill Bar (Auto-scrolls to active phase)
              SingleChildScrollView(
                controller: _phaseScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.routine.phaseGroups.length, (index) {
                    final group = widget.routine.phaseGroups[index];
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
                          color: isCurrentGroup ? AppTheme.accentBlue : AppTheme.surfaceElevated,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXERCISE ${_currentIndex + 1} OF ${exercises.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
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

              // Embedded Video & Exercise Player
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
                      _currentIndex == exercises.length - 1 ? 'FINISH SESSION' : 'NEXT DRILL',
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
