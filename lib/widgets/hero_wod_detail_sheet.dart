import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/dt_wod_screen.dart';
import 'package:oly/widgets/log_wod_score_sheet.dart';
import 'package:oly/widgets/wod_history_sheet.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Comprehensive modal detail sheet presenting a CrossFit Hero Memorial Workout,
/// showcasing the fallen hero's tribute biography, RX prescription, and action buttons.
class HeroWodDetailSheet extends StatelessWidget {
  const HeroWodDetailSheet({
    required this.heroWod,
    this.onAddWod,
    super.key,
  });

  final CrossfitHeroWod heroWod;
  final void Function(DynamicWorkoutItem item)? onAddWod;

  static void show(
    BuildContext context,
    CrossfitHeroWod heroWod, {
    void Function(DynamicWorkoutItem item)? onAddWod,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HeroWodDetailSheet(
        heroWod: heroWod,
        onAddWod: onAddWod,
      ),
    );
  }

  void _launchInteractiveOrSetup(BuildContext context) {
    Navigator.pop(context);
    if (heroWod.slug == 'dt') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const DtWodScreen(),
        ),
      );
    } else {
      WodSetupExplainerSheet.show(context, heroWod.toWodDefinition());
    }
  }

  void _addWodToCurrentWorkout(BuildContext context) {
    final DynamicWorkoutItem item = DynamicWorkoutItem(
      id: const Uuid().v4(),
      type: DynamicItemType.wod,
      name: '${heroWod.name} (Hero WOD)',
      refId: heroWod.id,
      setScheme: heroWod.format.displayName,
      subtitle: heroWod.subtitle.isNotEmpty ? heroWod.subtitle : heroWod.category,
      targetWeightKg: 0.0,
      data: <String, dynamic>{
        'wodId': heroWod.id,
        'format': heroWod.format.name,
        'equipment': heroWod.equipment,
        'movementsSummary': heroWod.movementsSummary,
        'rawWorkoutText': heroWod.rawWorkoutText,
        'rxWeights': heroWod.rxWeights,
        'tributeText': heroWod.tributeText,
      },
    );

    HapticFeedback.heavyImpact();
    Navigator.pop(context);

    if (onAddWod != null) {
      onAddWod!(item);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${heroWod.name} to workout!',
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openOfficialCrossfitUrl() async {
    final Uri uri = Uri.parse(heroWod.sourceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.primaryAmber.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryAmber.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Top Drag Pill
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: AppTheme.primaryAmber,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          Text(
                            heroWod.name,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.primaryAmber.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              'HERO WOD',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        heroWod.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Personal Record Banner
                  Builder(
                    builder: (BuildContext ctx) {
                      final RecoveryProvider recovery = Provider.of<RecoveryProvider>(ctx);
                      final BenchmarkWodLog? pr = recovery.getBenchmarkWodPersonalRecord(heroWod.id) ??
                          recovery.getBenchmarkWodPersonalRecord(heroWod.slug);
                      String? prDisplay = pr?.scoreDisplay;
                      bool isRxPr = pr?.isRx ?? true;
                      if (prDisplay == null && (heroWod.slug == 'dt' || heroWod.id == 'dt')) {
                        final DtWorkoutLog? dtPr = recovery.getDtPersonalRecord();
                        if (dtPr != null) {
                          prDisplay = dtPr.scoreDisplay;
                          isRxPr = dtPr.scalingTier.toLowerCase() == 'rx';
                        }
                      }
                      if (prDisplay == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            WodHistorySheet.show(
                              ctx,
                              wodId: heroWod.id,
                              wodName: heroWod.name,
                              heroWod: heroWod,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.greenAccent.withValues(alpha: 0.15),
                                  AppTheme.surfaceCard,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.emoji_events_rounded, color: Colors.greenAccent, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'PERSONAL RECORD',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.greenAccent,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$prDisplay (${isRxPr ? "Rx" : "Scaled"})',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'History',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.greenAccent, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Fallen Hero Memorial Card
                  if (heroWod.tributeText.isNotEmpty) ...<Widget>[
                    _buildMemorialTributeCard(),
                    const SizedBox(height: 20),
                  ],

                  // RX'd Workout Card
                  _buildRxdWorkoutCard(),

                  const SizedBox(height: 20),

                  // Required Equipment Checklist
                  _buildEquipmentSection(),

                  if (heroWod.firstPosted != null && heroWod.firstPosted!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.history_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'First posted on CrossFit.com: ${heroWod.firstPosted}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(
                top: BorderSide(color: AppTheme.surfaceElevated),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: <Widget>[
                  // Official Crossfit Link Button
                  OutlinedButton.icon(
                    onPressed: _openOfficialCrossfitUrl,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryCyan,
                      side: const BorderSide(color: AppTheme.secondaryCyan),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      'SOURCE',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Log Score Button
                  OutlinedButton.icon(
                    onPressed: () => LogWodScoreSheet.show(context, heroWod: heroWod),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryAmber,
                      side: const BorderSide(color: AppTheme.primaryAmber),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(
                      'LOG',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Add to Workout Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addWodToCurrentWorkout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.surfaceElevated),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: Text(
                        'ADD TO SESSION',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Start or Setup Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchInteractiveOrSetup(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      icon: Icon(
                        heroWod.hasInteractiveTracker ? Icons.play_arrow_rounded : Icons.explore_outlined,
                        size: 18,
                      ),
                      label: Text(
                        heroWod.hasInteractiveTracker ? 'LIVE TRACK' : 'SETUP',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildMemorialTributeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryAmber.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.military_tech, size: 18, color: AppTheme.primaryAmber),
              const SizedBox(width: 8),
              Text(
                'FALLEN HERO MEMORIAL',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            heroWod.tributeText,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.55,
              color: AppTheme.textPrimary.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRxdWorkoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                "RX'D WORKOUT PRESCRIPTION",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryCyan,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  heroWod.format.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            heroWod.rawWorkoutText,
            style: GoogleFonts.firaCode(
              fontSize: 13,
              height: 1.6,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (heroWod.rxWeights != null && heroWod.rxWeights!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.surfaceElevated),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.fitness_center_rounded, size: 16, color: AppTheme.primaryAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prescribed Loads: ${heroWod.rxWeights}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryAmber,
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

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'EQUIPMENT NEEDED:',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: heroWod.equipment.map((String eq) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceElevated),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primaryAmber),
                  const SizedBox(width: 6),
                  Text(
                    eq,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
