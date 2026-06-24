import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/safe_scaffold.dart';

import '../../configs/app_colors.dart';
import '../../generated/assets.dart';
import 'bottom_nav_controller.dart';
import '../drawer/zoom_drawer_wrapper.dart';

class BottomNavUi extends StatelessWidget {
  BottomNavUi({super.key});

  final BottomNavigationController controller = Get.put(BottomNavigationController());

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerWrapper(
      child: SafeScaffold(
        body: Obx(() => controller.getCurrentPage()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.images.imgBackgroundBottomBar.path),
              fit: BoxFit.contain,
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            color: Colors.transparent,
          ),
          child: Obx(
                () => GNav(
              tabBackgroundColor: AppColors.tabSelectedColor,
              gap: 8,
              padding: const EdgeInsets.all(12),
              color: Colors.black,
              activeColor: Colors.white,
              selectedIndex: controller.selectedIndex.value,
              onTabChange: (index) {
                controller.updateIndex(index);
              },
              tabs: List.generate(4, (index) {
                final tab = controller.tabs[index];
                final isSelected =
                    controller.selectedIndex.value == index;
                final isSvg = tab['isSvg'] == true;
                final iconSize = tab['size'] ?? 24.0;

                final iconWidget = isSvg
                    ? SvgPicture.asset(
                  tab['icon'],
                  width: iconSize,
                  height: iconSize,
                  colorFilter: isSelected
                      ? null
                      : const ColorFilter.mode(AppColors.blackColor, BlendMode.srcIn),
                )
                    : Icon(
                  tab['icon'],
                  size: iconSize,
                  color: isSelected ? null : AppColors.labelBlackColor,
                );

                final leadingWidget = isSelected
                    ? ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      getGradientShader(bounds),
                  child: isSvg
                      ? SvgPicture.asset(
                    tab['icon'],
                    width: iconSize,
                    height: iconSize,
                  )
                      : Icon(
                    tab['icon'],
                    size: iconSize,
                  ),
                )
                    : null;

                return GButton(
                  haptic: true,
                  gap: 10,
                  borderRadius: BorderRadius.circular(30),

                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                  icon: isSvg ? Icons.circle : tab['icon'],
                  text: tab['label'],
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  leading: leadingWidget ?? iconWidget,
                  textStyle: isSelected
                      ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = getGradientShader(
                        Rect.fromLTWH(0, 0, 100, 60),
                      ),
                  )
                      : const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                );
              }),
            ).paddingOnly(left: 0, right:0 ),
          ),
        ),
      ).paddingOnly(bottom: 24),
      ),
    );
  }
  Shader getGradientShader(Rect bounds) {
    return const LinearGradient(
      colors: [AppColors.primaryColor, AppColors.secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bounds);
  }
}
