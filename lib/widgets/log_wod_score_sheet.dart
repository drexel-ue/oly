import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/benchmark_wod_log.dart';
import 'package:oly/models/crossfit_hero_wod.dart';
import 'package:oly/models/wod_definition.dart';
import 'package:oly/providers/recovery_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// Modal bottom sheet for logging or recording a score for any CrossFit Benchmark or Hero WOD.
class LogWodScoreSheet extends StatefulWidget {
  const LogWodScoreSheet({
    this.wod,
    this.heroWod,
    this.allWods = const <WodDefinition>[],
    this.wodId,
    this.wodName,
    this.wodFormat,
    super.key,
  });

  final WodDefinition? wod;
  final CrossfitHeroWod? heroWod;
  final List<WodDefinition> allWods;
  final String? wodId;
  final String? wodName;
  final String? wodFormat;

  static Future<BenchmarkWodLog?> show(
    BuildContext context, {
    WodDefinition? wod,
    CrossfitHeroWod? heroWod,
    List<WodDefinition> allWods = const <WodDefinition>[],
    String? wodId,
    String? wodName,
    String? wodFormat,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<BenchmarkWodLog>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogWodScoreSheet(
        wod: wod,
        heroWod: heroWod,
        allWods: allWods,
        wodId: wodId,
        wodName: wodName,
        wodFormat: wodFormat,
      ),
    );
  }

  @override
  State<LogWodScoreSheet> createState() => _LogWodScoreSheetState();
}

class _LogWodScoreSheetState extends State<LogWodScoreSheet> {
  late String _wodId;
  late String _wodName;
  late String _format;
  late String _category;

  // Score state
  int _minutes = 0;
  int _seconds = 0;
  int _rounds = 0;
  int _reps = 0;
  bool _isRx = true;
  DateTime _selectedDate = DateTime.now();
  int _rpe = 8;
  final TextEditingController _scalingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _calController = TextEditingController();

  final List<String> _commonScalings = <String>[
    'No Weight Vest',
    'Banded Pull-ups',
    'Knee Push-ups',
    'Ring Rows',
    'Lighter Barbell',
    'Single Unders',
    'Jumping Pull-ups',
    'Dumbbells substituted',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.heroWod != null) {
      final CrossfitHeroWod hero = widget.heroWod!;
      _wodId = hero.id;
      _wodName = hero.name;
      _format = hero.format.name;
      _category = 'Hero Benchmark';
    } else if (widget.wod != null) {
      final WodDefinition w = widget.wod!;
      _wodId = w.id;
      _wodName = w.name;
      _format = w.format.name;
      _category = w.category;
    } else if (widget.wodId != null) {
      _wodId = widget.wodId!;
      _wodName = widget.wodName ?? widget.wodId!;
      _format = widget.wodFormat ?? 'forTime';
      _category = 'Hero Benchmark';
    } else if (widget.allWods.isNotEmpty) {
      final WodDefinition first = widget.allWods.first;
      _wodId = first.id;
      _wodName = first.name;
      _format = first.format.name;
      _category = first.category;
    } else {
      _wodId = 'custom_wod';
      _wodName = 'Custom WOD';
      _format = 'forTime';
      _category = 'Custom Benchmark';
    }

    // Default sensible durations based on format
    if (_isFormatForTime) {
      _minutes = 15;
      _seconds = 0;
    } else if (_isFormatAmrap) {
      _rounds = 10;
      _reps = 0;
    } else {
      _minutes = 10;
    }
  }

  @override
  void dispose() {
    _scalingController.dispose();
    _notesController.dispose();
    _hrController.dispose();
    _calController.dispose();
    super.dispose();
  }

  bool get _isFormatForTime {
    final String f = _format.toLowerCase();
    return f.contains('time') || f.contains('chipper') || f.contains('rft');
  }

  bool get _isFormatAmrap {
    final String f = _format.toLowerCase();
    return f.contains('amrap');
  }

  void _onWodSelected(WodDefinition selected) {
    setState(() {
      _wodId = selected.id;
      _wodName = selected.name;
      _format = selected.format.name;
      _category = selected.category;
    });
  }

  String _calculateScoreDisplay() {
    if (_isFormatForTime) {
      final String m = '$_minutes';
      final String s = _seconds < 10 ? '0$_seconds' : '$_seconds';
      return '$m:$s';
    } else if (_isFormatAmrap) {
      if (_reps > 0) {
        return '$_rounds Rds + $_reps Reps';
      }
      return '$_rounds Rounds';
    } else {
      return '$_minutes Minutes';
    }
  }

  int _calculateDurationSeconds() {
    if (_isFormatForTime) {
      return (_minutes * 60) + _seconds;
    } else {
      return _minutes * 60;
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryAmber,
              surface: AppTheme.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveLog() async {
    final int duration = _calculateDurationSeconds();
    if (_isFormatForTime && duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid completion time')),
      );
      return;
    }

    final RecoveryProvider recovery = Provider.of<RecoveryProvider>(context, listen: false);
    final String scoreStr = _calculateScoreDisplay();

    final BenchmarkWodLog newLog = BenchmarkWodLog.create(
      wodId: _wodId,
      wodName: _wodName,
      format: _format,
      category: _category,
      date: _selectedDate,
      durationSeconds: duration,
      completedRounds: _rounds,
      completedReps: _reps,
      scoreDisplay: scoreStr,
      isRx: _isRx,
      scalingModifications: _isRx ? null : _scalingController.text.trim(),
      rpe: _rpe,
      averageHeartRate: int.tryParse(_hrController.text.trim()),
      caloriesBurned: int.tryParse(_calController.text.trim()),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final BenchmarkWodLog saved = await recovery.logBenchmarkWod(newLog);

    HapticFeedback.heavyImpact();
    if (mounted) {
      Navigator.pop(context, saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: saved.isPr ? Colors.green.shade800 : AppTheme.surfaceCard,
          content: Row(
            children: <Widget>[
              Icon(
                saved.isPr ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
                color: saved.isPr ? AppTheme.primaryAmber : Colors.greenAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  saved.isPr
                      ? 'NEW PERSONAL RECORD! 🏆 $scoreStr (${saved.isRx ? "Rx" : "Scaled"})'
                      : 'Logged $scoreStr for $_wodName',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header Drag Handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Modal Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
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
                        'Log WOD Score',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$_wodName • $_category',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // Scrollable Form Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // If opening from general "+ Log Score", allow selecting which WOD
                  if (widget.wod == null && widget.heroWod == null && widget.allWods.isNotEmpty) ...<Widget>[
                    _buildWodSelector(),
                    const SizedBox(height: 16),
                  ],

                  // Score Input Section (Tailored to Format)
                  _buildScoreInputSection(),

                  const SizedBox(height: 18),

                  // Rx vs Scaled Selector
                  _buildRxScaledToggle(),

                  const SizedBox(height: 18),

                  // Date & Effort (RPE)
                  _buildDateAndRpeSection(),

                  const SizedBox(height: 18),

                  // Notes & Strategy
                  _buildNotesSection(),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(top: BorderSide(color: AppTheme.surfaceElevated)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    'RECORD SCORE (${_calculateScoreDisplay()})',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWodSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'SELECT WORKOUT',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _wodId,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceCard,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryAmber),
              items: widget.allWods.map((WodDefinition item) {
                return DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(
                    '${item.name} (${item.format.displayName})',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newId) {
                if (newId != null) {
                  final WodDefinition selected =
                      widget.allWods.firstWhere((WodDefinition w) => w.id == newId);
                  _onWodSelected(selected);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _isFormatForTime ? Icons.timer_outlined : Icons.repeat_rounded,
                size: 16,
                color: AppTheme.primaryAmber,
              ),
              const SizedBox(width: 6),
              Text(
                _isFormatForTime ? 'COMPLETION TIME (FOR TIME)' : 'ROUNDS & REPS (AMRAP)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _calculateScoreDisplay(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isFormatForTime) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // Minutes Counter
                _buildStepperCol(
                  label: 'MINUTES',
                  value: _minutes,
                  onDecrement: () => setState(() => _minutes = (_minutes - 1).clamp(0, 300)),
                  onIncrement: () => setState(() => _minutes = (_minutes + 1).clamp(0, 300)),
                ),
                Text(':', style: GoogleFonts.outfit(fontSize: 32, color: AppTheme.textSecondary)),
                // Seconds Counter
                _buildStepperCol(
                  label: 'SECONDS',
                  value: _seconds,
                  onDecrement: () => setState(() => _seconds = (_seconds - 5 < 0 ? 55 : _seconds - 5)),
                  onIncrement: () => setState(() => _seconds = (_seconds + 5 > 59 ? 0 : _seconds + 5)),
                ),
              ],
            ),
          ] else ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // Completed Rounds
                _buildStepperCol(
                  label: 'ROUNDS',
                  value: _rounds,
                  onDecrement: () => setState(() => _rounds = (_rounds - 1).clamp(0, 100)),
                  onIncrement: () => setState(() => _rounds = (_rounds + 1).clamp(0, 100)),
                ),
                Text('+', style: GoogleFonts.outfit(fontSize: 28, color: AppTheme.textSecondary)),
                // Extra Reps
                _buildStepperCol(
                  label: 'EXTRA REPS',
                  value: _reps,
                  onDecrement: () => setState(() => _reps = (_reps - 1).clamp(0, 500)),
                  onIncrement: () => setState(() => _reps = (_reps + 1).clamp(0, 500)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperCol({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
              onPressed: () {
                HapticFeedback.selectionClick();
                onDecrement();
              },
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 48),
              alignment: Alignment.center,
              child: Text(
                value < 10 ? '0$value' : '$value',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryAmber),
              onPressed: () {
                HapticFeedback.selectionClick();
                onIncrement();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRxScaledToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.tune_rounded, size: 16, color: AppTheme.secondaryCyan),
              const SizedBox(width: 6),
              Text(
                'WORKOUT TIER & MODIFICATIONS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryCyan,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isRx = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isRx
                          ? AppTheme.primaryAmber.withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isRx ? AppTheme.primaryAmber : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Rx (As Prescribed)',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: _isRx ? FontWeight.bold : FontWeight.normal,
                          color: _isRx ? AppTheme.primaryAmber : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isRx = false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isRx
                          ? AppTheme.secondaryCyan.withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isRx ? AppTheme.secondaryCyan : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Scaled',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: !_isRx ? FontWeight.bold : FontWeight.normal,
                          color: !_isRx ? AppTheme.secondaryCyan : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_isRx) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Quick Scaled Tags:',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonScalings.map((String tag) {
                final bool isIncluded = _scalingController.text.contains(tag);
                return InkWell(
                  onTap: () {
                    final String cur = _scalingController.text.trim();
                    if (cur.isEmpty) {
                      _scalingController.text = tag;
                    } else if (!cur.contains(tag)) {
                      _scalingController.text = '$cur, $tag';
                    }
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIncluded
                          ? AppTheme.secondaryCyan.withValues(alpha: 0.25)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isIncluded ? AppTheme.secondaryCyan : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isIncluded ? AppTheme.secondaryCyan : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _scalingController,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. No vest, 35 lb bar, knee push-ups...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateAndRpeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Date selector
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'COMPLETED DATE',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppTheme.primaryAmber),
                label: Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppTheme.surfaceElevated),
          // RPE Slider
          Row(
            children: <Widget>[
              const Icon(Icons.speed_rounded, size: 16, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Text(
                'PERCEIVED EXERTION (RPE: $_rpe/10)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Slider(
            value: _rpe.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _rpe >= 9 ? Colors.redAccent : (_rpe >= 7 ? AppTheme.primaryAmber : AppTheme.secondaryCyan),
            onChanged: (double val) => setState(() => _rpe = val.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('1 (Easy Warmup)', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
              Text('8 (Very Hard)', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
              Text('10 (Maximum Effort)', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.notes_rounded, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'SESSION NOTES & PACING STRATEGY',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Partitioned 5/10/15. Push-ups broke on round 12. Paced first mile at 8:15...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
