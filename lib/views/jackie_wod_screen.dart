import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/mobility_exercise_model.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:oly/widgets/jackie_wod_card.dart';

class JackieWodScreen extends StatefulWidget {
  const JackieWodScreen({
    super.key,
    this.isPreviewMode = false,
  });

  final bool isPreviewMode;

  @override
  State<JackieWodScreen> createState() => _JackieWodScreenState();
}

class _JackieWodScreenState extends State<JackieWodScreen> {
  late bool _isPreview;

  @override
  void initState() {
    super.initState();
    _isPreview = widget.isPreviewMode;
  }

  @override
  Widget build(BuildContext context) {
    final MobilityExerciseModel jackieExercise =
        MobilityExerciseModel.defaultExercises().firstWhere(
      (MobilityExerciseModel e) => e.id == 'jackie_wod',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CrossFit Jackie',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          // Mode Toggle Button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPreview = !_isPreview);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isPreview
                        ? AppTheme.secondaryCyan.withValues(alpha: 0.2)
                        : AppTheme.primaryAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _isPreview ? Icons.explore : Icons.play_arrow_rounded,
                        size: 14,
                        color: _isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPreview ? 'PREVIEW' : 'LIVE WOD',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppTheme.surfaceElevated, AppTheme.surfaceCard],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPreview
                        ? AppTheme.secondaryCyan.withValues(alpha: 0.4)
                        : AppTheme.primaryAmber.withValues(alpha: 0.4),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (_isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber)
                          .withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (_isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        _isPreview ? Icons.explore : Icons.rowing_rounded,
                        color: _isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _isPreview
                                ? 'PREVIEW MODE (NO SCORES SAVED)'
                                : 'FOR TIME CHIPPER (LIVE STOPWATCH)',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isPreview ? AppTheme.secondaryCyan : AppTheme.primaryAmber,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '1,000m Row • 50 Thrusters • 30 Pull-ups',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: 7–12 minutes • Rx: 45 lb Barbell • Track splits for each station.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Jackie WOD Card
              JackieWodCard(
                key: ValueKey('jackie_wod_card_preview_$_isPreview'),
                exercise: jackieExercise,
                isPreviewMode: _isPreview,
                onCompleted: () {
                  // Workout completed or preview dismissed
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
