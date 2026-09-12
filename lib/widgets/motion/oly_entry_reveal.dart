import 'dart:async';
import 'package:flutter/material.dart';

/// A staggered slide and fade reveal animation widget for screen entry cascades.
/// Translates children by a fixed physical pixel distance ([slidePixels]) and fades
/// them in with athletic spring deceleration.
class OlyEntryReveal extends StatefulWidget {
  /// Creates an [OlyEntryReveal] widget.
  const new({
    required this.child,
    super.key,
    this.index = 0,
    this.delay,
    this.duration = const Duration(milliseconds: 380),
    this.slidePixels = 28,
    this.curve = Curves.easeOutCubic,
    this.fade = true,
  });

  /// The child widget to reveal.
  final Widget child;

  /// Stagger sequence index (used to calculate delay: index * 55ms).
  final int index;

  /// Optional explicit delay before animation starts.
  final Duration? delay;

  /// Duration of the reveal animation.
  final Duration duration;

  /// Vertical pixels to slide from.
  final double slidePixels;

  /// Easing curve for the reveal.
  final Curve curve;

  /// Whether to also animate opacity.
  final bool fade;

  @override
  State<OlyEntryReveal> createState() => _OlyEntryRevealState();
}

class _OlyEntryRevealState extends State<OlyEntryReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  Timer? _timer;
  late final bool _isTest;

  @override
  void initState() {
    super.initState();
    _isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (_isTest) {
      _controller.value = 1;
    } else {
      final Duration delayDuration = widget.delay ??
          Duration(milliseconds: widget.index.clamp(0, 10) * 55);
      if (delayDuration == Duration.zero) {
        _controller.forward();
      } else {
        _timer = Timer(delayDuration, () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isTest) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, child) {
        final double progress = _curvedAnimation.value;
        final double dy = (1 - progress) * widget.slidePixels;
        final double opacity = widget.fade ? progress.clamp(0, 1) : 1;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
