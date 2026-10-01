import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/program_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/services/notification_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/views/diagnostics/crash_report_screen.dart';
import 'package:provider/provider.dart';

class SettingsModal extends StatefulWidget {
  const new({super.key});

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
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json', 'csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.single;
      String content = '';

      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (content.trim().isEmpty) {
        return;
      }

      if (!context.mounted) {
        return;
      }
      final SettingsProvider settings = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final LiftProvider lifts = Provider.of<LiftProvider>(
        context,
        listen: false,
      );
      final ProgramProvider program = Provider.of<ProgramProvider>(
        context,
        listen: false,
      );

      final String trimmed = content.trim();
      final bool isJson = trimmed.startsWith('{') || trimmed.startsWith('[');
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
              content: Text(
                '⚠️ Could not import ${file.name}. Invalid format.',
              ),
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
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);

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
            children: <Widget>[
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
                children: <Widget>[
                  Text(
                    'App Preferences & Data',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unit Preference
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Display Weight Unit',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Currently set to ${settings.isLbs ? "Imperial (LBS)" : "Metric (KG)"}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
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
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Rest Timer Sound Alerts',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plays audio chime when rest timer reaches 0s',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    activeTrackColor: AppTheme.primaryAmber,
                    value: settings.soundAlertsEnabled,
                    onChanged: (_) => settings.toggleSoundAlerts(),
                  ),
                ],
              ),
              if (settings.soundAlertsEnabled) ...[
                const SizedBox(height: 12),
                // Sound Tone Selection Chips with Preview
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Rest Alert Tone',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: OlySoundTone.values.map((tone) {
                        final bool isSelected = settings.soundTone == tone.id;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            settings.setSoundTone(tone.id);
                            NotificationService().playSound(tone);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryAmber.withValues(alpha: 0.18)
                                  : AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryAmber
                                    : AppTheme.borderColor,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  isSelected ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? AppTheme.primaryAmber
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tone.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    // Notification Testing Hub Section Header
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.speed_rounded,
                          size: 14,
                          color: AppTheme.accentElectricCyan,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LOCK SCREEN TESTING HUB (5-SEC TIMERS)',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentElectricCyan,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap any test below and lock your iPhone immediately. In 5s, the banner fires with full audio, payload & Quick Actions (long-press to reveal actions).',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildNotificationTestTile(
                      emoji: '💧',
                      title: 'Circadian Hydration (739 mL)',
                      subtitle: 'Paced daily water reminder with quick-log credit',
                      actionsHint: '💧 Quick Log • Open Fuel',
                      accentColor: AppTheme.accentElectricCyan,
                      onSchedule: () =>
                          NotificationService().scheduleTestHydrationNotification(),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationTestTile(
                      emoji: '⚡',
                      title: 'Rest Timer (Ready / +30s)',
                      subtitle: 'Inter-set recovery alarm with custom chime',
                      actionsHint: '⏱️ +30s Rest • ⚡ Ready to Lift',
                      accentColor: AppTheme.primaryAmber,
                      onSchedule: () =>
                          NotificationService().scheduleTestRestTimerNotification(),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationTestTile(
                      emoji: '☕',
                      title: 'Fasting Coffee Primer (240 mL)',
                      subtitle: 'Circadian caffeine mobilization & ghrelin shield',
                      actionsHint: '☕ Log Coffee (240 mL) • Open Fasting',
                      accentColor: const Color(0xFFD7CCC8),
                      onSchedule: () =>
                          NotificationService().scheduleTestCoffeeNotification(),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationTestTile(
                      emoji: '💪',
                      title: 'GtG Submax Pull-Ups (5 Reps)',
                      subtitle: 'Periodic neural drive & volume accumulation',
                      actionsHint: '💪 Log Reps • Open GtG Hub',
                      accentColor: const Color(0xFF00E676),
                      onSchedule: () =>
                          NotificationService().scheduleTestGtgPullUpNotification(),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationTestTile(
                      emoji: '🧗',
                      title: 'GtG Scapular Hang (45s)',
                      subtitle: 'Active shoulder tendon armor interval hold',
                      actionsHint: '🧗 Log Hang • ⏱️ Start Hang',
                      accentColor: const Color(0xFF00B0FF),
                      onSchedule: () =>
                          NotificationService().scheduleTestGtgHangNotification(),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationTestTile(
                      emoji: '🌬️',
                      title: 'Wim Hof Breathwork Reset',
                      subtitle: 'Parasympathetic autonomic reset & HRV recovery',
                      actionsHint: '🌬️ Start Breathwork • Open Recover',
                      accentColor: const Color(0xFFE040FB),
                      onSchedule: () =>
                          NotificationService().scheduleTestBreathworkNotification(),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 8),

              // Haptic Feedback Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Haptic Vibration Alerts',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Triggers device vibration when rest timer finishes',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    activeTrackColor: AppTheme.primaryAmber,
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
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Export JSON Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final String jsonStr = settings.exportFullDataJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '📋 Full App Data Backup copied to Clipboard (JSON)!',
                        ),
                        backgroundColor: AppTheme.primaryAmber,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.download,
                    color: AppTheme.primaryAmber,
                  ),
                  label: Text(
                    'Export App Backup (JSON)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Export CSV Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final String csvStr = settings.exportPrsCsv();
                    Clipboard.setData(ClipboardData(text: csvStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📊 PR History CSV copied to Clipboard!'),
                        backgroundColor: AppTheme.primaryAmber,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.table_chart,
                    color: AppTheme.secondaryCyan,
                  ),
                  label: Text(
                    'Export PR History (CSV)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  label: Text(
                    'Import File (.json / .csv)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Fallback Paste Dialog Button
              Center(
                child: TextButton.icon(
                  onPressed: () => _showPasteImportDialog(context),
                  icon: const Icon(
                    Icons.paste,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  label: Text(
                    'Paste Raw Text / JSON',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 8),

              // Diagnostics & System Logs
              Text(
                'DIAGNOSTICS & SYSTEM LOGS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CrashReportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.bug_report,
                    color: Colors.orangeAccent,
                  ),
                  label: Text(
                    'View Diagnostics & Crash Logs',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  void _showPasteImportDialog(BuildContext context) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final LiftProvider lifts = Provider.of<LiftProvider>(
      context,
      listen: false,
    );
    final ProgramProvider program = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Paste JSON or CSV Data',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Paste JSON or CSV data below to restore PRs and workout logs.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _importController,
              maxLines: 5,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '{"lifts": [...]} or Snatch,Snatch,100,220...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final String raw = _importController.text.trim();
              final bool isJson = raw.startsWith('{') || raw.startsWith('[');
              final bool success = isJson
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

  Widget _buildNotificationTestTile({
    required String emoji,
    required String title,
    required String subtitle,
    required String actionsHint,
    required Color accentColor,
    required Future<void> Function() onSchedule,
  }) {
    return InkWell(
      onTap: () async {
        await HapticFeedback.mediumImpact();
        await onSchedule();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚡ $title scheduled in 5s! Lock your iPhone now to test.',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: accentColor,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Actions: $actionsHint',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.play_circle_fill_rounded,
              size: 20,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
