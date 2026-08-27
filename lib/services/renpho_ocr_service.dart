import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import '../models/body_composition_entry.dart';

class RenphoOcrService {
  final TextRecognizer _recognizer;

  RenphoOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> dispose() async {
    await _recognizer.close();
  }

  /// Processes an image from local file path and extracts Renpho Body Composition metrics
  Future<BodyCompositionEntry?> processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer.processImage(inputImage);
      return parseRecognizedText(recognizedText.text);
    } catch (e) {
      // Fallback or debug logging
      return null;
    }
  }

  /// Parses raw text extracted from a Renpho screenshot into a BodyCompositionEntry
  BodyCompositionEntry? parseRecognizedText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final normalized = rawText.replaceAll('\r\n', '\n');

    // Extract Timestamp
    DateTime? timestamp;
    final dateMatch = RegExp(
      r'([A-Za-z]{3}\s+\d{1,2},\s+\d{4}\s+at\s+\d{1,2}:\d{2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (dateMatch != null) {
      try {
        final dateStr = dateMatch.group(1)!;
        timestamp = DateFormat("MMM d, yyyy 'at' HH:mm:ss").parse(dateStr);
      } catch (_) {}
    }

    // Helper to extract double by key pattern
    double? extractDouble(String pattern, [int groupIndex = 1]) {
      final match = RegExp(pattern, caseSensitive: false, multiLine: true).firstMatch(normalized);
      if (match != null && match.groupCount >= groupIndex) {
        final val = match.group(groupIndex);
        if (val != null) return double.tryParse(val.replaceAll(',', '.'));
      }
      return null;
    }

    // Helper to extract integer
    int? extractInt(String pattern, [int groupIndex = 1]) {
      final match = RegExp(pattern, caseSensitive: false, multiLine: true).firstMatch(normalized);
      if (match != null && match.groupCount >= groupIndex) {
        final val = match.group(groupIndex);
        if (val != null) return int.tryParse(val);
      }
      return null;
    }

    // Helper to extract double and percentage pair: e.g. "56.2 lb, 21.2 %" or "150.6 lb, 56.9 %"
    (double? lb, double? pct) extractDualWeightPct(String label) {
      // 1. Try single-line dual match: "Body Water Average 150.6 lb, 56.9 %"
      final dualRegex = RegExp(
        '$label[^\\n\\r]*?(\\d+\\.?\\d*)\\s*(?:lb|kg)?\\s*,?\\s*(\\d+\\.?\\d*)\\s*%',
        caseSensitive: false,
      );
      final match = dualRegex.firstMatch(normalized);
      if (match != null) {
        final w = double.tryParse(match.group(1) ?? '');
        final p = double.tryParse(match.group(2) ?? '');
        return (w, p);
      }

      // 2. Try single-line percentage: "Body Fat 21.2 %"
      final pctRegex = RegExp('$label[^\\n\\r]*?(\\d+\\.?\\d*)\\s*%', caseSensitive: false);
      final pMatch = pctRegex.firstMatch(normalized);
      final p = pMatch != null ? double.tryParse(pMatch.group(1) ?? '') : null;

      // 3. Try single-line weight: "Body Water 150.6 lb"
      final weightRegex = RegExp('$label[^\\n\\r]*?(\\d+\\.?\\d*)\\s*(?:lb|kg)', caseSensitive: false);
      final wMatch = weightRegex.firstMatch(normalized);
      final w = wMatch != null ? double.tryParse(wMatch.group(1) ?? '') : null;

      return (w, p);
    }

    // 1. Weight (e.g. "Weight 264.8 lb" or "264.8 lb")
    double? weightLb = extractDouble(r'Weight\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+\.?\d*)\s*(?:lb|kg)?');
    if (weightLb == null) {
      // Check for standalone large number next to Weight
      final fallbackWeight = RegExp(r'(\d{2,3}\.\d)\s*lb', caseSensitive: false).firstMatch(normalized);
      if (fallbackWeight != null) {
        weightLb = double.tryParse(fallbackWeight.group(1) ?? '');
      }
    }

    // 2. BMI (e.g. "BMI High 34.9" or "BMI 34.9")
    final bmi = extractDouble(r'BMI\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+\.?\d*)');

    // 3. Body Fat (e.g. "Body Fat Average 56.2 lb, 21.2 %")
    final (bodyFatLb, bodyFatPct) = extractDualWeightPct(r'Body\s*Fat');

    // 4. Skeletal Muscle (e.g. "Skeletal Muscle Average 134.6 lb, 50.8 %")
    final (skeletalMuscleLb, skeletalMusclePct) = extractDualWeightPct(r'Skeletal\s*Muscle');

    // 5. Fat-Free Mass (e.g. "Fat-Free Mass Average 208.6 lb")
    final fatFreeMassLb = extractDouble(r'Fat[- ]Free\s*Mass\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+\.?\d*)\s*(?:lb|kg)?');

    // 6. Subcutaneous Fat (e.g. "Subcutaneous Fat High 16.8 %")
    final subcutaneousFatPct = extractDouble(r'Subcutaneous\s*Fat\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+\.?\d*)\s*%');

    // 7. Visceral Fat (e.g. "Visceral Fat High 17")
    final visceralFat = extractInt(r'Visceral\s*Fat\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+)');

    // 8. Body Water (e.g. "Body Water Average 150.6 lb, 56.9 %")
    final (bodyWaterLb, bodyWaterPct) = extractDualWeightPct(r'Body\s*Water');

    // 9. Muscle Mass (e.g. "Muscle Mass High 198.4 lb, 74.9 %")
    final (muscleMassLb, muscleMassPct) = extractDualWeightPct(r'Muscle\s*Mass');

    // 10. Bone Mass (e.g. "Bone Mass Average 10.4 lb, 3.9 %")
    final (boneMassLb, boneMassPct) = extractDualWeightPct(r'Bone\s*Mass');

    // 11. Protein (e.g. "Protein Average 47.6 lb, 18.0 %")
    final (proteinLb, proteinPct) = extractDualWeightPct(r'Protein');

    // 12. BMR (e.g. "BMR Average 2394 kcal")
    final bmrKcal = extractInt(r'BMR\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+)\s*kcal');

    // 13. Metabolic Age (e.g. "Metabolic Age High 35")
    final metabolicAge = extractInt(r'Metabolic\s*Age\s*(?:High|Average|Low)?\s*[:\-]?\s*(\d+)');

    if (weightLb == null || weightLb <= 0) {
      return null;
    }

    return BodyCompositionEntry.create(
      timestamp: timestamp ?? DateTime.now(),
      weightLb: weightLb,
      bmi: bmi,
      bodyFatPct: bodyFatPct,
      bodyFatLb: bodyFatLb,
      skeletalMuscleLb: skeletalMuscleLb,
      skeletalMusclePct: skeletalMusclePct,
      fatFreeMassLb: fatFreeMassLb,
      subcutaneousFatPct: subcutaneousFatPct,
      visceralFat: visceralFat,
      bodyWaterLb: bodyWaterLb,
      bodyWaterPct: bodyWaterPct,
      muscleMassLb: muscleMassLb,
      muscleMassPct: muscleMassPct,
      boneMassLb: boneMassLb,
      boneMassPct: boneMassPct,
      proteinLb: proteinLb,
      proteinPct: proteinPct,
      bmrKcal: bmrKcal,
      metabolicAge: metabolicAge,
      source: 'renpho_ocr',
    );
  }
}
