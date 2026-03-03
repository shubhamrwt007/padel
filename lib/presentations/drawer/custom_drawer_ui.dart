import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/app_strings.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/cart/cart_screen.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_screen.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_screen.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawerUi extends GetView<ProfileController> {
  const CustomDrawerUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width * 0.2,
      decoration: const BoxDecoration(
        color: Colors.white,
        // Removed borderRadius and boxShadow to eliminate line and shadow
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          Expanded(child: _buildMenuItems(context)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 66),
          // Profile Picture with Pencil Icon
          Obx(
                () => Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () => Get.to(()=>EditProfileUi(buttonType: "drawer",)),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: Get.height * 0.08,
                      width: Get.height * 0.08,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tabSelectedColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (controller.profileModel.value?.response?.profilePic?.isNotEmpty ?? false)
                            ? CachedNetworkImage(
                          imageUrl: controller.profileModel.value?.response?.profilePic ?? "",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: LoadingWidget(color: AppColors.primaryColor),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.labelBlackColor,
                          ),
                        )
                            : Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.labelBlackColor,
                        ),
                      ),
                    ),

                    // ✏️ Pencil Icon at Bottom Right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryColor,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Name and Email
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final profile = controller.profileModel.value?.response;
                  return Text(
                    profile?.name?.capitalizeFirstChar() ?? 'Guest',
                    style: Get.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.labelBlackColor,
                    ),
                  );
                }),
                const SizedBox(height: 0),
                Obx(() {
                  final profile = controller.profileModel.value?.response;
                  return Text(
                    profile?.email ?? 'unknown@gmail.com',
                    style: Get.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.labelBlackColor,
                      fontSize: 12,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    ).paddingOnly(top: 30);
  }
  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [

              Obx(
                    () => ProfileRow(
                  icon: Image.asset(Assets.imagesIcBalanceWallet, scale: 5, color: controller.selectedIndex.value == 3 ? AppColors.primaryColor : AppColors.labelBlackColor),
                  title: "My Transactions",
                  isSelected: controller.selectedIndex.value == 3,
                  onTap: () {
                    controller.selectedIndex.value = 3;
                    Get.toNamed(RoutesName.paymentWallet);
                  },
                ),
              ),

              Obx(
                    () => ProfileRow(
                  icon: Icon(Icons.person_add_alt_1, size: 20, color: controller.selectedIndex.value == 5 ? AppColors.primaryColor : AppColors.labelBlackColor),
                  title: "My Requests",
                  isSelected: controller.selectedIndex.value == 5,
                  onTap: () {
                    controller.selectedIndex.value = 5;
                    Get.toNamed(RoutesName.requests);
                  },
                  count: controller.pendingRequestCount.value,
                ),
              ),
              Obx(
                    () => ProfileRow(
                  icon: Icon(Icons.bar_chart, size: 20, color: controller.selectedIndex.value == 6 ? AppColors.primaryColor : AppColors.labelBlackColor),
                  title: "LeaderBoard",
                  isSelected: controller.selectedIndex.value == 6,
                  onTap: () {
                    controller.selectedIndex.value = 6;
                    Get.to(()=>LeaderboardScreen(buttonType: "drawer",));
                  },

                ),
              ),
              Obx(
                    () => ProfileRow(
                  icon: SvgPicture.asset(
                      Assets.imagesIcBookings,
                      height: 22,
                      width: 22,
                      colorFilter: ColorFilter.mode(
                        controller.selectedIndex.value == 7
                            ? AppColors.primaryColor
                            : AppColors.labelBlackColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  title: "My Bookings",
                  isSelected: controller.selectedIndex.value == 7,
                  onTap: () {
                    controller.selectedIndex.value = 7;
                    Get.to(()=>BookingHistoryUi(buttonType: "drawer",));
                  },
                ),
              ),
              // Obx(
              //       () => ProfileRow(
              //     icon: Icon(Icons.emoji_events, size: 20, color: controller.selectedIndex.value == 8 ? AppColors.primaryColor : AppColors.labelBlackColor),
              //     title: "Tournaments",
              //     isSelected: controller.selectedIndex.value == 8,
              //     onTap: () {
              //       controller.selectedIndex.value = 8;
              //       Get.toNamed(RoutesName.tournaments);
              //     },
              //
              //   ),
              // ),
              // Obx(
              //   () => ProfileRow(
              //     icon: SvgPicture.asset(
              //       Assets.imagesIcPackages,
              //       height: 17,
              //       width: 17,
              //       colorFilter: ColorFilter.mode(
              //         controller.selectedIndex.value == 8
              //             ? AppColors.primaryColor
              //             : AppColors.labelBlackColor,
              //         BlendMode.srcIn,
              //       ),
              //     ),
              //     title: "Packages",
              //     isSelected: controller.selectedIndex.value == 8,
              //     onTap: () {
              //       controller.selectedIndex.value = 8;
              //       Get.toNamed(RoutesName.packages);
              //     },
              //   ),
              // ),
              // Obx(
              //       () => ProfileRow(
              //     icon: Icon(Icons.group_outlined,
              //         size: 20,
              //         color: controller.selectedIndex.value == 9
              //             ? AppColors.primaryColor
              //             : AppColors.labelBlackColor),
              //     title: "Community",
              //     isSelected: controller.selectedIndex.value == 9,
              //     onTap: () {
              //       controller.selectedIndex.value = 9;
              //       // Get.toNamed(RoutesName.community);
              //     },
              //   ),
              // ),




          //     Obx(
          //       () => ProfileRow(
          //         icon: Icon(Icons.wallet,color: controller.selectedIndex.value == 13
          // ? AppColors.primaryColor
          //     : AppColors.labelBlackColor,
          // ).paddingOnly(left: 3),
          //         title: "Wallet",
          //         isSelected: controller.selectedIndex.value == 13,
          //         onTap: (){
          //           controller.selectedIndex.value = 13;
          //           Get.toNamed(RoutesName.wallet);
          //         },
          //       ),
          //     ),

              const SizedBox(height: 20),
            ],
          ),
          Column(
            children: [
              ProfileRow(
                fontSize: 12,
                height: 30,
                icon: SvgPicture.asset(Assets.imagesIcLogOut, height: 15, width: 17).paddingOnly(left: 3),
                title: AppStrings.logout,
                textColor: Colors.red,
                onTap: () => controller.showLogoutDialog(Get.context!),
              ),
              Obx(
                    () => ProfileRow(
                  icon: Icon(
                    Icons.delete_forever_outlined,
                    size: 20,
                    color: controller.selectedIndex.value == 13
                        ? AppColors.primaryColor
                        : AppColors.labelBlackColor,
                  ),
                  title: "Delete Account",
                      fontSize: 12,
                      height: 30,
                  isSelected: controller.selectedIndex.value == 13,
                  onTap: () {
                    controller.selectedIndex.value = 13;
                    controller.showDeleteAccountDialog(Get.context!);
                  },
                ),
              ),
              Obx(
                    () => ProfileRow(
                  icon: Icon(Icons.headset_mic_outlined, size: 15, color: controller.selectedIndex.value == 10 ? AppColors.primaryColor : AppColors.labelBlackColor),
                  title: AppStrings.helpSupport,
                  isSelected: controller.selectedIndex.value == 10,
                  fontSize: 12,
                  height: 30,
                  onTap: () {
                    controller.selectedIndex.value = 10;
                    Get.toNamed(RoutesName.support);
                  },
                ),
              ),
              Obx(
                    () => ProfileRow(
                  icon: Image.asset(
                    Assets.imagesIcPrivacy,
                    scale: 6,
                    color: controller.selectedIndex.value == 12
                        ? AppColors.primaryColor
                        : AppColors.labelBlackColor,
                  ),
                  title: AppStrings.privacy,
                      fontSize: 12,
                      height: 30,
                  isSelected: controller.selectedIndex.value == 12,
                  onTap: () async {
                    controller.selectedIndex.value = 12;

                    final url = Uri.parse("https://swootapp.com/privacy-policy");

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication, // opens in browser
                      );
                    }
                  },
                ),
              ),
              Obx(
                    () => ProfileRow(
                  icon: Icon(Icons.copyright, size: 15, color: controller.selectedIndex.value == 11 ? AppColors.primaryColor : AppColors.labelBlackColor),
                  title: "Terms and Conditions",
                  isSelected: controller.selectedIndex.value == 11,
                  fontSize: 12,
                  height: 30,
                  onTap: () async {
                    controller.selectedIndex.value = 11;

                    final url = Uri.parse("https://swootapp.com/term-&-conditions");

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication, // opens in browser
                      );
                    }
                  },
                ),
              ).paddingOnly(bottom: 20),

              Row(
                children: [
                  GestureDetector(
                    onTap: ()async{
                      final url = Uri.parse("https://rowthtech.com");

                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication, // opens in browser
                        );
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 4,horizontal: 9),
                      child: Text(
                        "Powered By RowthTech",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: AppColors.blackColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  SvgPicture.asset(Assets.imagesRowthTechLogo,height: 13,width: 13,)
                ],
              )
            ],
          ).paddingOnly(bottom: 50),


        ],
      ),
    );
  }
}

/// Reusable row widget
class ProfileRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool isSelected;
  final double? fontSize;
  final double? height;
  final int? count;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.textColor,
    this.isSelected = false,
    this.fontSize,
    this.height,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = AppColors.labelBlackColor;
    final highlightColor = AppColors.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 48,
        color: Colors.transparent,
        child: Row(
          children: [
            // 👇 Wrap all icons in a fixed-size box for alignment
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: icon,
              ),
            ),
            const SizedBox(width: 16), // consistent spacing between icon and text
            Text(
              title,
              style: Get.textTheme.headlineSmall!.copyWith(
                color: isSelected ? highlightColor : (textColor ?? defaultColor),
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ).paddingOnly(right: 5),
            if (count != null && count! > 0)
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.redColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.0, // 👈 removes extra bottom space
                    decoration: TextDecoration.none, // 👈 ensures no underline artifact
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}