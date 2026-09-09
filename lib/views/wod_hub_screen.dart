import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/death_by_burpees_log.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/fran_workout_log.dart';
import 'package:oly/models/grace_workout_log.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/jackie_workout_log.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/cindy_wod_screen.dart';
import 'package:oly/views/death_by_burpees_screen.dart';
import 'package:oly/views/dt_wod_screen.dart';
import 'package:oly/views/fran_wod_screen.dart';
import 'package:oly/views/grace_wod_screen.dart';
import 'package:oly/views/helen_wod_screen.dart';
import 'package:oly/views/jackie_wod_screen.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:provider/provider.dart';

class WodHubScreen extends StatefulWidget {
  const WodHubScreen({super.key});

  @override
  State<WodHubScreen> createState() => _WodHubScreenState();
}

class _WodHubScreenState extends State<WodHubScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterCategories = <String>[
    'All',
    'Interactive Trackers',
    'For Time',
    'AMRAP',
    'The Girls',
    'Bodyweight',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WodDefinition> get _filteredWods {
    return WodCatalog.allWods.where((WodDefinition wod) {
      // Category filter
      if (_selectedCategory == 'Interactive Trackers' && !wod.hasInteractiveTracker) {
        return false;
      }
      if (_selectedCategory == 'For Time' && wod.format != WodFormat.forTime) {
        return false;
      }
      if (_selectedCategory == 'AMRAP' && wod.format != WodFormat.amrap) {
        return false;
      }
      if (_selectedCategory == 'The Girls' && !wod.category.contains('Girls')) {
        return false;
      }
      if (_selectedCategory == 'Bodyweight' &&
          wod.equipment.any((String e) => e.contains('Barbell') || e.contains('Kettlebell') || e.contains('Rower'))) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final String q = _searchQuery.toLowerCase();
        final bool nameMatch = wod.name.toLowerCase().contains(q);
        final bool descMatch = wod.subtitle.toLowerCase().contains(q);
        final bool movementMatch =
            wod.movementsSummary.any((String m) => m.toLowerCase().contains(q));
        final bool equipMatch = wod.equipment.any((String e) => e.toLowerCase().contains(q));
        return nameMatch || descMatch || movementMatch || equipMatch;
      }

      return true;
    }).toList();
  }

  void _launchWod(WodDefinition wod, {bool isPreview = false}) {
    if (wod.id == 'cindy') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CindyWodScreen(isPreviewMode: isPreview),
        ),
      );
    } else if (wod.id == 'jackie') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => JackieWodScreen(isPreviewMode: isPreview),
        ),
      );
    } else if (wod.id == 'fran') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => FranWodScreen(isPreviewMode: isPreview),
        ),
      );
    } else if (wod.id == 'helen') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HelenWodScreen(isPreviewMode: isPreview),
        ),
      );
    } else if (wod.id == 'grace') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GraceWodScreen(isPreviewMode: isPreview),
        ),
      );
    } else if (wod.id == 'dt') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DtWodScreen(isPreviewMode: isPreview),
        ),
      );
    } else if (wod.id == 'death_by_burpees') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DeathByBurpeesScreen(isPreviewMode: isPreview),
        ),
      );
    } else {
      // Show setup explainer for WODs that don't have a dedicated live card yet
      WodSetupExplainerSheet.show(context, wod);
    }
  }

  void _showShuffleDialog() {
    HapticFeedback.heavyImpact();
    final Random random = Random();
    WodDefinition picked = WodCatalog.allWods[random.nextInt(WodCatalog.allWods.length)];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, color: AppTheme.primaryAmber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'RANDOM WOD SELECTED',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selected WOD Card
                  Container(
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
                        color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              picked.name,
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.secondaryCyan.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                picked.format.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          picked.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppTheme.surfaceElevated),
                        const SizedBox(height: 12),
                        Text(
                          'WORKOUT STRUCTURE:',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...picked.movementsSummary.map((String m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppTheme.primaryAmber,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    m,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              picked = WodCatalog.getRandomWod(excludeId: picked.id);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondaryCyan,
                            side: const BorderSide(color: AppTheme.secondaryCyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.shuffle_rounded, size: 20),
                          label: Text(
                            'REROLL',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _launchWod(picked);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: Icon(
                            picked.hasInteractiveTracker
                                ? Icons.play_arrow_rounded
                                : Icons.tips_and_updates_outlined,
                            size: 22,
                          ),
                          label: Text(
                            picked.hasInteractiveTracker ? 'START WOD' : 'VIEW SETUP',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context);
    final List<CindyWorkoutLog> cindyLogs = recovery.cindyWorkoutLogs;
    final List<JackieWorkoutLog> jackieLogs = recovery.jackieWorkoutLogs;
    final List<FranWorkoutLog> franLogs = recovery.franWorkoutLogs;
    final List<HelenWorkoutLog> helenLogs = recovery.helenWorkoutLogs;
    final List<GraceWorkoutLog> graceLogs = recovery.graceWorkoutLogs;
    final List<DtWorkoutLog> dtLogs = recovery.dtWorkoutLogs;
    final List<DeathByBurpeesLog> burpeeLogs = recovery.deathByBurpeesLogs;
    final int totalLogged = cindyLogs.length +
        jackieLogs.length +
        franLogs.length +
        helenLogs.length +
        graceLogs.length +
        dtLogs.length +
        burpeeLogs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CrossFit WOD Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.shuffle_rounded, color: AppTheme.primaryAmber),
            tooltip: 'Shuffle Random WOD',
            onPressed: _showShuffleDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top Scrollable Controls & Hero
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: <Widget>[
                  // Shuffle Hero Banner
                  _buildShuffleHeroBanner(),

                  const SizedBox(height: 12),

                  // Stats Quick Row
                  _buildStatsRow(totalLogged, recovery),

                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (String val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search WODs by name, movement, equipment...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.surfaceElevated),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.surfaceElevated),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primaryAmber),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterCategories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String cat = _filterCategories[index];
                        final bool isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                                  : AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryAmber
                                    : AppTheme.surfaceElevated,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.primaryAmber : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.surfaceElevated),

            // WOD Catalog List
            Expanded(
              child: _filteredWods.isEmpty
                  ? Center(
                      child: Text(
                        'No matching WODs found.',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredWods.length,
                      itemBuilder: (BuildContext context, int index) {
                        final WodDefinition wod = _filteredWods[index];
                        return _buildWodCard(wod, recovery);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShuffleHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryAmber.withValues(alpha: 0.4),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryAmber.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryAmber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryAmber.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.shuffle_rounded,
              color: AppTheme.primaryAmber,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'AT THE GYM?',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Shuffle Random WOD',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Instant workout setup, floor plan & pacing tips.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showShuffleDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'SHUFFLE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalLogged, RecoveryProvider recovery) {
    final CindyWorkoutLog? cindyPr = recovery.getCindyPersonalRecord();
    final JackieWorkoutLog? jackiePr = recovery.getJackiePersonalRecord();
    final FranWorkoutLog? franPr = recovery.getFranPersonalRecord();
    final HelenWorkoutLog? helenPr = recovery.getHelenPersonalRecord();
    final GraceWorkoutLog? gracePr = recovery.getGracePersonalRecord();
    final DtWorkoutLog? dtPr = recovery.getDtPersonalRecord();
    final DeathByBurpeesLog? burpeesPr = recovery.getDeathByBurpeesPersonalRecord();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _buildStatItem('LOGGED', '$totalLogged', AppTheme.textPrimary),
          const SizedBox(width: 6),
          _buildStatItem('CINDY', cindyPr != null ? '${cindyPr.completedRounds}R' : '--', AppTheme.primaryAmber),
          const SizedBox(width: 6),
          _buildStatItem('JACKIE', jackiePr != null ? jackiePr.formattedTotalTime : '--', AppTheme.secondaryCyan),
          const SizedBox(width: 6),
          _buildStatItem('FRAN', franPr != null ? franPr.formattedTotalTime : '--', Colors.greenAccent),
          const SizedBox(width: 6),
          _buildStatItem('HELEN', helenPr != null ? helenPr.formattedTotalTime : '--', Colors.orangeAccent),
          const SizedBox(width: 6),
          _buildStatItem('GRACE', gracePr != null ? gracePr.formattedTotalTime : '--', AppTheme.primaryAmber),
          const SizedBox(width: 6),
          _buildStatItem('DT', dtPr != null ? dtPr.formattedTotalTime : '--', Colors.redAccent),
          const SizedBox(width: 6),
          _buildStatItem('BURPEES', burpeesPr != null ? '${burpeesPr.completedMinutes}M' : '--', Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color accentColor) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWodCard(WodDefinition wod, RecoveryProvider recovery) {
    // Check if user has a PR for this WOD
    String? prDisplay;
    if (wod.id == 'cindy') {
      final CindyWorkoutLog? pr = recovery.getCindyPersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    } else if (wod.id == 'jackie') {
      final JackieWorkoutLog? pr = recovery.getJackiePersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    } else if (wod.id == 'fran') {
      final FranWorkoutLog? pr = recovery.getFranPersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    } else if (wod.id == 'helen') {
      final HelenWorkoutLog? pr = recovery.getHelenPersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    } else if (wod.id == 'grace') {
      final GraceWorkoutLog? pr = recovery.getGracePersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    } else if (wod.id == 'dt') {
      final DtWorkoutLog? pr = recovery.getDtPersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    } else if (wod.id == 'death_by_burpees') {
      final DeathByBurpeesLog? pr = recovery.getDeathByBurpeesPersonalRecord();
      if (pr != null) {
        prDisplay = pr.scoreDisplay;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: wod.hasInteractiveTracker
              ? AppTheme.primaryAmber.withValues(alpha: 0.3)
              : AppTheme.surfaceElevated,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      wod.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        wod.format.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (wod.hasInteractiveTracker) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.bolt, size: 12, color: AppTheme.primaryAmber),
                            const SizedBox(width: 2),
                            Text(
                              'LIVE TRACKER',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  wod.subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (prDisplay != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PR: $prDisplay',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Movements Breakdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.darkBackground.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: wod.movementsSummary.map((String m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.arrow_right, size: 16, color: AppTheme.primaryAmber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Equipment Tags
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: wod.equipment.map((String eq) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eq,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // Card Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    WodSetupExplainerSheet.show(
                      context,
                      wod,
                      onStartWod: () => _launchWod(wod),
                    );
                  },
                  icon: const Icon(Icons.tips_and_updates_outlined, size: 16),
                  label: Text(
                    'Setup Explainer',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _launchWod(wod),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(
                    wod.hasInteractiveTracker ? Icons.play_arrow_rounded : Icons.explore_outlined,
                    size: 18,
                  ),
                  label: Text(
                    wod.hasInteractiveTracker ? 'START WOD' : 'VIEW SETUP',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
