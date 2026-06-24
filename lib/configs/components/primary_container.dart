import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/generated/assets.dart';

class PrimaryContainer extends StatelessWidget {
  final Widget child;
  const PrimaryContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SizedBox(
          height: Get.height,
          width: Get.width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                Assets.images.imgBackground.path,
                fit: BoxFit.cover,
              ),
              child, // your foreground content
            ],
          ),
        ),
    );
  }
}
