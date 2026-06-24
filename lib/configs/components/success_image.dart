import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/generated/assets.dart';

class SuccessImage extends StatelessWidget {
  final bool isCancelled;

  const SuccessImage({
    super.key,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: isCancelled
            ? SvgPicture.asset(Assets.images.icBookingcancellation.path)
            : SvgPicture.asset(Assets.images.imgBookingConfirm.path),
      ),
    );
  }
}

// Alternative version if you have a cancel SVG asset:
// Replace the Icon widget with:
// SvgPicture.asset(Assets.imagesImgBookingCancel)