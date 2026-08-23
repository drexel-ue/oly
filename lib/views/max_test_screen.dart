import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/plate_modal.dart';
import '../widgets/rest_timer_widget.dart';

class MaxTestScreen extends StatefulWidget {
  const MaxTestScreen({super.key});

  @override
  State<MaxTestScreen> createState() => _MaxTestScreenState();
}

class _MaxTestScreenState extends State<MaxTestScreen> {
  late String _selectedLiftId;
  final TextEditingController _targetPrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLiftId = 'snatch';
  }

  @override
  void dispose() {
    _targetPrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifts = Provider.of<LiftProvider>(context);
    final program = Provider.of<ProgramProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final selectedLift = lifts.getLift(_selectedLiftId) ?? lifts.lifts.first;
    final currentMaxKg = selectedLift.currentMax;
    final currentMaxDisplay = settings.toDisplayWeight(currentMaxKg);

    if (_targetPrController.text.isEmpty) {
      _targetPrController.text = (currentMaxDisplay * 1.025).round().toString();
    }

    final targetPrDisplay = double.tryParse(_targetPrController.text) ?? (currentMaxDisplay * 1.025);
    final targetPrKg = settings.toBaseKg(targetPrDisplay);

    return Scaffold(
      appBar: AppBar(
        title: Text('1RM Retest Assistant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E0000), Color(0xFF2A0000)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEEK 5: MAX TEST PROTOCOL',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            'Retest 1RM baselines to reset your training percentages for Cycle ${program.currentCycle + 1}.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Select Lift & Target PR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECT MOVEMENT', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedLiftId,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      underline: const SizedBox(),
                      items: lifts.lifts.map((l) {
                        return DropdownMenuItem<String>(
                          value: l.id,
                          child: Text(l.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLiftId = val;
                            _targetPrController.clear();
                          });
                        }
                      },
                    ),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current 1RM', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                              Text(settings.formatWeight(currentMaxKg), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target New PR', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryAmber)),
                              TextField(
                                controller: _targetPrController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                                decoration: InputDecoration(
                                  suffixText: settings.unitLabel.toUpperCase(),
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warmup Ramp-Up Table
              Text('ESTABLISHED RAMP-UP ATTEMPTS', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),

              _buildRampItem(context, 'Set 1 (Warmup)', '50%', targetPrKg * 0.50, '3 Reps', settings),
              _buildRampItem(context, 'Set 2 (Warmup)', '60%', targetPrKg * 0.60, '3 Reps', settings),
              _buildRampItem(context, 'Set 3 (Technique)', '70%', targetPrKg * 0.70, '2 Reps', settings),
              _buildRampItem(context, 'Set 4 (Speed)', '80%', targetPrKg * 0.80, '1 Rep', settings),
              _buildRampItem(context, 'Attempt 1 (Opener)', '88%', targetPrKg * 0.88, '1 Rep', settings),
              _buildRampItem(context, 'Attempt 2 (Match PR)', '95%', targetPrKg * 0.95, '1 Rep', settings),
              _buildRampItem(context, 'Attempt 3 (NEW PR!)', '100%+', targetPrKg, '1 Rep', settings, isPrAttempt: true),

              const SizedBox(height: 16),

              // Embedded Rest Timer for 3-5 min rest
              const RestTimerWidget(initialSeconds: 180),
              const SizedBox(height: 24),

              // Confirm & Save New PR Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await lifts.updateMax(selectedLift.id, targetPrKg, notes: 'Week 5 Max Retest PR!');
                    await program.startNewCycle();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('NEW PR RECORDED! ${settings.formatWeight(targetPrKg)} for ${selectedLift.name}! Cycle ${program.currentCycle} Initialized!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.stars, color: Colors.black),
                  label: Text(
                    'Record New PR & Start Cycle ${program.currentCycle + 1}',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRampItem(BuildContext context, String label, String pctLabel, double weightKg, String scheme, SettingsProvider settings, {bool isPrAttempt = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrAttempt ? AppTheme.primaryAmber.withValues(alpha: 0.15) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPrAttempt ? AppTheme.primaryAmber : AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPrAttempt ? AppTheme.primaryAmber : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pctLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPrAttempt ? Colors.black : AppTheme.primaryAmber,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(scheme, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                settings.formatWeight(weightKg),
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isPrAttempt ? AppTheme.primaryAmber : AppTheme.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.pie_chart_outline, size: 18, color: AppTheme.primaryAmber),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PlateModal(initialWeightKg: weightKg),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
