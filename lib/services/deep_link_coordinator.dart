import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/models/workout_session.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/gtg_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/wim_hof_session_screen.dart';
import 'package:oly/views/gtg/grease_the_groove_screen.dart';
import 'package:oly/views/nutrition/fasting_circadian_sheet.dart';
import 'package:oly/views/nutrition/water_log_sheet.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:provider/provider.dart';

typedef TabSwitchCallback = void Function(
  int tabIndex, [
  int? subIndex,
  VoidCallback? onComplete,
]);

/// Centralized coordinator for deep linking across OLY.
/// Handles local notification taps, lock-screen quick actions, and custom URI schemes.
class DeepLinkCoordinator {
  new _internal() {
    _nativeChannel.setMethodCallHandler(_handleNativeCall);
  }
  static final DeepLinkCoordinator instance = DeepLinkCoordinator._internal();

  static const MethodChannel _nativeChannel =
      MethodChannel('lamontlabs.oly/deep_links');

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  TabSwitchCallback? _tabSwitcher;
  String? _pendingPayload;
  String? _pendingActionId;

  String? _lastDispatchedPayload;
  String? _lastDispatchedAction;
  DateTime? _lastDispatchedTime;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final Map<dynamic, dynamic>? args =
          call.arguments as Map<dynamic, dynamic>?;
      if (args != null) {
        final String? payload = args['payload'] as String?;
        final String? actionId = args['actionId'] as String?;
        if (payload != null && payload.isNotEmpty) {
          AppLogService.instance.info(
            'DEEP_LINK',
            'Native channel onDeepLink: $payload (action: $actionId)',
          );
          handlePayload(payload, actionId: actionId);
        }
      }
    }
  }

  bool _isDuplicate(String payload, String? actionId) {
    if (_lastDispatchedTime == null) return false;
    final bool samePayload = _lastDispatchedPayload == payload;
    final bool sameAction = _lastDispatchedAction == actionId;
    final bool withinWindow = DateTime.now().difference(_lastDispatchedTime!) <
        const Duration(milliseconds: 1500);
    return samePayload && sameAction && withinWindow;
  }

  /// Registers the main container's tab switching function.
  void registerTabSwitcher(TabSwitchCallback switcher) {
    _tabSwitcher = switcher;
  }

  /// Unregisters the tab switcher on container disposal.
  void unregisterTabSwitcher() {
    _tabSwitcher = null;
  }

  /// Ingests a raw payload string (e.g. `oly://fuel/water?amount=739`) and optional action ID.
  void handlePayload(String payload, {String? actionId}) {
    AppLogService.instance.info(
      'DEEP_LINK',
      'handlePayload => payload: $payload, actionId: $actionId',
    );
    debugPrint(
      'DeepLinkCoordinator: handlePayload => payload: $payload, actionId: $actionId',
    );

    final BuildContext? context = navigatorKey.currentContext;
    if (context == null || _tabSwitcher == null) {
      _pendingPayload = payload;
      _pendingActionId = actionId;
      AppLogService.instance.info(
        'DEEP_LINK',
        'App not fully mounted, queued payload: $payload',
      );
      return;
    }

    unawaited(_dispatch(payload, actionId));
  }

  /// Called by the main navigation container once mounted to process any cold-launch deep link.
  void processPendingDeepLink(BuildContext context) {
    if (_pendingPayload != null) {
      final String payload = _pendingPayload!;
      final String? actionId = _pendingActionId;
      _pendingPayload = null;
      _pendingActionId = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_dispatch(payload, actionId));
      });
    }
  }

  BuildContext? _getSafeActiveContext() {
    return navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
  }

  Future<void> _dispatch(
    String rawPayload,
    String? actionId,
  ) async {
    if (_isDuplicate(rawPayload, actionId)) {
      AppLogService.instance.info(
        'DEEP_LINK',
        'Suppressed duplicate dispatch within 1.5s: $rawPayload ($actionId)',
      );
      return;
    }

    _lastDispatchedPayload = rawPayload;
    _lastDispatchedAction = actionId;
    _lastDispatchedTime = DateTime.now();

    Uri? uri;
    try {
      uri = Uri.parse(rawPayload);
    } catch (e) {
      AppLogService.instance.warning(
        'DEEP_LINK',
        'Malformed URI $rawPayload: $e',
      );
      return;
    }

    final String host = uri.host.toLowerCase();
    final List<String> segments = uri.pathSegments;
    final String domain = host.isNotEmpty
        ? host
        : (segments.isNotEmpty ? segments.first.toLowerCase() : '');

    // Pop any open modal bottom sheets, dialogs, or subroutes first to restore root state
    final NavigatorState? nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      AppLogService.instance.info(
        'DEEP_LINK',
        'Closing active modal sheets to return to root navigation',
      );
      nav.popUntil((route) => route.isFirst);
      // Wait for modal dismiss animation to complete before presenting new sheet
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    // 1. FASTING & HYDRATION (Fuel Tab = index 2)
    if (domain == 'fuel' || domain == 'nutrition') {
      final bool isWater = segments.contains('water') ||
          uri.queryParameters.containsKey('amount');
      final bool isFasting = segments.contains('fasting') ||
          domain == 'fasting' ||
          uri.queryParameters.containsKey('slot');

      final double? amount =
          double.tryParse(uri.queryParameters['amount'] ?? '');

      // Handle Lock Screen Quick Action: Instant 1-tap water log
      if (actionId == 'action_log_water') {
        final BuildContext? targetContext = _getSafeActiveContext();
        if (targetContext != null && targetContext.mounted) {
          _quickLogWater(targetContext, amount ?? 250);
        }
        _tabSwitcher?.call(2);
        return;
      }

      // Handle Lock Screen Quick Action: Instant coffee log
      if (actionId == 'action_log_coffee') {
        final BuildContext? targetContext = _getSafeActiveContext();
        if (targetContext != null && targetContext.mounted) {
          _quickLogCoffee(targetContext);
        }
        _tabSwitcher?.call(2, null, () {
          final BuildContext? activeContext = _getSafeActiveContext();
          if (activeContext == null || !activeContext.mounted) return;
          FastingCircadianSheet.show(activeContext);
        });
        return;
      }

      if (actionId == 'action_open_fasting') {
        _tabSwitcher?.call(2, null, () {
          final BuildContext? activeContext = _getSafeActiveContext();
          if (activeContext == null || !activeContext.mounted) return;
          FastingCircadianSheet.show(activeContext);
        });
        return;
      }

      _tabSwitcher?.call(2, null, () {
        final BuildContext? activeContext = _getSafeActiveContext();
        if (activeContext == null || !activeContext.mounted) return;

        if (isWater) {
          WaterLogSheet.show(activeContext, initialMl: amount);
        } else if (isFasting) {
          FastingCircadianSheet.show(activeContext);
        }
      });
      return;
    }

    // 2. GREASE THE GROOVE (Dashboard Tab = index 0)
    if (domain == 'gtg') {
      final bool isHang = segments.contains('hang');
      final int? targetHang =
          int.tryParse(uri.queryParameters['target'] ?? '');
      final int? pullUpReps =
          int.tryParse(uri.queryParameters['reps'] ?? '');

      // Handle Lock Screen Quick Action: Direct pull-up log
      if (actionId == 'action_log_gtg_reps') {
        final BuildContext? targetContext = _getSafeActiveContext();
        if (targetContext != null && targetContext.mounted) {
          _quickLogPullUps(targetContext, pullUpReps);
        }
        _tabSwitcher?.call(0);
        return;
      }

      // Handle Lock Screen Quick Action: Direct hang log
      if (actionId == 'action_log_gtg_hang') {
        final BuildContext? targetContext = _getSafeActiveContext();
        if (targetContext != null && targetContext.mounted) {
          _quickLogHang(targetContext, targetHang);
        }
        _tabSwitcher?.call(0);
        return;
      }

      _tabSwitcher?.call(0, null, () {
        final BuildContext? activeContext = _getSafeActiveContext();
        if (activeContext == null || !activeContext.mounted) return;

        Navigator.of(activeContext).push(
          MaterialPageRoute<void>(
            builder: (_) => GreaseTheGrooveScreen(
              autoStartHang: isHang || actionId == 'action_start_gtg_hang',
              initialHangSeconds: targetHang,
              initialPullUpReps: pullUpReps,
            ),
          ),
        );
      });
      return;
    }

    // 3. WORKOUT & REST TIMER (Active workout modal)
    if (domain == 'workout') {
      final BuildContext? targetContext = _getSafeActiveContext();
      if (targetContext == null || !targetContext.mounted) return;

      final ActiveSessionProvider session =
          targetContext.read<ActiveSessionProvider>();
      final ProgramProvider program = targetContext.read<ProgramProvider>();

      if (actionId == 'action_add_rest_30s') {
        final int current = session.restSecondsRemaining;
        final int nextRemaining = current > 0 ? current + 30 : 30;
        session.startRestTimer(seconds: nextRemaining);
        await HapticFeedback.heavyImpact();
        if (targetContext.mounted) {
          ScaffoldMessenger.of(targetContext).showSnackBar(
            const SnackBar(
              content: Text(
                '⏱️ Added +30s to Rest Timer!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primaryAmber,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (actionId == 'action_workout_ready') {
        session.resetRestTimer();
        await HapticFeedback.heavyImpact();
        if (targetContext.mounted) {
          ScaffoldMessenger.of(targetContext).showSnackBar(
            const SnackBar(
              content: Text(
                '⚡ Ready to Lift! Platform active.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.accentElectricCyan,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      final ActiveWorkoutDraft? draft = program.activeDraft;
      final DayTemplate matchingDay = draft != null
          ? program.days.firstWhere(
              (d) => d.dayNumber == draft.dayNumber,
              orElse: () => program.currentDayTemplate,
            )
          : program.currentDayTemplate;

      _tabSwitcher?.call(0, null, () {
        final BuildContext? activeContext = _getSafeActiveContext();
        if (activeContext == null || !activeContext.mounted) return;

        Navigator.of(activeContext).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkoutSessionScreen(
              dayTemplate: matchingDay,
              initialDraft: draft,
              isPreviewMode: session.isPreviewMode,
            ),
          ),
        );
      });
      return;
    }

    // 4. RECOVER & BREATHWORK (Recover Tab = index 1)
    if (domain == 'recover' || domain == 'breathing') {
      _tabSwitcher?.call(1, null, () {
        final BuildContext? activeContext = _getSafeActiveContext();
        if (activeContext == null || !activeContext.mounted) return;

        if (actionId == 'action_start_breathwork' ||
            segments.contains('breathwork') ||
            domain == 'breathing') {
          final BreathingProvider breathing =
              activeContext.read<BreathingProvider>();
          Navigator.of(activeContext).push(
            MaterialPageRoute<void>(
              builder: (_) => WimHofSessionScreen(
                config: breathing.config,
              ),
            ),
          );
        }
      });
      return;
    }

    // 5. ANALYTICS (Analytics Tab = index 3)
    if (domain == 'analytics') {
      final int subTab =
          int.tryParse(uri.queryParameters['tab'] ?? '') ?? 0;
      _tabSwitcher?.call(3, subTab);
      return;
    }

    // Default fallback: Dashboard
    _tabSwitcher?.call(0);
  }

  void _quickLogWater(BuildContext context, double amountMl) {
    HapticFeedback.heavyImpact();
    try {
      final NutritionProvider nutrition = context.read<NutritionProvider>();
      final FastingProvider fasting = context.read<FastingProvider>();

      nutrition.addWaterMl(amountMl);
      fasting.syncWaterFromFuel(nutrition.currentDayLog.waterMl.round());

      AppLogService.instance.info(
        'DEEP_LINK',
        'Quick logged ${amountMl.round()} mL water from lock screen',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💧 Quick Logged ${amountMl.round()} mL water!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.accentElectricCyan,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      AppLogService.instance.error(
        'DEEP_LINK',
        'Error quick logging water: $e',
      );
    }
  }

  void _quickLogCoffee(BuildContext context) {
    HapticFeedback.heavyImpact();
    try {
      final NutritionProvider nutrition = context.read<NutritionProvider>();
      final FastingProvider fasting = context.read<FastingProvider>();

      // 240 mL (~8 oz) black coffee counted toward fluid hydration
      const double coffeeMl = 240;
      nutrition.addWaterMl(coffeeMl);
      fasting.syncWaterFromFuel(nutrition.currentDayLog.waterMl.round());

      AppLogService.instance.info(
        'DEEP_LINK',
        'Quick logged 240 mL coffee from lock screen',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '☕ Quick Logged 240 mL Coffee (Hydration Credit)!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryAmber,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      AppLogService.instance.error(
        'DEEP_LINK',
        'Error quick logging coffee: $e',
      );
    }
  }

  void _quickLogPullUps(BuildContext context, int? reps) {
    HapticFeedback.heavyImpact();
    try {
      final GtgProvider gtg = context.read<GtgProvider>();
      final int loggedReps = reps ?? gtg.config.targetPullUpReps;
      unawaited(gtg.logPullUpSet(reps: loggedReps));

      AppLogService.instance.info(
        'DEEP_LINK',
        'Quick logged $loggedReps pull-ups from lock screen',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💪 Logged $loggedReps submax pull-ups (GtG)!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryAmber,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      AppLogService.instance.error(
        'DEEP_LINK',
        'Error quick logging pullups: $e',
      );
    }
  }

  void _quickLogHang(BuildContext context, int? seconds) {
    HapticFeedback.heavyImpact();
    try {
      final GtgProvider gtg = context.read<GtgProvider>();
      final int loggedSeconds = seconds ?? gtg.config.targetHangSeconds;
      unawaited(gtg.logActiveHangSet(seconds: loggedSeconds));

      AppLogService.instance.info(
        'DEEP_LINK',
        'Quick logged ${loggedSeconds}s hang from lock screen',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🧗 Logged ${loggedSeconds}s active scapular hang (GtG)!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.accentElectricCyan,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      AppLogService.instance.error(
        'DEEP_LINK',
        'Error quick logging hang: $e',
      );
    }
  }
}
