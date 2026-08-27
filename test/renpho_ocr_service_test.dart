import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/body_composition_entry.dart';
import 'package:oly/services/renpho_ocr_service.dart';

void main() {
  group('Renpho OCR & Spatial Text Parsing Tests', () {
    late RenphoOcrService ocrService;

    setUp(() {
      ocrService = RenphoOcrService();
    });

    test('Parses exact Renpho scale export printout text correctly', () {
      const sampleRenphoText = '''
RENPHO
ikeshpack
Jul 21, 2026 at 19:30:37 Data from Scale

Weight
264.8
lb
Body Water 150.6 lb
Protein 47.6 lb
Body Fat 56.2 lb
Bone Mass 10.4 lb

Weight High 264.8 lb
BMI High 34.9
Body Fat Average 56.2 lb,21.2 %
Skeletal Muscle Average 134.6 lb,50.8 %
Fat-Free Mass Average 208.6 lb
Subcutaneous Fat High 16.8 %
Visceral Fat High 17
Body Water Average 150.6 lb,56.9 %
Muscle Mass High 198.4 lb,74.9 %
Bone Mass Average 10.4 lb,3.9 %
Protein Average 47.6 lb,18.0 %
BMR Average 2394 kcal
Metabolic Age High 35

Data from RENPHO Scale
''';

      final entry = ocrService.parseRecognizedText(sampleRenphoText);

      expect(entry, isNotNull);
      expect(entry!.weightLb, closeTo(264.8, 0.01));
      expect(entry.bmi, closeTo(34.9, 0.01));
      expect(entry.bodyFatLb, closeTo(56.2, 0.01));
      expect(entry.bodyFatPct, closeTo(21.2, 0.01));
      expect(entry.skeletalMuscleLb, closeTo(134.6, 0.01));
      expect(entry.skeletalMusclePct, closeTo(50.8, 0.01));
      expect(entry.fatFreeMassLb, closeTo(208.6, 0.01));
      expect(entry.subcutaneousFatPct, closeTo(16.8, 0.01));
      expect(entry.visceralFat, equals(17));
      expect(entry.bodyWaterLb, closeTo(150.6, 0.01));
      expect(entry.bodyWaterPct, closeTo(56.9, 0.01));
      expect(entry.muscleMassLb, closeTo(198.4, 0.01));
      expect(entry.muscleMassPct, closeTo(74.9, 0.01));
      expect(entry.boneMassLb, closeTo(10.4, 0.01));
      expect(entry.boneMassPct, closeTo(3.9, 0.01));
      expect(entry.proteinLb, closeTo(47.6, 0.01));
      expect(entry.proteinPct, closeTo(18.0, 0.01));
      expect(entry.bmrKcal, equals(2394));
      expect(entry.metabolicAge, equals(35));
      expect(entry.timestamp.year, equals(2026));
      expect(entry.timestamp.month, equals(7));
      expect(entry.timestamp.day, equals(21));
    });

    test('Calculates accurate Lean Body Mass and Katch-McArdle BMR', () {
      final entry = BodyCompositionEntry.create(
        weightLb: 264.8,
        bodyFatPct: 21.2,
        fatFreeMassLb: 208.6,
      );

      expect(entry.leanBodyMassLb, closeTo(208.6, 0.1));
      expect(entry.leanBodyMassKg, closeTo(94.62, 0.1));
      // BMR = 370 + 21.6 * 94.62 = 2413.8 -> 2414
      expect(entry.katchMcArdleBmr, equals(2414));
    });

    test('Calculates accurate target weight to reach 15.0% Body Fat', () {
      final entry = BodyCompositionEntry.create(
        weightLb: 264.8,
        fatFreeMassLb: 208.6,
      );

      // Target weight = 208.6 / (1 - 0.15) = 245.41 lb
      final targetWeight = entry.targetWeightForBodyFat(15.0);
      expect(targetWeight, closeTo(245.41, 0.1));

      // Pure fat to lose = 264.8 - 245.41 = 19.39 lb
      final fatToLose = entry.fatToLoseForTargetBf(15.0);
      expect(fatToLose, closeTo(19.39, 0.1));
    });

    test('Parses multiline fragmented OCR text from mobile camera roll screenshots', () {
      const fragmentedText = '''
RENPHO Report
Jul 21, 2026 at 19:30:37

Weight
264.8 lb
High

BMI
34.9
High

Body Fat
56.2 lb
21.2 %
Average

Skeletal Muscle
134.6 lb
50.8 %

Fat-Free Mass
208.6 lb

Subcutaneous Fat
16.8 %

Visceral Fat
17

Body Water
150.6 lb
56.9 %

Muscle Mass
198.4 lb
74.9 %

Bone Mass
10.4 lb
3.9 %

Protein
47.6 lb
18.0 %

BMR
2394 kcal

Metabolic Age
35
''';

      final entry = ocrService.parseRecognizedText(fragmentedText);

      expect(entry, isNotNull);
      expect(entry!.weightLb, closeTo(264.8, 0.01));
      expect(entry.bmi, closeTo(34.9, 0.01));
      expect(entry.bodyFatLb, closeTo(56.2, 0.01));
      expect(entry.bodyFatPct, closeTo(21.2, 0.01));
      expect(entry.skeletalMuscleLb, closeTo(134.6, 0.01));
      expect(entry.skeletalMusclePct, closeTo(50.8, 0.01));
      expect(entry.fatFreeMassLb, closeTo(208.6, 0.01));
      expect(entry.subcutaneousFatPct, closeTo(16.8, 0.01));
      expect(entry.visceralFat, equals(17));
      expect(entry.bodyWaterLb, closeTo(150.6, 0.01));
      expect(entry.bodyWaterPct, closeTo(56.9, 0.01));
      expect(entry.muscleMassLb, closeTo(198.4, 0.01));
      expect(entry.boneMassLb, closeTo(10.4, 0.01));
      expect(entry.proteinLb, closeTo(47.6, 0.01));
      expect(entry.bmrKcal, equals(2394));
      expect(entry.metabolicAge, equals(35));
    });

    test('Parses exact raw multi-column OCR text from user iPhone device scan', () {
      const userDeviceOcrText = '''
RENPHO
Data from Scale
ikeshpack
Jul 21, 2026 at 19:30:37
Body Water
O Protein
Body Fat
Bone Mass
150.6 Ib
47.6 lb
56.2 Ib
10.4 Ib
Weight
264.8
Weight
High
BMI
High
Body Fat
Average
Skeletal Muscle
Average
264.8 lb
34.9
56.2 Ib,21.2 %
134.6 lb,50.8 %
Fat-Free Mass
Subcutaneous Fat
High
Visceral Fat
High
Body Water
Average
208.6 lb
16.8 %
17
150.6 Ib,56.9 %
Muscle Mass
High
Bone Mass
Average
Protein
Average
198.4 Ib,74.9 %
10.4 Ib,3.9 %
47.6 Ib,18.0 %
BMR
Average
Metabolic Age
High
2394 kcal
35
Data from RENPHO Scale
Disclaimer: The information provided by the app is for reference
purposes only and should not be considered a substitute for
professional healthcare services.
''';

      final entry = ocrService.parseRecognizedText(userDeviceOcrText);

      expect(entry, isNotNull);
      expect(entry!.weightLb, closeTo(264.8, 0.01));
      expect(entry.bmi, closeTo(34.9, 0.01));
      expect(entry.bodyFatLb, closeTo(56.2, 0.01));
      expect(entry.bodyFatPct, closeTo(21.2, 0.01));
      expect(entry.skeletalMuscleLb, closeTo(134.6, 0.01));
      expect(entry.skeletalMusclePct, closeTo(50.8, 0.01));
      expect(entry.fatFreeMassLb, closeTo(208.6, 0.01));
      expect(entry.subcutaneousFatPct, closeTo(16.8, 0.01));
      expect(entry.visceralFat, equals(17));
      expect(entry.bodyWaterLb, closeTo(150.6, 0.01));
      expect(entry.bodyWaterPct, closeTo(56.9, 0.01));
      expect(entry.muscleMassLb, closeTo(198.4, 0.01));
      expect(entry.muscleMassPct, closeTo(74.9, 0.01));
      expect(entry.boneMassLb, closeTo(10.4, 0.01));
      expect(entry.boneMassPct, closeTo(3.9, 0.01));
      expect(entry.proteinLb, closeTo(47.6, 0.01));
      expect(entry.proteinPct, closeTo(18.0, 0.01));
      expect(entry.bmrKcal, equals(2394));
      expect(entry.metabolicAge, equals(35));
    });
  });
}
