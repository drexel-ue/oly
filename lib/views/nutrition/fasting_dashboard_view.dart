import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/fasting_biomarker_entry.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/nutrition/fasting_biomarker_history_sheet.dart';
import 'package:oly/views/nutrition/fasting_biomarker_sheet.dart';
import 'package:oly/views/nutrition/fasting_refeed_guide_sheet.dart';
import 'package:oly/views/nutrition/fasting_science_explainer_screen.dart';
import 'package:oly/views/nutrition/fasting_setup_sheet.dart';
import 'package:oly/widgets/nutrition/fasting_cellular_card.dart';
import 'package:oly/widgets/nutrition/fasting_grocery_sheet.dart';
import 'package:oly/widgets/nutrition/fasting_projection_card.dart';
import 'package:oly/widgets/nutrition/fasting_radial_gauge.dart';
import 'package:provider/provider.dart';

class FastingDashboardView extends StatelessWidget {
  const FastingDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final FastingProvider fasting = Provider.of<FastingProvider>(context);
    final FastingSession? active = fasting.activeSession;

    if (active == null) {
      return _buildInactiveView(context, fasting);
    }

    return _buildActiveView(context, fasting, active);
  }

  Widget _buildInactiveView(BuildContext context, FastingProvider fasting) {
    final List<FastingSession> history = fasting.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Hero Inactive Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryAmber),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: AppTheme.primaryAmber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Active Fast in Progress',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to begin your 16:8 circadian cycle? Eating window: 10:00 AM – 6:00 PM.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: Text(
                    'START GUIDED FAST',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: () => FastingSetupSheet.show(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Keto-Mojo Blood Glucose, Ketones & GKI Card
        _buildKetoMojoCard(context, fasting),
        const SizedBox(height: 16),

        // Quick Tools Row (Pantry, GKI Tracking, Science)
        _buildQuickToolsRow(context),
        const SizedBox(height: 16),

        // 7-Day Forward Projection Card
        FastingProjectionCard(scheduleDays: fasting.projectionSchedule),
        const SizedBox(height: 16),

        // History Section
        if (history.isNotEmpty) ...<Widget>[
          Text(
            'FASTING HISTORY & COMPLETED CYCLES',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...history.take(5).map((FastingSession s) => _buildHistoryTile(s)),
        ],
      ],
    );
  }

  Widget _buildActiveView(
      BuildContext context, FastingProvider fasting, FastingSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Hero Radial Dial
        FastingRadialGauge(session: session, size: 260),
        const SizedBox(height: 18),

        // Live Cellular Mechanism Card
        FastingCellularCard(session: session),
        const SizedBox(height: 16),

        // Electrolyte & Hydration Station
        _buildElectrolyteStation(context, fasting, session),
        const SizedBox(height: 16),

        // Keto-Mojo Biomarker Card
        _buildKetoMojoCard(context, fasting),
        const SizedBox(height: 16),

        // 7-Day Forward Projection
        FastingProjectionCard(scheduleDays: fasting.projectionSchedule),
        const SizedBox(height: 16),

        // Quick Tools
        _buildQuickToolsRow(context),
        const SizedBox(height: 20),

        // Bottom Action Buttons (End Fast / Cancel)
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _confirmCancelFast(context, fasting),
                child: Text(
                  'Cancel Fast',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'END FAST & REFEED',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                onPressed: () => _confirmEndFast(context, fasting, session),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildElectrolyteStation(
      BuildContext context, FastingProvider fasting, FastingSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.water_drop, size: 18, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  Text(
                    'ELECTROLYTE & HYDRATION STATION',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showSnakeJuiceDialog(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Saline Recipe',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Logged Metrics
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('SODIUM LOGGED',
                          style: GoogleFonts.inter(
                              fontSize: 9, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${session.sodiumLoggedMg} mg',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('WATER LOGGED',
                          style: GoogleFonts.inter(
                              fontSize: 9, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${session.waterLoggedMl} mL',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1-Tap Quick Log Chips
          Wrap(
            spacing: 8,
            children: <Widget>[
              ActionChip(
                backgroundColor: const Color(0xFF22222C),
                avatar: const Icon(Icons.add, size: 14, color: AppTheme.primaryAmber),
                label: Text('+500mg Salt',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                onPressed: () => fasting.logSodium(500),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF22222C),
                avatar: const Icon(Icons.add, size: 14, color: Colors.cyanAccent),
                label: Text('+250mL Water',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                onPressed: () => fasting.logWater(250),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF22222C),
                avatar: const Icon(Icons.add, size: 14, color: Colors.cyanAccent),
                label: Text('+500mL Water',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                onPressed: () => fasting.logWater(500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKetoMojoCard(BuildContext context, FastingProvider fasting) {
    final FastingBiomarkerEntry? latest = fasting.latestBiomarker;
    final int logCount = fasting.allBiomarkers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.bloodtype, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    'KETO-MOJO BIOMARKERS & GKI',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  if (logCount > 0) ...<Widget>[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => FastingBiomarkerHistorySheet.show(context),
                      icon: const Icon(Icons.insights, size: 14, color: Colors.cyanAccent),
                      label: Text(
                        'History ($logCount)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => FastingBiomarkerSheet.show(context),
                    icon: const Icon(Icons.add, size: 14, color: AppTheme.primaryAmber),
                    label: Text(
                      'Log Test',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (latest != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('GLUCOSE',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppTheme.textSecondary)),
                        Text(
                          '${latest.glucoseMgDl.toInt()} mg/dL',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('KETONES (BHB)',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppTheme.textSecondary)),
                        Text(
                          '${latest.ketoneMmolL} mmol/L',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('GKI INDEX',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppTheme.textSecondary)),
                        Text(
                          latest.gki < 90
                              ? latest.gki.toStringAsFixed(2)
                              : '--',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Zone: ${latest.zoneLabel} • ${DateFormat('MMM d, h:mm a').format(latest.timestamp)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: () => FastingBiomarkerHistorySheet.show(context),
                  child: Text(
                    'All Logs →',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            Text(
              'No blood readings recorded yet. Log your capillary glucose and ketone strips to track your live Seyfried Glucose-Ketone Index (GKI).',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.bloodtype, size: 16, color: Colors.redAccent),
                label: Text(
                  'RECORD FIRST BLOOD TEST',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                onPressed: () => FastingBiomarkerSheet.show(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickToolsRow(BuildContext context) {
    return Row(
      children: <Widget>[
        // Pantry Checklist
        Expanded(
          child: InkWell(
            onTap: () => FastingGrocerySheet.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.shopping_basket_outlined,
                      color: AppTheme.primaryAmber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('PANTRY & FOOD',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Fasting essentials',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Biomarker Tracking
        Expanded(
          child: InkWell(
            onTap: () => FastingBiomarkerHistorySheet.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.insights,
                      color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('GKI TRACKING',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Blood history',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Science Explainer
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) =>
                      const FastingScienceExplainerScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.science_outlined,
                      color: Color(0xFF00E676), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('SCIENCE',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('mTOR & 72h',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(FastingSession session) {
    final int hours = (session.elapsedSeconds / 3600).round();
    final String dateStr =
        DateFormat('MMM d, yyyy').format(session.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle,
                  color: AppTheme.primaryAmber, size: 16),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    session.protocol.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$dateStr • ${session.protocol.shortCode}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${hours}h Fasted',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAmber,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnakeJuiceDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.water_drop, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Text(
                'Fasting Saline ("Snake Juice")',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'In 1 Liter (34 oz) clean water, dissolve:\n\n'
            '• 1/2 tsp Pink Himalayan or Celtic Salt (~1,100 mg Sodium)\n'
            '• 1/2 tsp Potassium Chloride / NoSalt (~1,300 mg Potassium)\n'
            '• 1/4 tsp Food-grade Epsom Salt or 200mg Magnesium powder\n\n'
            'Sip steadily throughout your fasting hours. Prevents headaches, lethargy, and orthostatic dizziness.',
            style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: const Color(0xFFD1D5DB)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryAmber)),
            ),
          ],
        );
      },
    );
  }

  void _confirmCancelFast(BuildContext context, FastingProvider fasting) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Fast?'),
          content: const Text(
            'Are you sure you want to cancel this fast? It will not be logged in your completed history.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Fasting',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                fasting.cancelFast();
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel Fast'),
            ),
          ],
        );
      },
    );
  }

  void _confirmEndFast(
      BuildContext context, FastingProvider fasting, FastingSession session) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'End Fast & Begin Refeed?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You completed ${session.elapsedHours.toStringAsFixed(1)} hours fasted!\n\n'
            'Ending your fast unlocks the step-by-step Structured Refeeding Protocol.',
            style: GoogleFonts.inter(fontSize: 12, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Fasting',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAmber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final double hours = session.elapsedHours;
                fasting.endFast();
                Navigator.of(ctx).pop();
                FastingRefeedGuideSheet.show(context, elapsedHours: hours);
              },
              child: const Text('Complete & Refeed'),
            ),
          ],
        );
      },
    );
  }
}
