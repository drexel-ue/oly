import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/breathing_session_model.dart';
import 'package:oly/providers/breathing_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/breathing/wim_hof_session_screen.dart';
import 'package:provider/provider.dart';

class WimHofSetupSheet extends StatefulWidget {
  const WimHofSetupSheet({super.key});

  @override
  State<WimHofSetupSheet> createState() => _WimHofSetupSheetState();
}

class _WimHofSetupSheetState extends State<WimHofSetupSheet> {
  late int _rounds;
  late int _breathsPerRound;
  late BreathingPace _pace;
  late bool _soundEnabled;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    final BreathingProvider breathingProvider =
        Provider.of<BreathingProvider>(context, listen: false);
    final WimHofConfig config = breathingProvider.config;
    _rounds = config.defaultRounds;
    _breathsPerRound = config.breathsPerRound;
    _pace = config.pace;
    _soundEnabled = config.soundEnabled;
    _hapticsEnabled = config.hapticsEnabled;
  }

  void _startSession() {
    final BreathingProvider breathingProvider =
        Provider.of<BreathingProvider>(context, listen: false);

    final WimHofConfig newConfig = WimHofConfig(
      defaultRounds: _rounds,
      breathsPerRound: _breathsPerRound,
      pace: _pace,
      soundEnabled: _soundEnabled,
      hapticsEnabled: _hapticsEnabled,
    );
    breathingProvider.updateConfig(newConfig);

    Navigator.pop(context); // Close setup sheet
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WimHofSessionScreen(config: newConfig),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BreathingProvider breathingProvider =
        Provider.of<BreathingProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grab handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.air,
                    color: AppTheme.secondaryCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Wim Hof Breathwork',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Guided Hyperventilation & Retention Flow',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),

            if (breathingProvider.allTimeMaxHoldSeconds > 0) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppTheme.secondaryCyan.withValues(alpha: 0.12),
                      AppTheme.primaryAmber.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All-Time Retention PR: ${breathingProvider.formattedAllTimeMaxHold}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${breathingProvider.totalSessionsCompleted} Sessions Logged',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Number of Rounds Selector
            Text(
              'NUMBER OF ROUNDS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: _rounds > 1
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _rounds--);
                              }
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        color: AppTheme.primaryAmber,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$_rounds',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _rounds < 10
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _rounds++);
                              }
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        color: AppTheme.primaryAmber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <int>[1, 3, 4, 5].map((int r) {
                      final bool isSelected = _rounds == r;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rounds = r);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.secondaryCyan
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.secondaryCyan
                                    : AppTheme.borderColor,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$r ${r == 1 ? "Round" : "Rounds"}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Breaths Per Round Selector
            Text(
              'BREATHS PER ROUND',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <int>[20, 30, 40].map((int b) {
                final bool isSelected = _breathsPerRound == b;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _breathsPerRound = b);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryAmber
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryAmber
                              : AppTheme.borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          Text(
                            '$b Breaths',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.black
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            b == 30 ? 'Standard' : (b == 20 ? 'Light' : 'Deep'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.black87
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Pacing Selector
            Text(
              'BREATHING PACE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: BreathingPace.values.map((BreathingPace p) {
                final bool isSelected = _pace == p;
                String label;
                String speedDesc;
                switch (p) {
                  case BreathingPace.relaxed:
                    label = 'Relaxed';
                    speedDesc = '4.5s cycle';
                    break;
                  case BreathingPace.normal:
                    label = 'Normal';
                    speedDesc = '3.5s cycle';
                    break;
                  case BreathingPace.fast:
                    label = 'Fast';
                    speedDesc = '2.5s cycle';
                    break;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _pace = p);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryCyan
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondaryCyan
                              : AppTheme.borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.black
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            speedDesc,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.black87
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Sound & Haptics Toggles
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.volume_up_outlined,
                            size: 20,
                            color: AppTheme.secondaryCyan,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Audio Cues & Bell',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _soundEnabled,
                        activeColor: AppTheme.secondaryCyan,
                        onChanged: (bool val) =>
                            setState(() => _soundEnabled = val),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.vibration,
                            size: 20,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Haptic Breathing Pulses',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _hapticsEnabled,
                        activeColor: AppTheme.primaryAmber,
                        onChanged: (bool val) =>
                            setState(() => _hapticsEnabled = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Start Flow Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 26),
                label: Text(
                  'START GUIDED BREATHWORK',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
