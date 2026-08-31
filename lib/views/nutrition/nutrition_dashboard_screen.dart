import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/daily_nutrition_log.dart';
import 'package:oly/models/nutrition_entry.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/nutrition/activity_log_sheet.dart';
import 'package:oly/views/nutrition/body_comp_analytics_screen.dart';
import 'package:oly/views/nutrition/edit_food_entry_sheet.dart';
import 'package:oly/views/nutrition/food_search_sheet.dart';
import 'package:oly/views/nutrition/metabolic_science_explainer_screen.dart';
import 'package:oly/views/nutrition/nutrition_settings_screen.dart';
import 'package:oly/views/nutrition/quick_macro_log_sheet.dart';
import 'package:oly/views/nutrition/renpho_scanner_sheet.dart';
import 'package:oly/widgets/nutrition/energy_balance_card.dart';
import 'package:oly/widgets/nutrition/macro_ring_card.dart';
import 'package:provider/provider.dart';

class NutritionDashboardScreen extends StatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  State<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen> {
  int _selectedViewIndex =
      0; // 0 = Energy Balance (In vs Out), 1 = Macro Targets (P/C/F)

  @override
  Widget build(BuildContext context) {
    final NutritionProvider nutrition = Provider.of<NutritionProvider>(context);
    final BodyCompProvider bodyComp = Provider.of<BodyCompProvider>(context);
    final DailyNutritionLog currentLog = nutrition.getDayLog(
      nutrition.selectedDateKey,
      latestBodyComp: bodyComp.latestEntry,
    );

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
            Flexible(
              child: Text(
                'Nutrition & Energy',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.primaryAmber),
            tooltip: 'Metabolic Science & Calculations',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MetabolicScienceExplainerScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.analytics_outlined,
              color: AppTheme.primaryAmber,
            ),
            tooltip: 'Body Composition Analytics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BodyCompAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppTheme.primaryAmber),
            tooltip: 'Goal Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NutritionSettingsScreen(),
                ),
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
            children: <Widget>[
              // Date Switcher Bar
              _buildDateSwitcher(context, nutrition),
              const SizedBox(height: 12),

              // View Selector Segment (Energy Balance vs Macro Targets)
              _buildViewSelector(),
              const SizedBox(height: 12),

              // Hero View (Energy Balance or Macro Ring)
              if (_selectedViewIndex == 0)
                EnergyBalanceCard(
                  log: currentLog,
                  latestBodyComp: bodyComp.latestEntry,
                  goal: nutrition.goal,
                  onLogActivityTap: () => _openActivityLogSheet(context),
                )
              else
                MacroRingCard(
                  log: currentLog,
                  onToggleTrainingDay: () {
                    nutrition.toggleTrainingDay(
                      !currentLog.isTrainingDay,
                      latestBodyComp: bodyComp.latestEntry,
                    );
                  },
                ),

              const SizedBox(height: 14),

              // Renpho Biometrics Glance Card
              _buildRenphoGlanceCard(context, bodyComp),
              const SizedBox(height: 14),

              // Water Tracker Strip
              _buildWaterTracker(context, nutrition, currentLog),
              const SizedBox(height: 16),

              // Daily Activities & Workout Energy Section
              _buildActivitiesSection(context, nutrition, currentLog, bodyComp),
              const SizedBox(height: 16),

              // Meal Category Sections
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'DAILY MEALS & FOOD LOG',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _openFoodSearchSheet(context, MealCategory.lunch),
                    icon: const Icon(
                      Icons.search,
                      size: 14,
                      color: AppTheme.primaryAmber,
                    ),
                    label: Text(
                      'Search / Barcode',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...MealCategory.values.map((MealCategory category) {
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
            builder: (_) =>
                const FoodSearchSheet(defaultCategory: MealCategory.lunch),
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

  Widget _buildViewSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedViewIndex = 0),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewIndex == 0
                      ? AppTheme.secondaryCyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.bolt,
                        size: 15,
                        color: _selectedViewIndex == 0
                            ? AppTheme.secondaryCyan
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Energy In vs Out',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedViewIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedViewIndex == 0
                              ? AppTheme.secondaryCyan
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedViewIndex = 1),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewIndex == 1
                      ? AppTheme.primaryAmber.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.pie_chart_outline,
                        size: 15,
                        color: _selectedViewIndex == 1
                            ? AppTheme.primaryAmber
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Macro Targets',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedViewIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedViewIndex == 1
                              ? AppTheme.primaryAmber
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSwitcher(BuildContext context, NutritionProvider nutrition) {
    final bool isToday =
        DateFormat('yyyy-MM-dd').format(nutrition.selectedDate) ==
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
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            onPressed: () => nutrition.previousDay(),
          ),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: nutrition.selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                builder: (BuildContext context, Widget? child) {
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
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.primaryAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  isToday
                      ? 'Today, ${DateFormat('MMM d').format(nutrition.selectedDate)}'
                      : DateFormat('EEEE, MMM d')
                            .format(nutrition.selectedDate),
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

  Widget _buildRenphoGlanceCard(
    BuildContext context,
    BodyCompProvider bodyComp,
  ) {
    final BodyCompositionEntry? latest = bodyComp.latestEntry;
    if (latest == null) {
      return const SizedBox();
    }

    final double fatDelta = bodyComp.fatMassDeltaVsPrevious;
    final double muscleDelta = bodyComp.skeletalMuscleDeltaVsPrevious;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
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
                    Icons.monitor_weight_outlined,
                    color: AppTheme.primaryAmber,
                    size: 18,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.camera_alt,
                        size: 13,
                        color: AppTheme.primaryAmber,
                      ),
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
            children: <Widget>[
              Expanded(
                child: _buildMetricTile(
                  'Weight',
                  '${latest.weightLb.toStringAsFixed(1)} lb',
                  subtitle: latest.bmi != null
                      ? 'BMI ${latest.bmi!.toStringAsFixed(1)}'
                      : null,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Body Fat',
                  latest.bodyFatPct != null
                      ? '${latest.bodyFatPct!.toStringAsFixed(1)}%'
                      : '--',
                  subtitle: fatDelta != 0
                      ? '${fatDelta > 0 ? '+' : ''}${fatDelta.toStringAsFixed(1)} lb'
                      : null,
                  isSubtitleGood: fatDelta <= 0,
                  color: AppTheme.warningOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Lean Mass',
                  '${latest.leanBodyMassLb.toStringAsFixed(1)} lb',
                  subtitle: muscleDelta != 0
                      ? '${muscleDelta > 0 ? '+' : ''}${muscleDelta.toStringAsFixed(1)} lb'
                      : null,
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
    required Color color,
    String? subtitle,
    bool isSubtitleGood = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
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
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSubtitleGood
                    ? AppTheme.successGreen
                    : AppTheme.warningOrange,
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
    final double progress = log.waterProgress;
    final bool isGoalMet =
        log.waterOz >= log.targetWaterOz && log.targetWaterOz > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoalMet
              ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Color(0xFF00D2FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: <Widget>[
                              Text(
                                'Daily Hydration',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (log.isTrainingDay)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D2FF)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+24oz Training',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00D2FF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${log.waterOz.toStringAsFixed(0)} oz / ${log.targetWaterOz.toStringAsFixed(0)} oz (${(progress * 100).toStringAsFixed(0)}%)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isGoalMet
                                  ? const Color(0xFF00E5FF)
                                  : AppTheme.textSecondary,
                              fontWeight: isGoalMet
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildWaterAddButton(nutrition, 8, '+8oz'),
                    const SizedBox(width: 4),
                    _buildWaterAddButton(nutrition, 16, '+16oz'),
                    const SizedBox(width: 4),
                    _buildWaterAddButton(nutrition, 24, '+24oz'),
                    const SizedBox(width: 4),
                    _buildWaterAddButton(nutrition, 32, '+32oz'),
                  ],
                ),
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

  Widget _buildWaterAddButton(
    NutritionProvider nutrition,
    double oz,
    String label,
  ) {
    return InkWell(
      onTap: () => nutrition.addWater(oz),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00D2FF).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
          ),
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

  Widget _buildActivitiesSection(
    BuildContext context,
    NutritionProvider nutrition,
    DailyNutritionLog log,
    BodyCompProvider bodyComp,
  ) {
    final List<DailyActivityEntry> activities = log.activities;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: AppTheme.secondaryCyan,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'DAILY ACTIVITIES & WOD',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _openActivityLogSheet(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.add,
                        size: 13,
                        color: AppTheme.secondaryCyan,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Log Activity',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No activities logged today. Completed workouts and steps will appear here.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (BuildContext ctx, int idx) {
                final DailyActivityEntry a = activities[idx];
                return Dismissible(
                  key: Key(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => nutrition.removeActivity(a.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Icon(
                                a.activityType == 'workout_wod'
                                    ? Icons.fitness_center
                                    : Icons.directions_walk,
                                size: 16,
                                color: a.activityType == 'workout_wod'
                                    ? AppTheme.primaryAmber
                                    : AppTheme.secondaryCyan,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      a.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${a.durationMinutes.round()} mins • ${a.metValue} MET${a.notes != null ? ' • ${a.notes}' : ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${a.caloriesBurned} kcal',
                          style: GoogleFonts.firaCode(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryCyan,
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

  Widget _buildMealCategorySection(
    BuildContext context,
    NutritionProvider nutrition,
    DailyNutritionLog log,
    MealCategory category,
    BodyCompProvider bodyComp,
  ) {
    final List<NutritionEntry> entries = log.getEntriesForCategory(category);
    final int categoryCals = log.getCaloriesForCategory(category);

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
        initiallyExpanded:
            entries.isNotEmpty || category == MealCategory.breakfast,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: AppTheme.primaryAmber,
            size: 18,
          ),
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
            color: categoryCals > 0
                ? AppTheme.primaryAmber
                : AppTheme.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.search,
                size: 18,
                color: AppTheme.primaryAmber,
              ),
              tooltip: 'Search & Barcode',
              onPressed: () => _openFoodSearchSheet(context, category),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryAmber,
              ),
              tooltip: 'Quick Macro Log',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => QuickMacroLogSheet(defaultCategory: category),
                );
              },
            ),
          ],
        ),
        children: <Widget>[
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'No items logged yet',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => nutrition.copyYesterdayMeal(
                      category,
                      latestBodyComp: bodyComp.latestEntry,
                    ),
                    icon: const Icon(
                      Icons.replay,
                      size: 14,
                      color: AppTheme.primaryAmber,
                    ),
                    label: Text(
                      'Repeat Yesterday',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primaryAmber,
                      ),
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
              separatorBuilder: (_, _) => Divider(
                color: AppTheme.borderColor.withValues(alpha: 0.5),
                height: 1,
              ),
              itemBuilder: (BuildContext context, int index) {
                final NutritionEntry item = entries[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Icon(Icons.delete_outline, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    nutrition.deleteFoodEntry(item.id);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted ${item.name}',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.surfaceElevated,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'UNDO',
                          textColor: AppTheme.primaryAmber,
                          onPressed: () {
                            nutrition.restoreFoodEntry(
                              item,
                              atIndex: index,
                              latestBodyComp: bodyComp.latestEntry,
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: InkWell(
                    onTap: () => _openEditFoodSheet(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.proteinGrams.toStringAsFixed(0)}g P • ${item.carbsGrams.toStringAsFixed(0)}g C • ${item.fatGrams.toStringAsFixed(0)}g F${item.portion != null ? ' • ${item.portion}' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '${item.calories} kcal',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openEditFoodSheet(BuildContext context, NutritionEntry item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditFoodEntrySheet(entry: item),
    );
  }

  void _openActivityLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ActivityLogSheet(),
    );
  }

  void _openFoodSearchSheet(BuildContext context, MealCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodSearchSheet(defaultCategory: category),
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
