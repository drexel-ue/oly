import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/services/injury_adaptation_service.dart';
import 'package:oly/theme/app_theme.dart';

class SessionInjuryAdaptationCard extends StatefulWidget {
  const SessionInjuryAdaptationCard({
    super.key,
    required this.dayTemplate,
    required this.activeInjuries,
    required this.currentWeek,
    required this.currentMaxes,
    required this.onApplySwaps,
    this.appliedSwaps = const <String, String>{},
  });

  final DayTemplate dayTemplate;
  final List<InjuryRecord> activeInjuries;
  final int currentWeek;
  final Map<String, double> currentMaxes;
  final Function(Map<String, String> swaps, Map<String, double> newWeights) onApplySwaps;
  final Map<String, String> appliedSwaps;

  @override
  State<SessionInjuryAdaptationCard> createState() =>
      _SessionInjuryAdaptationCardState();
}

class _SessionInjuryAdaptationCardState
    extends State<SessionInjuryAdaptationCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.activeInjuries.isEmpty) {
      return const SizedBox.shrink();
    }

    final SessionAdaptationPlan plan = InjuryAdaptationService.generateSessionPlan(
      dayTemplate: widget.dayTemplate,
      activeInjuries: widget.activeInjuries,
      currentWeek: widget.currentWeek,
      currentMaxes: widget.currentMaxes,
    );

    final bool hasRecommendations = plan.hasAdaptations;
    final int adaptedCount = plan.adaptedCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryAmber.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Banner Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.healing,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Injury Adaptive Shield Active',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.activeInjuries.length} Active',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          hasRecommendations
                              ? '$adaptedCount movement ${adaptedCount == 1 ? "swap" : "swaps"} recommended'
                              : 'Session loading aligned with active tissue tolerance',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...<Widget>[
            const Divider(color: AppTheme.borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Active Injury Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.activeInjuries.map((InjuryRecord injury) {
                      final Color stageColor = injury.stage == InjuryStage.acute
                          ? AppTheme.primaryAmber
                          : (injury.stage == InjuryStage.subacute
                              ? const Color(0xFFFF9F0A)
                              : const Color(0xFFBF5AF2));

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: stageColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              injury.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${injury.stage.label})',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: stageColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Recommendations List
                  if (hasRecommendations) ...<Widget>[
                    Text(
                      'BIOMECHANICAL SWAP RECOMMENDATIONS:',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...plan.adaptations.entries
                        .where((MapEntry<String, ExerciseAdaptationRecommendation> e) =>
                            e.value.isContraindicated)
                        .map((MapEntry<String, ExerciseAdaptationRecommendation> e) {
                      final ExerciseAdaptationRecommendation rec = e.value;
                      final bool isApplied = widget.appliedSwaps[rec.originalExerciseName] ==
                          rec.replacementName;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isApplied
                                ? AppTheme.successGreen
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              isApplied
                                  ? Icons.check_circle
                                  : Icons.swap_horizontal_circle_outlined,
                              color: isApplied
                                  ? AppTheme.successGreen
                                  : AppTheme.primaryAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        rec.originalExerciseName,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          decoration: isApplied
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 12,
                                        color: AppTheme.primaryAmber,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          rec.replacementName ?? '',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (rec.rationale.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 2),
                                    Text(
                                      rec.rationale,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 10),

                    // Apply Swaps Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_fix_high, size: 16, color: Colors.black),
                        label: Text(
                          'Apply Recommended Rehab Swaps',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAmber,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final Map<String, String> swaps = <String, String>{};
                          final Map<String, double> newWeights = <String, double>{};

                          for (final MapEntry<String, ExerciseAdaptationRecommendation> e
                              in plan.adaptations.entries) {
                            if (e.value.isContraindicated && e.value.replacementName != null) {
                              swaps[e.key] = e.value.replacementName!;
                              if (e.value.suggestedWeightKg != null) {
                                newWeights[e.key] = e.value.suggestedWeightKg!;
                              }
                            }
                          }

                          widget.onApplySwaps(swaps, newWeights);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
