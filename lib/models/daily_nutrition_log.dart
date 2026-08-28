import 'package:oly/models/daily_activity_entry.dart';
import 'package:oly/models/nutrition_entry.dart';

class DailyNutritionLog {
  const DailyNutritionLog({
    required this.date,
    required this.entries,
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.targetCarbsGrams,
    required this.targetFatGrams,
    this.activities = const <DailyActivityEntry>[],
    this.targetWaterOz = 120.0,
    this.waterOz = 0,
    this.isTrainingDay = false,
    this.notes,
  });

  factory DailyNutritionLog.create({
    required String date,
    List<NutritionEntry>? entries,
    List<DailyActivityEntry>? activities,
    int targetCalories = 2400,
    double targetProteinGrams = 200,
    double targetCarbsGrams = 250,
    double targetFatGrams = 70,
    double targetWaterOz = 120.0,
    double waterOz = 0,
    bool isTrainingDay = false,
    String? notes,
  }) {
    return DailyNutritionLog(
      date: date,
      entries: entries ?? <NutritionEntry>[],
      activities: activities ?? <DailyActivityEntry>[],
      targetCalories: targetCalories,
      targetProteinGrams: targetProteinGrams,
      targetCarbsGrams: targetCarbsGrams,
      targetFatGrams: targetFatGrams,
      targetWaterOz: targetWaterOz,
      waterOz: waterOz,
      isTrainingDay: isTrainingDay,
      notes: notes,
    );
  }

  factory DailyNutritionLog.fromJson(Map<String, dynamic> json) {
    return DailyNutritionLog(
      date: json['date'] as String,
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((dynamic e) => NutritionEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <NutritionEntry>[],
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map(
                (dynamic e) => DailyActivityEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <DailyActivityEntry>[],
      targetCalories: json['targetCalories'] as int? ?? 2400,
      targetProteinGrams:
          (json['targetProteinGrams'] as num?)?.toDouble() ?? 200.0,
      targetCarbsGrams: (json['targetCarbsGrams'] as num?)?.toDouble() ?? 250.0,
      targetFatGrams: (json['targetFatGrams'] as num?)?.toDouble() ?? 70.0,
      targetWaterOz: (json['targetWaterOz'] as num?)?.toDouble() ?? 120.0,
      waterOz: (json['waterOz'] as num?)?.toDouble() ?? 0.0,
      isTrainingDay: json['isTrainingDay'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
  final String date; // Format: 'YYYY-MM-DD'
  final List<NutritionEntry> entries;
  final List<DailyActivityEntry> activities;
  final int targetCalories;
  final double targetProteinGrams;
  final double targetCarbsGrams;
  final double targetFatGrams;
  final double targetWaterOz;
  final double waterOz;
  final bool isTrainingDay;
  final String? notes;

  int get totalCalories =>
      entries.fold(0, (int sum, NutritionEntry item) => sum + item.calories);
  double get totalProtein => entries.fold(
    0.0,
    (double sum, NutritionEntry item) => sum + item.proteinGrams,
  );
  double get totalCarbs => entries.fold(
    0.0,
    (double sum, NutritionEntry item) => sum + item.carbsGrams,
  );
  double get totalFat => entries.fold(
    0.0,
    (double sum, NutritionEntry item) => sum + item.fatGrams,
  );

  int get totalActivityCalories => activities.fold(
    0,
    (int sum, DailyActivityEntry item) => sum + item.caloriesBurned,
  );

  int totalCaloriesBurned([int baselineBmr = 2394]) =>
      baselineBmr + totalActivityCalories;

  int netCalories([int baselineBmr = 2394]) =>
      totalCalories - totalCaloriesBurned(baselineBmr);

  bool get hasWodActivity =>
      activities.any((DailyActivityEntry a) => a.activityType == 'workout_wod');

  int get remainingCalories => targetCalories - totalCalories;
  double get remainingProtein => targetProteinGrams - totalProtein;
  double get remainingCarbs => targetCarbsGrams - totalCarbs;
  double get remainingFat => targetFatGrams - totalFat;
  double get remainingWaterOz => targetWaterOz - waterOz;

  double get calorieProgress => targetCalories > 0
      ? (totalCalories / targetCalories).clamp(0.0, 1.5)
      : 0.0;
  double get proteinProgress => targetProteinGrams > 0
      ? (totalProtein / targetProteinGrams).clamp(0.0, 1.5)
      : 0.0;
  double get carbsProgress => targetCarbsGrams > 0
      ? (totalCarbs / targetCarbsGrams).clamp(0.0, 1.5)
      : 0.0;
  double get fatProgress =>
      targetFatGrams > 0 ? (totalFat / targetFatGrams).clamp(0.0, 1.5) : 0.0;
  double get waterProgress =>
      targetWaterOz > 0 ? (waterOz / targetWaterOz).clamp(0.0, 1.5) : 0.0;

  List<NutritionEntry> getEntriesForCategory(MealCategory category) {
    return entries
        .where((NutritionEntry entry) => entry.category == category)
        .toList();
  }

  int getCaloriesForCategory(MealCategory category) {
    return getEntriesForCategory(category)
        .fold(0, (int sum, NutritionEntry item) => sum + item.calories);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date,
      'entries': entries.map((NutritionEntry e) => e.toJson()).toList(),
      'activities': activities
          .map((DailyActivityEntry e) => e.toJson())
          .toList(),
      'targetCalories': targetCalories,
      'targetProteinGrams': targetProteinGrams,
      'targetCarbsGrams': targetCarbsGrams,
      'targetFatGrams': targetFatGrams,
      'targetWaterOz': targetWaterOz,
      'waterOz': waterOz,
      'isTrainingDay': isTrainingDay,
      'notes': notes,
    };
  }

  DailyNutritionLog copyWith({
    String? date,
    List<NutritionEntry>? entries,
    List<DailyActivityEntry>? activities,
    int? targetCalories,
    double? targetProteinGrams,
    double? targetCarbsGrams,
    double? targetFatGrams,
    double? targetWaterOz,
    double? waterOz,
    bool? isTrainingDay,
    String? notes,
  }) {
    return DailyNutritionLog(
      date: date ?? this.date,
      entries: entries ?? this.entries,
      activities: activities ?? this.activities,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinGrams: targetProteinGrams ?? this.targetProteinGrams,
      targetCarbsGrams: targetCarbsGrams ?? this.targetCarbsGrams,
      targetFatGrams: targetFatGrams ?? this.targetFatGrams,
      targetWaterOz: targetWaterOz ?? this.targetWaterOz,
      waterOz: waterOz ?? this.waterOz,
      isTrainingDay: isTrainingDay ?? this.isTrainingDay,
      notes: notes ?? this.notes,
    );
  }
}
