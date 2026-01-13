import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_controller.dart';
import 'package:get/get.dart';
class TopTabBar extends StatelessWidget {
  TopTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        'Player',
        style: Get.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}