import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/services/fasting_engine_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/nutrition/fasting_science_explainer_screen.dart';

class FastingCellularCard extends StatelessWidget {
  const FastingCellularCard({
    required this.session,
    super.key,
  });

  final FastingSession session;

  @override
  Widget build(BuildContext context) {
    final FastingBiologicalStage stage = session.currentStage;
    final String trainingAdvisory =
        FastingEngineService.getBarbellAdvisory(session.elapsedHours);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stage.color.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: stage.color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stage.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.biotech,
                  color: stage.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CELLULAR & METABOLIC STATUS',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      stage.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.menu_book_outlined,
                  color: AppTheme.primaryAmber,
                  size: 20,
                ),
                tooltip: 'Fasting Science Reference',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) =>
                          const FastingScienceExplainerScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cellular Summary
          Text(
            stage.cellularSummary,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: const Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 14),

          // Training & Barbell Advisory
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF16161A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: AppTheme.primaryAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trainingAdvisory,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
