import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InjuryProvider State & Persistence Tests', () {
    late StorageService storage;
    late InjuryProvider injuryProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      injuryProvider = InjuryProvider(storage);
    });

    test('Initializes with empty injuries list when no data is stored', () {
      expect(injuryProvider.allInjuries, isEmpty);
      expect(injuryProvider.activeInjuries, isEmpty);
      expect(injuryProvider.totalActiveCount, equals(0));
      expect(injuryProvider.averagePainScore, equals(0.0));
    });

    test('Adds injury, updates active counts and persists to storage', () async {
      final InjuryRecord record = InjuryRecord(
        id: 'test_knee_1',
        name: 'Patellar Tendon Soreness',
        region: InjuryRegion.leftKnee,
        onsetDate: DateTime.now().subtract(const Duration(days: 3)),
        painScale: 4,
      );

      await injuryProvider.addInjury(record);

      expect(injuryProvider.totalActiveCount, equals(1));
      expect(injuryProvider.activeInjuries.first.name, equals('Patellar Tendon Soreness'));
      expect(injuryProvider.getPainForRegion(InjuryRegion.leftKnee), equals(4));
      expect(injuryProvider.averagePainScore, equals(4.0));
      expect(injuryProvider.acuteInjuries.length, equals(1));
      expect(injuryProvider.chronicInjuries.length, equals(0));

      // Check fresh provider instance loads persisted injury from storage
      final InjuryProvider reloaded = InjuryProvider(storage);
      expect(reloaded.totalActiveCount, equals(1));
      expect(reloaded.activeInjuries.first.id, equals('test_knee_1'));
    });

    test('Updates injury pain and history entry', () async {
      final InjuryRecord record = InjuryRecord(
        id: 'test_shoulder_1',
        name: 'Right Shoulder AC Strain',
        region: InjuryRegion.rightShoulder,
        onsetDate: DateTime.now().subtract(const Duration(days: 10)),
        painScale: 5,
      );
      await injuryProvider.addInjury(record);

      await injuryProvider.logPainCheckin(
        region: InjuryRegion.rightShoulder,
        painScale: 2,
        notes: 'Improving with banded distraction',
      );

      expect(injuryProvider.getPainForRegion(InjuryRegion.rightShoulder), equals(2));
      final InjuryRecord updated = injuryProvider.getActiveInjuryForRegion(InjuryRegion.rightShoulder)!;
      expect(updated.painScale, equals(2));
      expect(updated.history.isNotEmpty, isTrue);
      expect(updated.history.first.notes, contains('Improving'));
    });

    test('Resolves injury and moves to resolved list', () async {
      final InjuryRecord record = InjuryRecord(
        id: 'test_wrist_1',
        name: 'Left Wrist Sprain',
        region: InjuryRegion.leftWrist,
        onsetDate: DateTime.now().subtract(const Duration(days: 15)),
        painScale: 3,
      );
      await injuryProvider.addInjury(record);
      expect(injuryProvider.totalActiveCount, equals(1));

      await injuryProvider.resolveInjury('test_wrist_1');

      expect(injuryProvider.totalActiveCount, equals(0));
      expect(injuryProvider.resolvedInjuries.length, equals(1));
      expect(injuryProvider.resolvedInjuries.first.isActive, isFalse);
      expect(injuryProvider.resolvedInjuries.first.resolvedAt, isNotNull);
    });

    test('Processes post-session check-in diff map', () async {
      // Add existing knee injury
      await injuryProvider.addInjury(
        InjuryRecord(
          id: 'knee_init',
          name: 'Left Knee Strain',
          region: InjuryRegion.leftKnee,
          onsetDate: DateTime.now().subtract(const Duration(days: 4)),
          painScale: 3,
        ),
      );

      // Post session check-in: Knee stayed 3, but new Right Elbow soreness 2
      final Map<InjuryRegion, int> postSessionPain = <InjuryRegion, int>{
        InjuryRegion.leftKnee: 3,
        InjuryRegion.rightElbow: 2,
      };

      await injuryProvider.processPostSessionCheckin(
        postSessionPain: postSessionPain,
        sessionNotes: 'Heavy snatch day',
        sessionRpe: 8,
      );

      expect(injuryProvider.totalActiveCount, equals(2));
      expect(injuryProvider.getPainForRegion(InjuryRegion.leftKnee), equals(3));
      expect(injuryProvider.getPainForRegion(InjuryRegion.rightElbow), equals(2));
    });
  });
}
