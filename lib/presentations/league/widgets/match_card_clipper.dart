import 'package:flutter/material.dart';
class MatchCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double cornerRadius = 12;
    const double notchWidth = 100;
    const double notchDepth = 25;

    final path = Path();

    /// left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    /// line to left notch
    path.lineTo(size.width / 2 - notchWidth / 2 - 20, 0);

    /// smoother left curve
    path.cubicTo(
      size.width / 2 - notchWidth / 2 - 8,
      0,
      size.width / 2 - notchWidth / 2 - 8,
      notchDepth,
      size.width / 2 - notchWidth / 2,
      notchDepth,
    );

    /// bottom notch line
    path.lineTo(size.width / 2 + notchWidth / 2, notchDepth);

    /// smoother right curve
    path.cubicTo(
      size.width / 2 + notchWidth / 2 + 8,
      notchDepth,
      size.width / 2 + notchWidth / 2 + 8,
      0,
      size.width / 2 + notchWidth / 2 + 20,
      0,
    );

    /// right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    /// sides
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) => false;
}