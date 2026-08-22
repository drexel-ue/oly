import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/lift_model.dart';
import '../providers/lift_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ratio_chart_widget.dart';

class LiftsScreen extends StatefulWidget {
  const LiftsScreen({super.key});

  @override
  State<LiftsScreen> createState() => _LiftsScreenState();
}

class _LiftsScreenState extends State<LiftsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  void _showUpdateMaxDialog(BuildContext context, LiftModel lift, SettingsProvider settings) {
    final provider = Provider.of<LiftProvider>(context, listen: false);
    final suggestion = provider.getSuggestion(lift.id);

    final controller = TextEditingController(
      text: settings.toDisplayWeight(lift.currentMax).toStringAsFixed(1),
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Update ${lift.name} 1RM',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'New 1RM (${settings.unitLabel.toUpperCase()})',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryAmber),
                ),
              ),
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  final displayVal = settings.toDisplayWeight(suggestion.suggestedMaxKg);
                  controller.text = displayVal.toStringAsFixed(1);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondaryCyan.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppTheme.secondaryCyan, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suggested: ${settings.formatWeight(suggestion.suggestedMaxKg)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryCyan,
                              ),
                            ),
                            Text(
                              '${suggestion.reason} • Tap to apply',
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
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null && parsed > 0) {
                final baseKg = settings.toBaseKg(parsed);
                Provider.of<LiftProvider>(context, listen: false).updateMax(
                  lift.id,
                  baseKg,
                  notes: notesController.text.isNotEmpty ? notesController.text : 'Manual update',
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save PR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lifts = Provider.of<LiftProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lift Catalog & Ratios', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAmber,
          labelColor: AppTheme.primaryAmber,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Maxes & Percentages'),
            Tab(text: 'Ratio Balance'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Maxes & Percentage Table
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lifts.lifts.length,
              itemBuilder: (context, index) {
                final lift = lifts.lifts[index];
                return _buildLiftCard(context, lift, lifts, settings);
              },
            ),

            // TAB 2: Ratio Analysis
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RatioChartWidget(ratios: lifts.getRatioAnalysis()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiftCard(
      BuildContext context, LiftModel lift, LiftProvider provider, SettingsProvider settings) {
    final percentages = provider.getPercentageMatrix(lift.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryAmber.withOpacity(0.15),
          child: Icon(
            lift.category == LiftCategory.snatch
                ? Icons.fitness_center
                : lift.category == LiftCategory.squat
                    ? Icons.directions_walk
                    : Icons.sports_gymnastics,
            color: AppTheme.primaryAmber,
            size: 20,
          ),
        ),
        title: Text(
          lift.name,
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Current 1RM: ${settings.formatWeight(lift.currentMax)}',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryAmber),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note, color: AppTheme.primaryAmber),
          onPressed: () => _showUpdateMaxDialog(context, lift, settings),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERCENTAGE MATRIX',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: percentages.entries.map((entry) {
                    final isHighlighted = entry.key == 70 || entry.key == 75 || entry.key == 80;
                    return Container(
                      width: 75,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppTheme.primaryAmber.withOpacity(0.15)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isHighlighted ? AppTheme.primaryAmber : AppTheme.borderColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${entry.key}%',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isHighlighted ? AppTheme.primaryAmber : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.formatWeight(entry.value, includeUnit: false),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
