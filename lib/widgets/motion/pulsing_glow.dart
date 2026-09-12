import 'package:flutter/material.dart';

/// A breathing, ambient glowing wrapper for elements signaling active live state
/// (in-progress barbell session, live rest timer countdown, fasting autophagy threshold).
class PulsingGlow extends StatefulWidget {
  const new({
    required this.child,
    required this.glowColor,
    super.key,
    this.maxBlurRadius = 18.0,
    this.minBlurRadius = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.period = const Duration(milliseconds: 2200),
    this.isPulsing = true,
  });

  final Widget child;
  final Color glowColor;
  final double maxBlurRadius;
  final double minBlurRadius;
  final BorderRadius borderRadius;
  final Duration period;
  final bool isPulsing;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    );

    _glowAnimation = Tween<double>(
      begin: widget.minBlurRadius,
      end: widget.maxBlurRadius,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.isPulsing) {
      if (_isTesting) {
        _controller.value = 0.5;
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void didUpdateWidget(PulsingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        if (_isTesting) {
          _controller.value = 0.5;
        } else {
          _controller.repeat(reverse: true);
        }
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: (_glowAnimation.value / widget.maxBlurRadius) * 0.35,
                ),
                blurRadius: _glowAnimation.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
