import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/c25k_model.dart';
import 'package:oly/providers/c25k_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/c25k/c25k_active_run_screen.dart';
import 'package:oly/widgets/motion/oly_entry_reveal.dart';
import 'package:oly/widgets/motion/oly_pressable.dart';
import 'package:provider/provider.dart';

class C25kProgramDetailScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<C25kProgramDetailScreen> createState() =>
      _C25kProgramDetailScreenState();
}

class _C25kProgramDetailScreenState extends State<C25kProgramDetailScreen> {
  int _selectedWeek = 1;

  @override
  void initState() {
    super.initState();
    final C25kProvider c25k =
        Provider.of<C25kProvider>(context, listen: false);
    _selectedWeek = c25k.currentWeek;
  }

  @override
  Widget build(BuildContext context) {
    final C25kProvider c25k = Provider.of<C25kProvider>(context);
    final int completedCount = c25k.totalCompletedSessions;
    final double overallProgress = (completedCount / 27.0).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Couch to 5K Program',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Overall 9-Week Progression Card
              OlyEntryReveal(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '9-WEEK JOURNEY TO 5K',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                          Text(
                            '$completedCount / 27 SESSIONS',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 10,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.secondaryCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Current Stage: Week ${c25k.currentWeek} • Day ${c25k.currentDay}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Week Selector Horizontal Pills
              OlyEntryReveal(
                index: 1,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List<Widget>.generate(9, (idx) {
                      final int week = idx + 1;
                      final bool isSelected = week == _selectedWeek;
                      final bool isCurrent = week == c25k.currentWeek;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Week $week'),
                          selected: isSelected,
                          selectedColor: AppTheme.secondaryCyan,
                          avatar: isCurrent
                              ? const Icon(Icons.bolt,
                                  size: 16, color: Colors.black)
                              : null,
                          labelStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.black
                                : (isCurrent
                                    ? AppTheme.secondaryCyan
                                    : AppTheme.textSecondary),
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedWeek = week);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3 Workouts for Selected Week
              OlyEntryReveal(
                index: 2,
                child: Text(
                  'WEEK $_selectedWeek SESSIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...List<Widget>.generate(3, (dayIdx) {
                final int day = dayIdx + 1;
                final C25kWorkout workout =
                    C25kCurriculum.getWorkout(_selectedWeek, day);
                final bool isCurrent = _selectedWeek == c25k.currentWeek &&
                    day == c25k.currentDay;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkoutCard(workout, isCurrent),
                );
              }),
              const SizedBox(height: 20),

              // Run History
              if (c25k.sessionLogs.isNotEmpty) ...<Widget>[
                Text(
                  'COMPLETED RUN LOGS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ...c25k.sessionLogs.take(5).map((log) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Week ${log.week} • Day ${log.day}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${DateFormat('MMM d, yyyy').format(log.date)} • ${log.estimatedDistanceKm.toStringAsFixed(2)} km',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              log.formattedDuration,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.secondaryCyan,
                              ),
                            ),
                            Text(
                              '${log.netCaloriesBurned.toStringAsFixed(0)} kcal',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(C25kWorkout workout, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppTheme.secondaryCyan
              : Colors.white.withValues(alpha: 0.08),
          width: isCurrent ? 1.5 : 1.0,
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
                  Text(
                    'Day ${workout.day}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (isCurrent) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'UP NEXT',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryCyan,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                workout.formattedTotalDuration,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            workout.description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          OlyPressable(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => C25kActiveRunScreen(
                    week: workout.week,
                    day: workout.day,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.secondaryCyan.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.secondaryCyan
                      : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  isCurrent ? 'START RUN SESSION' : 'PREVIEW OR RUN',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isCurrent
                        ? AppTheme.secondaryCyan
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
