import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/theme/app_theme.dart';

class FastingRefeedGuideSheet extends StatefulWidget {
  const FastingRefeedGuideSheet({super.key, this.elapsedHours = 24.0});

  final double elapsedHours;

  static void show(BuildContext context, {double elapsedHours = 24.0}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext _) =>
          FastingRefeedGuideSheet(elapsedHours: elapsedHours),
    );
  }

  @override
  State<FastingRefeedGuideSheet> createState() =>
      _FastingRefeedGuideSheetState();
}

class _FastingRefeedGuideSheetState extends State<FastingRefeedGuideSheet> {
  final Set<int> _checkedSteps = <int>{};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
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

              // Title
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.soup_kitchen,
                      color: Colors.tealAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'STRUCTURED REFEEDING PROTOCOL',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Protecting digestive enzymes & electrolyte balance',
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
              const SizedBox(height: 16),

              // Why it matters alert
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.info_outline,
                        color: Colors.tealAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After ${widget.elapsedHours.toInt()}h without food, digestive enzymes, stomach acid, and bile are quiescent. Insulin sensitivity is sky-high. Breaking gradually prevents gastrointestinal cramps, osmotic diarrhea, and sudden intracellular phosphorus shifts.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          height: 1.4,
                          color: const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Phase 1
              _buildPhaseCard(
                stepIndex: 1,
                phaseNumber: 'PHASE 1 (HOUR 0)',
                title: 'Digestive Wake-Up & Gut Lining Coat',
                timeline: 'Immediate upon breaking fast',
                description:
                    '• 8–12 oz Warm Grass-Fed Bone Broth or Miso Broth\n• Pinch of unrefined sea salt\n• Wait 60–90 minutes before consuming solid food.\n• Glycine and glutamine in broth coat the quiescent intestinal mucosa.',
                color: Colors.tealAccent,
              ),
              const SizedBox(height: 12),

              // Phase 2
              _buildPhaseCard(
                stepIndex: 2,
                phaseNumber: 'PHASE 2 (HOUR 2)',
                title: 'Gentle Bioavailable Whole Foods',
                timeline: '2 hours post-broth',
                description:
                    '• 2 Soft-boiled or poached pasture-raised eggs\n• 1/2 Ripe Hass avocado (monounsaturated oleic acid & potassium)\n• 1 tbsp Raw unpasteurized sauerkraut or kimchi (probiotic flora)\n• Chew thoroughly; keep portion modest.',
                color: AppTheme.primaryAmber,
              ),
              const SizedBox(height: 12),

              // Phase 3
              _buildPhaseCard(
                stepIndex: 3,
                phaseNumber: 'PHASE 3 (HOUR 5+)',
                title: 'Glycogen Reload & Muscle Protein Synthesis',
                timeline: '5+ hours post-broth (or evening meal)',
                description:
                    '• 150–200g Wild Alaskan Salmon, Chicken, or Grass-Fed Beef\n• 1 Steamed sweet potato or 1 cup jasmine rice (clean glycogen reload)\n• Steamed greens with extra virgin olive oil\n• Resume standard athletic macronutrient tracking in OLY.',
                color: const Color(0xFF00E676),
              ),
              const SizedBox(height: 20),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'GOT IT — PROTOCOL REVIEWED',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseCard({
    required int stepIndex,
    required String phaseNumber,
    required String title,
    required String timeline,
    required String description,
    required Color color,
  }) {
    final bool isDone = _checkedSteps.contains(stepIndex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF141418) : const Color(0xFF1A1A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.white12 : color.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  phaseNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isDone) {
                      _checkedSteps.remove(stepIndex);
                    } else {
                      _checkedSteps.add(stepIndex);
                    }
                  });
                },
                child: Row(
                  children: <Widget>[
                    Icon(
                      isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: isDone ? AppTheme.primaryAmber : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDone ? 'Completed' : 'Mark Done',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDone ? AppTheme.primaryAmber : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            timeline,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}
