import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/exercise_database_model.dart';
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
        (ExerciseDatabaseModel e) => e.name.toLowerCase() == 'front squat',
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
  });
}
