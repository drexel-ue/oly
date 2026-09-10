#!/usr/bin/env dart

import 'dart:io';

import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/services/crossfit_scraper_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main(List<String> args) async {
  stdout.writeln();
  stdout.writeln('================================================================');
  stdout.writeln('🏋️  CrossFit.com Hero Workouts & Movements Ingestion Pipeline');
  stdout.writeln('================================================================');

  bool force = false;
  bool skipHeroes = false;
  bool skipMovements = false;
  int? limit;
  String dbRelativePath = 'assets/data/exercises.db';

  for (int i = 0; i < args.length; i++) {
    final arg = args[i].toLowerCase();
    if (arg == '--force' || arg == '-f') {
      force = true;
    } else if (arg == '--skip-heroes') {
      skipHeroes = true;
    } else if (arg == '--skip-movements') {
      skipMovements = true;
    } else if (arg.startsWith('--limit=') || arg.startsWith('-l=')) {
      limit = int.tryParse(arg.split('=')[1]);
    } else if ((arg == '--limit' || arg == '-l') && i + 1 < args.length) {
      limit = int.tryParse(args[++i]);
    } else if (arg.startsWith('--db=')) {
      dbRelativePath = args[i].split('=')[1];
    }
  }

  final stopwatch = Stopwatch()..start();
  final scraper = CrossfitScraperService();

  // 1. Scrape Hero Workouts
  List<CrossfitHeroWod>? heroWods;
  if (!skipHeroes) {
    stdout.writeln('\n📋 Step 1: Scraping official CrossFit Hero Workouts (crossfit.com/heroes/)...');
    try {
      heroWods = await scraper.scrapeHeroWods(
        force: force,
        limit: limit,
        onProgress: (msg) => stdout.writeln('  ➜ $msg'),
      );
      stdout.writeln('  ✓ Total Hero Workouts parsed: ${heroWods.length}');
    } catch (e, st) {
      stderr.writeln('  ✗ Failed to scrape Hero Workouts: $e\n$st');
    }
  }

  // 2. Scrape CrossFit Movements
  List<Map<String, dynamic>>? movements;
  if (!skipMovements) {
    stdout.writeln('\n🤸 Step 2: Scraping official CrossFit Movements (crossfit.com/crossfit-movements)...');
    try {
      movements = await scraper.scrapeMovements(
        force: force,
        limit: limit,
        onProgress: (msg) => stdout.writeln('  ➜ $msg'),
      );
      stdout.writeln('  ✓ Total Movements parsed: ${movements.length}');
    } catch (e, st) {
      stderr.writeln('  ✗ Failed to scrape Movements: $e\n$st');
    }
  }

  // 3. Export Bundled JSON for offline resilience
  stdout.writeln('\n📦 Step 3: Exporting bundled JSON datasets to assets/data/...');
  try {
    await scraper.exportBundledJson(
      heroWods: heroWods,
      movements: movements,
    );
    stdout.writeln('  ✓ Exported crossfit_hero_wods.json and crossfit_movements.json');
  } catch (e) {
    stderr.writeln('  ✗ Failed to export bundled JSON: $e');
  }

  // 4. Save to SQLite Database
  final dbFile = File(p.join(Directory.current.path, dbRelativePath));
  stdout.writeln('\n💾 Step 4: Storing data in SQLite database at ${dbFile.path}...');

  if (!dbFile.existsSync()) {
    stdout.writeln('  ⚠️ Database file not found at ${dbFile.path}. Creating parent directory...');
    dbFile.parent.createSync(recursive: true);
  }

  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(dbFile.path);

  try {
    await scraper.saveToDatabase(
      db,
      heroWods: heroWods,
      movements: movements,
      onProgress: (msg) => stdout.writeln('  ➜ $msg'),
    );

    // Verify counts in DB
    final heroCountRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM hero_wods');
    final heroCount = heroCountRes.first['cnt']! as int;

    final cfMovementsRes = await db.rawQuery("SELECT COUNT(*) as cnt FROM exercises WHERE source = 'crossfit'");
    final cfMovementCount = cfMovementsRes.first['cnt']! as int;

    final totalExercisesRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM exercises');
    final totalExerciseCount = totalExercisesRes.first['cnt']! as int;

    stdout.writeln('\n================================================================');
    stdout.writeln('🎉 Successfully ingested CrossFit data into SQLite!');
    stdout.writeln('  • Total Hero Workouts in Database: $heroCount');
    stdout.writeln('  • CrossFit Essential Movements in Database: $cfMovementCount');
    stdout.writeln('  • Total Exercises (All Sources): $totalExerciseCount');
    stdout.writeln('  • Elapsed Time: ${stopwatch.elapsed.inSeconds}.${(stopwatch.elapsed.inMilliseconds % 1000) ~/ 100}s');
    stdout.writeln('================================================================\n');
  } finally {
    await db.close();
  }
}
