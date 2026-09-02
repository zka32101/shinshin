/// Animated Shake Widget - Error feedback animation
///
/// Provides horizontal shake effect for error states and validation feedback.
/// Creates a snappy, noticeable animation that draws attention to issues.

import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// AnimatedShake - Horizontal shake animation for error states
///
/// Creates a shake effect by repeatedly moving the widget left and right.
/// Perfect for highlighting errors, validation failures, and warnings.
///
/// Example:
/// ```dart
/// AnimatedShake(
///   duration: Duration(milliseconds: 400),
///   distance: 10,
///   child: ErrorMessage(error: validationError),
/// )
/// ```
class AnimatedShake extends StatefulWidget {
  /// The widget to shake
  final Widget child;

  /// Animation duration (default: Duration(milliseconds: 400))
  final Duration duration;

  /// Distance to shake horizontally in pixels (default: 10)
  final double distance;

  /// Number of shake iterations (default: 4)
  final int shakes;

  /// Called when animation completes
  final VoidCallback? onAnimationComplete;

  const AnimatedShake({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.distance = 10,
    this.shakes = 4,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedShake> createState() => _AnimatedShakeState();
}

class _AnimatedShakeState extends State<AnimatedShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create shake animation using a custom Tween
    _offsetAnimation = _buildShakeAnimation();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // Start animation immediately
    _controller.forward();
  }

  Animation<double> _buildShakeAnimation() {
    // Create a sequence of offsets for shake effect
    // Oscillate between -distance and +distance
    return Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Create shake pattern: oscillate back and forth
        final shakeProgress = _controller.value * widget.shakes * 2;
        final shakeValue = (shakeProgress % 2 - 1).abs() * 2 - 1;
        final offset = shakeValue * widget.distance;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
