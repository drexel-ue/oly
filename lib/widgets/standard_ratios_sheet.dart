import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/models/lift_model.dart';
import 'package:oly/providers/lift_provider.dart';
import 'package:oly/providers/settings_provider.dart';
import 'package:oly/theme/app_theme.dart';
import 'package:provider/provider.dart';

class StandardRatiosSheet extends StatelessWidget {
  const StandardRatiosSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final LiftProvider lifts = Provider.of<LiftProvider>(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);

    final List<LiftModel> allLifts = lifts.lifts;
    final List<LiftModel> anchorLifts = allLifts
        .where(
          (LiftModel l) => l.anchorLiftId != null && l.anchorLiftId!.isNotEmpty,
        )
        .toList();

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
                  Expanded(
                    child: Text(
                      'Olympic Ratio Standards',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
              Text(
                'Standard weightlifting variation ratios relative to primary 1RMs.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Ratios Table Container
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: <Widget>[
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: Text(
                              'VARIATION',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAmber,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ANCHOR',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'RATIO',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'IDEAL 1RM',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),

                    // Table Rows
                    ...anchorLifts.map((LiftModel lift) {
                      final LiftModel? anchor = lifts.getLift(
                        lift.anchorLiftId!,
                      );
                      final double anchorMax = anchor?.currentMax ?? 0.0;
                      final double targetMaxKg = anchorMax * lift.targetRatio;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.borderColor,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: Text(
                                lift.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                anchor?.name ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${(lift.targetRatio * 100).toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryAmber,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                targetMaxKg > 0
                                    ? settings.formatWeight(targetMaxKg)
                                    : '-',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
