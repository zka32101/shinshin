/// Animated Progress Ring Widget - Achievement progress visualization
///
/// Provides a circular progress indicator animation that smoothly fills.
/// Perfect for showing achievement progress, completion status, and mastery levels.

import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// AnimatedProgressRing - Circular progress animation
///
/// Creates a smooth circular progress indicator that animates from 0 to the
/// target progress value. Uses easeInOut curve for natural motion.
///
/// Example:
/// ```dart
/// AnimatedProgressRing(
///   progress: 0.75,
///   duration: AnimationDurations.long,
///   radius: 60,
///   child: Text('75%'),
/// )
/// ```
class AnimatedProgressRing extends StatefulWidget {
  /// Progress value (0.0 to 1.0)
  final double progress;

  /// Ring color
  final Color color;

  /// Background ring color
  final Color backgroundColor;

  /// Ring stroke width
  final double strokeWidth;

  /// Ring radius
  final double radius;

  /// Animation duration (default: AnimationDurations.long)
  final Duration duration;

  /// Widget displayed in center of ring (optional)
  final Widget? child;

  /// Called when animation completes
  final VoidCallback? onAnimationComplete;

  const AnimatedProgressRing({
    Key? key,
    required this.progress,
    this.color = const Color(0xFF4CAF50),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.strokeWidth = 8,
    this.radius = 60,
    this.duration = const Duration(milliseconds: 800),
    this.child,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
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
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(begin: _progressAnimation.value, end: widget.progress)
              .animate(
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
    return Center(
      child: CustomPaint(
        size: Size(widget.radius * 2, widget.radius * 2),
        painter: _ProgressRingPainter(
          progress: _progressAnimation.value,
          color: widget.color,
          backgroundColor: widget.backgroundColor,
          strokeWidth: widget.strokeWidth,
        ),
        child: widget.child != null
            ? Center(child: widget.child)
            : null,
      ),
    );
  }
}

/// Custom painter for progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -90.0 * 3.14159 / 180; // Start from top
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * 3.14159; // Full circle = 2π

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
