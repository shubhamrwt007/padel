import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArrowAnimation extends StatefulWidget {
  final bool isUpward; // true = upward, false = downward
  final Color? color;
  const ArrowAnimation({
    super.key,
    this.isUpward = true, // default upward
    this.color
  });

  @override
  State<ArrowAnimation> createState() => _ArrowAnimationState();
}

class _ArrowAnimationState extends State<ArrowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // common tween (direction handled later)
    final tween = Tween<double>(begin: 8, end: -8)
        .chain(CurveTween(curve: Curves.easeInOut));

    _animation1 = tween.animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _animation2 = tween.animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    _animation3 = tween.animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildArrow(Animation<double> animation, double opacity) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        // reverse direction for downward arrow
        final directionMultiplier = widget.isUpward ? 1.0 : -1.0;

        return Transform.translate(
          offset: Offset(0, animation.value * directionMultiplier),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              // rotate arrow based on direction
              angle: widget.isUpward ? -math.pi / 2 : math.pi / 2,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color:widget.color?? Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildArrow(_animation3, 0.3),
        _buildArrow(_animation2, 0.6),
        _buildArrow(_animation1, 1.0),
      ],
    );
  }
}