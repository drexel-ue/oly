import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/theme/app_theme.dart';
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
    'WODs',
    'Carries & Cardio',
    'Olympic & Strength',
    'Core & Accessories',
    'Custom',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    _customSetsController.dispose();
    _customRepsController.dispose();
    super.dispose();
  }

  void _selectItem(DynamicWorkoutItem item) {
    HapticFeedback.mediumImpact();
    widget.onAddMovement(item);
    Navigator.pop(context);
  }

  void _addCustomMovement() {
    final String name = _customNameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final int sets = int.tryParse(_customSetsController.text.trim()) ?? 3;
    final int reps = int.tryParse(_customRepsController.text.trim()) ?? 8;

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
    final WodDefinition picked =
        WodCatalog.allWods[rand.nextInt(WodCatalog.allWods.length)];

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
                  onChanged: (String val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search WODs, lifts, carries, accessories...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
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
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Category Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String cat = _categories[index];
                      final bool isSelected = _selectedCategory == cat;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryAmber : AppTheme.surfaceElevated,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
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

          // Content List
          Expanded(
            child: _selectedCategory == 'Custom'
                ? _buildCustomInputView()
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
    if (showWods) {
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

        items.add(
          _buildItemTile(
            title: wod.name,
            subtitle: '${wod.category} • ${wod.format.displayName}: ${wod.subtitle}',
            badge: 'WOD',
            badgeColor: AppTheme.primaryAmber,
            icon: Icons.bolt_rounded,
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

    if (items.isEmpty) {
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
}
