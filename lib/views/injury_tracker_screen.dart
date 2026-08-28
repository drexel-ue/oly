import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/injury_log_bottom_sheet.dart';
import 'package:oly/widgets/interactive_body_map.dart';
import 'package:provider/provider.dart';

class InjuryTrackerScreen extends StatefulWidget {
  const InjuryTrackerScreen({super.key});

  @override
  State<InjuryTrackerScreen> createState() => _InjuryTrackerScreenState();
}

class _InjuryTrackerScreenState extends State<InjuryTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InjuryRegion? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onRegionTapped(InjuryRegion region) {
    setState(() => _selectedRegion = region);

    final InjuryProvider provider = Provider.of<InjuryProvider>(
      context,
      listen: false,
    );
    final InjuryRecord? existing = provider.getActiveInjuryForRegion(region);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext _) => InjuryLogBottomSheet(
        initialRegion: region,
        existingInjury: existing,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Text(
            'Injury Classification Guide',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildGuideRow(
                badge: 'ACUTE (< 14d)',
                color: AppTheme.primaryAmber,
                desc: 'Recent tissue strain. Eliminate ballistic catch shock and peak eccentric loads.',
              ),
              const SizedBox(height: 12),
              _buildGuideRow(
                badge: 'SUBACUTE (14-42d)',
                color: const Color(0xFFFF9F0A),
                desc: 'Tissue healing phase. Progressive isometric loading, tempo eccentrics.',
              ),
              const SizedBox(height: 12),
              _buildGuideRow(
                badge: 'CHRONIC (42d+)',
                color: const Color(0xFFBF5AF2),
                desc: 'Persistent condition (6+ weeks). Movement pattern modification and capacity building.',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Got It',
                style: TextStyle(color: AppTheme.primaryAmber),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuideRow({
    required String badge,
    required Color color,
    required String desc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            badge,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final InjuryProvider injuryProvider = Provider.of<InjuryProvider>(context);
    final List<InjuryRecord> activeList = injuryProvider.activeInjuries;
    final List<InjuryRecord> resolvedList = injuryProvider.resolvedInjuries;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.accessibility_new,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Body Map & Injuries',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Injury Stage Guide',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Metric Summary Cards
              _buildMetricHeader(injuryProvider),
              const SizedBox(height: 16),

              // Interactive Visual Body Map
              Text(
                'ANATOMICAL HEATMAP (TAP TO LOG / INSPECT)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InteractiveBodyMap(
                injuries: activeList,
                selectedRegion: _selectedRegion,
                onRegionSelected: _onRegionTapped,
              ),
              const SizedBox(height: 20),

              // Tabs: Active Strains / Rehab Recommendations / History
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  labelColor: AppTheme.primaryAmber,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: <Widget>[
                    Tab(text: 'Active (${activeList.length})'),
                    const Tab(text: 'Targeted Rehab'),
                    Tab(text: 'History (${resolvedList.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab View Content
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildActiveInjuriesTab(activeList, injuryProvider),
                    _buildRehabTab(activeList),
                    _buildHistoryTab(resolvedList),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _onRegionTapped(InjuryRegion.leftKnee);
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'Log Strain',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricHeader(InjuryProvider provider) {
    final int activeCount = provider.totalActiveCount;
    final int acuteCount = provider.acuteInjuries.length;
    final int chronicCount = provider.chronicInjuries.length;
    final double avgPain = provider.averagePainScore;

    return Row(
      children: <Widget>[
        Expanded(
          child: _buildMetricTile(
            label: 'Active Strains',
            value: activeCount.toString(),
            color: activeCount > 0 ? AppTheme.primaryAmber : AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Acute (<14d)',
            value: acuteCount.toString(),
            color: AppTheme.primaryAmber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Chronic (6w+)',
            value: chronicCount.toString(),
            color: const Color(0xFFBF5AF2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Avg Pain',
            value: avgPain > 0 ? avgPain.toStringAsFixed(1) : '0.0',
            color: avgPain > 4 ? Colors.redAccent : AppTheme.secondaryCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInjuriesTab(
    List<InjuryRecord> injuries,
    InjuryProvider provider,
  ) {
    if (injuries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.successGreen,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'All Joints & Tissues Healthy!',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap any region on the body map to log a strain.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: injuries.length,
      itemBuilder: (BuildContext context, int index) {
        final InjuryRecord injury = injuries[index];
        final Color stageColor = injury.stage == InjuryStage.acute
            ? AppTheme.primaryAmber
            : (injury.stage == InjuryStage.subacute
                ? const Color(0xFFFF9F0A)
                : const Color(0xFFBF5AF2));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: stageColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: stageColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${injury.stage.label} • ${injury.formattedDuration}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: stageColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          injury.region.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.secondaryCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: injury.painScale <= 3
                            ? AppTheme.primaryAmber
                            : (injury.painScale <= 6
                                ? const Color(0xFFFF9F0A)
                                : Colors.redAccent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pain: ${injury.painScale}/10',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  injury.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (injury.notes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    injury.notes,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16, color: AppTheme.successGreen),
                      label: const Text('Healed', style: TextStyle(color: AppTheme.successGreen)),
                      onPressed: () => provider.resolveInjury(injury.id),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 14, color: Colors.black),
                      label: const Text('Update', style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _onRegionTapped(injury.region),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRehabTab(List<InjuryRecord> activeInjuries) {
    final List<MobilityExerciseModel> allDrills = MobilityExerciseModel.defaultExercises();
    final Set<MobilityFocusArea> activeFocus = <MobilityFocusArea>{};

    for (final InjuryRecord injury in activeInjuries) {
      activeFocus.addAll(injury.rehabFocusAreas);
    }

    final List<MobilityExerciseModel> targetDrills = allDrills
        .where((MobilityExerciseModel d) => activeFocus.contains(d.focusArea))
        .toList();

    if (targetDrills.isEmpty) {
      return Center(
        child: Text(
          'No specific prehab drills needed currently.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: targetDrills.length,
      itemBuilder: (BuildContext context, int index) {
        final MobilityExerciseModel drill = targetDrills[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.spa, color: AppTheme.secondaryCyan),
            ),
            title: Text(
              drill.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              drill.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(List<InjuryRecord> resolved) {
    if (resolved.isEmpty) {
      return Center(
        child: Text(
          'No resolved injury history recorded yet.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: resolved.length,
      itemBuilder: (BuildContext context, int index) {
        final InjuryRecord record = resolved[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.history, color: AppTheme.successGreen),
            title: Text(
              record.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${record.region.displayName} • Duration: ${record.formattedDuration}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        );
      },
    );
  }
}
