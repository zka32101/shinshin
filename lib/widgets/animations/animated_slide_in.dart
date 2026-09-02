/// Animated Slide In Widget - Content entry animation
///
/// Provides smooth slide-in effects from all directions with fade-in effect.
/// Perfect for content entering screen, page transitions, and expansions.

import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// Direction for slide animation
enum SlideDirection {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}

/// AnimatedSlideIn - Smooth slide entrance animation with fade
///
/// Creates a slide animation combined with fade-in for smooth content entry.
/// Supports multiple slide directions with customizable duration and curve.
///
/// Example:
/// ```dart
/// AnimatedSlideIn(
///   direction: SlideDirection.fromBottom,
///   duration: AnimationDurations.medium,
///   child: ProfileCard(user: user),
/// )
/// ```
class AnimatedSlideIn extends StatefulWidget {
  /// The widget to animate with slide-in effect
  final Widget child;

  /// Slide direction (default: SlideDirection.fromBottom)
  final SlideDirection direction;

  /// Animation duration (default: AnimationDurations.medium)
  final Duration duration;

  /// Distance to slide from (in pixels, default: 50)
  final double offset;

  /// Animation delay before starting (default: Duration.zero)
  final Duration delay;

  /// Called when animation completes
  final VoidCallback? onAnimationComplete;

  const AnimatedSlideIn({
    Key? key,
    required this.child,
    this.direction = SlideDirection.fromBottom,
    this.duration = const Duration(milliseconds: 300),
    this.offset = 50,
    this.delay = Duration.zero,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

class _AnimatedSlideInState extends State<AnimatedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Calculate slide offset based on direction
    Offset beginOffset = _getBeginOffset();

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.easeInOut),
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

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.fromLeft:
        return Offset(-widget.offset, 0);
      case SlideDirection.fromRight:
        return Offset(widget.offset, 0);
      case SlideDirection.fromTop:
        return Offset(0, -widget.offset);
      case SlideDirection.fromBottom:
        return Offset(0, widget.offset);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
