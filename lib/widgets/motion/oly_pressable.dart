import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A high-performance, tactile spring-scale interaction wrapper designed
/// for the OLY athletic aesthetic. Compresses on touch with an elastic curve
/// and triggers a crisp micro-haptic pulse, giving buttons and cards a physical,
/// mechanical feel like an Olympic barbell collar.
class OlyPressable extends StatefulWidget {
  const new({
    required this.child,
    super.key,
    this.scaleFactor = 0.965,
    this.enableHaptic = true,
    this.duration = const Duration(milliseconds: 110),
    this.curve = Curves.easeOutCubic,
    this.borderRadius,
    this.behavior = HitTestBehavior.opaque,
    this.onPressed,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final bool enableHaptic;
  final Duration duration;
  final Curve curve;
  final BorderRadius? borderRadius;
  final HitTestBehavior behavior;

  @override
  State<OlyPressable> createState() => _OlyPressableState();
}

class _OlyPressableState extends State<OlyPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null && widget.onLongPress == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null && widget.onLongPress == null) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onPressed == null && widget.onLongPress == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive =
        widget.onPressed != null || widget.onLongPress != null;

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    if (!isInteractive) {
      return content;
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: content,
    );
  }
}
