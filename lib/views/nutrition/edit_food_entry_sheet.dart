import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class EditFoodEntrySheet extends StatefulWidget {
  const EditFoodEntrySheet({
    required this.entry,
    super.key,
  });

  final NutritionEntry entry;

  @override
  State<EditFoodEntrySheet> createState() => _EditFoodEntrySheetState();
}

class _EditFoodEntrySheetState extends State<EditFoodEntrySheet> {
  late MealCategory _selectedCategory;
  late TextEditingController _nameController;
  late TextEditingController _calsController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _portionController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.entry.category;
    _nameController = TextEditingController(text: widget.entry.name);
    _calsController = TextEditingController(
      text: widget.entry.calories.toString(),
    );
    _proteinController = TextEditingController(
      text: widget.entry.proteinGrams == widget.entry.proteinGrams.roundToDouble()
          ? widget.entry.proteinGrams.round().toString()
          : widget.entry.proteinGrams.toString(),
    );
    _carbsController = TextEditingController(
      text: widget.entry.carbsGrams == widget.entry.carbsGrams.roundToDouble()
          ? widget.entry.carbsGrams.round().toString()
          : widget.entry.carbsGrams.toString(),
    );
    _fatController = TextEditingController(
      text: widget.entry.fatGrams == widget.entry.fatGrams.roundToDouble()
          ? widget.entry.fatGrams.round().toString()
          : widget.entry.fatGrams.toString(),
    );
    _portionController = TextEditingController(
      text: widget.entry.portion ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calsController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  void _adjustCalories(int delta) {
    HapticFeedback.selectionClick();
    final int current = int.tryParse(_calsController.text) ?? 0;
    final int next = (current + delta).clamp(0, 9999);
    setState(() {
      _calsController.text = next.toString();
    });
  }

  void _saveChanges() {
    final int cals = int.tryParse(_calsController.text) ?? 0;
    final double protein = double.tryParse(_proteinController.text) ?? 0.0;
    final double carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final double fat = double.tryParse(_fatController.text) ?? 0.0;
    final String name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.entry.name;
    final String? portion = _portionController.text.trim().isNotEmpty
        ? _portionController.text.trim()
        : null;

    final NutritionProvider nutrition = Provider.of<NutritionProvider>(
      context,
      listen: false,
    );
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(
      context,
      listen: false,
    );

    final NutritionEntry updatedEntry = widget.entry.copyWith(
      name: name,
      category: _selectedCategory,
      calories: cals,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      portion: portion,
    );

    nutrition.updateFoodEntry(
      updatedEntry,
      latestBodyComp: bodyComp.latestEntry,
    );

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Updated $name in ${_selectedCategory.displayName}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryAmber,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete() {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Row(
            children: <Widget>[
              const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Food Item',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove "${widget.entry.name}" from your daily log?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                _performDelete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performDelete() {
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(
      context,
      listen: false,
    );

    final NutritionEntry deletedItem = widget.entry;
    nutrition.deleteFoodEntry(deletedItem.id);

    Navigator.of(context).pop(); // Close edit bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted ${deletedItem.name}',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppTheme.surfaceElevated,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.primaryAmber,
          onPressed: () {
            nutrition.restoreFoodEntry(deletedItem);
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(MealCategory cat) {
    switch (cat) {
      case MealCategory.breakfast:
        return Icons.wb_sunny_outlined;
      case MealCategory.lunch:
        return Icons.restaurant_outlined;
      case MealCategory.dinner:
        return Icons.nights_stay_outlined;
      case MealCategory.snack:
        return Icons.cookie_outlined;
      case MealCategory.preWorkout:
        return Icons.bolt_outlined;
      case MealCategory.postWorkout:
        return Icons.fitness_center_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double p = double.tryParse(_proteinController.text) ?? 0.0;
    final double c = double.tryParse(_carbsController.text) ?? 0.0;
    final double f = double.tryParse(_fatController.text) ?? 0.0;
    final int macroKcal = ((p * 4) + (c * 4) + (f * 9)).round();
    final double totalMacroGrams = p + c + f;
    final int pPct = totalMacroGrams > 0 ? ((p * 4 / (macroKcal > 0 ? macroKcal : 1)) * 100).round() : 0;
    final int cPct = totalMacroGrams > 0 ? ((c * 4 / (macroKcal > 0 ? macroKcal : 1)) * 100).round() : 0;
    final int fPct = totalMacroGrams > 0 ? ((f * 9 / (macroKcal > 0 ? macroKcal : 1)) * 100).round() : 0;

    final bool movedSection = _selectedCategory != widget.entry.category;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Handle Bar
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
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: AppTheme.primaryAmber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Edit Logged Food',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section / Category Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'MEAL SECTION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.9,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (movedSection)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Moving to ${_selectedCategory.displayName}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Category Choice Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MealCategory.values.map((MealCategory cat) {
                  final bool isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        _getCategoryIcon(cat),
                        size: 16,
                        color: isSelected ? Colors.black : AppTheme.primaryAmber,
                      ),
                      label: Text(cat.displayName),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryAmber,
                      backgroundColor: AppTheme.surfaceCard,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.black : AppTheme.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryAmber
                            : AppTheme.borderColor,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Food Name Field
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Food Name',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                prefixIcon: const Icon(
                  Icons.fastfood_outlined,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryAmber,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Calories Field & Quick Stepper Buttons
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _calsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Calories (kcal)',
                      labelStyle: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryAmber,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildQuickCalButton('-50', -50, isNegative: true),
                const SizedBox(width: 4),
                _buildQuickCalButton('+50', 50),
                const SizedBox(width: 4),
                _buildQuickCalButton('+100', 100),
                const SizedBox(width: 4),
                _buildQuickCalButton('+250', 250),
              ],
            ),

            const SizedBox(height: 14),

            // Macros Grid (Protein, Carbs, Fat)
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildMacroField(
                    controller: _proteinController,
                    label: 'Protein (g)',
                    color: AppTheme.secondaryCyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroField(
                    controller: _carbsController,
                    label: 'Carbs (g)',
                    color: AppTheme.primaryAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroField(
                    controller: _fatController,
                    label: 'Fat (g)',
                    color: const Color(0xFFFF453A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Portion / Serving Notes Field
            TextField(
              controller: _portionController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Portion / Serving Notes (optional)',
                hintText: 'e.g. 200g, 1.5 cups, 1 scoop whey',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                prefixIcon: const Icon(
                  Icons.scale_outlined,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryAmber,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Macro Split & Ratio Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.pie_chart_outline,
                            size: 14,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Macro Split Energy',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'P: $pPct% • C: $cPct% • F: $fPct%',
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Visual 3-color Macro Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: <Widget>[
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
                              child: Container(color: const Color(0xFFFF453A)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (macroKcal > 0) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      'Calculated macro calories: $macroKcal kcal',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons (Save & Delete)
            Row(
              children: <Widget>[
                // Delete Button
                IconButton.filledTonal(
                  onPressed: _confirmDelete,
                  tooltip: 'Delete Food Entry',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 22),
                ),
                const SizedBox(width: 10),

                // Save Changes Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCalButton(
    String text,
    int amount, {
    bool isNegative = false,
  }) {
    return InkWell(
      onTap: () => _adjustCalories(amount),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.redAccent : AppTheme.primaryAmber,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
        filled: true,
        fillColor: AppTheme.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}
