import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A kinetic rolling numeric counter that interpolates smoothly between
/// values with an elastic ease-out curve. Perfect for 1RM weights, session tonnage,
/// metabolic calorie balances, and biometric indicators.
class KineticCounter extends StatelessWidget {
  const new({
    required this.value,
    super.key,
    this.style,
    this.fractionDigits = 0,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
    this.textAlign = TextAlign.start,
  });

  final num value;
  final TextStyle? style;
  final int fractionDigits;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final TextStyle defaultStyle = GoogleFonts.firaCode(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final TextStyle effectiveStyle = style != null
        ? defaultStyle.merge(style)
        : defaultStyle;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final String formattedNumber = fractionDigits > 0
            ? val.toStringAsFixed(fractionDigits)
            : val.round().toString();

        return Text(
          '$prefix$formattedNumber$suffix',
          style: effectiveStyle,
          textAlign: textAlign,
        );
      },
    );
  }
}
