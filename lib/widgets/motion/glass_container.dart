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
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final double blur;
  final Color? backgroundColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        );

    final effectiveShadow = boxShadow ??
        <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceGlass,
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
