import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/fasting_grocery_item.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class FastingGrocerySheet extends StatelessWidget {
  const FastingGrocerySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext _) => const FastingGrocerySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FastingProvider fasting = Provider.of<FastingProvider>(context);
    final List<FastingGroceryItem> items = fasting.pantryItems;

    // Group items by category
    final Map<FastingGroceryCategory, List<FastingGroceryItem>> grouped =
        <FastingGroceryCategory, List<FastingGroceryItem>>{};
    for (final FastingGroceryCategory cat in FastingGroceryCategory.values) {
      grouped[cat] =
          items.where((FastingGroceryItem i) => i.category == cat).toList();
    }

    final int checkedCount =
        items.where((FastingGroceryItem i) => i.isChecked).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            // Grab handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'FASTING PANTRY & GROCERY LIST',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$checkedCount of ${items.length} items prepared on hand',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppTheme.primaryAmber),
                    tooltip: 'Add Custom Item',
                    onPressed: () => _showAddItemDialog(context, fasting),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // Scrollable Category List
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: FastingGroceryCategory.values.map((FastingGroceryCategory cat) {
                  final List<FastingGroceryItem> catItems = grouped[cat] ?? <FastingGroceryItem>[];
                  if (catItems.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  String title = '';
                  IconData icon = Icons.check_circle_outline;
                  Color iconColor = AppTheme.primaryAmber;

                  switch (cat) {
                    case FastingGroceryCategory.fastingEssentials:
                      title = 'FASTING WINDOW ESSENTIALS';
                      icon = Icons.water_drop_outlined;
                      iconColor = Colors.cyanAccent;
                      break;
                    case FastingGroceryCategory.preWorkoutPrimer:
                      title = '5:15 AM PLATFORM PRIMER';
                      icon = Icons.bolt;
                      iconColor = AppTheme.primaryAmber;
                      break;
                    case FastingGroceryCategory.refeedingBroth:
                      title = 'REFEEDING: PHASE 1 (BROTH & ENZYMES)';
                      icon = Icons.soup_kitchen_outlined;
                      iconColor = Colors.tealAccent;
                      break;
                    case FastingGroceryCategory.refeedingGentle:
                      title = 'REFEEDING: PHASE 2 (GENTLE WHOLE FOODS)';
                      icon = Icons.egg_alt_outlined;
                      iconColor = Colors.amberAccent;
                      break;
                    case FastingGroceryCategory.refeedingRecovery:
                      title = 'REFEEDING: PHASE 3 (GLYCOGEN & PROTEIN)';
                      icon = Icons.restaurant;
                      iconColor = Colors.greenAccent;
                      break;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 6),
                        child: Row(
                          children: <Widget>[
                            Icon(icon, size: 14, color: iconColor),
                            const SizedBox(width: 6),
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...catItems.map((FastingGroceryItem item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.isChecked
                                  ? Colors.white10
                                  : Colors.white24,
                            ),
                          ),
                          child: Material(
                            color: item.isChecked
                                ? const Color(0xFF141418)
                                : const Color(0xFF1C1C22),
                            borderRadius: BorderRadius.circular(10),
                            child: CheckboxListTile(
                              value: item.isChecked,
                              onChanged: (_) => fasting.togglePantryItem(item.id),
                              activeColor: AppTheme.primaryAmber,
                              checkColor: Colors.black,
                              title: Text(
                                item.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: item.isChecked
                                      ? AppTheme.textSecondary
                                      : Colors.white,
                                  decoration: item.isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                item.description,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, FastingProvider fasting) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    FastingGroceryCategory selectedCategory =
        FastingGroceryCategory.fastingEssentials;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Add Grocery Item',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: AppTheme.primaryAmber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Purpose / Description (Optional)',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: AppTheme.primaryAmber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FastingGroceryCategory>(
                    initialValue: selectedCategory,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: FastingGroceryCategory.values
                        .map((FastingGroceryCategory c) {
                      return DropdownMenuItem<FastingGroceryCategory>(
                        value: c,
                        child: Text(
                          c.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (FastingGroceryCategory? val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      fasting.addCustomPantryItem(
                        name: nameCtrl.text.trim(),
                        category: selectedCategory,
                        description: descCtrl.text.trim(),
                      );
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
