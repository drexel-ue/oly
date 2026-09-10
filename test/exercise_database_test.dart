import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/exercise_database_model.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/services/exercise_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ExerciseDatabaseModel Unit Tests', () {
    test('Correctly serializes and deserializes SQLite maps and JSON', () {
      const ExerciseDatabaseModel model = ExerciseDatabaseModel(
        id: 'fedb_barbell_bench_press',
        name: 'Barbell Bench Press',
        category: 'strength',
        bodyPart: 'chest',
        targetMuscle: 'pectorals',
        secondaryMuscles: <String>['triceps', 'deltoids'],
        equipment: 'barbell',
        mechanic: 'compound',
        force: 'push',
        level: 'intermediate',
        instructions: '1. Lie on bench.\n2. Lower bar to chest.\n3. Press up.',
        tips: 'Keep wrists straight and drive through legs.',
        source: 'free_exercise_db',
        sourceId: 'barbell_bench_press',
        gifUrl: 'https://example.com/bench.gif',
      );

      final Map<String, dynamic> sqliteMap = model.toSqlite();
      expect(sqliteMap['id'], 'fedb_barbell_bench_press');
      expect(sqliteMap['secondary_muscles'], '["triceps","deltoids"]');

      final ExerciseDatabaseModel fromDb = ExerciseDatabaseModel.fromSqlite(sqliteMap);
      expect(fromDb.id, 'fedb_barbell_bench_press');
      expect(fromDb.name, 'Barbell Bench Press');
      expect(fromDb.displayCategory, 'Strength');
      expect(fromDb.displayBodyPart, 'Chest');
      expect(fromDb.displayTargetMuscle, 'Pectorals (Chest)');
      expect(fromDb.secondaryMuscles, contains('triceps'));
      expect(fromDb.secondaryMuscles, contains('deltoids'));
      expect(fromDb.mechanic, 'compound');
      expect(fromDb.force, 'push');

      final Map<String, dynamic> jsonMap = model.toJson();
      final ExerciseDatabaseModel fromJson = ExerciseDatabaseModel.fromJson(jsonMap);
      expect(fromJson.name, model.name);
      expect(fromJson.source, model.source);
    });
  });

  group('ExerciseDatabaseService SQLite Integration Tests', () {
    late ExerciseDatabaseService service;

    setUpAll(() async {
      final String dbPath = '${Directory.current.path}/assets/data/exercises.db';
      expect(File(dbPath).existsSync(), isTrue,
          reason: 'assets/data/exercises.db should exist from build_exercise_sqlite.py');
      service = ExerciseDatabaseService(dbPath: dbPath);
      await service.initDatabase();
    });

    tearDownAll(() async {
      await service.close();
    });

    test('Total exercise count reflects deduplicated catalog (>2,500 unique exercises)', () async {
      final int total = await service.getTotalCount();
      expect(total, greaterThanOrEqualTo(2500));
      expect(total, lessThan(3074)); // Confirms duplicates were merged
    });

    test('Merged exercises retain multi-source attribution and full metadata', () async {
      final List<ExerciseDatabaseModel> frontSquats = await service.search(
        'Front Squat',
        equipment: 'barbell',
      );
      expect(frontSquats.isNotEmpty, isTrue);
      final ExerciseDatabaseModel primary = frontSquats.firstWhere(
        (ExerciseDatabaseModel e) => e.source.contains('oly_curated'),
      );
      expect(primary.name, 'Front Squat');
      expect(primary.targetMuscle, 'quadriceps');
      expect(primary.equipment, 'barbell');
      expect(primary.source, contains('oly_curated'));
      expect(primary.source, contains('free_exercise_db'));
    });

    test('Fetches distinct metadata categories, muscles, and equipment', () async {
      final List<String> categories = await service.getCategories();
      expect(categories, contains('strength'));
      expect(categories, contains('olympic_weightlifting'));
      expect(categories, contains('cardio'));
      expect(categories, contains('core'));

      final List<String> muscles = await service.getTargetMuscles();
      expect(muscles, contains('abs'));
      expect(muscles, contains('deltoids'));
      expect(muscles, contains('quadriceps'));
      expect(muscles, contains('pectorals'));

      final List<String> equipment = await service.getEquipmentList();
      expect(equipment, contains('barbell'));
      expect(equipment, contains('dumbbell'));
      expect(equipment, contains('kettlebell'));
      expect(equipment, contains('cable'));
    });

    test('Finds curated Olympic lift by exact ID with merged source tags', () async {
      final ExerciseDatabaseModel? snatch = await service.getById('oly_snatch');
      expect(snatch, isNotNull);
      expect(snatch!.name, 'Snatch');
      expect(snatch.category, 'olympic_weightlifting');
      expect(snatch.equipment, 'barbell');
      expect(snatch.source, contains('oly_curated'));
      expect(snatch.instructions, isNotEmpty);
      expect(snatch.instructions, contains('overhead'));
    });

    test('FTS5 full-text search retrieves relevant Olympic and strength movements', () async {
      final List<ExerciseDatabaseModel> snatchResults = await service.search('snatch');
      expect(snatchResults.isNotEmpty, isTrue);
      expect(snatchResults.any((ExerciseDatabaseModel e) => e.name.toLowerCase().contains('snatch')), isTrue);

      final List<ExerciseDatabaseModel> benchResults = await service.search('bench press');
      expect(benchResults.isNotEmpty, isTrue);
      expect(benchResults.any((ExerciseDatabaseModel e) => e.name.toLowerCase().contains('bench')), isTrue);

      // Search for Bayesian curl with standard spelling and common typo 'baysean'
      final List<ExerciseDatabaseModel> bayesianResults = await service.search('Bayesian');
      expect(bayesianResults.isNotEmpty, isTrue);
      expect(bayesianResults.any((ExerciseDatabaseModel e) => e.name.contains('Bayesian')), isTrue);

      final List<ExerciseDatabaseModel> typoResults = await service.search('baysean');
      expect(typoResults.isNotEmpty, isTrue);
      expect(typoResults.any((ExerciseDatabaseModel e) => e.name.contains('Bayesian')), isTrue);

      // Search for GHD Sit-Up across various spelling and hyphen formats
      final List<ExerciseDatabaseModel> ghdResults = await service.search('ghd sit up');
      expect(ghdResults.isNotEmpty, isTrue);
      expect(ghdResults.any((ExerciseDatabaseModel e) => e.name == 'GHD Sit-Up'), isTrue);

      final List<ExerciseDatabaseModel> ghdHyphenResults = await service.search('ghd sit-up');
      expect(ghdHyphenResults.isNotEmpty, isTrue);
      expect(ghdHyphenResults.any((ExerciseDatabaseModel e) => e.name == 'GHD Sit-Up'), isTrue);

      final List<ExerciseDatabaseModel> ghdCompoundResults = await service.search('ghd situp');
      expect(ghdCompoundResults.isNotEmpty, isTrue);
      expect(ghdCompoundResults.any((ExerciseDatabaseModel e) => e.name == 'GHD Sit-Up'), isTrue);
    });

    test('Filters search results by category, muscle, and equipment', () async {
      final List<ExerciseDatabaseModel> kettlebellCardio = await service.search(
        '',
        category: 'cardio',
        equipment: 'kettlebell',
      );
      expect(kettlebellCardio.isNotEmpty, isTrue);
      for (final ExerciseDatabaseModel ex in kettlebellCardio) {
        expect(ex.category, 'cardio');
        expect(ex.equipment, 'kettlebell');
      }

      final List<ExerciseDatabaseModel> quadExercises = await service.search(
        '',
        targetMuscle: 'quadriceps',
        equipment: 'barbell',
      );
      expect(quadExercises.isNotEmpty, isTrue);
      for (final ExerciseDatabaseModel ex in quadExercises) {
        expect(ex.targetMuscle, 'quadriceps');
        expect(ex.equipment, 'barbell');
      }
    });

    test('Supports pagination with limit and offset', () async {
      final List<ExerciseDatabaseModel> page1 = await service.search('squat', limit: 5, offset: 0);
      final List<ExerciseDatabaseModel> page2 = await service.search('squat', limit: 5, offset: 5);

      expect(page1.length, lessThanOrEqualTo(5));
      expect(page2.length, lessThanOrEqualTo(5));
      if (page1.isNotEmpty && page2.isNotEmpty) {
        expect(page1.first.id, isNot(equals(page2.first.id)));
      }
    });

    test('Hero WODs table is populated and queried correctly', () async {
      final int heroCount = await service.getHeroWodCount();
      expect(heroCount, greaterThanOrEqualTo(240));

      final List<CrossfitHeroWod> allHeroWods = await service.getHeroWods(limit: 300);
      expect(allHeroWods.length, equals(heroCount));

      // Query Murph
      final CrossfitHeroWod? murph = await service.getHeroWodBySlug('murph');
      expect(murph, isNotNull);
      expect(murph!.name, contains('Murph'));
      expect(murph.tributeText, isNotEmpty);

      // Query DT
      final CrossfitHeroWod? dt = await service.getHeroWodBySlug('dt');
      expect(dt, isNotNull);
      expect(dt!.name, contains('DT'));
      expect(dt.format, equals(WodFormat.forTime));

      // FTS search for hero workout
      final List<CrossfitHeroWod> searchResults = await service.getHeroWods(query: 'Michael');
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.any((CrossfitHeroWod w) => w.name.toLowerCase().contains('michael')), isTrue);
    });

    test('CrossFit Movements are ingested into exercises table with source crossfit', () async {
      final List<ExerciseDatabaseModel> cfMovements = await service.search('', limit: 3000);
      final List<ExerciseDatabaseModel> cfOnly =
          cfMovements.where((ExerciseDatabaseModel e) => e.source.contains('crossfit')).toList();
      expect(cfOnly.isNotEmpty, isTrue);
      expect(cfOnly.length, greaterThanOrEqualTo(100));

      final ExerciseDatabaseModel thruster =
          cfOnly.firstWhere((ExerciseDatabaseModel e) => e.name.toLowerCase().contains('thruster'));
      expect(thruster.name, isNotEmpty);
      expect(thruster.source, 'crossfit');
    });
  });
}
