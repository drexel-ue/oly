import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/bodybuilding_model.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/oly_entry_reveal.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:oly/widgets/workout_weight_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BodybuildingRoutineScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<BodybuildingRoutineScreen> createState() =>
      _BodybuildingRoutineScreenState();
}

class _BodybuildingRoutineScreenState extends State<BodybuildingRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWeekday = DateTime.now().weekday;
  BodypartCategory? _selectedCategoryFilter;

  static const Color hypertrophyViolet = Color(0xFFA855F7);
  static const Color hypertrophyVioletGlow = Color(0xFF7C3AED);

  final List<String> _dayNames = const <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showMilestoneUpdateSheet(
    BuildContext context,
    GoalMilestone milestone,
    GoalProvider goalProvider,
  ) {
    final TextEditingController textController =
        TextEditingController(text: milestone.currentValue.toStringAsFixed(0));
    double sliderValue =
        milestone.currentValue.clamp(0.0, milestone.targetValue * 1.5);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hypertrophyViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hypertrophyViolet.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          'Goal: ${milestone.targetValue.toInt()} ${milestone.unit}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hypertrophyViolet,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (milestone.description != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      milestone.description!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppTheme.secondaryCyan,
                        iconSize: 32,
                        onPressed: () {
                          if (sliderValue > 0) {
                            setModalState(() {
                              sliderValue = (sliderValue - 2.5)
                                  .clamp(0.0, milestone.targetValue * 1.5);
                              textController.text =
                                  sliderValue.toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 110,
                        alignment: Alignment.center,
                        child: TextField(
                          controller: textController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            suffixText: milestone.unit,
                            suffixStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            final double? parsed = double.tryParse(val);
                            if (parsed != null) {
                              setModalState(() {
                                sliderValue = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: hypertrophyViolet,
                        iconSize: 32,
                        onPressed: () {
                          setModalState(() {
                            sliderValue = (sliderValue + 2.5)
                                .clamp(0.0, milestone.targetValue * 1.5);
                            textController.text =
                                sliderValue.toStringAsFixed(0);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: sliderValue.clamp(0.0, milestone.targetValue),
                    max: milestone.targetValue,
                    activeColor: hypertrophyViolet,
                    inactiveColor: AppTheme.surfaceElevated,
                    onChanged: (val) {
                      setModalState(() {
                        sliderValue = val;
                        textController.text = val.toStringAsFixed(0);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hypertrophyViolet,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final double? parsed =
                          double.tryParse(textController.text);
                      final double finalVal = parsed ?? sliderValue;
                      goalProvider.updateBodybuildingMilestone(
                          milestone.id, finalVal);
                      Navigator.pop(sheetCtx);
                    },
                    child: Text(
                      'Save Progress',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoalProvider goalProvider = Provider.of<GoalProvider>(context);
    final GoalTrack? bbGoal = goalProvider.getGoal('goal_bodybuilding');
    final List<GoalMilestone> milestones =
        bbGoal?.milestones ?? <GoalMilestone>[];

    final double overallProgress = bbGoal?.overallMilestoneProgress ?? 0.0;
    final int completedCount = milestones.where((m) => m.isCompleted).length;

    String levelTier = 'Level 1: Novice Builder';
    Color levelColor = AppTheme.secondaryCyan;

    if (overallProgress >= 0.85) {
      levelTier = 'Level 4: Titan Elite';
      levelColor = hypertrophyViolet;
    } else if (overallProgress >= 0.55) {
      levelTier = 'Level 3: Hypertrophy Master';
      levelColor = AppTheme.accentEmerald;
    } else if (overallProgress >= 0.30) {
      levelTier = 'Level 2: Intermediate Sculptor';
      levelColor = AppTheme.primaryAmber;
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        elevation: 0,
        title: Text(
          'Bodybuilding (19 Exercises)',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.ondemand_video, color: hypertrophyViolet),
            tooltip: 'Watch Trainer Winny Inspo Video',
            onPressed: () =>
                _launchUrl('https://www.youtube.com/watch?v=eYdaAb77oSI'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: hypertrophyViolet,
          indicatorWeight: 3,
          labelColor: hypertrophyViolet,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          tabs: const <Widget>[
            Tab(text: '19 Exercises Guide'),
            Tab(text: 'Hypertrophy Standards'),
            Tab(text: 'Weekly Curriculum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildExercisesGuideTab(context),
          _buildStandardsTab(
            context,
            milestones,
            overallProgress,
            completedCount,
            levelTier,
            levelColor,
            goalProvider,
          ),
          _buildCurriculumTab(context),
        ],
      ),
    );
  }

  // --- TAB 1: 19 EXERCISES GUIDE ---
  Widget _buildExercisesGuideTab(BuildContext context) {
    final List<BodybuildingExercise> allExercises =
        BodybuildingExercise.get19Exercises();
    final List<BodybuildingExercise> filteredExercises =
        _selectedCategoryFilter == null
            ? allExercises
            : allExercises
                .where((e) => e.bodypart == _selectedCategoryFilter)
                .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Hero Card: Trainer Winny Inspo Video
        OlyEntryReveal(
          delay: Duration.zero,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            ambientGlowColor: hypertrophyViolet,
            ambientGlowRadius: 1.2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hypertrophyViolet.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hypertrophyViolet.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: hypertrophyViolet,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      hypertrophyViolet.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'INSPIRATION VIDEO',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: hypertrophyViolet,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Trainer Winny',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '9 Bodyparts, 19 Exercises, Maximum Gains',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bodybuilding Simplified: No overcomplicated fluff. Every major muscle group systematically trained with foundational mechanical precision.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () =>
                      _launchUrl('https://www.youtube.com/watch?v=eYdaAb77oSI'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(
                    'Watch Video on YouTube (eYdaAb77oSI)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hypertrophyViolet,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bodypart Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _buildFilterChip('All (19)', null),
              ...BodypartCategory.values.map((cat) {
                final int count =
                    allExercises.where((e) => e.bodypart == cat).length;
                return _buildFilterChip(
                  '${cat.displayName} ($count)',
                  cat,
                  color: cat.color,
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Exercises List
        ...filteredExercises.asMap().entries.map((entry) {
          final int index = entry.key;
          final BodybuildingExercise ex = entry.value;

          return OlyEntryReveal(
            delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ex.bodypart.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ex.bodypart.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    ex.bodypart.icon,
                    color: ex.bodypart.color,
                    size: 22,
                  ),
                ),
                title: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        ex.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (ex.isBonus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BONUS',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ex.bodypart.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ex.role,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ex.bodypart.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ex.setsReps,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Divider(color: AppTheme.borderColor),
                        const SizedBox(height: 6),
                        Text(
                          'Target Anatomy:',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          ex.targetMuscles,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: ex.bodypart.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Why Trainer Winny Recommends This:',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          ex.whyItWorks,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Execution & Form Cues:',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...ex.cues.map((cue) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                      color: ex.bodypart.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      cue,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _launchUrl(
                            'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${ex.name} Trainer Winny form')}',
                          ),
                          icon: const Icon(Icons.search, size: 16),
                          label: Text(
                            'Search Tutorial Video',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ex.bodypart.color,
                            side: BorderSide(
                                color:
                                    ex.bodypart.color.withValues(alpha: 0.5)),
                            minimumSize: const Size(double.infinity, 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }),
      ],
    );
  }

  Widget _buildFilterChip(String label, BodypartCategory? cat, {Color? color}) {
    final bool isSelected = _selectedCategoryFilter == cat;
    final Color activeColor = color ?? hypertrophyViolet;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategoryFilter = cat;
          });
        },
        selectedColor: activeColor.withValues(alpha: 0.25),
        backgroundColor: AppTheme.surfaceCard,
        checkmarkColor: activeColor,
        side: BorderSide(
          color: isSelected ? activeColor : AppTheme.borderColor,
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? activeColor : AppTheme.textSecondary,
        ),
      ),
    );
  }

  // --- TAB 2: STANDARDS & MILESTONES ---
  Widget _buildStandardsTab(
    BuildContext context,
    List<GoalMilestone> milestones,
    double overallProgress,
    int completedCount,
    String levelTier,
    Color levelColor,
    GoalProvider goalProvider,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Overall Tier Card
        OlyEntryReveal(
          delay: Duration.zero,
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            ambientGlowColor: levelColor,
            ambientGlowRadius: 1.2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'PHYSIQUE PROGRESSION TIER',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: levelColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: levelColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${(overallProgress * 100).toInt()}% Done',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  levelTier,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount of ${milestones.length} Hypertrophy Benchmarks Achieved',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'HYPERTROPHY BENCHMARKS (8-12RM)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              'Tap to log weight',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: hypertrophyViolet,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (milestones.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No milestones found for Bodybuilding Track.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...milestones.asMap().entries.map((entry) {
            final int index = entry.key;
            final GoalMilestone m = entry.value;

            return OlyEntryReveal(
              delay: Duration(milliseconds: (index * 25).clamp(0, 300)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: OlyPressable(
                  onPressed: () =>
                      _showMilestoneUpdateSheet(context, m, goalProvider),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: m.isCompleted
                            ? hypertrophyViolet.withValues(alpha: 0.6)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: m.isCompleted
                                    ? hypertrophyViolet.withValues(alpha: 0.2)
                                    : AppTheme.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                m.isCompleted
                                    ? Icons.check
                                    : Icons.fitness_center,
                                size: 16,
                                color: m.isCompleted
                                    ? hypertrophyViolet
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    m.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: m.isCompleted
                                          ? hypertrophyViolet
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (m.description != null)
                                    Text(
                                      m.description!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  '${m.currentValue.toInt()} / ${m.targetValue.toInt()} ${m.unit}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: m.isCompleted
                                        ? hypertrophyViolet
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${m.progressPercent}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: m.progressRatio,
                            minHeight: 5,
                            backgroundColor: AppTheme.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              m.isCompleted
                                  ? hypertrophyViolet
                                  : hypertrophyVioletGlow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 3: WEEKLY CURRICULUM ---
  Widget _buildCurriculumTab(BuildContext context) {
    final List<DayTemplate> bbDays = ProgramCycle.getBodybuildingProgram();
    final DayTemplate currentDay = bbDays.firstWhere(
      (d) => d.dayNumber == _selectedWeekday,
      orElse: () => bbDays.first,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Weekday Selector Pills
        Row(
          children: List.generate(7, (index) {
            final int dNum = index + 1;
            final bool isSelected = _selectedWeekday == dNum;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                child: OlyPressable(
                  onPressed: () {
                    setState(() {
                      _selectedWeekday = dNum;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? hypertrophyViolet
                          : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected ? Colors.white : AppTheme.borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[index],
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Selected Day Header Card
        GlassContainer(
          padding: const EdgeInsets.all(18),
          ambientGlowColor: currentDay.isActiveRecovery
              ? AppTheme.secondaryCyan
              : hypertrophyViolet,
          ambientGlowRadius: 1.2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'DAY ${currentDay.dayNumber} OF 7',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: currentDay.isActiveRecovery
                          ? AppTheme.secondaryCyan
                          : hypertrophyViolet,
                    ),
                  ),
                  if (currentDay.isActiveRecovery)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active Restoration',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                currentDay.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentDay.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  // Switch active track to bodybuilding & selected day in provider
                  final ProgramProvider program =
                      Provider.of<ProgramProvider>(context, listen: false);
                  program.setTrainingTrack(TrainingTrack.bodybuilding);
                  program.selectDay(currentDay.dayNumber);

                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => WorkoutSessionScreen(
                        dayTemplate: currentDay,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.play_arrow,
                  size: 18,
                ),
                label: Text(
                  'Start Live Workout Session',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentDay.isActiveRecovery
                      ? AppTheme.secondaryCyan
                      : hypertrophyViolet,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Phases & Exercises (Matching Active Day Session Card Style)
        ...currentDay.phases.map((phase) {
          final Color phaseAccent = currentDay.isActiveRecovery
              ? AppTheme.secondaryCyan
              : hypertrophyViolet;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: phaseAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phase.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: phaseAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                ...phase.exercises.map((ex) {
                  final bool isTimed = WorkoutWeightHelper.isTimedExercise(
                    ex.name,
                    ex.setScheme,
                  );

                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: phaseAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTimed
                                ? Icons.timer_outlined
                                : Icons.fitness_center,
                            size: 16,
                            color: phaseAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                ex.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ex.setScheme,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: phaseAccent,
                                ),
                              ),
                              if (ex.notes != null && ex.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    ex.notes!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (ex.fixedWeightKg != null && ex.fixedWeightKg! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              '${ex.fixedWeightKg!.toStringAsFixed(0)} kg',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
