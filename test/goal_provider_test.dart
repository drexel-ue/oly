import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalProvider & Composable Blueprint Tests', () {
    late StorageService storage;
    late GoalProvider goalProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      goalProvider = GoalProvider(storage);
    });

    test('Initializes with default 3 goals if storage is empty', () {
      expect(goalProvider.goals.length, equals(3));
      expect(goalProvider.activeGoals.length, equals(3));

      final GoalTrack? olyGoal = goalProvider.getGoal('goal_oly_lifting');
      final GoalTrack? gripGoal = goalProvider.getGoal('goal_grip_hang');
      final GoalTrack? c25kGoal = goalProvider.getGoal('goal_c25k');

      expect(olyGoal, isNotNull);
      expect(gripGoal, isNotNull);
      expect(c25kGoal, isNotNull);

      expect(olyGoal!.type, equals(GoalType.olympicLifting));
      expect(gripGoal!.type, equals(GoalType.gripAndHang));
      expect(c25kGoal!.type, equals(GoalType.c25kRunning));
    });

    test('Can toggle goal enable/disable status and persists', () async {
      await goalProvider.toggleGoal('goal_c25k', false);

      expect(goalProvider.getGoal('goal_c25k')!.isEnabled, isFalse);
      expect(goalProvider.activeGoals.length, equals(2));

      // Check persistence with fresh instance
      final GoalProvider reloaded = GoalProvider(storage);
      expect(reloaded.getGoal('goal_c25k')!.isEnabled, isFalse);
      expect(reloaded.activeGoals.length, equals(2));
    });

    test('Updates goal schedule weekdays and persists', () async {
      // Schedule C25K only on Tuesdays and Thursdays (weekdays 2 and 4)
      await goalProvider.updateGoalSchedule('goal_c25k', <int>{DateTime.tuesday, DateTime.thursday});

      final GoalTrack updated = goalProvider.getGoal('goal_c25k')!;
      expect(updated.scheduleConfig.scheduledWeekdays, equals(<int>{DateTime.tuesday, DateTime.thursday}));
      expect(updated.scheduleConfig.isScheduledForWeekday(DateTime.tuesday), isTrue);
      expect(updated.scheduleConfig.isScheduledForWeekday(DateTime.monday), isFalse);
    });

    test('Updates milestone values and syncMilestoneValues works correctly', () async {
      goalProvider.syncMilestoneValues(
        olyTotalKg: 185,
        snatchKg: 82.5,
        cjKg: 102.5,
        bestTwoHandHangSeconds: 150,
        bestLeftHangSeconds: 45,
        bestRightHangSeconds: 50,
        c25kCompletedSessions: 6,
        c25kMaxContinuousJogSeconds: 300,
      );

      final GoalTrack gripGoal = goalProvider.getGoal('goal_grip_hang')!;
      final GoalMilestone dualMilestone = gripGoal.milestones.firstWhere((m) => m.id == 'hang_dual_300s');
      final GoalMilestone leftMilestone = gripGoal.milestones.firstWhere((m) => m.id == 'hang_left_120s');

      expect(dualMilestone.currentValue, equals(150.0));
      expect(leftMilestone.currentValue, equals(45.0));

      final GoalTrack c25kGoal = goalProvider.getGoal('goal_c25k')!;
      final GoalMilestone sessionsMilestone = c25kGoal.milestones.firstWhere((m) => m.id == 'c25k_complete_curriculum');
      expect(sessionsMilestone.currentValue, equals(6.0));
    });

    test('Composes daily session plan based on scheduled weekdays', () async {
      // Monday: default Oly (1,2,4,5,6) and Grip (1,3,5) are scheduled; C25K (2,4,6) is not.
      final DateTime monday = DateTime(2026, 9, 14); // 2026-09-14 is Monday
      expect(monday.weekday, equals(DateTime.monday));

      final DayTemplate olyDay = DayTemplate(
        dayNumber: 1,
        title: 'Snatch Technique & Front Squat',
        subtitle: 'Volume Phase',
        phases: <PhaseTemplate>[],
      );

      final DailySessionPlan mondayPlan = goalProvider.getDailyPlanForDate(
        date: monday,
        currentOlyDay: olyDay,
      );

      // On Monday: Oly Lifting + Grip Hang
      expect(mondayPlan.blocks.length, equals(2));
      expect(mondayPlan.blocks[0].type, equals(SessionBlockType.lifting));
      expect(mondayPlan.blocks[1].type, equals(SessionBlockType.hang));

      // Tuesday: Oly (1,2,4,5,6) + C25K (2,4,6) are scheduled; Grip (1,3,5) is not.
      final DateTime tuesday = DateTime(2026, 9, 15); // Tuesday
      expect(tuesday.weekday, equals(DateTime.tuesday));

      final DailySessionPlan tuesdayPlan = goalProvider.getDailyPlanForDate(
        date: tuesday,
        currentOlyDay: olyDay,
      );

      expect(tuesdayPlan.blocks.length, equals(2));
      expect(tuesdayPlan.blocks[0].type, equals(SessionBlockType.lifting));
      expect(tuesdayPlan.blocks[1].type, equals(SessionBlockType.c25k));

      // Wednesday: Only Grip & Hang (1,3,5) is scheduled.
      final DateTime wednesday = DateTime(2026, 9, 16); // Wednesday
      expect(wednesday.weekday, equals(DateTime.wednesday));

      final DailySessionPlan wednesdayPlan = goalProvider.getDailyPlanForDate(
        date: wednesday,
        currentOlyDay: olyDay,
      );

      expect(wednesdayPlan.blocks.length, equals(1));
      expect(wednesdayPlan.blocks[0].type, equals(SessionBlockType.hang));

      // Sunday: Complete rest day (0 blocks).
      final DateTime sunday = DateTime(2026, 9, 20); // Sunday
      expect(sunday.weekday, equals(DateTime.sunday));

      final DailySessionPlan sundayPlan = goalProvider.getDailyPlanForDate(
        date: sunday,
        currentOlyDay: olyDay,
      );

      expect(sundayPlan.blocks.length, equals(0));
    });

    test('Marks block completed in daily plan and persists', () async {
      final DateTime monday = DateTime(2026, 9, 14);
      final DayTemplate olyDay = DayTemplate(
        dayNumber: 1,
        title: 'Snatch Technique',
        subtitle: 'Volume',
        phases: <PhaseTemplate>[],
      );

      final DailySessionPlan initialPlan = goalProvider.getDailyPlanForDate(
        date: monday,
        currentOlyDay: olyDay,
      );
      final String blockId = initialPlan.blocks.first.id;

      await goalProvider.markBlockCompleted(monday, blockId);

      final DailySessionPlan updatedPlan = goalProvider.getDailyPlanForDate(
        date: monday,
        currentOlyDay: olyDay,
      );

      final ComposedSessionBlock completedBlock = updatedPlan.blocks.firstWhere((b) => b.id == blockId);
      expect(completedBlock.isCompleted, isTrue);
      expect(completedBlock.completedAt, isNotNull);
    });
  });
}
