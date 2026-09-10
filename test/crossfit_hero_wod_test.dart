import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/wod_definition.dart';

void main() {
  group('CrossfitHeroWod Model Unit Tests', () {
    test('Correctly serializes and deserializes SQLite maps and JSON', () {
      const CrossfitHeroWod hero = CrossfitHeroWod(
        id: 'cf_hero_murph',
        slug: 'murph',
        name: 'Murph',
        subtitle: 'For Time • 1-mile run • 100 pull-ups • 200 push-ups • 300 squats • 1-mile run',
        format: WodFormat.forTime,
        category: 'Hero Benchmark',
        targetTimeOrCap: 'For Time',
        equipment: <String>['Pull-up Bar', 'Running Track / Course'],
        movementsSummary: <String>[
          '1-mile run',
          '100 pull-ups',
          '200 push-ups',
          '300 squats',
          '1-mile run',
        ],
        rawWorkoutText: '1-mile run\n100 pull-ups\n200 push-ups\n300 squats\n1-mile run',
        rxWeights: '20-lb vest',
        tributeText: 'Dedicated to Navy Lieutenant Michael Murphy, 29.',
        firstPosted: 'August 18, 2005',
        sourceUrl: 'https://www.crossfit.com/benchmark/murph',
        hasInteractiveTracker: true,
      );

      // SQLite roundtrip
      final Map<String, dynamic> sqlite = hero.toSqlite();
      expect(sqlite['id'], 'cf_hero_murph');
      expect(sqlite['has_interactive_tracker'], 1);
      expect(sqlite['equipment'], jsonEncode(hero.equipment));

      final CrossfitHeroWod fromSqlite = CrossfitHeroWod.fromSqlite(sqlite);
      expect(fromSqlite.id, hero.id);
      expect(fromSqlite.name, hero.name);
      expect(fromSqlite.format, hero.format);
      expect(fromSqlite.equipment, equals(hero.equipment));
      expect(fromSqlite.movementsSummary, equals(hero.movementsSummary));
      expect(fromSqlite.hasInteractiveTracker, isTrue);

      // JSON roundtrip
      final Map<String, dynamic> json = hero.toJson();
      final CrossfitHeroWod fromJson = CrossfitHeroWod.fromJson(json);
      expect(fromJson.id, hero.id);
      expect(fromJson.name, hero.name);
      expect(fromJson.tributeText, hero.tributeText);
      expect(fromJson.hasInteractiveTracker, isTrue);
    });

    test('toWodDefinition bridges hero workout into full WodDefinition for UI', () {
      const CrossfitHeroWod hero = CrossfitHeroWod(
        id: 'cf_hero_dt',
        slug: 'dt',
        name: 'DT',
        subtitle: 'For Time • 12 deadlifts • 9 hang power cleans • 6 push jerks',
        format: WodFormat.forTime,
        category: 'Hero Benchmark',
        targetTimeOrCap: 'For Time',
        equipment: <String>['Barbell'],
        movementsSummary: <String>[
          '12 deadlifts',
          '9 hang power cleans',
          '6 push jerks',
        ],
        rawWorkoutText: '5 rounds for time of:\n12 deadlifts\n9 hang power cleans\n6 push jerks',
        rxWeights: '♀ 105 lb, ♂ 155 lb',
        tributeText: 'In honor of USAF Staff Sgt. Timothy P. Davis.',
        sourceUrl: 'https://www.crossfit.com/benchmark/dt-new',
        hasInteractiveTracker: true,
      );

      final WodDefinition def = hero.toWodDefinition();
      expect(def.id, 'cf_hero_dt');
      expect(def.name, 'DT');
      expect(def.hasInteractiveTracker, isTrue);
      expect(def.equipment, contains('Barbell'));
      expect(def.setupExplainer.floorPlanAdvice, hero.tributeText);
      expect(def.setupExplainer.scalingOptions['Rx'], contains('155 lb'));
      expect(def.setupExplainer.movementStandards.length, 3);
      expect(def.setupExplainer.movementStandards.first.movementName, '12 deadlifts');
    });

    test('parseFormat accurately parses CrossFit workout timing formats', () {
      expect(CrossfitHeroWod.parseFormat('Complete as many rounds as possible in 20 minutes'), WodFormat.amrap);
      expect(CrossfitHeroWod.parseFormat('AMRAP in 15 minutes of:'), WodFormat.amrap);
      expect(CrossfitHeroWod.parseFormat('Every minute on the minute for 10 minutes'), WodFormat.emom);
      expect(CrossfitHeroWod.parseFormat('EMOM 20:'), WodFormat.emom);
      expect(CrossfitHeroWod.parseFormat('Tabata intervals of:'), WodFormat.intervals);
      expect(CrossfitHeroWod.parseFormat('5 rounds for time of:'), WodFormat.forTime);
      expect(CrossfitHeroWod.parseFormat(null), WodFormat.forTime);
    });

    test('Bundled JSON datasets exist and contain full scraped content', () {
      final String heroJsonPath = '${Directory.current.path}/assets/data/crossfit_hero_wods.json';
      final String movementsJsonPath = '${Directory.current.path}/assets/data/crossfit_movements.json';

      expect(File(heroJsonPath).existsSync(), isTrue);
      expect(File(movementsJsonPath).existsSync(), isTrue);

      final List<dynamic> heroList = jsonDecode(File(heroJsonPath).readAsStringSync());
      expect(heroList.length, equals(248));

      final List<dynamic> movementList = jsonDecode(File(movementsJsonPath).readAsStringSync());
      expect(movementList.length, equals(121));

      // Verify a known hero workout in dataset
      final murphJson = heroList.firstWhere((dynamic h) => (h as Map<String, dynamic>)['slug'] == 'murph') as Map<String, dynamic>;
      expect(murphJson['name'], contains('Murph'));
      expect(murphJson['tributeText'], isNotEmpty);

      // Verify a known movement in dataset
      final thrusterJson = movementList.firstWhere((dynamic m) => (m as Map<String, dynamic>)['source_id'] == 'the-thruster') as Map<String, dynamic>;
      expect(thrusterJson['name'], 'Thruster');
      expect(thrusterJson['category'], isNotEmpty);
      expect(thrusterJson['source'], 'crossfit');
    });
  });
}
