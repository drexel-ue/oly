import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/lift_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final TextEditingController _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'App Preferences & Data',
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

              // Unit Preference
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Display Weight Unit', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('Currently set to ${settings.isLbs ? "Imperial (LBS)" : "Metric (KG)"}'),
                trailing: ChoiceChip(
                  label: Text(settings.isLbs ? 'LBS' : 'KG'),
                  selected: true,
                  selectedColor: AppTheme.primaryAmber,
                  onSelected: (_) => settings.toggleUnit(),
                ),
              ),
              const Divider(color: AppTheme.borderColor),

              // Sound Alerts Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryAmber,
                title: Text('Rest Timer Sound Alerts', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: const Text('Plays system audio pulse when rest timer reaches 0s'),
                value: settings.soundAlertsEnabled,
                onChanged: (_) => settings.toggleSoundAlerts(),
              ),

              // Haptic Feedback Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryAmber,
                title: Text('Haptic Vibration Alerts', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: const Text('Triggers device vibration when rest timer finishes'),
                value: settings.hapticsEnabled,
                onChanged: (_) => settings.toggleHaptics(),
              ),

              const SizedBox(height: 16),
              Text(
                'DATA BACKUP & EXPORT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Export JSON Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final jsonStr = settings.exportFullDataJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Full App Data Backup copied to Clipboard (JSON)!'),
                        backgroundColor: AppTheme.primaryAmber,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, color: AppTheme.primaryAmber),
                  label: Text('Export App Backup (JSON)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Export CSV Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final csvStr = settings.exportPrsCsv();
                    Clipboard.setData(ClipboardData(text: csvStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📊 PR History CSV copied to Clipboard!'),
                        backgroundColor: AppTheme.primaryAmber,
                      ),
                    );
                  },
                  icon: const Icon(Icons.table_chart, color: AppTheme.secondaryCyan),
                  label: Text('Export PR History (CSV)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Import JSON Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showImportDialog(context),
                  icon: const Icon(Icons.upload, color: Colors.black),
                  label: Text('Import Data Backup (JSON)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lifts = Provider.of<LiftProvider>(context, listen: false);
    final program = Provider.of<ProgramProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: Text('Import JSON Backup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste JSON data below to restore PRs, workout logs, and settings.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _importController,
              maxLines: 5,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '{"lifts": [...], "workoutSessions": [...]}',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final success = await settings.importDataJson(_importController.text.trim());
              if (success) {
                await lifts.reload();
                await program.reload();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Close settings sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ App Data Restored Successfully!'),
                      backgroundColor: AppTheme.primaryAmber,
                    ),
                  );
                }
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Invalid JSON backup format.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
  }
}
