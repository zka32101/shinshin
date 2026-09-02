/// Animated Bounce Widget - Playful elastic entrance animation
///
/// Provides a bounce effect perfect for badge reveals, achievement unlocks,
/// and surprise moments. Uses elasticOut curve for delightful animations.

import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// AnimatedBounce - Elastic bounce entrance animation
///
/// Creates a scale animation with elasticOut curve for bouncy, playful effects.
/// Perfect for revealing badges, achievements, and celebratory moments.
///
/// Example:
/// ```dart
/// AnimatedBounce(
///   duration: AnimationDurations.long,
///   scale: 1.0,
///   child: Badge(unreadCount: 3),
/// )
/// ```
class AnimatedBounce extends StatefulWidget {
  /// The widget to animate with bounce effect
  final Widget child;

  /// Animation duration (default: AnimationDurations.long)
  final Duration duration;

  /// Final scale value (default: 1.0)
  final double scale;

  /// Animation delay before starting (default: Duration.zero)
  final Duration delay;

  /// Called when animation completes
  final VoidCallback? onAnimationComplete;

  const AnimatedBounce({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.scale = 1.0,
    this.delay = Duration.zero,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedBounce> createState() => _AnimatedBounceState();
}

class _AnimatedBounceState extends State<AnimatedBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.bounceEasing),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // Start animation after delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
