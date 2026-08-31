import 'dart:io';

import 'package:flutter/services.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/food_database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Embedded local SQLite database service providing high-performance full-text search
/// and offline barcode lookups across the complete USDA FoodData Central and restaurant menu catalog.
class UsdaDatabaseService {
  UsdaDatabaseService({Database? db, String? dbPath})
      : _customDbPath = dbPath {
    _db = db;
  }

  static UsdaDatabaseService? _instance;
  static UsdaDatabaseService get instance => _instance ??= UsdaDatabaseService();
  static void setMockInstance(UsdaDatabaseService? mock) {
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
      // Wait for ongoing initialization
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
        'usda_foods.db',
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
      final String dbPath = p.join(appDir.path, 'usda_foods.db');
      final File dbFile = File(dbPath);

      bool needsExtract = !dbFile.existsSync();
      if (!needsExtract) {
        try {
          final ByteData data = await rootBundle.load('assets/data/usda_foods.db');
          final int assetSize = data.lengthInBytes;
          final int existingSize = dbFile.lengthSync();
          if (existingSize != assetSize) {
            needsExtract = true;
            AppLogService.instance.info(
              'USDA_DB',
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
          final File walFile = File('$dbPath-wal');
          if (walFile.existsSync()) {
            walFile.deleteSync();
          }
          final File shmFile = File('$dbPath-shm');
          if (shmFile.existsSync()) {
            shmFile.deleteSync();
          }

          final ByteData data = await rootBundle.load('assets/data/usda_foods.db');
          final List<int> bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await dbFile.parent.create(recursive: true);
          await dbFile.writeAsBytes(bytes, flush: true);
          AppLogService.instance.info(
            'USDA_DB',
            'Extracted usda_foods.db (${bytes.length} bytes / ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB) to local storage',
          );
        } catch (e) {
          AppLogService.instance.warning(
            'USDA_DB',
            'Could not load usda_foods.db from assets: $e',
          );
        }
      }

      if (dbFile.existsSync()) {
        _db = await openDatabase(dbPath);
        final List<Map<String, dynamic>> countRows = await _db!.rawQuery('SELECT COUNT(*) as c FROM foods');
        final int count = Sqflite.firstIntValue(countRows) ?? 0;
        AppLogService.instance.info(
          'USDA_DB',
          'Connected to local USDA SQLite database ($count foods ready)',
        );
      }
      return _db;
    } catch (e, st) {
      AppLogService.instance.error(
        'USDA_DB',
        'Failed to initialize USDA SQLite database: $e',
        error: e,
        stackTrace: st,
      );
      return null;
    } finally {
      _isInitializing = false;
    }
  }

  /// Searches the local SQLite database using FTS5 full-text search with token prefix matching.
  Future<List<FoodItem>> searchFoods(
    String query, {
    String? category,
    String? source,
    int limit = 50,
    int offset = 0,
  }) async {
    final String clean = query.trim();
    final Database? db = _db ?? await initDatabase();
    if (db == null || !db.isOpen) {
      return <FoodItem>[];
    }

    AppLogService.instance.debug(
      'USDA_DB',
      'Searching foods: query="$clean", source="$source", category="$category", limit=$limit',
    );

    try {
      List<Map<String, dynamic>> rows;

      if (clean.isEmpty) {
        // Return top foods
        final StringBuffer sql = StringBuffer('SELECT * FROM foods WHERE 1=1');
        final List<dynamic> args = <dynamic>[];

        if (source != null && source.isNotEmpty) {
          sql.write(' AND source = ?');
          args.add(source);
        }
        if (category != null && category.isNotEmpty) {
          sql.write(' AND category = ?');
          args.add(category);
        }

        sql.write(' ORDER BY calories DESC LIMIT ? OFFSET ?');
        args.add(limit);
        args.add(offset);

        rows = await db.rawQuery(sql.toString(), args);
      } else if (int.tryParse(clean) != null) {
        // Direct FDC ID or Barcode number query
        final int fdcNum = int.parse(clean);
        rows = await db.rawQuery(
          'SELECT * FROM foods WHERE fdc_id = ? OR barcode = ? LIMIT ?',
          <dynamic>[fdcNum, clean, limit],
        );
        if (rows.isEmpty) {
          // Fallback to FTS if not matched directly
          final String ftsQuery = '$clean*';
          rows = await db.rawQuery(
            'SELECT f.* FROM foods f JOIN foods_fts ON f.rowid = foods_fts.rowid WHERE foods_fts MATCH ? LIMIT ?',
            <dynamic>[ftsQuery, limit],
          );
        }
      } else {
        // Sanitize and prepare FTS5 query with prefix wildcard
        final List<String> tokens = clean
            .replaceAll(RegExp(r'[^\w\s]'), ' ')
            .split(RegExp(r'\s+'))
            .where((String t) => t.isNotEmpty)
            .map((String t) => '$t*')
            .toList();

        if (tokens.isEmpty) {
          return <FoodItem>[];
        }

        final String ftsQuery = tokens.join(' ');

        final StringBuffer sql = StringBuffer('''
          SELECT f.* FROM foods f
          JOIN foods_fts ON f.rowid = foods_fts.rowid
          WHERE foods_fts MATCH ?
        ''');
        final List<dynamic> args = <dynamic>[ftsQuery];

        if (source != null && source.isNotEmpty) {
          sql.write(' AND f.source = ?');
          args.add(source);
        }
        if (category != null && category.isNotEmpty) {
          sql.write(' AND f.category = ?');
          args.add(category);
        }

        sql.write('''
          ORDER BY 
            (f.source = 'offline_restaurant') DESC,
            (f.source = 'usda_survey_fndds') DESC,
            (f.source = 'usda_foundation') DESC,
            (f.source = 'usda_sr_legacy') DESC,
            (f.source = 'offline_staple') DESC,
            (f.calories > 0) DESC,
            foods_fts.rank ASC 
          LIMIT ? OFFSET ?
        ''');
        args.add(limit);
        args.add(offset);

        try {
          rows = await db.rawQuery(sql.toString(), args);
        } catch (ftsError) {
          // Fallback to LIKE query if FTS syntax error
          final String likePattern = '%$clean%';
          rows = await db.rawQuery(
            'SELECT * FROM foods WHERE name LIKE ? OR brand LIKE ? LIMIT ? OFFSET ?',
            <dynamic>[likePattern, likePattern, limit, offset],
          );
        }
      }

      final List<FoodItem> results = rows.map((Map<String, dynamic> row) => _rowToFoodItem(row)).toList();
      AppLogService.instance.info(
        'USDA_DB',
        'Search "$clean" returned ${results.length} items (Top: ${results.take(3).map((FoodItem f) => "${f.name} [${f.source}]").join(", ")})',
      );
      return results;
    } catch (e, st) {
      AppLogService.instance.error(
        'USDA_DB',
        'Error searching SQLite foods for "$query": $e',
        error: e,
        stackTrace: st,
      );
      return <FoodItem>[];
    }
  }

  /// Directly looks up a food item by UPC/EAN barcode in the local SQLite database.
  Future<FoodItem?> lookupBarcode(String barcode) async {
    final String clean = barcode.trim();
    if (clean.isEmpty) {
      return null;
    }

    final Database? db = _db ?? await initDatabase();
    if (db == null || !db.isOpen) {
      return null;
    }

    try {
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM foods WHERE barcode = ? LIMIT 1',
        <dynamic>[clean],
      );

      if (rows.isNotEmpty) {
        return _rowToFoodItem(rows.first);
      }
    } catch (e) {
      AppLogService.instance.warning('USDA_DB', 'Barcode lookup error for $clean: $e');
    }
    return null;
  }

  /// Returns total counts and dataset metadata from the SQLite database.
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final Database? db = _db ?? await initDatabase();
    if (db == null || !db.isOpen) {
      return <String, dynamic>{'available': false};
    }

    try {
      final List<Map<String, dynamic>> countRows = await db.rawQuery(
        'SELECT COUNT(*) as total, COUNT(DISTINCT brand) as brands FROM foods',
      );
      final int total = countRows.first['total'] as int? ?? 0;
      final int brands = countRows.first['brands'] as int? ?? 0;

      return <String, dynamic>{
        'available': true,
        'totalFoods': total,
        'totalBrands': brands,
      };
    } catch (_) {
      return <String, dynamic>{'available': false};
    }
  }

  FoodItem _rowToFoodItem(Map<String, dynamic> row) {
    return FoodItem(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      brand: row['brand'] as String?,
      category: row['category'] as String?,
      servingSize: row['serving_size'] as String? ?? '100g',
      servingWeightGrams: (row['serving_weight_grams'] as num?)?.toDouble() ?? 100.0,
      calories: (row['calories'] as num?)?.toInt() ?? 0,
      protein: (row['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (row['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (row['fiber'] as num?)?.toDouble(),
      barcode: row['barcode'] as String?,
      source: row['source'] as String? ?? 'offline_staple',
      servingUnitName: row['serving_unit_name'] as String?,
    );
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
