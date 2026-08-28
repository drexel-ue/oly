import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/theme/app_theme.dart';

class RenphoStatPill extends StatelessWidget {
  const RenphoStatPill({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.unit,
    this.subtitle,
    this.status,
    this.delta,
    this.isDeltaPositiveGood = true,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String? subtitle;
  final String? status; // 'High', 'Average', 'Low'
  final double? delta;
  final bool isDeltaPositiveGood;

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.textSecondary;
    if (status == 'Average' || status == 'Standard') {
      statusColor = AppTheme.successGreen;
    } else if (status == 'High') {
      statusColor = AppTheme.warningOrange;
    } else if (status == 'Low') {
      statusColor = AppTheme.secondaryCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: <Widget>[
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryAmber),
          ),
          const SizedBox(width: 12),

          // Label & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (status != null) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Value & Delta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (unit != null) ...<Widget>[
                    const SizedBox(width: 3),
                    Text(
                      unit!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (delta != null && delta != 0.0) ...<Widget>[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      delta! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 11,
                      color: (delta! > 0 == isDeltaPositiveGood)
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                    ),
                    Text(
                      '${delta! > 0 ? '+' : ''}${delta!.toStringAsFixed(1)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (delta! > 0 == isDeltaPositiveGood)
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
