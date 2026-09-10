import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/models/cindy_workout_log.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/death_by_burpees_log.dart';
import 'package:oly/models/dt_workout_log.dart';
import 'package:oly/models/fran_workout_log.dart';
import 'package:oly/models/grace_workout_log.dart';
import 'package:oly/models/helen_workout_log.dart';
import 'package:oly/models/jackie_workout_log.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/cindy_wod_screen.dart';
import 'package:oly/views/death_by_burpees_screen.dart';
import 'package:oly/views/dt_wod_screen.dart';
import 'package:oly/views/fran_wod_screen.dart';
import 'package:oly/views/grace_wod_screen.dart';
import 'package:oly/views/helen_wod_screen.dart';
import 'package:oly/views/jackie_wod_screen.dart';
import 'package:oly/widgets/hero_wod_detail_sheet.dart';
import 'package:oly/widgets/log_wod_score_sheet.dart';
import 'package:oly/widgets/wod_history_sheet.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:provider/provider.dart';

class WodHubScreen extends StatefulWidget {
  const WodHubScreen({super.key});

  @override
  State<WodHubScreen> createState() => _WodHubScreenState();
}

class _WodHubScreenState extends State<WodHubScreen> {
  int _currentTabIndex = 0; // 0: Catalog, 1: Progress & PRs
  String _selectedCategory = 'All';
  String _leaderboardFilter = 'All'; // All, Hero WODs, Rx Only
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterCategories = <String>[
    'All',
    'Hero WODs',
    'Interactive Trackers',
    'For Time',
    'AMRAP',
    'The Girls',
    'Bodyweight',
  ];

  List<CrossfitHeroWod> _databaseHeroWods = <CrossfitHeroWod>[];
  final Map<String, CrossfitHeroWod> _heroWodsByWodId = <String, CrossfitHeroWod>{};
  bool _isLoadingHeroWods = false;

  @override
  void initState() {
    super.initState();
    _loadHeroWods();
  }

  Future<void> _loadHeroWods() async {
    setState(() => _isLoadingHeroWods = true);
    try {
      List<CrossfitHeroWod> heroWods =
          await ExerciseDatabaseService.instance.getHeroWods(limit: 500);
      if (heroWods.isEmpty) {
        try {
          final String jsonStr =
              await rootBundle.loadString('assets/data/crossfit_hero_wods.json');
          final List<dynamic> decoded = jsonDecode(jsonStr);
          heroWods = decoded
              .map((dynamic e) => CrossfitHeroWod.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _databaseHeroWods = heroWods;
          for (final CrossfitHeroWod hw in heroWods) {
            _heroWodsByWodId[hw.id.toLowerCase()] = hw;
            _heroWodsByWodId[hw.slug.toLowerCase()] = hw;
          }
          _isLoadingHeroWods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHeroWods = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WodDefinition> get _allCombinedWods {
    final Set<String> existingIds =
        WodCatalog.allWods.map((WodDefinition w) => w.id.toLowerCase()).toSet();
    return <WodDefinition>[
      ...WodCatalog.allWods,
      ..._databaseHeroWods
          .where((CrossfitHeroWod hw) =>
              !existingIds.contains(hw.id.toLowerCase()) &&
              !existingIds.contains(hw.slug.toLowerCase()))
          .map((CrossfitHeroWod hw) => hw.toWodDefinition()),
    ];
  }

  WodDefinition _getRandomWod({String? excludeId}) {
    final List<WodDefinition> pool = _allCombinedWods;
    if (pool.isEmpty) {
      return WodCatalog.allWods.first;
    }
    final List<WodDefinition> candidates =
        pool.where((WodDefinition w) => w.id != excludeId).toList();
    final List<WodDefinition> selectFrom = candidates.isNotEmpty ? candidates : pool;
    return selectFrom[Random().nextInt(selectFrom.length)];
  }

  List<WodDefinition> get _filteredWods {
    return _allCombinedWods.where((WodDefinition wod) {
      // Category filter
      if (_selectedCategory == 'Hero WODs') {
        final bool isHero = wod.category.toLowerCase().contains('hero') ||
            _heroWodsByWodId.containsKey(wod.id.toLowerCase());
        if (!isHero) {
          return false;
        }
      }
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
          wod.equipment.any((String e) =>
              e.contains('Barbell') || e.contains('Kettlebell') || e.contains('Rower'))) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final String q = _searchQuery.toLowerCase();
        final bool nameMatch = wod.name.toLowerCase().contains(q);
        final bool descMatch = wod.subtitle.toLowerCase().contains(q);
        final bool movementMatch =
            wod.movementsSummary.any((String m) => m.toLowerCase().contains(q));
        final bool equipMatch =
            wod.equipment.any((String e) => e.toLowerCase().contains(q));
        final CrossfitHeroWod? heroWod = _heroWodsByWodId[wod.id.toLowerCase()];
        final bool tributeMatch =
            heroWod != null && heroWod.tributeText.toLowerCase().contains(q);
        return nameMatch || descMatch || movementMatch || equipMatch || tributeMatch;
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
      final CrossfitHeroWod? heroWod = _heroWodsByWodId[wod.id.toLowerCase()];
      if (heroWod != null) {
        HeroWodDetailSheet.show(context, heroWod);
      } else {
        // Show setup explainer for WODs that don't have a dedicated live card yet
        WodSetupExplainerSheet.show(context, wod);
      }
    }
  }

  void _showShuffleDialog() {
    HapticFeedback.heavyImpact();
    WodDefinition picked = _getRandomWod();

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
                              picked = _getRandomWod(excludeId: picked.id);
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
                                : (_heroWodsByWodId.containsKey(picked.id.toLowerCase())
                                    ? Icons.military_tech_rounded
                                    : Icons.tips_and_updates_outlined),
                            size: 22,
                          ),
                          label: Text(
                            picked.hasInteractiveTracker
                                ? 'START WOD'
                                : (_heroWodsByWodId.containsKey(picked.id.toLowerCase())
                                    ? 'VIEW HERO WOD'
                                    : 'VIEW SETUP'),
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
    final int totalLogged = recovery.totalAllWodCompletionsCount;

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
            // Tab Selector: WOD Catalog vs Progress & PRs
            _buildTabSelector(),

            // Active Tab Content
            Expanded(
              child: _currentTabIndex == 0
                  ? _buildCatalogTab(totalLogged, recovery)
                  : _buildProgressTab(recovery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentTabIndex = 0);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _currentTabIndex == 0 ? AppTheme.primaryAmber : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 15,
                      color: _currentTabIndex == 0 ? Colors.black : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WOD CATALOG',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: _currentTabIndex == 0 ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentTabIndex = 1);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _currentTabIndex == 1 ? AppTheme.primaryAmber : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 15,
                      color: _currentTabIndex == 1 ? Colors.black : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PROGRESS & PRS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: _currentTabIndex == 1 ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab(int totalLogged, RecoveryProvider recovery) {
    return Column(
      children: <Widget>[
        // Top Scrollable Controls & Hero
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          child: _isLoadingHeroWods && _filteredWods.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryAmber),
                )
              : _filteredWods.isEmpty
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
    );
  }

  Widget _buildProgressTab(RecoveryProvider recovery) {
    final int completedHeroCount = recovery.totalCompletedHeroWodsCount;
    final double heroPercent = (completedHeroCount / 248.0).clamp(0.0, 1.0);

    String rankTitle = 'Tribute Cadet';
    if (completedHeroCount >= 100) {
      rankTitle = 'Immortal Hero';
    } else if (completedHeroCount >= 50) {
      rankTitle = 'Hero Legend';
    } else if (completedHeroCount >= 25) {
      rankTitle = 'Elite Valor';
    } else if (completedHeroCount >= 10) {
      rankTitle = 'Valor Veteran';
    } else if (completedHeroCount >= 1) {
      rankTitle = 'Tribute Warrior';
    }

    final Map<String, BenchmarkWodLog> allPrsMap = recovery.getAllBenchmarkPersonalRecords();
    List<BenchmarkWodLog> prsList = allPrsMap.values.toList();
    if (_leaderboardFilter == 'Hero WODs') {
      prsList = prsList.where((BenchmarkWodLog p) {
        final String id = p.wodId.toLowerCase();
        return p.category.toLowerCase().contains('hero') ||
            id.startsWith('cf_hero_') ||
            id == 'dt';
      }).toList();
    } else if (_leaderboardFilter == 'Rx Only') {
      prsList = prsList.where((BenchmarkWodLog p) => p.isRx).toList();
    }
    prsList.sort((BenchmarkWodLog a, BenchmarkWodLog b) => a.wodName.compareTo(b.wodName));

    final List<BenchmarkWodLog> recentLogs = recovery.benchmarkWodLogs.take(8).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        // Hero WOD Odyssey Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryAmber.withValues(alpha: 0.35),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primaryAmber.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: AppTheme.primaryAmber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'HERO WOD ODYSSEY',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$completedHeroCount of 248 Completed',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      rankTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: heroPercent,
                  backgroundColor: AppTheme.darkBackground,
                  color: AppTheme.primaryAmber,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${(heroPercent * 100).toStringAsFixed(1)}% of all Hero tributes conquered',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${248 - completedHeroCount} remaining',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // KPI Summary Row
        Row(
          children: <Widget>[
            Expanded(
              child: _buildMetricBox(
                label: 'TOTAL LOGS',
                value: '${recovery.totalAllWodCompletionsCount}',
                icon: Icons.fitness_center_rounded,
                accentColor: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricBox(
                label: 'HERO TRIBUTES',
                value: '$completedHeroCount',
                icon: Icons.military_tech_rounded,
                accentColor: AppTheme.primaryAmber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricBox(
                label: 'ALL-TIME PRS',
                value: '${allPrsMap.length}',
                icon: Icons.emoji_events_rounded,
                accentColor: Colors.greenAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Log Score Primary Action
        ElevatedButton.icon(
          onPressed: () => _showLogPickerBottomSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryAmber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
          icon: const Icon(Icons.add_task_rounded, size: 20),
          label: Text(
            '+ LOG WOD SCORE / PR',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Benchmark PR Leaderboard Header & Filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'BENCHMARK PR LEADERBOARD',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryAmber,
                letterSpacing: 1.0,
              ),
            ),
            Row(
              children: <String>['All', 'Hero WODs', 'Rx Only'].map((String f) {
                final bool isSelected = _leaderboardFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _leaderboardFilter = f);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                            : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryAmber
                              : AppTheme.surfaceElevated,
                        ),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryAmber : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // PR List
        if (prsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceElevated),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 36,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No PRs matching current filter',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Log your benchmark workout scores to build your Hall of Fame.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...prsList.map((BenchmarkWodLog pr) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    WodHistorySheet.show(
                      context,
                      wodId: pr.wodId,
                      wodName: pr.wodName,
                      wodFormat: pr.format,
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.greenAccent,
                      size: 18,
                    ),
                  ),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          pr.wodName,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pr.isRx
                              ? Colors.greenAccent.withValues(alpha: 0.15)
                              : Colors.orangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pr.isRx ? 'Rx' : 'Scaled',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: pr.isRx ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'PR: ${pr.scoreDisplay}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.greenAccent,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(pr.date),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }),

        if (recentLogs.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          Text(
            'RECENT WOD COMPLETIONS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAmber,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          ...recentLogs.map((BenchmarkWodLog log) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceElevated),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    WodHistorySheet.show(
                      context,
                      wodId: log.wodId,
                      wodName: log.wodName,
                      wodFormat: log.format,
                    );
                  },
                title: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        log.wodName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (log.isPr)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.emoji_events_rounded, size: 10, color: Colors.greenAccent),
                            const SizedBox(width: 2),
                            Text(
                              'PR',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${log.scoreDisplay} (${log.isRx ? "Rx" : "Scaled"})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(log.date),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }),
        ],
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogPickerBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setSheetState) {
            final List<WodDefinition> list = _allCombinedWods.where((WodDefinition w) {
              if (query.isEmpty) {
                return true;
              }
              final String q = query.toLowerCase();
              return w.name.toLowerCase().contains(q) ||
                  w.subtitle.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Select Workout to Log',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (String val) => setSheetState(() => query = val.trim()),
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search benchmark or Hero WOD...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.surfaceElevated),
                      itemBuilder: (BuildContext context, int index) {
                        final WodDefinition item = list[index];
                        final bool isHero = _heroWodsByWodId.containsKey(item.id.toLowerCase()) ||
                            item.category.toLowerCase().contains('hero');
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          title: Row(
                            children: <Widget>[
                              Text(
                                item.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (isHero) ...<Widget>[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'HERO',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${item.format.displayName} • ${item.subtitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.primaryAmber,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            LogWodScoreSheet.show(
                              context,
                              wodId: item.id,
                              wodName: item.name,
                              wodFormat: item.format.name,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final CrossfitHeroWod? heroWod = _heroWodsByWodId[wod.id.toLowerCase()];
    final bool isHero = heroWod != null || wod.category.toLowerCase().contains('hero');

    // Check if user has a PR for this WOD
    String? prDisplay;
    final BenchmarkWodLog? benchPr = recovery.getBenchmarkWodPersonalRecord(wod.id);
    if (benchPr != null) {
      prDisplay = benchPr.scoreDisplay;
    } else if (wod.id == 'cindy') {
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
                    if (isHero) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.military_tech_rounded, size: 12, color: AppTheme.primaryAmber),
                            const SizedBox(width: 3),
                            Text(
                              'HERO WOD',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAmber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      WodHistorySheet.show(
                        context,
                        wodId: wod.id,
                        wodName: wod.name,
                        wodFormat: wod.format.name,
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 13,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PR: $prDisplay',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.history_rounded,
                            size: 11,
                            color: Colors.greenAccent,
                          ),
                        ],
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    if (heroWod != null) {
                      HeroWodDetailSheet.show(context, heroWod);
                    } else {
                      WodSetupExplainerSheet.show(
                        context,
                        wod,
                        onStartWod: () => _launchWod(wod),
                      );
                    }
                  },
                  icon: Icon(
                    heroWod != null ? Icons.military_tech_outlined : Icons.tips_and_updates_outlined,
                    size: 16,
                    color: heroWod != null ? AppTheme.primaryAmber : AppTheme.secondaryCyan,
                  ),
                  label: Text(
                    heroWod != null ? 'Hero Tribute' : 'Setup Explainer',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: heroWod != null ? AppTheme.primaryAmber : AppTheme.secondaryCyan,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    LogWodScoreSheet.show(
                      context,
                      wodId: wod.id,
                      wodName: wod.name,
                      wodFormat: wod.format.name,
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 16, color: Colors.greenAccent),
                  label: Text(
                    'Log Score',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _launchWod(wod),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(
                    wod.hasInteractiveTracker
                        ? Icons.play_arrow_rounded
                        : (heroWod != null ? Icons.military_tech_rounded : Icons.explore_outlined),
                    size: 18,
                  ),
                  label: Text(
                    wod.hasInteractiveTracker
                        ? 'START WOD'
                        : (heroWod != null ? 'VIEW HERO WOD' : 'VIEW SETUP'),
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
