import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/active_session_provider.dart';
import 'package:oly/providers/body_comp_provider.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/nutrition_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/services/recovery_engine_service.dart';
import 'package:oly/services/storage_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/analytics_screen.dart';
import 'package:oly/views/dashboard_screen.dart';
import 'package:oly/views/nutrition/nutrition_dashboard_screen.dart';
import 'package:oly/views/recover_screen.dart';
import 'package:oly/views/recovery_session_screen.dart';
import 'package:oly/views/splash_screen.dart';
import 'package:oly/views/warmup_session_screen.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/active_session_mini_dock.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Keep screen awake during workouts, rest timers, and active recovery flows
  try {
    await WakelockPlus.enable();
  } catch (e) {
    debugPrint('Wakelock enable skipped: $e');
  }

  // Initialize logging and crash reporting first
  await AppLogService.instance.init();

  // Global Flutter framework error hook
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogService.instance.crash(
      'FLUTTER_FRAMEWORK',
      details.exceptionAsString(),
      stackTrace: details.stack,
    );
  };

  // Global uncaught asynchronous errors hook
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogService.instance.crash(
      'UNCAUGHT_ASYNC',
      error.toString(),
      stackTrace: stack,
    );
    return true; // prevent application from dying
  };

  final StorageService storageService = await StorageService.init();
  await NotificationService().init();

  AppLogService.instance.info(
    'SYSTEM',
    'Oly application initialized with portrait lock and wakelock enabled',
  );

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProvider<LiftProvider>(
          create: (_) => LiftProvider(storageService),
        ),
        ChangeNotifierProvider<ProgramProvider>(
          create: (_) => ProgramProvider(storageService),
        ),
        ChangeNotifierProvider<RecoveryProvider>(
          create: (_) => RecoveryProvider(storageService),
        ),
        ChangeNotifierProvider<BodyCompProvider>(
          create: (_) => BodyCompProvider(storageService),
        ),
        ChangeNotifierProvider<NutritionProvider>(
          create: (_) => NutritionProvider(storageService),
        ),
        ChangeNotifierProvider<FastingProvider>(
          create: (_) => FastingProvider(storageService),
        ),
        ChangeNotifierProvider<InjuryProvider>(
          create: (_) => InjuryProvider(storageService),
        ),
        ChangeNotifierProvider<BreathingProvider>(
          create: (_) => BreathingProvider(storageService),
        ),
        ChangeNotifierProvider<ActiveSessionProvider>(
          create: (_) => ActiveSessionProvider(),
        ),
      ],
      child: const OlyApp(),
    ),
  );
}

class OlyApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OLY',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/warmup') {
          final DayTemplate? dayTemplate = settings.arguments as DayTemplate?;
          final DayTemplate defaultDay = ProgramCycle.getBuiltInProgram().first;
          return MaterialPageRoute<void>(
            builder: (_) =>
                WarmupSessionScreen(dayTemplate: dayTemplate ?? defaultDay),
          );
        }
        return null;
      },
      home: SplashScreen(child: _buildHomeScreen()),
    );
  }

  Widget _buildHomeScreen() {
    const String screen = String.fromEnvironment('SCREEN');
    if (screen == 'workout') {
      return WorkoutSessionScreen(
        dayTemplate: ProgramCycle.getBuiltInProgram().first,
      );
    } else if (screen == 'recovery') {
      return RecoverySessionScreen(
        routine: RecoveryEngineService.generateRoutine(
          ratioAnalyses: <LiftRatioAnalysis>[],
          lastSession: null,
        ),
      );
    }
    return const MainNavigationContainer(
      
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const new({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = <Widget>[
      DashboardScreen(onNavigateTab: _switchTab),
      const RecoverScreen(),
      const NutritionDashboardScreen(),
      const AnalyticsScreen(),
    ];
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const ActiveSessionMiniDock(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceCard,
            selectedItemColor: AppTheme.primaryAmber,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_outlined),
                activeIcon: Icon(Icons.fitness_center_rounded),
                label: 'TRAIN',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.self_improvement_outlined),
                activeIcon: Icon(Icons.self_improvement_rounded),
                label: 'RECOVER',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_outlined),
                activeIcon: Icon(Icons.restaurant_rounded),
                label: 'FUEL',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights_rounded),
                label: 'INSIGHTS',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
