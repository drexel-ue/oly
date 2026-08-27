import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/body_composition_entry.dart';
import '../models/daily_nutrition_log.dart';
import '../models/nutrition_entry.dart';
import '../models/nutrition_goal_model.dart';
import '../services/storage_service.dart';
import '../services/tdee_calculator_service.dart';

class NutritionProvider extends ChangeNotifier {
  final StorageService _storage;
  DateTime _selectedDate = DateTime.now();
  Map<String, DailyNutritionLog> _logs = {};
  NutritionGoalModel _goal = const NutritionGoalModel();
  List<NutritionEntry> _templates = [];

  NutritionProvider(this._storage) {
    _loadData();
  }

  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  NutritionGoalModel get goal => _goal;
  List<NutritionEntry> get templates => List.unmodifiable(_templates);
  Map<String, DailyNutritionLog> get allLogs => Map.unmodifiable(_logs);

  void _loadData() {
    _logs = _storage.loadDailyNutritionLogs();
    _goal = _storage.loadNutritionGoal();
    _templates = _storage.loadMealTemplates();

    if (_templates.isEmpty) {
      // Seed default quick templates for lifters
      _templates = [
        NutritionEntry.create(
          name: 'Post-Workout Whey & Banana',
          calories: 320,
          proteinGrams: 30,
          carbsGrams: 42,
          fatGrams: 3,
          category: MealCategory.postWorkout,
          portion: '1 scoop whey + 1 large banana',
        ),
        NutritionEntry.create(
          name: '4 Eggs & Sourdough Toast',
          calories: 480,
          proteinGrams: 28,
          carbsGrams: 34,
          fatGrams: 22,
          category: MealCategory.breakfast,
          portion: '4 large eggs + 2 slices sourdough',
        ),
        NutritionEntry.create(
          name: 'Chicken Breast & Jasmine Rice',
          calories: 560,
          proteinGrams: 48,
          carbsGrams: 65,
          fatGrams: 8,
          category: MealCategory.lunch,
          portion: '200g chicken + 1.5 cups rice',
        ),
        NutritionEntry.create(
          name: 'Greek Yogurt & Berries Bowl',
          calories: 240,
          proteinGrams: 22,
          carbsGrams: 26,
          fatGrams: 4,
          category: MealCategory.snack,
          portion: '1 cup non-fat Greek yogurt + 0.5 cup blueberries',
        ),
      ];
      _storage.saveMealTemplates(_templates);
    }
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  void setToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  DailyNutritionLog getDayLog(String dateKey, {BodyCompositionEntry? latestBodyComp}) {
    if (_logs.containsKey(dateKey)) {
      return _logs[dateKey]!;
    }
    // Calculate default day targets based on goal and latest body comp
    final targets = TdeeCalculatorService.calculateMacroTargets(
      latestBodyComp: latestBodyComp,
      goal: _goal,
      isTrainingDay: false,
    );
    final waterTarget = _goal.getRecommendedWaterGoalOz(
      latestBodyComp: latestBodyComp,
      isTrainingDay: false,
    );
    return DailyNutritionLog.create(
      date: dateKey,
      targetCalories: targets.calories,
      targetProteinGrams: targets.proteinGrams,
      targetCarbsGrams: targets.carbsGrams,
      targetFatGrams: targets.fatGrams,
      targetWaterOz: waterTarget,
    );
  }

  DailyNutritionLog get currentDayLog => getDayLog(selectedDateKey);

  Future<void> addFoodEntry(NutritionEntry entry, {BodyCompositionEntry? latestBodyComp}) async {
    final key = selectedDateKey;
    final current = getDayLog(key, latestBodyComp: latestBodyComp);
    final updatedEntries = List<NutritionEntry>.from(current.entries)..add(entry);

    final updatedLog = current.copyWith(entries: updatedEntries);
    _logs[key] = updatedLog;
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }

  Future<void> quickAddCalories({
    required int calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    MealCategory category = MealCategory.snack,
    String name = 'Quick Entry',
    BodyCompositionEntry? latestBodyComp,
  }) async {
    final entry = NutritionEntry.create(
      name: name,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      category: category,
    );
    await addFoodEntry(entry, latestBodyComp: latestBodyComp);
  }

  Future<void> updateFoodEntry(NutritionEntry entry) async {
    final key = selectedDateKey;
    final current = _logs[key];
    if (current == null) return;

    final updatedEntries = current.entries.map((e) => e.id == entry.id ? entry : e).toList();
    _logs[key] = current.copyWith(entries: updatedEntries);
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }

  Future<void> deleteFoodEntry(String entryId) async {
    final key = selectedDateKey;
    final current = _logs[key];
    if (current == null) return;

    final updatedEntries = current.entries.where((e) => e.id != entryId).toList();
    _logs[key] = current.copyWith(entries: updatedEntries);
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }

  Future<void> addWater(double oz) async {
    final key = selectedDateKey;
    final current = getDayLog(key);
    _logs[key] = current.copyWith(waterOz: (current.waterOz + oz).clamp(0.0, 400.0));
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }

  Future<void> toggleTrainingDay(bool isTraining, {BodyCompositionEntry? latestBodyComp}) async {
    final key = selectedDateKey;
    final current = getDayLog(key, latestBodyComp: latestBodyComp);
    final targets = TdeeCalculatorService.calculateMacroTargets(
      latestBodyComp: latestBodyComp,
      goal: _goal,
      isTrainingDay: isTraining,
    );
    final waterTarget = _goal.getRecommendedWaterGoalOz(
      latestBodyComp: latestBodyComp,
      isTrainingDay: isTraining,
    );

    _logs[key] = current.copyWith(
      isTrainingDay: isTraining,
      targetCalories: targets.calories,
      targetProteinGrams: targets.proteinGrams,
      targetCarbsGrams: targets.carbsGrams,
      targetFatGrams: targets.fatGrams,
      targetWaterOz: waterTarget,
    );
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }

  Future<void> updateGoal(NutritionGoalModel newGoal, {BodyCompositionEntry? latestBodyComp}) async {
    _goal = newGoal;
    await _storage.saveNutritionGoal(_goal);

    // Recalculate current day targets
    final key = selectedDateKey;
    final current = getDayLog(key, latestBodyComp: latestBodyComp);
    final targets = TdeeCalculatorService.calculateMacroTargets(
      latestBodyComp: latestBodyComp,
      goal: _goal,
      isTrainingDay: current.isTrainingDay,
    );
    final waterTarget = _goal.getRecommendedWaterGoalOz(
      latestBodyComp: latestBodyComp,
      isTrainingDay: current.isTrainingDay,
    );
    _logs[key] = current.copyWith(
      targetCalories: targets.calories,
      targetProteinGrams: targets.proteinGrams,
      targetCarbsGrams: targets.carbsGrams,
      targetFatGrams: targets.fatGrams,
      targetWaterOz: waterTarget,
    );
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }

  Future<void> saveAsTemplate(NutritionEntry entry) async {
    _templates.removeWhere((t) => t.name.toLowerCase() == entry.name.toLowerCase());
    _templates.add(entry);
    await _storage.saveMealTemplates(_templates);
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _storage.saveMealTemplates(_templates);
    notifyListeners();
  }

  Future<void> copyYesterdayMeal(MealCategory category, {BodyCompositionEntry? latestBodyComp}) async {
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(_selectedDate.subtract(const Duration(days: 1)));
    final yesterdayLog = _logs[yesterdayKey];
    if (yesterdayLog == null) return;

    final yesterdayCategoryEntries = yesterdayLog.getEntriesForCategory(category);
    if (yesterdayCategoryEntries.isEmpty) return;

    final key = selectedDateKey;
    final current = getDayLog(key, latestBodyComp: latestBodyComp);
    final newEntries = List<NutritionEntry>.from(current.entries);

    for (final item in yesterdayCategoryEntries) {
      newEntries.add(NutritionEntry.create(
        name: item.name,
        calories: item.calories,
        proteinGrams: item.proteinGrams,
        carbsGrams: item.carbsGrams,
        fatGrams: item.fatGrams,
        category: category,
        portion: item.portion,
      ));
    }

    _logs[key] = current.copyWith(entries: newEntries);
    await _storage.saveDailyNutritionLogs(_logs);
    notifyListeners();
  }
}
