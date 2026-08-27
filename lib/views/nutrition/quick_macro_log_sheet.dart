import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_entry.dart';
import '../../providers/body_comp_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../theme/app_theme.dart';

class QuickMacroLogSheet extends StatefulWidget {
  final MealCategory defaultCategory;

  const QuickMacroLogSheet({
    super.key,
    this.defaultCategory = MealCategory.snack,
  });

  @override
  State<QuickMacroLogSheet> createState() => _QuickMacroLogSheetState();
}

class _QuickMacroLogSheetState extends State<QuickMacroLogSheet> {
  late MealCategory _selectedCategory;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _portionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
    _nameController.text = _selectedCategory.displayName;
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

  void _addCalories(int delta) {
    final current = int.tryParse(_calsController.text) ?? 0;
    final next = (current + delta).clamp(0, 5000);
    _calsController.text = next.toString();
  }

  void _saveLog() {
    final cals = int.tryParse(_calsController.text) ?? 0;
    if (cals <= 0) return;

    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _selectedCategory.displayName;

    final nutrition = Provider.of<NutritionProvider>(context, listen: false);
    final bodyComp = Provider.of<BodyCompProvider>(context, listen: false);

    nutrition.addFoodEntry(
      NutritionEntry.create(
        name: name,
        calories: cals,
        proteinGrams: protein,
        carbsGrams: carbs,
        fatGrams: fat,
        category: _selectedCategory,
        portion: _portionController.text.trim().isNotEmpty ? _portionController.text.trim() : null,
      ),
      latestBodyComp: bodyComp.latestEntry,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
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
          children: [
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
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Food & Macro Log',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MealCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.displayName),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryAmber,
                      backgroundColor: AppTheme.surfaceCard,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : AppTheme.textPrimary,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                            if (_nameController.text.isEmpty ||
                                MealCategory.values.any((c) => c.displayName == _nameController.text)) {
                              _nameController.text = cat.displayName;
                            }
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
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Meal or Item Name',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
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
              ),
            ),

            const SizedBox(height: 14),

            // Calories Input & Quick Add Steppers
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _calsController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Calories (kcal)',
                      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildQuickCalButton('+100', 100),
                const SizedBox(width: 6),
                _buildQuickCalButton('+250', 250),
                const SizedBox(width: 6),
                _buildQuickCalButton('+500', 500),
              ],
            ),

            const SizedBox(height: 14),

            // Macros Row (Protein, Carbs, Fat)
            Row(
              children: [
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

            const SizedBox(height: 20),

            // Log Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Log Entry',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCalButton(String text, int amount) {
    return InkWell(
      onTap: () => _addCalories(amount),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryAmber,
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
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11),
        filled: true,
        fillColor: AppTheme.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
      ),
    );
  }
}
