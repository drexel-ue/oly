import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/exercise_database_model.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ExerciseSwapHelper {
  /// Segments all lifts into suggested variations for the given exercise and other movements.
  static ({List<LiftModel> suggested, List<LiftModel> others}) segmentLifts({
    required ExerciseTemplate exercise,
    required List<LiftModel> allLifts,
  }) {
    final String lowerName = exercise.name.toLowerCase();
    final String lowerLiftId = exercise.liftId.toLowerCase();

    final bool isSnatchPullOrDeadlift =
        lowerName.contains('pull') ||
        lowerName.contains('deadlift') ||
        lowerName.contains('rdl');
    final bool isSnatch =
        (lowerName.contains('snatch') || lowerLiftId == 'snatch') &&
        !isSnatchPullOrDeadlift;
    final bool isClean =
        (lowerName.contains('clean') || lowerLiftId.contains('clean')) &&
        !lowerName.contains('squat');
    final bool isSquat =
        lowerName.contains('squat') ||
        lowerLiftId.contains('squat') ||
        lowerName.contains('lunge') ||
        lowerLiftId.contains('lunge');
    final bool isOverhead =
        lowerName.contains('press') ||
        lowerLiftId.contains('press') ||
        (lowerName.contains('jerk') && !isClean);
    final bool isPull =
        isSnatchPullOrDeadlift ||
        lowerLiftId.contains('pull') ||
        lowerLiftId.contains('deadlift') ||
        lowerLiftId.contains('rdl');

    final List<LiftModel> suggested = <LiftModel>[];
    final List<LiftModel> others = <LiftModel>[];

    for (final LiftModel lift in allLifts) {
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
      final double pct = exerciseTemplate.weekPercentages![currentWeek]!;
      return newLift.currentMax * (pct / 100.0);
    }

    if (exerciseTemplate.fixedPercentage != null) {
      return newLift.currentMax * (exerciseTemplate.fixedPercentage! / 100.0);
    }

    if (exerciseTemplate.weeklyWeightIncrementKg != null) {
      final double baseWeight = newLift.currentMax * 0.60;
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
      final double pct = exerciseTemplate.weekPercentages![currentWeek]!;
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
  const ExerciseSwapModal({
    required this.exercise,
    required this.currentWeek,
    required this.onSwapSelected,
    super.key,
    this.currentSwappedName,
    this.onResetToOriginal,
  });
  final ExerciseTemplate exercise;
  final String? currentSwappedName;
  final int currentWeek;
  final ValueChanged<LiftModel> onSwapSelected;
  final VoidCallback? onResetToOriginal;

  @override
  State<ExerciseSwapModal> createState() => _ExerciseSwapModalState();
}

class _ExerciseSwapModalState extends State<ExerciseSwapModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0 = Suggested Lifts, 1 = Full Database (2,700+)

  List<ExerciseDatabaseModel> _dbResults = <ExerciseDatabaseModel>[];
  bool _isSearchingDb = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final String trimmed = val.trim();
    setState(() => _searchQuery = trimmed);
    _debounceTimer?.cancel();
    if (trimmed.isNotEmpty || _selectedTabIndex == 1) {
      _debounceTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          _performDbSearch(trimmed);
        }
      });
    } else {
      setState(() => _dbResults = <ExerciseDatabaseModel>[]);
    }
  }

  Future<void> _performDbSearch(String query) async {
    if (!mounted) {
      return;
    }
    setState(() => _isSearchingDb = true);
    try {
      final List<ExerciseDatabaseModel> results =
          await ExerciseDatabaseService.instance.search(query, limit: 60);
      if (mounted) {
        setState(() {
          _dbResults = results;
          _isSearchingDb = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearchingDb = false);
      }
    }
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
    final LiftProvider liftProvider = Provider.of<LiftProvider>(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final List<LiftModel> allLifts = liftProvider.lifts;

    final ({List<LiftModel> others, List<LiftModel> suggested}) segmentation =
        ExerciseSwapHelper.segmentLifts(
          exercise: widget.exercise,
          allLifts: allLifts,
        );

    final String queryLower = _searchQuery.toLowerCase();
    final String queryNorm = queryLower.replaceAll('baysean', 'bayesian');

    bool matchesLift(LiftModel lift) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      final String name = lift.name.toLowerCase();
      final String cat = lift.category.name.toLowerCase();
      return name.contains(queryLower) ||
          cat.contains(queryLower) ||
          name.contains(queryNorm) ||
          cat.contains(queryNorm);
    }

    final List<LiftModel> filteredSuggested =
        segmentation.suggested.where(matchesLift).toList();

    final List<LiftModel> filteredOthers =
        segmentation.others.where(matchesLift).toList();

    final String activeDisplayName =
        widget.currentSwappedName ?? widget.exercise.name;
    final bool isCurrentlySwapped =
        widget.currentSwappedName != null &&
        widget.currentSwappedName != widget.exercise.name;

    final String periodizationDesc =
        ExerciseSwapHelper.getPercentageDescription(
          exerciseTemplate: widget.exercise,
          currentWeek: widget.currentWeek,
        );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
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
                      children: <InlineSpan>[
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.swap_horiz,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
                          backgroundColor: AppTheme.primaryAmber.withValues(
                            alpha: 0.2,
                          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search 2,700+ exercises, cables, lifts...',
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
                              _onSearchChanged('');
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

            // Tab Selector: Suggested Lifts vs Full Database (2,700+)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? AppTheme.primaryAmber.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedTabIndex == 0
                                ? Border.all(
                                    color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Suggested Lifts',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTabIndex == 0
                                    ? AppTheme.primaryAmber
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTabIndex = 1);
                          if (_dbResults.isEmpty) {
                            _performDbSearch(_searchQuery);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? AppTheme.secondaryCyan.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedTabIndex == 1
                                ? Border.all(
                                    color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.storage,
                                  size: 13,
                                  color: _selectedTabIndex == 1
                                      ? AppTheme.secondaryCyan
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Full Library (2.7k+)',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: _selectedTabIndex == 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _selectedTabIndex == 1
                                          ? AppTheme.secondaryCyan
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Content Body
            Flexible(
              child: _selectedTabIndex == 0
                  ? _buildCuratedLiftsList(
                      filteredSuggested: filteredSuggested,
                      filteredOthers: filteredOthers,
                      activeDisplayName: activeDisplayName,
                      settings: settings,
                      liftProvider: liftProvider,
                    )
                  : _buildDatabaseLiftsList(
                      settings: settings,
                      liftProvider: liftProvider,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuratedLiftsList({
    required List<LiftModel> filteredSuggested,
    required List<LiftModel> filteredOthers,
    required String activeDisplayName,
    required SettingsProvider settings,
    required LiftProvider liftProvider,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      children: <Widget>[
        // Shortcut banner to full database if matches exist
        if (_searchQuery.isNotEmpty && _dbResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppTheme.secondaryCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedTabIndex = 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.search,
                        color: AppTheme.secondaryCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Found ${_dbResults.length} matches in Full Exercise Database',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryCyan,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppTheme.secondaryCyan,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // SECTION 1: SUGGESTED VARIATIONS
        if (filteredSuggested.isNotEmpty) ...<Widget>[
          _buildSectionHeader(
            title: 'SUGGESTED SWAPS',
            icon: Icons.auto_awesome,
            iconColor: AppTheme.primaryAmber,
            count: filteredSuggested.length,
            subtitle: 'Direct variations matching movement pattern',
          ),
          const SizedBox(height: 8),
          ...filteredSuggested.map((LiftModel lift) {
            final bool isCurrent = lift.name == activeDisplayName;
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
        if (filteredOthers.isNotEmpty) ...<Widget>[
          _buildSectionHeader(
            title: 'OTHER MOVEMENTS',
            icon: Icons.fitness_center,
            iconColor: AppTheme.textSecondary,
            count: filteredOthers.length,
            subtitle: 'All catalog Olympic lifts and strength movements',
          ),
          const SizedBox(height: 8),
          ...filteredOthers.map((LiftModel lift) {
            final bool isCurrent = lift.name == activeDisplayName;
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
        if (filteredSuggested.isEmpty && filteredOthers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'No standard lifts found for "$_searchQuery".',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => setState(() => _selectedTabIndex = 1),
                    icon: const Icon(Icons.storage, size: 14),
                    label: Text(
                      'Search Full 2,700+ Database',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDatabaseLiftsList({
    required SettingsProvider settings,
    required LiftProvider liftProvider,
  }) {
    if (_isSearchingDb) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.secondaryCyan),
      );
    }

    if (_dbResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No matching exercises found in full database for "$_searchQuery".',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: _dbResults.length,
      itemBuilder: (BuildContext context, int index) {
        final ExerciseDatabaseModel item = _dbResults[index];
        final LiftModel lift = LiftModel.fromDatabaseModel(
          item,
          currentMaxes: liftProvider.currentMaxes,
        );

        final double targetKg = ExerciseSwapHelper.calculateSwappedWeight(
          newLift: lift,
          exerciseTemplate: widget.exercise,
          currentWeek: widget.currentWeek,
          currentMaxes: liftProvider.currentMaxes,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                widget.onSwapSelected(lift);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: AppTheme.secondaryCyan,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Text(
                                  item.displayEquipment.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryAmber,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Text(
                                  item.displayTargetMuscle.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimated Target: ${settings.formatWeight(targetKg)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      children: <Widget>[
        Row(
          children: <Widget>[
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
    final double targetKg = ExerciseSwapHelper.calculateSwappedWeight(
      newLift: lift,
      exerciseTemplate: widget.exercise,
      currentWeek: widget.currentWeek,
      currentMaxes: liftProvider.currentMaxes,
    );

    final Color catColor = _getCategoryColor(lift.category);
    final String catName = _formatCategoryName(lift.category);

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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
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
                    children: <Widget>[
                      Row(
                        children: <Widget>[
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
                        children: <Widget>[
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
