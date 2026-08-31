import 'dart:io';

import 'package:flutter/services.dart';
import 'package:oly/models/exercise_database_model.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Embedded local SQLite database service providing high-performance full-text search (FTS5)
/// and filtering across 3,000+ exercises from Free Exercise DB, wger, Exercises-Dataset, and Oly curated catalogs.
class ExerciseDatabaseService {
  ExerciseDatabaseService({Database? db, String? dbPath})
      : _customDbPath = dbPath {
    _db = db;
  }

  static ExerciseDatabaseService? _instance;
  static ExerciseDatabaseService get instance =>
      _instance ??= ExerciseDatabaseService();
  static void setMockInstance(ExerciseDatabaseService? mock) {
    _instance = mock;
  }

  Database? _db;
  final String? _customDbPath;
  bool _isInitializing = false;

  bool get isOpen => _db != null && _db!.isOpen;

  /// Initializes the SQLite database, copying from bundled assets on first launch.
  Future<Database?> initDatabase() async {
    if (_db != null && _db!.isOpen) {
      return _db;
    }

    if (_isInitializing) {
      while (_isInitializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _db;
    }

    _isInitializing = true;
    try {
      try {
        if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      } catch (_) {}

      if (_customDbPath != null) {
        _db = await openDatabase(_customDbPath);
        return _db;
      }

      // Check direct project asset path (fast-path for desktop / test runner)
      final String directAssetPath = p.join(
        Directory.current.path,
        'assets',
        'data',
        'exercises.db',
      );
      if (File(directAssetPath).existsSync()) {
        _db = await openDatabase(directAssetPath);
        return _db;
      }

      Directory appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        appDir = Directory.current;
      }
      final String dbPath = p.join(appDir.path, 'exercises.db');
      final File dbFile = File(dbPath);

      bool needsExtract = !dbFile.existsSync();
      if (!needsExtract) {
        try {
          final ByteData data = await rootBundle.load('assets/data/exercises.db');
          final int assetSize = data.lengthInBytes;
          final int existingSize = dbFile.lengthSync();
          if (existingSize != assetSize) {
            needsExtract = true;
            AppLogService.instance.info(
              'EXERCISE_DB',
              'Detected updated asset database ($assetSize vs $existingSize bytes). Overwriting local database...',
            );
          }
        } catch (_) {}
      }

      if (needsExtract) {
        try {
          if (_db != null && _db!.isOpen) {
            await _db!.close();
            _db = null;
          }
          if (dbFile.existsSync()) {
            dbFile.deleteSync();
          }

          final ByteData data = await rootBundle.load('assets/data/exercises.db');
          final List<int> bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await dbFile.writeAsBytes(bytes, flush: true);
          AppLogService.instance.info(
            'EXERCISE_DB',
            'Successfully extracted bundled exercise database (${bytes.length} bytes).',
          );
        } catch (e) {
          AppLogService.instance.warning(
            'EXERCISE_DB',
            'Could not extract asset database: $e',
          );
        }
      }

      if (dbFile.existsSync()) {
        _db = await openDatabase(dbPath);
      }
    } catch (e, st) {
      AppLogService.instance.error(
        'EXERCISE_DB',
        'Failed to initialize SQLite exercise database',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isInitializing = false;
    }

    return _db;
  }

  /// Sanitizes user query string for FTS5 syntax safety with common synonym expansion.
  String _sanitizeFtsQuery(String query) {
    String clean = query
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s_-]'), ' ')
        .trim();
    if (clean.isEmpty) {
      return '';
    }

    // Common fitness spelling & alias corrections
    clean = clean.replaceAll(RegExp(r'\bbayseans?\b', caseSensitive: false), 'bayesian');
    clean = clean.replaceAll(RegExp(r'\bpush-?ups?\b', caseSensitive: false), 'pushup');
    clean = clean.replaceAll(RegExp(r'\bpull-?ups?\b', caseSensitive: false), 'pullup');
    clean = clean.replaceAll(RegExp(r'\bchin-?ups?\b', caseSensitive: false), 'chinup');
    clean = clean.replaceAll(RegExp(r'\bsit-?ups?\b', caseSensitive: false), 'situp');

    final List<String> tokens = clean
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return '';
    }
    return tokens.map((String t) => '$t*').join(' ');
  }

  /// Searches exercises using FTS5 full-text match with optional filters and pagination.
  Future<List<ExerciseDatabaseModel>> search(
    String query, {
    String? category,
    String? bodyPart,
    String? targetMuscle,
    String? equipment,
    String? source,
    int limit = 50,
    int offset = 0,
  }) async {
    final Database? db = await initDatabase();
    if (db == null) {
      return <ExerciseDatabaseModel>[];
    }

    final String cleanQuery = query.trim();
    final String ftsQuery = _sanitizeFtsQuery(cleanQuery);

    final List<String> whereClauses = <String>[];
    final List<dynamic> whereArgs = <dynamic>[];

    if (category != null && category.isNotEmpty) {
      whereClauses.add('e.category = ?');
      whereArgs.add(category.toLowerCase());
    }
    if (bodyPart != null && bodyPart.isNotEmpty) {
      whereClauses.add('e.body_part = ?');
      whereArgs.add(bodyPart.toLowerCase());
    }
    if (targetMuscle != null && targetMuscle.isNotEmpty) {
      whereClauses.add('e.target_muscle = ?');
      whereArgs.add(targetMuscle.toLowerCase());
    }
    if (equipment != null && equipment.isNotEmpty) {
      whereClauses.add('e.equipment = ?');
      whereArgs.add(equipment.toLowerCase());
    }
    if (source != null && source.isNotEmpty) {
      whereClauses.add('e.source = ?');
      whereArgs.add(source.toLowerCase());
    }

    List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];

    if (ftsQuery.isNotEmpty) {
      String sql = '''
        SELECT e.*
        FROM exercises_fts fts
        JOIN exercises e ON e.rowid = fts.rowid
        WHERE exercises_fts MATCH ?
      ''';
      final List<dynamic> args = <dynamic>[ftsQuery];

      if (whereClauses.isNotEmpty) {
        sql += ' AND ${whereClauses.join(" AND ")}';
        args.addAll(whereArgs);
      }

      sql += ' ORDER BY rank, e.name ASC LIMIT ? OFFSET ?';
      args.add(limit);
      args.add(offset);

      try {
        rows = await db.rawQuery(sql, args);
      } catch (e) {
        AppLogService.instance.warning('EXERCISE_DB', 'FTS query failed: $e, falling back to LIKE');
      }
    }

    // Fallback or empty query with filters
    if (rows.isEmpty) {
      String fallbackSql = 'SELECT * FROM exercises e';
      final List<dynamic> fallbackArgs = <dynamic>[];
      final List<String> fallbackClauses = List<String>.from(whereClauses);

      if (cleanQuery.isNotEmpty) {
        fallbackClauses.add('(e.name LIKE ? OR e.target_muscle LIKE ?)');
        fallbackArgs.add('%$cleanQuery%');
        fallbackArgs.add('%$cleanQuery%');
      }
      fallbackArgs.addAll(whereArgs);

      if (fallbackClauses.isNotEmpty) {
        fallbackSql += ' WHERE ${fallbackClauses.join(" AND ")}';
      }

      fallbackSql += ' ORDER BY e.name ASC LIMIT ? OFFSET ?';
      fallbackArgs.add(limit);
      fallbackArgs.add(offset);

      rows = await db.rawQuery(fallbackSql, fallbackArgs);
    }

    return rows.map((Map<String, dynamic> r) => ExerciseDatabaseModel.fromSqlite(r)).toList();
  }

  /// Looks up a single exercise by ID.
  Future<ExerciseDatabaseModel?> getById(String id) async {
    final Database? db = await initDatabase();
    if (db == null) {
      return null;
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: <dynamic>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return ExerciseDatabaseModel.fromSqlite(rows.first);
  }

  /// Gets total number of exercises in the database.
  Future<int> getTotalCount() async {
    final Database? db = await initDatabase();
    if (db == null) {
      return 0;
    }
    final List<Map<String, dynamic>> res =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM exercises');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Gets distinct list of categories.
  Future<List<String>> getCategories() async {
    final Database? db = await initDatabase();
    if (db == null) {
      return <String>[];
    }
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT DISTINCT category FROM exercises ORDER BY category ASC',
    );
    return rows.map((Map<String, dynamic> r) => r['category'] as String).toList();
  }

  /// Gets distinct list of body parts.
  Future<List<String>> getBodyParts() async {
    final Database? db = await initDatabase();
    if (db == null) {
      return <String>[];
    }
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT DISTINCT body_part FROM exercises ORDER BY body_part ASC',
    );
    return rows.map((Map<String, dynamic> r) => r['body_part'] as String).toList();
  }

  /// Gets distinct list of target muscles.
  Future<List<String>> getTargetMuscles() async {
    final Database? db = await initDatabase();
    if (db == null) {
      return <String>[];
    }
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT DISTINCT target_muscle FROM exercises ORDER BY target_muscle ASC',
    );
    return rows.map((Map<String, dynamic> r) => r['target_muscle'] as String).toList();
  }

  /// Gets distinct list of equipment.
  Future<List<String>> getEquipmentList() async {
    final Database? db = await initDatabase();
    if (db == null) {
      return <String>[];
    }
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT DISTINCT equipment FROM exercises ORDER BY equipment ASC',
    );
    return rows.map((Map<String, dynamic> r) => r['equipment'] as String).toList();
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
