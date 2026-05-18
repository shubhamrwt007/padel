import 'package:flutter/material.dart';
import 'dart:math';

class ComingSoonFireworks extends StatefulWidget {
  final TextStyle? textStyle;
  
  const ComingSoonFireworks({super.key, this.textStyle});

  @override
  State<ComingSoonFireworks> createState() => _ComingSoonFireworksState();
}

class _ComingSoonFireworksState extends State<ComingSoonFireworks> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(' AI Coming Soon', style: widget.textStyle),
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          height: 40,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _FireworksPainter(_controller.value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  
  _FireworksPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..strokeWidth = 1.5;
    
    if (progress < 0.5) {
      final p = Curves.easeOut.transform(progress * 2);
      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4);
        final opacity = (1 - p).clamp(0.0, 1.0);
        paint.color = Color.lerp(Colors.red, Colors.green, p)!.withOpacity(opacity);
        canvas.drawLine(
          center,
          Offset(
            center.dx + cos(angle) * p * size.width * 0.4,
            center.dy + sin(angle) * p * size.height * 0.4,
          ),
          paint,
        );
      }
    } else {
      final p = Curves.easeOut.transform((progress - 0.5) * 2);
      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4) + pi / 8;
        final opacity = (1 - p).clamp(0.0, 1.0);
        paint.color = Color.lerp(Colors.pink, Colors.purple, p)!.withOpacity(opacity);
        canvas.drawLine(
          center,
          Offset(
            center.dx + cos(angle) * p * size.width * 0.4,
            center.dy + sin(angle) * p * size.height * 0.4,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) => true;
}
