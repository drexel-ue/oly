import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MetabolicScienceExplainerScreen extends StatelessWidget {
  const MetabolicScienceExplainerScreen({super.key});

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
            'Metabolic Science & Calculations',
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
                    Icon(Icons.bolt, size: 16),
                    SizedBox(width: 6),
                    Text('Energy & TDEE'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.science_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Algorithm B (METs)'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.fitness_center, size: 16),
                    SizedBox(width: 6),
                    Text('WOD & Lifting Physics'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.water_drop_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Hydration Model'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.menu_book_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Open-Source Sources'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _EnergyAndTdeeTab(),
            _AlgorithmBTab(),
            _WodPhysicsTab(),
            _HydrationModelTab(),
            _OpenSourcesTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: Energy & TDEE
// ---------------------------------------------------------------------------
class _EnergyAndTdeeTab extends StatelessWidget {
  const _EnergyAndTdeeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeroHeader(
            icon: Icons.bolt,
            title: 'Total Daily Energy Expenditure (TDEE)',
            subtitle: 'How Oly models your metabolic engine from Renpho Scale biometrics.',
          ),
          const SizedBox(height: 20),
          _buildFormulaCard(
            title: '1. Katch-McArdle BMR Equation',
            formula: 'BMR = 370 + (21.6 × Lean Body Mass in kg)',
            description: 'Unlike standard Mifflin-St Jeor or Harris-Benedict formulas that treat all bodyweight equally, Katch-McArdle isolates Lean Body Mass (LBM). Adipose tissue burns minimal energy (~4.5 kcal/kg/day), while skeletal muscle and vital organs burn ~13-22 kcal/kg/day at rest.',
            badge: 'Renpho Biometric LBM',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '2. The 4 Components of Total Expenditure',
            formula: 'TDEE = BMR (60-70%) + NEAT (15-20%) + EAT (10-15%) + TEF (~10%)',
            description: '• BMR (Basal Rate): Energy required for cellular respiration and organ function.\n• NEAT (Non-Exercise Activity): Daily steps, walking, fidgeting, posture.\n• EAT (Exercise Activity): Planned Olympic lifting, cardio intervals, mobility flows.\n• TEF (Thermic Effect of Food): Metabolic cost of digesting protein (~25%), carbs (~7%), and fats (~3%).',
            badge: 'Full Physiological Model',
          ),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '3. Long-Term Adaptive Energy Equation',
            formula: 'Adaptive TDEE = Avg Daily Intake - [(ΔFat × 3,500 kcal + ΔLBM × 800 kcal) / Days]',
            description: 'Over multi-week Renpho scale scan intervals, Oly compares actual logged food intake against physical changes in fat and muscle tissue to detect metabolic adaptation (reverse dieting or diet fatigue).',
            badge: 'Adaptive Intelligence',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 2: Algorithm B (METs & LBM Scaling)
// ---------------------------------------------------------------------------
class _AlgorithmBTab extends StatelessWidget {
  const _AlgorithmBTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeroHeader(
            icon: Icons.biotech_outlined,
            title: 'Algorithm B: Personalized REE Scaling',
            subtitle: 'Why generic fitness trackers overestimate calories burned for strength athletes.',
          ),
          const SizedBox(height: 20),
          _buildComparisonCard(),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: 'Mathematical Formulation of Algorithm B',
            formula: 'Calories Burned = Activity MET × (BMR / 1440 min) × Duration in min',
            description: '1. Oly computes your personal Resting Energy Expenditure per minute (REE_min):\n   REE_min = (370 + 21.6 × LBM_kg) / 1,440\n   For 208.6 lb LBM (94.6 kg) -> 1.676 kcal/min.\n2. The Compendium MET score is multiplied directly against your true biological REE.',
            badge: 'NIH / ACSM Gold Standard',
          ),
          const SizedBox(height: 16),
          _buildMetReferenceTable(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 3: WOD & Lifting Physics
// ---------------------------------------------------------------------------
class _WodPhysicsTab extends StatelessWidget {
  const _WodPhysicsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeroHeader(
            icon: Icons.fitness_center,
            title: 'Workout of the Day (WOD) Caloric Physics',
            subtitle: 'Modeling energy expenditure across explosive lifts, heavy squats, and rest intervals.',
          ),
          const SizedBox(height: 20),
          _buildFormulaCard(
            title: '1. Two-Phase Exercise Time & Work Model',
            formula: 'Total Time = (Completed Reps × TUT_rep) + ((Sets - 1) × Rest_target)',
            description: 'Strength training is non-steady-state. In a Snatch set of 5x2 (10 reps total), only ~40 seconds is spent in maximal explosive contraction (11.0-14.0 MET), while ~10 minutes is spent in active EPOC and ATP-CP recovery (3.0-3.5 MET). The Compendium assigns a blended 6.5 MET across total elapsed time.',
            badge: '2-Phase Interval Physics',
          ),
          const SizedBox(height: 16),
          _buildMovementTiersCard(),
          const SizedBox(height: 16),
          _buildFormulaCard(
            title: '2. Mechanical Tonnage & Work against Gravity',
            formula: 'Volume Load = Σ (Sets × Reps × Weight Lifted in kg)',
            description: 'In addition to baseline MET duration, moving 15,000+ lb of barbell displacement requires mechanical work against gravitational acceleration (W = m × g × h). Human muscular efficiency is ~20-25%, meaning ~75-80% of energy is released as metabolic heat.',
            badge: 'Mechanical Work & EPOC',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 4: Hydration Model
// ---------------------------------------------------------------------------
class _HydrationModelTab extends StatelessWidget {
  const _HydrationModelTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeroHeader(
            icon: Icons.water_drop,
            title: 'Biometric Hydration Turnover Model',
            subtitle: 'ACSM & ISSN Lean Tissue Hydration Guidelines for Strength Athletes.',
          ),
          const SizedBox(height: 20),
          _buildFormulaCard(
            title: 'The Multi-Tier Hydration Algorithm',
            formula: 'Daily Water (oz) = (LBM_lb × 0.65) + (Fat_lb × 0.25) + Δ_Training (+24 oz) + Δ_Deficit (+12 oz)',
            description: '• Lean/Muscle tissue is ~75% water with high intracellular turnover: 0.65 oz / lb LBM.\n• Adipose/Fat tissue is ~10% water: 0.25 oz / lb Fat Mass.\n• Training Surcharge: +24 oz (standard shaker bottle) for intra/post-workout rehydration and glycogen storage (3-4g water per 1g glycogen stored).\n• Renpho Low-Hydration Booster: +12 oz if scale Body Water % is < 55%.',
            badge: 'ACSM / ISSN Model',
          ),
          const SizedBox(height: 16),
          _buildSampleCalculationCard(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 5: Open-Source Sources & Citations
// ---------------------------------------------------------------------------
class _OpenSourcesTab extends StatelessWidget {
  const _OpenSourcesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeroHeader(
            icon: Icons.menu_book_outlined,
            title: 'Open-Source Databases & Scientific Literature',
            subtitle: 'Transparent, reproducible scientific resources powering Oly calculations.',
          ),
          const SizedBox(height: 20),
          _buildResourceTile(
            title: 'Compendium of Physical Activities',
            source: 'Ainsworth BE et al. (NIH / pacompendium.com)',
            description: 'The global gold standard coding system for physical activity METs used by exercise physiologists worldwide.',
            url: 'https://pacompendium.com',
          ),
          const SizedBox(height: 12),
          _buildResourceTile(
            title: 'Open Food Facts API',
            source: 'World Open Food Facts Consortium',
            description: 'Open-source database of over 3 million packaged products with barcode lookup (UPC/EAN) and complete nutritional breakdowns.',
            url: 'https://world.openfoodfacts.org',
          ),
          const SizedBox(height: 12),
          _buildResourceTile(
            title: 'USDA FoodData Central',
            source: 'U.S. Department of Agriculture (data.gov)',
            description: 'Foundational and SR Legacy datasets providing rigorous macronutrient and micronutrient profiles for raw ingredients.',
            url: 'https://fdc.nal.usda.gov',
          ),
          const SizedBox(height: 12),
          _buildResourceTile(
            title: 'Katch-McArdle Energy Expenditure Model',
            source:
                'Exercise Physiology: Nutrition, Energy, and Human Performance',
            description: 'Peer-reviewed formula establishing that basal energy expenditure is determined by fat-free mass rather than total mass.',
            url: 'https://en.wikipedia.org/wiki/Basal_metabolic_rate#BMR_estimation_formulas',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER WIDGETS
// ---------------------------------------------------------------------------

Widget _buildHeroHeader({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryAmber, size: 28),
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
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFormulaCard({
  required String title,
  required String formula,
  required String description,
  required String badge,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            formula,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryCyan,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

Widget _buildComparisonCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Generic Apps (Algorithm A) vs. Oly (Algorithm B)',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Example: 45-minute Brisk Walk (3.8 MET) for a 264.8 lb (208.6 lb LBM) athlete:',
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Algorithm A (Generic)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '360 kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+25% Overestimate (Assumes fat burns same energy as muscle)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
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
                  color: AppTheme.successGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Algorithm B (Oly LBM)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '287 kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Physiologically accurate to your actual Lean Body Mass',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMetReferenceTable() {
  const List<(String, String, String, String)> activities =
      <(String, String, String, String)>[
        ('Walking 3.5 mph (Brisk)', '17151', '3.8 MET', '8.0 kcal/min'),
        ('Rucking (25 lb pack)', '17165', '6.0 MET', '12.6 kcal/min'),
        ('Assault Bike (Moderate)', '02010', '7.0 MET', '14.7 kcal/min'),
        ('Assault Bike (Sprint HIIT)', '02015', '11.5 MET', '24.1 kcal/min'),
        ('Concept2 Rowing (150W)', '02070', '7.0 MET', '14.7 kcal/min'),
        ('Olympic Lifting (Session)', '02050', '6.5 MET', '13.6 kcal/min'),
        ('Mobility & Stretching Flow', '02100', '2.8 MET', '5.9 kcal/min'),
      ];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Compendium MET Reference Catalog (208.6 lb LBM)',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...activities.map(
          ((String, String, String, String) a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    a.$1,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  a.$3,
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: AppTheme.primaryAmber,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  a.$4,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMovementTiersCard() {
  const List<(String, String, String, String)> tiers =
      <(String, String, String, String)>[
        (
          'Explosive Olympic Lifts',
          'Snatch, Clean & Jerk, Power Snatch, Jerk',
          '6.5 MET',
          '0.45 - 0.55 kcal/rep',
        ),
        (
          'Heavy Compound Squats & Pulls',
          'Back Squat, Front Squat, Clean Pull, Deadlift',
          '6.0 MET',
          '0.40 - 0.50 kcal/rep',
        ),
        (
          'Overhead Presses & Bench',
          'Push Press, Strict Press, Snatch Push Press',
          '5.0 MET',
          '0.25 - 0.35 kcal/rep',
        ),
        (
          'Accessory Hypertrophy & Core',
          'Split Squats, Hyperextensions, Arms, Abs',
          '4.5 MET',
          '0.15 - 0.25 kcal/rep',
        ),
      ];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Movement Metabolic Intensity Tiers',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...tiers.map(
          ((String, String, String, String) t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        t.$1,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.$3,
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.$2,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSampleCalculationCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Sample Target for 208.6 lb LBM / 56.2 lb Fat:',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '• Rest Day Baseline: (208.6 × 0.65) + (56.2 × 0.25) = 150.0 oz (~4.4 L)',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          '• Training Day Goal: 150.0 + 24.0 oz = 174.0 oz (~5.1 L)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryCyan,
          ),
        ),
      ],
    ),
  );
}

Widget _buildResourceTile({
  required String title,
  required String source,
  required String description,
  required String url,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.open_in_new,
                size: 16,
                color: AppTheme.primaryAmber,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          source,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryCyan,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
