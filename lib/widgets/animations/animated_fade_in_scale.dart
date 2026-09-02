/// Animated Fade In Scale Widget - Card entrance animation
///
/// Combines fade and scale animations for a smooth card appearance effect.
/// Perfect for revealing cards, gallery items, and UI elements.

import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// AnimatedFadeInScale - Fade and scale entrance animation
///
/// Creates a combined fade-in and scale-up effect for smooth card reveals.
/// Uses easeInOut curve for balanced, natural motion.
///
/// Example:
/// ```dart
/// AnimatedFadeInScale(
///   duration: AnimationDurations.medium,
///   beginScale: 0.8,
///   child: StoryCard(story: story),
/// )
/// ```
class AnimatedFadeInScale extends StatefulWidget {
  /// The widget to animate with fade and scale effect
  final Widget child;

  /// Animation duration (default: AnimationDurations.medium)
  final Duration duration;

  /// Initial scale value (default: 0.8)
  final double beginScale;

  /// Final scale value (default: 1.0)
  final double endScale;

  /// Animation delay before starting (default: Duration.zero)
  final Duration delay;

  /// Called when animation completes
  final VoidCallback? onAnimationComplete;

  const AnimatedFadeInScale({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.beginScale = 0.8,
    this.endScale = 1.0,
    this.delay = Duration.zero,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedFadeInScale> createState() => _AnimatedFadeInScaleState();
}

class _AnimatedFadeInScaleState extends State<AnimatedFadeInScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: widget.beginScale, end: widget.endScale)
        .animate(
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
