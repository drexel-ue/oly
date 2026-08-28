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

  int get totalSetsCount => exerciseSets.values.fold(
    0,
    (int sum, List<CompletedSet> sets) => sum + sets.length,
  );

  int get totalCompletedSets => exerciseSets.values.fold(
    0,
    (int sum, List<CompletedSet> sets) =>
        sum + sets.where((CompletedSet s) => s.isCompleted).length,
  );

  double get completionPercentage =>
      totalSetsCount == 0 ? 0.0 : (totalCompletedSets / totalSetsCount);

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
    };
  }
}
