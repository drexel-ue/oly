import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oly/theme/app_theme.dart';

/// A premium glassmorphic frosted card container featuring BackdropFilter blur,
/// subtle specular top highlight, and an athletic dark gradient surface.
class GlassContainer extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.blur = 12.0,
    this.backgroundColor,
    this.gradient,
    this.ambientGlowColor,
    this.ambientGlowRadius = 0.8,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final double blur;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? ambientGlowColor;
  final double ambientGlowRadius;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ?? AppTheme.specularBorderTop;

    final effectiveShadow = boxShadow ??
        <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
          if (ambientGlowColor != null)
            BoxShadow(
              color: ambientGlowColor!.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 4),
            ),
        ];

    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            backgroundColor ?? const Color(0xFF181C28),
            if (backgroundColor != null)
              backgroundColor!.withValues(alpha: 0.85)
            else
              const Color(0xFF10121A),
          ],
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: borderRadius,
        border: effectiveBorder,
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: effectiveShadow,
      ),
      child: content,
    );
  }
}
