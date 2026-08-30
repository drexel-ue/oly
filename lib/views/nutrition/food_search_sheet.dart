import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/nutrition/live_barcode_scanner_sheet.dart';
import 'package:oly/widgets/nutrition/smart_portion_drawer.dart';
import 'package:provider/provider.dart';

enum FoodSourceFilter {
  all('All Foods'),
  restaurants('Restaurants & Chains'),
  staples('Staples & Whole Foods'),
  online('USDA & Online');

  const FoodSourceFilter(this.label);
  final String label;
}

class FoodSearchSheet extends StatefulWidget {
  const FoodSearchSheet({
    super.key,
    this.defaultCategory = MealCategory.lunch,
    this.foodDatabaseService,
  });
  final MealCategory defaultCategory;
  final FoodDatabaseService? foodDatabaseService;

  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet> {
  late final FoodDatabaseService _foodService;
  late final bool _ownsFoodService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  MealCategory _selectedCategory = MealCategory.lunch;
  FoodSourceFilter _selectedFilter = FoodSourceFilter.all;
  List<FoodItem> _results = <FoodItem>[];
  List<FoodItem> _recentScans = <FoodItem>[];
  bool _isLoading = false;
  FoodItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _ownsFoodService = widget.foodDatabaseService == null;
    _foodService = widget.foodDatabaseService ?? FoodDatabaseService();
    _selectedCategory = widget.defaultCategory;
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    if (_ownsFoodService) {
      _foodService.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final StorageService storage = Provider.of<NutritionProvider>(
      context,
      listen: false,
    ).storage;
    final List<FoodItem> initial = await _foodService.searchLocalFoods('');
    if (!mounted) {
      return;
    }

    // Load recent scans from storage
    final List<String> recentCodes = storage.loadRecentScannedBarcodes();
    final Map<String, Map<String, dynamic>> cached = storage
        .loadCachedProductsJson();

    final List<FoodItem> recents = <FoodItem>[];
    for (final String code in recentCodes) {
      if (cached.containsKey(code)) {
        recents.add(
          FoodItem.fromJson(cached[code]!, defaultSource: 'open_food_facts'),
        );
      }
    }

    AppLogService.instance.info(
      'FOOD_SEARCH',
      'Initial load: ${initial.length} staple foods, ${recents.length} recent scans',
    );

    if (mounted) {
      setState(() {
        _results = initial;
        _recentScans = recents;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    _debounceTimer?.cancel();
    final String clean = query.trim();

    if (clean.isEmpty) {
      await _loadData();
      return;
    }

    AppLogService.instance.info('FOOD_SEARCH', 'Search query input: "$clean"');

    // 1. Instant local search (immediate zero-latency display)
    try {
      final List<FoodItem> local = await _foodService.searchLocalFoods(clean);
      AppLogService.instance.info(
        'FOOD_SEARCH',
        'Local SQLite search for "$clean": ${local.length} results (Top: ${local.take(3).map((FoodItem f) => "${f.name} [${f.source}]").join(", ")})',
      );
      if (mounted && _searchController.text.trim() == clean) {
        setState(() {
          _results = local;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogService.instance.warning('FOOD_SEARCH', 'Local SQLite search error for "$clean": $e');
    }

    // 2. Debounced concurrent parallel search (USDA + OpenFoodFacts)
    if (clean.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final List<FoodItem> combined = await _foodService.searchAllFoods(clean);
          AppLogService.instance.info(
            'FOOD_SEARCH',
            'Combined search for "$clean": ${combined.length} results',
          );
          if (mounted && _searchController.text.trim() == clean && combined.isNotEmpty) {
            setState(() {
              _results = combined;
            });
          }
        } catch (e) {
          AppLogService.instance.warning('FOOD_SEARCH', 'Combined search error for "$clean": $e');
        }
      });
    }
  }

  void _openLiveCameraScanner() {
    HapticFeedback.selectionClick();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                LiveBarcodeScannerSheet(defaultCategory: _selectedCategory),
          ),
        )
        .then((_) => _loadData());
  }

  List<FoodItem> get _filteredResults {
    switch (_selectedFilter) {
      case FoodSourceFilter.all:
        return _results;
      case FoodSourceFilter.restaurants:
        return _results
            .where((FoodItem i) => i.source == 'offline_restaurant')
            .toList();
      case FoodSourceFilter.staples:
        return _results
            .where(
              (FoodItem i) =>
                  i.source == 'offline_staple' ||
                  i.source == 'usda_foundation' ||
                  i.source == 'usda_sr_legacy',
            )
            .toList();
      case FoodSourceFilter.online:
        return _results
            .where(
              (FoodItem i) =>
                  i.source.startsWith('usda_') ||
                  i.source == 'usda_fooddata' ||
                  i.source == 'open_food_facts',
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FoodItem> displayList = _filteredResults;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          // Top Bar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Search Foods & Menus',
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar + Live Camera Scan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search Wingstop, Chipotle, Chicken, Oats...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
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
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  tooltip: 'Live Camera Barcode Scanner',
                  onPressed: _openLiveCameraScanner,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Recent Scans Ribbon Tray (if available and not actively querying)
          if (_recentScans.isNotEmpty && _searchController.text.isEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'RECENT SCANNED PANTRY ITEMS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.9,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${_recentScans.length} cached',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.secondaryCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _recentScans.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext ctx, int idx) {
                  final FoodItem item = _recentScans[idx];
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext modalContext) =>
                            SmartPortionDrawer(
                              key: Key(item.id),
                              initialFoodItem: item,
                              defaultCategory: _selectedCategory,
                              onAdded: () {
                                Navigator.of(modalContext).pop();
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.calories} kcal • ${item.protein}g P',
                            style: GoogleFonts.firaCode(
                              fontSize: 10,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Source Filter Chips (All, Restaurants, Staples, Online)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: FoodSourceFilter.values.map((FoodSourceFilter f) {
                final bool isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      f.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryAmber.withValues(alpha: 0.2),
                    backgroundColor: AppTheme.surfaceCard,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryAmber
                          : AppTheme.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryAmber
                          : AppTheme.borderColor,
                    ),
                    onSelected: (bool sel) {
                      setState(() => _selectedFilter = f);
                      AppLogService.instance.info(
                        'FOOD_SEARCH',
                        'Active filter: ${f.label} (${_filteredResults.length} / ${_results.length} items shown)',
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // Meal Category Chips (Breakfast, Lunch, Dinner, Snack)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: MealCategory.values.map((MealCategory cat) {
                final bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      cat.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryAmber.withValues(alpha: 0.2),
                    backgroundColor: AppTheme.surfaceCard,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryAmber
                          : AppTheme.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryAmber
                          : AppTheme.borderColor,
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Search Results List
          Expanded(
            child: _isLoading && displayList.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryAmber,
                    ),
                  )
                : displayList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.search_off,
                                size: 40,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No foods found for "${_searchController.text}"',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try searching for brands like Wingstop, Chipotle, or general foods.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: displayList.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext ctx, int idx) {
                          final FoodItem item = displayList[idx];
                          final bool isSelected = _selectedItem?.id == item.id;
                          return _buildFoodItemTile(item, isSelected);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemTile(FoodItem item, bool isSelected) {
    Color badgeColor;
    String badgeText;

    if (item.source == 'offline_restaurant') {
      badgeColor = AppTheme.primaryAmber;
      badgeText = item.brand ?? 'Restaurant';
    } else if (item.source == 'offline_staple') {
      badgeColor = AppTheme.secondaryCyan;
      badgeText = 'Staple';
    } else if (item.source == 'usda_survey_fndds') {
      badgeColor = Colors.lightGreenAccent;
      badgeText = 'USDA Survey';
    } else if (item.source == 'usda_foundation') {
      badgeColor = Colors.lightGreenAccent;
      badgeText = 'USDA Foundation';
    } else if (item.source == 'usda_sr_legacy') {
      badgeColor = Colors.lightGreenAccent;
      badgeText = 'USDA Legacy';
    } else if (item.source == 'usda_branded') {
      badgeColor = AppTheme.secondaryCyan;
      badgeText = item.brand != null && item.brand!.isNotEmpty
          ? item.brand!
          : 'Branded';
    } else if (item.source == 'usda_fooddata') {
      badgeColor = Colors.lightGreenAccent;
      badgeText = item.brand != null && item.brand!.isNotEmpty
          ? item.brand!
          : 'USDA';
    } else {
      badgeColor = Colors.orangeAccent;
      badgeText = item.brand != null && item.brand!.isNotEmpty
          ? item.brand!
          : 'OpenFoodFacts';
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryAmber.withValues(alpha: 0.12)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext modalContext) => SmartPortionDrawer(
                key: Key(item.id),
                initialFoodItem: item,
                defaultCategory: _selectedCategory,
                onAdded: () {
                  Navigator.of(modalContext).pop();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (item.brand != null && item.brand!.isNotEmpty) ...<Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item.brand!.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Text(
                            '${item.calories} kcal • ${item.protein}g P • ${item.carbs}g C • ${item.fat}g F',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${item.servingSize})',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
