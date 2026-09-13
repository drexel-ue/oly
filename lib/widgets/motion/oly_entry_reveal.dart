import 'dart:async';
import 'package:flutter/material.dart';

/// An inherited widget that propagates directional velocity and horizontal displacement
/// from tab-to-tab navigation down to cascading [OlyEntryReveal] cards.
class TabDirectionScope extends InheritedWidget {
  const new({
    required super.child,
    super.key,
    this.direction = 0,
    this.horizontalOffset = 38,
  });

  /// The horizontal direction of travel:
  /// +1 when moving right (e.g. Train -> Recover -> Fuel -> Insights)
  /// -1 when moving left (e.g. Insights -> Fuel -> Recover -> Train)
  /// 0 for initial load or stationary route transitions.
  final int direction;

  /// The horizontal pixel distance to slide from.
  final double horizontalOffset;

  /// Look up the nearest [TabDirectionScope] in the widget tree.
  static TabDirectionScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabDirectionScope>();
  }

  @override
  bool updateShouldNotify(TabDirectionScope oldWidget) {
    return direction != oldWidget.direction ||
        horizontalOffset != oldWidget.horizontalOffset;
  }
}

/// A staggered slide and fade reveal animation widget for screen entry cascades.
/// Translates children by a physical displacement vector ([slidePixels], [horizontalSlidePixels])
/// and fades them in with athletic spring deceleration.
///
/// Automatically synchronizes with [TabDirectionScope] to impart directional horizontal
/// inertia when traveling across navigation tabs.
///
/// Can coordinate with the enclosing [ModalRoute] to wait for incoming page transitions
/// to complete before cascading, and smoothly reverse the cascade upon exit/pop.
class OlyEntryReveal extends StatefulWidget {
  /// Creates an [OlyEntryReveal] widget.
  const new({
    required this.child,
    super.key,
    this.index = 0,
    this.delay,
    this.reverseDelay,
    this.duration = const Duration(milliseconds: 480),
    this.reverseDuration = const Duration(milliseconds: 220),
    this.slidePixels = 28,
    this.horizontalSlidePixels,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    this.fade = true,
    this.waitForPageTransition = true,
    this.reverseOnExit = true,
  });

  /// The child widget to reveal.
  final Widget child;

  /// Stagger sequence index (used to calculate delay: index * 55ms).
  final int index;

  /// Optional explicit delay before animation starts.
  final Duration? delay;

  /// Optional explicit delay before reverse animation starts on exit.
  final Duration? reverseDelay;

  /// Duration of the reveal animation.
  final Duration duration;

  /// Duration of the reverse exit animation.
  final Duration reverseDuration;

  /// Vertical pixels to slide from.
  final double slidePixels;

  /// Optional horizontal pixels to slide from. If null, derives directional
  /// velocity automatically from ambient [TabDirectionScope].
  final double? horizontalSlidePixels;

  /// Easing curve for the reveal.
  final Curve curve;

  /// Easing curve for the reverse exit.
  final Curve reverseCurve;

  /// Whether to also animate opacity.
  final bool fade;

  /// Whether to wait for the enclosing route's page transition to complete
  /// before triggering the staggered entry cascade.
  final bool waitForPageTransition;

  /// Whether to reverse the reveal animation when the enclosing route is popped.
  final bool reverseOnExit;

  @override
  State<OlyEntryReveal> createState() => _OlyEntryRevealState();
}

class _OlyEntryRevealState extends State<OlyEntryReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  Timer? _entryTimer;
  Timer? _exitTimer;
  late final bool _isTest;
  Animation<double>? _routeAnimation;
  bool _hasStartedEntry = false;

  @override
  void initState() {
    super.initState();
    _isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );

    if (_isTest) {
      _controller.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isTest) return;

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final Animation<double>? animation = route?.animation;

    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
      _routeAnimation = animation;
      _routeAnimation?.addStatusListener(_onRouteAnimationStatusChanged);
    }

    _checkRouteAndAnimate();
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _startEntryCascade();
    } else if (status == AnimationStatus.reverse) {
      if (widget.reverseOnExit) {
        _startExitAnimation();
      }
    }
  }

  void _checkRouteAndAnimate() {
    if (_hasStartedEntry) return;

    final Animation<double>? anim = _routeAnimation;
    if (widget.waitForPageTransition && anim != null && !anim.isCompleted) {
      // Enclosing route is actively transitioning in; wait for AnimationStatus.completed
      return;
    }

    _startEntryCascade();
  }

  void _startEntryCascade() {
    if (!mounted || _hasStartedEntry) return;
    _hasStartedEntry = true;
    _exitTimer?.cancel();
    _exitTimer = null;

    final Duration delayDuration = widget.delay ??
        Duration(milliseconds: widget.index.clamp(0, 15) * 60);

    if (delayDuration == Duration.zero) {
      _controller.forward();
    } else {
      _entryTimer?.cancel();
      _entryTimer = Timer(delayDuration, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  void _startExitAnimation() {
    if (!mounted) return;
    _entryTimer?.cancel();
    _entryTimer = null;
    _hasStartedEntry = false; // Allow re-trigger if swipe-to-pop is cancelled

    final Duration delayDuration = widget.reverseDelay ?? Duration.zero;

    if (delayDuration == Duration.zero) {
      if (_controller.value > 0) {
        _controller.reverse();
      }
    } else {
      _exitTimer?.cancel();
      _exitTimer = Timer(delayDuration, () {
        if (mounted && _controller.value > 0) {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void didUpdateWidget(OlyEntryReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.reverseDuration != oldWidget.reverseDuration) {
      _controller.reverseDuration = widget.reverseDuration;
    }
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _exitTimer?.cancel();
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isTest) {
      return widget.child;
    }

    final TabDirectionScope? tabScope = TabDirectionScope.of(context);
    final double horizontalOffset = widget.horizontalSlidePixels ??
        ((tabScope != null && tabScope.direction != 0)
            ? (tabScope.direction * tabScope.horizontalOffset)
            : 0.0);

    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, child) {
        final double progress = _curvedAnimation.value;
        final double dx = (1 - progress) * horizontalOffset;
        final double dy = (1 - progress) * widget.slidePixels;
        final double opacity = widget.fade ? progress.clamp(0, 1) : 1;

        return Transform.translate(
          offset: Offset(dx, dy),
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
