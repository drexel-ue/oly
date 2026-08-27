import 'package:uuid/uuid.dart';

enum MealCategory {
  breakfast,
  lunch,
  dinner,
  snack,
  preWorkout,
  postWorkout;

  String get displayName {
    switch (this) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.dinner:
        return 'Dinner';
      case MealCategory.snack:
        return 'Snacks';
      case MealCategory.preWorkout:
        return 'Pre-Workout';
      case MealCategory.postWorkout:
        return 'Post-Workout';
    }
  }

  String get iconName {
    switch (this) {
      case MealCategory.breakfast:
        return 'wb_sunny_outlined';
      case MealCategory.lunch:
        return 'restaurant_outlined';
      case MealCategory.dinner:
        return 'nights_stay_outlined';
      case MealCategory.snack:
        return 'cookie_outlined';
      case MealCategory.preWorkout:
        return 'bolt_outlined';
      case MealCategory.postWorkout:
        return 'fitness_center_outlined';
    }
  }
}

class NutritionEntry {
  final String id;
  final String name;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final MealCategory category;
  final DateTime timestamp;
  final String? portion;

  const NutritionEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.category,
    required this.timestamp,
    this.portion,
  });

  factory NutritionEntry.create({
    String? id,
    required String name,
    required int calories,
    double proteinGrams = 0,
    double carbsGrams = 0,
    double fatGrams = 0,
    MealCategory category = MealCategory.snack,
    DateTime? timestamp,
    String? portion,
  }) {
    return NutritionEntry(
      id: id ?? const Uuid().v4(),
      name: name,
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      category: category,
      timestamp: timestamp ?? DateTime.now(),
      portion: portion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'portion': portion,
    };
  }

  factory NutritionEntry.fromJson(Map<String, dynamic> json) {
    return NutritionEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      proteinGrams: (json['proteinGrams'] as num).toDouble(),
      carbsGrams: (json['carbsGrams'] as num).toDouble(),
      fatGrams: (json['fatGrams'] as num).toDouble(),
      category: MealCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String),
        orElse: () => MealCategory.snack,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      portion: json['portion'] as String?,
    );
  }

  NutritionEntry copyWith({
    String? id,
    String? name,
    int? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    MealCategory? category,
    DateTime? timestamp,
    String? portion,
  }) {
    return NutritionEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      portion: portion ?? this.portion,
    );
  }
}
