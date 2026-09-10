import 'dart:convert';

import 'package:oly/models/wod_definition.dart';

/// Represents a CrossFit Hero Workout scraped from crossfit.com.
/// Contains official workout rep schemes, RX loads, and memorial tribute text
/// honoring fallen military, law enforcement, and first responder personnel.
class CrossfitHeroWod {
  const CrossfitHeroWod({
    required this.id,
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.format,
    required this.category,
    required this.targetTimeOrCap,
    required this.equipment,
    required this.movementsSummary,
    required this.rawWorkoutText,
    required this.tributeText,
    required this.sourceUrl,
    this.rxWeights,
    this.firstPosted,
    this.targetCapSeconds,
    this.hasInteractiveTracker = false,
  });

  /// Deserializes from SQLite row map
  factory CrossfitHeroWod.fromSqlite(Map<String, dynamic> map) {
    List<String> decodeList(dynamic val) {
      if (val == null) {
        return <String>[];
      }
      if (val is List) {
        return val.map((dynamic e) => e.toString()).toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(val);
          if (decoded is List) {
            return decoded.map((dynamic e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return <String>[];
    }

    return CrossfitHeroWod(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      format: parseFormat(map['format'] as String?),
      category: map['category'] as String? ?? 'Hero Benchmark',
      targetTimeOrCap: map['target_time_or_cap'] as String? ?? 'For Time',
      targetCapSeconds: map['target_cap_seconds'] as int?,
      equipment: decodeList(map['equipment']),
      movementsSummary: decodeList(map['movements_summary']),
      rawWorkoutText: map['raw_workout_text'] as String? ?? '',
      rxWeights: map['rx_weights'] as String?,
      tributeText: map['tribute_text'] as String? ?? '',
      firstPosted: map['first_posted'] as String?,
      sourceUrl: map['source_url'] as String? ?? '',
      hasInteractiveTracker: (map['has_interactive_tracker'] as int? ?? 0) == 1,
    );
  }

  /// Deserializes from JSON map
  factory CrossfitHeroWod.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((dynamic e) => e.toString()).toList();
      }
      return <String>[];
    }

    return CrossfitHeroWod(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      format: parseFormat(json['format'] as String?),
      category: json['category'] as String? ?? 'Hero Benchmark',
      targetTimeOrCap: json['targetTimeOrCap'] as String? ?? 'For Time',
      targetCapSeconds: json['targetCapSeconds'] as int?,
      equipment: parseStringList(json['equipment']),
      movementsSummary: parseStringList(json['movementsSummary']),
      rawWorkoutText: json['rawWorkoutText'] as String? ?? '',
      rxWeights: json['rxWeights'] as String?,
      tributeText: json['tributeText'] as String? ?? '',
      firstPosted: json['firstPosted'] as String?,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      hasInteractiveTracker: json['hasInteractiveTracker'] as bool? ?? false,
    );
  }

  final String id;
  final String slug;
  final String name;
  final String subtitle;
  final WodFormat format;
  final String category;
  final String targetTimeOrCap;
  final int? targetCapSeconds;
  final List<String> equipment;
  final List<String> movementsSummary;
  final String rawWorkoutText;
  final String? rxWeights;
  final String tributeText;
  final String? firstPosted;
  final String sourceUrl;
  final bool hasInteractiveTracker;

  /// Helper to convert a format string to [WodFormat] enum
  static WodFormat parseFormat(String? formatStr) {
    if (formatStr == null) {
      return WodFormat.forTime;
    }
    final String lower = formatStr.toLowerCase();
    if (lower.contains('amrap') || lower.contains('as many rounds') || lower.contains('as many reps')) {
      return WodFormat.amrap;
    }
    if (lower.contains('emom') || lower.contains('every minute') || lower.contains('minute on the minute')) {
      return WodFormat.emom;
    }
    if (lower.contains('interval') || lower.contains('tabata')) {
      return WodFormat.intervals;
    }
    return WodFormat.forTime;
  }

  /// Converts this database model into a standard [WodDefinition] for seamless UI reuse.
  WodDefinition toWodDefinition() {
    return WodDefinition(
      id: id,
      name: name,
      subtitle: subtitle.isNotEmpty ? subtitle : 'Hero Memorial Workout',
      format: format,
      category: category,
      targetTimeOrCap: targetTimeOrCap,
      targetCapSeconds: targetCapSeconds,
      equipment: equipment,
      movementsSummary: movementsSummary,
      hasInteractiveTracker: hasInteractiveTracker,
      setupExplainer: WodSetupExplainer(
        floorPlanAdvice: tributeText.isNotEmpty
            ? tributeText
            : 'Prepare your workout bay with all required gear before starting the clock.',
        equipmentChecklist: equipment.isNotEmpty ? equipment : <String>['Open Gym Space'],
        movementStandards: movementsSummary.map((String m) {
          return WodMovementStandard(
            movementName: m,
            repsOrDistance: '',
            standards: const <String>[
              'Maintain full range of motion throughout all repetitions.',
            ],
            rxLoad: rxWeights,
          );
        }).toList(),
        pacingStrategy: <String>[
          'Steady pacing: Hero workouts are tests of grit and mental endurance.',
          if (rxWeights != null && rxWeights!.isNotEmpty) 'Prescribed weights: $rxWeights',
          if (firstPosted != null && firstPosted!.isNotEmpty) 'CrossFit.com tribute first posted: $firstPosted',
        ],
        targetTimes: <String, String>{
          'Benchmark': targetTimeOrCap,
          'Stimulus': 'Hero Memorial Tribute',
        },
        scalingOptions: <String, String>{
          'Rx': rxWeights != null && rxWeights!.isNotEmpty ? 'As prescribed ($rxWeights)' : 'Full prescribed volume',
          'Scaled': 'Reduce load to ~60-70% and partition high-volume sets as needed',
          'Beginner': 'Scale reps by 50% or substitute bodyweight alternatives',
        },
      ),
    );
  }

  /// Serializes to SQLite row map
  Map<String, dynamic> toSqlite() {
    return <String, dynamic>{
      'id': id,
      'slug': slug,
      'name': name,
      'subtitle': subtitle,
      'format': format.name,
      'category': category,
      'target_time_or_cap': targetTimeOrCap,
      'target_cap_seconds': targetCapSeconds,
      'equipment': jsonEncode(equipment),
      'movements_summary': jsonEncode(movementsSummary),
      'raw_workout_text': rawWorkoutText,
      'rx_weights': rxWeights,
      'tribute_text': tributeText,
      'first_posted': firstPosted,
      'source_url': sourceUrl,
      'has_interactive_tracker': hasInteractiveTracker ? 1 : 0,
    };
  }

  /// Serializes to JSON map
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'slug': slug,
      'name': name,
      'subtitle': subtitle,
      'format': format.name,
      'category': category,
      'targetTimeOrCap': targetTimeOrCap,
      'targetCapSeconds': targetCapSeconds,
      'equipment': equipment,
      'movementsSummary': movementsSummary,
      'rawWorkoutText': rawWorkoutText,
      'rxWeights': rxWeights,
      'tributeText': tributeText,
      'firstPosted': firstPosted,
      'sourceUrl': sourceUrl,
      'hasInteractiveTracker': hasInteractiveTracker,
    };
  }
}
