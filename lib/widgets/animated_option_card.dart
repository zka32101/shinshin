import 'package:flutter/material.dart';
import 'package:shared_core/widgets/furigana_text.dart';

class AnimatedOptionCard extends StatefulWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback onTap;
  final bool isEnabled;
  final Color? customColor;

  const AnimatedOptionCard({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onTap,
    this.isEnabled = true,
    this.customColor,
  });

  @override
  State<AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<AnimatedOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _playSelectAnimation();
    }
  }

  void _playSelectAnimation() {
    _controller.forward(from: 0.8);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    final color = widget.customColor ?? Colors.blue;

    if (!widget.isEnabled) {
      return Colors.grey.shade50;
    }

    if (widget.showFeedback) {
      if (widget.isCorrect) {
        return Colors.green.shade50;
      } else if (widget.isSelected && !widget.isCorrect) {
        return Colors.red.shade50;
      }
    }

    if (widget.isSelected) {
      return color.withAlpha(30);
    }

    return Colors.white;
  }

  Color _getBorderColor() {
    final color = widget.customColor ?? Colors.blue;

    if (!widget.isEnabled) {
      return Colors.grey.shade300;
    }

    if (widget.showFeedback) {
      if (widget.isCorrect) {
        return Colors.green.shade400;
      } else if (widget.isSelected && !widget.isCorrect) {
        return Colors.red.shade400;
      }
    }

    if (widget.isSelected) {
      return color.withAlpha(200);
    }

    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isEnabled ? _fadeAnimation : AlwaysStoppedAnimation(0.5);

    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              border: Border.all(
                color: _getBorderColor(),
                width: widget.isSelected ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.customColor ?? Colors.blue.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FuriganaText(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showFeedback)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: widget.isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (widget.isSelected
                            ? const Icon(Icons.close_outlined, color: Colors.red)
                            : const SizedBox.shrink()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
