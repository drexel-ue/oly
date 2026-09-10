import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

/// Service for scraping, caching, normalizing, and storing CrossFit Hero Workouts
/// and official CrossFit Movements from crossfit.com.
/// Fully idempotent: caches raw responses and uses deterministic IDs and upserts.
class CrossfitScraperService {
  CrossfitScraperService({
    String? cacheDirectory,
    http.Client? client,
  })  : _cacheDir = cacheDirectory ?? p.join(Directory.current.path, '.crossfit_cache'),
        _client = client ?? http.Client();

  final String _cacheDir;
  final http.Client _client;

  static const String heroesIndexUrl = 'https://www.crossfit.com/heroes/';
  static const String movementsIndexUrl = 'https://www.crossfit.com/crossfit-movements';

  static const String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 OlyApp/1.0';

  /// Helper to fetch a URL or return cached content from disk.
  Future<String> fetchOrLoadCached(
    String url,
    String cacheSubdir,
    String filename, {
    bool force = false,
  }) async {
    final dir = Directory(p.join(_cacheDir, cacheSubdir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final cacheFile = File(p.join(dir.path, filename));
    if (!force && cacheFile.existsSync() && cacheFile.lengthSync() > 0) {
      return cacheFile.readAsStringSync();
    }

    // Download over network with timeout and User-Agent
    final request = http.Request('GET', Uri.parse(url));
    request.headers['User-Agent'] = userAgent;

    final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 25));
    if (streamedResponse.statusCode != 200) {
      if (cacheFile.existsSync() && cacheFile.lengthSync() > 0) {
        return cacheFile.readAsStringSync();
      }
      throw HttpException('HTTP ${streamedResponse.statusCode} for $url');
    }

    final responseBody = await streamedResponse.stream.bytesToString();
    cacheFile.writeAsStringSync(responseBody, flush: true);
    return responseBody;
  }

  /// Scrapes all Hero Workouts from crossfit.com/heroes/ and individual benchmark pages.
  Future<List<CrossfitHeroWod>> scrapeHeroWods({
    bool force = false,
    int? limit,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Fetching Hero workouts directory from $heroesIndexUrl...');
    final indexHtml = await fetchOrLoadCached(
      heroesIndexUrl,
      'heroes',
      'heroes_index.html',
      force: force,
    );

    final indexDoc = html_parser.parse(indexHtml);
    final benchmarkLinks = indexDoc.querySelectorAll('a[href*="/benchmark/"]');
    
    // De-duplicate benchmark links by slug
    final Map<String, _RawHeroCard> cardsBySlug = <String, _RawHeroCard>{};

    for (final link in benchmarkLinks) {
      final href = link.attributes['href'] ?? '';
      final uri = Uri.tryParse(href);
      if (uri == null) {
        continue;
      }
      
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty || segments.first != 'benchmark') {
        continue;
      }
      final slug = segments.last.toLowerCase().trim();
      if (slug.isEmpty) {
        continue;
      }

      // Extract card text from link or ancestor card
      Element cardEl = link;
      var parent = link.parent;
      while (parent != null && parent.localName != 'main') {
        if (parent.className.contains('card') || parent.className.contains('Card') || parent.className.contains('result')) {
          cardEl = parent;
          break;
        }
        parent = parent.parent;
      }

      final cardText = cardEl.text.trim();
      final name = _extractNameFromSlug(slug);

      if (!cardsBySlug.containsKey(slug)) {
        cardsBySlug[slug] = _RawHeroCard(
          slug: slug,
          name: name,
          url: 'https://www.crossfit.com/benchmark/$slug',
          rawCardText: cardText,
        );
      }
    }

    onProgress?.call('Found ${cardsBySlug.length} unique Hero Workouts.');
    final cardList = cardsBySlug.values.toList();
    final int toProcess = limit != null && limit < cardList.length ? limit : cardList.length;

    final List<CrossfitHeroWod> heroWods = <CrossfitHeroWod>[];

    const batchSize = 10;
    for (int i = 0; i < toProcess; i += batchSize) {
      final end = (i + batchSize < toProcess) ? i + batchSize : toProcess;
      final chunk = cardList.sublist(i, end);
      onProgress?.call('Fetching Hero benchmarks [${i + 1}-$end/$toProcess]...');

      final futures = chunk.map((rawCard) async {
        try {
          final benchmarkHtml = await fetchOrLoadCached(
            rawCard.url,
            'benchmarks',
            '${rawCard.slug}.html',
            force: force,
          );
          final detailDoc = html_parser.parse(benchmarkHtml);
          return _parseHeroBenchmarkDetail(rawCard.slug, rawCard.url, detailDoc, rawCard.rawCardText);
        } catch (e) {
          return _createFallbackHeroWod(rawCard);
        }
      });

      final results = await Future.wait(futures);
      heroWods.addAll(results);
    }

    // Deterministic sort by name
    heroWods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    onProgress?.call('✅ Successfully parsed ${heroWods.length} Hero Workouts.');
    return heroWods;
  }

  /// Parses an individual hero benchmark detail page.
  CrossfitHeroWod _parseHeroBenchmarkDetail(
    String slug,
    String sourceUrl,
    Document doc,
    String fallbackCardText,
  ) {
    // 1. Name
    final h1El = doc.querySelector('h1');
    String name = h1El?.text.trim() ?? '';
    if (name.isEmpty) {
      name = _extractNameFromSlug(slug);
    }

    // 2. Prescription text (RX'd Workout)
    final prescriptionEl = doc.querySelector('[class*="prescription"]');
    String prescription = prescriptionEl?.text.trim() ?? '';
    if (prescription.isEmpty) {
      // Fallback to rxdCard or main text
      final rxdCard = doc.querySelector('[class*="rxdCard"]');
      prescription = rxdCard?.text.trim() ?? '';
      if (prescription.startsWith("RX'D Workout")) {
        prescription = prescription.substring("RX'D Workout".length).trim();
      }
    }
    if (prescription.isEmpty) {
      prescription = fallbackCardText;
    }

    // 3. Weight standards
    final weightsEl = doc.querySelector('[class*="weightStandards"]');
    final String? rxWeights = weightsEl?.text.trim().isNotEmpty == true ? weightsEl!.text.trim() : null;

    // 4. Tribute text ("About <Hero>")
    final tributeCard = doc.querySelector('[class*="tributeCard"]') ?? doc.querySelector('[class*="tributeContent"]');
    String tributeText = '';
    if (tributeCard != null) {
      final pTexts = tributeCard.querySelectorAll('p').map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();
      tributeText = pTexts.join('\n\n');
    }
    if (tributeText.isEmpty) {
      // Look for paragraphs following About <Hero> h2
      final h2s = doc.querySelectorAll('h2');
      for (final h2 in h2s) {
        if (h2.text.toLowerCase().contains('about')) {
          var next = h2.nextElementSibling;
          final parts = <String>[];
          while (next != null && next.localName != 'h2' && next.localName != 'section') {
            if (next.localName == 'p' && next.text.trim().isNotEmpty) {
              parts.add(next.text.trim());
            }
            next = next.nextElementSibling;
          }
          tributeText = parts.join('\n\n');
          break;
        }
      }
    }

    if (tributeText.isEmpty) {
      if (slug == 'murph') {
        tributeText =
            "Dedicated to Navy Lieutenant Michael Murphy, 29, of Patchogue, N.Y., who was killed in Afghanistan June 28, 2005. He was awarded the Congressional Medal of Honor for his heroic actions during Operation Red Wings. This workout was one of Mike's favorites and he'd named it 'Body Armor'. From here on it shall be referred to as 'Murph' in honor of the focused warrior and great American.";
      } else {
        tributeText = 'Dedicated to honoring the sacrifice and service of our fallen heroes.';
      }
    }

    // 5. First posted date
    String? firstPosted;
    final textAll = doc.body?.text ?? '';
    final firstPostedMatch = RegExp(r'First posted ([A-Za-z]+ \d{1,2}, \d{4})', caseSensitive: false).firstMatch(textAll);
    if (firstPostedMatch != null) {
      firstPosted = firstPostedMatch.group(1);
    }

    // 6. Movements Summary
    final List<String> movementsSummary = _extractMovementsSummary(prescription);

    // 7. Equipment detection
    final List<String> equipment = _detectEquipment(prescription, rxWeights);

    // 8. Format detection
    final WodFormat format = CrossfitHeroWod.parseFormat(prescription);

    // 9. Interactive tracker check
    final bool hasInteractiveTracker = _hasInteractiveTracker(slug);

    // 10. Subtitle
    final String subtitle = _buildSubtitle(format, movementsSummary, rxWeights);

    return CrossfitHeroWod(
      id: 'cf_hero_$slug',
      slug: slug,
      name: name,
      subtitle: subtitle,
      format: format,
      category: 'Hero Benchmark',
      targetTimeOrCap: format == WodFormat.amrap ? 'AMRAP' : 'For Time',
      equipment: equipment,
      movementsSummary: movementsSummary,
      rawWorkoutText: prescription,
      rxWeights: rxWeights,
      tributeText: tributeText,
      firstPosted: firstPosted,
      sourceUrl: sourceUrl,
      hasInteractiveTracker: hasInteractiveTracker,
    );
  }

  CrossfitHeroWod _createFallbackHeroWod(_RawHeroCard rawCard) {
    final movements = _extractMovementsSummary(rawCard.rawCardText);
    final equipment = _detectEquipment(rawCard.rawCardText, null);
    final format = CrossfitHeroWod.parseFormat(rawCard.rawCardText);

    return CrossfitHeroWod(
      id: 'cf_hero_${rawCard.slug}',
      slug: rawCard.slug,
      name: rawCard.name,
      subtitle: 'Hero Memorial Workout',
      format: format,
      category: 'Hero Benchmark',
      targetTimeOrCap: 'For Time',
      equipment: equipment,
      movementsSummary: movements,
      rawWorkoutText: rawCard.rawCardText,
      tributeText: 'Dedicated to honoring fallen heroes.',
      sourceUrl: rawCard.url,
      hasInteractiveTracker: _hasInteractiveTracker(rawCard.slug),
    );
  }

  /// Scrapes all official Movements from crossfit.com/crossfit-movements
  Future<List<Map<String, dynamic>>> scrapeMovements({
    bool force = false,
    int? limit,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Fetching CrossFit Movements directory from $movementsIndexUrl...');
    final indexHtml = await fetchOrLoadCached(
      movementsIndexUrl,
      'movements',
      'movements_index.html',
      force: force,
    );

    final indexDoc = html_parser.parse(indexHtml);
    final essentialsLinks = indexDoc.querySelectorAll('a[href*="/essentials/"]');
    
    final Map<String, String> movementUrlsBySlug = <String, String>{};
    for (final link in essentialsLinks) {
      final href = link.attributes['href'] ?? '';
      final uri = Uri.tryParse(href);
      if (uri == null) {
        continue;
      }
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty || segments.first != 'essentials') {
        continue;
      }
      final slug = segments.last.toLowerCase().trim();
      if (slug.isEmpty || slug == 'movements') {
        continue;
      }

      if (!movementUrlsBySlug.containsKey(slug)) {
        movementUrlsBySlug[slug] = href.startsWith('http') ? href : 'https://www.crossfit.com$href';
      }
    }

    onProgress?.call('Found ${movementUrlsBySlug.length} unique CrossFit Movement essentials.');
    final entries = movementUrlsBySlug.entries.toList();
    final int toProcess = limit != null && limit < entries.length ? limit : entries.length;

    final List<Map<String, dynamic>> movements = <Map<String, dynamic>>[];

    const batchSize = 10;
    for (int i = 0; i < toProcess; i += batchSize) {
      final end = (i + batchSize < toProcess) ? i + batchSize : toProcess;
      final chunk = entries.sublist(i, end);
      onProgress?.call('Fetching Movement details [${i + 1}-$end/$toProcess]...');

      final futures = chunk.map((entry) async {
        final slug = entry.key;
        final url = entry.value;
        try {
          final movementHtml = await fetchOrLoadCached(
            url,
            'essentials',
            '$slug.html',
            force: force,
          );
          final doc = html_parser.parse(movementHtml);
          return _parseMovementDetail(slug, url, doc);
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      for (final r in results) {
        if (r != null) {
          movements.add(r);
        }
      }
    }

    movements.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    onProgress?.call('✅ Successfully parsed ${movements.length} CrossFit Movements.');
    return movements;
  }

  Map<String, dynamic> _parseMovementDetail(String slug, String sourceUrl, Document doc) {
    // 1. Name
    final h1 = doc.querySelector('h1');
    String name = h1?.text.trim() ?? '';
    if (name.isEmpty) {
      name = _extractNameFromSlug(slug);
    }
    if (name.toLowerCase().startsWith('the ')) {
      name = name.substring(4).trim();
    }

    // 2. Video URL (YouTube embed or link)
    String? videoUrl;
    final iframes = doc.querySelectorAll('iframe');
    for (final iframe in iframes) {
      final src = iframe.attributes['src'] ?? '';
      if (src.contains('youtube.com') || src.contains('youtu.be') || src.contains('vimeo.com')) {
        videoUrl = src;
        break;
      }
    }

    // 3. Instructions & Guide paragraphs
    final paragraphs = doc.querySelectorAll('main p').map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();
    String instructions = '';
    if (paragraphs.isNotEmpty) {
      // Filter out boilerplate text
      final valid = paragraphs.where((p) {
        final lower = p.toLowerCase();
        return !lower.contains('cookie') &&
            !lower.contains('privacy policy') &&
            !lower.contains('terms of service') &&
            !lower.contains('competition dashboard') &&
            !lower.contains('we encountered a problem') &&
            !lower.contains('by crossfit') &&
            !lower.contains('read further to learn');
      }).toList();
      instructions = valid.take(8).join('\n\n');
    }

    // 4. Equipment, category, target muscle, body part
    final equipment = _inferMovementEquipment(name, slug, instructions);
    final category = _inferMovementCategory(name, slug);
    final bodyPart = _inferMovementBodyPart(name, slug, category);
    final targetMuscle = _inferMovementMuscle(name, slug, bodyPart);

    return <String, dynamic>{
      'id': 'cf_mov_$slug',
      'name': name,
      'category': category,
      'body_part': bodyPart,
      'target_muscle': targetMuscle,
      'secondary_muscles': jsonEncode(<String>[]),
      'equipment': equipment,
      'mechanic': 'compound',
      'force': 'push',
      'level': 'intermediate',
      'instructions': instructions,
      'tips': 'Maintain proper mechanics and midline stabilization before increasing intensity.',
      'source': 'crossfit',
      'source_id': slug,
      'gif_url': null,
      'video_url': videoUrl,
    };
  }

  /// Inserts/updates scraped hero workouts and movements into SQLite database.
  Future<void> saveToDatabase(
    Database db, {
    List<CrossfitHeroWod>? heroWods,
    List<Map<String, dynamic>>? movements,
    void Function(String message)? onProgress,
  }) async {
    // 1. Ensure hero_wods table & FTS table exist
    onProgress?.call('Ensuring hero_wods schema and FTS5 indexing exist in SQLite...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hero_wods (
        id TEXT PRIMARY KEY,
        slug TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        subtitle TEXT,
        format TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Hero Benchmark',
        target_time_or_cap TEXT,
        target_cap_seconds INTEGER,
        equipment TEXT NOT NULL DEFAULT '[]',
        movements_summary TEXT NOT NULL DEFAULT '[]',
        raw_workout_text TEXT NOT NULL,
        rx_weights TEXT,
        tribute_text TEXT,
        first_posted TEXT,
        source_url TEXT NOT NULL,
        has_interactive_tracker INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_hero_wods_slug ON hero_wods(slug);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hero_wods_name ON hero_wods(name);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hero_wods_format ON hero_wods(format);');

    // Hero WODs FTS5 table
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS hero_wods_fts USING fts5(
          id UNINDEXED,
          name,
          subtitle,
          raw_workout_text,
          tribute_text,
          equipment,
          content='hero_wods',
          content_rowid='rowid'
        );
      ''');

      // FTS Triggers
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS hero_wods_ai AFTER INSERT ON hero_wods BEGIN
          INSERT INTO hero_wods_fts(rowid, id, name, subtitle, raw_workout_text, tribute_text, equipment)
          VALUES (new.rowid, new.id, new.name, new.subtitle, new.raw_workout_text, new.tribute_text, new.equipment);
        END;
      ''');

      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS hero_wods_ad AFTER DELETE ON hero_wods BEGIN
          INSERT INTO hero_wods_fts(hero_wods_fts, rowid, id, name, subtitle, raw_workout_text, tribute_text, equipment)
          VALUES ('delete', old.rowid, old.id, old.name, old.subtitle, old.raw_workout_text, old.tribute_text, old.equipment);
        END;
      ''');

      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS hero_wods_au AFTER UPDATE ON hero_wods BEGIN
          INSERT INTO hero_wods_fts(hero_wods_fts, rowid, id, name, subtitle, raw_workout_text, tribute_text, equipment)
          VALUES ('delete', old.rowid, old.id, old.name, old.subtitle, old.raw_workout_text, old.tribute_text, old.equipment);
          INSERT INTO hero_wods_fts(rowid, id, name, subtitle, raw_workout_text, tribute_text, equipment)
          VALUES (new.rowid, new.id, new.name, new.subtitle, new.raw_workout_text, new.tribute_text, new.equipment);
        END;
      ''');
    } catch (_) {}

    // 2. Upsert Hero WODs in transaction
    if (heroWods != null && heroWods.isNotEmpty) {
      onProgress?.call('Upserting ${heroWods.length} Hero Workouts into hero_wods...');
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final wod in heroWods) {
          batch.insert(
            'hero_wods',
            wod.toSqlite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      onProgress?.call('✅ ${heroWods.length} Hero Workouts committed to SQLite.');
    }

    // 3. Upsert Movements into exercises table in transaction
    if (movements != null && movements.isNotEmpty) {
      onProgress?.call('Upserting ${movements.length} CrossFit Movements into exercises table...');
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final mov in movements) {
          batch.insert(
            'exercises',
            mov,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      onProgress?.call('✅ ${movements.length} CrossFit Movements committed to exercises table.');
    }
  }

  /// Exports scraped data to bundled JSON files in assets/data.
  Future<void> exportBundledJson({
    List<CrossfitHeroWod>? heroWods,
    List<Map<String, dynamic>>? movements,
    String? targetDir,
  }) async {
    final baseDir = targetDir ?? p.join(Directory.current.path, 'assets', 'data');
    final dir = Directory(baseDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    if (heroWods != null) {
      final heroFile = File(p.join(baseDir, 'crossfit_hero_wods.json'));
      final jsonList = heroWods.map((w) => w.toJson()).toList();
      await heroFile.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList), flush: true);
    }

    if (movements != null) {
      final movFile = File(p.join(baseDir, 'crossfit_movements.json'));
      await movFile.writeAsString(const JsonEncoder.withIndent('  ').convert(movements), flush: true);
    }
  }

  // --- Normalization Helpers ---

  static String _extractNameFromSlug(String slug) {
    return slug
        .split(RegExp(r'[-_]'))
        .where((s) => s.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static bool _hasInteractiveTracker(String slug) {
    return slug == 'cindy' ||
        slug == 'murph' ||
        slug == 'dt' ||
        slug == 'jackie' ||
        slug == 'fran' ||
        slug == 'helen' ||
        slug == 'grace' ||
        slug == 'death_by_burpees';
  }

  static List<String> _extractMovementsSummary(String prescription) {
    final lines = prescription.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) {
      return <String>[prescription];
    }

    final filtered = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      // Skip header lines like "for time:", "3 rounds of:", "then,"
      if (lower.startsWith('for time') ||
          lower.startsWith('complete as many') ||
          lower.startsWith('amrap') ||
          lower.contains('rounds for time') ||
          RegExp(r'^\d+\s+rounds\b').hasMatch(lower) ||
          lower == 'then,' ||
          lower == 'then' ||
          lower.startsWith('details') ||
          lower.startsWith("rx'd workout")) {
        continue;
      }
      filtered.add(line);
    }

    return filtered.isNotEmpty ? filtered : lines;
  }

  static List<String> _detectEquipment(String text, String? weights) {
    final lower = '${text.toLowerCase()} ${weights?.toLowerCase() ?? ""}';
    final Set<String> eq = <String>{};

    if (lower.contains('barbell') ||
        lower.contains('clean') ||
        lower.contains('deadlift') ||
        lower.contains('snatch') ||
        lower.contains('thruster') ||
        lower.contains('bench press') ||
        lower.contains('jerk') ||
        lower.contains('back squat') ||
        lower.contains('front squat') ||
        lower.contains('overhead squat') ||
        lower.contains('lb') ||
        lower.contains('kg')) {
      eq.add('Barbell');
    }
    if (lower.contains('dumbbell') || lower.contains('db ')) {
      eq.add('Dumbbells');
    }
    if (lower.contains('kettlebell') || lower.contains('kb ') || lower.contains('swing') || lower.contains('get-up')) {
      eq.add('Kettlebell');
    }
    if (lower.contains('pull-up') ||
        lower.contains('chin-up') ||
        lower.contains('toes-to-bar') ||
        lower.contains('bar muscle-up') ||
        lower.contains('chest-to-bar') ||
        lower.contains('knees-to-elbow')) {
      eq.add('Pull-up Bar');
    }
    if (lower.contains('ring dip') ||
        lower.contains('ring muscle-up') ||
        lower.contains('muscle-up') ||
        lower.contains('rings')) {
      eq.add('Gymnastics Rings');
    }
    if (lower.contains('row') || lower.contains('rower') || lower.contains('500-meter row') || lower.contains('1,000-meter row')) {
      eq.add('Concept2 Rower');
    }
    if (lower.contains('double-under') || lower.contains('single-under') || lower.contains('jump rope')) {
      eq.add('Speed Rope');
    }
    if (lower.contains('box jump') || lower.contains('box step-up') || lower.contains('24-inch') || lower.contains('20-inch')) {
      eq.add('Plyo Box');
    }
    if (lower.contains('wall-ball') || lower.contains('wall ball') || lower.contains('medicine ball')) {
      eq.add('Medicine Ball');
    }
    if (lower.contains('vest') || lower.contains('body armor') || lower.contains('20-lb vest') || lower.contains('14-lb vest')) {
      eq.add('Weighted Vest');
    }
    if (lower.contains('sandbag')) {
      eq.add('Sandbag');
    }
    if (lower.contains('rope climb') || lower.contains('15-foot rope')) {
      eq.add('Climbing Rope');
    }
    if (lower.contains('ghd') || lower.contains('glute-ham')) {
      eq.add('GHD Machine');
    }
    if (lower.contains('run') || lower.contains('1-mile') || lower.contains('400-meter')) {
      eq.add('Running Track / Course');
    }

    if (eq.isEmpty) {
      eq.add('Bodyweight');
    }

    return eq.toList();
  }

  static String _buildSubtitle(WodFormat format, List<String> movements, String? weights) {
    final prefix = format.displayName;
    if (movements.length <= 3) {
      return '$prefix • ${movements.join(" • ")}';
    }
    return '$prefix • ${movements.length} Movement Hero Memorial';
  }

  static String _inferMovementEquipment(String name, String slug, String instructions) {
    final nameSlug = '$name $slug'.toLowerCase();
    if (RegExp(r'\bdumbbell\b').hasMatch(nameSlug)) {
      return 'dumbbell';
    }
    if (RegExp(r'\bkettlebell\b').hasMatch(nameSlug)) {
      return 'kettlebell';
    }
    if (RegExp(r'\b(rings?|ring dip|ring muscle-up)\b').hasMatch(nameSlug)) {
      return 'rings';
    }
    if (RegExp(r'\b(barbell|snatch|clean|jerk|deadlift|press|front rack)\b').hasMatch(nameSlug)) {
      return 'barbell';
    }
    if (RegExp(r'\b(back squat|front squat|overhead squat|zercher squat)\b').hasMatch(nameSlug)) {
      return 'barbell';
    }
    if (RegExp(r'\b(rower|rowing)\b').hasMatch(nameSlug)) {
      return 'machine';
    }
    if (RegExp(r'\brope climb\b').hasMatch(nameSlug)) {
      return 'other';
    }
    if (RegExp(r'\b(box jump|box step-up)\b').hasMatch(nameSlug)) {
      return 'plyo box';
    }
    if (RegExp(r'\bghd\b').hasMatch(nameSlug)) {
      return 'other';
    }
    if (RegExp(r'\b(medicine ball|wall ball|slam ball)\b').hasMatch(nameSlug)) {
      return 'medicine ball';
    }
    if (RegExp(r'\b(double under|single under)\b').hasMatch(nameSlug)) {
      return 'rope';
    }
    return 'body weight';
  }

  static String _inferMovementCategory(String name, String slug) {
    final text = '$name $slug'.toLowerCase();
    if (text.contains('snatch') || text.contains('clean') || text.contains('jerk') || text.contains('sots')) {
      return 'olympic_weightlifting';
    }
    if (text.contains('pull-up') ||
        text.contains('push-up') ||
        text.contains('dip') ||
        text.contains('muscle-up') ||
        text.contains('handstand') ||
        text.contains('rope climb') ||
        text.contains('roll') ||
        text.contains('l-sit')) {
      return 'gymnastics';
    }
    if (text.contains('squat') || text.contains('deadlift') || text.contains('press') || text.contains('lunge')) {
      return 'strength';
    }
    if (text.contains('run') || text.contains('row') || text.contains('under') || text.contains('burpee')) {
      return 'cardio';
    }
    if (text.contains('sit-up') || text.contains('abmat') || text.contains('ghd') || text.contains('scale')) {
      return 'core';
    }
    return 'functional_fitness';
  }

  static String _inferMovementBodyPart(String name, String slug, String category) {
    final text = '$name $slug'.toLowerCase();
    if (text.contains('squat') || text.contains('lunge') || text.contains('leg')) {
      return 'upper_legs';
    }
    if (text.contains('press') || text.contains('handstand') || text.contains('jerk')) {
      return 'shoulders';
    }
    if (text.contains('pull-up') || text.contains('deadlift') || text.contains('rope')) {
      return 'back';
    }
    if (text.contains('push-up') || text.contains('bench') || text.contains('dip')) {
      return 'chest';
    }
    if (text.contains('sit-up') || text.contains('core') || text.contains('l-sit')) {
      return 'core';
    }
    if (text.contains('row') || text.contains('run') || text.contains('burpee')) {
      return 'cardio';
    }
    return 'full_body';
  }

  static String _inferMovementMuscle(String name, String slug, String bodyPart) {
    final text = '$name $slug'.toLowerCase();
    if (text.contains('squat') || text.contains('lunge')) {
      return 'quadriceps';
    }
    if (text.contains('deadlift')) {
      return 'hamstrings';
    }
    if (text.contains('press') || text.contains('jerk')) {
      return 'deltoids';
    }
    if (text.contains('pull-up')) {
      return 'lats';
    }
    if (text.contains('push-up') || text.contains('bench')) {
      return 'pectorals';
    }
    if (text.contains('sit-up') || text.contains('abmat')) {
      return 'abs';
    }
    if (text.contains('row') || text.contains('run')) {
      return 'cardio';
    }
    return 'full_body';
  }
}

class _RawHeroCard {
  _RawHeroCard({
    required this.slug,
    required this.name,
    required this.url,
    required this.rawCardText,
  });

  final String slug;
  final String name;
  final String url;
  final String rawCardText;
}
