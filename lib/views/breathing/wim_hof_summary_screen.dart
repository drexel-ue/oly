import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class WimHofSummaryScreen extends StatefulWidget {
  const WimHofSummaryScreen({
    required this.rounds,
    required this.config,
    super.key,
  });

  final List<BreathingRoundLog> rounds;
  final WimHofConfig config;

  @override
  State<WimHofSummaryScreen> createState() => _WimHofSummaryScreenState();
}

class _WimHofSummaryScreenState extends State<WimHofSummaryScreen> {
  int _readinessRating = 4;
  final TextEditingController _notesController = TextEditingController();
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  IconData _ratingIcon(int rating) {
    switch (rating) {
      case 1:
        return Icons.bedtime_outlined;
      case 2:
        return Icons.sentiment_neutral_outlined;
      case 3:
        return Icons.self_improvement_outlined;
      case 4:
        return Icons.bolt;
      case 5:
        return Icons.rocket_launch;
      default:
        return Icons.self_improvement_outlined;
    }
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Sleepy / Drowsy';
      case 2:
        return 'Lightly Centered';
      case 3:
        return 'Deeply Relaxed';
      case 4:
        return 'Energized & Tingling';
      case 5:
        return 'Supercharged / Peak Flow';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final BreathingProvider breathingProvider =
        Provider.of<BreathingProvider>(context);

    final int maxHoldSeconds = widget.rounds.isEmpty
        ? 0
        : widget.rounds
            .map((BreathingRoundLog r) => r.retentionSeconds)
            .reduce((int a, int b) => a > b ? a : b);

    final int totalHoldSeconds = widget.rounds.fold(
      0,
      (int sum, BreathingRoundLog r) => sum + r.retentionSeconds,
    );

    final int avgHoldSeconds = widget.rounds.isEmpty
        ? 0
        : (totalHoldSeconds / widget.rounds.length).round();

    final bool isNewPR =
        maxHoldSeconds > 0 && maxHoldSeconds > breathingProvider.allTimeMaxHoldSeconds;

    final String formattedMax =
        '${(maxHoldSeconds ~/ 60).toString().padLeft(2, '0')}:${(maxHoldSeconds % 60).toString().padLeft(2, '0')}';
    final String formattedTotal =
        '${(totalHoldSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalHoldSeconds % 60).toString().padLeft(2, '0')}';
    final String formattedAvg =
        '${(avgHoldSeconds ~/ 60).toString().padLeft(2, '0')}:${(avgHoldSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Breathwork Complete',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Celebration Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isNewPR
                        ? <Color>[
                            const Color(0xFF003C4D),
                            AppTheme.surfaceCard,
                          ]
                        : <Color>[
                            AppTheme.surfaceElevated,
                            AppTheme.surfaceCard,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isNewPR
                        ? AppTheme.secondaryCyan
                        : AppTheme.borderColor,
                    width: isNewPR ? 2 : 1,
                  ),
                  boxShadow: <BoxShadow>[
                    if (isNewPR)
                      BoxShadow(
                        color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isNewPR
                            ? AppTheme.primaryAmber
                            : AppTheme.secondaryCyan,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNewPR ? Icons.emoji_events : Icons.air,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isNewPR
                          ? 'NEW RETENTION PR!'
                          : '${widget.rounds.length} Rounds Completed',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isNewPR
                            ? AppTheme.primaryAmber
                            : AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isNewPR
                          ? 'You crushed your personal best with a $formattedMax hold!'
                          : 'Excellent oxygenation and nervous system reset.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KPI Stats Row
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildMetricCard(
                      title: 'LONGEST HOLD',
                      value: formattedMax,
                      icon: Icons.timer,
                      accentColor: AppTheme.primaryAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'AVG HOLD',
                      value: formattedAvg,
                      icon: Icons.speed,
                      accentColor: AppTheme.secondaryCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'TOTAL HOLD',
                      value: formattedTotal,
                      icon: Icons.hourglass_bottom,
                      accentColor: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Round-by-Round Breakdown
              Text(
                'ROUND-BY-ROUND RETENTION DURATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              ...widget.rounds.map((BreathingRoundLog round) {
                final double ratio = maxHoldSeconds > 0
                    ? (round.retentionSeconds / maxHoldSeconds).clamp(0.0, 1.0)
                    : 0.0;
                final bool isMaxRound =
                    round.retentionSeconds == maxHoldSeconds &&
                        maxHoldSeconds > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMaxRound
                          ? AppTheme.primaryAmber.withValues(alpha: 0.5)
                          : AppTheme.borderColor,
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
                                'Round ${round.roundNumber}',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (isMaxRound) ...<Widget>[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAmber
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'BEST HOLD',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            round.formattedRetentionTime,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isMaxRound
                                  ? AppTheme.primaryAmber
                                  : AppTheme.secondaryCyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMaxRound
                                ? AppTheme.primaryAmber
                                : AppTheme.secondaryCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Subjective Feeling / Rating
              Text(
                'HOW DO YOU FEEL NOW?',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (int index) {
                  final int star = index + 1;
                  final bool isSelected = star == _readinessRating;
                  return GestureDetector(
                    onTap: () => setState(() => _readinessRating = star),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryCyan.withValues(alpha: 0.2)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondaryCyan
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            _ratingIcon(star),
                            size: 26,
                            color: isSelected
                                ? AppTheme.secondaryCyan
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '$star',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppTheme.secondaryCyan
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.star,
                                size: 11,
                                color: isSelected
                                    ? AppTheme.secondaryCyan
                                    : AppTheme.textSecondary.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(_readinessRating),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Notes text field
              TextField(
                controller: _notesController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Session Notes (Optional)',
                  labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                  hintText: 'e.g. Tingling in hands, calm heartbeat...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.secondaryCyan),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Save & Finish Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final BreathingSessionLog session = BreathingSessionLog(
                      id: _uuid.v4(),
                      date: DateTime.now(),
                      totalRounds: widget.rounds.length,
                      rounds: widget.rounds,
                      readinessRating: _readinessRating,
                      notes: _notesController.text.trim().isNotEmpty
                          ? _notesController.text.trim()
                          : null,
                    );

                    await breathingProvider.saveSession(session);

                    if (mounted) {
                      Navigator.pop(context); // Close summary
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isNewPR
                                ? '🏆 NEW PR! Wim Hof Session logged successfully!'
                                : '⚡ Wim Hof Breathwork logged successfully!',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.secondaryCyan,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: Text(
                    'LOG BREATHWORK SESSION',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Discard & Exit',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
