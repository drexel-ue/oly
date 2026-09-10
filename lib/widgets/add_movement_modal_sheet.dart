import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/exercise_database_model.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/hero_wod_detail_sheet.dart';
import 'package:oly/widgets/wod_setup_explainer_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AddMovementModalSheet extends StatefulWidget {
  const AddMovementModalSheet({
    required this.onAddMovement,
    super.key,
  });

  final void Function(DynamicWorkoutItem item) onAddMovement;

  static Future<void> show(
    BuildContext context, {
    required void Function(DynamicWorkoutItem item) onAddMovement,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMovementModalSheet(onAddMovement: onAddMovement),
    );
  }

  @override
  State<AddMovementModalSheet> createState() => _AddMovementModalSheetState();
}

class _AddMovementModalSheetState extends State<AddMovementModalSheet> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customSetsController = TextEditingController(text: '3');
  final TextEditingController _customRepsController = TextEditingController(text: '8');

  final List<String> _categories = <String>[
    'All',
    'Exercise Library',
    'WODs',
    'Carries & Cardio',
    'Olympic & Strength',
    'Core & Accessories',
    'Custom',
  ];

  final List<String> _equipmentFilters = <String>[
    'All',
    'Barbell',
    'Dumbbell',
    'Cable',
    'Bodyweight',
    'Machine',
  ];

  String _selectedEquipmentFilter = 'All';
  List<ExerciseDatabaseModel> _dbResults = <ExerciseDatabaseModel>[];
  List<CrossfitHeroWod> _heroWods = <CrossfitHeroWod>[];
  bool _isSearchingDb = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadHeroWods();
  }

  Future<void> _loadHeroWods() async {
    try {
      List<CrossfitHeroWod> list =
          await ExerciseDatabaseService.instance.getHeroWods(limit: 500);
      if (list.isEmpty) {
        try {
          final String jsonStr =
              await rootBundle.loadString('assets/data/crossfit_hero_wods.json');
          final List<dynamic> decoded = jsonDecode(jsonStr);
          list = decoded
              .map((dynamic e) => CrossfitHeroWod.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _heroWods = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _customNameController.dispose();
    _customSetsController.dispose();
    _customRepsController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final String trimmed = val.trim();
    setState(() => _searchQuery = trimmed);
    _debounceTimer?.cancel();
    if (trimmed.isNotEmpty || _selectedCategory == 'Exercise Library') {
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        _performDbSearch(trimmed);
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
      String? equipment;
      if (_selectedEquipmentFilter != 'All') {
        equipment = _selectedEquipmentFilter.toLowerCase();
        if (equipment == 'bodyweight') {
          equipment = 'body weight';
        }
      }

      final List<ExerciseDatabaseModel> results =
          await ExerciseDatabaseService.instance.search(
        query,
        equipment: equipment,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _dbResults = results;
          _isSearchingDb = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingDb = false);
      }
    }
  }

  void _addDatabaseExercise(
    ExerciseDatabaseModel exercise, {
    int sets = 3,
    int reps = 8,
  }) {
    final DynamicWorkoutItem item = DynamicWorkoutItem(
      id: const Uuid().v4(),
      type: DynamicItemType.exercise,
      name: exercise.name,
      refId: exercise.id,
      setScheme: '$sets Sets of $reps Reps',
      subtitle: '${exercise.displayCategory} • ${exercise.displayTargetMuscle} • ${exercise.displayEquipment}',
      targetWeightKg: 0.0,
      data: <String, dynamic>{
        'category': exercise.category,
        'bodyPart': exercise.bodyPart,
        'targetMuscle': exercise.targetMuscle,
        'equipment': exercise.equipment,
        'instructions': exercise.instructions,
        'tips': exercise.tips,
        'source': exercise.source,
      },
    );
    _selectItem(item);
  }

  void _selectItem(DynamicWorkoutItem item) {
    HapticFeedback.selectionClick();
    widget.onAddMovement(item);
    Navigator.pop(context);
  }

  void _addCustomMovement() {
    final String name = _customNameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final int sets = int.tryParse(_customSetsController.text) ?? 3;
    final int reps = int.tryParse(_customRepsController.text) ?? 8;

    final DynamicWorkoutItem item = DynamicWorkoutItem(
      id: const Uuid().v4(),
      type: DynamicItemType.custom,
      name: name,
      setScheme: '$sets Sets of $reps Reps',
      subtitle: 'Custom Exercise ($sets × $reps)',
    );

    _selectItem(item);
  }

  void _pickRandomWod() {
    HapticFeedback.heavyImpact();
    final Random rand = Random();
    final Set<String> existingIds =
        WodCatalog.allWods.map((WodDefinition w) => w.id.toLowerCase()).toSet();
    final List<WodDefinition> allAvailable = <WodDefinition>[
      ...WodCatalog.allWods,
      ..._heroWods
          .where((CrossfitHeroWod hw) =>
              !existingIds.contains(hw.id.toLowerCase()) &&
              !existingIds.contains(hw.slug.toLowerCase()))
          .map((CrossfitHeroWod hw) => hw.toWodDefinition()),
    ];
    final WodDefinition picked =
        allAvailable[rand.nextInt(allAvailable.length)];

    final DynamicWorkoutItem item = DynamicWorkoutItem(
      id: const Uuid().v4(),
      type: DynamicItemType.wod,
      name: picked.name,
      refId: picked.id,
      subtitle: '${picked.category} • ${picked.format.displayName}',
    );

    _selectItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        children: <Widget>[
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.add_circle_outline, color: AppTheme.primaryAmber, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'ADD TO WORKOUT',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search 2.5k+ exercises, WODs, lifts, carries...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Category Chips
                SizedBox(
                  height: 34,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((String cat) {
                        final bool isSelected = _selectedCategory == cat;
                        final bool isDatabaseCat = cat == 'Exercise Library';
                        final Color activeColor = isDatabaseCat ? AppTheme.secondaryCyan : AppTheme.primaryAmber;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                              if (isDatabaseCat && _dbResults.isEmpty) {
                                _performDbSearch(_searchQuery);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.2)
                                    : AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? activeColor : AppTheme.surfaceElevated,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (isDatabaseCat) ...<Widget>[
                                      Icon(Icons.storage_rounded, size: 13, color: isSelected ? activeColor : AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      cat,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? activeColor : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // Content List
          Expanded(
            child: _selectedCategory == 'Custom'
                ? _buildCustomInputView()
                : _selectedCategory == 'Exercise Library'
                    ? _buildDatabaseLibraryView()
                    : _buildMovementListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CREATE CUSTOM MOVEMENT',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAmber,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _customNameController,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Movement Name',
              hintText: 'e.g. Farmer Walk 100m, Sled Push, Dips',
              labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _customSetsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Target Sets',
                    hintText: '3',
                    labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _customRepsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Target Reps',
                    hintText: '8',
                    labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addCustomMovement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'ADD CUSTOM MOVEMENT TO SESSION',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementListView() {
    final List<Widget> items = <Widget>[];

    final bool showWods = _selectedCategory == 'All' || _selectedCategory == 'WODs';
    final bool showCarries =
        _selectedCategory == 'All' || _selectedCategory == 'Carries & Cardio';
    final bool showLifts =
        _selectedCategory == 'All' || _selectedCategory == 'Olympic & Strength';
    final bool showAccessories =
        _selectedCategory == 'All' || _selectedCategory == 'Core & Accessories';

    // 0. Browse 2,500+ Exercise Database Shortcut (at top of 'All' when not searching)
    if (_selectedCategory == 'All' && _searchQuery.isEmpty) {
      items.add(
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = 'Exercise Library');
            if (_dbResults.isEmpty) {
              _performDbSearch('');
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppTheme.secondaryCyan.withValues(alpha: 0.15),
                  AppTheme.surfaceCard,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storage_rounded, color: AppTheme.secondaryCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Browse 2,500+ Exercise Database',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Full offline library: Barbell, dumbbell, machines & bodyweight',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.secondaryCyan, size: 14),
              ],
            ),
          ),
        ),
      );
    }

    // 1. Shuffle WOD Shortcut (at top of WODs)
    if (showWods && _searchQuery.isEmpty) {
      items.add(
        InkWell(
          onTap: _pickRandomWod,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppTheme.primaryAmber.withValues(alpha: 0.15),
                  AppTheme.surfaceCard,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shuffle_rounded, color: AppTheme.primaryAmber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Shuffle Random CrossFit WOD',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        "Picks an authentic benchmark for today's session",
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryAmber, size: 14),
              ],
            ),
          ),
        ),
      );
    }

    // 2. CrossFit Benchmark WODs
    // 2. CrossFit Benchmark WODs & Hero Memorial Workouts
    if (showWods) {
      final Set<String> catalogIds =
          WodCatalog.allWods.map((WodDefinition w) => w.id.toLowerCase()).toSet();

      for (final WodDefinition wod in WodCatalog.allWods) {
        if (_searchQuery.isNotEmpty) {
          final String q = _searchQuery.toLowerCase();
          final bool match = wod.name.toLowerCase().contains(q) ||
              wod.subtitle.toLowerCase().contains(q) ||
              wod.movementsSummary.any((String m) => m.toLowerCase().contains(q));
          if (!match) {
            continue;
          }
        }

        final bool isHero = wod.category.toLowerCase().contains('hero');

        items.add(
          _buildItemTile(
            title: wod.name,
            subtitle: '${wod.category} • ${wod.format.displayName}: ${wod.subtitle}',
            badge: isHero ? 'HERO WOD' : 'WOD',
            badgeColor: AppTheme.primaryAmber,
            icon: isHero ? Icons.military_tech_rounded : Icons.bolt_rounded,
            onAdd: () {
              _selectItem(
                DynamicWorkoutItem(
                  id: const Uuid().v4(),
                  type: DynamicItemType.wod,
                  name: wod.name,
                  refId: wod.id,
                  subtitle: '${wod.category} • ${wod.format.displayName}',
                ),
              );
            },
            onPreview: () {
              WodSetupExplainerSheet.show(
                context,
                wod,
                onAddWod: () {
                  _selectItem(
                    DynamicWorkoutItem(
                      id: const Uuid().v4(),
                      type: DynamicItemType.wod,
                      name: wod.name,
                      refId: wod.id,
                      subtitle: '${wod.category} • ${wod.format.displayName}',
                    ),
                  );
                },
              );
            },
          ),
        );
      }

      // Add all scraped Hero WODs from database
      for (final CrossfitHeroWod heroWod in _heroWods) {
        if (catalogIds.contains(heroWod.id.toLowerCase()) ||
            catalogIds.contains(heroWod.slug.toLowerCase())) {
          continue;
        }

        if (_searchQuery.isNotEmpty) {
          final String q = _searchQuery.toLowerCase();
          final bool match = heroWod.name.toLowerCase().contains(q) ||
              heroWod.subtitle.toLowerCase().contains(q) ||
              heroWod.tributeText.toLowerCase().contains(q) ||
              heroWod.movementsSummary.any((String m) => m.toLowerCase().contains(q)) ||
              heroWod.equipment.any((String e) => e.toLowerCase().contains(q));
          if (!match) {
            continue;
          }
        }

        items.add(
          _buildItemTile(
            title: heroWod.name,
            subtitle: 'Hero Benchmark • ${heroWod.format.displayName}: ${heroWod.subtitle.isNotEmpty ? heroWod.subtitle : heroWod.targetTimeOrCap}',
            badge: 'HERO WOD',
            badgeColor: AppTheme.primaryAmber,
            icon: Icons.military_tech_rounded,
            onAdd: () {
              _selectItem(
                DynamicWorkoutItem(
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
                ),
              );
            },
            onPreview: () {
              HeroWodDetailSheet.show(context, heroWod);
            },
          ),
        );
      }
    }

    // 3. Loaded Carries & Cardio Conditioning
    if (showCarries) {
      final List<Map<String, String>> carries = <Map<String, String>>[
        <String, String>{
          'name': 'Kettlebell Mile (Loaded Carry)',
          'id': 'kettlebell_mile',
          'type': 'kettlebellMile',
          'desc': '1.0 Mile @ 10%–30% Bodyweight • Speed & Incline Tracking',
        },
        <String, String>{
          'name': 'Concept2 Row (2,000m)',
          'id': 'row_2000m',
          'type': 'custom',
          'desc': '2,000m Time Trial pace effort',
        },
        <String, String>{
          'name': 'Concept2 Row (5,000m)',
          'id': 'row_5000m',
          'type': 'custom',
          'desc': '5,000m Aerobic Base pacing',
        },
        <String, String>{
          'name': 'Echo Bike (100 Calories)',
          'id': 'echo_bike_100c',
          'type': 'custom',
          'desc': '100 Calorie max-sustainable threshold effort',
        },
        <String, String>{
          'name': 'Interval Run (4 × 400m)',
          'id': 'interval_run_4x400',
          'type': 'custom',
          'desc': '400m Track intervals with 90s rest',
        },
      ];

      for (final Map<String, String> carry in carries) {
        if (_searchQuery.isNotEmpty) {
          final String q = _searchQuery.toLowerCase();
          if (!carry['name']!.toLowerCase().contains(q) &&
              !carry['desc']!.toLowerCase().contains(q)) {
            continue;
          }
        }

        final bool isKbMile = carry['type'] == 'kettlebellMile';
        final DynamicWorkoutItem carryItem = DynamicWorkoutItem(
          id: const Uuid().v4(),
          type: isKbMile ? DynamicItemType.kettlebellMile : DynamicItemType.custom,
          name: carry['name']!,
          refId: carry['id'],
          subtitle: carry['desc'],
          setScheme: isKbMile ? '1.0 Mile Carry' : 'Cardio Session',
          targetWeightKg: isKbMile ? 32.0 : 0.0,
        );

        items.add(
          _buildItemTile(
            title: carry['name']!,
            subtitle: carry['desc']!,
            badge: 'CARDIO',
            badgeColor: AppTheme.secondaryCyan,
            icon: Icons.directions_walk_rounded,
            onAdd: () => _selectItem(carryItem),
            onPreview: isKbMile
                ? _showKettlebellMileExplainer
                : () => _showMovementExplainer(
                      name: carry['name']!,
                      sets: carry['desc']!,
                      category: 'Cardio Conditioning',
                      color: AppTheme.secondaryCyan,
                      icon: Icons.directions_run_rounded,
                      itemToAdd: carryItem,
                    ),
          ),
        );
      }
    }

    // 4. Olympic & Barbell Strength Lifts
    if (showLifts) {
      final List<Map<String, String>> lifts = <Map<String, String>>[
        <String, String>{'name': 'Snatch', 'id': 'snatch', 'sets': '4 Sets of 2 Reps'},
        <String, String>{'name': 'Clean and Jerk', 'id': 'clean_and_jerk', 'sets': '4 Sets of 2 Reps'},
        <String, String>{'name': 'Back Squat', 'id': 'back_squat', 'sets': '4 Sets of 5 Reps'},
        <String, String>{'name': 'Front Squat', 'id': 'front_squat', 'sets': '3 Sets of 3 Reps'},
        <String, String>{'name': 'Overhead Squat', 'id': 'overhead_squat', 'sets': '3 Sets of 3 Reps'},
        <String, String>{'name': 'Deadlift', 'id': 'deadlift', 'sets': '3 Sets of 5 Reps'},
        <String, String>{'name': 'Power Snatch', 'id': 'power_snatch', 'sets': '4 Sets of 2 Reps'},
        <String, String>{'name': 'Power Clean', 'id': 'power_clean', 'sets': '4 Sets of 2 Reps'},
        <String, String>{'name': 'Push Press', 'id': 'push_press', 'sets': '3 Sets of 5 Reps'},
        <String, String>{'name': 'Strict Overhead Press', 'id': 'strict_press', 'sets': '3 Sets of 5 Reps'},
        <String, String>{'name': 'Snatch Pull', 'id': 'snatch_pull', 'sets': '3 Sets of 3 Reps'},
        <String, String>{'name': 'Clean Pull', 'id': 'clean_pull', 'sets': '3 Sets of 3 Reps'},
      ];

      for (final Map<String, String> lift in lifts) {
        if (_searchQuery.isNotEmpty) {
          final String q = _searchQuery.toLowerCase();
          if (!lift['name']!.toLowerCase().contains(q)) {
            continue;
          }
        }

        final DynamicWorkoutItem liftItem = DynamicWorkoutItem(
          id: const Uuid().v4(),
          type: DynamicItemType.exercise,
          name: lift['name']!,
          refId: lift['id'],
          setScheme: lift['sets'],
          subtitle: lift['sets'],
        );

        items.add(
          _buildItemTile(
            title: lift['name']!,
            subtitle: 'Olympic & Strength • ${lift['sets']!}',
            badge: 'LIFT',
            badgeColor: Colors.orangeAccent,
            icon: Icons.fitness_center_rounded,
            onAdd: () => _selectItem(liftItem),
            onPreview: () => _showMovementExplainer(
              name: lift['name']!,
              sets: lift['sets']!,
              category: 'Olympic & Strength',
              color: Colors.orangeAccent,
              icon: Icons.fitness_center_rounded,
              itemToAdd: liftItem,
            ),
          ),
        );
      }
    }

    // 5. Core & Accessory Hypertrophy
    if (showAccessories) {
      final List<Map<String, String>> accessories = <Map<String, String>>[
        <String, String>{'name': 'Cable Crunches', 'id': 'cable_crunches', 'sets': '3 Sets of 8 Reps'},
        <String, String>{'name': 'Dragon Flags', 'id': 'dragon_flags', 'sets': '3 Sets of 5 Reps'},
        <String, String>{'name': 'GHD Machine Back Extensions', 'id': 'ghd_back_extensions', 'sets': '3 Sets of 12 Reps'},
        <String, String>{'name': 'GHD Sit-Up', 'id': 'ghd_situp', 'sets': '3 Sets of 15 Reps'},
        <String, String>{'name': 'Pull-ups', 'id': 'pull_ups', 'sets': '3 Sets of 8 Reps'},
        <String, String>{'name': 'Dips (Parallel Bar / Rings)', 'id': 'dips', 'sets': '3 Sets of 8 Reps'},
        <String, String>{'name': 'Incline Dumbbell Bicep Curls', 'id': 'incline_curls', 'sets': '3 Sets of 12 Reps'},
        <String, String>{'name': 'Overhead Rope Tricep Extensions', 'id': 'rope_extensions', 'sets': '3 Sets of 15 Reps'},
        <String, String>{'name': 'Seated Leg Extensions (VMO Isolation)', 'id': 'leg_extensions', 'sets': '3 Sets of 20 Reps'},
        <String, String>{'name': 'Hanging Leg Raises', 'id': 'hanging_leg_raises', 'sets': '3 Sets of 10 Reps'},
        <String, String>{'name': 'Ab Wheel Rollouts', 'id': 'ab_wheel', 'sets': '3 Sets of 10 Reps'},
      ];

      for (final Map<String, String> acc in accessories) {
        if (_searchQuery.isNotEmpty) {
          final String q = _searchQuery.toLowerCase();
          if (!acc['name']!.toLowerCase().contains(q)) {
            continue;
          }
        }

        final DynamicWorkoutItem accItem = DynamicWorkoutItem(
          id: const Uuid().v4(),
          type: DynamicItemType.exercise,
          name: acc['name']!,
          refId: acc['id'],
          setScheme: acc['sets'],
          subtitle: acc['sets'],
        );

        items.add(
          _buildItemTile(
            title: acc['name']!,
            subtitle: 'Core & Accessory • ${acc['sets']!}',
            badge: 'CORE',
            badgeColor: Colors.greenAccent,
            icon: Icons.shield_outlined,
            onAdd: () => _selectItem(accItem),
            onPreview: () => _showMovementExplainer(
              name: acc['name']!,
              sets: acc['sets']!,
              category: 'Core & Accessory',
              color: Colors.greenAccent,
              icon: Icons.shield_outlined,
              itemToAdd: accItem,
            ),
          ),
        );
      }
    }

    // Database search results in 'All' view
    if (_selectedCategory == 'All' && _searchQuery.isNotEmpty && _dbResults.isNotEmpty) {
      items.add(
        Container(
          margin: const EdgeInsets.only(top: 14, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: <Widget>[
              const Icon(Icons.storage_rounded, size: 15, color: AppTheme.secondaryCyan),
              const SizedBox(width: 8),
              Text(
                'DATABASE MOVEMENTS (${_dbResults.length} FOUND)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondaryCyan,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );

      for (final ExerciseDatabaseModel dbModel in _dbResults) {
        items.add(_buildDatabaseItemTile(dbModel));
      }
    }

    if (items.isEmpty) {
      if (_isSearchingDb) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.secondaryCyan),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.search_off, size: 40, color: AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              'No matching movements found.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedCategory = 'Custom'),
              child: Text(
                'Create as Custom Movement',
                style: GoogleFonts.outfit(color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, int i) => items[i],
    );
  }

  void _showKettlebellMileExplainer() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk, color: AppTheme.secondaryCyan, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Kettlebell Mile Carry',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Aerobic Conditioning & Work Capacity Protocol',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildProtocolCard(
                      title: 'Distance & Benchmark Target',
                      desc: '1.0 Mile (1,609 meters) on treadmill or track. Aim to complete in under 20:00 without dropping bells.',
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolCard(
                      title: 'Prescribed Loading Standards',
                      desc: 'Rx: 32kg (70 lb) for Men, 24kg (53 lb) for Women. Alternatively, scale to 10%–30% of total bodyweight.',
                      icon: Icons.fitness_center_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolCard(
                      title: 'The Drop Penalty Rule',
                      desc: 'Every time the kettlebells touch the floor: 5 Chest-to-Floor Burpees immediately before resuming your walk.',
                      icon: Icons.warning_amber_rounded,
                      accentColor: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolCard(
                      title: 'Key Coaching & Technique Cues',
                      desc: 'Active shoulder blades pinched back and down, ribs tucked, neutral spine, quick short strides, diaphragmatic nasal breathing.',
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _selectItem(
                    DynamicWorkoutItem(
                      id: const Uuid().v4(),
                      type: DynamicItemType.kettlebellMile,
                      name: 'Kettlebell Mile (Loaded Carry)',
                      refId: 'kettlebell_mile',
                      subtitle: '1.0 Mile @ 10%–30% Bodyweight • Speed & Incline Tracking',
                      targetWeightKg: 32.0,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  'ADD KETTLEBELL MILE TO WORKOUT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovementExplainer({
    required String name,
    required String sets,
    required String category,
    required Color color,
    required IconData icon,
    required DynamicWorkoutItem itemToAdd,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '$category • $sets',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildProtocolCard(
                      title: 'Prescribed Scheme',
                      desc: '$sets with target RPE 8-9. Full set-logging and weight adjustment will be active in the session.',
                      icon: Icons.fitness_center,
                    ),
                    const SizedBox(height: 10),
                    _buildProtocolCard(
                      title: 'Technique & Video Tutorial',
                      desc: 'Watch the official video demonstration from Catalyst Athletics for movement standards and cues.',
                      icon: Icons.play_circle_outline,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final String query = '$name Catalyst Athletics weightlifting tutorial';
                        final Uri uri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.smart_display_outlined, size: 18, color: Colors.redAccent),
                      label: Text(
                        'Watch Video Tutorial on YouTube',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _selectItem(itemToAdd);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  'ADD TO WORKOUT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolCard({
    required String title,
    required String desc,
    required IconData icon,
    Color accentColor = AppTheme.secondaryCyan,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onAdd,
    VoidCallback? onPreview,
  }) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceElevated),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
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
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onPreview != null) ...<Widget>[
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.explore, size: 13, color: AppTheme.secondaryCyan),
                label: Text(
                  'PREVIEW',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryCyan,
                  side: const BorderSide(color: AppTheme.secondaryCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                '+ ADD',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseLibraryView() {
    return Column(
      children: <Widget>[
        // Equipment horizontal filter chips
        Container(
          height: 32,
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _equipmentFilters.length,
            separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 6),
            itemBuilder: (BuildContext context, int index) {
              final String eq = _equipmentFilters[index];
              final bool isSelected = _selectedEquipmentFilter == eq;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedEquipmentFilter = eq);
                  _performDbSearch(_searchQuery);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondaryCyan.withValues(alpha: 0.2)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.secondaryCyan : AppTheme.surfaceElevated,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      eq,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.secondaryCyan : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, color: AppTheme.surfaceElevated),

        Expanded(
          child: _isSearchingDb
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.secondaryCyan),
                )
              : _dbResults.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.search_off, size: 40, color: AppTheme.textSecondary),
                            const SizedBox(height: 10),
                            Text(
                              'No matching exercises found',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different keyword or equipment filter, or create a custom movement.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () => setState(() => _selectedCategory = 'Custom'),
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryAmber, size: 16),
                              label: Text(
                                'Create Custom Movement',
                                style: GoogleFonts.outfit(color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _dbResults.length,
                      itemBuilder: (BuildContext _, int i) =>
                          _buildDatabaseItemTile(_dbResults[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildDatabaseItemTile(ExerciseDatabaseModel exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, color: AppTheme.secondaryCyan, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exercise.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    if (exercise.source.toLowerCase().contains('crossfit')) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'CROSSFIT',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exercise.displayEquipment.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        exercise.displayTargetMuscle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showDatabaseExerciseExplainer(exercise),
            icon: const Icon(Icons.explore, size: 13, color: AppTheme.secondaryCyan),
            label: Text(
              'PREVIEW',
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondaryCyan,
              side: const BorderSide(color: AppTheme.secondaryCyan),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () => _addDatabaseExercise(exercise),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              '+ ADD',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatabaseExerciseExplainer(ExerciseDatabaseModel exercise) {
    HapticFeedback.mediumImpact();
    int chosenSets = 3;
    int chosenReps = 8;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext sheetContext, StateSetter setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: AppTheme.secondaryCyan, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            exercise.name,
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            '${exercise.displayCategory} • ${exercise.displayBodyPart}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    if (exercise.source.toLowerCase().contains('crossfit'))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.bolt, size: 12, color: AppTheme.primaryAmber),
                            const SizedBox(width: 4),
                            Text(
                              'CROSSFIT ESSENTIAL',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        exercise.displayEquipment.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        exercise.displayTargetMuscle.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                      ),
                    ),
                    if (exercise.mechanic != null && exercise.mechanic!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise.mechanic!.toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                    if (exercise.force != null && exercise.force!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise.force!.toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Target Sets & Reps Stepper
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.surfaceElevated),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'TARGET SETS & REPS',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryAmber,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text('Sets', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                                        Row(
                                          children: <Widget>[
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.textSecondary),
                                              onPressed: chosenSets > 1
                                                  ? () => setSheetState(() => chosenSets--)
                                                  : null,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '$chosenSets',
                                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryAmber),
                                              onPressed: chosenSets < 20
                                                  ? () => setSheetState(() => chosenSets++)
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 28, color: AppTheme.surfaceElevated, margin: const EdgeInsets.symmetric(horizontal: 14)),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text('Reps', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                                        Row(
                                          children: <Widget>[
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.textSecondary),
                                              onPressed: chosenReps > 1
                                                  ? () => setSheetState(() => chosenReps--)
                                                  : null,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '$chosenReps',
                                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryAmber),
                                              onPressed: chosenReps < 100
                                                  ? () => setSheetState(() => chosenReps++)
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final Uri uri = Uri.parse(exercise.videoUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Watch Official Coaching Demo',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Instructional video by CrossFit HQ',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, color: AppTheme.textSecondary, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (exercise.instructions != null && exercise.instructions!.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          _buildProtocolCard(
                            title: 'Step-by-Step Instructions',
                            desc: exercise.instructions!.trim(),
                            icon: Icons.format_list_numbered_rounded,
                            accentColor: AppTheme.secondaryCyan,
                          ),
                        ],

                        if (exercise.tips != null && exercise.tips!.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          _buildProtocolCard(
                            title: 'Form Cues & Tips',
                            desc: exercise.tips!.trim(),
                            icon: Icons.lightbulb_outline_rounded,
                            accentColor: Colors.orangeAccent,
                          ),
                        ],

                        if (exercise.secondaryMuscles.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.surfaceElevated),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Secondary Muscles Worked',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: exercise.secondaryMuscles.map((String m) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m.replaceAll('_', ' '),
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final String query = '${exercise.name} exercise tutorial';
                            final Uri uri = Uri.parse(
                              'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
                            );
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.smart_display_outlined, size: 18, color: Colors.redAccent),
                          label: Text(
                            'Watch Video Tutorial on YouTube',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addDatabaseExercise(exercise, sets: chosenSets, reps: chosenReps);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(
                      'ADD TO WORKOUT ($chosenSets × $chosenReps)',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
