import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_entry.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/food_database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutrition/smart_portion_drawer.dart';
import 'live_barcode_scanner_sheet.dart';

class FoodSearchSheet extends StatefulWidget {
  final MealCategory defaultCategory;

  const FoodSearchSheet({
    super.key,
    this.defaultCategory = MealCategory.lunch,
  });

  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet> {
  final FoodDatabaseService _foodService = FoodDatabaseService();
  final TextEditingController _searchController = TextEditingController();

  MealCategory _selectedCategory = MealCategory.lunch;
  List<FoodItem> _results = [];
  List<FoodItem> _recentScans = [];
  bool _isLoading = false;
  FoodItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final staples = await _foodService.getStapleFoods();

    // Load recent scans from storage
    final storage = Provider.of<NutritionProvider>(context, listen: false).storage;
    final recentCodes = storage.loadRecentScannedBarcodes();
    final cached = storage.loadCachedProductsJson();

    final List<FoodItem> recents = [];
    for (final code in recentCodes) {
      if (cached.containsKey(code)) {
        recents.add(FoodItem.fromJson(cached[code]!, defaultSource: 'open_food_facts'));
      }
    }

    if (mounted) {
      setState(() {
        _results = staples;
        _recentScans = recents;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    setState(() => _isLoading = true);
    final staples = await _foodService.searchStapleFoods(query);
    if (staples.isEmpty && query.trim().length >= 3) {
      final online = await _foodService.searchOnlineFoods(query);
      setState(() {
        _results = online;
        _isLoading = false;
      });
    } else {
      setState(() {
        _results = staples;
        _isLoading = false;
      });
    }
  }

  void _openLiveCameraScanner() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveBarcodeScannerSheet(defaultCategory: _selectedCategory),
      ),
    ).then((_) => _loadData());
  }

  @override
  void dispose() {
    _foodService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Top Bar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Search Foods & Barcodes',
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary),
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search foods (e.g. Chicken, Oats, Whey)',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  tooltip: 'Live Camera Barcode Scanner',
                  onPressed: _openLiveCameraScanner,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Recent Scans Ribbon Tray (if available)
          if (_recentScans.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT SCANNED PANTRY ITEMS',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.9, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${_recentScans.length} cached',
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold),
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
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final item = _recentScans[idx];
                  return InkWell(
                    onTap: () => setState(() => _selectedItem = item),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _selectedItem?.id == item.id ? AppTheme.primaryAmber : AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.calories} kcal • ${item.protein}g P',
                            style: GoogleFonts.firaCode(fontSize: 10, color: AppTheme.primaryAmber),
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

          // Meal Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: MealCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryAmber.withOpacity(0.2),
                    backgroundColor: AppTheme.surfaceCard,
                    labelStyle: TextStyle(color: isSelected ? AppTheme.primaryAmber : AppTheme.textSecondary),
                    side: BorderSide(color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Search Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = _results[idx];
                      final isSelected = _selectedItem?.id == item.id;
                      return _buildFoodItemTile(item, isSelected);
                    },
                  ),
          ),

          // Selected Item Smart Portion Drawer
          if (_selectedItem != null)
            SmartPortionDrawer(
              key: Key(_selectedItem!.id),
              initialFoodItem: _selectedItem!,
              defaultCategory: _selectedCategory,
              onAdded: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodItemTile(FoodItem item, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryAmber.withOpacity(0.12) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          title: Text(
            item.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          subtitle: Text(
            '${item.calories} kcal • ${item.protein}g P • ${item.carbs}g C • ${item.fat}g F (${item.servingSize})',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.source == 'offline_staple' ? AppTheme.secondaryCyan.withOpacity(0.12) : Colors.orangeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.source == 'offline_staple' ? 'Staple' : 'OpenFoodFacts',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: item.source == 'offline_staple' ? AppTheme.secondaryCyan : Colors.orangeAccent,
              ),
            ),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedItem = item);
          },
        ),
      ),
    );
  }
}
