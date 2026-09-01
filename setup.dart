#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

/// ANSI Color and Style Codes for rich terminal formatting.
class Ansi {
  static final bool supportsAnsi =
      stdout.hasTerminal && (Platform.environment['TERM'] != 'dumb');

  static String color(String code, String text) =>
      supportsAnsi ? '\x1B[${code}m$text\x1B[0m' : text;

  static String bold(String text) => color('1', text);
  static String dim(String text) => color('2', text);
  static String italic(String text) => color('3', text);
  static String green(String text) => color('32', text);
  static String yellow(String text) => color('33', text);
  static String red(String text) => color('31', text);
  static String cyan(String text) => color('36', text);
  static String blue(String text) => color('34', text);
  static String magenta(String text) => color('35', text);
  static String brightGreen(String text) => color('92', text);
  static String brightCyan(String text) => color('96', text);
  static String brightYellow(String text) => color('93', text);
  static String gray(String text) => color('90', text);

  static String check() => brightGreen('✓');
  static String cross() => red('✗');
  static String arrow() => brightCyan('➜');
  static String bullet() => dim('•');
  static String star() => brightYellow('★');
}

/// Configuration parsed from CLI arguments.
class SetupConfig {
  bool quick = false;
  bool skipPub = false;
  bool skipDb = false;
  bool skipExerciseDb = false;
  bool skipUsdaDb = false;
  bool runTests = false;
  bool runAnalyze = false;
  bool clean = false;
  bool showHelp = false;

  static SetupConfig parse(List<String> args) {
    final config = SetupConfig();
    for (final arg in args) {
      switch (arg.toLowerCase()) {
        case '-h':
        case '--help':
        case 'help':
          config.showHelp = true;
          break;
        case '-q':
        case '--quick':
        case '--fast':
        case '--core':
          config.quick = true;
          break;
        case '--full':
          config.quick = false;
          break;
        case '--skip-pub':
        case '--no-pub':
          config.skipPub = true;
          break;
        case '--skip-db':
        case '--no-db':
          config.skipDb = true;
          break;
        case '--skip-exercise-db':
          config.skipExerciseDb = true;
          break;
        case '--skip-usda-db':
          config.skipUsdaDb = true;
          break;
        case '-t':
        case '--test':
        case '--verify':
          config.runTests = true;
          break;
        case '-a':
        case '--analyze':
          config.runAnalyze = true;
          break;
        case '--clean':
          config.clean = true;
          break;
        default:
          stdout.writeln(Ansi.yellow('⚠️  Unknown option: $arg (use --help for usage)'));
      }
    }
    return config;
  }
}

void printBanner() {
  stdout.writeln();
  stdout.writeln(Ansi.bold(Ansi.brightCyan('╔════════════════════════════════════════════════════════════════════╗')));
  stdout.writeln(Ansi.bold('${Ansi.brightCyan('║')}  🏋️   ${Ansi.bold(Ansi.brightYellow('OLY'))} — Olympic Weightlifting & Nutrition Environment Setup   ${Ansi.brightCyan('║')}'));
  stdout.writeln(Ansi.bold(Ansi.brightCyan('╚════════════════════════════════════════════════════════════════════╝')));
  stdout.writeln(Ansi.dim('  Automated dependency installation, toolchain validation & offline database builder.'));
  stdout.writeln();
}

void printHelp() {
  printBanner();
  stdout.writeln(Ansi.bold('USAGE:'));
  stdout.writeln('  dart setup.dart [options]');
  stdout.writeln('  dart run setup.dart [options]');
  stdout.writeln('  ./setup.dart [options]');
  stdout.writeln();
  stdout.writeln(Ansi.bold('OPTIONS:'));
  stdout.writeln('  ${Ansi.brightCyan('--full')}               Build full 2.06M+ offline USDA & Restaurant database (${Ansi.dim('default')})');
  stdout.writeln('  ${Ansi.brightCyan('-q, --quick')}          Build fast lightweight core whole foods & fast-food database (~20MB in ~2s)');
  stdout.writeln('  ${Ansi.brightCyan('--skip-pub')}           Skip `flutter pub get` dependency installation');
  stdout.writeln('  ${Ansi.brightCyan('--skip-db')}            Skip building all SQLite databases');
  stdout.writeln('  ${Ansi.brightCyan('--skip-exercise-db')}   Skip building the 2,748+ exercise SQLite database');
  stdout.writeln('  ${Ansi.brightCyan('--skip-usda-db')}       Skip building the USDA food SQLite database');
  stdout.writeln('  ${Ansi.brightCyan('-t, --test, --verify')} Run `flutter test` after setup to verify tests pass');
  stdout.writeln('  ${Ansi.brightCyan('-a, --analyze')}        Run `flutter analyze` after setup');
  stdout.writeln('  ${Ansi.brightCyan('--clean')}              Remove existing .db files and caches before rebuilding');
  stdout.writeln('  ${Ansi.brightCyan('-h, --help')}           Show this help message');
  stdout.writeln();
  stdout.writeln(Ansi.bold('EXAMPLES:'));
  stdout.writeln('  ${Ansi.dim('# Standard setup after a fresh clone (installs dependencies & builds full databases):')}');
  stdout.writeln('  dart setup.dart');
  stdout.writeln();
  stdout.writeln('  ${Ansi.dim('# Fast setup for quick local UI development & widgets:')}');
  stdout.writeln('  dart setup.dart --quick');
  stdout.writeln();
  stdout.writeln('  ${Ansi.dim('# Setup with full test suite verification:')}');
  stdout.writeln('  dart setup.dart --verify');
  stdout.writeln();
}

/// Helper to format file sizes in human-readable units.
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Runs a command, optionally streaming or capturing its stdout/stderr.
Future<ProcessResult> runStep({
  required String stepName,
  required String executable,
  required List<String> arguments,
  required String workingDirectory,
  bool streamOutput = false,
}) async {
  final stopwatch = Stopwatch()..start();
  stdout.write('  ${Ansi.arrow()} ${Ansi.bold(stepName)}... ');
  if (streamOutput) {
    stdout.writeln();
  }

  try {
    if (streamOutput) {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: Platform.environment,
        mode: ProcessStartMode.inheritStdio,
      );
      final exitCode = await process.exitCode;
      stopwatch.stop();
      final elapsed = '(${stopwatch.elapsed.inSeconds}.${(stopwatch.elapsed.inMilliseconds % 1000) ~/ 100}s)';
      if (exitCode == 0) {
        stdout.writeln('  ${Ansi.check()} ${Ansi.green('$stepName succeeded')} ${Ansi.dim(elapsed)}');
        return ProcessResult(process.pid, 0, '', '');
      } else {
        stdout.writeln('  ${Ansi.cross()} ${Ansi.red('$stepName failed')} (exit code: $exitCode)');
        return ProcessResult(process.pid, exitCode, '', 'Process exited with code $exitCode');
      }
    } else {
      final result = await Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
      );
      stopwatch.stop();
      final elapsed = '(${stopwatch.elapsed.inSeconds}.${(stopwatch.elapsed.inMilliseconds % 1000) ~/ 100}s)';

      if (result.exitCode == 0) {
        stdout.writeln('${Ansi.check()} ${Ansi.dim(elapsed)}');
      } else {
        stdout.writeln('${Ansi.cross()} ${Ansi.red('failed')} ${Ansi.dim(elapsed)}');
        if (result.stdout.toString().trim().isNotEmpty) {
          stdout.writeln(Ansi.gray(result.stdout.toString().trim()));
        }
        if (result.stderr.toString().trim().isNotEmpty) {
          stderr.writeln(Ansi.red(result.stderr.toString().trim()));
        }
      }
      return result;
    }
  } catch (e) {
    stopwatch.stop();
    stdout.writeln('${Ansi.cross()} ${Ansi.red('error')}');
    stderr.writeln(Ansi.red('  Error executing $executable: $e'));
    return ProcessResult(-1, -1, '', e.toString());
  }
}

/// Finds the appropriate python3 binary.
Future<String?> findPythonExecutable() async {
  for (final candidate in ['python3', 'python']) {
    try {
      final res = await Process.run(candidate, ['--version']);
      if (res.exitCode == 0) {
        return candidate;
      }
    } catch (_) {}
  }
  return null;
}

/// Verifies prerequisites (Flutter, Dart, Python, and project directory structure).
Future<bool> preflightCheck(Directory projectRoot, String? pythonCmd) async {
  stdout.writeln(Ansi.bold(Ansi.brightCyan('🔍 Step 1: Toolchain & System Pre-flight Check')));

  // 1. Verify project root
  final pubspecFile = File('${projectRoot.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln(Ansi.red('  ${Ansi.cross()} Error: pubspec.yaml not found. Please run setup.dart from the repository root.'));
    return false;
  }
  stdout.writeln('  ${Ansi.check()} Project Root: ${Ansi.dim(projectRoot.path)}');

  // 2. Verify Flutter
  try {
    final flutterRes = await Process.run('flutter', ['--version']);
    if (flutterRes.exitCode == 0) {
      final firstLine = flutterRes.stdout.toString().split('\n').first.trim();
      stdout.writeln('  ${Ansi.check()} Flutter SDK: ${Ansi.dim(firstLine)}');
    } else {
      stderr.writeln(Ansi.yellow('  ⚠️ Flutter CLI returned non-zero exit code. Ensure Flutter is added to PATH.'));
    }
  } catch (e) {
    stderr.writeln(Ansi.red('  ${Ansi.cross()} Error: `flutter` command not found in PATH. Please install Flutter or add it to PATH.'));
    return false;
  }

  // 3. Verify Dart
  try {
    final dartRes = await Process.run('dart', ['--version']);
    final dartVer = (dartRes.stdout.toString() + dartRes.stderr.toString()).trim().split('\n').first;
    stdout.writeln('  ${Ansi.check()} Dart SDK: ${Ansi.dim(dartVer)}');
  } catch (e) {
    stderr.writeln(Ansi.red('  ${Ansi.cross()} Error: `dart` command not found in PATH.'));
    return false;
  }

  // 4. Verify Python 3
  if (pythonCmd == null) {
    stderr.writeln(Ansi.red('  ${Ansi.cross()} Error: Python 3 not found. Python 3 is required for building SQLite datasets.'));
    stderr.writeln(Ansi.dim('      Please install Python 3 (https://www.python.org/ or `brew install python3`).'));
    return false;
  }
  try {
    final pyRes = await Process.run(pythonCmd, ['--version']);
    final pyVer = (pyRes.stdout.toString() + pyRes.stderr.toString()).trim();
    stdout.writeln('  ${Ansi.check()} Python 3: ${Ansi.dim(pyVer)} ($pythonCmd)');
  } catch (_) {}

  stdout.writeln();
  return true;
}

Future<void> cleanArtifacts(Directory projectRoot) async {
  stdout.writeln(Ansi.bold(Ansi.brightCyan('🧹 Cleaning Previous Database Artifacts & Caches')));
  final pathsToClean = [
    '${projectRoot.path}/assets/data/exercises.db',
    '${projectRoot.path}/assets/data/exercises.db-shm',
    '${projectRoot.path}/assets/data/exercises.db-wal',
    '${projectRoot.path}/assets/data/usda_foods.db',
    '${projectRoot.path}/assets/data/usda_foods.db-shm',
    '${projectRoot.path}/assets/data/usda_foods.db-wal',
  ];

  for (final path in pathsToClean) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
      stdout.writeln('  ${Ansi.bullet()} Deleted ${Ansi.dim(path)}');
    }
  }
  stdout.writeln('  ${Ansi.check()} Clean completed.\n');
}

Future<void> main(List<String> args) async {
  final overallStopwatch = Stopwatch()..start();
  final config = SetupConfig.parse(args);

  if (config.showHelp) {
    printHelp();
    exit(0);
  }

  printBanner();

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectRoot = scriptDir;

  final pythonCmd = await findPythonExecutable();

  final preflightOk = await preflightCheck(projectRoot, pythonCmd);
  if (!preflightOk) {
    stderr.writeln(Ansi.red('Setup aborted due to pre-flight check failures.'));
    exit(1);
  }

  if (config.clean) {
    await cleanArtifacts(projectRoot);
  }

  // -------------------------------------------------------------
  // Step 2: Install Flutter Dependencies
  // -------------------------------------------------------------
  if (!config.skipPub) {
    stdout.writeln(Ansi.bold(Ansi.brightCyan('📦 Step 2: Fetching Flutter Dependencies (pub get)')));
    final pubResult = await runStep(
      stepName: 'flutter pub get',
      executable: 'flutter',
      arguments: ['pub', 'get'],
      workingDirectory: projectRoot.path,
    );
    if (pubResult.exitCode != 0) {
      stderr.writeln(Ansi.red('Failed to fetch Flutter dependencies. Please check pubspec.yaml.'));
      exit(pubResult.exitCode);
    }
    stdout.writeln();
  } else {
    stdout.writeln(Ansi.dim('⏩ Skipping dependency installation (--skip-pub)\n'));
  }

  // -------------------------------------------------------------
  // Step 3: Compile Datasets & Build SQLite Databases
  // -------------------------------------------------------------
  if (!config.skipDb) {
    stdout.writeln(Ansi.bold(Ansi.brightCyan('🗄️  Step 3: Building Embedded SQLite Databases & Assets')));

    // 3A: Restaurant catalog
    stdout.writeln(Ansi.dim('  3a. Generating restaurant menus catalog...'));
    final restaurantResult = await runStep(
      stepName: 'Generate restaurant catalog',
      executable: pythonCmd!,
      arguments: ['scripts/generate_restaurant_catalog.py'],
      workingDirectory: projectRoot.path,
    );
    if (restaurantResult.exitCode != 0) {
      stderr.writeln(Ansi.red('Failed generating restaurant catalog.'));
      exit(restaurantResult.exitCode);
    }

    // 3B: Exercise database
    if (!config.skipExerciseDb) {
      stdout.writeln(Ansi.dim('  3b. Aggregating & indexing 2,748+ exercises (Free Exercise DB, wger, exercises-dataset)...'));
      final exerciseResult = await runStep(
        stepName: 'Build exercise database',
        executable: pythonCmd,
        arguments: ['scripts/build_exercise_sqlite.py'],
        workingDirectory: projectRoot.path,
      );
      if (exerciseResult.exitCode != 0) {
        stderr.writeln(Ansi.red('Failed building exercise database.'));
        exit(exerciseResult.exitCode);
      }
    } else {
      stdout.writeln(Ansi.dim('  ⏩ Skipping exercise database build (--skip-exercise-db)'));
    }

    // 3C: USDA foods database
    if (!config.skipUsdaDb) {
      if (config.quick) {
        stdout.writeln(Ansi.dim('  3c. Building core whole foods & fast-food SQLite database (lightweight mode)...'));
        final usdaQuickResult = await runStep(
          stepName: 'Build core USDA SQLite database',
          executable: pythonCmd,
          arguments: ['scripts/build_usda_sqlite.py'],
          workingDirectory: projectRoot.path,
        );
        if (usdaQuickResult.exitCode != 0) {
          stderr.writeln(Ansi.red('Failed building core USDA database.'));
          exit(usdaQuickResult.exitCode);
        }
      } else {
        stdout.writeln(Ansi.dim('  3c. Ingesting full 2.06M+ USDA FoodData Central & Branded Products database...'));
        stdout.writeln(Ansi.gray('      (Extracts Foundation, SR Legacy, Survey FNDDS, and 1.98M+ barcoded products with FTS5 search)'));
        final usdaBulkResult = await runStep(
          stepName: 'Build full USDA 2.06M+ SQLite database',
          executable: pythonCmd,
          arguments: ['scripts/import_usda_bulk.py'],
          workingDirectory: projectRoot.path,
          streamOutput: true,
        );
        if (usdaBulkResult.exitCode != 0) {
          stderr.writeln(Ansi.red('Failed building full USDA database.'));
          exit(usdaBulkResult.exitCode);
        }
      }
    } else {
      stdout.writeln(Ansi.dim('  ⏩ Skipping USDA foods database build (--skip-usda-db)'));
    }

    stdout.writeln();
  } else {
    stdout.writeln(Ansi.dim('⏩ Skipping database compilation (--skip-db)\n'));
  }

  // -------------------------------------------------------------
  // Step 4: Asset Verification & Inspection
  // -------------------------------------------------------------
  stdout.writeln(Ansi.bold(Ansi.brightCyan('📊 Step 4: Database & Asset Verification Summary')));

  final exerciseDbFile = File('${projectRoot.path}/assets/data/exercises.db');
  final usdaDbFile = File('${projectRoot.path}/assets/data/usda_foods.db');
  final restaurantJsonFile = File('${projectRoot.path}/assets/data/restaurant_foods.json');
  final stapleJsonFile = File('${projectRoot.path}/assets/data/staple_foods.json');

  void printAssetStatus(String name, File file, {bool isCritical = true}) {
    if (file.existsSync() && file.lengthSync() > 0) {
      final size = formatBytes(file.lengthSync());
      stdout.writeln('  ${Ansi.check()} $name: ${Ansi.brightGreen(size)} ${Ansi.dim('(${file.path.split('/').last})')}');
    } else {
      if (isCritical) {
        stdout.writeln('  ${Ansi.cross()} $name: ${Ansi.red('Missing or Empty')}');
      } else {
        stdout.writeln('  ${Ansi.bullet()} $name: ${Ansi.dim('Not generated')}');
      }
    }
  }

  printAssetStatus('Exercise SQLite Database', exerciseDbFile);
  printAssetStatus('USDA Foods SQLite Database', usdaDbFile);
  printAssetStatus('Restaurant Menu Catalog', restaurantJsonFile);
  printAssetStatus('Staple Foods Catalog', stapleJsonFile);
  stdout.writeln();

  // -------------------------------------------------------------
  // Step 5: Optional Lint Analysis & Testing
  // -------------------------------------------------------------
  if (config.runAnalyze) {
    stdout.writeln(Ansi.bold(Ansi.brightCyan('🔍 Step 5: Running Flutter Analyze')));
    final analyzeResult = await runStep(
      stepName: 'flutter analyze',
      executable: 'flutter',
      arguments: ['analyze'],
      workingDirectory: projectRoot.path,
      streamOutput: true,
    );
    if (analyzeResult.exitCode != 0) {
      stderr.writeln(Ansi.yellow('⚠️  Flutter analyze reported warnings or issues.'));
    }
    stdout.writeln();
  }

  if (config.runTests) {
    stdout.writeln(Ansi.bold(Ansi.brightCyan('🧪 Step 5: Running Flutter Test Suite')));
    final testResult = await runStep(
      stepName: 'flutter test',
      executable: 'flutter',
      arguments: ['test'],
      workingDirectory: projectRoot.path,
      streamOutput: true,
    );
    if (testResult.exitCode != 0) {
      stderr.writeln(Ansi.red('Some tests failed during post-setup verification.'));
    }
    stdout.writeln();
  }

  overallStopwatch.stop();
  final totalElapsed = '${overallStopwatch.elapsed.inMinutes}m ${overallStopwatch.elapsed.inSeconds % 60}s';

  stdout.writeln(Ansi.bold(Ansi.brightGreen('╔════════════════════════════════════════════════════════════════════╗')));
  stdout.writeln(Ansi.bold('${Ansi.brightGreen('║')}  🎉   ${Ansi.bold(Ansi.brightYellow('OLY Environment Setup Completed Successfully!'))}         ${Ansi.brightGreen('║')}'));
  stdout.writeln(Ansi.bold(Ansi.brightGreen('╚════════════════════════════════════════════════════════════════════╝')));
  stdout.writeln('  ${Ansi.star()} Total time elapsed: ${Ansi.bold(totalElapsed)}');
  stdout.writeln();
  stdout.writeln(Ansi.bold('Next Steps:'));
  stdout.writeln('  ${Ansi.bullet()} Launch on iOS Simulator:    ${Ansi.brightCyan('flutter run -d iPhone')}');
  stdout.writeln('  ${Ansi.bullet()} Launch specific screen:      ${Ansi.brightCyan('flutter run --dart-define=TAB=5')} (0=Home, 5=Nutrition)');
  stdout.writeln('  ${Ansi.bullet()} Run verification tests:      ${Ansi.brightCyan('flutter test')}');
  stdout.writeln('  ${Ansi.bullet()} Capture view screenshots:    ${Ansi.brightCyan('flutter test test/screenshot_capture_test.dart')}');
  stdout.writeln();
}
