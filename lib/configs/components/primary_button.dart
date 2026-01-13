import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final double? width, height;
  final Widget? child;
  final String text;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  const PrimaryButton({
    super.key,
    this.width,
    this.height,
    this.child,
    required this.onTap,
    required this.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        height: height ?? 50,
        width: width ?? Get.width,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3DBE64),
              Color(0xFF1F41BB),
              Color(0xFF1F41BB),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: child ??
            Text(
              text,
              style: textStyle ??
                  Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
            ),
      ),
    );
  }
}
