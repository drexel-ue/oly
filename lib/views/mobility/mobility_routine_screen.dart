import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/goal_model.dart';
import 'package:oly/models/program_model.dart';
import 'package:oly/providers/goal_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/workout_session_screen.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/oly_entry_reveal.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MobilityRoutineScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<MobilityRoutineScreen> createState() => _MobilityRoutineScreenState();
}

class _MobilityRoutineScreenState extends State<MobilityRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWeekday = DateTime.now().weekday;

  final List<String> _dayNames = <String>[
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
    _tabController = TabController(length: 2, vsync: this);
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
    double sliderValue = milestone.currentValue.clamp(0.0, milestone.targetValue);

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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentEmerald.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          'Goal: ${milestone.targetValue.toInt()} ${milestone.unit}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentEmerald,
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
                              sliderValue = (sliderValue - (milestone.unit == 's' ? 5 : 2.5))
                                  .clamp(0.0, milestone.targetValue * 1.5);
                              textController.text = sliderValue.toStringAsFixed(0);
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        color: AppTheme.accentEmerald,
                        iconSize: 32,
                        onPressed: () {
                          setModalState(() {
                            sliderValue = (sliderValue + (milestone.unit == 's' ? 5 : 2.5))
                                .clamp(0.0, milestone.targetValue * 1.5);
                            textController.text = sliderValue.toStringAsFixed(0);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: sliderValue.clamp(0.0, milestone.targetValue),
                    max: milestone.targetValue,
                    activeColor: AppTheme.accentEmerald,
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
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final double? parsed = double.tryParse(textController.text);
                      final double finalVal = parsed ?? sliderValue;
                      goalProvider.updateMobilityMilestone(milestone.id, finalVal);
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
    final GoalTrack? mobilityGoal = goalProvider.getGoal('goal_mobility_hypertrophy');
    final List<GoalMilestone> milestones =
        mobilityGoal?.milestones ?? <GoalMilestone>[];

    final double overallProgress = mobilityGoal?.overallMilestoneProgress ?? 0.0;
    final int completedCount = milestones.where((m) => m.isCompleted).length;

    String levelTier = 'Level 1: Foundation';
    Color levelColor = AppTheme.secondaryCyan;
    if (overallProgress >= 0.75) {
      levelTier = 'Level 3: Elite Oly Ready';
      levelColor = AppTheme.accentEmerald;
    } else if (overallProgress >= 0.35) {
      levelTier = 'Level 2: Athlete';
      levelColor = AppTheme.primaryAmber;
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Mobility & Hypertrophy',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.video_library_outlined),
            tooltip: 'Inspiration Tutorials',
            onPressed: () => _showInspoVideosSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentEmerald,
          labelColor: AppTheme.accentEmerald,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const <Widget>[
            Tab(text: 'Standards & Milestones'),
            Tab(text: 'Weekly Curriculum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          // TAB 1: STANDARDS & MILESTONES
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // HERO LEVEL CARD
                OlyEntryReveal(
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(18),
                    border: Border.all(color: levelColor.withValues(alpha: 0.4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: levelColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                levelTier,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: levelColor,
                                ),
                              ),
                            ),
                            Text(
                              '${(overallProgress * 100).toInt()}% Met',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            minHeight: 10,
                            backgroundColor: AppTheme.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$completedCount of ${milestones.length} benchmarks mastered. Tap any standard to update your current numbers.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'STANDARDS BENCHMARKS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // MILESTONE CARDS
                ...milestones.map((milestone) {
                  final bool isDone = milestone.isCompleted;
                  final double ratio = milestone.progressRatio;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OlyPressable(
                      onPressed: () => _showMilestoneUpdateSheet(
                          context, milestone, goalProvider),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDone
                                ? AppTheme.accentEmerald.withValues(alpha: 0.6)
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    value: ratio,
                                    strokeWidth: 4,
                                    backgroundColor: AppTheme.surfaceElevated,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDone
                                          ? AppTheme.accentEmerald
                                          : AppTheme.secondaryCyan,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isDone
                                      ? Icons.check
                                      : Icons.accessibility_new,
                                  size: 20,
                                  color: isDone
                                      ? AppTheme.accentEmerald
                                      : AppTheme.secondaryCyan,
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    milestone.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (milestone.description != null)
                                    Text(
                                      milestone.description!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  '${milestone.currentValue.toInt()} / ${milestone.targetValue.toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDone
                                        ? AppTheme.accentEmerald
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  milestone.unit,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // TAB 2: WEEKLY CURRICULUM
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // WEEKDAY CHIPS
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, idx) {
                      final int weekdayNum = idx + 1;
                      final bool isSelected = _selectedWeekday == weekdayNum;
                      final bool isToday = DateTime.now().weekday == weekdayNum;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${_dayNames[idx]}${isToday ? ' •' : ''}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.accentEmerald,
                          backgroundColor: AppTheme.surfaceCard,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedWeekday = weekdayNum;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // DAY DETAILS CARD
                _buildCurriculumDayCard(_selectedWeekday),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumDayCard(int weekday) {
    String dayTitle = '';
    String focusArea = '';
    List<Map<String, String>> exercises = <Map<String, String>>[];

    switch (weekday) {
      case DateTime.monday:
        dayTitle = 'Lower Hypertrophy + ATG Knee/Ankle Mobility';
        focusArea = 'Quad mass, deep knee flexion, ankle dorsiflexion, hip flexor opening';
        exercises = <Map<String, String>>[
          {
            'name': 'Slant Board Calf Stretch',
            'setsReps': '3 sets x 60s per leg (straight & bent knee)',
            'cues': 'Drive knee forward over toes without heel lifting; expand dorsiflexion.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Tibialis Anterior Raises',
            'setsReps': '3 sets x 25 reps (wall or tib bar)',
            'cues': 'Full dorsiflexion squeeze; strengthens decelerators to protect knees.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Banded Hip Internal Rotation',
            'setsReps': '2 sets x 12 reps per leg (2s peak hold)',
            'cues': 'Anchor band laterally to ankle, flare foot outward against resistance; active capsule clearance for deep squats.',
            'video': 'https://www.youtube.com/results?search_query=Banded+Hip+Internal+Rotation',
          },
          {
            'name': 'Pause Back Squats (Dane Miller)',
            'setsReps': '4 sets x 6 reps (3-second pause in hole)',
            'cues': 'Sit deep between hips, knees out, tall chest, isometric hole stability.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': 'ATG Split Squats (Ben Patrick)',
            'setsReps': '4 sets x 8 reps per leg (towards 50% BW standard)',
            'cues': 'Front hamstring covers calf completely; back leg locked straight with glute flexed.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Wall Couch Stretch',
            'setsReps': '2 sets x 90s per side',
            'cues': 'Shin flush to wall; squeeze glute to drive hip forward with upright spine.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
        ];

      case DateTime.tuesday:
        dayTitle = 'C25K Run + Upper Hypertrophy & Thoracic Mobility';
        focusArea = 'Aerobic endurance, overhead lockout strength, triceps & lat hypertrophy';
        exercises = <Map<String, String>>[
          {
            'name': 'Couch to 5K Interval Session',
            'setsReps': 'Scheduled C25K Running Interval (20-30 mins)',
            'cues': 'Steady aerobic base; nasal breathing where possible.',
            'video': '',
          },
          {
            'name': 'Miracle Grow (Pullover into Tricep Ext)',
            'setsReps': '4 sets x 10-12 reps (Dane Miller)',
            'cues': 'Full lat stretch behind head, drop into 90° elbow flexion, fire triceps.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': 'Incline Trap-3 Raise',
            'setsReps': '3 sets x 10 reps (2-second top hold)',
            'cues': 'Thumb pointing up at 45°; strict lower trapezius contraction.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Seated DB External Rotation',
            'setsReps': '3 sets x 8 reps per side (3s eccentric)',
            'cues': 'Elbow on knee; isolate infraspinatus and rotator cuff with strict tempo.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Dumbbell Hammer Curls',
            'setsReps': '3-4 sets x 10-12 reps (neutral grip)',
            'cues': 'Palms facing each other; targets brachialis & brachioradialis while offloading medial epicondyle.',
            'video': 'https://www.youtube.com/results?search_query=Dumbbell+Hammer+Curls',
          },
          {
            'name': 'Dumbbell Wrist Curls (Flexion & Extension)',
            'setsReps': '3 sets x 15-20 reps (slow eccentric)',
            'cues': 'Forearms flat on bench; full wrist extension into flexion squeeze; flip over for reverse extensor curls.',
            'video': 'https://www.youtube.com/results?search_query=Dumbbell+Wrist+Curls',
          },
          {
            'name': "Pull-Up Isometric Hold (Golfer's Elbow Rehab)",
            'setsReps': '3-4 sets x 20-30s hold (at 90° elbow flexion)',
            'cues': 'Hold 90° elbow bend with neutral or chin-up grip; active scapular depression; isometric tendon loading relieves medial epicondyle pain.',
            'video': 'https://www.youtube.com/results?search_query=Pull+Up+Isometric+Hold',
          },
        ];

      case DateTime.wednesday:
        dayTitle = 'Restorative Posterior Chain & Hip Capsule Flow';
        focusArea = 'Hamstring elasticity, adductor opening, spinal segmentation, unilateral grip';
        exercises = <Map<String, String>>[
          {
            'name': 'ATG Elephant Walk',
            'setsReps': '2 sets x 45 alternating reps',
            'cues': 'Hands flat to floor; pump knees alternately into full extension.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Jefferson Curls',
            'setsReps': '4 sets x 8 reps (elevated box, light load)',
            'cues': 'Chin to chest, roll down bone-by-bone below toes, reverse smoothly.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Seated Good Mornings',
            'setsReps': '4 sets x 10 reps (straddle stance on bench)',
            'cues': 'Flat back, push chest and belly between knees to touch bench.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': '90/90 Hip Switches & Rotations (Separate)',
            'setsReps': '4 sets x 5 switches per side (5s end-range hold)',
            'cues': 'Dedicated capsule work; open back knee first, maintain tall posture.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': '90/90 Rear-Leg Hip IR PAILs/RAILs',
            'setsReps': '3 sets x 60s hold per side',
            'cues': 'Rotate torso toward rear knee; 60s passive hold + 10s PAILs push + 5s active lift-off.',
            'video': 'https://www.youtube.com/results?search_query=90+90+Hip+Internal+Rotation+PAILs+RAILs',
          },
          {
            'name': 'Seated Butterfly Stretch & PNF Hold (Separate)',
            'setsReps': '3 sets x 60s active adductor contraction & fold',
            'cues': 'Soles together, drive knees toward floor, hinge forward with flat back.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Grip Hang Protocol: Single-Arm Hangs',
            'setsReps': '3 sets per side (working toward 2:00 goal)',
            'cues': 'Active scapular stabilization with core braced.',
            'video': '',
          },
        ];

      case DateTime.thursday:
        dayTitle = 'C25K Run + Lower Body Depth Hypertrophy';
        focusArea = 'Single-leg balance, adductor hypertrophy, running mechanics';
        exercises = <Map<String, String>>[
          {
            'name': 'C25K Interval Run',
            'setsReps': 'Scheduled C25K Interval Session',
            'cues': 'Paced cadence and relaxed shoulders.',
            'video': '',
          },
          {
            'name': 'Curtsy Lunges (Dane Miller)',
            'setsReps': '3 sets x 10 reps per leg',
            'cues': 'Cross trailing foot behind; strengthens glute medius and hip stabilizers.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': 'Banded Hip Internal Rotation',
            'setsReps': '3 sets x 12 reps per leg (2s peak hold)',
            'cues': 'Flare ankle outward into deep IR against band tension; clears capsule before vertical squats.',
            'video': 'https://www.youtube.com/results?search_query=Banded+Hip+Internal+Rotation',
          },
          {
            'name': 'Front Squats or Goblet Squats (Heel Elevated)',
            'setsReps': '4 sets x 8-10 reps (2s bottom pause)',
            'cues': 'Torso completely vertical, quads under continuous tension.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': 'Wall Couch Stretch',
            'setsReps': '2 sets x 120s per side',
            'cues': 'Long restorative hold; push pelvis forward with glute activation.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
        ];

      case DateTime.friday:
        dayTitle = 'Upper Hypertrophy + Scapular Armor & Shoulders';
        focusArea = 'Upper back thickness, rotator cuff resilience, overhead jerk/snatch support';
        exercises = <Map<String, String>>[
          {
            'name': 'Overhead Press / Z-Press',
            'setsReps': '4 sets x 8 reps',
            'cues': 'Barbell or dumbbell overhead press from seated floor position.',
            'video': '',
          },
          {
            'name': 'Powell Raises (Ben Patrick 4-Step)',
            'setsReps': '3 sets x 10 reps per side',
            'cues': 'Side-lying straight arm raise; targets rear delt and mid-trap.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Dumbbell Pullovers',
            'setsReps': '3 sets x 12 reps',
            'cues': 'Deep stretch in lats with ribcage expansion, keeping lower back neutral.',
            'video': 'https://www.youtube.com/watch?v=omuAtS7zOa0',
          },
          {
            'name': 'Two-Hand Dual Hang (Grip Goal)',
            'setsReps': '1 max-effort attempt (towards 5:00 goal)',
            'cues': 'Lock in grip with thumb wrapped; breathe calmly.',
            'video': '',
          },
          {
            'name': 'Dumbbell Hammer Curls',
            'setsReps': '3 sets x 10-12 reps',
            'cues': 'Strict neutral grip; reinforces brachialis and lateral forearm stability.',
            'video': 'https://www.youtube.com/results?search_query=Dumbbell+Hammer+Curls',
          },
          {
            'name': 'Dumbbell Wrist Curls (Flexion & Extension)',
            'setsReps': '3 sets x 15-20 reps',
            'cues': 'Rest forearms on knees/bench; slow 3-second eccentric lower.',
            'video': 'https://www.youtube.com/results?search_query=Dumbbell+Wrist+Curls',
          },
          {
            'name': "Pull-Up Isometric Hold (Golfer's Elbow Iso)",
            'setsReps': '3 sets x 25-30s hold',
            'cues': 'Static tension at 90° elbow flexion without swinging or jerky transitions.',
            'video': 'https://www.youtube.com/results?search_query=Pull+Up+Isometric+Hold',
          },
        ];

      case DateTime.saturday:
        dayTitle = 'C25K Long Base Run + Loaded Oly Mobility Flow';
        focusArea = 'Aerobic endurance, technique retention with zero joint strain, loaded athletic mobility';
        exercises = <Map<String, String>>[
          {
            'name': 'C25K Long Base Run',
            'setsReps': 'Week milestone run',
            'cues': 'Aerobic endurance and pacing.',
            'video': '',
          },
          {
            'name': 'Close-Grip Snatch Balance / Overhead Squat',
            'setsReps': '4 sets x 5 reps (empty bar / light)',
            'cues': 'Narrower grip; forces extreme thoracic extension and shoulder mobility.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': 'Loaded Cossack Squats',
            'setsReps': '3 sets x 8 reps per side',
            'cues': 'Kettlebell held in goblet position; sink into deep adductor stretch.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
          {
            'name': 'Deep Squat Pry with Kettlebell',
            'setsReps': '3 sets x 45s hold in bottom hole',
            'cues': 'Use elbows to pry knees outward while keeping chest tall.',
            'video': 'https://www.youtube.com/watch?v=EJD6Xr5UIOs',
          },
        ];

      case DateTime.sunday:
        dayTitle = 'Complete Rest & Restorative Decompression';
        focusArea = 'Systemic recovery, passive spinal decompression, mental reset';
        exercises = <Map<String, String>>[
          {
            'name': 'Passive Bar Hang Decompression',
            'setsReps': '3 sets x 30-45s',
            'cues': 'Pure passive traction; relax shoulders completely up to ears.',
            'video': '',
          },
          {
            'name': 'Diaphragmatic Breathing / Wim Hof',
            'setsReps': '3-4 rounds (optional)',
            'cues': 'Deep circular oxygenation and calm retention.',
            'video': '',
          },
        ];

      default:
        dayTitle = 'Rest & Recovery';
        focusArea = 'Gentle stretching and hydration';
        exercises = <Map<String, String>>[];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.accentEmerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dayTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      focusArea,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentEmerald,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final List<DayTemplate> mobilityDays =
                    ProgramCycle.getMobilityProgram();
                final DayTemplate day = mobilityDays.firstWhere(
                  (d) => d.dayNumber == weekday,
                  orElse: () => mobilityDays.first,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutSessionScreen(dayTemplate: day),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'Start Live Workout Session',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),

          Text(
            'EXERCISE PROTOCOLS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          ...exercises.map((ex) {
            final String videoUrl = ex['video'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          ex['name']!,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (videoUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: AppTheme.accentEmerald,
                            size: 22,
                          ),
                          tooltip: 'Watch Tutorial',
                          onPressed: () => _launchUrl(videoUrl),
                        ),
                    ],
                  ),
                  Text(
                    ex['setsReps']!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryCyan,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ex['cues']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showInspoVideosSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Inspiration & Form Tutorials',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Official tutorials from Coach Dane Miller & Ben Patrick that anchor this routine.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.red),
                ),
                title: Text(
                  'Garage Strength',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '7 Mobility Strength Exercises EVERY Athlete Should Do',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, color: AppTheme.textSecondary, size: 18),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _launchUrl('https://www.youtube.com/watch?v=EJD6Xr5UIOs');
                },
              ),
              const Divider(color: AppTheme.borderColor),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.red),
                ),
                title: Text(
                  'The Kneesovertoesguy',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '7-Step ATG Mobility Routine (+ 4-Step Shoulder Routine)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, color: AppTheme.textSecondary, size: 18),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _launchUrl('https://www.youtube.com/watch?v=omuAtS7zOa0');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
