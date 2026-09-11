import 'package:intl/intl.dart';

/// Metabolic zone classification according to Dr. Thomas Seyfried's Glucose-Ketone Index (GKI)
enum GkiMetabolicZone {
  therapeuticAutophagy, // GKI < 1.0 (Highest cellular cleanup, deep ketosis)
  highKetosis, // 1.0 <= GKI < 3.0 (High ketosis, significant autophagy)
  moderateKetosis, // 3.0 <= GKI < 6.0 (Moderate ketosis, active fat burning)
  lowOrBaseline, // 6.0 <= GKI < 9.0 (Low ketosis)
  notInKetosis, // GKI >= 9.0 (Standard glucose-fueled state)
}

/// A biomarker log entry from Keto-Mojo or similar meter
class FastingBiomarkerEntry {
  const FastingBiomarkerEntry({
    required this.id,
    required this.timestamp,
    required this.glucoseMgDl,
    required this.ketoneMmolL,
    this.breathAcetonePpm,
    this.notes,
  });

  factory FastingBiomarkerEntry.create({
    required String id,
    required double glucoseMgDl,
    required double ketoneMmolL,
    DateTime? timestamp,
    double? breathAcetonePpm,
    String? notes,
  }) {
    return FastingBiomarkerEntry(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      glucoseMgDl: glucoseMgDl,
      ketoneMmolL: ketoneMmolL,
      breathAcetonePpm: breathAcetonePpm,
      notes: notes,
    );
  }

  factory FastingBiomarkerEntry.fromJson(Map<String, dynamic> json) {
    return FastingBiomarkerEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      glucoseMgDl: (json['glucoseMgDl'] as num).toDouble(),
      ketoneMmolL: (json['ketoneMmolL'] as num).toDouble(),
      breathAcetonePpm: json['breathAcetonePpm'] != null
          ? (json['breathAcetonePpm'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime timestamp;
  final double glucoseMgDl;
  final double ketoneMmolL;
  final double? breathAcetonePpm;
  final String? notes;

  /// Seyfried Glucose-Ketone Index (GKI) formula:
  /// GKI = (Glucose in mg/dL / 18.016) / Ketones in mmol/L
  /// If ketones <= 0, returns a very high number (99.0)
  double get gki {
    if (ketoneMmolL <= 0.05) {
      return 99.0;
    }
    final double glucoseMmolL = glucoseMgDl / 18.016;
    return glucoseMmolL / ketoneMmolL;
  }

  GkiMetabolicZone get zone {
    final double score = gki;
    if (score < 1.0) {
      return GkiMetabolicZone.therapeuticAutophagy;
    }
    if (score < 3.0) {
      return GkiMetabolicZone.highKetosis;
    }
    if (score < 6.0) {
      return GkiMetabolicZone.moderateKetosis;
    }
    if (score < 9.0) {
      return GkiMetabolicZone.lowOrBaseline;
    }
    return GkiMetabolicZone.notInKetosis;
  }

  String get zoneLabel {
    switch (zone) {
      case GkiMetabolicZone.therapeuticAutophagy:
        return 'Therapeutic Autophagy';
      case GkiMetabolicZone.highKetosis:
        return 'High Ketosis';
      case GkiMetabolicZone.moderateKetosis:
        return 'Moderate Ketosis';
      case GkiMetabolicZone.lowOrBaseline:
        return 'Low Ketosis';
      case GkiMetabolicZone.notInKetosis:
        return 'Baseline (Fed)';
    }
  }

  String get formattedTime => DateFormat('h:mm a').format(timestamp);
  String get formattedDate => DateFormat('MMM d, yyyy').format(timestamp);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'glucoseMgDl': glucoseMgDl,
      'ketoneMmolL': ketoneMmolL,
      if (breathAcetonePpm != null) 'breathAcetonePpm': breathAcetonePpm,
      if (notes != null) 'notes': notes,
    };
  }
}
