import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/generated/assets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset(
          Assets.images.padelLogo11.path,
          height: 60,
          width: 60,
        ),
      ),
    );
  }
}
