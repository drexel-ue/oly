enum FastingGroceryCategory {
  fastingEssentials, // Salts, electrolytes, green tea, mineral water
  preWorkoutPrimer, // 5:15 AM salt packets, black coffee
  refeedingBroth, // Phase 1: Bone broth, miso
  refeedingGentle, // Phase 2: Eggs, avocado, kimchi
  refeedingRecovery, // Phase 3: Salmon, chicken, sweet potatoes
}

class FastingGroceryItem {
  const FastingGroceryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.isChecked = false,
    this.isCustom = false,
  });

  factory FastingGroceryItem.fromJson(Map<String, dynamic> json) {
    return FastingGroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: FastingGroceryCategory.values.firstWhere(
        (FastingGroceryCategory c) => c.name == json['category'],
        orElse: () => FastingGroceryCategory.fastingEssentials,
      ),
      description: json['description'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final FastingGroceryCategory category;
  final String description;
  final bool isChecked;
  final bool isCustom;

  FastingGroceryItem copyWith({
    String? id,
    String? name,
    FastingGroceryCategory? category,
    String? description,
    bool? isChecked,
    bool? isCustom,
  }) {
    return FastingGroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      isChecked: isChecked ?? this.isChecked,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category.name,
      'description': description,
      'isChecked': isChecked,
      'isCustom': isCustom,
    };
  }

  String get categoryLabel {
    switch (category) {
      case FastingGroceryCategory.fastingEssentials:
        return 'Fasting Window Essentials';
      case FastingGroceryCategory.preWorkoutPrimer:
        return '5:15 AM Platform Primer';
      case FastingGroceryCategory.refeedingBroth:
        return 'Refeeding: Phase 1 (Broth)';
      case FastingGroceryCategory.refeedingGentle:
        return 'Refeeding: Phase 2 (Gentle Whole Foods)';
      case FastingGroceryCategory.refeedingRecovery:
        return 'Refeeding: Phase 3 (Glycogen & Protein)';
    }
  }
}
