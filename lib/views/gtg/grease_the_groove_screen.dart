import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/gtg_model.dart';
import 'package:oly/providers/gtg_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/motion/glass_container.dart';
import 'package:oly/widgets/motion/kinetic_counter.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class GreaseTheGrooveScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<GreaseTheGrooveScreen> createState() => _GreaseTheGrooveScreenState();
}

class _GreaseTheGrooveScreenState extends State<GreaseTheGrooveScreen> {
  int _selectedPullUpReps = 4;
  int _selectedHangPreset = 30;
  bool _isCuesExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final GtgProvider gtg = Provider.of<GtgProvider>(context, listen: false);
      setState(() {
        _selectedPullUpReps = gtg.config.targetPullUpReps;
        _selectedHangPreset = gtg.config.targetHangSeconds;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final GtgProvider gtg = Provider.of<GtgProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Grease the Groove',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.primaryAmber, size: 22),
            onPressed: () => _showSettingsModal(context, gtg),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Hero Card: Protocol Overview & Micro-Cues
            _buildHeroCard(context, gtg),
            const SizedBox(height: 16),

            // 2. Dual Daily Progress Rings (Pull-Ups & Active Hangs)
            _buildDailyProgressSection(context, gtg),
            const SizedBox(height: 16),

            // 3. Action Hub: Live Active Scapular Hang Timer
            _buildLiveHangTimerCard(context, gtg),
            const SizedBox(height: 16),

            // 4. Action Hub: Submaximal Pull-Up Logger
            _buildPullUpLogCard(context, gtg),
            const SizedBox(height: 16),

            // 5. Interval Notification Reminders Manager
            _buildIntervalRemindersCard(context, gtg),
            const SizedBox(height: 16),

            // 6. Today's Completed Sets Log
            _buildTodaySetsLog(context, gtg),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 1. HERO PROTOCOL CARD ---

  Widget _buildHeroCard(BuildContext context, GtgProvider gtg) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.electric_bolt,
                  color: AppTheme.primaryAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Pavel Neural Potentiation',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Frequent submaximal volume • Zero fatigue',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (gtg.currentStreakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('🔥 ', style: TextStyle(fontSize: 12)),
                      Text(
                        '${gtg.currentStreakDays}d streak',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Grease the Groove builds supreme neuromuscular efficiency by practicing movement patterns far from failure. Accumulate pull-ups and active hangs throughout the day.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Biomechanical Standards Banner (Active Scapula + Micro-Bend)
          GestureDetector(
            onTap: () => setState(() => _isCuesExpanded = !_isCuesExpanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentElectricCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentElectricCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.shield_outlined,
                            color: AppTheme.accentElectricCyan,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active Scapula + Micro-Bend Form Cues',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentElectricCyan,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isCuesExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.accentElectricCyan,
                        size: 18,
                      ),
                    ],
                  ),
                  if (_isCuesExpanded) ...<Widget>[
                    const SizedBox(height: 10),
                    _buildCueBullet(
                      icon: '🛡️',
                      title: 'Micro-Bend Elbows (Tendon Armor)',
                      description:
                          'Maintain a subtle 5°-10° bend at the elbows. This isometrically loads the biceps brachii, brachialis, and tendon complexes instead of hanging dead on passive ligaments.',
                    ),
                    const SizedBox(height: 8),
                    _buildCueBullet(
                      icon: '🦾',
                      title: 'Active Scapular Depression',
                      description:
                          'Actively pull your shoulder blades down and back toward your rear pockets. Keep neck long and ears clear of shoulders to strengthen lower traps and serratus.',
                    ),
                    const SizedBox(height: 8),
                    _buildCueBullet(
                      icon: '⚡',
                      title: 'Submaximal Pull-Up Precision',
                      description:
                          'Stop 3-4 reps shy of failure (~40-50% of 1RM max). Every rep must be strict, smooth, and explosive with zero kipping or form breakdown.',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCueBullet({
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.35),
              children: <TextSpan>[
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. DUAL PROGRESS DASHBOARD ---

  Widget _buildDailyProgressSection(BuildContext context, GtgProvider gtg) {
    final GtgConfig config = gtg.config;

    return Row(
      children: <Widget>[
        // Pull-Up Progress Card
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.65),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'PULL-UPS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    Text(
                      '${(gtg.pullUpProgressRatio * 100).toInt()}%',
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    KineticCounter(
                      value: gtg.todayPullUpReps,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' / ${config.dailyPullUpGoal}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: gtg.pullUpProgressRatio,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${config.targetPullUpReps} reps / set (submax)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Active Hang Progress Card
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.65),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'ACTIVE HANG',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.accentElectricCyan,
                      ),
                    ),
                    Text(
                      '${(gtg.hangProgressRatio * 100).toInt()}%',
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    KineticCounter(
                      value: gtg.todayHangSeconds,
                      suffix: 's',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' / ${config.dailyHangSecondsGoal}s',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: gtg.hangProgressRatio,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.accentElectricCyan),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${config.targetHangSeconds}s micro-bend hang',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. LIVE ACTIVE HANG TIMER CARD ---

  Widget _buildLiveHangTimerCard(BuildContext context, GtgProvider gtg) {
    final bool isRunning = gtg.isHangTimerRunning;
    final int remaining = gtg.hangSecondsRemaining;
    final int target = gtg.hangTargetSeconds;
    final double progress = target > 0 ? (target - remaining) / target : 0.0;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.timer_outlined,
                    color: AppTheme.accentElectricCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Scapular Hang Timer',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentElectricCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Micro-Bend Flexion',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentElectricCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central Countdown Circular Ring
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: isRunning ? progress : 1.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isRunning ? AppTheme.accentElectricCyan : Colors.white24,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      isRunning ? '$remaining' : '$_selectedHangPreset',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: isRunning ? AppTheme.accentElectricCyan : Colors.white,
                      ),
                    ),
                    Text(
                      isRunning ? 'SECONDS' : 'TARGET SEC',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preset Chips (20s, 30s, 45s, 60s)
          if (!isRunning) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <int>[20, 30, 45, 60].map((sec) {
                final bool isSelected = _selectedHangPreset == sec;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${sec}s'),
                    selected: isSelected,
                    selectedColor: AppTheme.accentElectricCyan.withValues(alpha: 0.25),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.accentElectricCyan : Colors.white60,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accentElectricCyan
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedHangPreset = sec);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Start / Stop Timer Buttons
          Row(
            children: <Widget>[
              Expanded(
                child: OlyPressable(
                  onPressed: () {
                    if (isRunning) {
                      gtg.stopActiveHangTimer(logPartial: true);
                    } else {
                      gtg.startActiveHangTimer(seconds: _selectedHangPreset);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Colors.redAccent.withValues(alpha: 0.85)
                          : AppTheme.accentElectricCyan,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: (isRunning ? Colors.redAccent : AppTheme.accentElectricCyan)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          isRunning ? Icons.stop : Icons.play_arrow,
                          color: isRunning ? Colors.white : Colors.black,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRunning ? 'Stop & Log Hang' : 'Start Active Hang',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isRunning ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isRunning) ...<Widget>[
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () => gtg.resetActiveHangTimer(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. SUBMAX PULL-UP LOGGER CARD ---

  Widget _buildPullUpLogCard(BuildContext context, GtgProvider gtg) {
    final GtgConfig config = gtg.config;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.fitness_center,
                    color: AppTheme.primaryAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Submax Strict Pull-Up',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Max: ${config.pullUpMax} reps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper Rep Selector & Log Button
          Row(
            children: <Widget>[
              // Stepper Count Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white70, size: 20),
                      onPressed: () {
                        if (_selectedPullUpReps > 1) {
                          setState(() => _selectedPullUpReps--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$_selectedPullUpReps',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white70, size: 20),
                      onPressed: () {
                        setState(() => _selectedPullUpReps++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Log Button
              Expanded(
                child: OlyPressable(
                  onPressed: () {
                    gtg.logPullUpSet(reps: _selectedPullUpReps);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged $_selectedPullUpReps strict pull-ups!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.primaryAmber,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.check, color: Colors.black, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Log $_selectedPullUpReps Pull-Ups',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target is 40-50% of 1RM max (${config.calculatedSubmaxReps} reps). Keep sets crisp, fast, and strict.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. INTERVAL REMINDERS CARD ---

  Widget _buildIntervalRemindersCard(BuildContext context, GtgProvider gtg) {
    final GtgConfig config = gtg.config;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Paced Interval Reminders',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: config.remindersEnabled,
                activeTrackColor: AppTheme.primaryAmber,
                onChanged: (val) => gtg.toggleReminders(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Schedules automatic alerts throughout your workday with Oly’s custom pulse chime.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),

          // Interval Selector Chips
          Row(
            children: <int>[45, 60, 90, 120].map((minutes) {
              final bool isSelected = config.intervalMinutes == minutes;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Every ${minutes}m'),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryAmber.withValues(alpha: 0.25),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryAmber : Colors.white60,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryAmber
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  onSelected: (_) {
                    gtg.updateConfig(config.copyWith(intervalMinutes: minutes));
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Active window: ${config.startHour}:00 AM – ${config.endHour - 12}:00 PM',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. TODAY'S COMPLETED SETS LOG ---

  Widget _buildTodaySetsLog(BuildContext context, GtgProvider gtg) {
    final List<GtgSetLog> todaySets = gtg.todayLogs;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'TODAY’S SETS (${todaySets.length})',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              if (todaySets.isNotEmpty)
                Text(
                  '${gtg.todayPullUpReps} reps • ${gtg.todayHangSeconds}s hang',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: AppTheme.primaryAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (todaySets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No sets logged yet today.\nStart with a 30s active hang or a submax pull-up set!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todaySets.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 16),
              itemBuilder: (context, index) {
                final GtgSetLog set = todaySets[index];
                final bool isHang = set.type == GtgExerciseType.activeHang;
                final String timeStr =
                    '${set.timestamp.hour.toString().padLeft(2, '0')}:${set.timestamp.minute.toString().padLeft(2, '0')}';

                return Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isHang ? AppTheme.accentElectricCyan : AppTheme.primaryAmber)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHang ? Icons.timer_outlined : Icons.fitness_center,
                        color: isHang ? AppTheme.accentElectricCyan : AppTheme.primaryAmber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isHang
                                ? 'Active Scapular Hang (${set.durationSeconds}s)'
                                : 'Strict Pull-Ups (${set.reps} reps)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isHang
                                ? 'Micro-bend elbow tendon tension • Active scapula'
                                : 'Submaximal clean reps',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white24),
                      onPressed: () => gtg.deleteSet(set.id),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- SETTINGS / RECALIBRATION MODAL ---

  void _showSettingsModal(BuildContext context, GtgProvider gtg) {
    int tempMax = gtg.config.pullUpMax;
    int tempHangGoal = gtg.config.dailyHangSecondsGoal;
    int tempPullUpGoal = gtg.config.dailyPullUpGoal;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Grease the Groove Targets',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Max Pull-Up Slider
                  Text(
                    'Current 1-Set Max Pull-Ups: $tempMax reps',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                  Slider(
                    value: tempMax.toDouble(),
                    min: 1,
                    max: 35,
                    divisions: 34,
                    activeColor: AppTheme.primaryAmber,
                    inactiveColor: Colors.white10,
                    onChanged: (val) {
                      setModalState(() => tempMax = val.toInt());
                    },
                  ),
                  Text(
                    'Prescribed Submax Set: ${(tempMax * 0.45).clamp(1, 30).round()} reps',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryAmber),
                  ),
                  const SizedBox(height: 16),

                  // Daily Goal Presets
                  Text(
                    'Daily Pull-Up Goal: $tempPullUpGoal reps',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                  Slider(
                    value: tempPullUpGoal.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 18,
                    activeColor: AppTheme.primaryAmber,
                    inactiveColor: Colors.white10,
                    onChanged: (val) {
                      setModalState(() => tempPullUpGoal = val.toInt());
                    },
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Daily Active Hang Goal: ${tempHangGoal}s (${(tempHangGoal / 60).toStringAsFixed(1)} min)',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                  Slider(
                    value: tempHangGoal.toDouble(),
                    min: 60,
                    max: 600,
                    divisions: 18,
                    activeColor: AppTheme.accentElectricCyan,
                    inactiveColor: Colors.white10,
                    onChanged: (val) {
                      setModalState(() => tempHangGoal = val.toInt());
                    },
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      gtg.updateConfig(
                        gtg.config.copyWith(
                          pullUpMax: tempMax,
                          targetPullUpReps: (tempMax * 0.45).clamp(1, 30).round(),
                          dailyPullUpGoal: tempPullUpGoal,
                          dailyHangSecondsGoal: tempHangGoal,
                        ),
                      );
                      setState(() {
                        _selectedPullUpReps = (tempMax * 0.45).clamp(1, 30).round();
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Save Settings',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
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
}
