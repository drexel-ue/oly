import 'package:flutter/foundation.dart';
import 'package:oly/models/c25k_model.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/grip_hang_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/services/storage_service.dart';

class GoalProvider extends ChangeNotifier {
  new(this._storageService) {
    _loadFromStorage();
  }

  final StorageService _storageService;
  List<GoalTrack> _goals = <GoalTrack>[];
  List<DailySessionPlan> _plans = <DailySessionPlan>[];

  List<GoalTrack> get goals => List<GoalTrack>.unmodifiable(_goals);
  List<GoalTrack> get activeGoals =>
      _goals.where((g) => g.isEnabled).toList();

  GoalTrack? getGoal(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  void _loadFromStorage() {
    _goals = _storageService.loadGoalTracks();
    _plans = _storageService.loadDailySessionPlans();
    notifyListeners();
  }

  Future<void> toggleGoal(String goalId, bool isEnabled) async {
    final int idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      final GoalTrack goal = _goals[idx];
      _goals[idx] = goal.copyWith(
        scheduleConfig: goal.scheduleConfig.copyWith(isEnabled: isEnabled),
      );
      await _storageService.saveGoalTracks(_goals);
      notifyListeners();
    }
  }

  Future<void> updateGoalSchedule(String goalId, Set<int> weekdays) async {
    final int idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      final GoalTrack goal = _goals[idx];
      _goals[idx] = goal.copyWith(
        scheduleConfig: goal.scheduleConfig.copyWith(scheduledWeekdays: weekdays),
      );
      await _storageService.saveGoalTracks(_goals);
      notifyListeners();
    }
  }

  Future<void> updateMilestoneProgress(
    String goalId,
    String milestoneId,
    double currentValue,
  ) async {
    final int goalIdx = _goals.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final GoalTrack goal = _goals[goalIdx];
      final List<GoalMilestone> updatedMilestones =
          goal.milestones.map((m) {
        if (m.id == milestoneId) {
          return m.copyWith(currentValue: currentValue);
        }
        return m;
      }).toList();

      _goals[goalIdx] = goal.copyWith(milestones: updatedMilestones);
      await _storageService.saveGoalTracks(_goals);
      notifyListeners();
    }
  }

  /// Sync milestone progress from other providers (Lifts, Hang PRs, C25K)
  void syncMilestoneValues({
    double? olyTotalKg,
    double? snatchKg,
    double? cjKg,
    int? bestTwoHandHangSeconds,
    int? bestLeftHangSeconds,
    int? bestRightHangSeconds,
    int? c25kCompletedSessions,
    int? c25kMaxContinuousJogSeconds,
  }) {
    bool changed = false;
    for (int i = 0; i < _goals.length; i++) {
      final GoalTrack g = _goals[i];
      final List<GoalMilestone> updated = g.milestones.map((m) {
        double? newVal;
        if (m.id == 'oly_total_200' && olyTotalKg != null) newVal = olyTotalKg;
        if (m.id == 'snatch_90' && snatchKg != null) newVal = snatchKg;
        if (m.id == 'cj_115' && cjKg != null) newVal = cjKg;
        if (m.id == 'hang_dual_300s' && bestTwoHandHangSeconds != null) {
          newVal = bestTwoHandHangSeconds.toDouble();
        }
        if (m.id == 'hang_left_120s' && bestLeftHangSeconds != null) {
          newVal = bestLeftHangSeconds.toDouble();
        }
        if (m.id == 'hang_right_120s' && bestRightHangSeconds != null) {
          newVal = bestRightHangSeconds.toDouble();
        }
        if (m.id == 'c25k_complete_curriculum' && c25kCompletedSessions != null) {
          newVal = c25kCompletedSessions.toDouble();
        }
        if (m.id == 'c25k_continuous_5k' && c25kMaxContinuousJogSeconds != null) {
          newVal = c25kMaxContinuousJogSeconds.toDouble();
        }

        if (newVal != null && newVal != m.currentValue) {
          changed = true;
          return m.copyWith(currentValue: newVal);
        }
        return m;
      }).toList();

      if (changed) {
        _goals[i] = g.copyWith(milestones: updated);
      }
    }

    if (changed) {
      _storageService.saveGoalTracks(_goals);
      notifyListeners();
    }
  }

  // --- DAILY SESSION COMPOSER ---

  /// Composes today's training blueprint based on active goals and current day of the week
  DailySessionPlan getDailyPlanForDate({
    required DateTime date,
    required DayTemplate currentOlyDay,
    HangProtocol? hangProtocol,
    C25kWorkout? c25kWorkout,
  }) {
    final String dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final int existingIdx = _plans.indexWhere((p) {
      final String pKey =
          '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
      return pKey == dateKey;
    });

    if (existingIdx != -1) {
      return _plans[existingIdx];
    }

    final int weekday = date.weekday;
    final List<ComposedSessionBlock> blocks = <ComposedSessionBlock>[];

    // Check Oly Lifting Goal
    final GoalTrack? olyGoal = getGoal('goal_oly_lifting');
    if (olyGoal != null &&
        olyGoal.scheduleConfig.isScheduledForWeekday(weekday)) {
      blocks.add(
        ComposedSessionBlock(
          id: 'block_oly_${currentOlyDay.dayNumber}',
          goalId: olyGoal.id,
          type: SessionBlockType.lifting,
          title: currentOlyDay.title,
          subtitle: currentOlyDay.subtitle,
          estimatedMinutes: 50,
        ),
      );
    }

    // Check Grip & Hang Goal
    final GoalTrack? gripGoal = getGoal('goal_grip_hang');
    if (gripGoal != null &&
        gripGoal.scheduleConfig.isScheduledForWeekday(weekday)) {
      final HangProtocol proto = hangProtocol ?? HangProtocol.getProtocols()[1];
      blocks.add(
        ComposedSessionBlock(
          id: 'block_hang_${proto.id}',
          goalId: gripGoal.id,
          type: SessionBlockType.hang,
          title: proto.title,
          subtitle: proto.subtitle,
          estimatedMinutes: 15,
          data: <String, dynamic>{'protocolId': proto.id},
        ),
      );
    }

    // Check C25K Goal
    final GoalTrack? c25kGoal = getGoal('goal_c25k');
    if (c25kGoal != null &&
        c25kGoal.scheduleConfig.isScheduledForWeekday(weekday)) {
      final C25kWorkout workout = c25kWorkout ?? C25kCurriculum.getWorkout(1, 1);
      blocks.add(
        ComposedSessionBlock(
          id: 'block_c25k_w${workout.week}d${workout.day}',
          goalId: c25kGoal.id,
          type: SessionBlockType.c25k,
          title: workout.title,
          subtitle: workout.description,
          estimatedMinutes: workout.totalDurationSeconds ~/ 60,
          data: <String, dynamic>{
            'week': workout.week,
            'day': workout.day,
          },
        ),
      );
    }

    final DailySessionPlan newPlan =
        DailySessionPlan(date: date, blocks: blocks);
    _plans.add(newPlan);
    _storageService.saveDailySessionPlans(_plans);
    return newPlan;
  }

  Future<void> markBlockCompleted(
    DateTime date,
    String blockId, {
    bool isCompleted = true,
  }) async {
    final String dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final int planIdx = _plans.indexWhere((p) {
      final String pKey =
          '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
      return pKey == dateKey;
    });

    if (planIdx != -1) {
      final DailySessionPlan plan = _plans[planIdx];
      final List<ComposedSessionBlock> updatedBlocks = plan.blocks.map((b) {
        if (b.id == blockId) {
          return b.copyWith(
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
          );
        }
        return b;
      }).toList();

      _plans[planIdx] = plan.copyWith(blocks: updatedBlocks);
      await _storageService.saveDailySessionPlans(_plans);
      notifyListeners();
    }
  }
}
