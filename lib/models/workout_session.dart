import 'package:uuid/uuid.dart';

class CompletedSet {
  CompletedSet({
    required this.setIndex,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isCompleted = true,
    this.completedAt,
  });

  factory CompletedSet.fromJson(Map<String, dynamic> json) {
    return CompletedSet(
      setIndex: json['setIndex'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      rpe: json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
      isCompleted: json['isCompleted'] as bool? ?? true,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
  final int setIndex;
  final double weight; // KG
  final int reps;
  final double? rpe;
  final bool isCompleted;
  final DateTime? completedAt;

  double get totalVolumeKg => isCompleted ? weight * reps : 0.0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'setIndex': setIndex,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

class ExerciseLog {
  ExerciseLog({
    required this.exerciseName,
    required this.liftId,
    required this.sets,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseName: json['exerciseName'] as String,
      liftId: json['liftId'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((dynamic e) => CompletedSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final String exerciseName;
  final String liftId;
  final List<CompletedSet> sets;

  double get totalVolumeKg =>
      sets.fold(0.0, (double sum, CompletedSet s) => sum + s.totalVolumeKg);
  int get totalReps => sets.fold(
    0,
    (int sum, CompletedSet s) => sum + (s.isCompleted ? s.reps : 0),
  );
  int get totalSets => sets.where((CompletedSet s) => s.isCompleted).length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseName': exerciseName,
      'liftId': liftId,
      'sets': sets.map((CompletedSet e) => e.toJson()).toList(),
    };
  }
}

class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.date,
    required this.dayNumber,
    required this.weekNumber,
    required this.cycleNumber,
    required this.logs,
    this.durationSeconds = 0,
    this.notes,
    this.sessionRpe,
    this.jointStrainTags,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      dayNumber: json['dayNumber'] as int,
      weekNumber: json['weekNumber'] as int,
      cycleNumber: json['cycleNumber'] as int,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      notes: json['notes'] as String?,
      sessionRpe: json['sessionRpe'] as int?,
      jointStrainTags: (json['jointStrainTags'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      logs: (json['logs'] as List<dynamic>)
          .map((dynamic e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final String id;
  final DateTime date;
  final int dayNumber;
  final int weekNumber;
  final int cycleNumber;
  final int durationSeconds;
  final String? notes;
  final int? sessionRpe;
  final List<String>? jointStrainTags;
  final List<ExerciseLog> logs;

  double get totalVolumeKg =>
      logs.fold(0.0, (double sum, ExerciseLog l) => sum + l.totalVolumeKg);
  double get totalTonsMetric => totalVolumeKg / 1000.0;
  double get totalTonsUs => (totalVolumeKg * 2.20462) / 2000.0;
  int get totalSets =>
      logs.fold(0, (int sum, ExerciseLog l) => sum + l.totalSets);
  int get totalReps =>
      logs.fold(0, (int sum, ExerciseLog l) => sum + l.totalReps);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'cycleNumber': cycleNumber,
      'durationSeconds': durationSeconds,
      'notes': notes,
      'sessionRpe': sessionRpe,
      'jointStrainTags': jointStrainTags,
      'logs': logs.map((ExerciseLog e) => e.toJson()).toList(),
    };
  }
}

enum DynamicItemType {
  wod,
  exercise,
  kettlebellMile,
  custom,
}

class DynamicWorkoutItem {
  DynamicWorkoutItem({
    required this.id,
    required this.type,
    required this.name,
    this.refId,
    this.subtitle,
    this.setScheme,
    this.targetWeightKg,
    this.isCompleted = false,
    this.completedResult,
    this.data = const <String, dynamic>{},
  });

  factory DynamicWorkoutItem.fromJson(Map<String, dynamic> json) {
    return DynamicWorkoutItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      type: _typeFromString(json['type'] as String?),
      name: json['name'] as String? ?? 'Custom Movement',
      refId: json['refId'] as String?,
      subtitle: json['subtitle'] as String?,
      setScheme: json['setScheme'] as String?,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedResult: json['completedResult'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  final String id;
  final DynamicItemType type;
  final String name;
  final String? refId; // e.g., 'death_by_burpees', 'dt', 'snatch', 'cable_crunches'
  final String? subtitle;
  final String? setScheme; // e.g., '3 Sets of 8 Reps'
  final double? targetWeightKg;
  bool isCompleted;
  String? completedResult; // e.g. '14 Mins + 8 Reps' or '07:15 (Rx)'
  final Map<String, dynamic> data;

  static DynamicItemType _typeFromString(String? typeStr) {
    switch (typeStr) {
      case 'wod':
        return DynamicItemType.wod;
      case 'kettlebellMile':
      case 'kettlebell_mile':
        return DynamicItemType.kettlebellMile;
      case 'exercise':
        return DynamicItemType.exercise;
      case 'custom':
      default:
        return DynamicItemType.custom;
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'name': name,
      'refId': refId,
      'subtitle': subtitle,
      'setScheme': setScheme,
      'targetWeightKg': targetWeightKg,
      'isCompleted': isCompleted,
      'completedResult': completedResult,
      'data': data,
    };
  }

  DynamicWorkoutItem copyWith({
    String? id,
    DynamicItemType? type,
    String? name,
    String? refId,
    String? subtitle,
    String? setScheme,
    double? targetWeightKg,
    bool? isCompleted,
    String? completedResult,
    Map<String, dynamic>? data,
  }) {
    return DynamicWorkoutItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      refId: refId ?? this.refId,
      subtitle: subtitle ?? this.subtitle,
      setScheme: setScheme ?? this.setScheme,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      isCompleted: isCompleted ?? this.isCompleted,
      completedResult: completedResult ?? this.completedResult,
      data: data ?? this.data,
    );
  }
}

class ActiveWorkoutDraft {
  ActiveWorkoutDraft({
    required this.dayNumber,
    required this.weekNumber,
    required this.cycleNumber,
    required this.dayTitle,
    required this.startTime,
    required this.exerciseSets,
    required this.exerciseWeights,
    this.swappedExerciseNames = const <String, String>{},
    this.notes = '',
    this.selectedRpe = 8,
    this.selectedJointStrains = const <String>[],
    this.isPreviewMode = false,
    this.dynamicItems = const <DynamicWorkoutItem>[],
  });

  factory ActiveWorkoutDraft.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawSets =
        json['exerciseSets'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, List<CompletedSet>> setsMap =
        <String, List<CompletedSet>>{};
    rawSets.forEach((String k, dynamic v) {
      if (v is List) {
        setsMap[k] = v
            .map((dynamic s) => CompletedSet.fromJson(s as Map<String, dynamic>))
            .toList();
      }
    });

    final Map<String, dynamic> rawWeights =
        json['exerciseWeights'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, double> weightsMap = <String, double>{};
    rawWeights.forEach((String k, dynamic v) {
      if (v is num) {
        weightsMap[k] = v.toDouble();
      }
    });

    final Map<String, dynamic> rawSwaps =
        json['swappedExerciseNames'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final Map<String, String> swapsMap = <String, String>{};
    rawSwaps.forEach((String k, dynamic v) {
      if (v is String) {
        swapsMap[k] = v;
      }
    });

    final List<dynamic>? rawDynamic = json['dynamicItems'] as List<dynamic>?;
    final List<DynamicWorkoutItem> dynamicList = rawDynamic != null
        ? rawDynamic
            .map((dynamic e) => DynamicWorkoutItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : const <DynamicWorkoutItem>[];

    return ActiveWorkoutDraft(
      dayNumber: json['dayNumber'] as int? ?? 1,
      weekNumber: json['weekNumber'] as int? ?? 1,
      cycleNumber: json['cycleNumber'] as int? ?? 1,
      dayTitle: json['dayTitle'] as String? ?? 'Workout Session',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      exerciseSets: setsMap,
      exerciseWeights: weightsMap,
      swappedExerciseNames: swapsMap,
      notes: json['notes'] as String? ?? '',
      selectedRpe: json['selectedRpe'] as int? ?? 8,
      selectedJointStrains:
          (json['selectedJointStrains'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      isPreviewMode: json['isPreviewMode'] as bool? ?? false,
      dynamicItems: dynamicList,
    );
  }
  final int dayNumber;
  final int weekNumber;
  final int cycleNumber;
  final String dayTitle;
  final DateTime startTime;
  final Map<String, List<CompletedSet>> exerciseSets;
  final Map<String, double> exerciseWeights;
  final Map<String, String> swappedExerciseNames;
  final String notes;
  final int selectedRpe;
  final List<String> selectedJointStrains;
  final bool isPreviewMode;
  final List<DynamicWorkoutItem> dynamicItems;

  int get totalSetsCount => exerciseSets.values.fold(
    0,
    (int sum, List<CompletedSet> sets) => sum + sets.length,
  );

  int get totalCompletedSets => exerciseSets.values.fold(
    0,
    (int sum, List<CompletedSet> sets) =>
        sum + sets.where((CompletedSet s) => s.isCompleted).length,
  );

  int get totalDynamicCount => dynamicItems.length;

  int get totalCompletedDynamic =>
      dynamicItems.where((DynamicWorkoutItem i) => i.isCompleted).length;

  double get completionPercentage {
    final int total = totalSetsCount + totalDynamicCount;
    if (total == 0) {
      return 0.0;
    }
    return (totalCompletedSets + totalCompletedDynamic) / total;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'cycleNumber': cycleNumber,
      'dayTitle': dayTitle,
      'startTime': startTime.toIso8601String(),
      'exerciseSets': exerciseSets.map(
        (String key, List<CompletedSet> value) =>
            MapEntry(key, value.map((CompletedSet s) => s.toJson()).toList()),
      ),
      'exerciseWeights': exerciseWeights,
      'swappedExerciseNames': swappedExerciseNames,
      'notes': notes,
      'selectedRpe': selectedRpe,
      'selectedJointStrains': selectedJointStrains,
      'isPreviewMode': isPreviewMode,
      'dynamicItems': dynamicItems.map((DynamicWorkoutItem e) => e.toJson()).toList(),
    };
  }
}
