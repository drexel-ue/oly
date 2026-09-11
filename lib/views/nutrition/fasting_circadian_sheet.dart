import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/fasting_session_model.dart';
import 'package:oly/providers/fasting_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class FastingCircadianSheet extends StatefulWidget {
  const FastingCircadianSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext _) => const FastingCircadianSheet(),
    );
  }

  @override
  State<FastingCircadianSheet> createState() => _FastingCircadianSheetState();
}

class _FastingCircadianSheetState extends State<FastingCircadianSheet> {
  static const List<int> _waterTargets = <int>[2500, 3000, 3500, 4000];

  @override
  Widget build(BuildContext context) {
    final FastingProvider fasting = Provider.of<FastingProvider>(context);
    final AthleteCircadianConfig config = fasting.circadianConfig;
    final int portionMl = (config.dailyWaterTargetMl / 6).round();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
              // Sheet Grab Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.primaryAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'CIRCADIAN & REMINDERS',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Paced hydration, coffee timing & sleep shield',
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
              const SizedBox(height: 20),

              // ----------------------------------------------------
              // 1. PACED HYDRATION SECTION
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: config.waterRemindersEnabled
                        ? Colors.cyanAccent.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: Colors.cyanAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Paced Hydration Reminders',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '6 daily alerts across waking hours',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: config.waterRemindersEnabled,
                          activeThumbColor: Colors.cyanAccent,
                          activeTrackColor:
                              Colors.cyanAccent.withValues(alpha: 0.4),
                          onChanged: (bool enabled) {
                            fasting.toggleWaterReminders(enabled);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Paces water consumption through waking hours so you hydrate cellular tissue and restore plasma volume before your 6:00 AM lift without waterlogging.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (config.waterRemindersEnabled) ...<Widget>[
                      const Divider(color: Colors.white12, height: 24),
                      Text(
                        'DAILY WATER TARGET',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _waterTargets.map((int target) {
                          final bool isSelected =
                              config.dailyWaterTargetMl == target;
                          return ChoiceChip(
                            label: Text('$target mL'),
                            selected: isSelected,
                            selectedColor:
                                Colors.cyanAccent.withValues(alpha: 0.25),
                            backgroundColor: const Color(0xFF22222E),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white70,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white12,
                            ),
                            onSelected: (bool selected) {
                              if (selected) {
                                fasting.updateCircadianConfig(
                                  config.copyWith(
                                      dailyWaterTargetMl: target),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Target volume per alert: ~$portionMl mL water',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hydration Schedule Timeline
                      Text(
                        'PACED NOTIFICATION SCHEDULE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleRow(
                        time: '5:00 AM',
                        title: 'Morning Primer (+$portionMl mL)',
                        desc: 'Salt + water restores plasma volume before lift',
                        icon: Icons.wb_twilight,
                        accentColor: Colors.cyanAccent,
                      ),
                      _buildScheduleRow(
                        time: '7:30 AM',
                        title: 'Post-Lift Rehydration (+$portionMl mL)',
                        desc: 'Replenishes muscles post-training',
                        icon: Icons.fitness_center,
                        accentColor: Colors.cyanAccent,
                      ),
                      _buildScheduleRow(
                        time: '10:00 AM',
                        title: 'Mid-Morning Pacer (+$portionMl mL)',
                        desc: 'Steady flow into the work morning',
                        icon: Icons.schedule,
                        accentColor: Colors.cyanAccent,
                      ),
                      _buildScheduleRow(
                        time: '12:30 PM',
                        title: 'Midday Cellular Check (+$portionMl mL)',
                        desc: 'Maintains electrolyte balance during fast',
                        icon: Icons.light_mode_outlined,
                        accentColor: Colors.cyanAccent,
                      ),
                      _buildScheduleRow(
                        time: '3:30 PM',
                        title: 'Afternoon Slump Shield (+$portionMl mL)',
                        desc: 'Salted water curbs hunger and boosts focus',
                        icon: Icons.bolt,
                        accentColor: Colors.cyanAccent,
                      ),
                      _buildScheduleRow(
                        time: '6:00 PM',
                        title: 'Final Evening Target (+$portionMl mL)',
                        desc: 'Concludes hydration to safeguard sleep HRV',
                        icon: Icons.bedtime_outlined,
                        accentColor: Colors.cyanAccent,
                        isLast: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 2. COFFEE & CAFFEINE SECTION
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: config.coffeeRemindersEnabled
                        ? const Color(0xFFFFB74D).withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.coffee,
                            color: Color(0xFFFFB74D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Fasting Coffee & Caffeine Alerts',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Fat mobilization & adenosine sleep shield',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: config.coffeeRemindersEnabled,
                          activeThumbColor: const Color(0xFFFFB74D),
                          activeTrackColor: const Color(0xFFFFB74D)
                              .withValues(alpha: 0.4),
                          onChanged: (bool enabled) {
                            fasting.toggleCoffeeReminders(enabled);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Timed caffeine alerts to mobilize free fatty acids before heavy Olympic lifts, blunt mid-morning ghrelin hunger waves, and enforce an early curfew for uninterrupted deep sleep.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (config.coffeeRemindersEnabled) ...<Widget>[
                      const Divider(color: Colors.white12, height: 24),
                      Text(
                        'STRATEGIC ALERTS TIMELINE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleRow(
                        time: '5:15 AM',
                        title: 'Pre-Workout Platform Primer',
                        desc:
                            'Black coffee + 600mg salt spikes free fatty acid mobilization 45m before 6:00 AM lift.',
                        icon: Icons.fitness_center,
                        accentColor: const Color(0xFFFFB74D),
                      ),
                      _buildScheduleRow(
                        time: '9:30 AM',
                        title: 'Fasting Bridge (Ghrelin Shield)',
                        desc:
                            'Black coffee or green tea stimulates peptide YY to blunt morning hunger waves.',
                        icon: Icons.shield_outlined,
                        accentColor: const Color(0xFFFFB74D),
                      ),
                      _buildScheduleRow(
                        time: '12:00 PM',
                        title: 'Caffeine Curfew (HRV Shield)',
                        desc:
                            'Last call for coffee! Clears adenosine before 8:45 PM bedtime for deep HRV and sleep.',
                        icon: Icons.do_not_disturb_on_outlined,
                        accentColor: Colors.redAccent,
                        isLast: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 3. CIRCADIAN CLOCK OVERVIEW
              // ----------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.access_time_filled,
                          color: AppTheme.primaryAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ATHLETE CIRCADIAN ANCHORS',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _buildAnchorTile('WAKE', config.formattedWakeTime,
                            Icons.wb_sunny_outlined),
                        _buildAnchorTile('TRAIN', config.formattedWorkoutTime,
                            Icons.fitness_center),
                        _buildAnchorTile('FAST START',
                            config.formattedFeedingCutoff, Icons.lock_clock),
                        _buildAnchorTile(
                            'BEDTIME', config.formattedBedTime, Icons.bedtime),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Close / Done Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleRow({
    required String time,
    required String title,
    required String desc,
    required IconData icon,
    required Color accentColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 10,
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

  Widget _buildAnchorTile(String label, String value, IconData icon) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 16, color: AppTheme.primaryAmber),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
