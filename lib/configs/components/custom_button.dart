import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final Color? circleColor;
  static const double _defaultWidth = 250;
  static const double _defaultHeight = 60;
  const CustomButton({
    super.key,
    this.width = _defaultWidth,
    this.height = _defaultHeight,
    required this.child,
    required this.onTap,
    this.gradientColors,
    this.circleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: RPSCustomPainter(
                gradientColors: gradientColors,
                circleColor: circleColor,
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

class RPSCustomPainter extends CustomPainter {
  final List<Color>? gradientColors;
  final Color? circleColor;

  RPSCustomPainter({this.gradientColors, this.circleColor});

  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.7644431, size.height * 0.05357143);
    path_0.cubicTo(
      size.width * 0.7911377,
      size.height * 0.05357143,
      size.width * 0.8145629,
      size.height * 0.1369291,
      size.width * 0.8278144,
      size.height * 0.2623750,
    );
    path_0.cubicTo(
      size.width * 0.8314461,
      size.height * 0.2967500,
      size.width * 0.8374611,
      size.height * 0.3214286,
      size.width * 0.8442725,
      size.height * 0.3214286,
    );
    path_0.cubicTo(
      size.width * 0.8510838,
      size.height * 0.3214286,
      size.width * 0.8571018,
      size.height * 0.2967500,
      size.width * 0.8607335,
      size.height * 0.2623732,
    );
    path_0.cubicTo(
      size.width * 0.8739820,
      size.height * 0.1369279,
      size.width * 0.8974102,
      size.height * 0.05357143,
      size.width * 0.9241048,
      size.height * 0.05357143,
    );
    path_0.cubicTo(
      size.width * 0.9654431,
      size.height * 0.05357143,
      size.width * 0.9989551,
      size.height * 0.2534446,
      size.width * 0.9989551,
      size.height * 0.5000000,
    );
    path_0.cubicTo(
      size.width * 0.9989551,
      size.height * 0.7465554,
      size.width * 0.9654431,
      size.height * 0.9464286,
      size.width * 0.9241048,
      size.height * 0.9464286,
    );
    path_0.cubicTo(
      size.width * 0.8958114,
      size.height * 0.9464286,
      size.width * 0.8711886,
      size.height * 0.8527964,
      size.width * 0.8584641,
      size.height * 0.7146607,
    );
    path_0.cubicTo(
      size.width * 0.8555689,
      size.height * 0.6832179,
      size.width * 0.8502904,
      size.height * 0.6607143,
      size.width * 0.8442754,
      size.height * 0.6607143,
    );
    path_0.cubicTo(
      size.width * 0.8382605,
      size.height * 0.6607143,
      size.width * 0.8329820,
      size.height * 0.6832179,
      size.width * 0.8300838,
      size.height * 0.7146607,
    );
    path_0.cubicTo(
      size.width * 0.8173593,
      size.height * 0.8527964,
      size.width * 0.7927365,
      size.height * 0.9464250,
      size.width * 0.7644461,
      size.height * 0.9464286,
    );
    path_0.lineTo(size.width * 0.07881647, size.height * 0.9464286);
    path_0.cubicTo(
      size.width * 0.03747784,
      size.height * 0.9464286,
      size.width * 0.003966198,
      size.height * 0.7465554,
      size.width * 0.003966198,
      size.height * 0.5000000,
    );
    path_0.cubicTo(
      size.width * 0.003966198,
      size.height * 0.2534464,
      size.width * 0.03747545,
      size.height * 0.05357607,
      size.width * 0.07881347,
      size.height * 0.05357143,
    );
    path_0.lineTo(size.width * 0.7644431, size.height * 0.05357143);
    path_0.close();

    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.width, 0),
      gradientColors ?? [
        Color(0xff3DBE64),
        Color(0xff1F41BB),
        Color(0xff1F41BB),
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.drawPath(path_0, paint0Fill);

    Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = circleColor ?? Color(0xff3DBE64).withValues(alpha: 1.0);
    canvas.drawCircle(
      Offset(size.width * 0.9251497, size.height * 0.5),
      size.width * 0.06586826,
      paint1Fill,
    );

    Path path_2 = Path();
    path_2.moveTo(size.width * 0.9071347, size.height * 0.6217446);
    path_2.lineTo(size.width * 0.9455599, size.height * 0.3925786);
    path_2.moveTo(size.width * 0.9455599, size.height * 0.3925786);
    path_2.lineTo(size.width * 0.9071347, size.height * 0.3925786);
    path_2.moveTo(size.width * 0.9455599, size.height * 0.3925786);
    path_2.lineTo(size.width * 0.9455599, size.height * 0.6217446);

    Paint paint2Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.006586826
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path_2, paint2Stroke);

    Paint paint2Fill = Paint()..style = PaintingStyle.fill;
    paint2Fill.color = Colors.black;
    canvas.drawPath(path_2, paint2Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
