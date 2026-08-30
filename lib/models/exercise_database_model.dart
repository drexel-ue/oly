import 'dart:convert';

/// Representation of an exercise entry from the unified offline exercise database.
class ExerciseDatabaseModel {
  const ExerciseDatabaseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.bodyPart,
    required this.targetMuscle,
    required this.equipment,
    required this.source,
    this.secondaryMuscles = const <String>[],
    this.mechanic,
    this.force,
    this.level,
    this.instructions,
    this.tips,
    this.sourceId,
    this.gifUrl,
    this.videoUrl,
  });

  factory ExerciseDatabaseModel.fromSqlite(Map<String, dynamic> map) {
    List<String> secondary = <String>[];
    if (map['secondary_muscles'] != null && map['secondary_muscles'] is String) {
      try {
        final dynamic decoded = jsonDecode(map['secondary_muscles'] as String);
        if (decoded is List) {
          secondary = decoded.map((dynamic e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ExerciseDatabaseModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'strength',
      bodyPart: map['body_part'] as String? ?? 'full_body',
      targetMuscle: map['target_muscle'] as String? ?? 'general',
      secondaryMuscles: secondary,
      equipment: map['equipment'] as String? ?? 'body weight',
      mechanic: map['mechanic'] as String?,
      force: map['force'] as String?,
      level: map['level'] as String?,
      instructions: map['instructions'] as String?,
      tips: map['tips'] as String?,
      source: map['source'] as String? ?? 'unknown',
      sourceId: map['source_id'] as String?,
      gifUrl: map['gif_url'] as String?,
      videoUrl: map['video_url'] as String?,
    );
  }

  factory ExerciseDatabaseModel.fromJson(Map<String, dynamic> json) {
    List<String> secondary = <String>[];
    if (json['secondaryMuscles'] != null && json['secondaryMuscles'] is List) {
      secondary = (json['secondaryMuscles'] as List<dynamic>)
          .map((dynamic e) => e.toString())
          .toList();
    }

    return ExerciseDatabaseModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'strength',
      bodyPart: json['bodyPart'] as String? ?? 'full_body',
      targetMuscle: json['targetMuscle'] as String? ?? 'general',
      secondaryMuscles: secondary,
      equipment: json['equipment'] as String? ?? 'body weight',
      mechanic: json['mechanic'] as String?,
      force: json['force'] as String?,
      level: json['level'] as String?,
      instructions: json['instructions'] as String?,
      tips: json['tips'] as String?,
      source: json['source'] as String? ?? 'unknown',
      sourceId: json['sourceId'] as String?,
      gifUrl: json['gifUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
    );
  }

  final String id;
  final String name;
  final String category;
  final String bodyPart;
  final String targetMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String? mechanic;
  final String? force;
  final String? level;
  final String? instructions;
  final String? tips;
  final String source;
  final String? sourceId;
  final String? gifUrl;
  final String? videoUrl;

  String get displayCategory {
    switch (category) {
      case 'olympic_weightlifting':
        return 'Olympic Weightlifting';
      case 'strength':
        return 'Strength';
      case 'powerlifting':
        return 'Powerlifting';
      case 'plyometrics':
        return 'Plyometrics';
      case 'cardio':
        return 'Cardio';
      case 'mobility':
        return 'Mobility';
      case 'stretching':
        return 'Stretching';
      case 'core':
        return 'Core';
      case 'calisthenics':
        return 'Calisthenics';
      default:
        return category.replaceAll('_', ' ').titleCase;
    }
  }

  String get displayBodyPart {
    switch (bodyPart) {
      case 'upper_legs':
        return 'Upper Legs (Quads / Hams)';
      case 'lower_legs':
        return 'Lower Legs (Calves)';
      case 'full_body':
        return 'Full Body';
      default:
        return bodyPart.replaceAll('_', ' ').titleCase;
    }
  }

  String get displayTargetMuscle {
    switch (targetMuscle) {
      case 'abs':
        return 'Abdominals';
      case 'deltoids':
        return 'Deltoids (Shoulders)';
      case 'pectorals':
        return 'Pectorals (Chest)';
      case 'quadriceps':
        return 'Quadriceps';
      case 'hamstrings':
        return 'Hamstrings';
      case 'upper_back':
        return 'Upper Back (Rhomboids / Traps)';
      case 'lower_back':
        return 'Lower Back (Erectors)';
      default:
        return targetMuscle.replaceAll('_', ' ').titleCase;
    }
  }

  String get displayEquipment {
    return equipment.replaceAll('_', ' ').titleCase;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'bodyPart': bodyPart,
      'targetMuscle': targetMuscle,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'mechanic': mechanic,
      'force': force,
      'level': level,
      'instructions': instructions,
      'tips': tips,
      'source': source,
      'sourceId': sourceId,
      'gifUrl': gifUrl,
      'videoUrl': videoUrl,
    };
  }

  Map<String, dynamic> toSqlite() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'body_part': bodyPart,
      'target_muscle': targetMuscle,
      'secondary_muscles': jsonEncode(secondaryMuscles),
      'equipment': equipment,
      'mechanic': mechanic,
      'force': force,
      'level': level,
      'instructions': instructions,
      'tips': tips,
      'source': source,
      'source_id': sourceId,
      'gif_url': gifUrl,
      'video_url': videoUrl,
    };
  }
}

extension _StringExtension on String {
  String get titleCase {
    if (isEmpty) {
      return this;
    }
    return split(' ')
        .map((String word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
