import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/services/injury_database_service.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class InjuryLogBottomSheet extends StatefulWidget {
  const InjuryLogBottomSheet({
    required this.initialRegion,
    super.key,
    this.existingInjury,
  });

  final InjuryRegion initialRegion;
  final InjuryRecord? existingInjury;

  @override
  State<InjuryLogBottomSheet> createState() => _InjuryLogBottomSheetState();
}

class _InjuryLogBottomSheetState extends State<InjuryLogBottomSheet> {
  final Uuid _uuid = const Uuid();
  late InjuryRegion _region;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late DateTime _onsetDate;
  late int _painScale;
  late Set<BiomechanicalConstraint> _selectedConstraints;
  String _osiicsCode = '';
  List<InjurySubstitution> _safeSubstitutions = <InjurySubstitution>[];

  List<CatalogInjury> _catalogSuggestions = <CatalogInjury>[];

  @override
  void initState() {
    super.initState();
    _region = widget.existingInjury?.region ?? widget.initialRegion;
    _nameController = TextEditingController(
      text: widget.existingInjury?.name ?? '${_region.displayName} Strain',
    );
    _notesController = TextEditingController(
      text: widget.existingInjury?.notes ?? '',
    );
    _onsetDate = widget.existingInjury?.onsetDate ?? DateTime.now();
    _painScale = widget.existingInjury?.painScale ?? 4;
    _selectedConstraints = Set<BiomechanicalConstraint>.from(
      widget.existingInjury?.constraints ?? <BiomechanicalConstraint>[],
    );
    _osiicsCode = widget.existingInjury?.osiicsCode ?? '';
    _safeSubstitutions = List<InjurySubstitution>.from(
      widget.existingInjury?.safeSubstitutions ?? <InjurySubstitution>[],
    );

    _loadCatalogForRegion();
  }

  void _loadCatalogForRegion() {
    setState(() {
      _catalogSuggestions = InjuryDatabaseService.instance.getByRegion(_region);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _durationDays {
    return DateTime.now().difference(_onsetDate).inDays.clamp(0, 9999);
  }

  InjuryStage get _currentStage {
    if (_durationDays < 14) {
      return InjuryStage.acute;
    }
    if (_durationDays <= 42) {
      return InjuryStage.subacute;
    }
    return InjuryStage.chronic;
  }

  void _applyCatalogInjury(CatalogInjury catalog) {
    setState(() {
      _nameController.text = catalog.name;
      _osiicsCode = catalog.osiicsCode;
      _selectedConstraints.addAll(catalog.aggravatingVectors);
      _safeSubstitutions = List<InjurySubstitution>.from(catalog.safeSubstitutions);
    });
  }

  Future<void> _pickOnsetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _onsetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryAmber,
              surface: AppTheme.surfaceElevated,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _onsetDate = picked);
    }
  }

  Future<void> _save() async {
    final InjuryProvider provider = Provider.of<InjuryProvider>(
      context,
      listen: false,
    );

    final InjuryRecord record = InjuryRecord(
      id: widget.existingInjury?.id ?? _uuid.v4(),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : '${_region.displayName} Strain',
      osiicsCode: _osiicsCode,
      region: _region,
      onsetDate: _onsetDate,
      painScale: _painScale,
      constraints: _selectedConstraints.toList(),
      notes: _notesController.text.trim(),
      isActive: _painScale > 0,
      resolvedAt: _painScale == 0 ? DateTime.now() : null,
      safeSubstitutions: _safeSubstitutions,
    );

    if (widget.existingInjury != null) {
      await provider.updateInjury(record);
    } else {
      await provider.addInjury(record);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _painScale > 0
                ? '🩺 Injury updated: ${record.name} (${record.stage.label})'
                : '🎉 Region marked pain-free & healed!',
          ),
          backgroundColor:
              _painScale > 0 ? AppTheme.primaryAmber : AppTheme.successGreen,
        ),
      );
    }
  }

  Future<void> _resolve() async {
    if (widget.existingInjury != null) {
      final InjuryProvider provider = Provider.of<InjuryProvider>(
        context,
        listen: false,
      );
      await provider.resolveInjury(widget.existingInjury!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Injury marked resolved!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color stageColor = _currentStage == InjuryStage.acute
        ? AppTheme.primaryAmber
        : (_currentStage == InjuryStage.subacute
            ? const Color(0xFFFF9F0A)
            : const Color(0xFFBF5AF2));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Drag Handle
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.existingInjury != null ? 'Edit Injury Log' : 'Log New Strain / Injury',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _region.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.secondaryCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 12),

          // Scrollable Content
          Expanded(
            child: ListView(
              children: <Widget>[
                // OSIICS / Preset Diagnosis Catalog Chips
                if (_catalogSuggestions.isNotEmpty) ...<Widget>[
                  Text(
                    'REPRESENTATIVE CONDITIONS (OSIICS TAXONOMY)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _catalogSuggestions.map((CatalogInjury cat) {
                      final bool isSelected = _nameController.text == cat.name;
                      return ActionChip(
                        label: Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.black : AppTheme.textPrimary,
                          ),
                        ),
                        backgroundColor:
                            isSelected ? AppTheme.secondaryCyan : AppTheme.surfaceElevated,
                        side: BorderSide(
                          color: isSelected ? AppTheme.secondaryCyan : AppTheme.borderColor,
                        ),
                        onPressed: () => _applyCatalogInjury(cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Condition Name Field
                Text(
                  'CONDITION / PATHOLOGY NAME',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Patellar Tendon Strain',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryAmber),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Onset Date & Stage Duration
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ONSET DATE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickOnsetDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(_onsetDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppTheme.primaryAmber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'STAGE & DURATION',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: stageColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  _currentStage == InjuryStage.acute
                                      ? Icons.flash_on
                                      : (_currentStage == InjuryStage.subacute
                                          ? Icons.cached
                                          : Icons.hourglass_top),
                                  size: 16,
                                  color: stageColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${_currentStage.label} ($_durationDays d)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: stageColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pain Rating Slider (0 - 10)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'PAIN / DISCOMFORT SCORE (0 - 10)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _painScale == 0
                            ? AppTheme.successGreen
                            : (_painScale <= 3
                                ? AppTheme.primaryAmber
                                : (_painScale <= 6
                                    ? const Color(0xFFFF9F0A)
                                    : Colors.redAccent)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_painScale / 10',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _painScale.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: _painScale <= 3
                      ? AppTheme.primaryAmber
                      : (_painScale <= 6 ? const Color(0xFFFF9F0A) : Colors.redAccent),
                  inactiveColor: AppTheme.surfaceElevated,
                  onChanged: (double val) => setState(() => _painScale = val.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '0 = Pain Free',
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '1-3 = Mild / Ache',
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '4-6 = Moderate',
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '7-10 = Severe',
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Biomechanical Constraints
                Text(
                  'AGGRAVATING LOADING VECTORS (CONSTRAINTS)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BiomechanicalConstraint.values.map((BiomechanicalConstraint c) {
                    final bool isSelected = _selectedConstraints.contains(c);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        c.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : AppTheme.textPrimary,
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceElevated,
                      selectedColor: AppTheme.primaryAmber,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryAmber : AppTheme.borderColor,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedConstraints.add(c);
                          } else {
                            _selectedConstraints.remove(c);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Clinical / Athlete Notes
                Text(
                  'SYMPTOMS & REHAB NOTES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Pain during catch in bottom position, stable during pulls.',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Buttons
          Row(
            children: <Widget>[
              if (widget.existingInjury != null) ...<Widget>[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _resolve,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: const BorderSide(color: AppTheme.successGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Mark Healed'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.existingInjury != null ? 'Save Changes' : 'Log Injury',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
