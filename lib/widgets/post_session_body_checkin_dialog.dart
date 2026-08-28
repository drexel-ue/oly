import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/injury_model.dart';
import 'package:oly/providers/injury_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/interactive_body_map.dart';
import 'package:provider/provider.dart';

class PostSessionBodyCheckinDialog extends StatefulWidget {
  const PostSessionBodyCheckinDialog({
    required this.onComplete,
    super.key,
    this.initialJointStrains = const <String>[],
  });

  final Function(Map<InjuryRegion, int> updatedPain, List<String> jointTags) onComplete;
  final List<String> initialJointStrains;

  @override
  State<PostSessionBodyCheckinDialog> createState() =>
      _PostSessionBodyCheckinDialogState();
}

class _PostSessionBodyCheckinDialogState
    extends State<PostSessionBodyCheckinDialog> {
  final Map<InjuryRegion, int> _sessionPainMap = <InjuryRegion, int>{};
  final Set<String> _jointTags = <String>{};
  InjuryRegion? _focusedRegion;

  @override
  void initState() {
    super.initState();
    _jointTags.addAll(widget.initialJointStrains);

    final InjuryProvider provider = Provider.of<InjuryProvider>(
      context,
      listen: false,
    );

    // Initialize with active injury pain scores
    for (final InjuryRecord injury in provider.activeInjuries) {
      _sessionPainMap[injury.region] = injury.painScale;
    }
  }

  void _onRegionSelected(InjuryRegion region) {
    setState(() {
      _focusedRegion = region;
      // Default to pain 3 if not present yet
      if (!_sessionPainMap.containsKey(region)) {
        _sessionPainMap[region] = 3;
      }
      _syncJointTags();
    });
  }

  void _syncJointTags() {
    _jointTags.clear();
    _sessionPainMap.forEach((InjuryRegion r, int pain) {
      if (pain > 0) {
        if (r == InjuryRegion.leftShoulder || r == InjuryRegion.rightShoulder) {
          _jointTags.add('Shoulders');
        } else if (r == InjuryRegion.leftKnee || r == InjuryRegion.rightKnee) {
          _jointTags.add('Knees');
        } else if (r == InjuryRegion.leftWrist || r == InjuryRegion.rightWrist) {
          _jointTags.add('Wrists');
        } else if (r == InjuryRegion.leftHipGlute || r == InjuryRegion.rightHipGlute) {
          _jointTags.add('Hips');
        } else if (r == InjuryRegion.lumbarSpine || r == InjuryRegion.thoracicSpine) {
          _jointTags.add('Lower Back');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final InjuryProvider provider = Provider.of<InjuryProvider>(context);
    final List<InjuryRecord> activeInjuries = provider.activeInjuries;

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                      Icons.checklist_rtl,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Post-Session Strain Check-In',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Update joint strain & pain scores for recovery sync',
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
              const SizedBox(height: 14),
              const Divider(color: AppTheme.borderColor, height: 1),
              const SizedBox(height: 14),

              // Interactive Mini Map
              Text(
                'TAP ANY REGION TO UPDATE STRAIN / PAIN:',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InteractiveBodyMap(
                injuries: activeInjuries,
                isCompact: true,
                selectedRegion: _focusedRegion,
                customPainMap: _sessionPainMap,
                onRegionSelected: _onRegionSelected,
              ),
              const SizedBox(height: 14),

              // Focused Region Pain Adjuster (if selected)
              if (_focusedRegion != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _focusedRegion!.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryCyan,
                            ),
                          ),
                          Text(
                            '${_sessionPainMap[_focusedRegion!] ?? 0} / 10',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Slider(
                        value: (_sessionPainMap[_focusedRegion!] ?? 0).toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: AppTheme.primaryAmber,
                        onChanged: (double v) {
                          setState(() {
                            final int val = v.round();
                            if (val == 0) {
                              _sessionPainMap.remove(_focusedRegion);
                            } else {
                              _sessionPainMap[_focusedRegion!] = val;
                            }
                            _syncJointTags();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Active Region Diff Summary List
              if (_sessionPainMap.isNotEmpty) ...<Widget>[
                Text(
                  'CURRENT POST-SESSION STATUS:',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _sessionPainMap.entries.map((MapEntry<InjuryRegion, int> entry) {
                    final int prePain = provider.getPainForRegion(entry.key);
                    final int postPain = entry.value;
                    final int delta = postPain - prePain;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: delta > 0
                              ? Colors.redAccent
                              : (delta < 0 ? AppTheme.successGreen : AppTheme.borderColor),
                        ),
                      ),
                      child: Text(
                        '${entry.key.displayName}: $postPain/10 ${delta != 0 ? "(${delta > 0 ? "+$delta" : "$delta"})" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: delta > 0
                              ? Colors.redAccent
                              : (delta < 0 ? AppTheme.successGreen : AppTheme.textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onComplete(_sessionPainMap, _jointTags.toList());
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Skip Check-In',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onComplete(_sessionPainMap, _jointTags.toList());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save & Finish',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
