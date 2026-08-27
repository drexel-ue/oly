import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _pickAndImportFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      String content = '';

      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (content.trim().isEmpty) return;

      if (!context.mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final lifts = Provider.of<LiftProvider>(context, listen: false);
      final program = Provider.of<ProgramProvider>(context, listen: false);

      final trimmed = content.trim();
      final isJson = trimmed.startsWith('{') || trimmed.startsWith('[');
      bool success = false;

      if (isJson) {
        success = await settings.importDataJson(trimmed);
      } else {
        success = await settings.importDataCsv(trimmed);
      }

      if (success) {
        await lifts.reload();
        await program.reload();
        if (context.mounted) {
          Navigator.pop(context); // Close modal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isJson
                    ? '✅ App Backup restored from ${file.name}!'
                    : '✅ PR History imported from ${file.name}!',
              ),
              backgroundColor: AppTheme.primaryAmber,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Could not import ${file.name}. Invalid format.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ File import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Display Weight Unit', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          'Currently set to ${settings.isLbs ? "Imperial (LBS)" : "Metric (KG)"}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ChoiceChip(
                    label: Text(settings.isLbs ? 'LBS' : 'KG'),
                    selected: true,
                    selectedColor: AppTheme.primaryAmber,
                    onSelected: (_) => settings.toggleUnit(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 8),

              // Sound Alerts Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rest Timer Sound Alerts', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          'Plays system audio pulse when rest timer reaches 0s',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    activeColor: AppTheme.primaryAmber,
                    value: settings.soundAlertsEnabled,
                    onChanged: (_) => settings.toggleSoundAlerts(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 8),

              // Haptic Feedback Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Haptic Vibration Alerts', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          'Triggers device vibration when rest timer finishes',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    activeColor: AppTheme.primaryAmber,
                    value: settings.hapticsEnabled,
                    onChanged: (_) => settings.toggleHaptics(),
                  ),
                ],
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

              // Import File Button (Native FilePicker for JSON / CSV)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndImportFile(context),
                  icon: const Icon(Icons.folder_open, color: Colors.black),
                  label: Text('Import File (.json / .csv)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Fallback Paste Dialog Button
              Center(
                child: TextButton.icon(
                  onPressed: () => _showPasteImportDialog(context),
                  icon: const Icon(Icons.paste, size: 16, color: AppTheme.textSecondary),
                  label: Text('Paste Raw Text / JSON', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasteImportDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lifts = Provider.of<LiftProvider>(context, listen: false);
    final program = Provider.of<ProgramProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: Text('Paste JSON or CSV Data', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste JSON or CSV data below to restore PRs and workout logs.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _importController,
              maxLines: 5,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '{"lifts": [...]} or Snatch,Snatch,100,220...',
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
              final raw = _importController.text.trim();
              final isJson = raw.startsWith('{') || raw.startsWith('[');
              bool success = isJson
                  ? await settings.importDataJson(raw)
                  : await settings.importDataCsv(raw);

              if (success) {
                await lifts.reload();
                await program.reload();
                if (ctx.mounted && context.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Close settings sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Data Restored Successfully!'),
                      backgroundColor: AppTheme.primaryAmber,
                    ),
                  );
                }
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Invalid data format.'),
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
