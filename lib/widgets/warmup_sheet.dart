import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WarmupSheet extends StatefulWidget {
  const WarmupSheet({super.key});

  @override
  State<WarmupSheet> createState() => _WarmupSheetState();
}

class _WarmupSheetState extends State<WarmupSheet> {
  // General Warm Up Timer
  Timer? _timer;
  int _secondsRemaining = 180; // Default 3 min row/bike
  bool _isTimerRunning = false;

  // Foam rolling pass counter
  int _foamPasses = 0;

  // DROM Checkboxes
  final Map<String, bool> _droms = {
    'Wrists (10-15 reps)': false,
    'Elbows (10-15 reps)': false,
    'Shoulders (10-15 reps)': false,
    'Twists (10-15 reps)': false,
    'Hips (10-15 reps)': false,
    'Knees (10-15 reps)': false,
  };

  // Static Stretches
  bool _stretchShoulders = false;
  bool _stretchAnkles = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          setState(() => _isTimerRunning = false);
        }
      });
    }
  }

  void _resetTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _isTimerRunning = false;
    });
  }

  String get _formattedTime {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Guided Olympic Warm-Up',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step 1: General Warm Up
            _buildSectionHeader('1. General Warm Up (Cardio)', Icons.directions_bike),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Row / Bike (Row Preferred)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formattedTime,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAmber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _resetTimer(180),
                        child: const Text('3 Min'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _resetTimer(300),
                        child: const Text('5 Min'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Foam Rolling
            _buildSectionHeader('2. Foam Rolling', Icons.fitness_center),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thoracic Spine Focus',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '8-10 passes per muscle group',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryAmber),
                        onPressed: _foamPasses > 0 ? () => setState(() => _foamPasses--) : null,
                      ),
                      Text(
                        '$_foamPasses / 10',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryAmber),
                        onPressed: () => setState(() => _foamPasses++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 3: DROMs
            _buildSectionHeader('3. Dynamic Mobility (DROMs)', Icons.accessibility_new),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: _droms.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key, style: GoogleFonts.inter(fontSize: 14)),
                    value: _droms[key],
                    activeColor: AppTheme.primaryAmber,
                    checkColor: Colors.black,
                    onChanged: (val) => setState(() => _droms[key] = val ?? false),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Step 4: Static Stretching
            _buildSectionHeader('4. Static Stretching', Icons.self_improvement),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: Text('Shoulders (30s hold per side)', style: GoogleFonts.inter(fontSize: 14)),
                    value: _stretchShoulders,
                    activeColor: AppTheme.primaryAmber,
                    checkColor: Colors.black,
                    onChanged: (val) => setState(() => _stretchShoulders = val ?? false),
                  ),
                  CheckboxListTile(
                    title: Text('Ankles (Dorsiflexion 30s per leg)', style: GoogleFonts.inter(fontSize: 14)),
                    value: _stretchAnkles,
                    activeColor: AppTheme.primaryAmber,
                    checkColor: Colors.black,
                    onChanged: (val) => setState(() => _stretchAnkles = val ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 5: Barbell Warmup
            _buildSectionHeader('5. Barbell Warm-Up', Icons.sports_gymnastics),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryAmber.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empty Barbell Specific Prep:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                  ),
                  const SizedBox(height: 8),
                  Text('• 5 Tall Muscle Snatches / Cleans', style: GoogleFonts.inter(fontSize: 13)),
                  Text('• 5 Overhead Squats / Front Squats', style: GoogleFonts.inter(fontSize: 13)),
                  Text('• 5 Press in Snatch / Push Press', style: GoogleFonts.inter(fontSize: 13)),
                  Text('• 3 Warmup Sets with progressive weight loading', style: GoogleFonts.inter(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Complete Warm-Up & Start Workout',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryAmber, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
