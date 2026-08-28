import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/services/app_log_service.dart';
import 'package:oly/theme/app_theme.dart';

class CrashReportScreen extends StatefulWidget {
  const CrashReportScreen({super.key});

  @override
  State<CrashReportScreen> createState() => _CrashReportScreenState();
}

class _CrashReportScreenState extends State<CrashReportScreen> {
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyAllLogs() {
    final String text = AppLogService.instance.exportFullLogsText();
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Full diagnostics log copied to clipboard'),
        backgroundColor: AppTheme.secondaryCyan,
      ),
    );
  }

  void _copySingleLog(LogEntry entry) {
    Clipboard.setData(ClipboardData(text: entry.toString()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Copied [${entry.tag}] log to clipboard'),
        backgroundColor: AppTheme.primaryAmber,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _clearLogs() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text(
          'Clear System Logs?',
          style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This will permanently delete all recorded log messages and crash reports from memory and local storage.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppLogService.instance.clearLogs();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ All logs cleared'),
            backgroundColor: AppTheme.primaryAmber,
          ),
        );
      }
    }
  }

  void _triggerTestException() {
    AppLogService.instance.error(
      'DIAGNOSTICS_TEST',
      'This is a user-initiated diagnostic test exception to verify error handling.',
      error: 'TestException: Manual diagnostic probe triggered',
      stackTrace: StackTrace.current,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<LogEntry> allLogs = AppLogService.instance.logs;
    final List<LogEntry> filteredLogs = allLogs.where((LogEntry log) {
      if (_filterLevel != null && log.level != _filterLevel) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final String q = _searchQuery.toLowerCase();
        final bool matchTag = log.tag.toLowerCase().contains(q);
        final bool matchMsg = log.message.toLowerCase().contains(q);
        return matchTag || matchMsg;
      }
      return true;
    }).toList();

    final int crashCount = allLogs
        .where((LogEntry l) => l.level == LogLevel.crash)
        .length;
    final int errorCount = allLogs
        .where((LogEntry l) => l.level == LogLevel.error)
        .length;
    final int warnCount = allLogs
        .where((LogEntry l) => l.level == LogLevel.warning)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        title: Text(
          'Diagnostics & Crash Logs',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.copy_all, color: AppTheme.primaryAmber),
            tooltip: 'Copy Full Log',
            onPressed: _copyAllLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Clear Logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Stat Overview Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: <Widget>[
                _buildStatCard(
                  'Total Logs',
                  '${allLogs.length}',
                  AppTheme.textPrimary,
                  null,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Crashes',
                  '$crashCount',
                  Colors.redAccent,
                  LogLevel.crash,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Errors',
                  '$errorCount',
                  Colors.orangeAccent,
                  LogLevel.error,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Warnings',
                  '$warnCount',
                  AppTheme.primaryAmber,
                  LogLevel.warning,
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    onChanged: (String val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Filter by tag or message (e.g. OCR, WOD, Barcode)...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _triggerTestException,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Probe',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Level Badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: <Widget>[
                _buildFilterChip('ALL (${allLogs.length})', null),
                _buildFilterChip('CRASHES ($crashCount)', LogLevel.crash),
                _buildFilterChip('ERRORS ($errorCount)', LogLevel.error),
                _buildFilterChip('WARNINGS ($warnCount)', LogLevel.warning),
                _buildFilterChip('INFO', LogLevel.info),
                _buildFilterChip('DEBUG', LogLevel.debug),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Logs List
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No log entries match your filter',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext ctx, int idx) =>
                        _buildLogCard(filteredLogs[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    Color color,
    LogLevel? level,
  ) {
    final bool isSelected = _filterLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () => setState(
          () => _filterLevel = (_filterLevel == level ? null : level),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                count,
                style: GoogleFonts.firaCode(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LogLevel? level) {
    final bool isSelected = _filterLevel == level;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryAmber.withValues(alpha: 0.2),
        backgroundColor: AppTheme.surfaceCard,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryAmber : AppTheme.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor,
        ),
        onSelected: (bool sel) =>
            setState(() => _filterLevel = sel ? level : null),
      ),
    );
  }

  Widget _buildLogCard(LogEntry entry) {
    Color badgeColor;
    switch (entry.level) {
      case LogLevel.crash:
        badgeColor = Colors.redAccent;
        break;
      case LogLevel.error:
        badgeColor = Colors.orangeAccent;
        break;
      case LogLevel.warning:
        badgeColor = AppTheme.primaryAmber;
        break;
      case LogLevel.info:
        badgeColor = AppTheme.secondaryCyan;
        break;
      case LogLevel.debug:
        badgeColor = Colors.grey;
        break;
    }

    final bool hasStack =
        entry.stackTrace != null && entry.stackTrace!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.level == LogLevel.crash || entry.level == LogLevel.error
              ? badgeColor.withValues(alpha: 0.4)
              : AppTheme.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Row: Level Badge + Tag + Timestamp + Copy Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.level.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '[${entry.tag}]',
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        entry.formattedTime,
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copy Log Entry',
                        onPressed: () => _copySingleLog(entry),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Message
              SelectableText(
                entry.message,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),

              // Stack Trace Expander (if present)
              if (hasStack) ...<Widget>[
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        'Stack Trace',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            entry.stackTrace!,
                            style: GoogleFonts.firaCode(
                              fontSize: 10,
                              color: Colors.red[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
