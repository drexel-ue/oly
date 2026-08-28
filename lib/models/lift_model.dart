import 'package:oly/models/pr_entry.dart';

enum LiftCategory { snatch, cleanAndJerk, squat, pull, overhead, accessory }

class LiftModel {
  LiftModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentMax,
    this.anchorLiftId,
    this.targetRatio = 1.0,
    List<PREntry>? history,
  }) : history = history ?? <PREntry>[];

  factory LiftModel.fromJson(Map<String, dynamic> json) {
    return LiftModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: LiftCategory.values.firstWhere(
        (LiftCategory e) => e.name == json['category'],
        orElse: () => LiftCategory.accessory,
      ),
      anchorLiftId: json['anchorLiftId'] as String?,
      targetRatio: (json['targetRatio'] as num?)?.toDouble() ?? 1.0,
      currentMax: (json['currentMax'] as num).toDouble(),
      history:
          (json['history'] as List<dynamic>?)
              ?.map((dynamic e) => PREntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <PREntry>[],
    );
  }
  final String id;
  final String name;
  final LiftCategory category;
  final String?
  anchorLiftId; // Reference lift for ratio (e.g. 'snatch' or 'clean_and_jerk')
  final double targetRatio; // Ideal ratio vs anchor lift (e.g. 0.82 for Power Snatch vs Snatch)
  double currentMax; // Current 1RM in KG
  final List<PREntry> history;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category.name,
      'anchorLiftId': anchorLiftId,
      'targetRatio': targetRatio,
      'currentMax': currentMax,
      'history': history.map((PREntry e) => e.toJson()).toList(),
    };
  }

  // Pre-configured default Olympic Weightlifting movements catalog
  static List<LiftModel> defaultLifts() {
    return <LiftModel>[
      LiftModel(
        id: 'snatch',
        name: 'Snatch',
        category: LiftCategory.snatch,
        currentMax: 80.0,
        history: <PREntry>[
          PREntry(
            id: 'init_snatch',
            weight: 80.0,
            reps: 1,
            date: DateTime.now().subtract(const Duration(days: 30)),
            notes: 'Baseline 1RM',
          ),
        ],
      ),
      LiftModel(
        id: 'clean_and_jerk',
        name: 'Clean & Jerk',
        category: LiftCategory.cleanAndJerk,
        currentMax: 100.0,
        history: <PREntry>[
          PREntry(
            id: 'init_cj',
            weight: 100.0,
            reps: 1,
            date: DateTime.now().subtract(const Duration(days: 30)),
            notes: 'Baseline 1RM',
          ),
        ],
      ),
      LiftModel(
        id: 'power_snatch',
        name: 'Power Snatch',
        category: LiftCategory.snatch,
        anchorLiftId: 'snatch',
        targetRatio: 0.82,
        currentMax: 65.0,
      ),
      LiftModel(
        id: 'hang_snatch',
        name: 'Hang Snatch',
        category: LiftCategory.snatch,
        anchorLiftId: 'snatch',
        targetRatio: 0.88,
        currentMax: 70.0,
      ),
      LiftModel(
        id: 'muscle_snatch',
        name: 'Muscle Snatch',
        category: LiftCategory.snatch,
        anchorLiftId: 'snatch',
        targetRatio: 0.60,
        currentMax: 50.0,
      ),
      LiftModel(
        id: 'power_clean',
        name: 'Power Clean',
        category: LiftCategory.cleanAndJerk,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.85,
        currentMax: 85.0,
      ),
      LiftModel(
        id: 'hang_clean',
        name: 'Hang Clean',
        category: LiftCategory.cleanAndJerk,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.88,
        currentMax: 88.0,
      ),
      LiftModel(
        id: 'block_clean',
        name: 'Block Clean',
        category: LiftCategory.cleanAndJerk,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.90,
        currentMax: 90.0,
      ),
      LiftModel(
        id: 'back_squat',
        name: 'Back Squat',
        category: LiftCategory.squat,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 1.35,
        currentMax: 135.0,
      ),
      LiftModel(
        id: 'front_squat',
        name: 'Front Squat',
        category: LiftCategory.squat,
        anchorLiftId: 'back_squat',
        targetRatio: 0.85,
        currentMax: 115.0,
      ),
      LiftModel(
        id: 'snatch_pull',
        name: 'Snatch Pull',
        category: LiftCategory.pull,
        anchorLiftId: 'snatch',
        targetRatio: 1.05,
        currentMax: 85.0,
      ),
      LiftModel(
        id: 'snatch_deadlift',
        name: 'Snatch Deadlift',
        category: LiftCategory.pull,
        anchorLiftId: 'snatch',
        targetRatio: 1.15,
        currentMax: 95.0,
      ),
      LiftModel(
        id: 'military_press',
        name: 'Military Press',
        category: LiftCategory.overhead,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.55,
        currentMax: 55.0,
      ),
      LiftModel(
        id: 'push_press',
        name: 'Push Press',
        category: LiftCategory.overhead,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.75,
        currentMax: 75.0,
      ),
      LiftModel(
        id: 'rdl',
        name: 'Romanian Deadlift (RDL)',
        category: LiftCategory.pull,
        anchorLiftId: 'clean_and_jerk',
        targetRatio: 0.80,
        currentMax: 80.0,
      ),
    ];
  }
}
