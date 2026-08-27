import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/daily_nutrition_log.dart';
import '../../models/nutrition_entry.dart';
import '../../providers/body_comp_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nutrition/macro_ring_card.dart';
import 'body_comp_analytics_screen.dart';
import 'nutrition_settings_screen.dart';
import 'quick_macro_log_sheet.dart';
import 'renpho_scanner_sheet.dart';

class NutritionDashboardScreen extends StatelessWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nutrition = Provider.of<NutritionProvider>(context);
    final bodyComp = Provider.of<BodyCompProvider>(context);
    final currentLog = nutrition.getDayLog(
      nutrition.selectedDateKey,
      latestBodyComp: bodyComp.latestEntry,
    );

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
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
              'Nutrition & Energy',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryAmber),
            tooltip: 'Body Composition Analytics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BodyCompAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppTheme.primaryAmber),
            tooltip: 'Goal Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NutritionSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Switcher Bar
              _buildDateSwitcher(context, nutrition),
              const SizedBox(height: 14),

              // Macro Ring & Calories Summary Card
              MacroRingCard(
                log: currentLog,
                onToggleTrainingDay: () {
                  nutrition.toggleTrainingDay(!currentLog.isTrainingDay, latestBodyComp: bodyComp.latestEntry);
                },
              ),
              const SizedBox(height: 14),

              // Renpho Biometrics Glance Card
              _buildRenphoGlanceCard(context, bodyComp),
              const SizedBox(height: 16),

              // Water Tracker Strip
              _buildWaterTracker(context, nutrition, currentLog),
              const SizedBox(height: 16),

              // Meal Category Sections
              ...MealCategory.values.map((category) {
                return _buildMealCategorySection(
                  context,
                  nutrition,
                  currentLog,
                  category,
                  bodyComp,
                );
              }),

              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const QuickMacroLogSheet(),
          );
        },
        backgroundColor: AppTheme.primaryAmber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, size: 22),
        label: Text(
          'Log Food',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDateSwitcher(BuildContext context, NutritionProvider nutrition) {
    final isToday = DateFormat('yyyy-MM-dd').format(nutrition.selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            onPressed: () => nutrition.previousDay(),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: nutrition.selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryAmber,
                        surface: AppTheme.surfaceElevated,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                nutrition.selectDate(picked);
              }
            },
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primaryAmber),
                const SizedBox(width: 8),
                Text(
                  isToday ? 'Today, ${DateFormat('MMM d').format(nutrition.selectedDate)}' : DateFormat('EEEE, MMM d').format(nutrition.selectedDate),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
            onPressed: () => nutrition.nextDay(),
          ),
        ],
      ),
    );
  }

  Widget _buildRenphoGlanceCard(BuildContext context, BodyCompProvider bodyComp) {
    final latest = bodyComp.latestEntry;
    if (latest == null) {
      return const SizedBox();
    }

    final fatDelta = bodyComp.fatMassDeltaVsPrevious;
    final muscleDelta = bodyComp.skeletalMuscleDeltaVsPrevious;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryAmber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'RENPHO SCALE BIOMETRICS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const RenphoScannerSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt, size: 13, color: AppTheme.primaryAmber),
                      const SizedBox(width: 4),
                      Text(
                        'Scan Scale',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4 Grid Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Weight',
                  '${latest.weightLb.toStringAsFixed(1)} lb',
                  subtitle: latest.bmi != null ? 'BMI ${latest.bmi!.toStringAsFixed(1)}' : null,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Body Fat',
                  latest.bodyFatPct != null ? '${latest.bodyFatPct!.toStringAsFixed(1)}%' : '--',
                  subtitle: fatDelta != 0 ? '${fatDelta > 0 ? '+' : ''}${fatDelta.toStringAsFixed(1)} lb' : null,
                  isSubtitleGood: fatDelta <= 0,
                  color: AppTheme.warningOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Lean Mass',
                  '${latest.leanBodyMassLb.toStringAsFixed(1)} lb',
                  subtitle: muscleDelta != 0 ? '${muscleDelta > 0 ? '+' : ''}${muscleDelta.toStringAsFixed(1)} lb' : null,
                  isSubtitleGood: muscleDelta >= 0,
                  color: AppTheme.secondaryCyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'BMR',
                  '${latest.bmrKcal ?? latest.katchMcArdleBmr}',
                  subtitle: 'kcal base',
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value, {
    String? subtitle,
    bool isSubtitleGood = true,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSubtitleGood ? AppTheme.successGreen : AppTheme.warningOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterTracker(
    BuildContext context,
    NutritionProvider nutrition,
    DailyNutritionLog log,
  ) {
    final progress = log.waterProgress;
    final isGoalMet = log.waterOz >= log.targetWaterOz;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoalMet ? const Color(0xFF00D2FF).withOpacity(0.5) : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.water_drop, color: Color(0xFF00D2FF), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Hydration',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (log.isTrainingDay) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+24oz Training',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryAmber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${log.waterOz.toStringAsFixed(0)} oz / ${log.targetWaterOz.toStringAsFixed(0)} oz goal (${(progress * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isGoalMet ? const Color(0xFF00D2FF) : AppTheme.textSecondary,
                          fontWeight: isGoalMet ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildWaterAddButton(nutrition, 8, '+8oz'),
                  const SizedBox(width: 5),
                  _buildWaterAddButton(nutrition, 16, '+16oz'),
                  const SizedBox(width: 5),
                  _buildWaterAddButton(nutrition, 24, '+24oz'),
                  const SizedBox(width: 5),
                  _buildWaterAddButton(nutrition, 32, '+32oz'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                isGoalMet ? const Color(0xFF00E5FF) : const Color(0xFF00D2FF),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterAddButton(NutritionProvider nutrition, double oz, String label) {
    return InkWell(
      onTap: () => nutrition.addWater(oz),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00D2FF).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00D2FF).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00D2FF),
          ),
        ),
      ),
    );
  }

  Widget _buildMealCategorySection(
    BuildContext context,
    NutritionProvider nutrition,
    DailyNutritionLog log,
    MealCategory category,
    BodyCompProvider bodyComp,
  ) {
    final entries = log.getEntriesForCategory(category);
    final categoryCals = log.getCaloriesForCategory(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: entries.isNotEmpty || category == MealCategory.breakfast,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getCategoryIcon(category), color: AppTheme.primaryAmber, size: 18),
        ),
        title: Text(
          category.displayName,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '$categoryCals kcal',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: categoryCals > 0 ? AppTheme.primaryAmber : AppTheme.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryAmber),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => QuickMacroLogSheet(defaultCategory: category),
            );
          },
        ),
        children: [
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'No items logged yet',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () => nutrition.copyYesterdayMeal(category, latestBodyComp: bodyComp.latestEntry),
                    icon: const Icon(Icons.replay, size: 14, color: AppTheme.primaryAmber),
                    label: Text(
                      'Repeat Yesterday',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryAmber),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(color: AppTheme.borderColor.withOpacity(0.5), height: 1),
              itemBuilder: (context, index) {
                final item = entries[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => nutrition.deleteFoodEntry(item.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.proteinGrams.toStringAsFixed(0)}g P • ${item.carbsGrams.toStringAsFixed(0)}g C • ${item.fatGrams.toStringAsFixed(0)}g F${item.portion != null ? ' • ${item.portion}' : ''}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.calories} kcal',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
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
}
