import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
class ContainerClipper extends CustomClipper<Path> {
  final double notchOffsetFromCenter;

  ContainerClipper({this.notchOffsetFromCenter = 0}); // positive moves down, negative moves up

  @override
  Path getClip(Size size) {
    double radius = 10;
    double bumpRadius = 0;
    double notchRadius = 9;

    double notchPosition = size.height / 2 + notchOffsetFromCenter;

    final Path path = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width / 2 - bumpRadius, 0)
      ..quadraticBezierTo(size.width / 2, 20, size.width / 2 + bumpRadius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, notchPosition - notchRadius)
      ..arcToPoint(
        Offset(size.width, notchPosition + notchRadius),
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(size.width, size.height, size.width - radius, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, notchPosition + notchRadius)
      ..arcToPoint(
        Offset(0, notchPosition - notchRadius),
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
