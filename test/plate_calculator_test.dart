import 'package:flutter_test/flutter_test.dart';
import 'package:oly/models/plate_calc.dart';

void main() {
  group('PlateCalculator Tests', () {
    test('Calculates exact plate breakdown for 100kg bar in KG', () {
      final PlateCalcResult result = PlateCalculator.calculate(
        targetWeight: 100.0,
        barWeight: 20.0,
        collarWeight: 0.0,
        isLbs: false,
      );

      expect(result.isExact, isTrue);
      expect(result.actualWeight, equals(100.0));
      // (100 - 20) / 2 = 40kg per side -> 25 + 15 = 40kg
      expect(result.platesPerSide.length, equals(2));
      expect(result.platesPerSide[0].weight, equals(25.0));
      expect(result.platesPerSide[1].weight, equals(15.0));
    });

    test('Handles empty bar weight (20kg)', () {
      final PlateCalcResult result = PlateCalculator.calculate(
        targetWeight: 20.0,
        barWeight: 20.0,
        collarWeight: 0.0,
        isLbs: false,
      );

      expect(result.isExact, isTrue);
      expect(result.actualWeight, equals(20.0));
      expect(result.platesPerSide, isEmpty);
    });

    test('Calculates breakdown in LBS', () {
      final PlateCalcResult result = PlateCalculator.calculate(
        targetWeight: 135.0,
        barWeight: 45.0,
        collarWeight: 0.0,
        isLbs: true,
      );

      expect(result.isExact, isTrue);
      expect(result.actualWeight, equals(135.0));
      // (135 - 45) / 2 = 45lb plate per side
      expect(result.platesPerSide.length, equals(1));
      expect(result.platesPerSide.first.label, equals('45'));
    });

    test(
      'Defaults to 45 lbs bar when isLbs is true without explicit barWeight',
      () {
        final PlateCalcResult result = PlateCalculator.calculate(
          targetWeight: 225.0,
          isLbs: true,
        );

        expect(result.barWeight, equals(45.0));
        expect(result.actualWeight, equals(225.0));
        // (225 - 45) / 2 = 90 lbs per side -> two 45lb plates
        expect(result.platesPerSide.length, equals(2));
        expect(result.platesPerSide[0].weight, equals(45.0));
        expect(result.platesPerSide[1].weight, equals(45.0));
      },
    );
  });
}
