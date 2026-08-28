import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/services/injury_export_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class InjuryExportBottomSheet extends StatefulWidget {
  const InjuryExportBottomSheet({
    required this.injuries,
    super.key,
  });

  final List<InjuryRecord> injuries;

  @override
  State<InjuryExportBottomSheet> createState() =>
      _InjuryExportBottomSheetState();
}

class _InjuryExportBottomSheetState extends State<InjuryExportBottomSheet> {
  bool _isGeneratingPdf = false;
  bool _copiedJson = false;

  Future<void> _handleSharePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await InjuryExportService.sharePdfReport(allInjuries: widget.injuries);
      AppLogService.instance.info(
        'INJURY_EXPORT',
        'Exported ${widget.injuries.length} injury records to PDF report',
      );
    } catch (e, st) {
      AppLogService.instance.warning(
        'INJURY_EXPORT',
        'Failed to generate or share PDF report: $e',
        stackTrace: st.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _handlePreviewPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await InjuryExportService.previewOrPrintPdf(allInjuries: widget.injuries);
    } catch (e, st) {
      AppLogService.instance.warning(
        'INJURY_EXPORT',
        'Failed to preview or print PDF report: $e',
        stackTrace: st.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF preview: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _handleShareJson() async {
    try {
      await InjuryExportService.shareJsonExport(allInjuries: widget.injuries);
      AppLogService.instance.info(
        'INJURY_EXPORT',
        'Exported ${widget.injuries.length} injury records to JSON file',
      );
    } catch (e, st) {
      AppLogService.instance.warning(
        'INJURY_EXPORT',
        'Failed to share JSON export: $e',
        stackTrace: st.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export JSON file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleCopyJson() async {
    final String jsonStr =
        InjuryExportService.generateJsonExport(allInjuries: widget.injuries);
    try {
      await Clipboard.setData(ClipboardData(text: jsonStr));
    } catch (_) {}

    if (mounted) {
      setState(() => _copiedJson = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Copied ${widget.injuries.length} injury records as JSON to clipboard!',
          ),
          backgroundColor: AppTheme.primaryAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final InjuryProvider? provider = Provider.of<InjuryProvider?>(context);
    final List<InjuryRecord> active =
        widget.injuries.where((InjuryRecord i) => i.isActive).toList();
    final List<InjuryRecord> resolved =
        widget.injuries.where((InjuryRecord i) => !i.isActive).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.ios_share,
                    color: AppTheme.primaryAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Export Injury History',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Share with PT, orthopedic doctor, or export raw data',
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
            const SizedBox(height: 14),

            // Summary metrics pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildStatItem('Total', '${widget.injuries.length}'),
                  _buildStatDivider(),
                  _buildStatItem('Active', '${active.length}'),
                  _buildStatDivider(),
                  _buildStatItem('Resolved', '${resolved.length}'),
                  _buildStatDivider(),
                  _buildStatItem(
                    'Avg Pain',
                    provider?.averagePainScore.toStringAsFixed(1) ?? '0.0',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: PDF Clinical Report Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clinical & Athletic PDF Report',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '.PDF',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comprehensive multi-page medical summary with active strain table, OSIICS codes, loading contraindications, safe regressions, and check-in timeline.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.share,
                                  size: 16,
                                  color: Colors.black,
                                ),
                          label: Text(
                            'Share / Save PDF',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAmber,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isGeneratingPdf ? null : _handleSharePdf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.print,
                            size: 16,
                            color: AppTheme.textPrimary,
                          ),
                          label: Text(
                            'Preview / Print',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isGeneratingPdf ? null : _handlePreviewPdf,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Option 2: JSON Backup Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.secondaryCyan.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.data_object,
                        color: AppTheme.secondaryCyan,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Structured JSON Data Export',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '.JSON',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Machine-readable backup with raw records, pain timeline audit, biomechanical vector tags, and recovery linkages.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.share,
                            size: 16,
                            color: Colors.black,
                          ),
                          label: Text(
                            'Share .JSON File',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryCyan,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleShareJson,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            _copiedJson ? Icons.check : Icons.copy,
                            size: 16,
                            color: _copiedJson
                                ? AppTheme.successGreen
                                : AppTheme.secondaryCyan,
                          ),
                          label: Text(
                            _copiedJson ? 'Copied!' : 'Copy to Clipboard',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: _copiedJson
                                  ? AppTheme.successGreen
                                  : AppTheme.secondaryCyan,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _copiedJson
                                  ? AppTheme.successGreen
                                  : AppTheme.secondaryCyan.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleCopyJson,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 20,
      width: 1,
      color: AppTheme.borderColor,
    );
  }
}
