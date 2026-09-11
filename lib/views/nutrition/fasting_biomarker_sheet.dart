import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class FastingBiomarkerSheet extends StatefulWidget {
  const FastingBiomarkerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext _) => const FastingBiomarkerSheet(),
    );
  }

  @override
  State<FastingBiomarkerSheet> createState() => _FastingBiomarkerSheetState();
}

class _FastingBiomarkerSheetState extends State<FastingBiomarkerSheet> {
  final TextEditingController _glucoseController =
      TextEditingController(text: '80.0');
  final TextEditingController _ketoneController =
      TextEditingController(text: '1.5');
  final TextEditingController _notesController = TextEditingController();

  double get _glucose => double.tryParse(_glucoseController.text) ?? 80.0;
  double get _ketone => double.tryParse(_ketoneController.text) ?? 1.5;

  double get _calculatedGki {
    if (_ketone <= 0.05) {
      return 99.0;
    }
    final double glucoseMmolL = _glucose / 18.016;
    return glucoseMmolL / _ketone;
  }

  GkiMetabolicZone get _zone {
    final double score = _calculatedGki;
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

  Color get _zoneColor {
    switch (_zone) {
      case GkiMetabolicZone.therapeuticAutophagy:
        return const Color(0xFF00E676); // Emerald
      case GkiMetabolicZone.highKetosis:
        return AppTheme.primaryAmber;
      case GkiMetabolicZone.moderateKetosis:
        return const Color(0xFF26C6DA);
      case GkiMetabolicZone.lowOrBaseline:
        return const Color(0xFF42A5F5);
      case GkiMetabolicZone.notInKetosis:
        return Colors.grey;
    }
  }

  String get _zoneTitle {
    switch (_zone) {
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

  @override
  void dispose() {
    _glucoseController.dispose();
    _ketoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FastingProvider fasting = Provider.of<FastingProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bloodtype,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'LOG KETO-MOJO BIOMARKERS',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Capillary Blood Glucose + Blood Ketone (BHB)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live GKI Gauge Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _zoneColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'SEYFRIED GKI INDEX',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _zoneColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _zoneColor),
                        ),
                        child: Text(
                          _zoneTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _zoneColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        _calculatedGki < 90
                            ? _calculatedGki.toStringAsFixed(2)
                            : '--',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GKI SCORE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Inputs Row
            Row(
              children: <Widget>[
                // Glucose Input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Blood Glucose (mg/dL)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _glucoseController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          suffixText: 'mg/dL',
                          suffixStyle: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF1A1A22),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: AppTheme.primaryAmber),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Ketone Input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Blood Ketones (mmol/L)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _ketoneController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          suffixText: 'mmol/L',
                          suffixStyle: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF1A1A22),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: AppTheme.primaryAmber),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Optional Notes
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Notes (e.g. 5:00 AM Fasting Baseline, Post-Lift)',
                labelStyle:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1A1A22),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white12),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.primaryAmber),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  'RECORD BIOMARKER ENTRY',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: () {
                  fasting.addBiomarkerEntry(
                    glucoseMgDl: _glucose,
                    ketoneMmolL: _ketone,
                    notes: _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : null,
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
