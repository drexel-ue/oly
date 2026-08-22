import 'package:flutter/material.dart';

class PlateSpec {
  final double weight;
  final String label;
  final Color color;
  final Color textColor;
  final double heightFactor; // 1.0 for standard bumper plate, smaller for fractionals
  final bool isFractional;

  const PlateSpec({
    required this.weight,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.heightFactor = 1.0,
    this.isFractional = false,
  });
}

class PlateCalcResult {
  final double targetWeight;
  final double actualWeight;
  final double barWeight;
  final double collarWeight;
  final List<PlateSpec> platesPerSide;
  final bool isExact;
  final String unit;

  PlateCalcResult({
    required this.targetWeight,
    required this.actualWeight,
    required this.barWeight,
    required this.collarWeight,
    required this.platesPerSide,
    required this.isExact,
    required this.unit,
  });
}

class PlateCalculator {
  // Standard IWF Color-Coded Plates in KG
  static const List<PlateSpec> kgPlates = [
    PlateSpec(weight: 25.0, label: '25', color: Color(0xFFE53935), heightFactor: 1.0),
    PlateSpec(weight: 20.0, label: '20', color: Color(0xFF1E88E5), heightFactor: 1.0),
    PlateSpec(weight: 15.0, label: '15', color: Color(0xFFFDD835), textColor: Colors.black, heightFactor: 1.0),
    PlateSpec(weight: 10.0, label: '10', color: Color(0xFF43A047), heightFactor: 1.0),
    PlateSpec(weight: 5.0, label: '5', color: Color(0xFFE0E0E0), textColor: Colors.black, heightFactor: 0.7, isFractional: true),
    PlateSpec(weight: 2.5, label: '2.5', color: Color(0xFFEF5350), heightFactor: 0.6, isFractional: true),
    PlateSpec(weight: 2.0, label: '2.0', color: Color(0xFF42A5F5), heightFactor: 0.55, isFractional: true),
    PlateSpec(weight: 1.5, label: '1.5', color: Color(0xFFFFEE58), textColor: Colors.black, heightFactor: 0.5, isFractional: true),
    PlateSpec(weight: 1.0, label: '1.0', color: Color(0xFF66BB6A), heightFactor: 0.45, isFractional: true),
    PlateSpec(weight: 0.5, label: '0.5', color: Color(0xFFFAFAFA), textColor: Colors.black, heightFactor: 0.4, isFractional: true),
  ];

  // Standard Plates in LBS
  static const List<PlateSpec> lbsPlates = [
    PlateSpec(weight: 45.0, label: '45', color: Color(0xFFE53935), heightFactor: 1.0),
    PlateSpec(weight: 35.0, label: '35', color: Color(0xFF1E88E5), heightFactor: 1.0),
    PlateSpec(weight: 25.0, label: '25', color: Color(0xFFFDD835), textColor: Colors.black, heightFactor: 0.85),
    PlateSpec(weight: 10.0, label: '10', color: Color(0xFF43A047), heightFactor: 0.7, isFractional: true),
    PlateSpec(weight: 5.0, label: '5', color: Color(0xFFE0E0E0), textColor: Colors.black, heightFactor: 0.55, isFractional: true),
    PlateSpec(weight: 2.5, label: '2.5', color: Color(0xFFEF5350), heightFactor: 0.45, isFractional: true),
  ];

  static PlateCalcResult calculate({
    required double targetWeight,
    double barWeight = 20.0,
    double collarWeight = 2.5, // 2.5kg pair (1.25kg each side) or total collar weight
    bool isLbs = false,
  }) {
    final availablePlates = isLbs ? lbsPlates : kgPlates;
    final unit = isLbs ? 'lbs' : 'kg';

    if (targetWeight <= barWeight) {
      return PlateCalcResult(
        targetWeight: targetWeight,
        actualWeight: barWeight,
        barWeight: barWeight,
        collarWeight: 0.0,
        platesPerSide: [],
        isExact: targetWeight == barWeight,
        unit: unit,
      );
    }

    double weightToLoad = targetWeight - barWeight - collarWeight;
    if (weightToLoad < 0) {
      // If adding collars makes it exceed target, try without collars
      weightToLoad = targetWeight - barWeight;
    }

    double weightPerSide = weightToLoad / 2.0;
    List<PlateSpec> resultPlates = [];

    double currentWeight = 0.0;
    for (var plate in availablePlates) {
      while (currentWeight + plate.weight <= weightPerSide + 0.0001) {
        resultPlates.add(plate);
        currentWeight += plate.weight;
      }
    }

    final actualWeight = barWeight + collarWeight + (currentWeight * 2.0);
    final isExact = (actualWeight - targetWeight).abs() < 0.01;

    return PlateCalcResult(
      targetWeight: targetWeight,
      actualWeight: actualWeight,
      barWeight: barWeight,
      collarWeight: collarWeight,
      platesPerSide: resultPlates,
      isExact: isExact,
      unit: unit,
    );
  }
}
