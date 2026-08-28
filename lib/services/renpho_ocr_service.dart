import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import '../models/body_composition_entry.dart';
import 'app_log_service.dart';

class OcrScanResult {
  final BodyCompositionEntry? entry;
  final String rawText;
  final String? errorMessage;
  final bool isSuccess;
  final int fieldsFound;

  const OcrScanResult({
    this.entry,
    required this.rawText,
    this.errorMessage,
    required this.isSuccess,
    this.fieldsFound = 0,
  });
}

class RenphoOcrService {
  final TextRecognizer _recognizer;

  RenphoOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> dispose() async {
    await _recognizer.close();
  }

  /// Extracts raw OCR text from an image file
  Future<String> extractRawTextFromImage(String imagePath) async {
    final result = await processImage(imagePath);
    return result.rawText;
  }

  /// Processes an image from local file path and extracts Renpho Body Composition metrics
  Future<OcrScanResult> processImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return const OcrScanResult(
          rawText: '',
          errorMessage: 'Image file does not exist on device.',
          isSuccess: false,
        );
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      debugPrint('--- [RenphoOcrService] RAW OCR EXTRACTED TEXT ---');
      debugPrint(rawText);
      debugPrint('--- [RenphoOcrService] END RAW TEXT ---');

      if (rawText.trim().isEmpty) {
        return const OcrScanResult(
          rawText: '',
          errorMessage: 'No text was detected in the selected image. Please try a clearer screenshot.',
          isSuccess: false,
        );
      }

      final entry = parseRecognizedText(rawText);
      if (entry != null) {
        return OcrScanResult(
          entry: entry,
          rawText: rawText,
          isSuccess: true,
          fieldsFound: _countExtractedFields(entry),
        );
      } else {
        return OcrScanResult(
          rawText: rawText,
          errorMessage: 'Detected text, but could not identify Renpho scale biometrics.',
          isSuccess: false,
        );
      }
    } catch (e, stack) {
      debugPrint('[RenphoOcrService] OCR Processing Exception: $e\n$stack');
      AppLogService.instance.error('RENPHO_OCR', 'OCR Processing exception on $imagePath', error: e, stackTrace: stack);
      return OcrScanResult(
        rawText: '',
        errorMessage: 'OCR Engine error: $e',
        isSuccess: false,
      );
    }
  }

  static int _countExtractedFields(BodyCompositionEntry entry) {
    int count = 0;
    if (entry.weightLb > 0) count++;
    if (entry.bmi != null) count++;
    if (entry.bodyFatPct != null) count++;
    if (entry.skeletalMuscleLb != null) count++;
    if (entry.fatFreeMassLb != null) count++;
    if (entry.subcutaneousFatPct != null) count++;
    if (entry.visceralFat != null) count++;
    if (entry.bodyWaterLb != null || entry.bodyWaterPct != null) count++;
    if (entry.muscleMassLb != null) count++;
    if (entry.boneMassLb != null) count++;
    if (entry.proteinLb != null || entry.proteinPct != null) count++;
    if (entry.bmrKcal != null) count++;
    if (entry.metabolicAge != null) count++;
    return count;
  }

  /// Parses raw text extracted from a Renpho screenshot into a BodyCompositionEntry
  BodyCompositionEntry? parseRecognizedText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    // 1. Normalize OCR text: replace typos (Ib -> lb, kca1 -> kcal, O Protein -> Protein)
    String normalized = rawText
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\bIb\b|\bIB\b|\b1b\b', caseSensitive: true), 'lb')
        .replaceAll(RegExp(r'O\s+Protein', caseSensitive: false), 'Protein')
        .replaceAll(RegExp(r'kca1|kcaI', caseSensitive: false), 'kcal')
        .replaceAll('·', '.')
        .replaceAll('•', '.');

    // Extract Timestamp (e.g. "Jul 21, 2026 at 19:30:37" or "07/21/2026 19:30:37")
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

    double? weightLb;
    double? bmi;
    double? bodyFatLb;
    double? bodyFatPct;
    double? skeletalMuscleLb;
    double? skeletalMusclePct;
    double? fatFreeMassLb;
    double? subcutaneousFatPct;
    int? visceralFat;
    double? bodyWaterLb;
    double? bodyWaterPct;
    double? muscleMassLb;
    double? muscleMassPct;
    double? boneMassLb;
    double? boneMassPct;
    double? proteinLb;
    double? proteinPct;
    int? bmrKcal;
    int? metabolicAge;

    // =========================================================================
    // PASS 1: Renpho 4-Card Grid Cluster Parser
    // In Renpho exports, ML Kit scans grid cards by outputting all card titles
    // first, followed by all card values in the exact same sequence.
    // =========================================================================

    // Cluster 1: Weight, BMI, Body Fat, Skeletal Muscle
    final cluster1Regex = RegExp(
      r'Weight[\s\S]*?BMI[\s\S]*?Body\s*Fat[\s\S]*?Skeletal\s*Muscle[\s\S]*?(\d{2,3}(?:\.\d+)?)\s*(?:lb)?[\s\n]+(\d{1,2}(?:\.\d+)?)[\s\n]+(\d{1,3}(?:\.\d+)?)\s*lb\s*,\s*(\d{1,2}(?:\.\d+)?)\s*%[\s\n]+(\d{1,3}(?:\.\d+)?)\s*lb\s*,\s*(\d{1,2}(?:\.\d+)?)\s*%',
      caseSensitive: false,
    );
    final c1Match = cluster1Regex.firstMatch(normalized);
    if (c1Match != null) {
      weightLb ??= double.tryParse(c1Match.group(1) ?? '');
      bmi ??= double.tryParse(c1Match.group(2) ?? '');
      bodyFatLb ??= double.tryParse(c1Match.group(3) ?? '');
      bodyFatPct ??= double.tryParse(c1Match.group(4) ?? '');
      skeletalMuscleLb ??= double.tryParse(c1Match.group(5) ?? '');
      skeletalMusclePct ??= double.tryParse(c1Match.group(6) ?? '');
    }

    // Cluster 2: Fat-Free Mass, Subcutaneous Fat, Visceral Fat, Body Water
    final cluster2Regex = RegExp(
      r'Fat[- ]*Free\s*Mass[\s\S]*?Subcutaneous\s*Fat[\s\S]*?Visceral\s*Fat[\s\S]*?Body\s*Water[\s\S]*?(\d{2,3}(?:\.\d+)?)\s*lb[\s\n]+(\d{1,2}(?:\.\d+)?)\s*%[\s\n]+(\d{1,2})[\s\n]+(\d{2,3}(?:\.\d+)?)\s*lb\s*,\s*(\d{1,2}(?:\.\d+)?)\s*%',
      caseSensitive: false,
    );
    final c2Match = cluster2Regex.firstMatch(normalized);
    if (c2Match != null) {
      fatFreeMassLb ??= double.tryParse(c2Match.group(1) ?? '');
      subcutaneousFatPct ??= double.tryParse(c2Match.group(2) ?? '');
      visceralFat ??= int.tryParse(c2Match.group(3) ?? '');
      bodyWaterLb ??= double.tryParse(c2Match.group(4) ?? '');
      bodyWaterPct ??= double.tryParse(c2Match.group(5) ?? '');
    }

    // Cluster 3: Muscle Mass, Bone Mass, Protein
    final cluster3Regex = RegExp(
      r'Muscle\s*Mass[\s\S]*?Bone\s*Mass[\s\S]*?Protein[\s\S]*?(\d{2,3}(?:\.\d+)?)\s*lb\s*,\s*(\d{1,2}(?:\.\d+)?)\s*%[\s\n]+(\d{1,2}(?:\.\d+)?)\s*lb\s*,\s*(\d{1,2}(?:\.\d+)?)\s*%[\s\n]+(\d{1,3}(?:\.\d+)?)\s*lb\s*,\s*(\d{1,2}(?:\.\d+)?)\s*%',
      caseSensitive: false,
    );
    final c3Match = cluster3Regex.firstMatch(normalized);
    if (c3Match != null) {
      muscleMassLb ??= double.tryParse(c3Match.group(1) ?? '');
      muscleMassPct ??= double.tryParse(c3Match.group(2) ?? '');
      boneMassLb ??= double.tryParse(c3Match.group(3) ?? '');
      boneMassPct ??= double.tryParse(c3Match.group(4) ?? '');
      proteinLb ??= double.tryParse(c3Match.group(5) ?? '');
      proteinPct ??= double.tryParse(c3Match.group(6) ?? '');
    }

    // Cluster 4: BMR, Metabolic Age
    final cluster4Regex = RegExp(
      r'BMR[\s\S]*?Metabolic\s*Age[\s\S]*?(\d{3,4})\s*(?:kcal)?[\s\n]+(\d{1,3})',
      caseSensitive: false,
    );
    final c4Match = cluster4Regex.firstMatch(normalized);
    if (c4Match != null) {
      bmrKcal ??= int.tryParse(c4Match.group(1) ?? '');
      metabolicAge ??= int.tryParse(c4Match.group(2) ?? '');
    }

    // =========================================================================
    // PASS 2: Regex Direct Matcher for single-line or multiline adjacent label-value lines
    // =========================================================================

    // Direct Dual Matcher (e.g. "Body Fat Average 56.2 lb, 21.2 %" or split across lines)
    (double? lb, double? pct) extractDual(String label) {
      final match = RegExp(
        '$label[\\s\\n]*(?:High|Average|Low|Standard)?[\\s\\n:]*(\\d{1,4}(?:[.,]\\d+)?)\\s*lb\\s*[,/\\s\\n]+\\s*(\\d{1,3}(?:[.,]\\d+)?)\\s*%',
        caseSensitive: false,
      ).firstMatch(normalized);
      if (match != null) {
        return (
          double.tryParse(match.group(1)?.replaceAll(',', '.') ?? ''),
          double.tryParse(match.group(2)?.replaceAll(',', '.') ?? ''),
        );
      }
      return (null, null);
    }

    if (bodyFatLb == null || bodyFatPct == null) {
      final (w, p) = extractDual(r'Body\s*Fat');
      bodyFatLb ??= w;
      bodyFatPct ??= p;
    }

    if (skeletalMuscleLb == null || skeletalMusclePct == null) {
      final (w, p) = extractDual(r'Skeletal\s*Muscle');
      skeletalMuscleLb ??= w;
      skeletalMusclePct ??= p;
    }

    if (bodyWaterLb == null || bodyWaterPct == null) {
      final (w, p) = extractDual(r'Body\s*Water');
      bodyWaterLb ??= w;
      bodyWaterPct ??= p;
    }

    if (muscleMassLb == null || muscleMassPct == null) {
      final (w, p) = extractDual(r'Muscle\s*Mass');
      muscleMassLb ??= w;
      muscleMassPct ??= p;
    }

    if (boneMassLb == null || boneMassPct == null) {
      final (w, p) = extractDual(r'Bone\s*Mass');
      boneMassLb ??= w;
      boneMassPct ??= p;
    }

    if (proteinLb == null || proteinPct == null) {
      final (w, p) = extractDual(r'Protein');
      proteinLb ??= w;
      proteinPct ??= p;
    }

    // Direct Single-Value Matchers (supporting newline separation)
    if (fatFreeMassLb == null) {
      final m = RegExp(r'Fat[- ]*Free\s*Mass[\s\n]*(?:High|Average|Low|Standard)?[\s\n:]*(\d{2,3}(?:[.,]\d+)?)\s*lb', caseSensitive: false).firstMatch(normalized);
      fatFreeMassLb = double.tryParse(m?.group(1)?.replaceAll(',', '.') ?? '');
    }

    if (subcutaneousFatPct == null) {
      final m = RegExp(r'Subcutaneous\s*Fat[\s\n]*(?:High|Average|Low|Standard)?[\s\n:]*(\d{1,2}(?:[.,]\d+)?)\s*%', caseSensitive: false).firstMatch(normalized);
      subcutaneousFatPct = double.tryParse(m?.group(1)?.replaceAll(',', '.') ?? '');
    }

    if (visceralFat == null) {
      final m = RegExp(r'Visceral\s*Fat[\s\n]*(?:High|Average|Low|Standard)?[\s\n:]*(\d{1,2})\b', caseSensitive: false).firstMatch(normalized);
      visceralFat = int.tryParse(m?.group(1) ?? '');
    }

    if (bmi == null) {
      final m = RegExp(r'BMI[\s\n]*(?:High|Average|Low|Standard)?[\s\n:]*(\d{1,2}(?:[.,]\d+)?)', caseSensitive: false).firstMatch(normalized);
      bmi = double.tryParse(m?.group(1)?.replaceAll(',', '.') ?? '');
    }

    if (bmrKcal == null) {
      final m = RegExp(r'BMR[\s\n]*(?:High|Average|Low|Standard)?[\s\n:]*(\d{3,4})\s*kcal', caseSensitive: false).firstMatch(normalized);
      bmrKcal = int.tryParse(m?.group(1) ?? '');
    }

    if (metabolicAge == null) {
      final m = RegExp(r'Metabolic\s*Age[\s\n]*(?:High|Average|Low|Standard)?[\s\n:]*(\d{1,3})', caseSensitive: false).firstMatch(normalized);
      metabolicAge = int.tryParse(m?.group(1) ?? '');
    }

    // Weight Fallback from Top Donut or main card
    if (weightLb == null || weightLb <= 0) {
      final weightDirect = RegExp(r'Weight[^\n\r]*?(\d{2,3}(?:[.,]\d+)?)\s*lb', caseSensitive: false).firstMatch(normalized);
      if (weightDirect != null) {
        weightLb = double.tryParse(weightDirect.group(1)?.replaceAll(',', '.') ?? '');
      }
    }

    if (weightLb == null || weightLb <= 0) {
      final weightFollowed = RegExp(r'Weight[\s\n]+(\d{2,3}(?:[.,]\d+)?)', caseSensitive: false).firstMatch(normalized);
      if (weightFollowed != null) {
        weightLb = double.tryParse(weightFollowed.group(1)?.replaceAll(',', '.') ?? '');
      }
    }

    // If still null, sum FatFreeMass + BodyFat
    if ((weightLb == null || weightLb <= 0) && fatFreeMassLb != null && bodyFatLb != null) {
      weightLb = fatFreeMassLb + bodyFatLb;
    }

    // Validation: Return entry if at least 2 metrics or weight was found
    final foundCount = [
      weightLb,
      bmi,
      bodyFatPct,
      skeletalMuscleLb,
      fatFreeMassLb,
      bodyWaterPct,
      muscleMassLb,
      boneMassLb,
      proteinPct,
      bmrKcal,
      metabolicAge,
    ].where((v) => v != null).length;

    if (foundCount < 2 && (weightLb == null || weightLb <= 0)) {
      return null;
    }

    return BodyCompositionEntry.create(
      timestamp: timestamp ?? DateTime.now(),
      weightLb: weightLb ?? 200.0,
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
