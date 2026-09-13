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
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (ambientGlowColor != null)
            BoxShadow(
              color: ambientGlowColor!.withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 1,
            ),
        ];

    final effectiveGradient = gradient ??
        (ambientGlowColor != null
            ? RadialGradient(
                center: const Alignment(0, -0.7),
                radius: ambientGlowRadius,
                colors: <Color>[
                  ambientGlowColor!.withValues(alpha: 0.18),
                  (backgroundColor ?? AppTheme.surfaceGlass)
                      .withValues(alpha: 0.85),
                ],
              )
            : null);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveGradient == null
            ? (backgroundColor ?? AppTheme.surfaceGlass)
            : null,
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
