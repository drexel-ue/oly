import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/exercise_database_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MobilitySwapHelper {
  /// Segments mobility exercises into suggested alternatives (same focus area or category) and others.
  static ({
    List<MobilityExerciseModel> suggested,
    List<MobilityExerciseModel> others,
  }) segmentExercises({
    required MobilityExerciseModel current,
    required List<MobilityExerciseModel> allExercises,
  }) {
    final List<MobilityExerciseModel> suggested = <MobilityExerciseModel>[];
    final List<MobilityExerciseModel> others = <MobilityExerciseModel>[];

    for (final MobilityExerciseModel ex in allExercises) {
      if (ex.id == current.id) {
        continue;
      }

      final bool isFocusMatch = ex.focusArea == current.focusArea;
      final bool isCategoryMatch = ex.category == current.category;

      if (isFocusMatch || isCategoryMatch) {
        suggested.add(ex);
      } else {
        others.add(ex);
      }
    }

    return (suggested: suggested, others: others);
  }
}

class MobilityExerciseSwapModal extends StatefulWidget {
  const MobilityExerciseSwapModal({
    required this.exercise,
    required this.onSwapSelected,
    super.key,
    this.originalExercise,
    this.onResetToOriginal,
  });
  final MobilityExerciseModel exercise;
  final MobilityExerciseModel? originalExercise;
  final ValueChanged<MobilityExerciseModel> onSwapSelected;
  final VoidCallback? onResetToOriginal;

  @override
  State<MobilityExerciseSwapModal> createState() =>
      _MobilityExerciseSwapModalState();
}

class _MobilityExerciseSwapModalState extends State<MobilityExerciseSwapModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0 = Suggested & Curated, 1 = Full Database (2,700+)

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

  bool get _isSwapped =>
      widget.originalExercise != null &&
      widget.originalExercise!.id != widget.exercise.id;

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final List<MobilityExerciseModel> allExercises =
        MobilityExerciseModel.defaultExercises();
    final ({
      List<MobilityExerciseModel> others,
      List<MobilityExerciseModel> suggested,
    }) segmentation = MobilitySwapHelper.segmentExercises(
      current: widget.exercise,
      allExercises: allExercises,
    );

    bool matchesQuery(MobilityExerciseModel ex) {
      if (_searchQuery.trim().isEmpty) {
        return true;
      }
      final String q = _searchQuery.trim().toLowerCase();
      final String normQ = q.replaceAll('baysean', 'bayesian');
      final String name = ex.name.toLowerCase();
      final String desc = ex.description.toLowerCase();
      final bool cuesMatch = ex.cues.any(
        (String c) =>
            c.toLowerCase().contains(q) || c.toLowerCase().contains(normQ),
      );
      return name.contains(q) ||
          desc.contains(q) ||
          name.contains(normQ) ||
          desc.contains(normQ) ||
          cuesMatch;
    }

    final List<MobilityExerciseModel> filteredSuggested =
        segmentation.suggested.where(matchesQuery).toList();

    final List<MobilityExerciseModel> filteredOthers =
        segmentation.others.where(matchesQuery).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.swap_horiz,
                            color: AppTheme.primaryAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Swap Movement',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select an alternative drill or accessory',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSwapped && widget.onResetToOriginal != null)
                  TextButton.icon(
                    onPressed: () {
                      widget.onResetToOriginal!();
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.restore,
                      size: 16,
                      color: Colors.orangeAccent,
                    ),
                    label: Text(
                      'Reset',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Current Movement Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.directions_run,
                  color: AppTheme.primaryAmber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'CURRENT MOVEMENT',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        widget.exercise.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    widget.exercise.durationSeconds > 0
                        ? '${widget.exercise.durationSeconds}s'
                        : '${widget.exercise.defaultSets}×${widget.exercise.defaultReps}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search 2,700+ exercises, drills & cables...',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
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
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryAmber),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tab Selector: Suggested vs Full Database (2,700+)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
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
                            'Suggested',
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
          const SizedBox(height: 10),

          // Content List
          Flexible(
            child: _selectedTabIndex == 0
                ? _buildCuratedList(
                    filteredSuggested: filteredSuggested,
                    filteredOthers: filteredOthers,
                    settings: settings,
                  )
                : _buildDatabaseList(settings),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedList({
    required List<MobilityExerciseModel> filteredSuggested,
    required List<MobilityExerciseModel> filteredOthers,
    required SettingsProvider settings,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: <Widget>[
        // Quick shortcut to Full Database if searching
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

        // Suggested Alternatives
        if (filteredSuggested.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.star,
                color: AppTheme.accentBlue,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'SUGGESTED ALTERNATIVES',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentBlue,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...filteredSuggested.map(
            (MobilityExerciseModel ex) =>
                _buildExerciseTile(ex, settings, isSuggested: true),
          ),
          const SizedBox(height: 16),
        ],

        // Other Catalog Movements
        if (filteredOthers.isNotEmpty) ...<Widget>[
          Text(
            'OTHER CATALOG MOVEMENTS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...filteredOthers.map(
            (MobilityExerciseModel ex) =>
                _buildExerciseTile(ex, settings, isSuggested: false),
          ),
        ],

        if (filteredSuggested.isEmpty && filteredOthers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'No curated movements found for "$_searchQuery".',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _buildDatabaseList(SettingsProvider settings) {
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: _dbResults.length,
      itemBuilder: (BuildContext context, int index) {
        final ExerciseDatabaseModel item = _dbResults[index];
        return _buildDatabaseTile(item, settings);
      },
    );
  }

  Widget _buildDatabaseTile(
    ExerciseDatabaseModel item,
    SettingsProvider settings,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final MobilityExerciseModel model =
                MobilityExerciseModel.fromDatabaseModel(item);
            widget.onSwapSelected(model);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
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
                              vertical: 2,
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
                              vertical: 2,
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
                      if (item.instructions != null &&
                          item.instructions!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          item.instructions!.split('\n').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.secondaryCyan,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTile(
    MobilityExerciseModel ex,
    SettingsProvider settings, {
    required bool isSuggested,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSuggested ? AppTheme.surfaceElevated : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            widget.onSwapSelected(ex);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSuggested
                    ? AppTheme.accentBlue.withValues(alpha: 0.4)
                    : AppTheme.borderColor,
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        ex.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              ex.category.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              settings.formatTextUnits(ex.description),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    ex.durationSeconds > 0
                        ? '${ex.durationSeconds}s'
                        : '${ex.defaultSets}×${ex.defaultReps}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
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
