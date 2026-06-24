import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../generated/assets.dart';
import '../app_colors.dart';

class NoDataFound extends StatelessWidget {
 final String msg;

 const NoDataFound({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: Get.height * .3,
              width: Get.width * .9,
              child: Image.asset(Assets.lottieFiles.noData.path),
            ),
            SizedBox(
              height: Get.height*.03,
            ),
            Text(
              msg,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.blackColor,
                fontSize: 15
              ),
            ),
          ],
        ),
      ),
    );
  }
}
