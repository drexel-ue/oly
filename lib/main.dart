import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/body_comp_provider.dart';
import 'providers/lift_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/program_provider.dart';
import 'providers/recovery_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'models/program_model.dart';
import 'services/recovery_engine_service.dart';
import 'views/analytics_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/lifts_screen.dart';
import 'views/max_test_screen.dart';
import 'views/nutrition/nutrition_dashboard_screen.dart';
import 'views/plate_calculator_screen.dart';
import 'views/recovery_session_screen.dart';
import 'views/splash_screen.dart';
import 'views/warmup_session_screen.dart';
import 'views/workout_session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LiftProvider(storageService)),
        ChangeNotifierProvider(create: (_) => ProgramProvider(storageService)),
        ChangeNotifierProvider(create: (_) => RecoveryProvider(storageService)),
        ChangeNotifierProvider(create: (_) => BodyCompProvider(storageService)),
        ChangeNotifierProvider(create: (_) => NutritionProvider(storageService)),
      ],
      child: const OlyApp(),
    ),
  );
}

class OlyApp extends StatelessWidget {
  const OlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oly - Olympic Weightlifting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/warmup') {
          final dayTemplate = settings.arguments as DayTemplate?;
          final defaultDay = ProgramCycle.getBuiltInProgram().first;
          return MaterialPageRoute(
            builder: (_) => WarmupSessionScreen(
              dayTemplate: dayTemplate ?? defaultDay,
            ),
          );
        }
        return null;
      },
      home: SplashScreen(
        child: _buildHomeScreen(),
      ),
    );
  }

  Widget _buildHomeScreen() {
    const screen = String.fromEnvironment('SCREEN');
    if (screen == 'workout') {
      return WorkoutSessionScreen(
        dayTemplate: ProgramCycle.getBuiltInProgram().first,
      );
    } else if (screen == 'recovery') {
      return RecoverySessionScreen(
        routine: RecoveryEngineService.generateRoutine(
          ratioAnalyses: [],
          lastSession: null,
        ),
      );
    }
    return const MainNavigationContainer(
      initialIndex: int.fromEnvironment('TAB', defaultValue: 0),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  final int initialIndex;

  const MainNavigationContainer({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const LiftsScreen(),
    const NutritionDashboardScreen(),
    const PlateCalculatorScreen(),
    const MaxTestScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Lifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Loader',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Max Test',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
