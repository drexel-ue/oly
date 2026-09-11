import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/theme/app_theme.dart';

class FastingScienceExplainerScreen extends StatelessWidget {
  const FastingScienceExplainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceCard,
          elevation: 0,
          title: Text(
            'Fasting Science & Physiology',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.primaryAmber,
            labelColor: AppTheme.primaryAmber,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const <Widget>[
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.biotech, size: 16),
                    SizedBox(width: 6),
                    Text('Cellular Biology'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.timeline, size: 16),
                    SizedBox(width: 6),
                    Text('72-Hour Timeline'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.fitness_center, size: 16),
                    SizedBox(width: 6),
                    Text('6 AM Lifter Blueprint'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.water_drop_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Electrolytes & Salt'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.bloodtype_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Keto-Mojo & GKI'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildCellularBiologyTab(),
            _buildTimelineTab(),
            _buildLifterBlueprintTab(),
            _buildElectrolytesTab(),
            _buildGkiMathTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCellularBiologyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: 'The Master Metabolic Switch: mTOR vs. AMPK',
          subtitle: 'How cellular energy sensors govern growth and recycling',
          icon: Icons.sync_alt,
          color: AppTheme.primaryAmber,
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          title: '1. The Fed State: mTOR Activation (Growth)',
          content:
              'When calories and amino acids (particularly leucine) are present, circulating insulin activates mTORC1 (mechanistic target of rapamycin). mTOR stimulates muscle protein synthesis, glycogen accumulation, and cell proliferation. Simultaneously, it phosphorylates ULK1, shutting down autophagic recycling.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '2. The Fasted State: AMPK Activation (Autophagy)',
          content:
              'As hepatic glycogen depletes and cellular ATP/AMP ratios drop, the energy sensor AMPK (5′ AMP-activated protein kinase) is activated. AMPK directly suppresses mTORC1 and activates ULK1, initiating macroautophagy. Cells sequester damaged organelles and protein aggregates into autophagosomes, fusing with lysosomes for recycling.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '3. Muscle Preservation & Human Growth Hormone (HGH)',
          content:
              'A common myth is that fasting burns muscle tissue. In reality, fasting induces an evolutionary survival adaptation: endogenous HGH pulses increase by up to 300–500% at 24–48 hours. HGH preserves skeletal muscle mass and structural proteins while circulating ketones (BHB) and free fatty acids fulfill peripheral energy demands.',
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: 'The Biological Milestones (0 to 72 Hours)',
          subtitle: 'What happens inside human physiology hour-by-hour',
          icon: Icons.history_toggle_off,
          color: const Color(0xFF26C6DA),
        ),
        const SizedBox(height: 14),
        _buildStageStep(
          range: '0 – 4 Hours',
          phase: 'FED / DIGESTIVE STATE',
          desc:
              'Nutrients absorbed. Blood glucose peaks and returns to baseline. Insulin partitions calories into liver/muscle glycogen and triglycerides.',
          color: const Color(0xFF9E9E9E),
        ),
        _buildStageStep(
          range: '4 – 12 Hours',
          phase: 'EARLY POST-ABSORPTIVE',
          desc:
              'Insulin drops to basal levels; glucagon rises. Hepatic glycogen phosphorylase breaks down glycogen to maintain 70–90 mg/dL blood sugar. First ghrelin wave occurs around usual meal times.',
          color: const Color(0xFF42A5F5),
        ),
        _buildStageStep(
          range: '12 – 18 Hours',
          phase: 'KETOSIS ONSET & LIPOLYSIS',
          desc:
              'Liver glycogen ~75% depleted. Adipose lipolysis accelerates; liver synthesizes beta-hydroxybutyrate (BHB) ketones. Circulating ketones rise above 0.5 mmol/L.',
          color: const Color(0xFF26C6DA),
        ),
        _buildStageStep(
          range: '18 – 24 Hours',
          phase: 'AUTOPHAGY ACTIVATION (AMPK SURGE)',
          desc:
              'AMPK turns off mTOR. Intracellular lysosomes begin cleaning misfolded proteins and dysfunctional mitochondria (mitophagy). Hunger frequently subsides.',
          color: const Color(0xFFAB47BC),
        ),
        _buildStageStep(
          range: '24 – 48 Hours',
          phase: 'DEEP AUTOPHAGY & HGH SURGE',
          desc:
              'Glycogen exhausted. Endogenous HGH pulses up to 400% above baseline to preserve skeletal muscle. Brain-Derived Neurotrophic Factor (BDNF) elevates, sharpening mental focus.',
          color: AppTheme.primaryAmber,
        ),
        _buildStageStep(
          range: '48 – 72+ Hours',
          phase: 'PEAK STEM CELL & IMMUNE RESET',
          desc:
              "Dr. Valter Longo's research (USC) demonstrates that 48–72h fasts trigger hematopoietic stem cell self-renewal. Senescent white blood cells undergo apoptosis. Systemic inflammation markers (CRP, TNF-α) drop dramatically.",
          color: const Color(0xFF00E676),
        ),
      ],
    );
  }

  Widget _buildLifterBlueprintTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: "The 6:00 AM Lifter's Circadian Blueprint",
          subtitle: 'Syncing heavy Olympic lifting with 4:45 AM wake and 8:45 PM sleep',
          icon: Icons.fitness_center,
          color: AppTheme.primaryAmber,
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          title: '1. Why Dinner Must End by 6:00 PM',
          content:
              'Digesting food within 2.5 hours of sleep elevates core body temperature, raises resting heart rate by 8–15 bpm, and impairs nocturnal HRV. For an 8:45 PM bedtime, finishing food by 6:00 PM ensures an empty gastrointestinal tract, promoting deep restorative slow-wave sleep and peak nighttime HGH release.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '2. The 5:15 AM "Platform Primer"',
          content:
              'When waking at 4:45 AM and lifting at 6:00 AM fasted, overnight sodium dumping can cause orthostatic dizziness when standing up from a heavy clean or front squat.\n\nTake 45 minutes prior to the session:\n• 16–20 oz Room-temp water\n• 600–800 mg Sodium (1/4 tsp Pink Himalayan / Celtic salt)\n• Optional 1 cup black coffee (spikes epinephrine and fat oxidation without breaking the fast).',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: '3. Barbell Load Regulation by Fast Duration',
          content:
              '• Under 18h Fasted: Full heavy Olympic lifting and WODs permitted. Intramuscular glycogen from the prior day is intact.\n• 18h – 36h Fasted: Emphasize positional technique, speed under the bar, and pull volume. Avoid maximal 1RM attempts (>90%).\n• 36h – 72h Fasted: Zero heavy barbell work. Swap with OLY Active Mobility, foam rolling, and Wim Hof breathwork.',
        ),
      ],
    );
  }

  Widget _buildElectrolytesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: 'The Natriuresis of Fasting',
          subtitle: 'Why salt and minerals are non-negotiable on extended fasts',
          icon: Icons.water_drop,
          color: Colors.cyanAccent,
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          title: 'What is Fasting Natriuresis?',
          content:
              'Insulin signals renal tubules in the kidneys to retain sodium. As insulin plummets during fasting, the kidneys rapidly excrete sodium into urine, pulling water along with it. Fasting headaches, fatigue, muscle cramps, and "keto flu" are acute electrolyte depletion, not lack of calories.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Daily Extended Fasting Baseline (24h+)',
          content:
              '• Sodium: 2,500 – 4,000 mg (1 – 1.5 tsp Pink Himalayan or sea salt)\n• Potassium: 1,000 – 2,000 mg (e.g. NoSalt / potassium chloride)\n• Magnesium: 300 – 400 mg (magnesium glycinate or malate taken in the evening to prevent cramping and support sleep).\n\nRule: Sip salted water across the day rather than chugging in a single bolus.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'The Fasting Saline / "Snake Juice" Formula',
          content:
              'In 1 Liter (34 oz) of water, dissolve:\n• 1/2 tsp Pink Himalayan Salt (Sodium ~1,100 mg)\n• 1/2 tsp Potassium Chloride / NoSalt (Potassium ~1,300 mg)\n• 1/4 tsp Food-grade Epsom Salt or 200mg Magnesium powder\nSip throughout your fasting day.',
        ),
      ],
    );
  }

  Widget _buildGkiMathTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: 'The Seyfried Glucose-Ketone Index (GKI)',
          subtitle: 'The clinical formula for measuring metabolic autophagy depth',
          icon: Icons.calculate_outlined,
          color: Colors.purpleAccent,
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          title: 'The Formula',
          content:
              'Developed by Dr. Thomas Seyfried at Boston College:\n\nGKI = [Blood Glucose (mg/dL) / 18.016] / Blood Ketones (mmol/L)\n\nIt compares circulating glucose fuel vs. ketone fuel to index total metabolic pressure.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'GKI Metabolic Zone Standards',
          content:
              '• GKI < 1.0: Highest Therapeutic Autophagy. Cellular cleanup and stem cell recycling are peaked.\n• GKI 1.0 – 3.0: High Ketosis & Fat Oxidation. Significant autophagy and brain BDNF enhancement.\n• GKI 3.0 – 6.0: Moderate Ketosis. Active fat oxidation and glycogen sparing.\n• GKI 6.0 – 9.0: Low Ketosis.\n• GKI > 9.0: Baseline / Fed state.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Why Keto-Mojo is the Gold Standard',
          content:
              'Capillary blood measurement with Keto-Mojo GK+ directly tests circulating beta-hydroxybutyrate (BHB) with ±10% laboratory accuracy, ensuring reliable GKI scores compared to volatile breath acetone or urinary strips.',
        ),
      ],
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAmber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageStep({
    required String range,
    required String phase,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              range,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  phase,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    color: const Color(0xFFCBD5E1),
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
