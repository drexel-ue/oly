import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/mobility_exercise_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class MobilitySwapHelper {
  /// Segments mobility exercises into suggested alternatives (same focus area or category) and others.
  static ({List<MobilityExerciseModel> suggested, List<MobilityExerciseModel> others}) segmentExercises({
    required MobilityExerciseModel current,
    required List<MobilityExerciseModel> allExercises,
  }) {
    final suggested = <MobilityExerciseModel>[];
    final others = <MobilityExerciseModel>[];

    for (final ex in allExercises) {
      if (ex.id == current.id) continue;

      final isFocusMatch = ex.focusArea == current.focusArea;
      final isCategoryMatch = ex.category == current.category;

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
  final MobilityExerciseModel exercise;
  final MobilityExerciseModel? originalExercise;
  final ValueChanged<MobilityExerciseModel> onSwapSelected;
  final VoidCallback? onResetToOriginal;

  const MobilityExerciseSwapModal({
    super.key,
    required this.exercise,
    this.originalExercise,
    required this.onSwapSelected,
    this.onResetToOriginal,
  });

  @override
  State<MobilityExerciseSwapModal> createState() => _MobilityExerciseSwapModalState();
}

class _MobilityExerciseSwapModalState extends State<MobilityExerciseSwapModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSwapped =>
      widget.originalExercise != null && widget.originalExercise!.id != widget.exercise.id;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final allExercises = MobilityExerciseModel.defaultExercises();
    final segmentation = MobilitySwapHelper.segmentExercises(
      current: widget.exercise,
      allExercises: allExercises,
    );

    final filteredSuggested = segmentation.suggested.where((ex) {
      if (_searchQuery.isEmpty) return true;
      return ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredOthers = segmentation.others.where((ex) {
      if (_searchQuery.isEmpty) return true;
      return ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: AppTheme.primaryAmber, size: 20),
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
                    icon: const Icon(Icons.restore, size: 16, color: Colors.orangeAccent),
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
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
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
              border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_run, color: AppTheme.primaryAmber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search drills, mobility & accessories...',
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const SizedBox(height: 12),

          // Movement Lists
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: [
                // Suggested Alternatives
                if (filteredSuggested.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.accentBlue, size: 14),
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
                  ...filteredSuggested.map((ex) => _buildExerciseTile(ex, settings, isSuggested: true)),
                  const SizedBox(height: 16),
                ],

                // Other Catalog Movements
                if (filteredOthers.isNotEmpty) ...[
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
                  ...filteredOthers.map((ex) => _buildExerciseTile(ex, settings, isSuggested: false)),
                ],

                if (filteredSuggested.isEmpty && filteredOthers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No matching movements found for "$_searchQuery".',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
        color: isSuggested
            ? AppTheme.surfaceElevated
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            widget.onSwapSelected(ex);
            Navigator.pop(context);
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
