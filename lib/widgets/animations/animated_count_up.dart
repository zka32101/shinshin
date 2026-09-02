/// Animated Count Up Widget - Number animation for score reveals
///
/// Animates a number from 0 (or start value) to end value smoothly.
/// Perfect for displaying scores, counts, and achievement revelations.

import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// AnimatedCountUp - Number count-up animation
///
/// Smoothly animates a number from a start value to an end value.
/// Useful for dramatic score reveals, counter animations, and statistics.
///
/// Example:
/// ```dart
/// AnimatedCountUp(
///   endValue: 2500,
///   duration: AnimationDurations.extraLong,
///   style: Theme.of(context).textTheme.headline4,
/// )
/// ```
class AnimatedCountUp extends StatefulWidget {
  /// Final number value to animate to
  final int endValue;

  /// Starting number value (default: 0)
  final int startValue;

  /// Animation duration (default: AnimationDurations.extraLong)
  final Duration duration;

  /// Text style for the number
  final TextStyle? style;

  /// Number formatting function (default: simple int.toString())
  final String Function(int)? formatter;

  /// Called when animation completes
  final VoidCallback? onAnimationComplete;

  /// Prefix text (displayed before number)
  final String prefix;

  /// Suffix text (displayed after number)
  final String suffix;

  const AnimatedCountUp({
    Key? key,
    required this.endValue,
    this.startValue = 0,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.formatter,
    this.onAnimationComplete,
    this.prefix = '',
    this.suffix = '',
  }) : super(key: key);

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.startValue.toDouble(),
      end: widget.endValue.toDouble(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCountUp oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.endValue != widget.endValue) {
      _animation = Tween<double>(
        begin: widget.startValue.toDouble(),
        end: widget.endValue.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: AnimationCurves.easeInOut),
      );

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value.toInt();
        final displayText = widget.formatter?.call(currentValue) ?? '$currentValue';
        final text = '${widget.prefix}$displayText${widget.suffix}';

        return Text(
          text,
          style: widget.style,
        );
      },
    );
  }
}

/// Extension for convenient formatting
extension IntFormatter on int {
  /// Format number with thousands separator
  String withCommas() {
    return toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  /// Format as percentage
  String asPercentage() {
    return '$this%';
  }

  /// Format with text suffix
  String withSuffix(String suffix) {
    return '$this$suffix';
  }
}
