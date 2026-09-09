import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/theme/app_theme.dart';

/// Modal bottom sheet that provides an in-depth explainer of gym setup, floor layout,
/// movement standards, target pacing, and scaling matrix for any WOD.
class WodSetupExplainerSheet extends StatefulWidget {
  const WodSetupExplainerSheet({
    required this.wod,
    super.key,
    this.onStartWod,
    this.onAddWod,
  });

  final WodDefinition wod;
  final VoidCallback? onStartWod;
  final VoidCallback? onAddWod;

  static Future<void> show(
    BuildContext context,
    WodDefinition wod, {
    VoidCallback? onStartWod,
    VoidCallback? onAddWod,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => WodSetupExplainerSheet(
        wod: wod,
        onStartWod: onStartWod,
        onAddWod: onAddWod,
      ),
    );
  }

  @override
  State<WodSetupExplainerSheet> createState() => _WodSetupExplainerSheetState();
}

class _WodSetupExplainerSheetState extends State<WodSetupExplainerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WodDefinition wod = widget.wod;
    final WodSetupExplainer explainer = wod.setupExplainer;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.primaryAmber.withValues(alpha: 0.3),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppTheme.primaryAmber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            wod.name,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              wod.format.displayName,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wod.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Movements Summary Pill Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.surfaceElevated,
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppTheme.primaryAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  wod.targetTimeOrCap,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
                const Spacer(),
                Text(
                  wod.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryAmber,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryAmber,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
            tabs: const <Widget>[
              Tab(text: 'Setup & Floor Plan'),
              Tab(text: 'Movement Standards'),
              Tab(text: 'Strategy & Pacing'),
              Tab(text: 'Scaling Matrix'),
            ],
          ),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildSetupTab(explainer, wod),
                _buildStandardsTab(explainer),
                _buildStrategyTab(explainer),
                _buildScalingTab(explainer),
              ],
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppTheme.darkBackground,
              border: Border(
                top: BorderSide(color: AppTheme.surfaceElevated),
              ),
            ),
            child: Row(
              children: <Widget>[
                if (widget.onAddWod != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      label: Text(
                        'ADD ${wod.name.toUpperCase()} TO WORKOUT',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAddWod!();
                      },
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: Icon(
                        wod.hasInteractiveTracker
                            ? Icons.play_arrow_rounded
                            : Icons.fitness_center_rounded,
                        size: 22,
                      ),
                      label: Text(
                        wod.hasInteractiveTracker
                            ? 'START ${wod.name.toUpperCase()} WORKOUT'
                            : 'SET UP & HIT ${wod.name.toUpperCase()}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onStartWod != null) {
                          widget.onStartWod!();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupTab(WodSetupExplainer explainer, WodDefinition wod) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Floor Plan Section
          _buildSectionHeader(
            title: 'Gym Floor Plan & Spacing',
            subtitle: 'Minimize transition seconds between stations',
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondaryCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: AppTheme.secondaryCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STATION SPACING ADVICE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryCyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  explainer.floorPlanAdvice,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Equipment Checklist
          _buildSectionHeader(
            title: 'Equipment Checklist',
            subtitle: 'Gather and prepare before starting the timer',
            icon: Icons.checklist_rounded,
          ),
          const SizedBox(height: 10),
          ...explainer.equipmentChecklist.map((String item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.surfaceElevated,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
  }

  Widget _buildStandardsTab(WodSetupExplainer explainer) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: explainer.movementStandards.length,
      itemBuilder: (BuildContext context, int index) {
        final WodMovementStandard standard = explainer.movementStandards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceElevated),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    standard.movementName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      standard.repsOrDistance,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (standard.rxLoad != null) ...<Widget>[
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: AppTheme.secondaryCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rx Load: ${standard.rxLoad}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryCyan,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              ...standard.standards.map((String cue) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(
                          Icons.arrow_right_rounded,
                          size: 18,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          cue,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color: AppTheme.textSecondary,
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
      },
    );
  }

  Widget _buildStrategyTab(WodSetupExplainer explainer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Target Benchmarks
          _buildSectionHeader(
            title: 'Target Benchmarks',
            subtitle: 'Expected finish times or rep outputs by level',
            icon: Icons.emoji_events_outlined,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceElevated),
            ),
            child: Column(
              children: explainer.targetTimes.entries.map((MapEntry<String, String> entry) {
                final bool isElite = entry.key == 'Elite';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.surfaceElevated),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isElite
                              ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isElite ? AppTheme.primaryAmber : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isElite ? AppTheme.primaryAmber : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Pacing Cues
          _buildSectionHeader(
            title: 'Tactical Pacing & Breakdown',
            subtitle: 'How to manage your heart rate and muscle fatigue',
            icon: Icons.speed_rounded,
          ),
          const SizedBox(height: 10),
          ...explainer.pacingStrategy.map((String tip) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
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
  }

  Widget _buildScalingTab(WodSetupExplainer explainer) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: explainer.scalingOptions.entries.map((MapEntry<String, String> entry) {
        final bool isRx = entry.key == 'Rx';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRx
                  ? AppTheme.primaryAmber.withValues(alpha: 0.4)
                  : AppTheme.surfaceElevated,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRx
                          ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isRx ? AppTheme.primaryAmber : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRx ? 'As Prescribed' : 'Modified',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppTheme.primaryAmber),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
