import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/lift_model.dart';
import '../models/program_model.dart';
import '../providers/lift_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class ExerciseSwapHelper {
  /// Segments all lifts into suggested variations for the given exercise and other movements.
  static ({List<LiftModel> suggested, List<LiftModel> others}) segmentLifts({
    required ExerciseTemplate exercise,
    required List<LiftModel> allLifts,
  }) {
    final lowerName = exercise.name.toLowerCase();
    final lowerLiftId = exercise.liftId.toLowerCase();

    final isSnatchPullOrDeadlift = lowerName.contains('pull') ||
        lowerName.contains('deadlift') ||
        lowerName.contains('rdl');
    final isSnatch = (lowerName.contains('snatch') || lowerLiftId == 'snatch') &&
        !isSnatchPullOrDeadlift;
    final isClean =
        (lowerName.contains('clean') || lowerLiftId.contains('clean')) &&
            !lowerName.contains('squat');
    final isSquat = lowerName.contains('squat') ||
        lowerLiftId.contains('squat') ||
        lowerName.contains('lunge') ||
        lowerLiftId.contains('lunge');
    final isOverhead = lowerName.contains('press') ||
        lowerLiftId.contains('press') ||
        (lowerName.contains('jerk') && !isClean);
    final isPull = isSnatchPullOrDeadlift ||
        lowerLiftId.contains('pull') ||
        lowerLiftId.contains('deadlift') ||
        lowerLiftId.contains('rdl');

    final suggested = <LiftModel>[];
    final others = <LiftModel>[];

    for (final lift in allLifts) {
      bool isMatch = false;

      if (isSnatch) {
        if (lift.category == LiftCategory.snatch) {
          isMatch = true;
        }
      } else if (isClean) {
        if (lift.category == LiftCategory.cleanAndJerk) {
          isMatch = true;
        }
      } else if (isSquat) {
        if (lift.category == LiftCategory.squat) {
          isMatch = true;
        }
      } else if (isOverhead) {
        if (lift.category == LiftCategory.overhead) {
          isMatch = true;
        }
      } else if (isPull) {
        if (lift.category == LiftCategory.pull) {
          isMatch = true;
        }
      } else {
        if (lift.id == exercise.liftId ||
            lift.anchorLiftId == exercise.liftId ||
            (exercise.anchorLiftId != null &&
                lift.anchorLiftId == exercise.anchorLiftId)) {
          isMatch = true;
        }
      }

      if (isMatch) {
        suggested.add(lift);
      } else {
        others.add(lift);
      }
    }

    return (suggested: suggested, others: others);
  }

  /// Calculates the appropriate working weight when swapping to a new lift,
  /// preserving the original exercise periodization percentage for the current week.
  static double calculateSwappedWeight({
    required LiftModel newLift,
    required ExerciseTemplate exerciseTemplate,
    required int currentWeek,
    required Map<String, double> currentMaxes,
  }) {
    if (exerciseTemplate.weekPercentages != null &&
        exerciseTemplate.weekPercentages!.containsKey(currentWeek)) {
      final pct = exerciseTemplate.weekPercentages![currentWeek]!;
      return newLift.currentMax * (pct / 100.0);
    }

    if (exerciseTemplate.fixedPercentage != null) {
      return newLift.currentMax * (exerciseTemplate.fixedPercentage! / 100.0);
    }

    if (exerciseTemplate.weeklyWeightIncrementKg != null) {
      final baseWeight = newLift.currentMax * 0.60;
      return baseWeight +
          ((currentWeek - 1) * exerciseTemplate.weeklyWeightIncrementKg!);
    }

    return newLift.currentMax * 0.75;
  }

  /// Returns a human-readable description of the periodization percentage rule.
  static String getPercentageDescription({
    required ExerciseTemplate exerciseTemplate,
    required int currentWeek,
  }) {
    if (exerciseTemplate.weekPercentages != null &&
        exerciseTemplate.weekPercentages!.containsKey(currentWeek)) {
      final pct = exerciseTemplate.weekPercentages![currentWeek]!;
      return '${pct.toStringAsFixed(0)}%';
    }

    if (exerciseTemplate.fixedPercentage != null) {
      return '${exerciseTemplate.fixedPercentage!.toStringAsFixed(0)}%';
    }

    if (exerciseTemplate.weeklyWeightIncrementKg != null) {
      return 'Base 60% + ${exerciseTemplate.weeklyWeightIncrementKg}kg/wk';
    }

    return '75%';
  }
}

class ExerciseSwapModal extends StatefulWidget {
  final ExerciseTemplate exercise;
  final String? currentSwappedName;
  final int currentWeek;
  final ValueChanged<LiftModel> onSwapSelected;
  final VoidCallback? onResetToOriginal;

  const ExerciseSwapModal({
    super.key,
    required this.exercise,
    this.currentSwappedName,
    required this.currentWeek,
    required this.onSwapSelected,
    this.onResetToOriginal,
  });

  @override
  State<ExerciseSwapModal> createState() => _ExerciseSwapModalState();
}

class _ExerciseSwapModalState extends State<ExerciseSwapModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(LiftCategory category) {
    switch (category) {
      case LiftCategory.snatch:
        return AppTheme.primaryAmber;
      case LiftCategory.cleanAndJerk:
        return AppTheme.secondaryCyan;
      case LiftCategory.squat:
        return AppTheme.successGreen;
      case LiftCategory.overhead:
        return const Color(0xFFBF5AF2);
      case LiftCategory.pull:
        return const Color(0xFFFF7A45);
      case LiftCategory.accessory:
        return AppTheme.textSecondary;
    }
  }

  String _formatCategoryName(LiftCategory category) {
    switch (category) {
      case LiftCategory.snatch:
        return 'SNATCH';
      case LiftCategory.cleanAndJerk:
        return 'CLEAN & JERK';
      case LiftCategory.squat:
        return 'SQUAT';
      case LiftCategory.overhead:
        return 'OVERHEAD';
      case LiftCategory.pull:
        return 'PULL';
      case LiftCategory.accessory:
        return 'ACCESSORY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final liftProvider = Provider.of<LiftProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final allLifts = liftProvider.lifts;

    final segmentation = ExerciseSwapHelper.segmentLifts(
      exercise: widget.exercise,
      allLifts: allLifts,
    );

    final filteredSuggested = segmentation.suggested.where((lift) {
      if (_searchQuery.isEmpty) return true;
      return lift.name.toLowerCase().contains(_searchQuery) ||
          lift.category.name.toLowerCase().contains(_searchQuery);
    }).toList();

    final filteredOthers = segmentation.others.where((lift) {
      if (_searchQuery.isEmpty) return true;
      return lift.name.toLowerCase().contains(_searchQuery) ||
          lift.category.name.toLowerCase().contains(_searchQuery);
    }).toList();

    final activeDisplayName = widget.currentSwappedName ?? widget.exercise.name;
    final isCurrentlySwapped = widget.currentSwappedName != null &&
        widget.currentSwappedName != widget.exercise.name;

    final periodizationDesc = ExerciseSwapHelper.getPercentageDescription(
      exerciseTemplate: widget.exercise,
      currentWeek: widget.currentWeek,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Swap Movement Variation',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Targeting: '),
                        TextSpan(
                          text: widget.exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' • Periodization: $periodizationDesc',
                          style: const TextStyle(
                            color: AppTheme.primaryAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // If already swapped, show Active Swap banner with Reset option
            if (isCurrentlySwapped)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Swap: $activeDisplayName',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                          Text(
                            'Original was ${widget.exercise.name}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onResetToOriginal != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          backgroundColor:
                              AppTheme.primaryAmber.withValues(alpha: 0.2),
                          foregroundColor: AppTheme.primaryAmber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          widget.onResetToOriginal!();
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search variations (e.g. Hang, Front, Power)...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Scrollable List of Segmented Exercises
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                children: [
                  // SECTION 1: SUGGESTED VARIATIONS
                  if (filteredSuggested.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'SUGGESTED SWAPS',
                      icon: Icons.auto_awesome,
                      iconColor: AppTheme.primaryAmber,
                      count: filteredSuggested.length,
                      subtitle: 'Direct variations matching movement pattern',
                    ),
                    const SizedBox(height: 8),
                    ...filteredSuggested.map((lift) {
                      final isCurrent = lift.name == activeDisplayName;
                      return _buildLiftTile(
                        context: context,
                        lift: lift,
                        isCurrent: isCurrent,
                        isSuggested: true,
                        settings: settings,
                        liftProvider: liftProvider,
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // SECTION 2: OTHER MOVEMENTS
                  if (filteredOthers.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'OTHER MOVEMENTS',
                      icon: Icons.fitness_center,
                      iconColor: AppTheme.textSecondary,
                      count: filteredOthers.length,
                      subtitle: 'All catalog Olympic lifts and strength movements',
                    ),
                    const SizedBox(height: 8),
                    ...filteredOthers.map((lift) {
                      final isCurrent = lift.name == activeDisplayName;
                      return _buildLiftTile(
                        context: context,
                        lift: lift,
                        isCurrent: isCurrent,
                        isSuggested: false,
                        settings: settings,
                        liftProvider: liftProvider,
                      );
                    }),
                  ],

                  // Empty State
                  if (filteredSuggested.isEmpty && filteredOthers.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No movements found for "$_searchQuery"',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: iconColor == AppTheme.primaryAmber
                    ? AppTheme.primaryAmber
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLiftTile({
    required BuildContext context,
    required LiftModel lift,
    required bool isCurrent,
    required bool isSuggested,
    required SettingsProvider settings,
    required LiftProvider liftProvider,
  }) {
    final targetKg = ExerciseSwapHelper.calculateSwappedWeight(
      newLift: lift,
      exerciseTemplate: widget.exercise,
      currentWeek: widget.currentWeek,
      currentMaxes: liftProvider.currentMaxes,
    );

    final catColor = _getCategoryColor(lift.category);
    final catName = _formatCategoryName(lift.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primaryAmber.withValues(alpha: 0.1)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primaryAmber
              : isSuggested
                  ? AppTheme.borderColor.withValues(alpha: 0.9)
                  : AppTheme.borderColor.withValues(alpha: 0.5),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onSwapSelected(lift);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Left Indicator Strip / Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      lift.category == LiftCategory.snatch
                          ? Icons.fitness_center
                          : lift.category == LiftCategory.squat
                              ? Icons.directions_walk
                              : Icons.sports_gymnastics,
                      color: catColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle: Lift Info & Periodization Target
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              lift.name,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? AppTheme.primaryAmber
                                    : AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              catName,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '1RM: ${settings.formatWeight(lift.currentMax)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Target: ${settings.formatWeight(targetKg)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right: Action / Status Badge
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CURRENT',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSuggested
                          ? AppTheme.primaryAmber.withValues(alpha: 0.15)
                          : AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: isSuggested
                          ? AppTheme.primaryAmber
                          : AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
