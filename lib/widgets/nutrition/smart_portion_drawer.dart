import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_entry.dart';
import '../../providers/body_comp_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/food_database_service.dart';
import '../../theme/app_theme.dart';

class SmartPortionDrawer extends StatefulWidget {
  final FoodItem initialFoodItem;
  final MealCategory defaultCategory;
  final VoidCallback? onAdded;
  final VoidCallback? onScanAnother;

  const SmartPortionDrawer({
    super.key,
    required this.initialFoodItem,
    this.defaultCategory = MealCategory.lunch,
    this.onAdded,
    this.onScanAnother,
  });

  @override
  State<SmartPortionDrawer> createState() => _SmartPortionDrawerState();
}

class _SmartPortionDrawerState extends State<SmartPortionDrawer> {
  late FoodItem _item;
  late MealCategory _selectedCategory;
  bool _isGramsMode = false;
  double _servingMultiplier = 1.0;
  double _customGrams = 100.0;
  final TextEditingController _gramsController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.initialFoodItem;
    _selectedCategory = widget.defaultCategory;
    _customGrams = _item.servingWeightGrams > 0 ? _item.servingWeightGrams : 100.0;
    _gramsController.text = _customGrams.round().toString();
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _onGramsTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0) {
      setState(() {
        _customGrams = parsed;
        if (_item.servingWeightGrams > 0) {
          _servingMultiplier = parsed / _item.servingWeightGrams;
        }
      });
    }
  }

  void _addGrams(double delta) {
    setState(() {
      _customGrams = (_customGrams + delta).clamp(1.0, 2000.0);
      _gramsController.text = _customGrams.round().toString();
      if (_item.servingWeightGrams > 0) {
        _servingMultiplier = _customGrams / _item.servingWeightGrams;
      }
    });
  }

  void _setMultiplier(double mult) {
    setState(() {
      _servingMultiplier = mult;
      _customGrams = (_item.servingWeightGrams * mult).roundToDouble();
      _gramsController.text = _customGrams.round().toString();
    });
  }

  Future<void> _forceRefresh() async {
    if (_item.barcode == null) return;
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();

    final service = FoodDatabaseService();
    final refreshed = await service.lookupBarcode(_item.barcode!, forceRefresh: true);
    service.dispose();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        if (refreshed != null) {
          _item = refreshed;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Data refreshed from Open Food Facts'),
          backgroundColor: AppTheme.secondaryCyan,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyComp = Provider.of<BodyCompProvider>(context);
    final nutrition = Provider.of<NutritionProvider>(context, listen: false);

    final effectiveMultiplier = _isGramsMode && _item.servingWeightGrams > 0
        ? (_customGrams / _item.servingWeightGrams)
        : _servingMultiplier;

    final scaledCalories = (_item.calories * effectiveMultiplier).round();
    final scaledProtein = (_item.protein * effectiveMultiplier).toStringAsFixed(1);
    final scaledCarbs = (_item.carbs * effectiveMultiplier).toStringAsFixed(1);
    final scaledFat = (_item.fat * effectiveMultiplier).toStringAsFixed(1);
    final scaledFiber = _item.fiber != null ? (_item.fiber! * effectiveMultiplier).toStringAsFixed(1) : null;

    final pPct = _item.proteinCaloriePct.round();
    final cPct = _item.carbsCaloriePct.round();
    final fPct = _item.fatCaloriePct.round();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header & Brand & Refresh Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_item.brand != null && _item.brand!.isNotEmpty)
                        Text(
                          _item.brand!.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      Text(
                        _item.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Serving Base: ${_item.servingSize}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_item.barcode != null)
                      IconButton(
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAmber),
                              )
                            : const Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                        tooltip: 'Force Refresh from Open Food Facts',
                        onPressed: _isRefreshing ? null : _forceRefresh,
                      ),
                    if (widget.onScanAnother != null)
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryAmber),
                        tooltip: 'Scan Another Barcode',
                        onPressed: widget.onScanAnother,
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Athlete Protein Density & Macro Split Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 14, color: _item.isHighProtein ? AppTheme.successGreen : AppTheme.primaryAmber),
                          const SizedBox(width: 4),
                          Text(
                            _item.proteinDensityLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _item.isHighProtein ? AppTheme.successGreen : AppTheme.primaryAmber,
                            ),
                          ),
                          if (_item.isHighProtein) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'HIGH PROTEIN',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'P: $pPct% • C: $cPct% • F: $fPct%',
                        style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Visual 3-color Macro Split Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          if (pPct > 0)
                            Expanded(
                              flex: pPct,
                              child: Container(color: AppTheme.secondaryCyan),
                            ),
                          if (cPct > 0)
                            Expanded(
                              flex: cPct,
                              child: Container(color: AppTheme.primaryAmber),
                            ),
                          if (fPct > 0)
                            Expanded(
                              flex: fPct,
                              child: Container(color: AppTheme.warningOrange),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Portion Mode Selector & Step Increments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PORTION SIZE',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.9, color: AppTheme.textSecondary),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isGramsMode = false),
                      child: Text(
                        'By Serving',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: !_isGramsMode ? FontWeight.bold : FontWeight.normal,
                          color: !_isGramsMode ? AppTheme.primaryAmber : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _isGramsMode = true),
                      child: Text(
                        'By Grams',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: _isGramsMode ? FontWeight.bold : FontWeight.normal,
                          color: _isGramsMode ? AppTheme.primaryAmber : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mode Controls
            if (!_isGramsMode)
              Row(
                children: [0.5, 1.0, 1.5, 2.0].map((m) {
                  final isSel = _servingMultiplier == m;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        onPressed: () => _setMultiplier(m),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSel ? AppTheme.primaryAmber.withOpacity(0.18) : AppTheme.darkBackground,
                          side: BorderSide(color: isSel ? AppTheme.primaryAmber : AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          '${m}x',
                          style: GoogleFonts.outfit(
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? AppTheme.primaryAmber : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gramsController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          onChanged: _onGramsTextChanged,
                          decoration: InputDecoration(
                            suffixText: 'grams',
                            suffixStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                            filled: true,
                            fillColor: AppTheme.darkBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderColor)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [10.0, 25.0, 50.0, 100.0].map((step) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => _addGrams(step),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.darkBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  '+${step.round()}g',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

            const SizedBox(height: 14),

            // Live Macro Recalculation Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroTile('Calories', '$scaledCalories', 'kcal', AppTheme.primaryAmber),
                  _buildMacroTile('Protein', scaledProtein, 'g', AppTheme.secondaryCyan),
                  _buildMacroTile('Carbs', scaledCarbs, 'g', AppTheme.primaryAmber),
                  _buildMacroTile('Fat', scaledFat, 'g', AppTheme.warningOrange),
                  if (scaledFiber != null) _buildMacroTile('Fiber', scaledFiber, 'g', AppTheme.textSecondary),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Category Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MealCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryAmber.withOpacity(0.2),
                      backgroundColor: AppTheme.darkBackground,
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

            const SizedBox(height: 16),

            // Log Food CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final entry = _item.toNutritionEntry(
                    mealCategory: _selectedCategory,
                    servingMultiplier: _servingMultiplier,
                    customGrams: _isGramsMode ? _customGrams : null,
                  );

                  nutrition.addFoodEntry(entry, latestBodyComp: bodyComp.latestEntry);

                  if (widget.onAdded != null) {
                    widget.onAdded!();
                  } else {
                    Navigator.of(context).pop();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Logged ${entry.name} to ${_selectedCategory.displayName} ($scaledCalories kcal)'),
                      backgroundColor: AppTheme.primaryAmber,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Add to ${_selectedCategory.displayName} ($scaledCalories kcal)',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTile(String label, String val, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: val,
            style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            children: [
              TextSpan(text: ' $unit', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
